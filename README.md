# Ballerina Commercetools Pricing Discount connector

[![Build](https://github.com/ballerina-platform/module-ballerinax-commercetools.pricingdiscount/actions/workflows/ci.yml/badge.svg)](https://github.com/ballerina-platform/module-ballerinax-commercetools.pricingdiscount/actions/workflows/ci.yml)
[![GitHub Last Commit](https://img.shields.io/github/last-commit/ballerina-platform/module-ballerinax-commercetools.pricingdiscount.svg)](https://github.com/ballerina-platform/module-ballerinax-commercetools.pricingdiscount/commits/main)
[![GitHub Issues](https://img.shields.io/github/issues/ballerina-platform/ballerina-library/module/commercetools.pricingdiscount.svg?label=Open%20Issues)](https://github.com/ballerina-platform/ballerina-library/labels/module%2Fcommercetools.pricingdiscount)

## Overview

[commercetools](https://commercetools.com/) is a composable commerce platform that provides API-first building blocks for online storefronts, carts, orders, customers and catalogs. Its pricing and discount features let merchants run promotions on carts and products, issue discount codes, and manage the tax categories and rates used to price orders.

The commercetools Pricing and Discount connector lets Ballerina applications manage cart discounts, discount codes, product discounts and tax categories in a commercetools Project. It supports version 1 of the commercetools HTTP API.

## Setup guide

To use the commercetools Pricing and Discount connector, you need a commercetools Project and an API client that can access its discounts and tax categories. If you do not have a commercetools account, you can sign up for a trial [here](https://commercetools.com/free-trial).

### Step 1: Create an API client

1. Open the [Merchant Center](https://mc.commercetools.com/) and select your Project.

2. Go to **Settings** → **Developer settings** and select **Create new API client**.

3. Give the client a name and select the scopes for the resources you use: `view_cart_discounts` and `manage_cart_discounts`, `view_discount_codes` and `manage_discount_codes`, `view_product_discounts` and `manage_product_discounts`, and `view_tax_categories` and `manage_tax_categories`.

### Step 2: Note down the credentials

After the client is created, copy the following values. The client secret is shown only once.

* Project key
* Client ID
* Client secret
* Auth URL, for example `https://auth.europe-west1.gcp.commercetools.com`
* API URL, for example `https://api.europe-west1.gcp.commercetools.com`

The token URL is the auth URL followed by `/oauth/token`.

## Quickstart

To use the commercetools Pricing and Discount connector in your Ballerina application, update the `.bal` file as follows:

### Step 1: Import the module

Import the `commercetools.pricingdiscount` module.

```ballerina
import ballerinax/commercetools.pricingdiscount;
```

### Step 2: Instantiate a new connector

1. Create a `Config.toml` file and configure the credentials obtained in the steps above:

```toml
clientId = "<Client ID>"
clientSecret = "<Client Secret>"
tokenUrl = "<Auth URL>/oauth/token"
apiUrl = "<API URL>"
projectKey = "<Project key>"
```

2. Create a `pricingdiscount:ConnectionConfig` with the OAuth 2.0 client credentials and initialize the connector with it.

```ballerina
configurable string clientId = ?;
configurable string clientSecret = ?;
configurable string tokenUrl = ?;
configurable string apiUrl = ?;
configurable string projectKey = ?;

final pricingdiscount:Client commercetools = check new ({
    auth: {
        tokenUrl,
        clientId,
        clientSecret
    }
}, apiUrl);
```

### Step 3: Invoke the connector operation

Now, utilize the available connector operations.

#### List the cart discounts

```ballerina
public function main() returns error? {
    pricingdiscount:CartDiscountPagedQueryResponse _ = check commercetools->listCartDiscounts(projectKey);
}
```

### Step 4: Run the Ballerina application

```bash
bal run
```

## Examples

The commercetools Pricing and Discount connector provides practical examples illustrating usage in various scenarios. Explore these [examples](https://github.com/ballerina-platform/module-ballerinax-commercetools.pricingdiscount/tree/main/examples/), covering the following use cases:

1. [Discount catalog review](https://github.com/ballerina-platform/module-ballerinax-commercetools.pricingdiscount/tree/main/examples/discount_catalog_review) - List the cart discounts, product discounts and discount codes of a Project, and fail when an active discount code refers to a cart discount that is missing or inactive.

2. [Tax category setup](https://github.com/ballerina-platform/module-ballerinax-commercetools.pricingdiscount/tree/main/examples/tax_category_setup) - Create a tax category with a German rate, add a French rate with a versioned update action, verify both rates and optionally delete the category.

## Build from the source

### Setting up the prerequisites

1. Download and install Java SE Development Kit (JDK) version 21. You can download it from either of the following sources:

    * [Oracle JDK](https://www.oracle.com/java/technologies/downloads/)
    * [OpenJDK](https://adoptium.net/)

   > **Note:** After installation, remember to set the `JAVA_HOME` environment variable to the directory where JDK was installed.

2. Download and install [Ballerina Swan Lake](https://ballerina.io/).

3. Download and install [Docker](https://www.docker.com/get-started).

   > **Note**: Ensure that the Docker daemon is running before executing any tests.

4. Export Github Personal access token with read package permissions as follows,

    ```bash
    export packageUser=<Username>
    export packagePAT=<Personal access token>
    ```

### Build options

Execute the commands below to build from the source.

1. To build the package:

   ```bash
   ./gradlew clean build
   ```

2. To run the tests:

   ```bash
   ./gradlew clean test
   ```

3. To build the without the tests:

   ```bash
   ./gradlew clean build -x test
   ```

4. To run tests against different environments:

   ```bash
   ./gradlew clean test -Pgroups=<Comma separated groups/test cases>
   ```

5. To debug the package with a remote debugger:

   ```bash
   ./gradlew clean build -Pdebug=<port>
   ```

6. To debug with the Ballerina language:

   ```bash
   ./gradlew clean build -PbalJavaDebug=<port>
   ```

7. Publish the generated artifacts to the local Ballerina Central repository:

    ```bash
    ./gradlew clean build -PpublishToLocalCentral=true
    ```

8. Publish the generated artifacts to the Ballerina Central repository:

   ```bash
   ./gradlew clean build -PpublishToCentral=true
   ```

## Contribute to Ballerina

As an open-source project, Ballerina welcomes contributions from the community.

For more information, go to the [contribution guidelines](https://github.com/ballerina-platform/ballerina-lang/blob/master/CONTRIBUTING.md).

## Code of conduct

All the contributors are encouraged to read the [Ballerina Code of Conduct](https://ballerina.io/code-of-conduct).

## Useful links

* For more information go to the [`commercetools.pricingdiscount` package](https://central.ballerina.io/ballerinax/commercetools.pricingdiscount/latest).
* For example demonstrations of the usage, go to [Ballerina By Examples](https://ballerina.io/learn/by-example/).
* Chat live with us via our [Discord server](https://discord.gg/ballerinalang).
* Post all technical questions on Stack Overflow with the [#ballerina](https://stackoverflow.com/questions/tagged/ballerina) tag.
