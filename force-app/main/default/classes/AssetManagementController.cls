/**
 * 
 */
public with sharing class AssetManagementController {

    /**
     * This is used for retreiving the Assets from Account which has HasLifecycleManagement is true
     */
    @AuraEnabled(cacheable=true)
    public static List<Asset> getAssetsByAccount(String accountId){
        return [SELECT Id, Name, LifecycleStartDate, LifecycleEndDate, RenewalTerm, RenewalTermUnit FROM Asset Where AccountId =: accountId and HasLifecycleManagement = TRUE Order By createdDate];

    }

    /**
     * Used to call the SM Renew and Cancel service through the Apex via Connect API
     */
    
    @AuraEnabled
    public static List<String> renewCancelAsset(List<Asset> assetList, String type, Datetime cancelDate){
        List<String> responseList = new List<String>();
        ConnectApi.RevenueAsyncRepresentation output;
        for(Asset asset : assetList) {
            List<String> idList = new List<String>();
            if(type == 'Renew'){
                ConnectApi.AssetMgmtInitiateRenewalInput input = new ConnectApi.AssetMgmtInitiateRenewalInput();
                idList.add(asset.Id);
                input.assetIds = idList;

                output = ConnectApi.AssetMgmt.initiateRenewal(input);
            }
            else if(type == 'Cancel'){
                ConnectApi.AssetMgmtInitiateCancellationInput input = new ConnectApi.AssetMgmtInitiateCancellationInput();
                idList.add(asset.Id);
                input.assetIds = idList;
                input.cancellationDate = cancelDate;
                input.cancellationOutputType = ConnectApi.AssetMgmtCancellationType.Order;
                output = ConnectApi.AssetMgmt.initiateCancellation(input);
            }
            responseList.add(string.valueOf(output));
        }
        return responseList;
    }

   
}