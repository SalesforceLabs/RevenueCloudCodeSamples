public with sharing class ProductMentionsClassDescriptor {
 
    // @AuraEnabled annotation exposes the methods to Lightning Components and Flows
    @AuraEnabled
    public String product_name;
 
    @AuraEnabled
    public integer quantity; 
 
    // Define the structure of the Apex-Defined Variable
    public ProductMentionsClassDescriptor(
            String product_name,
            integer quantity
    ) {
        this.product_name = product_name;
        this.quantity = quantity;
    }
 
    // Required no-argument constructor
    public ProductMentionsClassDescriptor() {}
}