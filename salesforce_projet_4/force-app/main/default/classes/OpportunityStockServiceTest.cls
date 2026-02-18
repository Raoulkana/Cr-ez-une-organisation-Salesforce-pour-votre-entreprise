@isTest
public class OpportunityStockServiceTest {

    @testSetup
    static void setupData() {

        // 1️⃣ Account
        Account acc = new Account(Name='Stock Account');
        insert acc;

        // 2️⃣ Pricebook standard
        Id standardPricebookId = Test.getStandardPricebookId();

        // 3️⃣ Opportunity AVEC Pricebook
        Opportunity opp = new Opportunity(
            Name='Stock Opp',
            StageName='Prospecting',
            CloseDate=Date.today(),
            AccountId = acc.Id,
            Pricebook2Id = standardPricebookId
        );
        insert opp;

        // 4️⃣ Product avec stock
        Product2 prod = new Product2(
            Name='Stock Product',
            IsActive=true,
            Stock__c = 10   // 🔥 important
        );
        insert prod;

        // 5️⃣ PricebookEntry
        PricebookEntry pbe = new PricebookEntry(
            Product2Id=prod.Id,
            Pricebook2Id=standardPricebookId,
            UnitPrice=50,
            IsActive=true
        );
        insert pbe;
    }

    // 🔴 TEST STOCK DÉPASSÉ
    @isTest
    static void testQuantityExceeded() {

        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        PricebookEntry pbe = [SELECT Id FROM PricebookEntry LIMIT 1];

        Test.startTest();

        try {
            insert new OpportunityLineItem(
                OpportunityId=opp.Id,
                Quantity=200, // > Stock__c = 10
                UnitPrice=50,
                PricebookEntryId=pbe.Id
            );
            System.assert(false, 'Une erreur devait être levée.');
        } catch (DmlException e) {
            System.assert(
                e.getMessage().contains('Stock insuffisant')
            );
        }

        Test.stopTest();
    }

    // 🟢 TEST CAS VALIDE
    @isTest
    static void testValidQuantity() {

        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        PricebookEntry pbe = [SELECT Id FROM PricebookEntry LIMIT 1];

        Test.startTest();

        OpportunityLineItem oli = new OpportunityLineItem(
            OpportunityId=opp.Id,
            Quantity=5,
            UnitPrice=50,
            PricebookEntryId=pbe.Id
        );
        insert oli;

        Test.stopTest();

        // Vérifie insertion
        System.assertNotEquals(null, oli.Id);

        // Vérifie décrémentation stock
        Product2 updatedProd = [
            SELECT Stock__c FROM Product2 LIMIT 1
        ];

        System.assertEquals(5, updatedProd.Stock__c);
    }

    // 🟢 TEST BULK (IMPORTANT CERTIFICATION)
    @isTest
    static void testBulkInsert() {

        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        PricebookEntry pbe = [SELECT Id FROM PricebookEntry LIMIT 1];

        List<OpportunityLineItem> olis = new List<OpportunityLineItem>();

        for(Integer i=0; i<2; i++){
            olis.add(new OpportunityLineItem(
                OpportunityId=opp.Id,
                Quantity=2,
                UnitPrice=50,
                PricebookEntryId=pbe.Id
            ));
        }

        Test.startTest();
        insert olis;
        Test.stopTest();

        Product2 updatedProd = [
            SELECT Stock__c FROM Product2 LIMIT 1
        ];

        // Stock initial = 10
        // 2*2 = 4 vendus
        System.assertEquals(6, updatedProd.Stock__c);
    }
}