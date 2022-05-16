import { LightningElement, api } from 'lwc';
import { subscribe, unsubscribe, onError}  from 'lightning/empApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class PearEventManager extends LightningElement {

    subscription = {};
     @api channel = '/event/AssetCancelInitiatedEvent';

    // Initializes the component
    connectedCallback() {
        // Register error listener
        this.registerErrorListener();
        this.handleSubscribe();
    }

    disconnectedCallback() {
        this.handleUnsubscribe();
    }

    // Handles subscribe button click
    handleSubscribe() {
        // Callback invoked whenever a new event message is received
        const thisReference = this;
        const messageCallback = function(response) {
            let obj = JSON.parse(JSON.stringify(response));
            let message = 'Order created: ' + obj.data.payload.CancellationRecordId;

            let variant = 'success'
            if (obj.data.payload.AssetCancelErrorDetailEvents != null) {
                message = 'Couldn’t cancel the asset: ' + obj.data.payload.AssetCancelErrorDetailEvents[0].ErrorMessage;
                variant = 'error'
            }
            const evt = new ShowToastEvent({
                message: message,
                variant: variant,
                mode : "sticky"
            });

            thisReference.dispatchEvent(evt);
            // Response contains the payload of the new message received
        };

        // Invoke subscribe method of empApi. Pass reference to messageCallback
        subscribe(this.channel, -1, messageCallback).then(response => {
            // Response contains the subscription information on subscribe call
            this.subscription = response;
        });

    }

    // Handles unsubscribe button click
    handleUnsubscribe() {

        // Invoke unsubscribe method of empApi
        unsubscribe(this.subscription, response => {
            console.log('unsubscribe() response: ', JSON.stringify(response));
            // Response is true for successful unsubscribe
        });
    }

    registerErrorListener() {
        // Invoke onError empApi method
        onError(error => {
            console.log('Received error from server: ', JSON.stringify(error));
            // Error contains the server-side error
        });
    }
}