@IsTest
public class OpportunityProductControllerTest {

    @IsTest
    static void testGetOpportunityProducts() {

        // 1️⃣ Account
        Account acc = new Account(Name = 'Client Test');
        insert acc;

        // 2️⃣ Récupération du Standard Pricebook
        Id standardPricebookId = Test.getStandardPricebookId();

        Pricebook2 standardPb = [
            SELECT Id, IsActive
            FROM Pricebook2
            WHERE Id = :standardPricebookId
        ];
        standardPb.IsActive = true;
        update standardPb;

        // 3️⃣ Product
        Product2 prod = new Product2(
            Name = 'Produit Test',
            IsActive = true,
            QuantityInStock__c = 10
        );
        insert prod;

        // 4️⃣ OBLIGATOIRE : créer d’abord une entrée standard
        PricebookEntry standardEntry = new PricebookEntry(
            Pricebook2Id = standardPricebookId,
            Product2Id = prod.Id,
            UnitPrice = 100,
            IsActive = true,
            UseStandardPrice = false
        );
        insert standardEntry;

        // 5️⃣ Opportunity
        Opportunity opp = new Opportunity(
            Name = 'Opportunity Test',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            AccountId = acc.Id,
            Pricebook2Id = standardPricebookId
        );
        insert opp;

        // 6️⃣ OpportunityLineItem
        OpportunityLineItem oli = new OpportunityLineItem(
            OpportunityId = opp.Id,
            PricebookEntryId = standardEntry.Id,
            Quantity = 2,
            UnitPrice = 100
        );
        insert oli;

        // 7️⃣ Test controller
        Test.startTest();
        List<OpportunityProductController.OpportunityProductWrapper> result =
            OpportunityProductController.getOpportunityProducts(opp.Id);
        Test.stopTest();

        // 8️⃣ Assertions
        System.assertEquals(1, result.size());
        OpportunityProductController.OpportunityProductWrapper wrap = result[0];

        System.assertEquals('Produit Test', wrap.productName);
        System.assertEquals(2, wrap.quantity);
        System.assertEquals(100, wrap.unitPrice);
        System.assertEquals(200, wrap.totalPrice);
        System.assertEquals(10, wrap.quantityInStock);
    }
}