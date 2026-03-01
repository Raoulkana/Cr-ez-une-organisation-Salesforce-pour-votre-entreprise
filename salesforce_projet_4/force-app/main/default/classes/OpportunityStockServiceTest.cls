@IsTest
public class OpportunityStockServiceTest {

    @testSetup
    static void setupData() {

        // 1️⃣ Account
        Account acc = new Account(Name='Stock Account');
        insert acc;

        // 2️⃣ Standard Pricebook
        Id standardPricebookId = Test.getStandardPricebookId();

        // 3️⃣ Product avec stock initial = 10
        Product2 prod = new Product2(
            Name='Stock Product',
            IsActive=true,
            QuantityInStock__c = 10
        );
        insert prod;

        // 4️⃣ PricebookEntry
        PricebookEntry pbe = new PricebookEntry(
            Product2Id=prod.Id,
            Pricebook2Id=standardPricebookId,
            UnitPrice=50,
            IsActive=true
        );
        insert pbe;

        // 5️⃣ Opportunity
        Opportunity opp = new Opportunity(
            Name='Stock Opp',
            StageName='Prospecting',
            CloseDate=Date.today(),
            AccountId = acc.Id,
            Pricebook2Id = standardPricebookId
        );
        insert opp;
    }

    // 🔴 TEST STOCK DÉPASSÉ
    @IsTest
    static void testQuantityExceeded() {

        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        PricebookEntry pbe = [SELECT Id FROM PricebookEntry LIMIT 1];

        OpportunityLineItem oli = new OpportunityLineItem(
            OpportunityId = opp.Id,
            Quantity = 200, // > stock 10
            UnitPrice = 50,
            PricebookEntryId = pbe.Id
        );

        Test.startTest();
        try {
            insert oli; // 🔥 le trigger doit bloquer
            System.assert(false, 'Une erreur devait être levée.');
        } 
        catch (DmlException e) {
            System.assert(true);
        }
        Test.stopTest();
    }

    // 🟢 TEST CAS VALIDE
    @IsTest
    static void testValidQuantity() {

        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        PricebookEntry pbe = [SELECT Id, Product2Id FROM PricebookEntry LIMIT 1];
        Product2 prod = [SELECT Id, QuantityInStock__c FROM Product2 LIMIT 1];

        OpportunityLineItem oli = new OpportunityLineItem(
            OpportunityId=opp.Id,
            Quantity=5,
            UnitPrice=50,
            PricebookEntryId=pbe.Id
        );

        Test.startTest();
        insert oli; // 🔥 le trigger décrémente le stock
        Test.stopTest();

        Product2 updatedProd = [
            SELECT QuantityInStock__c
            FROM Product2
            WHERE Id = :prod.Id
        ];

        // 10 - 5 = 5
        System.assertEquals(5, updatedProd.QuantityInStock__c,
            'Stock après vente incorrect');
    }

    // 🟢 TEST BULK
    @IsTest
    static void testBulkInsert() {

        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        PricebookEntry pbe = [SELECT Id, Product2Id FROM PricebookEntry LIMIT 1];
        Product2 prod = [SELECT Id, QuantityInStock__c FROM Product2 LIMIT 1];

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
        insert olis; // 🔥 trigger bulk-safe
        Test.stopTest();

        Product2 updatedProd = [
            SELECT QuantityInStock__c
            FROM Product2
            WHERE Id = :prod.Id
        ];

        // 10 - (2+2) = 6
        System.assertEquals(6, updatedProd.QuantityInStock__c,
            'Stock après bulk incorrect');
    }
}