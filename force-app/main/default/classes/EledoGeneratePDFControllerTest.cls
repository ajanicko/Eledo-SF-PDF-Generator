@isTest
private class EledoGeneratePDFControllerTest {
    @isTest
    static void testfindTemplates() {
        Integer numTemplates = 1;
        String sObjName = 'Account';
        Eledo_Template__c[] templates = EledoTestDataFactory.createTemplates(
            numTemplates,
            sObjName
        );

        Test.startTest();
        List<Eledo_Template__c> foundTemplates = EledoGeneratePDFController.findTemplates(
            sObjName
        );
        Test.stopTest();

        Integer numberOfFoundTemplates = foundTemplates.size();
        System.assertEquals(
            numTemplates,
            numberOfFoundTemplates,
            'Expected ' +
            numTemplates +
            '.' +
            ' Actual ' +
            numberOfFoundTemplates +
            '.'
        );
    }
}
