@IsTest
public class OpportunityProductControllerTest {

    @IsTest
    static void testGetOpportunityProducts() {

        Account acc = new Account(Name = 'Client Test');
        insert acc;

        // Récupération et activation du Standard Pricebook
        Id standardPricebookId = Test.getStandardPricebookId();

        Pricebook2 pb = new Pricebook2(
            Id = standardPricebookId,
            IsActive = true
        );
        update pb;

        Opportunity opp = new Opportunity(
            Name = 'Opportunity Test',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            AccountId = acc.Id
        );
        insert opp;

        // 🔥 Important : associer le Pricebook APRÈS insertion
        opp.Pricebook2Id = standardPricebookId;
        update opp;

        Product2 prod = new Product2(
            Name = 'Produit Test',
            IsActive = true,
            QuantityInStock__c = 10
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
            Quantity = 2
        );
        insert oli;

        Test.startTest();
        List<OpportunityProductController.OpportunityProductWrapper> result =
            OpportunityProductController.getOpportunityProducts(opp.Id);
        Test.stopTest();

        System.assertEquals(1, result.size());
        System.assertEquals('Produit Test', result[0].productName);
        System.assertEquals(2, result[0].quantity);
        System.assertEquals(200, result[0].totalPrice);
        System.assertEquals(10, result[0].quantityInStock);
    }
}