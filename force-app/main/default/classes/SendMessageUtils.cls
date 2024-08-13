public with sharing class SendMessageUtils {

    @AuraEnabled
    public static restResponse handleSendMessage(String message, String ECAName){

        System.debug(message);
        System.debug(ECAName);
        
        // Define the endpoint and access token placeholders
        String endpoint = 'https://hopedev-dev-ed.develop.my.salesforce.com/services/apexrest/mholt/ReceiveMessage';
    
        ECA_Auth__mdt auth = OauthController.getAquivaDemoAuth('Aquiva_Labs_Demo');        
        
        String accessToken = auth.access_token__c;

        // Send the message to the REST resource in another org
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod('POST');
        req.setHeader('Authorization', 'Bearer ' + accessToken);
        req.setHeader('Content-Type', 'application/json');
        req.setBody(JSON.serialize(message));


        Http http = new Http();
        try {
            HttpResponse res = http.send(req);
            System.debug(res.getStatusCode());
            System.debug('Response: ' + res.getBody());
            RestResponse response = (RestResponse) JSON.deserialize(res.getBody().substring(1, res.getBody().length() - 1), RestResponse.class);
            System.debug(response);

            return response;
        } catch (Exception e) {
            System.debug('Error: ' + e.getMessage());
            return null;
        }        
    }

    public class restResponse{
        @AuraEnabled
        public String message;
        @AuraEnabled
        public String errorCode;
        
        public restResponse(String m, String e){
            message = m;
            errorCode = e;
        }
    }

}