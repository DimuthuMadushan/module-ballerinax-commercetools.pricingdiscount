#!/usr/bin/env python3
"""
Extract the pricing and discount OpenAPI spec from the full commercetools spec.

Downloads the commercetools Composable Commerce API description published in
wso2/api-specs (~98k lines, 299 paths, 2,799 schemas) and writes the trimmed spec
the `ballerinax/commercetools.pricingdiscount` connector is generated from:

  openapi.yaml    — 30 operations, components pruned to their closure

This reproduces sanitations.md items 1 and 2. The trimming rules:

  paths       the (path, method) pairs in KEEP, in upstream order; path-level
              `parameters`/`description` are kept, every other method (HEAD
              included) is dropped
  components  the transitive closure of the kept operations. `$ref`s are always
              followed. `discriminator.mapping` targets are followed too, so the
              polymorphic subtypes (every *UpdateAction, CartDiscountValue,
              CartDiscountTarget, ...) survive and the update operations can
              express their actions. The exception is the GENERIC families,
              whose mappings span the whole API and would drag most of it in.
  mappings    any `discriminator.mapping` entry whose target was not kept is
              dropped; a discriminator left with no mapping is removed

The output is the starting point for sanitations.md items 3 onward, which are
applied on top of it by editing the spec. Re-running this script overwrites
docs/spec/openapi.yaml and drops them, so they must be re-applied after it.

Paths resolve relative to this file, so it can be run from anywhere. The source
spec is cached beside the script and re-downloaded only when it is missing:

    python3 docs/resources/script.py
"""

from __future__ import annotations

import ssl
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path
from typing import Iterable

try:
    import yaml
except ImportError:
    sys.stderr.write("PyYAML is required: pip install pyyaml\n")
    sys.exit(1)

try:
    from yaml import CSafeLoader as YamlLoader, CSafeDumper as YamlDumper
except ImportError:
    from yaml import SafeLoader as YamlLoader, SafeDumper as YamlDumper


HERE = Path(__file__).resolve().parent
SOURCE = HERE / "commercetools-openapi.yaml"
SOURCE_URL = (
    "https://raw.githubusercontent.com/wso2/api-specs/"
    "main/openapi/commercetools/pricingdiscount/v1/openapi.yaml"
)
OUT = HERE.parent / "spec" / "openapi.yaml"

# The previous connector's 30 operations. Excluded on purpose: every HEAD, the
# /in-store/... variants and discount-codes/key={key}, none of which it exposed.
KEEP = {
    "/{projectKey}/cart-discounts": ("get", "post"),
    "/{projectKey}/cart-discounts/key={key}": ("get", "post", "delete"),
    "/{projectKey}/cart-discounts/{ID}": ("get", "post", "delete"),
    "/{projectKey}/discount-codes": ("get", "post"),
    "/{projectKey}/discount-codes/{ID}": ("get", "post", "delete"),
    "/{projectKey}/product-discounts": ("get", "post"),
    "/{projectKey}/product-discounts/key={key}": ("get", "post", "delete"),
    "/{projectKey}/product-discounts/matching": ("post",),
    "/{projectKey}/product-discounts/{ID}": ("get", "post", "delete"),
    "/{projectKey}/tax-categories": ("get", "post"),
    "/{projectKey}/tax-categories/key={key}": ("get", "post", "delete"),
    "/{projectKey}/tax-categories/{ID}": ("get", "post", "delete"),
}

# Schemas whose discriminator mappings are not followed.
GENERIC = frozenset(("Reference", "ResourceIdentifier", "KeyReference", "ErrorObject"))

OPERATION_KEYS = frozenset(
    ("get", "put", "post", "delete", "options", "head", "patch", "trace")
)

REF_PREFIX = "#/components/"


def _ssl_context() -> ssl.SSLContext:
    """Verify against certifi's CA bundle when it is installed (the python.org
    macOS builds otherwise fail every HTTPS fetch)."""
    try:
        import certifi
    except ImportError:
        return ssl.create_default_context()
    return ssl.create_default_context(cafile=certifi.where())


def download_source(target: Path) -> None:
    print(f"Downloading {SOURCE_URL} ...", flush=True)
    try:
        with urllib.request.urlopen(SOURCE_URL, context=_ssl_context()) as response:
            payload = response.read()
    except urllib.error.HTTPError as exc:
        raise SystemExit(
            f"Download failed: HTTP {exc.code} for {SOURCE_URL}\n"
            "If the spec has not landed in wso2/api-specs yet, drop a local copy "
            f"at {target.name} beside this script."
        ) from exc
    except urllib.error.URLError as exc:
        raise SystemExit(f"Download failed: {exc.reason} for {SOURCE_URL}") from exc
    target.write_bytes(payload)
    print(f"  wrote {target.name} ({target.stat().st_size:,} bytes)")


def collect_refs(node, follow_mapping: bool) -> Iterable[str]:
    """Yield every `$ref` inside `node`, plus mapping targets when asked to."""
    if isinstance(node, dict):
        for key, value in node.items():
            if key == "$ref" and isinstance(value, str):
                yield value
            elif key == "mapping" and isinstance(value, dict):
                if follow_mapping:
                    yield from (v for v in value.values() if isinstance(v, str))
            else:
                yield from collect_refs(value, follow_mapping)
    elif isinstance(node, list):
        for item in node:
            yield from collect_refs(item, follow_mapping)


def walk_closure(paths: dict, components: dict) -> set[str]:
    """Transitively resolve every component reachable from the kept paths."""
    kept: set[str] = set()
    queue = list(collect_refs(paths, follow_mapping=False))
    while queue:
        ref = queue.pop()
        if ref in kept or not ref.startswith(REF_PREFIX):
            continue
        section, _, name = ref[len(REF_PREFIX):].partition("/")
        component = components.get(section, {}).get(name)
        if component is None:
            raise SystemExit(f"Dangling upstream ref: {ref}")
        kept.add(ref)
        queue.extend(collect_refs(component, follow_mapping=name not in GENERIC))
    return kept


def prune_mappings(node, kept: set[str]) -> None:
    """Drop mapping entries whose target was pruned; drop empty discriminators."""
    if isinstance(node, dict):
        disc = node.get("discriminator")
        if isinstance(disc, dict) and isinstance(disc.get("mapping"), dict):
            mapping = {k: v for k, v in disc["mapping"].items() if v in kept}
            if mapping:
                disc["mapping"] = mapping
            else:
                del node["discriminator"]
        for value in node.values():
            prune_mappings(value, kept)
    elif isinstance(node, list):
        for item in node:
            prune_mappings(item, kept)


def build_output(source_doc: dict) -> dict:
    paths: dict = {}
    for path, item in source_doc["paths"].items():
        methods = KEEP.get(path)
        if methods is None:
            continue
        missing = [m for m in methods if m not in item]
        if missing:
            raise SystemExit(f"{path} has no {', '.join(missing).upper()} upstream")
        paths[path] = {k: v for k, v in item.items() if k not in OPERATION_KEYS or k in methods}
    absent = set(KEEP) - set(paths)
    if absent:
        raise SystemExit(f"Paths not found upstream: {', '.join(sorted(absent))}")

    components = source_doc.get("components") or {}
    kept = walk_closure(paths, components)
    pruned: dict = {}
    for section, entries in components.items():
        if section == "securitySchemes":
            pruned[section] = entries
            continue
        subset = {n: v for n, v in entries.items() if f"{REF_PREFIX}{section}/{n}" in kept}
        if subset:
            pruned[section] = subset

    out = {k: v for k, v in source_doc.items() if k not in ("paths", "components")}
    out["paths"] = paths
    out["components"] = pruned
    prune_mappings(out, kept)
    return out


def write_yaml(target: Path, doc: dict) -> None:
    class Dumper(YamlDumper):
        # Anchors/aliases are valid YAML but most OpenAPI tooling chokes on them.
        def ignore_aliases(self, data):
            return True

    def represent_str(dumper, value):
        style = "|" if "\n" in value else None
        return dumper.represent_scalar("tag:yaml.org,2002:str", value, style=style)

    Dumper.add_representer(str, represent_str)
    with target.open("w", encoding="utf-8") as fh:
        yaml.dump(doc, fh, Dumper=Dumper, sort_keys=False, allow_unicode=True, width=10**6)


def main() -> int:
    if not SOURCE.exists():
        download_source(SOURCE)

    t0 = time.monotonic()
    print(f"Loading {SOURCE.name} ({SOURCE.stat().st_size:,} bytes) ...", flush=True)
    with SOURCE.open(encoding="utf-8") as fh:
        source_doc = yaml.load(fh, Loader=YamlLoader)
    print(f"  {len(source_doc['paths']):,} paths, "
          f"{len(source_doc.get('components', {}).get('schemas', {})):,} schemas")

    doc = build_output(source_doc)
    ops = sum(1 for item in doc["paths"].values() for k in item if k in OPERATION_KEYS)
    print(f"  {len(doc['paths'])} paths, {ops} operations")
    for section, entries in doc["components"].items():
        print(f"  {section:<16} {len(entries):,}")

    write_yaml(OUT, doc)
    print(f"\nWrote {OUT} in {time.monotonic() - t0:.1f}s")
    return 0


if __name__ == "__main__":
    sys.exit(main())
