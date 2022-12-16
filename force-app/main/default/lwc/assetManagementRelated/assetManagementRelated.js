import { LightningElement, wire, track, api } from 'lwc';
import getAssets from '@salesforce/apex/AssetManagementController.getAssetsByAccount'
import renewAssets from '@salesforce/apex/AssetManagementController.renewAssets'
import cancelAssets from '@salesforce/apex/AssetManagementController.cancelAssets'
import amendAssets from '@salesforce/apex/AssetManagementController.amendAssets'
import processAsyncData from '@salesforce/apex/AssetManagementController.processAsyncData';
import AssetManagementLabel from '@salesforce/label/c.AssetManagement';

const columns = [
    {
        label: 'Asset Name', fieldName: 'recordURL', type: 'url',
        typeAttributes: { label: { fieldName: 'name' }, target: '_blank' }
    },
    {
        label: 'Lifecycle Start Date', fieldName: 'lifeCycleStartDate', type: 'date', typeAttributes: {
            day: "2-digit",
            month: "2-digit",
            year: "numeric",
            timeZone: "UTC"
        }
    },
    {
        label: 'Lifecycle End Date', fieldName: 'lifeCycleEndDate', type: 'date', typeAttributes: {
            day: "2-digit",
            month: "2-digit",
            year: "numeric",
            timeZone: "UTC"
        }
    },
    { label: 'Renewal Term Unit', fieldName: 'renewalTermUnit', type: 'text' },
    { label: 'Renewal Term', fieldName: 'renewalTerm', type: 'Number' },
];

const columnsUpdated = [
    {
        label: 'Asset Name', fieldName: 'recordURL', type: 'url',
        typeAttributes: { label: { fieldName: 'name' }, target: '_blank' }
    },
    {
        label: 'Lifecycle Start Date', fieldName: 'lifeCycleStartDate', type: 'date', typeAttributes: {
            day: "2-digit",
            month: "2-digit",
            year: "numeric",
            timeZone: "UTC"
        }
    },
    {
        label: 'Lifecycle End Date', fieldName: 'lifeCycleEndDate', type: 'date', typeAttributes: {
            day: "2-digit",
            month: "2-digit",
            year: "numeric",
            timeZone: "UTC"
        }
    },
    { label: 'Renewal Term Unit', fieldName: 'renewalTermUnit', type: 'text' },
    { label: 'Renewal Term', fieldName: 'renewalTerm', type: 'Number' },
    {
        label: 'Status', fieldName: 'StatusURL', type: 'url',
        typeAttributes: { label: { fieldName: 'Status' }, target: '_blank' }
    },
];


export default class AssetManagement extends LightningElement {
    @track assetList;
    @track error;
    @track columns = columns;
    @track cancelledDate
    @track amendedDate
    @track isLoaded = false;
    @track isDatePopup = { isCancelDatePopup: false, isButtonsActivated: true, isAmendDatePopup: false }
    @track selectedRows = [];
    @track selectedRowsAPI = []
    @track AssetManagementLabel = AssetManagementLabel
    @api recordId
    isButtonsActivated = true;
    isCancelDatePopup = false;
    assetMap = new Map();
    a_Record_URL;
    asyncIdList = new Set();
    quantity;

    connectedCallback() {
        this.a_Record_URL = window.location.origin;
    }

    @wire(getAssets, { accountId: '$recordId' })
    assets({ error, data }) {
        if (data) {
            this.assetList = this.generateTree(data)
            console.log(this.assetMap)
        }
        else if (error) {
            this.error = error;
            this.assetList = undefined;
        }
    }

    generateTree(data) {
        data.forEach(element => {
            let tempConRec = Object.assign({}, element);
            tempConRec._children = []
            this.assetMap.set(tempConRec.assetId, tempConRec);
        })
        let assetList = Array.from(this.assetMap.values());
        let r = [], h = assetList.reduce((a, c) => (a[c.assetId] = c, a), {});
        assetList.forEach((c, i, a, e = h[c.parentId]) => {
            (e ? (e._children) : r).push(c)
        });
        return r;
    }

    handleRowSelection(event) {
        let selectedRows = event.detail.selectedRows;
        console.log(selectedRows);
        console.log(JSON.stringify(event));
        if (selectedRows.length > 0) {
            let tempList = [];
            selectedRows.forEach(selectedRecord => {
                console.log('selectedRecord', selectedRecord);
                console.log('selectedRecord', JSON.stringify(selectedRecord));
                tempList.push(selectedRecord.assetId);
                this.selectedRows.push(selectedRecord);
            })

            let assetList = Array.from(this.assetMap.values());
            assetList.forEach(asset => {
                if (asset.parentId != undefined) {

                    if (tempList.includes(asset.parentId)) {
                        tempList.push(asset.assetId);
                        this.selectedRows.push(asset);
                    }
                }
            })
            console.log('assetList', tempList);
            this.selectedRowsAPI = tempList;
        }

        this.isButtonsActivated = selectedRows.length > 0 ? false : true;
    }

    toggleCancelDatePopup = () => {
        this.isCancelDatePopup = this.isCancelDatePopup === false ? true : false
    }

    toggleAmendDatePopup = () => {
        this.isDatePopup.isAmendDatePopup = this.isDatePopup.isAmendDatePopup === false ? true : false
    }

    handleAction = event => {
        let actionType = event.currentTarget.name;
        this.isLoaded = true;
        console.log('actionType', actionType);
        if (actionType === 'Renew') {
            this.handleRenewAssets();
        }
        else if (actionType === 'Cancel') {
            this.handleCancelAssets();
        }
        else if (actionType === 'Amend') {
            this.handleAmendAssets();
        }
        this.isLoaded = false;
        this.isCancelDatePopup = false;
    }


    handleRenewAssets = () => {
        renewAssets({ assetList: this.selectedRows })
            .then((data) => {
                this.processAPIRequests(data);
            })
            .catch((error) => {
                this.error = error;
            });
    }

    handleCancelAssets = () => {
        cancelAssets({ assetList: this.selectedRows, cancelDate: this.cancelledDate })
            .then((data) => {
                this.processAPIRequests(data);
            })
            .catch((error) => {
                this.error = error;
            });
        this.isCancelDatePopup = false;
    }

    handleAmendAssets = () => {
        amendAssets({ assetList: this.selectedRows, amendDate: this.amendedDate, quantity: this.quantity })
            .then((data) => {
                this.processAPIRequests(data);
            })
            .catch((error) => {
                this.error = error;
            });
        this.isDatePopup.isAmendDatePopup = false;
    }

    processAPIRequests = (data) => {
        const status = 'Submitted'
        data.forEach(asset => {
            let assetRecord = this.assetMap.get(asset.assetId);
            assetRecord.StatusURL = this.a_Record_URL + '/' + asset.statusURL;
            assetRecord.Status = status;
            assetRecord.requestIdentifier = asset.requestIdentifier;
            this.asyncIdList.add(asset.statusURL);
        });
        this.columns = columnsUpdated;
        this.assetList = this.generateTree(Array.from(this.assetMap.values()));
        /*
        const fn = this.processAsyncStatus()
        this.poll(fn, this.asyncIdList, 1000);*/
    }

    handleDate(event) {
        this.cancelledDate = event.currentTarget.value;
    }

    handleAmendDate(event) {
        let elemId = event.currentTarget.dataset.id
        if (elemId == 'AmendDate')
            this.amendedDate = event.currentTarget.value;

        if (elemId == 'quantity')
            this.quantity = event.currentTarget.value;
    }

    get toggleCancelAssetButton() {
        return this.selectedRowsAPI.length > 0 && this.cancelledDate !== undefined ? false : true;
    }

    get toggleAmendAssetButton() {
        console.log(this.amendedDate);
        console.log(this.quantity);
        return this.selectedRowsAPI.length > 0 && this.amendedDate !== undefined && this.quantity !== undefined ? false : true;
    }

    handleEvent(event) {
        let obj = event.detail.data.payload;
        let data = Array.from(this.assetMap.values());
        data.forEach(asset => {
            if (asset.requestIdentifier == obj.RequestIdentifier) {
                this.removeAsyncId(asset.statusURL)
                if (obj.HasErrors) {
                    asset.Status = 'Completed With Failures';
                    asset.StatusURL = this.a_Record_URL + '/lightning/r/RevenueTransactionErrorLog/' + asset.assetId + '/related/PrimaryRevenueTransactionErrorLogs/view';
                }
                else {
                    if (obj.hasOwnProperty('RenewalRecordId')) {
                        asset.Status = 'Renewed';
                        asset.StatusURL = this.a_Record_URL + '/' + obj.RenewalRecordId;
                    }
                    else if (obj.hasOwnProperty('CancellationRecordId')) {
                        asset.Status = 'Cancelled';
                        asset.StatusURL = this.a_Record_URL + '/' + obj.CancellationRecordId;
                    }
                    else {
                        asset.Status = 'Amended';
                        asset.StatusURL = this.a_Record_URL + '/' + obj.AmendmentRecordId;
                    }
                }
            }
        })
        this.assetList = this.generateTree(data);
    }

    processAsyncStatus() {
        processAsyncData({ assetInfoList: this.asyncIdList })
            .then((data) => {
                let assetList = Array.from(this.assetMap.values());
                console.log('assetList', assetList);
                assetList.forEach(asset => {
                    let asyncObj = data.get(asset.requestIdentifier)
                    if (asyncObj.Id == asset.requestIdentifier) {
                        asset.Status = asyncObj.Status;
                        if (asyncObj.Status != 'Submitted') {
                            this.removeAsyncId(asyncObj.Id)
                        }
                    }
                })
                this.assetList = this.generateTree(assetList);
            })
            .catch((error) => {
                this.error = error;
            });
    }

    async poll(fn, fnCondition, ms) {
        let result = await fn;
        while (fnCondition.size > 0) {
            await this.wait(ms);
            result = await fn;
        }
        return result;
    }

    wait(ms = 500) {
        return new Promise(resolve => {
            console.log(`waiting ${ms} ms...`);
            setTimeout(resolve, ms);
        });
    }

    removeAsyncId(statusURL) {
        this.asyncIdList.delete(statusURL);
    }
}