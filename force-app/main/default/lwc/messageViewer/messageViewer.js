import { LightningElement, wire } from 'lwc';
import getMessages from '@salesforce/apex/MessageViewerController.getMessages';

export default class MessageViewer extends LightningElement {
    @wire(getMessages) messages;

}
