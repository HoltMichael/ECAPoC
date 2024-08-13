@RestResource(urlMapping='/ReceiveMessage')
global with sharing class MessageReceiver {
    
    //Nothing special happening here, could just use Salesforce standard REST APIs to insert message__c record
    //Original intention was to do something more interesting, but left it for PoC purposes
    @HttpPost
    global static void doPost() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        
        // Parse the JSON request body
        String reqMessage = req.requestBody.toString();
        System.debug('Received message: ' + reqMessage);        

        //save message without the quotes
        ECA_message__c msg = new ECA_message__c(message__c = reqMessage.substring(1, reqMessage.length() - 1));
        insert msg;

        // Set the response
        res.statusCode = 200;
        res.responseBody = Blob.valueOf('[{"message": "Message received","errorCode":"SUCCESS"}]');
    }
}