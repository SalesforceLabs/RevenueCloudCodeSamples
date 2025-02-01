public class ParseProductMentionsJson {
    @InvocableMethod(label='Parse ProductMentions Json' description='Parse ProductMentions Json')
    public static List<Response> parseProductMentionsJson(List<Request> requests) {
        // The ParseProductMentionsJson is consumed by Flow
        // Suppose that Flow runs in batch.
        // So the Input and Output should be a List of data structure
        
        String jsonString = requests.get(0).productMentionsJson;
        
        // Since the output from ECI is like ```json[{&quot;product_name&quot;: &quot;Intermediate Subscription&quot;,&quot;quantity&quot;: 1}]```
        jsonString = jsonString.remove('```json');        // remove first ```json
        jsonString = jsonString.remove('```');            // remove last ```
        
        // deserialize jsonString to list of ProductMentionsClassDescriptor
        List<ProductMentionsClassDescriptor> productMentions = (List<ProductMentionsClassDescriptor>) JSON.deserialize(jsonString, List<ProductMentionsClassDescriptor>.class); 
        
        // responses is for batch running return
        List<Response> responses = new List<Response>();
        // response is for single class call
        Response response = new Response();
        response.productMentions = productMentions;
        // add single return to batch running return
        responses.add(response);
        
        return responses;
    }
    
    public class Request {
        @InvocableVariable(label='Product Mentions Json' description='Product Mentions Json' required=true)
        public String productMentionsJson;
    }

    public class Response {
        @InvocableVariable(label='Parsed Product Mentions' description='Parse Product Mentions Json to list of ProductMentionsClassDescriptor Apex Defined Class' required=true)
        public List<ProductMentionsClassDescriptor> productMentions;
    }
}