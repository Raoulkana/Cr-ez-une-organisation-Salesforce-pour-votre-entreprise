@IsTest
public class OpportunityStockServiceTest {

    private static Id oppId;
    private static Id pbeId;
    private static Id productId;

    @testSetup
    static void setupData() {

        // 1️⃣ Account
        Account acc = new Account(Name='Stock Account');
        insert acc;

        // 2️⃣ Standard Pricebook
        Id standardPricebookId = Test.getStandardPricebookId();

        // 3️⃣ Opportunity
        Opportunity opp = new Opportunity(
            Name='Stock Opp',
            StageName='Prospecting',
            CloseDate=Date.today(),
            AccountId = acc.Id,
            Pricebook2Id = standardPricebookId
        );
        insert opp;
        oppId = opp.Id;

        // 4️⃣ Product avec stock
        Product2 prod = new Product2(
            Name='Stock Product',
            IsActive=true,
            Stock__c = 10
        );
        insert prod;
        productId = prod.Id;

        // 5️⃣ PricebookEntry
        PricebookEntry pbe = new PricebookEntry(
            Product2Id=prod.Id,
            Pricebook2Id=standardPricebookId,
            UnitPrice=50,
            IsActive=true
        );
        insert pbe;
        pbeId = pbe.Id;
    }

    // 🔴 TEST STOCK DÉPASSÉ
    @IsTest
    static void testQuantityExceeded() {

        Opportunity opp = [SELECT Id FROM Opportunity WHERE Id = :oppId];
        PricebookEntry pbe = [SELECT Id FROM PricebookEntry WHERE Id = :pbeId];

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
                e.getMessage().contains('Stock insuffisant'),
                'Le message attendu n’a pas été trouvé.'
            );
        }

        Test.stopTest();
    }

    // 🟢 TEST CAS VALIDE
    @IsTest
    static void testValidQuantity() {

        Opportunity opp = [SELECT Id FROM Opportunity WHERE Id = :oppId];
        PricebookEntry pbe = [SELECT Id FROM PricebookEntry WHERE Id = :pbeId];

        Test.startTest();

        OpportunityLineItem oli = new OpportunityLineItem(
            OpportunityId=opp.Id,
            Quantity=5,
            UnitPrice=50,
            PricebookEntryId=pbe.Id
        );
        insert oli;

        Test.stopTest();

        System.assertNotEquals(null, oli.Id);

        Product2 updatedProd = [
            SELECT Stock__c
            FROM Product2
            WHERE Id = :productId
        ];

        System.assertEquals(5, updatedProd.Stock__c);
    }

    // 🟢 TEST BULK (IMPORTANT)
    @IsTest
    static void testBulkInsert() {

        Opportunity opp = [SELECT Id FROM Opportunity WHERE Id = :oppId];
        PricebookEntry pbe = [SELECT Id FROM PricebookEntry WHERE Id = :pbeId];

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
            SELECT Stock__c
            FROM Product2
            WHERE Id = :productId
        ];

        // Stock initial = 10
        // 2 lignes de 2 = 4 vendus
        System.assertEquals(6, updatedProd.Stock__c);
    }
}