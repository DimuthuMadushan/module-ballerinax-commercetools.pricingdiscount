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

const string MISSING_ID = "missing-id";
const int STALE_VERSION = 999;

// A path segment is either an ID or `key=<key>`.
function isMissing(string idOrKey) returns boolean => idOrKey == MISSING_ID || idOrKey == "key=" + MISSING_ID;

function keyOf(string idOrKey) returns string? {
    if idOrKey.startsWith("key=") {
        return idOrKey.substring(4);
    }
    return ();
}

function cartDiscountFor(string idOrKey) returns CartDiscount {
    string? k = keyOf(idOrKey);
    return mockCartDiscount(k is () ? idOrKey : "cd-1001", k);
}

function productDiscountFor(string idOrKey) returns ProductDiscount {
    string? k = keyOf(idOrKey);
    return mockProductDiscount(k is () ? idOrKey : "pd-3001", k);
}

function taxCategoryFor(string idOrKey) returns TaxCategory {
    string? k = keyOf(idOrKey);
    return mockTaxCategory(k is () ? idOrKey : "tc-4001", k);
}

function mockCartDiscount(string id, string? 'key = ()) returns CartDiscount => {
    id,
    'key: 'key ?: "summer-sale",
    version: 3,
    createdAt: "2025-03-01T08:15:00.000Z",
    lastModifiedAt: "2025-03-10T10:20:30.000Z",
    name: {"en": "Summer Sale", "de": "Sommerschlussverkauf"},
    description: {"en": "10% off all items in the cart"},
    value: {'type: "relative", "permyriad": 1000},
    cartPredicate: "totalPrice > \"50.00 EUR\"",
    target: {'type: "lineItems", "predicate": "true"},
    sortOrder: "0.4",
    isActive: true,
    requiresDiscountCode: false,
    stackingMode: "Stacking",
    validFrom: "2025-06-01T00:00:00.000Z",
    validUntil: "2025-09-01T00:00:00.000Z",
    references: [],
    stores: [{typeId: "store", 'key: "berlin-store"}],
    recurringOrderScope: {'type: "anyOrder"}
};

function mockDiscountCode(string id) returns DiscountCode => {
    id,
    'key: "summer-code",
    version: 2,
    createdAt: "2025-03-01T08:15:00.000Z",
    lastModifiedAt: "2025-03-05T09:00:00.000Z",
    code: "SUMMER10",
    name: {"en": "Summer code"},
    description: {"en": "Ten percent off in summer"},
    cartDiscounts: [{typeId: "cart-discount", id: "cd-1001"}],
    cartPredicate: "true",
    isActive: true,
    maxApplications: 500,
    maxApplicationsPerCustomer: 1,
    groups: ["summer"],
    references: [],
    stores: [],
    validFrom: "2025-06-01T00:00:00.000Z",
    validUntil: "2025-09-01T00:00:00.000Z"
};

function mockProductDiscount(string id, string? 'key = ()) returns ProductDiscount => {
    id,
    'key: 'key ?: "spring-shoes",
    version: 4,
    createdAt: "2025-02-11T07:45:00.000Z",
    lastModifiedAt: "2025-02-20T12:30:00.000Z",
    name: {"en": "Spring shoes"},
    description: {"en": "15% off selected shoes"},
    value: {'type: "relative", "permyriad": 1500},
    predicate: "sku = \"SHOE-42\"",
    sortOrder: "0.3",
    isActive: true,
    references: [],
    validFrom: "2025-03-01T00:00:00.000Z",
    validUntil: "2025-05-31T23:59:59.000Z"
};

function mockTaxCategory(string id, string? 'key = ()) returns TaxCategory => {
    id,
    'key: 'key ?: "standard-tax",
    version: 1,
    createdAt: "2025-01-10T09:00:00.000Z",
    lastModifiedAt: "2025-01-10T09:00:00.000Z",
    name: "Standard tax",
    description: "Standard VAT rates",
    rates: [
        {name: "19% VAT", amount: 0.19, country: "DE", includedInPrice: true, id: "rate-de"},
        {name: "20% VAT", amount: 0.2, country: "FR", includedInPrice: true, id: "rate-fr"}
    ]
};

listener http:Listener ep0 = new (9090);

service / on ep0 {
    # Delete a cart discount by ID, or by key when the path segment is `key=<key>`
    #
    # + projectKey - Key of the commercetools project
    # + id - ID of the cart discount, or `key=<key>`
    # + version - Last seen version of the resource
    # + expand - Reference expansion paths
    # + return - The deleted cart discount, or an error response
    resource function delete [string projectKey]/cart\-discounts/[string id](int version, string[]? expand)
            returns CartDiscount|ErrorResponseConflict|http:NotFound {
        if isMissing(id) {
            return http:NOT_FOUND;
        }
        if version == STALE_VERSION {
            return <ErrorResponseConflict>{body: staleVersionError()};
        }
        return cartDiscountFor(id);
    }

    # Delete a discount code by ID
    #
    # + projectKey - Key of the commercetools project
    # + id - ID of the discount code
    # + dataErasure - Whether to delete personal data related to the code
    # + version - Last seen version of the resource
    # + expand - Reference expansion paths
    # + return - The deleted discount code, or an error response
    resource function delete [string projectKey]/discount\-codes/[string id](boolean? dataErasure, int version,
            string[]? expand) returns DiscountCode|ErrorResponseConflict|http:NotFound {
        if id == MISSING_ID {
            return http:NOT_FOUND;
        }
        if version == STALE_VERSION {
            return <ErrorResponseConflict>{body: staleVersionError()};
        }
        return mockDiscountCode(id);
    }

    # Delete a product discount by ID
    #
    # + projectKey - Key of the commercetools project
    # + id - ID of the product discount
    # + version - Last seen version of the resource
    # + expand - Reference expansion paths
    # + return - The deleted product discount, or an error response
    resource function delete [string projectKey]/product\-discounts/[string id](int version, string[]? expand)
            returns ProductDiscount|ErrorResponseConflict|http:NotFound {
        if id == MISSING_ID {
            return http:NOT_FOUND;
        }
        if version == STALE_VERSION {
            return <ErrorResponseConflict>{body: staleVersionError()};
        }
        return mockProductDiscount(id);
    }

    # Delete a tax category by ID
    #
    # + projectKey - Key of the commercetools project
    # + id - ID of the tax category
    # + version - Last seen version of the resource
    # + expand - Reference expansion paths
    # + return - The deleted tax category, or an error response
    resource function delete [string projectKey]/tax\-categories/[string id](int version, string[]? expand)
            returns TaxCategory|ErrorResponseConflict|http:NotFound {
        if id == MISSING_ID {
            return http:NOT_FOUND;
        }
        if version == STALE_VERSION {
            return <ErrorResponseConflict>{body: staleVersionError()};
        }
        return mockTaxCategory(id);
    }

    # Query cart discounts
    #
    # + projectKey - Key of the commercetools project
    # + expand - Reference expansion paths
    # + sort - Sort expressions
    # + 'limit - Maximum number of results
    # + offset - Number of results to skip
    # + withTotal - Whether to include the total count
    # + 'where - Query predicates
    # + return - A paged list of cart discounts
    resource function get [string projectKey]/cart\-discounts(string[]? expand, string[]? sort, int? 'limit,
            int? offset, boolean? withTotal, string[]? 'where)
            returns CartDiscountPagedQueryResponse {
        return {
            total: 2,
            offset: 0,
            'limit: 20,
            count: 2,
            results: [mockCartDiscount("cd-1001"), mockCartDiscount("cd-1002", "winter-sale")]
        };
    }

    # Get a cart discount by ID, or by key when the path segment is `key=<key>`
    #
    # + projectKey - Key of the commercetools project
    # + id - ID of the cart discount, or `key=<key>`
    # + expand - Reference expansion paths
    # + return - The cart discount, or an error response
    resource function get [string projectKey]/cart\-discounts/[string id](string[]? expand)
            returns CartDiscount|http:NotFound {
        if isMissing(id) {
            return http:NOT_FOUND;
        }
        return cartDiscountFor(id);
    }

    # Query discount codes
    #
    # + projectKey - Key of the commercetools project
    # + expand - Reference expansion paths
    # + sort - Sort expressions
    # + 'limit - Maximum number of results
    # + offset - Number of results to skip
    # + withTotal - Whether to include the total count
    # + 'where - Query predicates
    # + return - A paged list of discount codes
    resource function get [string projectKey]/discount\-codes(string[]? expand, string[]? sort, int? 'limit,
            int? offset, boolean? withTotal, string[]? 'where)
            returns DiscountCodePagedQueryResponse {
        return {
            total: 1,
            offset: 0,
            'limit: 20,
            count: 1,
            results: [mockDiscountCode("dc-2001")]
        };
    }

    # Get a discount code by ID
    #
    # + projectKey - Key of the commercetools project
    # + id - ID of the discount code
    # + expand - Reference expansion paths
    # + return - The discount code, or an error response
    resource function get [string projectKey]/discount\-codes/[string id](string[]? expand)
            returns DiscountCode|http:NotFound {
        if id == MISSING_ID {
            return http:NOT_FOUND;
        }
        return mockDiscountCode(id);
    }

    # Query product discounts
    #
    # + projectKey - Key of the commercetools project
    # + expand - Reference expansion paths
    # + sort - Sort expressions
    # + 'limit - Maximum number of results
    # + offset - Number of results to skip
    # + withTotal - Whether to include the total count
    # + 'where - Query predicates
    # + return - A paged list of product discounts
    resource function get [string projectKey]/product\-discounts(string[]? expand, string[]? sort, int? 'limit,
            int? offset, boolean? withTotal, string[]? 'where)
            returns ProductDiscountPagedQueryResponse {
        return {
            total: 2,
            offset: 0,
            'limit: 20,
            count: 2,
            results: [mockProductDiscount("pd-3001"), mockProductDiscount("pd-3002", "autumn-boots")]
        };
    }

    # Get a product discount by ID, or by key when the path segment is `key=<key>`
    #
    # + projectKey - Key of the commercetools project
    # + id - ID of the product discount, or `key=<key>`
    # + expand - Reference expansion paths
    # + return - The product discount, or an error response
    resource function get [string projectKey]/product\-discounts/[string id](string[]? expand)
            returns ProductDiscount|http:NotFound {
        if isMissing(id) {
            return http:NOT_FOUND;
        }
        return productDiscountFor(id);
    }

    # Query tax categories
    #
    # + projectKey - Key of the commercetools project
    # + expand - Reference expansion paths
    # + sort - Sort expressions
    # + 'limit - Maximum number of results
    # + offset - Number of results to skip
    # + withTotal - Whether to include the total count
    # + 'where - Query predicates
    # + return - A paged list of tax categories
    resource function get [string projectKey]/tax\-categories(string[]? expand, string[]? sort, int? 'limit,
            int? offset, boolean? withTotal, string[]? 'where)
            returns TaxCategoryPagedQueryResponse {
        return {
            total: 2,
            offset: 0,
            'limit: 20,
            count: 2,
            results: [mockTaxCategory("tc-4001"), mockTaxCategory("tc-4002", "reduced-tax")]
        };
    }

    # Get a tax category by ID, or by key when the path segment is `key=<key>`
    #
    # + projectKey - Key of the commercetools project
    # + id - ID of the tax category, or `key=<key>`
    # + expand - Reference expansion paths
    # + return - The tax category, or an error response
    resource function get [string projectKey]/tax\-categories/[string id](string[]? expand)
            returns TaxCategory|http:NotFound {
        if isMissing(id) {
            return http:NOT_FOUND;
        }
        return taxCategoryFor(id);
    }

    # Create a cart discount
    #
    # + projectKey - Key of the commercetools project
    # + expand - Reference expansion paths
    # + payload - Cart discount draft to create
    # + return - The created cart discount
    resource function post [string projectKey]/cart\-discounts(string[]? expand,
            @http:Payload CartDiscountDraft payload) returns CartDiscount {
        CartDiscount created = mockCartDiscount("cd-1003", payload.'key);
        created.name = payload.name;
        created.cartPredicate = payload.cartPredicate;
        created.version = 1;
        return created;
    }

    # Update a cart discount by ID
    #
    # + projectKey - Key of the commercetools project
    # + id - ID of the cart discount
    # + expand - Reference expansion paths
    # + payload - Version and update actions for the cart discount
    # + return - The updated cart discount, or an error response
    resource function post [string projectKey]/cart\-discounts/[string id](string[]? expand,
            @http:Payload CartDiscountUpdate payload) returns CartDiscountOk|ErrorResponseConflict|http:NotFound {
        if id == MISSING_ID {
            return http:NOT_FOUND;
        }
        if payload.version == STALE_VERSION {
            return <ErrorResponseConflict>{body: staleVersionError()};
        }
        CartDiscount updated = mockCartDiscount(id);
        updated.version = payload.version + 1;
        return <CartDiscountOk>{body: updated};
    }

    # Create a discount code
    #
    # + projectKey - Key of the commercetools project
    # + expand - Reference expansion paths
    # + payload - Discount code draft to create
    # + return - The created discount code
    resource function post [string projectKey]/discount\-codes(string[]? expand,
            @http:Payload DiscountCodeDraft payload) returns DiscountCode {
        DiscountCode created = mockDiscountCode("dc-2002");
        created.code = payload.code;
        created.version = 1;
        return created;
    }

    # Update a discount code by ID
    #
    # + projectKey - Key of the commercetools project
    # + id - ID of the discount code
    # + expand - Reference expansion paths
    # + payload - Version and update actions for the discount code
    # + return - The updated discount code, or an error response
    resource function post [string projectKey]/discount\-codes/[string id](string[]? expand,
            @http:Payload DiscountCodeUpdate payload) returns DiscountCodeOk|ErrorResponseConflict|http:NotFound {
        if id == MISSING_ID {
            return http:NOT_FOUND;
        }
        if payload.version == STALE_VERSION {
            return <ErrorResponseConflict>{body: staleVersionError()};
        }
        DiscountCode updated = mockDiscountCode(id);
        updated.version = payload.version + 1;
        return <DiscountCodeOk>{body: updated};
    }

    # Create a product discount
    #
    # + projectKey - Key of the commercetools project
    # + expand - Reference expansion paths
    # + payload - Product discount draft to create
    # + return - The created product discount
    resource function post [string projectKey]/product\-discounts(string[]? expand,
            @http:Payload ProductDiscountDraft payload) returns ProductDiscount {
        ProductDiscount created = mockProductDiscount("pd-3003", payload.'key);
        created.name = payload.name;
        created.predicate = payload.predicate;
        created.version = 1;
        return created;
    }

    # Update a product discount by ID
    #
    # + projectKey - Key of the commercetools project
    # + id - ID of the product discount
    # + expand - Reference expansion paths
    # + payload - Version and update actions for the product discount
    # + return - The updated product discount, or an error response
    resource function post [string projectKey]/product\-discounts/[string id](string[]? expand,
            @http:Payload ProductDiscountUpdate payload)
            returns ProductDiscountOk|ErrorResponseConflict|http:NotFound {
        if id == MISSING_ID {
            return http:NOT_FOUND;
        }
        if payload.version == STALE_VERSION {
            return <ErrorResponseConflict>{body: staleVersionError()};
        }
        ProductDiscount updated = mockProductDiscount(id);
        updated.version = payload.version + 1;
        return <ProductDiscountOk>{body: updated};
    }

    # Get the product discount matching a product price
    #
    # + projectKey - Key of the commercetools project
    # + payload - Product and price to match against product discounts
    # + return - The matching product discount, or an error response
    resource function post [string projectKey]/product\-discounts/matching(
            @http:Payload ProductDiscountMatchQuery payload) returns ProductDiscountOk|http:NotFound {
        if payload.productId == MISSING_ID {
            return http:NOT_FOUND;
        }
        return <ProductDiscountOk>{body: mockProductDiscount("pd-3001")};
    }

    # Create a tax category
    #
    # + projectKey - Key of the commercetools project
    # + expand - Reference expansion paths
    # + payload - Tax category draft to create
    # + return - The created tax category
    resource function post [string projectKey]/tax\-categories(string[]? expand,
            @http:Payload TaxCategoryDraft payload) returns TaxCategory {
        TaxCategory created = mockTaxCategory("tc-4003", payload.'key);
        created.name = payload.name;
        created.version = 1;
        return created;
    }

    # Update a tax category by ID
    #
    # + projectKey - Key of the commercetools project
    # + id - ID of the tax category
    # + expand - Reference expansion paths
    # + payload - Version and update actions for the tax category
    # + return - The updated tax category, or an error response
    resource function post [string projectKey]/tax\-categories/[string id](string[]? expand,
            @http:Payload TaxCategoryUpdate payload) returns TaxCategoryOk|ErrorResponseConflict|http:NotFound {
        if id == MISSING_ID {
            return http:NOT_FOUND;
        }
        if payload.version == STALE_VERSION {
            return <ErrorResponseConflict>{body: staleVersionError()};
        }
        TaxCategory updated = mockTaxCategory(id);
        updated.version = payload.version + 1;
        return <TaxCategoryOk>{body: updated};
    }
}

function staleVersionError() returns ErrorResponse => {
    statusCode: 409,
    message: "Object has a different version than expected.",
    errors: [{code: "ConcurrentModification", message: "Object has a different version than expected."}]
};

// Service-mode response types. `bal openapi --mode client` collapses 4XX/5XX
// to `error` and never emits these, so they are defined here for the mock only.
public type ErrorResponseConflict record {|
    *http:Conflict;
    ErrorResponse body;
|};

public type CartDiscountOk record {|
    *http:Ok;
    CartDiscount body;
|};

public type DiscountCodeOk record {|
    *http:Ok;
    DiscountCode body;
|};

public type ProductDiscountOk record {|
    *http:Ok;
    ProductDiscount body;
|};

public type TaxCategoryOk record {|
    *http:Ok;
    TaxCategory body;
|};

public type ErrorObject record {
    string code;
    string message;
};

public type ErrorResponse record {
    string message;
    ErrorObject[] errors?;
    int:Signed32 statusCode;
};
