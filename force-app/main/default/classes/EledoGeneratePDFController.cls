public with sharing class EledoGeneratePDFController {
    @AuraEnabled(cacheable=true)
    public static List<Eledo_Template__c> findTemplates(String sObjectName) {
        return [
            SELECT Name
            FROM Eledo_Template__c
            WHERE Object__c = :sObjectName
            WITH SECURITY_ENFORCED
        ];
    }
}
