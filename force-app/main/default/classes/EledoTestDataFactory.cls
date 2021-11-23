@isTest
public class EledoTestDataFactory {
    public static List<Eledo_Template__c> createTemplates(
        Integer numTemplates,
        String sObjName
    ) {
        List<Eledo_Template__c> templates = new List<Eledo_Template__c>();

        for (Integer i = 0; i < numTemplates; i++) {
            Eledo_Template__c t = new Eledo_Template__c(
                Name = 'TestTemplate' + i,
                Object__c = sObjName,
                Template_ID__c = 'TestTemplateId' + i,
                SOQL__c = 'SELECT Id FROM ' + sObjName
            );
            templates.add(t);
        }
        insert templates;
        return templates;
    }

    public static Eledo_Connection_Setting__mdt createEledoConnectionSettings() {
        return new Eledo_Connection_Setting__mdt(
            MasterLabel = 'testLabel',
            DeveloperName = 'testName',
            Api_Key__c = 'testKey',
            Endpoint__c = 'testEndpoint'
        );
    }

    public static Account createAccount() {
        Account a = new Account(Name = 'TestAccount');
        insert a;
        return a;
    }

    public class EledoCalloutSuccessMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"example":"test"}');
            res.setStatusCode(200);
            return res;
        }
    }

    public class EledoCalloutFailureMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"example":"test"}');
            res.setStatusCode(500);
            return res;
        }
    }
}
