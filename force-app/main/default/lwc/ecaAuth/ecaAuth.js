import { LightningElement, wire } from 'lwc';
import getAuthUrl from '@salesforce/apex/OauthController.getAuthUrl';
import getIsAuthenticated from '@salesforce/apex/OauthController.isAuthenticated';
import handleRefreshToken from '@salesforce/apex/OauthController.refreshAccessToken';
import handleSendMessage from '@salesforce/apex/SendMessageUtils.handleSendMessage';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';


export default class EcaAuth extends LightningElement {
    //@wire(getIsAuthenticated) isAuthenticated;
    isAuthenticated;
    message;
    ecaName = 'Aquiva_Labs_Demo';


    //Only works before initial auth, expired token requires additional work
    @wire(getIsAuthenticated)
    wiredIsAuthenticated({ error, data }) {
        this.isAuthenticated = data ? data : false;
    } 
    
    handleConnect() {
        getAuthUrl()
            .then(url => {
                window.location.href = url;
            })
            .catch(error => {
                console.error('Error fetching authorization URL', error);
            });
    }

    handleRefresh(){
        handleRefreshToken()
            .then(result => {
                console.log(result);
            })
            .catch(error => {
                console.log(error);
            })
    }

    handleChange(event){
        this.message = event.target.value;
    }

    handleSendMessage(){
        handleSendMessage({ message: this.message, ECAName: this.ecaName })
            .then(result => {
                let toastVariant = result.errorCode === 'SUCCESS' ? 'success' : 'error';
                this.showToast(result.message, result.errorCode, toastVariant);
            })
            .catch(error => {
                console.log('error');
                console.log(JSON.stringify(error));
            });
    }
    
    showToast(title, message, variant) {
        const toastEvent = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(toastEvent);
    }


}
