public with sharing class OauthController {


    public static ECA_Auth__mdt getAquivaDemoAuth(String DeveloperName){
        return [SELECT id, DeveloperName, client_id__c, client_secret__c, callback_url__c, token_url__c, Access_token__c, Refresh_token__c 
        FROM ECA_Auth__mdt
        WHERE DeveloperName=:DeveloperName
        LIMIT 1];
    }

    @AuraEnabled(cacheable=true)
    public static String getAuthUrl() {
        ECA_Auth__mdt auth = getAquivaDemoAuth('Aquiva_Labs_Demo');

        //could/should store authUrl in CMT also
        String authUrl = 'https://hopedev-dev-ed.develop.lightning.force.com/services/oauth2/authorize?response_type=code' + 
                         '&client_id=' + EncodingUtil.urlEncode(auth.client_id__c , 'UTF-8') + 
                         '&redirect_uri=' + EncodingUtil.urlEncode(auth.callback_url__c , 'UTF-8');
        return authUrl;
    }


    //If the token expires, this will still return true. Additional work required to properly implement this
    @AuraEnabled(cacheable=true)
    public static Boolean isAuthenticated(){
        ECA_Auth__mdt auth = getAquivaDemoAuth('Aquiva_Labs_Demo');
        return !String.isBlank(auth.access_token__c);
    }


    @RemoteAction
    public static void handleCallback(String code) {

        ECA_Auth__mdt auth = getAquivaDemoAuth('Aquiva_Labs_Demo');

        HttpRequest req = new HttpRequest();
        req.setEndpoint(auth.token_url__c);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        req.setBody('grant_type=authorization_code' +
                    '&code=' + EncodingUtil.urlEncode(code, 'UTF-8') +
                    '&client_id=' + EncodingUtil.urlEncode(auth.client_id__c, 'UTF-8') +
                    '&client_secret=' + EncodingUtil.urlEncode(auth.client_secret__c, 'UTF-8') +
                    '&redirect_uri=' + EncodingUtil.urlEncode(auth.callback_url__c, 'UTF-8'));

        Http http = new Http();
        HttpResponse res = http.send(req);

        if (res.getStatusCode() == 200) {
            Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            String accessToken = (String) responseMap.get('access_token');
            String refreshToken = (String) responseMap.get('refresh_token');

            deployCMT('Aquiva_Labs_Demo', accessToken, refreshToken);
        } else {
            throw new AuraHandledException('Failed to obtain access token: ' + res.getBody());
        }
    }


    public static void deployCMT(String devName, String accessToken, String refreshToken){
        //Set CMT name to 'Aquiva_Labs_Demo' to update the right record
        Metadata.CustomMetadata customMetadata =  new Metadata.CustomMetadata();
        customMetadata.fullName = 'MHolt__ECA_Auth__mdt.'+devName;
        customMetadata.label = 'Key';

        //Update access token
        Metadata.CustomMetadataValue field = new Metadata.CustomMetadataValue();
        field.field = 'MHolt__Access_token__c';
        field.value = accessToken;
        customMetadata.values.add(field);

        //Update refresh token if provided
        if(refreshToken != null){
            field = new Metadata.CustomMetadataValue();
            field.field = 'MHolt__Refresh_token__c';
            field.value = refreshToken;
            customMetadata.values.add(field);
        }

        //Deploy
        Metadata.DeployContainer mdContainer = new Metadata.DeployContainer();
        mdContainer.addMetadata(customMetadata);
        MHolt.CustomMetadataCallback callback = new MHolt.CustomMetadataCallback();
        Id jobId = Metadata.Operations.enqueueDeployment(mdContainer, callback);
    }

    @AuraEnabled
    public static String refreshAccessToken() {
        ECA_Auth__mdt auth = getAquivaDemoAuth('Aquiva_Labs_Demo');

        HttpRequest req = new HttpRequest();
        req.setEndpoint(auth.token_url__c);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        req.setBody('grant_type=refresh_token' +
                    '&refresh_token=' + EncodingUtil.urlEncode(auth.Refresh_token__c, 'UTF-8') +
                    '&client_id=' + EncodingUtil.urlEncode(auth.client_id__c, 'UTF-8') +
                    '&client_secret=' + EncodingUtil.urlEncode(auth.client_secret__c, 'UTF-8'));

        Http http = new Http();
        HttpResponse res = http.send(req);
        
        if (res.getStatusCode() == 200) {
            Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            String accessToken = (String) responseMap.get('access_token');
            deployCMT('Aquiva_Labs_Demo', accessToken, null);
            return 'Authorised';
        } else {
            throw new AuraHandledException('Failed to obtain access token: ' + res.getBody());
        }
    }
}
