/*
 * Parse ParseSearchProductRepresentationJson to apex defined class
 */
public class ParseSearchProductRepresentationJson {
    // Define Invocable method input
    public class Request {        
        @InvocableVariable(label='SearchProductsRepresentationJson' description='SearchProductsRepresentationJson' required=true)
        public String searchProductsRepresentationJson;
    }

    // Define Invocable method output
    public class Result {
        @InvocableVariable(label='SearchProductsRepresentation' description='SearchProductsRepresentation' required=false)
        public List<runtime_industries_cpq.SearchProductsRepresentation> searchProductsRepresentations;
    }
    
    
    @InvocableMethod(label='Parse Json to SearchProductsRepresentation' description='Parse Json to SearchProductsRepresentation')
    public static List<Result> parse(List<Request> requestList) {
        // pricing, configuration and context setup
        RevSalesTrxn.PricingPreferenceEnum pricingPrefEnum = RevSalesTrxn.PricingPreferenceEnum.SYSTEM;
        RevSalesTrxn.ConfigurationExecutionEnum configurationExecutionEnum = RevSalesTrxn.ConfigurationExecutionEnum.SKIP;
        
        // get request for the quote creation
        Request request = requestList.get(0);

        String str = request.searchProductsRepresentationJson.trim();
        System.debug('Check String ' + str.right(1));
        if (str.right(1) != ']') {
            str = str + ']';
        }
        System.debug('Check String ' + str.right(5));
        
        // Get the SearchProductsRepresentations from PCM
        List<runtime_industries_cpq.SearchProductsRepresentation> searchProductsRepresentations = (List<runtime_industries_cpq.SearchProductsRepresentation>) JSON.deserialize(str, List<runtime_industries_cpq.SearchProductsRepresentation>.class);
        
        List<Result> results = new List<Result>();
        Result result = new Result();
        results.add(result);
        
        result.searchProductsRepresentations = searchProductsRepresentations;
        
        System.debug('parse is done, size is ' + searchProductsRepresentations.size());
        return results;
    }
}