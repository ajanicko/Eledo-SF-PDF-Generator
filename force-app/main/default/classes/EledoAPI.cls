public with sharing class EledoAPI {
    @TestVisible
    private static Eledo_Connection_Setting__mdt testSetting;

    private static Eledo_Connection_Setting__mdt getEndpoint() {
        if (Test.isRunningTest()) {
            return testSetting;
        } else {
            return Eledo_Connection_Setting__mdt.getAll().values()[0];
        }
    }

    private static Eledo_Template__c getTemplate(String templateName) {
        Eledo_Template__c template = [
            SELECT Name, Object__c, SOQL__c, Template_ID__c
            FROM Eledo_Template__c
            WHERE Name = :templateName
        ][0];
        return template;
    }

    @SuppressWarnings('PMD.ApexSOQLInjection')
    private static String getData(Id recordId, Eledo_Template__c template) {
        sObject dataObject = Database.query(
            template.SOQL__c +
            ' WHERE Id = \'' +
            recordId +
            '\''
        );
        return JSON.serialize(dataObject);
    }

    private static HTTPResponse getPDF(
        Eledo_Connection_Setting__mdt endpoint,
        String data,
        String templateId
    ) {
        HTTP h = new HTTP();
        HTTPRequest req = new HTTPRequest();
        req.setEndpoint(endpoint.Endpoint__c + 'Generate');
        req.setMethod('GET');
        req.setHeader('Api-Key', endpoint.Api_Key__c);
        req.setHeader('Content-Type', 'application/json');
        req.setBody(
            '{\r\n\"templateId\":\"' +
            templateId +
            '\",\"file\":' +
            data +
            '}'
        );
        HTTPResponse res = h.send(req);
        return res;
    }

    @SuppressWarnings('PMD.ApexCRUDViolation')
    @AuraEnabled
    public static void generatePDF(Id recordId, String templateName) {
        try {
            Eledo_Template__c template = getTemplate(templateName);
            Eledo_Connection_Setting__mdt endpoint = getEndpoint();
            String data = getData(recordId, template);
            HTTPResponse res = getPDF(endpoint, data, template.Template_ID__c);
            if (res.getStatusCode() == 200) {
                Attachment attachment = new Attachment();
                attachment.Body = res.getBodyAsBlob();
                attachment.Name = template.Name + '.pdf';
                attachment.IsPrivate = false;
                attachment.ParentId = recordId;
                insert attachment;
            } else {
                //throw error status code response to frontend
                throw new CalloutException(res.getBody());
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static String getTemplates() {
        Eledo_Connection_Setting__mdt endpoint;
        try {
            endpoint = getEndpoint();
        } catch (ListException e) {
            throw new AuraHandledException(
                'Eledo Connection Settings custom metadata type not set. You will not be able to select a template from Eledo.'
            );
        }

        HTTP h = new HTTP();
        HTTPRequest req = new HTTPRequest();
        req.setEndpoint(endpoint.Endpoint__c + 'List?scope=Mine');
        req.setMethod('GET');
        req.setHeader('Api-Key', endpoint.Api_Key__c);
        req.setHeader('Content-Type', 'application/json');
        HTTPResponse res = h.send(req);
        if (res.getStatusCode() == 200) {
            return res.getBody();
        } else {
            //throw error status code response to frontend
            throw new AuraHandledException(res.getBody());
        }
    }
}
