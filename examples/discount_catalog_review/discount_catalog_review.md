# Discount catalog review

This example lists the cart discounts, product discounts and discount codes of a commercetools Project and prints how many of each exist. It then checks that every active discount code refers only to cart discounts that exist and are active, and fails if one does not.

## Prerequisites

### 1. Create a commercetools API client

Follow the [Setup guide](https://github.com/ballerina-platform/module-ballerinax-commercetools.pricingdiscount/blob/main/ballerina/README.md#setup-guide) to obtain a client ID, client secret, auth URL, API URL and Project key. The API client needs the `view_cart_discounts`, `view_product_discounts` and `view_discount_codes` scopes.

### 2. Configuration

Create a `Config.toml` file in this example's directory with the following content:

```toml
clientId = "<client-id>"
clientSecret = "<client-secret>"
tokenUrl = "<auth-url>/oauth/token"
apiUrl = "<api-url>"
projectKey = "<project-key>"
pageSize = 50
```

The example only reads data. Cart discounts, product discounts and discount codes are each read page by page, `pageSize` (an integer greater than 0) at a time, until a short page is returned.

## Run the example

Execute the following command to run the example:

```bash
bal run
```
