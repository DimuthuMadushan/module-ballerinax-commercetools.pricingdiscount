// Reviews the discounts configured in a commercetools Project: lists the cart
// discounts, product discounts and discount codes, and fails when an active
// discount code points at a cart discount that is not active.

import ballerina/io;
import ballerinax/commercetools.pricingdiscount;

configurable string clientId = ?;
configurable string clientSecret = ?;
configurable string tokenUrl = ?;
configurable string apiUrl = ?;
configurable string projectKey = ?;
configurable int pageSize = 50;

public function main() returns error? {
    if pageSize <= 0 {
        return error(string `pageSize must be greater than 0, but was ${pageSize}`);
    }

    pricingdiscount:Client commercetools = check new ({
        auth: {
            tokenUrl,
            clientId,
            clientSecret
        }
    }, apiUrl);

    // Step 1: Collect all cart discounts, following the pages until a short page is returned
    pricingdiscount:CartDiscount[] cartDiscounts = [];
    int offset = 0;
    while true {
        pricingdiscount:CartDiscountPagedQueryResponse page =
            check commercetools->listCartDiscounts(projectKey, 'limit = pageSize, offset = offset);
        cartDiscounts.push(...page.results);
        if page.results.length() < pageSize {
            break;
        }
        offset += pageSize;
    }
    map<boolean> activeCartDiscounts = {};
    foreach pricingdiscount:CartDiscount discount in cartDiscounts {
        activeCartDiscounts[discount.id] = discount.isActive;
    }
    io:println(string `Cart discounts: ${cartDiscounts.length()}`);

    // Step 2: Collect all product discounts and count the ones that are currently active
    pricingdiscount:ProductDiscount[] productDiscounts = [];
    offset = 0;
    while true {
        pricingdiscount:ProductDiscountPagedQueryResponse page =
            check commercetools->listProductDiscounts(projectKey, 'limit = pageSize, offset = offset);
        productDiscounts.push(...page.results);
        if page.results.length() < pageSize {
            break;
        }
        offset += pageSize;
    }
    int activeProductDiscounts = productDiscounts.filter(d => d.isActive).length();
    io:println(string `Product discounts: ${productDiscounts.length()} (${activeProductDiscounts} active)`);

    // Step 3: Collect all discount codes and check that every active one refers to active cart discounts
    pricingdiscount:DiscountCode[] discountCodes = [];
    offset = 0;
    while true {
        pricingdiscount:DiscountCodePagedQueryResponse page =
            check commercetools->listDiscountCodes(projectKey, 'limit = pageSize, offset = offset);
        discountCodes.push(...page.results);
        if page.results.length() < pageSize {
            break;
        }
        offset += pageSize;
    }
    string[] problems = [];
    foreach pricingdiscount:DiscountCode discountCode in discountCodes {
        if !discountCode.isActive {
            continue;
        }
        foreach pricingdiscount:CartDiscountReference reference in discountCode.cartDiscounts {
            if activeCartDiscounts[reference.id] != true {
                problems.push(string `Discount code ${discountCode.code} uses cart discount ${reference.id}, which is missing or inactive`);
            }
        }
    }
    io:println(string `Discount codes: ${discountCodes.length()}`);

    if problems.length() > 0 {
        foreach string problem in problems {
            io:println(problem);
        }
        return error(string `${problems.length()} discount code problem(s) found`);
    }
    io:println("All active discount codes refer to active cart discounts.");
}
