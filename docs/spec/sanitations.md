_Author_:  @DimuthuMadushan \
_Created_: 2026/10/06 \
_Updated_: 2026/10/06 \
_Edition_: Swan Lake

# Sanitation for OpenAPI specification

This document records the sanitation done on top of the official OpenAPI specification from Commercetools.
The OpenAPI specification is obtained from [https://github.com/wso2/api-specs/blob/main/openapi/commercetools/pricingdiscount/v1/openapi.yaml](https://github.com/wso2/api-specs/blob/main/openapi/commercetools/pricingdiscount/v1/openapi.yaml).
These changes are done in order to improve the overall usability, and as workarounds for some known language limitations.

1. **Subset the spec to the previous connector's 30 operations.** The source spec is the full commercetools Composable Commerce API. Only these operations under `/{projectKey}` were kept: `cart-discounts` (GET, POST), `cart-discounts/key={key}` (GET, POST, DELETE), `cart-discounts/{ID}` (GET, POST, DELETE), `discount-codes` (GET, POST), `discount-codes/{ID}` (GET, POST, DELETE), `product-discounts` (GET, POST), `product-discounts/key={key}` (GET, POST, DELETE), `product-discounts/matching` (POST), `product-discounts/{ID}` (GET, POST, DELETE), `tax-categories` (GET, POST), `tax-categories/key={key}` (GET, POST, DELETE) and `tax-categories/{ID}` (GET, POST, DELETE). All HEAD operations, all `/in-store/...` paths, `discount-codes/key={key}` and every other path were dropped. `components` was pruned to the transitive closure of the referenced schemas and responses (including `discriminator.mapping` targets, so every polymorphic subtype such as the `*UpdateAction` variants survives; the mappings of the generic `Reference`, `ResourceIdentifier`, `KeyReference` and `ErrorObject` families are not followed, as they span the whole API), plus the `oauth_2_0` security scheme: 260 schemas and 8 responses. Items 1 and 2 are scripted: `python3 docs/resources/script.py` downloads the source spec (cached beside the script as `commercetools-openapi.yaml`, untracked; drop a local copy there if the download fails) and rewrites `docs/spec/openapi.yaml`. Re-running it drops items 3 onward (3 to 10), which must be re-applied after it.

2. **Prune dangling discriminator mappings.** `Reference` keeps `cart-discount`, `category`, `channel`, `customer`, `customer-group`, `discount-group`, `product`, `product-discount`, `product-type`, `recurrence-policy`, `state`, `tax-category`, `type` and `variant`; `ResourceIdentifier` keeps `cart-discount`, `channel`, `discount-group`, `product`, `recurrence-policy`, `store` and `type`; `KeyReference` keeps `store`. The `discriminator` of `ErrorObject` was removed because none of its targets survive.

3. **Remove a bogus required property from `ErrorObject`.** The `required` list contained `//` (from a comment in the vendor's source definition). It was removed so the schema only requires `code` and `message`.

4. **Replace the templated server URL with a concrete one.** `https://api.{region}.commercetools.com` was replaced by `https://api.us-central1.gcp.commercetools.com`, so the generated client has a matching default `serviceUrl`.

5. **Match the token URL region to the server.** `securitySchemes.oauth_2_0.flows.clientCredentials.tokenUrl` was changed from `https://auth.europe-west1.gcp.commercetools.com/oauth/token` to `https://auth.us-central1.gcp.commercetools.com/oauth/token`.

6. **Add missing operation summaries and generic response descriptions.** Every operation gained a one-line `summary` (for example "Query cart discounts", "Update a tax category by key"), and the generic `'200'`/`'201'` success descriptions were replaced with descriptions of the returned cart discount, discount code, product discount, tax category or paged list. The 12 inline request bodies also got a one-line description through the generator's description step on the aligned spec.

7. **Describe every inline parameter.** All 80 inline parameter definitions had no `description`, which made `bal build` warn about an undocumented parameter or field for each one. Each now has a description of its commercetools HTTP API meaning: path `projectKey` (12) "`key` of the Project.", `key` (3) and `ID` (4) the user-defined and system identifiers of the resource; query `expand` (29), `sort`, `limit`, `offset`, `withTotal` and `where` (4 each) the standard expansion, sorting, paging and predicate parameters, with the API defaults and maximums; the `/^var[.][a-zA-Z0-9]+$/` pattern parameter (4) the predicate input variables; `version` (7) the expected version for optimistic concurrency control; and `dataErasure` (1).

8. **Rename the by-ID path parameter to `id`.** The four `/{projectKey}/{cart-discounts|discount-codes|product-discounts|tax-categories}/{ID}` paths used `{ID}` / `name: ID`, which the align step turned into `iD`, so the 12 by-ID client methods took `string iD`. The path template and parameter name were renamed to `{id}` / `id` in `openapi.yaml`, so the methods take `id`. The parameter descriptions from item 7 are kept.

9. **Remove the regex-named `var.<name>` query parameter.** The four list operations (`GET` on `cart-discounts`, `discount-codes`, `product-discounts` and `tax-categories`) declared a query parameter named `/^var[.][a-zA-Z0-9]+$/` for the predicate input variables. It generated `@http:Query {name: "/^var[.][a-zA-Z0-9]+$/"} string[] slashCaretVarAZAZ09`, which sends the regex itself as the literal query key, so callers could never name their variables. The parameter was removed from `openapi.yaml` (the description of it in item 7 no longer applies). The generated `List*Queries` records are open, so predicate variables are passed as quoted `"var.<name>"` keys, and `getPathForQueryParam` sends every key of the record:

   ```ballerina
   pricingdiscount:ListCartDiscountsQueries q = {'where: ["code = :code"], "var.code": "SAVE10"};
   pricingdiscount:CartDiscountPagedQueryResponse res = check commercetools->listCartDiscounts(projectKey, {}, q);
   ```

   This sends `where=code%20%3D%20%3Acode&var.code=SAVE10`. A `string` value (or int, boolean, decimal) is sent as `var.code=SAVE10`; a `string[]` value is serialised as repeated keys (`var.code=a&var.code=b`), because form style with `explode: true` is the default for keys that are not in the encoding map. A named argument such as `'var\.code = ...` does not compile (undefined parameter), so the record form is the only one.

10. **Use integer types for `limit`, `offset` and `version`.** The query parameters `limit` and `offset` (4 list operations each) were `type: number, format: double`, and `version` (7 DELETE operations) was `type: number, format: double`, so the client took `decimal` values for counts and optimistic-concurrency versions. They are now `type: integer` with no `format`, so the generated `Queries` records have `int 'limit`, `int offset` and `int version`. A plain integer maps to Ballerina `int`, whereas `format: int32` would generate `int:Signed32`, which a plain `int` such as a configurable page size does not satisfy. The change was made in `openapi.yaml`.

## OpenAPI cli command

The following command was used to generate the Ballerina client from the OpenAPI specification. The command should be executed from the repository root directory.

```bash
bal openapi -i docs/spec/aligned_ballerina_openapi.json -o ballerina --mode client --client-methods remote --license docs/license.txt
```

Note: The license year is hardcoded to 2024, change if necessary.
