import { LightningElement, wire, track, api} from 'lwc';
import getAssets from '@salesforce/apex/AssetManagementController.getAssetsByAccount'
import renewCancel from '@salesforce/apex/AssetManagementController.renewCancelAsset'
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
    isButtonsActivated = true;
    isCancelDatePopup = false;
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
        this.isButtonsActivated =  this.selectedRows.length > 0 ?  false : true;
    }

    toggleCancelDatePopup = () => {
        this.isCancelDatePopup = this.isCancelDatePopup === false ? true : false
    }

    renewCancelAction = event => {
        let actionType = event.currentTarget.name;
        //new Date(this.cancelledDate.toString().split('GMT')[0]+' UTC').toISOString()
        this.loaded = true;
        console.log(actionType);
        let date = this.cancelledDate === undefined ? new Date() : this.cancelledDate;
        renewCancel({assetList : this.selectedRows, type: actionType, cancelDate: date})
        .then(() => {
            this.loaded = false
        })
        .catch((error) => {
            this.loaded = false;
            this.error = error;
        });
        this.isCancelDatePopup = false;
    }

    handleDate(event){
        this.cancelledDate = event.currentTarget.value;
    }

    get toggleCancelAssetButton(){
        return this.selectedRows.length > 0 && this.cancelledDate !== undefined ?  false : true;
    }

}