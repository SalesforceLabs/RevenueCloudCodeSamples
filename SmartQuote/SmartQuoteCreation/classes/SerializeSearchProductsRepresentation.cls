public class SerializeSearchProductsRepresentation {
    // Define Invocable method input
    public class Request {        
        @InvocableVariable(label='List of SearchProductsRepresentation' description='List of SearchProductsRepresentation' required=true)
        public List<runtime_industries_cpq.SearchProductsRepresentation> searchProductsRepresentation;
    }

    // Define Invocable method output
    public class Result {
        @InvocableVariable(label='Json of SearchProductsRepresentation' description='Json of SearchProductsRepresentation' required=false)
        public String searchProductsRepresentationJson;
    }
    
    @InvocableMethod(label='doSerialization' description='doSerialization')
    public static List<Result> doSerialization(List<Request> requestList) {
    	List<runtime_industries_cpq.SearchProductsRepresentation> searchProductsRepresentation = requestList.get(0).searchProductsRepresentation;
                
        List<Result> results = new List<Result>();
        Result result = new Result();
        results.add(result);
        result.searchProductsRepresentationJson = JSON.serialize(searchProductsRepresentation);
        
        return results;
    }
}