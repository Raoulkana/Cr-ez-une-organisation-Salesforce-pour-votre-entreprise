@IsTest
public class OpportunityProductControllerTest {

    @IsTest
    static void testGetOpportunityProducts() {

        // 1️⃣ Compte
        Account acc = new Account(Name = 'Client Test');
        insert acc;

        // 2️⃣ Opportunité
        Opportunity opp = new Opportunity(
            Name = 'Opportunity Test',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            AccountId = acc.Id
        );
        insert opp;

        // 3️⃣ Produit
        Product2 prod = new Product2(
            Name = 'Produit Test',
            IsActive = true
        );
        insert prod;

        // 4️⃣ Standard Pricebook (CORRECT)
        Id standardPricebookId = Test.getStandardPricebookId();

        // 5️⃣ PricebookEntry
        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = standardPricebookId,
            Product2Id   = prod.Id,
            UnitPrice    = 100,
            IsActive     = true
        );
        insert pbe;

        // 6️⃣ OpportunityLineItem
        OpportunityLineItem oli = new OpportunityLineItem(
            OpportunityId = opp.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 2,
            UnitPrice = 100
        );
        insert oli;

        // 7️⃣ Appel méthode testée (SIGNATURE OK)
        Test.startTest();
        List<OpportunityProductController.OpportunityProductWrapper> result =
            OpportunityProductController.getOpportunityProducts(opp.Id);
        Test.stopTest();

        // 8️⃣ Assertions
        System.assertEquals(1, result.size());
        System.assertEquals('Produit Test', result[0].productName);
        System.assertEquals(2, result[0].quantity);
        System.assertEquals(200, result[0].totalPrice);
    }
}