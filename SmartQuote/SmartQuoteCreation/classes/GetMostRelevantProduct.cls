public class GetMostRelevantProduct {
    // Define Invocable method input
    public class Request {
        @InvocableVariable(label='SearchProductsRepresentations' description='The SearchProductsRepresentation for one Product Mention' required=true)
        public List<runtime_industries_cpq.SearchProductsRepresentation> searchProductsRepresentations;
        
        @InvocableVariable(label='Product Mention' description='Product mention and quantity' required=true)
        public ProductMentionsClassDescriptor productMention;
      }

    // Define Invocable method output
    public class Result {
        @InvocableVariable(label='Product' description='Product' required=false)
        public Product2 product;
        
        @InvocableVariable(label='SearchProductsRepresentation' description='Product' required=false)
        public runtime_industries_cpq.SearchProductsRepresentation searchProductsRepresentation;
    }
    
    @InvocableMethod(label='Get the most Relevant Produt and SearchProductsRepresentation' description='Get the most Relevant Produt and SearchProductsRepresentatio')
    public static List<Result> getMostRelevantQLI(List<Request> requestList) {
        Request request = requestList.get(0);
        List<runtime_industries_cpq.SearchProductsRepresentation> searchProductsRepresentations = request.searchProductsRepresentations;
        ProductMentionsClassDescriptor productMention = request.productMention;

        String productId = searchProductsRepresentations.get(0).id;
        Product2 product = [SELECT Id, Name FROM PRODUCT2 WHERE Id =: productId].get(0);
        
        List<Result> results = new List<Result>();
        Result result = new Result();
        
        result.product = product;
        result.searchProductsRepresentation = searchProductsRepresentations.get(0);
        result.searchProductsRepresentation.description = String.valueOf(productMention.quantity);
        
        results.add(result);
        return results;
    }
}