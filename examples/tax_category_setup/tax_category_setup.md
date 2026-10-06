# Tax category setup

This example creates a tax category with a German VAT rate, adds a French VAT rate with a versioned `addTaxRate` update action, reads the category again to verify both rates, and can delete the category afterwards.

## Prerequisites

### 1. Create a commercetools API client

Follow the [Setup guide](https://github.com/ballerina-platform/module-ballerinax-commercetools.pricingdiscount/blob/main/ballerina/README.md#setup-guide) to obtain a client ID, client secret, auth URL, API URL and Project key. The API client needs the `view_tax_categories` and `manage_tax_categories` scopes.

### 2. Configuration

Create a `Config.toml` file in this example's directory with the following content:

```toml
clientId = "<client-id>"
clientSecret = "<client-secret>"
tokenUrl = "<auth-url>/oauth/token"
apiUrl = "<api-url>"
projectKey = "<project-key>"
categoryName = "<tax-category-name>"
applyChange = false
deleteAfterwards = false
```

Creating a tax category changes the Project, so the example only does so when `applyChange` is `true`. Otherwise it prints what it would create. Set `deleteAfterwards` to `true` to remove the category again after it has been verified.

## Run the example

Execute the following command to run the example:

```bash
bal run
```
