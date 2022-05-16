/**
 * 
 */
public with sharing class AssetManagementController {
    private static final String renewAPIUri = '/services/data/v55.0/asset-management/assets/collection/actions/initiate-renewal';
    private static final String cancelAPIUri = '/services/data/v55.0/asset-management/assets/collection/actions/initiate-cancellation'; 

    @AuraEnabled(cacheable=true)
    public static List<Asset> getAssetsByAccount(String accountId){
        //RenewalTerm, RenewalTermUnit, LifecycleStartDate, LifecycleEndDate
        //and HasLifecycleManagement = TRUE 
        return [SELECT Id, Name, LifecycleStartDate, LifecycleEndDate, RenewalTerm, RenewalTermUnit FROM Asset Where AccountId =: accountId and HasLifecycleManagement = TRUE Order By createdDate];

    }
    
    @AuraEnabled
    public static List<String> renewOrCancelAsset(List<Asset> assetList, String type, Datetime cancelDate){
        system.debug('<<<<<<assetList>>>>>'+assetList);
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