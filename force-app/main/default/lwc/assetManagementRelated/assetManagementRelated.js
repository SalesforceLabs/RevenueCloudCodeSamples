import { LightningElement, wire, track, api} from 'lwc';
import getAssets from '@salesforce/apex/AssetManagementController.getAssetsByAccount'
import renewAssets from '@salesforce/apex/AssetManagementController.renewAssets'
import cancelAssets from '@salesforce/apex/AssetManagementController.cancelAssets'
import { getRecords } from 'lightning/uiRecordApi';
import STATUS_FIELD from '@salesforce/schema/RevenueAsyncOperation.Status';

const columns = [
    { label: 'Asset Name', fieldName: 'recordURL', type: 'url',
    typeAttributes: {label: { fieldName: 'name' }, target: '_blank'} },
    { label: 'Lifecycle Start Date', fieldName: 'lifeCycleStartDate',type: 'date', typeAttributes: {
        day: "2-digit",
        month: "2-digit",
        year:"numeric",
        timeZone:"UTC"
    }},
    { label: 'Lifecycle End Date', fieldName: 'lifeCycleEndDate', type: 'date', typeAttributes: {
        day: "2-digit",
        month: "2-digit",
        year:"numeric",
        timeZone:"UTC"
    }},
    { label: 'Renewal Term Unit', fieldName: 'renewalTermUnit', type: 'text'},
    { label: 'Renewal Term', fieldName: 'renewalTerm', type: 'Number'},
];

const columnsUpdated = [
    { label: 'Asset Name', fieldName: 'recordURL', type: 'url',
    typeAttributes: {label: { fieldName: 'name' }, target: '_blank'} },
    { label: 'Lifecycle Start Date', fieldName: 'lifeCycleStartDate',type: 'date', typeAttributes: {
        day: "2-digit",
        month: "2-digit",
        year:"numeric",
        timeZone:"UTC"
    }},
    { label: 'Lifecycle End Date', fieldName: 'lifeCycleEndDate', type: 'date', typeAttributes: {
        day: "2-digit",
        month: "2-digit",
        year:"numeric",
        timeZone:"UTC"
    }},
    { label: 'Renewal Term Unit', fieldName: 'renewalTermUnit', type: 'text'},
    { label: 'Renewal Term', fieldName: 'renewalTerm', type: 'Number'},
    { label: 'Async URL', fieldName: 'statusURL', type: 'url',
    typeAttributes: {label: { fieldName: 'StatusName' }, target: '_blank'} }, 
    { label: 'Async Status', fieldName: 'Status', type: 'text'},
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
    @track isLoaded = false;
    assetMap = new Map();
    statusURLList = [];
    a_Record_URL;
 
    connectedCallback(){
        this.a_Record_URL = window.location.origin;
    }   

    @wire(getAssets , {accountId : '$recordId'})
    assets({error, data}){
        if(data){
            data.forEach((record) => {
                let tempConRec = Object.assign({}, record);  
                tempConRec.recordURL = this.a_Record_URL + '/' + tempConRec.assetId;
                this.assetMap.set(tempConRec.assetId, tempConRec);
            });
            this.assetList = Array.from(this.assetMap.values());
            console.log(this.assetMap)
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

    handleAction = event => {
        let actionType = event.currentTarget.name;

        this.isLoaded = true;
        console.log('actionType',actionType);
        if(actionType === 'Renew') {
            this.handleRenewAssets();
        }
        else if(actionType === 'Cancel') {
            this.handleCancelAssets();
        }
        this.isLoaded = false;
        this.isCancelDatePopup = false;
    }


    handleRenewAssets = () =>{
        renewAssets({assetList : this.selectedRows})
        .then((data) => {
            this.processAPIRequests(data);
        })
        .catch((error) => {
            console.log('<<<error>>>'+JSON.stringify(error));
            this.error = error;
        });
    }

    handleCancelAssets = () =>{
        cancelAssets({assetList : this.selectedRows, cancelDate: this.cancelledDate})
        .then((data) => {
            this.processAPIRequests(data);
        })
        .catch((error) => {
            console.log('<<<error>>>'+JSON.stringify(error));
            this.error = error;
        });
        this.isCancelDatePopup = false;
    }

    processAPIRequests = (data) =>{
        const statusName = 'RevenueAsyncOperation';
        const status = 'Submitted'
        console.log('processAPIRequests', data);
        data.forEach( asset => {
            let assetRecord = this.assetMap.get(asset.assetId);
            assetRecord.statusURL = this.a_Record_URL + '/'+ asset.statusURL;
            assetRecord.StatusName = statusName;
            assetRecord.Status = status;
            assetRecord.requestIdentifier = asset.requestIdentifier;
            this.statusURLList.push(asset.statusURL);
        });
        this.columns = columnsUpdated;

        this.assetList = Array.from(this.assetMap.values());


        
        console.log('<><><><><>',this.assetList);
    }

    handleDate(event){
        this.cancelledDate = event.currentTarget.value;
    }

    get toggleCancelAssetButton(){
        return this.selectedRows.length > 0 && this.cancelledDate !== undefined ?  false : true;
    }

    handleEvent(event) {
        let obj = event.detail.data.payload;
        let data = Array.from(this.assetMap.values());
        console.log('processAPIRequests', data);
        data.forEach(asset =>{
            if(asset.requestIdentifier == obj.RequestIdentifier){
                if(obj.HasErrors){
                    asset.Status = 'Completed With Failures';
                }
                else{
                    asset.Status = 'Completed';
                }
            }
            console.log('<><><>', asset);
        })
        this.assetList = data;
    }

    getAsynRecords(){
        getRecords({
            records : [
                {
                  recordIds: this.statusURLList,
                  fields: [STATUS_FIELD]
                },
            ]
        }).then(data => {
            let assetList = Array.from(this.assetMap.values());
            assetList.map(asset => {
                if(asset.Status == 'Submitted' && asset.statusURL.contains(data.Id)){
                    asset
                }
            })
        })
    }
}