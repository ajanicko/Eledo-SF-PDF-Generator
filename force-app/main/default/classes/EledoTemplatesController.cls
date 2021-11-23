public with sharing class EledoTemplatesController {
    @AuraEnabled(cacheable=true)
    public static List<String> getObjects() {
        List<String> objectList = new List<String>();
        for (
            Schema.SObjectType objectType : Schema.getGlobalDescribe().Values()
        ) {
            objectList.add(String.valueOf(objectType));
        }
        objectList.sort();
        return objectList;
    }

    @SuppressWarnings('PMD.ApexSOQLInjection')
    @AuraEnabled
    public static void validateSoql(String query) {
        try {
            Database.query(query + ' LIMIT 0');
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @SuppressWarnings('PMD.ApexCrudViolation')
    @AuraEnabled
    public static Eledo_Template__c getTemplate(String recordId) {
        try {
            return [
                SELECT Name, Object__c, SOQL__c, Template_ID__c
                FROM Eledo_Template__c
                WHERE Id = :recordId
            ];
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}
