@isTest
private class EledoTemplatesControllerTest {
    @isTest
    static void testGetObjects() {
        Test.startTest();
        List<String> objects = EledoTemplatesController.getObjects();
        Test.stopTest();

        System.assert(
            !objects.isEmpty(),
            'All current SF sObjects should be returned.'
        );
    }

    @isTest
    static void testValidateSoql() {
        Test.startTest();
        AuraHandledException unexpectedException;
        try {
            EledoTemplatesController.validateSoql(
                'SELECT Id FROM Eledo_Template__c'
            );
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
    static void testValidateSoqlCatchAuraHandledException() {
        Test.startTest();
        AuraHandledException excp;
        try {
            EledoTemplatesController.validateSoql('Bad SOQL');
        } catch (AuraHandledException e) {
            excp = e;
        }
        Test.stopTest();

        System.assert(excp != null, 'There should have been an exception');
    }

    @isTest
    static void testGetTemplate() {
        Integer numTemplates = 1;
        String sObjName = 'Account';
        Eledo_Template__c[] templates = EledoTestDataFactory.createTemplates(
            numTemplates,
            sObjName
        );

        Test.startTest();
        Eledo_Template__c template = EledoTemplatesController.getTemplate(
            templates[0].Id
        );
        Test.stopTest();

        System.assert(
            template != null,
            'There should have been a templated returned'
        );
    }

    @isTest
    static void testGetTemplateCatchAuraHandledException() {
        Test.startTest();
        AuraHandledException excp;
        try {
            Eledo_Template__c template = EledoTemplatesController.getTemplate(
                'Invalid Id'
            );
        } catch (AuraHandledException e) {
            excp = e;
        }
        Test.stopTest();

        System.assert(excp != null, 'There should have been an exception');
    }
}
