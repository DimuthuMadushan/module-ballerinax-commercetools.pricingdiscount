# Examples

The `ballerinax/commercetools.pricingdiscount` connector provides practical examples illustrating usage in various scenarios.

1. **[Discount catalog review](https://github.com/ballerina-platform/module-ballerinax-commercetools.pricingdiscount/tree/main/examples/discount_catalog_review)** - List the cart discounts, product discounts and discount codes of a Project, and fail when an active discount code refers to a cart discount that is missing or inactive.

2. **[Tax category setup](https://github.com/ballerina-platform/module-ballerinax-commercetools.pricingdiscount/tree/main/examples/tax_category_setup)** - Create a tax category with a German rate, add a French rate with a versioned update action, verify both rates and optionally delete the category.

## Prerequisites

1. Create a commercetools API client as described in the [Setup guide](https://central.ballerina.io/ballerinax/commercetools.pricingdiscount/latest#setup-guide).

2. For each example, create a `Config.toml` file with the related configuration. Here's an example of how your Config.toml file should look:

```toml
clientId = "<client-id>"
clientSecret = "<client-secret>"
tokenUrl = "<auth-url>/oauth/token"
apiUrl = "<api-url>"
projectKey = "<project-key>"
```

Each example lists the additional values it needs in its own README.

## Running an example

Execute the following commands to build an example from the source:

* To build an example:

    ```bash
    bal build
    ```

* To run an example:

    ```bash
    bal run
    ```
