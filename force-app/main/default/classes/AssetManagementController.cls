public with sharing class AssetManagementController {

    private static final Integer REVCLOUDAPILIMIT = Integer.valueOf(System.Label.RevCloudAPILimit);
    
    /**
     * This is used for retreiving the Assets from Account which has HasLifecycleManagement is true
     * @param accountId
     * @return list of Assets with StartDate, EndDate and Renewal Fields
     */
    @AuraEnabled(cacheable=true)
    public static List<AssetInfo> getAssetsByAccount(String accountId){
        List<AssetInfo> assetInfoList = new List<AssetInfo>();
        AssetInfo assetInfo;
        for(Asset asset : [SELECT Id, Name, LifecycleStartDate, LifecycleEndDate, RenewalTerm, RenewalTermUnit 
        FROM Asset Where AccountId =: accountId and HasLifecycleManagement = TRUE WITH SECURITY_ENFORCED Order By createdDate]){
            assetInfo = new AssetInfo();
            assetInfo.assetId = asset.Id;
            assetInfo.name = asset.Name;
            assetInfo.lifeCycleStartDate = asset.LifecycleStartDate;
            assetInfo.lifeCycleEndDate = asset.LifecycleEndDate;
            assetInfo.renewalTerm = asset.renewalTerm;
            assetInfo.renewalTermUnit = asset.renewalTermUnit;
            assetInfoList.add(assetInfo);
        }
        return assetInfoList;
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

    private static ConnectApi.RevenueAsyncRepresentation renewAssetsAPI(List<String> assetIds){
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

    public class AssetInfo { 
        @AuraEnabled
        public Id assetId{get;set;}

        @AuraEnabled
        public String name{get;set;}

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
    }
}