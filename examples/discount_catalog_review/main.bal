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
configurable decimal pageSize = 50;

public function main() returns error? {
    pricingdiscount:Client commercetools = check new ({
        auth: {
            tokenUrl,
            clientId,
            clientSecret
        }
    }, apiUrl);

    // Step 1: Collect all cart discounts, following the pages until a short page is returned
    pricingdiscount:CartDiscount[] cartDiscounts = [];
    decimal offset = 0;
    while true {
        pricingdiscount:CartDiscountPagedQueryResponse page =
            check commercetools->listCartDiscounts(projectKey, 'limit = pageSize, offset = offset);
        cartDiscounts.push(...page.results);
        if <decimal>page.results.length() < pageSize {
            break;
        }
        offset += pageSize;
    }
    map<boolean> activeCartDiscounts = {};
    foreach pricingdiscount:CartDiscount discount in cartDiscounts {
        activeCartDiscounts[discount.id] = discount.isActive;
    }
    io:println(string `Cart discounts: ${cartDiscounts.length()}`);

    // Step 2: Count the product discounts that are currently active
    pricingdiscount:ProductDiscountPagedQueryResponse productDiscounts =
        check commercetools->listProductDiscounts(projectKey, 'limit = pageSize);
    int activeProductDiscounts = productDiscounts.results.filter(d => d.isActive).length();
    io:println(string `Product discounts: ${productDiscounts.results.length()} (${activeProductDiscounts} active)`);

    // Step 3: Check that every active discount code refers to active cart discounts
    pricingdiscount:DiscountCodePagedQueryResponse discountCodes =
        check commercetools->listDiscountCodes(projectKey, 'limit = pageSize);
    string[] problems = [];
    foreach pricingdiscount:DiscountCode discountCode in discountCodes.results {
        if !discountCode.isActive {
            continue;
        }
        foreach pricingdiscount:CartDiscountReference reference in discountCode.cartDiscounts {
            if activeCartDiscounts[reference.id] != true {
                problems.push(string `Discount code ${discountCode.code} uses cart discount ${reference.id}, which is missing or inactive`);
            }
        }
    }
    io:println(string `Discount codes: ${discountCodes.results.length()}`);

    if problems.length() > 0 {
        foreach string problem in problems {
            io:println(problem);
        }
        return error(string `${problems.length()} discount code problem(s) found`);
    }
    io:println("All active discount codes refer to active cart discounts.");
}
