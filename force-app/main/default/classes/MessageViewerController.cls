public with sharing class MessageViewerController {
    @AuraEnabled(cacheable=true)
    public static List<ECA_message__c> getMessages() {
        return [SELECT Id, message__c, CreatedDate FROM ECA_message__c ORDER BY CreatedDate DESC];
    }
}
