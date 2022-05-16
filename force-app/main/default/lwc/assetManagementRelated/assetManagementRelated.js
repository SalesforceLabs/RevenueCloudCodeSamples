import { LightningElement, wire, track, api} from 'lwc';
import getAssets from '@salesforce/apex/AssetManagementController.getAssetsByAccount'
import renewCancel from '@salesforce/apex/AssetManagementController.renewOrCancelAsset'
const columns = [
    { label: 'Asset Name', fieldName: 'Name', type: 'text' },
    { label: 'Lifecycle Start Date', fieldName: 'LifecycleStartDate',type: 'date', typeAttributes: {
        day: "2-digit",
        month: "2-digit",
        year:"numeric",
        timeZone:"UTC"
    }},
    { label: 'Lifecycle End Date', fieldName: 'LifecycleEndDate', type: 'date', typeAttributes: {
        day: "2-digit",
        month: "2-digit",
        year:"numeric",
        timeZone:"UTC"
    }},
    { label: 'Renewal Term Unit', fieldName: 'RenewalTermUnit', type: 'text'},
    { label: 'Renewal Term', fieldName: 'RenewalTerm', type: 'Number'},
];



export default class AssetManagement extends LightningElement {
    activateButtons = true;
    showCancelPopup = false;
    @track assetList;
    @track error;
    @api recordId
    @track columns = columns;
    selectedRows = [];
    @track cancelledDate
    @track loaded = false;

    @wire(getAssets , {accountId : '$recordId'})
    assets({error, data}){
        if(data){
            this.assetList = data;
        }
        else if(error){
            this.error = error;
            this.assetList = undefined;
        }
    }

    handleRowSelection = event => {
        this.selectedRows =event.detail.selectedRows;
        console.log(this.selectedRows);
        this.activateButtons =  this.selectedRows.length > 0 ?  false : true;
    }

    renewCancelPopup = () => {
        this.showCancelPopup=  this.showCancelPopup === false ? true : false
    }

    renewCancelAction = event => {
        let actionType = event.currentTarget.name;
        //new Date(this.cancelledDate.toString().split('GMT')[0]+' UTC').toISOString()
        this.loaded = true;
        console.log(actionType);
        let date = this.cancelledDate === undefined ? new Date() : this.cancelledDate;
        renewCancel({assetList : this.selectedRows, type: actionType, cancelDate: date})
        .then((result) => {
            
            console.log('result',result);
            this.loaded = false
        })
        .catch((error) => {
            this.loaded = false;
            console.log('result',error);
        });
        this.showCancelPopup = false;
    }

    handleDate(event){
        this.cancelledDate = event.currentTarget.value;
    }

    get activateCancelButton(){
        return this.selectedRows.length > 0 && this.cancelledDate !== undefined ?  false : true;
    }

}