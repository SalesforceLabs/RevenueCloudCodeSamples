public with sharing class AssetManagementController {

    private static final Integer REVCLOUDAPILIMIT = Integer.valueOf(System.Label.RevCloudAPILimit);
    private static final String ORG_BASE_URL = URL.getSalesforceBaseUrl().getHost();
    
    /**
     * This is used for retreiving the Assets from Account which has HasLifecycleManagement is true
     * @param accountId
     * @return list of Assets with StartDate, EndDate and Renewal Fields
     */
    @AuraEnabled(cacheable=true)
    public static List<AssetInfo> getAssetsByAccount(String accountId){
        Map<Id, AssetInfo> assetInfoMap = new Map<Id, AssetInfo>();
        AssetInfo assetInfo;
        //First getting all the Assets of the Account and adding AssetInfo into the map
        for(Asset asset : [SELECT Id, Name, LifecycleStartDate, LifecycleEndDate, 
                            RenewalTerm, RenewalTermUnit, AccountId, CurrentQuantity, Product2Id
        FROM Asset Where AccountId =: accountId and HasLifecycleManagement = TRUE WITH SECURITY_ENFORCED Order By createdDate]){
            assetInfo = new AssetInfo();
            assetInfo.asset = asset;
            assetInfo.assetId = asset.Id;
            assetInfo.name = asset.name;
            assetInfo.lifeCycleStartDate = asset.LifecycleStartDate;
            assetInfo.lifeCycleEndDate = asset.LifecycleEndDate;
            assetInfo.renewalTerm = asset.RenewalTerm;
            assetInfo.renewalTermUnit = asset.RenewalTermUnit;
            assetInfo.recordURL = ORG_BASE_URL + '/'+ asset.Id;
            assetInfoMap.put(asset.Id, assetInfo);
        }

        //If there is a bundle to show the heirarchy, for every AssetInfo parent Id is required to generate the tree here
        //Using the relation to populate the parentId to the POJO AssetInfo.
        for(AssetRelationShip ars :  [SELECT Id, AssetId,  RelatedAssetid FROM AssetRelationship where Asset.AccountId =: accountId WITH SECURITY_ENFORCED Order By AssetId]){
            assetInfoMap.get(ars.RelatedAssetid).parentId = ars.AssetId;
        }
        return assetInfoMap.values();
    }

    /**
     * Used to call the SM Renew service through the Apex via Connect API
     * @param assetList list of assets to be renewed or cancelled
     * @return list of responses from the connectAPI output
     */
    
    @AuraEnabled
    public static List<AssetInfo> renewAssets(List<AssetInfo> assetList){
        Map<Id, AssetInfo> responseList = new Map<Id, AssetInfo>();
        Map<Id, AssetInfo> assetMap = new Map<Id, AssetInfo>();
        List<Id> assetIds = new List<String>();
        ConnectApi.RevenueAsyncRepresentation response;
        for(AssetInfo asset : assetList) {
            assetIds.add(asset.assetId);
            assetMap.put(asset.assetId, asset);
            System.debug('<<<< asset >>>'+asset.assetId);
            if(assetIds.size() == REVCLOUDAPILIMIT){
                response =  renewAssetsAPI(assetIds);
                responseList = addStatusURL(assetIds, assetMap, response);
                assetIds = new List<String>();
            }
        }
        if(!assetIds.isEmpty()){
            response = renewAssetsAPI(assetIds);
            responseList = addStatusURL(assetIds, assetMap, response);
        }
        System.debug('<<<<< responseList >>>>'+responseList);
        return responseList.values();
    }

    /**
     * Used to call the SM Cancel service through the Apex via Connect API
     * @param assetList list of assets to be renewed or cancelled
     * @param cancelDate Date for the Cancel Service,
     * @return list of responses from the connectAPI output
     */
    
    @AuraEnabled
    public static List<AssetInfo> cancelAssets(List<AssetInfo> assetList, Datetime cancelDate){
        Map<Id, AssetInfo> responseList = new Map<Id, AssetInfo>();
        Map<Id, AssetInfo> assetMap = new Map<Id, AssetInfo>();
        List<Id> assetIds = new List<String>();
        ConnectApi.RevenueAsyncRepresentation response;
        for(AssetInfo asset : assetList) {
            assetIds.add(asset.assetId);
            assetMap.put(asset.assetId, asset);
            if(assetIds.size() == REVCLOUDAPILIMIT){
                response = cancelAssetsAPI(assetIds, cancelDate);
                responseList = addStatusURL(assetIds, assetMap, response);
                assetIds = new List<String>();
            }
        }
        if(!assetIds.isEmpty()){
            response = cancelAssetsAPI(assetIds, cancelDate);
            responseList = addStatusURL(assetIds, assetMap, response);
        }
        System.debug('<<<<< responseList >>>>'+responseList);
        return responseList.values();
    }


    /**
     * Used to call the SM Cancel service through the Apex via Connect API
     * @param assetList list of assets to be renewed or cancelled
     * @param cancelDate Date for the Cancel Service,
     * @return list of responses from the connectAPI output
     */
    
    @AuraEnabled
    public static List<AssetInfo> amendAssets(List<AssetInfo> assetList, Datetime amendDate, Integer quantity){
        Map<Id, AssetInfo> responseList = new Map<Id, AssetInfo>();
        Map<Id, AssetInfo> assetMap = new Map<Id, AssetInfo>();
        List<Id> assetIds = new List<String>();
        ConnectApi.RevenueAsyncRepresentation response;
        for(AssetInfo asset : assetList) {
            assetIds.add(asset.assetId);
            assetMap.put(asset.assetId, asset);
            if(assetIds.size() == REVCLOUDAPILIMIT){
                response = amendAssetsAPI(assetIds, amendDate, quantity);
                responseList = addStatusURL(assetIds, assetMap, response);
                assetIds = new List<String>();
            }
        }
        if(!assetIds.isEmpty()){
            response = amendAssetsAPI(assetIds, amendDate, quantity);
            responseList = addStatusURL(assetIds, assetMap, response);
        }
        System.debug('<<<<< responseList >>>>'+responseList);
        return responseList.values();
    }

    @AuraEnabled
    public static String createAmendQuote(List<AssetInfo> assetList, Datetime amendDate, Integer quantity, Id accountId){
        Opportunity opp = new Opportunity();
        opp.Name = 'Amend Opportunity '+ System.today();
        opp.CloseDate = System.today().addMonths(6);
        opp.StageName = 'Prospecting';
        opp.AccountId = accountId;
        insert opp;
        Quote quote = new Quote();
        quote.Name = 'Amend Quote ' + System.today();
        quote.OpportunityId = opp.Id;
        // Save the quote
        insert quote;

        List<QuoteLineItem> lineItemList = new List<QuoteLineItem>();
        // Create a new quote line item for the asset
        for(AssetInfo asset : assetList) {
            QuoteLineItem lineItem = new QuoteLineItem();
            lineItem.QuoteId = quote.Id;
            lineItem.Asset__c = asset.assetId; // Set the AssetId to the ID of the asset you want to add to the quote
            lineItem.Quantity = asset.asset.CurrentQuantity + quantity;
            lineItem.Product2Id = asset.asset.Product2Id;
            lineItem.EndDate = Date.valueOf(asset.lifeCycleEndDate);
            lineItem.StartDate = Date.valueOf(asset.lifeCycleStartDate);
            lineItemList.add(lineItem);
        }
        insert lineItemList;

        return quote.Id;
    }

    @AuraEnabled
    public static Map<Id, RevenueAsyncOperation> processAsyncData(List<String> asyncIds) {
        System.debug('<<<asyncIds>>>  '+asyncIds);
        return new Map<Id, RevenueAsyncOperation>([SELECT Id, Status FROM RevenueAsyncOperation Where Id IN: asyncIds WITH SECURITY_ENFORCED]);
    }

    private static Map<Id, AssetInfo> addStatusURL(List<String> assetIds, Map<Id, AssetInfo> assetMap, ConnectApi.RevenueAsyncRepresentation response){
        if(response.requestIdentifier != null) {
            Integer index=response.statusURL.lastIndexOf('/');
            for(Id assetId : assetIds){
                assetMap.get(assetId).statusURL = response.statusURL.substring(index+1); //Status temporory field used to datatable
                assetMap.get(assetId).requestIdentifier = response.requestIdentifier;
            }

            return assetMap;
        }
        throw new AuraHandledException('Error While sending the request');
    }

    public static ConnectApi.RevenueAsyncRepresentation renewAssetsAPI(List<String> assetIds){
        ConnectApi.AssetMgmtInitiateRenewalInput input = new ConnectApi.AssetMgmtInitiateRenewalInput();
        input.assetIds = assetIds;
        ConnectApi.RevenueAsyncRepresentation output = ConnectApi.AssetMgmt.initiateRenewal(input);
        System.debug(output);
        return output;
    }

    private static ConnectApi.RevenueAsyncRepresentation cancelAssetsAPI(List<String> assetIds, Datetime cancelDate){
        ConnectApi.AssetMgmtInitiateCancellationInput input = new ConnectApi.AssetMgmtInitiateCancellationInput();
        input.cancellationOutputType = ConnectApi.AssetMgmtCancellationType.Order;
        input.assetIds = assetIds;
        input.cancellationDate = cancelDate;
        return ConnectApi.AssetMgmt.initiateCancellation(input);
    }

    private static ConnectApi.RevenueAsyncRepresentation amendAssetsAPI(List<String> assetIds, Datetime amendDate, Integer quantity){
        ConnectApi.AssetMgmtInitiateAmendQtyInput input = new ConnectApi.AssetMgmtInitiateAmendQtyInput();
        input.amendmentOutputType = ConnectApi.AssetMgmtAmendmentType.Order;
        input.assetIds = assetIds;
        input.startDate = amendDate;
        input.quantityChange = quantity;
        return ConnectApi.AssetMgmt.initiateAmendQuantity(input);
    }

    public class AssetInfo { 
        @AuraEnabled
        public Asset asset{get;set;}

        @AuraEnabled
        public Id assetId{get;set;}

        @AuraEnabled
        public String name{get;set;}

        @AuraEnabled
        public String recordURL {get; set;}

        @AuraEnabled
        public Datetime lifeCycleStartDate{get;set;}

        @AuraEnabled
        public Datetime lifeCycleEndDate{get;set;}

        @AuraEnabled
        public String renewalTermUnit{get;set;}

        @AuraEnabled
        public Decimal renewalTerm{get;set;}

        @AuraEnabled
        public String statusURL{get;set;}

        @AuraEnabled
        public String requestIdentifier{get;set;}

        @AuraEnabled
        public String parentId {get;set;}
    }
}