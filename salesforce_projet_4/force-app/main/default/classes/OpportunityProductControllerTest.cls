@IsTest
public class OpportunityProductControllerTest {
    
    private static OpportunityLineItem createTestData() {
        Account acc = new Account(Name = 'Client Test');
        insert acc;

        Id standardPricebookId = Test.getStandardPricebookId();

        Opportunity opp = new Opportunity(
            Name = 'Opportunity Test',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            AccountId = acc.Id,
            Pricebook2Id = standardPricebookId
        );
        insert opp;

        // 🔥 Champ de stock correct
        Product2 prod = new Product2(
            Name = 'Produit Test',
            IsActive = true,
            QuantityInStock__c = 100
        );
        insert prod;

        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = standardPricebookId,
            Product2Id = prod.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert pbe;

        OpportunityLineItem oli = new OpportunityLineItem(
            OpportunityId = opp.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 2,
            UnitPrice = 100
        );
        insert oli;

        return oli;
    }

    // ==========================================
    // TEST READ
    // ==========================================
    @IsTest
    static void testGetOpportunityProducts() {
        OpportunityLineItem oli = createTestData();

        Test.startTest();
        List<OpportunityProductController.OpportunityLineWrapper> result =
            OpportunityProductController.getOpportunityProducts(oli.OpportunityId);
        Test.stopTest();

        System.assertEquals(1, result.size());
        System.assertEquals('Produit Test', result[0].productName);
        System.assertEquals(2, result[0].quantity);
        System.assertEquals(100, result[0].unitPrice);
        System.assertEquals(200, result[0].totalPrice);
        System.assertEquals(100, result[0].quantityInStock); // vérification stock
        System.assertNotEquals(null, result[0].productId);
    }

    // ==========================================
    // TEST CREATE
    // ==========================================
    @IsTest
    static void testCreateOpportunityProduct() {
        OpportunityLineItem existing = createTestData();

        Test.startTest();
        Id newLineId = OpportunityProductController.createOpportunityProduct(
            existing.OpportunityId,
            existing.PricebookEntryId,
            3
        );
        Test.stopTest();

        OpportunityLineItem newLine = [
            SELECT Quantity
            FROM OpportunityLineItem
            WHERE Id = :newLineId
        ];

        System.assertEquals(3, newLine.Quantity);
    }

    // ==========================================
    // TEST UPDATE
    // ==========================================
    @IsTest
    static void testUpdateQuantity() {
        OpportunityLineItem oli = createTestData();

        Test.startTest();
        OpportunityProductController.updateQuantity(oli.Id, 5);
        Test.stopTest();

        OpportunityLineItem updated = [
            SELECT Quantity
            FROM OpportunityLineItem
            WHERE Id = :oli.Id
        ];

        System.assertEquals(5, updated.Quantity);
    }

    // ==========================================
    // TEST DELETE
    // ==========================================
    @IsTest
    static void testDeleteOpportunityProduct() {
        OpportunityLineItem oli = createTestData();

        Test.startTest();
        OpportunityProductController.deleteOpportunityProduct(oli.Id);
        Test.stopTest();

        Integer countLines = [
            SELECT COUNT()
            FROM OpportunityLineItem
            WHERE Id = :oli.Id
        ];

        System.assertEquals(0, countLines);
    }

    // ==========================================
    // TEST ERREUR - Id null
    // ==========================================
    @IsTest
    static void testGetOpportunityProductsWithNullId() {
        try {
            OpportunityProductController.getOpportunityProducts(null);
            System.assert(false, 'Exception should have been thrown');
        } catch (AuraHandledException e) {
            System.assertEquals('Opportunity Id is required', e.getMessage());
        }
    }

    // ==========================================
    // TEST ERREUR - Quantité invalide
    // ==========================================
    @IsTest
    static void testUpdateWithInvalidQuantity() {
        OpportunityLineItem oli = createTestData();

        try {
            OpportunityProductController.updateQuantity(oli.Id, 0);
            System.assert(false, 'Exception should have been thrown');
        } catch (AuraHandledException e) {
            System.assertEquals('Quantity must be greater than 0.', e.getMessage());
        }
    }
}