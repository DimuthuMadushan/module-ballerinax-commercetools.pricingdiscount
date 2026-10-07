// Creates a tax category with a German VAT rate, adds a French rate with a versioned
// update action, reads the category back to verify both rates, and optionally deletes it.

import ballerina/io;
import ballerinax/commercetools.pricingdiscount;

configurable string clientId = ?;
configurable string clientSecret = ?;
configurable string tokenUrl = ?;
configurable string apiUrl = ?;
configurable string projectKey = ?;
configurable string categoryName = ?;
configurable boolean applyChange = false;
configurable boolean deleteAfterwards = false;

public function main() returns error? {
    pricingdiscount:Client commercetools = check new ({
        auth: {
            tokenUrl,
            clientId,
            clientSecret
        }
    }, apiUrl);

    if !applyChange {
        io:println(string `Dry run: would create the tax category "${categoryName}" with a German and a French rate. Set applyChange = true to apply.`);
        return;
    }

    // Step 1: Create the tax category with a German rate
    pricingdiscount:TaxCategory created = check commercetools->createTaxCategory(projectKey, {
        name: categoryName,
        rates: [{name: "German VAT", amount: 0.19, country: "DE", includedInPrice: true}]
    });
    io:println(string `Created tax category ${created.id} (version ${created.version})`);

    // Step 2: Add the French rate against the version that was just returned
    pricingdiscount:TaxCategory updated = check commercetools->updateTaxCategoryById(projectKey, created.id, {
        version: created.version,
        actions: [
            {
                action: "addTaxRate",
                "taxRate": {name: "French VAT", amount: 0.2, country: "FR", includedInPrice: true}
            }
        ]
    });
    io:println(string `Updated to version ${updated.version}`);

    // Step 3: Read the category again and verify both rates are present
    pricingdiscount:TaxCategory verified = check commercetools->getTaxCategoryById(projectKey, created.id);
    string[] countries = verified.rates.map(rate => rate.country);
    if countries.indexOf("DE") is () || countries.indexOf("FR") is () {
        return error(string `Expected rates for DE and FR but found ${countries.toString()}`);
    }
    io:println(string `Verified rates for: ${countries.toString()}`);

    // Step 4: Remove the category again when requested
    if deleteAfterwards {
        pricingdiscount:TaxCategory deleted =
            check commercetools->deleteTaxCategoryById(projectKey, verified.id, version = verified.version);
        io:println(string `Deleted tax category ${deleted.id}`);
    }
}
