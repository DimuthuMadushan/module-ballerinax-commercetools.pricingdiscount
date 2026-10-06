# Running Tests

## Prerequisites

By default the tests run against a mock commercetools server and a mock OAuth 2.0 token endpoint that start with `bal test`, so no credentials are needed.

To run the list tests against a real commercetools Project, create an API client with the `view_cart_discounts`, `view_discount_codes`, `view_product_discounts` and `view_tax_categories` scopes (see the [Setup guide](../README.md#setup-guide)) and set these environment variables:

| Variable | Description |
|---|---|
| `IS_LIVE_SERVER` | Set to `true` to use the real service |
| `COMMERCETOOLS_SERVICE_URL` | API URL, for example `https://api.europe-west1.gcp.commercetools.com` |
| `COMMERCETOOLS_TOKEN_URL` | Token URL, the auth URL followed by `/oauth/token` |
| `COMMERCETOOLS_CLIENT_ID` | API client ID |
| `COMMERCETOOLS_CLIENT_SECRET` | API client secret |
| `COMMERCETOOLS_PROJECT_KEY` | Key of the Project to query |

## Test approach

- The mock covers 25 of the 30 operations: list, create, get, update and delete for cart discounts, discount codes, product discounts and tax categories, plus the product discount match query. Get and delete by key are served by the same route as by ID, using a `key=<key>` path segment.
- The list tests belong to the `mock_tests` and `live_tests` groups. They only read, so they are safe against a real Project.
- Every other test belongs to the `mock_tests` group only, because it creates, changes or deletes data or relies on fixed mock IDs.
- Version-conflict (`409`) and not-found (`404`) cases are checked against the mock only.

## Running the tests

```bash
# Mock server (default)
bal test --groups mock_tests

# Live service (read-only list tests)
IS_LIVE_SERVER=true bal test --groups live_tests
```
