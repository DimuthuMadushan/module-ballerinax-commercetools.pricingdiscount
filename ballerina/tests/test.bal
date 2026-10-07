// Copyright (c) 2026, WSO2 LLC. (http://www.wso2.com).
//
// WSO2 LLC. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/http;
import ballerina/os;
import ballerina/test;

final boolean isLiveServer = os:getEnv("IS_LIVE_SERVER") == "true";
final string serviceUrl = isLiveServer ? os:getEnv("COMMERCETOOLS_SERVICE_URL") : "http://localhost:9090";
final string tokenUrl = isLiveServer ? os:getEnv("COMMERCETOOLS_TOKEN_URL") : "http://localhost:9444/oauth/token";
final string clientId = isLiveServer ? os:getEnv("COMMERCETOOLS_CLIENT_ID") : "test-client-id";
final string clientSecret = isLiveServer ? os:getEnv("COMMERCETOOLS_CLIENT_SECRET") : "test-client-secret";
final string projectKey = isLiveServer ? os:getEnv("COMMERCETOOLS_PROJECT_KEY") : "test-project";

// The mock token endpoint starts after module initialisation, so the client is created before the suite.
isolated Client? commercetoolsClient = ();

@test:BeforeSuite
function initClient() returns error? {
    Client c = check new ({
        auth: {
            tokenUrl,
            clientId,
            clientSecret
        },
        httpVersion: isLiveServer ? http:HTTP_2_0 : http:HTTP_1_1
    }, serviceUrl);
    lock {
        commercetoolsClient = c;
    }
}

isolated function getClient() returns Client|error {
    lock {
        Client? c = commercetoolsClient;
        if c is Client {
            return c;
        }
    }
    return error("The client is not initialised");
}

const string CART_DISCOUNT_ID = "cd-1001";
const string CART_DISCOUNT_KEY = "summer-sale";
const string DISCOUNT_CODE_ID = "dc-2001";
const string PRODUCT_DISCOUNT_ID = "pd-3001";
const string PRODUCT_DISCOUNT_KEY = "spring-shoes";
const string TAX_CATEGORY_ID = "tc-4001";
const string TAX_CATEGORY_KEY = "standard-tax";

// Cart discounts

@test:Config {groups: ["live_tests", "mock_tests"]}
isolated function testListCartDiscounts() returns error? {
    Client commercetools = check getClient();
    CartDiscountPagedQueryResponse response = check commercetools->listCartDiscounts(projectKey, 'limit = 5);
    test:assertEquals(response.count, response.results.length());
    test:assertTrue(response.'limit > 0);
}

@test:Config {groups: ["mock_tests"]}
isolated function testCreateCartDiscount() returns error? {
    Client commercetools = check getClient();
    CartDiscount created = check commercetools->createCartDiscount(projectKey, {
        name: {"en": "Autumn Sale"},
        cartPredicate: "true",
        value: {'type: "relative", "permyriad": 500},
        sortOrder: "0.5"
    });
    test:assertEquals(created.name, {"en": "Autumn Sale"});
    test:assertEquals(created.version, 1);
}

@test:Config {groups: ["mock_tests"]}
isolated function testGetCartDiscountByKey() returns error? {
    Client commercetools = check getClient();
    CartDiscount discount = check commercetools->getCartDiscountByKey(projectKey, CART_DISCOUNT_KEY);
    test:assertEquals(discount.'key, CART_DISCOUNT_KEY);
}

@test:Config {groups: ["mock_tests"]}
isolated function testGetCartDiscountById() returns error? {
    Client commercetools = check getClient();
    CartDiscount discount = check commercetools->getCartDiscountById(projectKey, CART_DISCOUNT_ID);
    test:assertEquals(discount.id, CART_DISCOUNT_ID);
    test:assertTrue(discount.isActive);
}

@test:Config {groups: ["mock_tests"]}
isolated function testUpdateCartDiscountById() returns error? {
    Client commercetools = check getClient();
    CartDiscount updated = check commercetools->updateCartDiscountById(projectKey, CART_DISCOUNT_ID, {
        version: 3,
        actions: [{action: "changeIsActive", "isActive": false}]
    });
    test:assertEquals(updated.id, CART_DISCOUNT_ID);
    test:assertEquals(updated.version, 4);
}

@test:Config {groups: ["mock_tests"]}
isolated function testDeleteCartDiscountById() returns error? {
    Client commercetools = check getClient();
    CartDiscount created = check commercetools->createCartDiscount(projectKey, {
        name: {"en": "Delete me"},
        cartPredicate: "true",
        value: {'type: "relative", "permyriad": 500}
    });
    CartDiscount deleted = check commercetools->deleteCartDiscountById(projectKey, created.id, version = created.version);
    test:assertEquals(deleted.id, created.id);
}

@test:Config {groups: ["mock_tests"]}
isolated function testDeleteCartDiscountByKey() returns error? {
    Client commercetools = check getClient();
    CartDiscount created = check commercetools->createCartDiscount(projectKey, {
        'key: "key-to-delete",
        name: {"en": "Delete me by key"},
        cartPredicate: "true",
        value: {'type: "relative", "permyriad": 500}
    });
    CartDiscount deleted = check commercetools->deleteCartDiscountByKey(projectKey, created.'key ?: "key-to-delete", version = created.version);
    test:assertEquals(deleted.'key, "key-to-delete");
}

@test:Config {groups: ["mock_tests"]}
isolated function testCartDiscountVersionConflict() returns error? {
    Client commercetools = check getClient();
    CartDiscount|error result = commercetools->deleteCartDiscountById(projectKey, CART_DISCOUNT_ID, version = 999);
    test:assertTrue(result is error);
}

@test:Config {groups: ["mock_tests"]}
isolated function testGetMissingCartDiscount() returns error? {
    Client commercetools = check getClient();
    CartDiscount|error result = commercetools->getCartDiscountById(projectKey, "missing-id");
    test:assertTrue(result is error);
}

// Discount codes

@test:Config {groups: ["live_tests", "mock_tests"]}
isolated function testListDiscountCodes() returns error? {
    Client commercetools = check getClient();
    DiscountCodePagedQueryResponse response = check commercetools->listDiscountCodes(projectKey, 'limit = 5);
    test:assertEquals(response.count, response.results.length());
}

@test:Config {groups: ["mock_tests"]}
isolated function testCreateDiscountCode() returns error? {
    Client commercetools = check getClient();
    DiscountCode created = check commercetools->createDiscountCode(projectKey, {
        code: "AUTUMN5",
        cartDiscounts: [{typeId: "cart-discount", id: CART_DISCOUNT_ID}]
    });
    test:assertEquals(created.code, "AUTUMN5");
}

@test:Config {groups: ["mock_tests"]}
isolated function testGetDiscountCodeById() returns error? {
    Client commercetools = check getClient();
    DiscountCode code = check commercetools->getDiscountCodeById(projectKey, DISCOUNT_CODE_ID);
    test:assertEquals(code.id, DISCOUNT_CODE_ID);
    test:assertTrue(code.cartDiscounts.length() > 0);
}

@test:Config {groups: ["mock_tests"]}
isolated function testUpdateDiscountCodeById() returns error? {
    Client commercetools = check getClient();
    DiscountCode updated = check commercetools->updateDiscountCodeById(projectKey, DISCOUNT_CODE_ID, {
        version: 2,
        actions: [{action: "setMaxApplications", "maxApplications": 100}]
    });
    test:assertEquals(updated.version, 3);
}

@test:Config {groups: ["mock_tests"]}
isolated function testDeleteDiscountCodeById() returns error? {
    Client commercetools = check getClient();
    DiscountCode created = check commercetools->createDiscountCode(projectKey, {
        code: "DELETEME",
        cartDiscounts: [{typeId: "cart-discount", id: CART_DISCOUNT_ID}]
    });
    DiscountCode deleted = check commercetools->deleteDiscountCodeById(projectKey, created.id, version = created.version);
    test:assertEquals(deleted.id, created.id);
}

// Product discounts

@test:Config {groups: ["live_tests", "mock_tests"]}
isolated function testListProductDiscounts() returns error? {
    Client commercetools = check getClient();
    ProductDiscountPagedQueryResponse response = check commercetools->listProductDiscounts(projectKey, 'limit = 5);
    test:assertEquals(response.count, response.results.length());
}

@test:Config {groups: ["mock_tests"]}
isolated function testCreateProductDiscount() returns error? {
    Client commercetools = check getClient();
    ProductDiscount created = check commercetools->createProductDiscount(projectKey, {
        name: {"en": "Boots"},
        predicate: "sku = \"BOOT-1\"",
        sortOrder: "0.2",
        isActive: true,
        value: {'type: "relative", "permyriad": 2000}
    });
    test:assertEquals(created.name, {"en": "Boots"});
}

@test:Config {groups: ["mock_tests"]}
isolated function testGetProductDiscountByKey() returns error? {
    Client commercetools = check getClient();
    ProductDiscount discount = check commercetools->getProductDiscountByKey(projectKey, PRODUCT_DISCOUNT_KEY);
    test:assertEquals(discount.'key, PRODUCT_DISCOUNT_KEY);
}

@test:Config {groups: ["mock_tests"]}
isolated function testGetProductDiscountById() returns error? {
    Client commercetools = check getClient();
    ProductDiscount discount = check commercetools->getProductDiscountById(projectKey, PRODUCT_DISCOUNT_ID);
    test:assertEquals(discount.id, PRODUCT_DISCOUNT_ID);
}

@test:Config {groups: ["mock_tests"]}
isolated function testGetMatchingProductDiscount() returns error? {
    Client commercetools = check getClient();
    ProductDiscount discount = check commercetools->getMatchingProductDiscount(projectKey, {
        productId: "product-1",
        variantId: 1,
        staged: false,
        price: {value: {centAmount: 5000, currencyCode: "EUR"}}
    });
    test:assertEquals(discount.id, PRODUCT_DISCOUNT_ID);
}

@test:Config {groups: ["mock_tests"]}
isolated function testUpdateProductDiscountById() returns error? {
    Client commercetools = check getClient();
    ProductDiscount updated = check commercetools->updateProductDiscountById(projectKey, PRODUCT_DISCOUNT_ID, {
        version: 4,
        actions: [{action: "changeIsActive", "isActive": false}]
    });
    test:assertEquals(updated.version, 5);
}

@test:Config {groups: ["mock_tests"]}
isolated function testDeleteProductDiscountById() returns error? {
    Client commercetools = check getClient();
    ProductDiscount created = check commercetools->createProductDiscount(projectKey, {
        name: {"en": "Delete me"},
        predicate: "sku = \"DELETE-1\"",
        sortOrder: "0.2",
        isActive: false,
        value: {'type: "relative", "permyriad": 100}
    });
    ProductDiscount deleted = check commercetools->deleteProductDiscountById(projectKey, created.id, version = created.version);
    test:assertEquals(deleted.id, created.id);
}

// Tax categories

@test:Config {groups: ["live_tests", "mock_tests"]}
isolated function testListTaxCategories() returns error? {
    Client commercetools = check getClient();
    TaxCategoryPagedQueryResponse response = check commercetools->listTaxCategories(projectKey, 'limit = 5);
    test:assertEquals(response.count, response.results.length());
}

@test:Config {groups: ["mock_tests"]}
isolated function testCreateTaxCategory() returns error? {
    Client commercetools = check getClient();
    TaxCategory created = check commercetools->createTaxCategory(projectKey, {name: "Reduced tax"});
    test:assertEquals(created.name, "Reduced tax");
}

@test:Config {groups: ["mock_tests"]}
isolated function testGetTaxCategoryByKey() returns error? {
    Client commercetools = check getClient();
    TaxCategory category = check commercetools->getTaxCategoryByKey(projectKey, TAX_CATEGORY_KEY);
    test:assertEquals(category.'key, TAX_CATEGORY_KEY);
    test:assertTrue(category.rates.length() > 0);
}

@test:Config {groups: ["mock_tests"]}
isolated function testGetTaxCategoryById() returns error? {
    Client commercetools = check getClient();
    TaxCategory category = check commercetools->getTaxCategoryById(projectKey, TAX_CATEGORY_ID);
    test:assertEquals(category.id, TAX_CATEGORY_ID);
}

@test:Config {groups: ["mock_tests"]}
isolated function testUpdateTaxCategoryById() returns error? {
    Client commercetools = check getClient();
    TaxCategory updated = check commercetools->updateTaxCategoryById(projectKey, TAX_CATEGORY_ID, {
        version: 1,
        actions: [{action: "changeName", "name": "Standard VAT"}]
    });
    test:assertEquals(updated.version, 2);
}

@test:Config {groups: ["mock_tests"]}
isolated function testDeleteTaxCategoryById() returns error? {
    Client commercetools = check getClient();
    TaxCategory created = check commercetools->createTaxCategory(projectKey, {name: "Delete me"});
    TaxCategory deleted = check commercetools->deleteTaxCategoryById(projectKey, created.id, version = created.version);
    test:assertEquals(deleted.id, created.id);
}
