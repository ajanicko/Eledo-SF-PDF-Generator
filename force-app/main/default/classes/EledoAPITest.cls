@isTest
private class EledoAPITest {
    @isTest
    static void testGeneratePDF() {
        Integer numTemplates = 1;
        String sObjName = 'Account';
        Eledo_Template__c[] templates = EledoTestDataFactory.createTemplates(
            numTemplates,
            sObjName
        );
        EledoTestDataFactory.createEledoConnectionSettings();
        Account testAcc = EledoTestDataFactory.createAccount();
        Test.setMock(
            HttpCalloutMock.class,
            new EledoTestDataFactory.EledoCalloutSuccessMock()
        );

        Test.startTest();
        AuraHandledException unexpectedException;
        try {
            EledoAPI.generatePDF(testAcc.Id, templates[0].Name);
        } catch (AuraHandledException e) {
            unexpectedException = e;
        }
        Test.stopTest();

        System.assertEquals(
            null,
            unexpectedException,
            'There should have been no exception. ' +
            unexpectedException?.getMessage()
        );
    }

    @isTest
    static void testGeneratePDFCatchAuraHandledException() {
        Account testAcc = EledoTestDataFactory.createAccount();

        Test.startTest();
        AuraHandledException excp;
        try {
            EledoAPI.generatePDF(testAcc.Id, 'Bad Name');
        } catch (AuraHandledException e) {
            excp = e;
        }
        Test.stopTest();

        System.assert(excp != null, 'There should have been an exception');
    }

    @isTest
    static void testGeneratePDFCatchAuraHandledExceptionResponseNot200() {
        Integer numTemplates = 1;
        String sObjName = 'Account';
        Eledo_Template__c[] templates = EledoTestDataFactory.createTemplates(
            numTemplates,
            sObjName
        );
        EledoTestDataFactory.createEledoConnectionSettings();
        Account testAcc = EledoTestDataFactory.createAccount();
        Test.setMock(
            HttpCalloutMock.class,
            new EledoTestDataFactory.EledoCalloutFailureMock()
        );

        Test.startTest();
        AuraHandledException excp;
        try {
            EledoAPI.generatePDF(testAcc.Id, templates[0].Name);
        } catch (AuraHandledException e) {
            excp = e;
        }
        Test.stopTest();

        System.assert(
            excp != null,
            'There should have been an exception based on response code different from 200'
        );
    }

    @isTest
    static void testGetTemplates() {
        EledoTestDataFactory.createEledoConnectionSettings();
        Test.setMock(
            HttpCalloutMock.class,
            new EledoTestDataFactory.EledoCalloutSuccessMock()
        );

        Test.startTest();
        AuraHandledException unexpectedException;
        try {
            EledoAPI.getTemplates();
        } catch (AuraHandledException e) {
            unexpectedException = e;
        }
        Test.stopTest();

        System.assertEquals(
            null,
            unexpectedException,
            'There should have been no exception. ' +
            unexpectedException?.getMessage()
        );
    }

    @isTest
    static void testGetTemplatesCatchAuraHandledExceptionResponseNot200() {
        EledoTestDataFactory.createEledoConnectionSettings();
        Test.setMock(
            HttpCalloutMock.class,
            new EledoTestDataFactory.EledoCalloutFailureMock()
        );

        Test.startTest();
        AuraHandledException excp;
        try {
            EledoAPI.getTemplates();
        } catch (AuraHandledException e) {
            excp = e;
        }
        Test.stopTest();

        System.assert(
            excp != null,
            'There should have been an exception based on response code different from 200'
        );
    }
}
