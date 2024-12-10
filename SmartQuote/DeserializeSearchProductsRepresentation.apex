public class DeserializeSearchProductsRepresentation {
    // Define Invocable method output
    public class Request {
        @InvocableVariable(label='Json of SearchProductsRepresentation' description='Json of SearchProductsRepresentation' required=false)
        public String searchProductsRepresentationJson;
    }
    
    // Define Invocable method input
    public class Result {        
        @InvocableVariable(label='List of SearchProductsRepresentation' description='List of SearchProductsRepresentation' required=true)
        public List<runtime_industries_cpq.SearchProductsRepresentation> searchProductsRepresentation;
    }

    @InvocableMethod(label='doDeserialization' description='doDeserialization')
    public static List<Result> doSerialization(List<Request> requestList) {
        String searchProductsRepresentationJson = requestList.get(0).searchProductsRepresentationJson;
                
        List<Result> results = new List<Result>();
        Result result = new Result();
        results.add(result);
        result.searchProductsRepresentation = (List<runtime_industries_cpq.SearchProductsRepresentation>) JSON.deserialize(searchProductsRepresentationJson, List<runtime_industries_cpq.SearchProductsRepresentation>.class);
        
        return results;
    }
}