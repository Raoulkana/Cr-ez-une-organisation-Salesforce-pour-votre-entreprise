@IsTest
public class OpportunityProductControllerTest {

    @IsTest
    static void testGetOpportunityProducts() {

        // 1. Création du compte
        Account acc = new Account(Name = 'Client Test');
        insert acc;

        // 2. Création de l’opportunité
        Opportunity opp = new Opportunity(
            Name = 'Opportunity Test',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            AccountId = acc.Id
        );
        insert opp;

        // 3. Création du produit
        Product2 prod = new Product2(
            Name = 'Produit Test',
            IsActive = true
        );
        insert prod;

        // 4. Récupération du Pricebook standard
        Pricebook2 standardPb = [
            SELECT Id FROM Pricebook2 WHERE IsStandard = true LIMIT 1
        ];

        // 5. Création du PricebookEntry
        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = standardPb.Id,
            Product2Id   = prod.Id,
            UnitPrice    = 100,
            IsActive     = true
        );
        insert pbe;

        // 6. Lien Produit ↔ Opportunité
        OpportunityLineItem oli = new OpportunityLineItem(
            OpportunityId = opp.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 2,
            UnitPrice = 100
        );
        insert oli;

        // 7. Appel de la méthode testée
        Test.startTest();
        List<OpportunityProductController.OpportunityProductWrapper> result =
            OpportunityProductController.getOpportunityProducts();
        Test.stopTest();

        // 8. Vérifications
        System.assertEquals(1, result.size());
        System.assertEquals('Opportunity Test', result[0].opportunityName);
        System.assertEquals('Produit Test', result[0].productName);
        System.assertEquals(2, result[0].quantity);
        System.assertEquals(200, result[0].totalPrice);
    }
}