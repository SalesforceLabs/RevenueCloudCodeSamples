/*
 * Place Sales Transaction Invovable Apex Method
 * It will be used to create quote following PCM API
 */
public class PlaceSalesTransactionForSmartQuote {
    // Define Invocable method input
    public class Request {
        @InvocableVariable(label='Opportunity Id' description='The Opportunity Id used to retrieve Video Call records.' required=true)
        public String opportunityId;
        
        @InvocableVariable(label='SearchProductsRepresentationJson' description='SearchProductsRepresentationJson' required=true)
        public String searchProductsRepresentationJson;
    }

    // Define Invocable method output
    public class Result {
        @InvocableVariable(label='Quote Record' description='Quote Record' required=false)
        public Quote quote;
    }
    
    
    @InvocableMethod(label='Create Quote from Products' description='Create Quote from Products')
    public static List<Result> callPSTAPI_Post(List<Request> requestList) {
        // pricing, configuration and context setup
        RevSalesTrxn.PricingPreferenceEnum pricingPrefEnum = RevSalesTrxn.PricingPreferenceEnum.SYSTEM;
        RevSalesTrxn.ConfigurationExecutionEnum configurationExecutionEnum = RevSalesTrxn.ConfigurationExecutionEnum.SKIP;
        
        // get request for the quote creation
        Request request = requestList.get(0);

        // get Opportunity Id from request
        String opportunityId = request.opportunityId;
        String str = request.searchProductsRepresentationJson.trim();
        if (str.right(1) != ']') {
            str = str + ']';
        }
        
        // Get the SearchProductsRepresentations from PCM
        List<runtime_industries_cpq.SearchProductsRepresentation> searchProductsRepresentations = (List<runtime_industries_cpq.SearchProductsRepresentation>) JSON.deserialize(str, List<runtime_industries_cpq.SearchProductsRepresentation>.class);
        
        // the records to be created, include Quote, QuoteLineItems
        List<RevSalesTrxn.RecordWithReferenceRequest> listOfRecords = new List<RevSalesTrxn.RecordWithReferenceRequest>();
        
        // create Quote and add to listOfRecords
        addQuote2Records(listOfRecords, opportunityId);

        // QuoteLineItems Setup
        addQuoteLineItem2Records(listOfRecords, searchProductsRepresentations);
        
        // Convert list of records to graph
        RevSalesTrxn.GraphRequest graph = new RevSalesTrxn.GraphRequest('test',listOfRecords);

        // PST API Call
        RevSalesTrxn.PlaceSalesTransactionResponse resp = RevSalesTrxn.PlaceSalesTransactionExecutor.execute(graph, pricingPrefEnum, configurationExecutionEnum, new RevSalesTrxn.ConfigurationOptionsInput(), null);
        
        List<Result> results = new List<Result>();
        Result result = new Result();
        results.add(result);
                
        // Get Quote Id from resp, Get Quote Object from Quote Id, Assign Quote to Results
        if (resp.isSuccess == true) {
            String quoteId = resp.salesTransactionId;
            Quote quote = [SELECT Id, Name FROM Quote WHERE Id =: quoteId].get(0);
            result.quote = quote;
        }
        
        
        return results;
    }
    
    /* 
     * Create and add Quote to list of records
     */
    private static void addQuote2Records (List<RevSalesTrxn.RecordWithReferenceRequest> listOfRecords, String opportunityId) {
        String quoteName = 'Quote From Conversation';
        String pricebook2Id = getPricebook2Id(opportunityId);
        
        System.debug('PriceBook is ' + pricebook2Id);
        
        // Quote Setup 
        RevSalesTrxn.RecordResource quoteRecord = new RevSalesTrxn.RecordResource(Quote.getSobjectType(),'POST');
        Map<String,Object> quoteFieldValues = new Map<String,Object>();
        quoteFieldValues.put('Name', quoteName);
        quoteFieldValues.put('Pricebook2Id', pricebook2Id);
        quoteFieldValues.put('OpportunityId', opportunityId);
        quoteRecord.fieldValues = quoteFieldValues;
        RevSalesTrxn.RecordWithReferenceRequest quoteRecordReference = new RevSalesTrxn.RecordWithReferenceRequest('refQuote',quoteRecord);
        
        // Add quoteRecord to list to be inserted.
        listOfRecords.add(quoteRecordReference);
    }
    
    /*
     * Create and add QuoteLineItem to list of records
     */
    private static void addQuoteLineItem2Records(List<RevSalesTrxn.RecordWithReferenceRequest> listOfRecords, List<runtime_industries_cpq.SearchProductsRepresentation> searchProductsRepresentations) {
        // Iterate each product representation
        for (Integer i = 0; i < searchProductsRepresentations.size(); i++) {
            runtime_industries_cpq.SearchProductsRepresentation searchProductsRepresentation = searchProductsRepresentations.get(i);
            
            // if no price information, skip this product
            if (searchProductsRepresentation.prices.size() == 0) {
                continue;
            }
            
            // Get productId, used to create qli
            String productId = searchProductsRepresentation.id;
            // Get pricesOutputRepresentation from searchProductsRepresentation
            runtime_industries_cpq.ProductPricesOutputRepresentation pricesOutputRepresentation;
            for (runtime_industries_cpq.ProductPricesOutputRepresentation price : searchProductsRepresentation.prices) {
                if (price.isDefault == true) {
                    pricesOutputRepresentation = price;
                    break;
                }
            }
            
            // if no psm defined, pick the first price.
            if (pricesOutputRepresentation == null) {
                pricesOutputRepresentation = searchProductsRepresentation.prices.get(0);
            }
            
            String pricingModelType = pricesOutputRepresentation.pricingModel.pricingModelType;
        
            RevSalesTrxn.RecordResource quoteLineItemRecord = new RevSalesTrxn.RecordResource(QuoteLineItem.getSobjectType(),'POST');
            Map<String,Object> quoteLineItemFieldValues = new Map<String,Object>();
            quoteLineItemFieldValues.put('QuoteId','@{refQuote.id}');
            quoteLineItemFieldValues.put('Product2Id', productId);
            quoteLineItemFieldValues.put('PricebookEntryId', pricesOutputRepresentation.priceBookEntryId);
            quoteLineItemFieldValues.put('Quantity', searchProductsRepresentation.description);
            quoteLineItemFieldValues.put('UnitPrice', pricesOutputRepresentation.price);
            
            if (pricingModelType == 'TermDefined') {
                quoteLineItemFieldValues.put('StartDate', Date.today().year() + '-' + Date.today().month() + '-' + Date.today().day());
                quoteLineItemFieldValues.put('SubscriptionTerm', 1);
                quoteLineItemFieldValues.put('PeriodBoundary', 'Anniversary');
                quoteLineItemFieldValues.put('SubscriptionTermUnit', pricesOutputRepresentation.pricingModel.frequency);
            }
            
            
            quoteLineItemRecord.fieldValues = quoteLineItemFieldValues;
            RevSalesTrxn.RecordWithReferenceRequest quoteLineItemRecordReference = new RevSalesTrxn.RecordWithReferenceRequest('refQuoteItem' + i, quoteLineItemRecord);
            
            listOfRecords.add(quoteLineItemRecordReference);
        }
    }
    
    /*
     * Get Pricebook2 Id from opportunity or standard Pricebook2
     */
    private static String getPricebook2Id(String opportunityId) {
        // Get standard Pricebook2 Id
        String standardPB2Id = [SELECT Id FROM Pricebook2 WHERE isStandard = true].Id;
        
        if (opportunityId == null) {
            return standardPB2Id;
        }
        
        // Get Opportunity's Pricebook Id
        String pb2Id = [SELECT Id, Pricebook2Id FROM Opportunity WHERE Id =: opportunityId].get(0).Pricebook2Id;
        
        if (String.isEmpty(pb2Id) || String.isBlank(pb2Id)) {
            return standardPB2Id;
        }
        
        return pb2Id;
    }
}