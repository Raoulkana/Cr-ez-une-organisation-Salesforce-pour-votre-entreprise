public with sharing class OpportunityProductController {

    /**
     * Wrapper utilisé pour l'affichage dans la DataTable LWC
     */
    public class OpportunityProductWrapper {

        @AuraEnabled public Id id;
        @AuraEnabled public String productName;
        @AuraEnabled public Decimal quantity;
        @AuraEnabled public Decimal unitPrice;
        @AuraEnabled public Decimal totalPrice;
        @AuraEnabled public Decimal quantityInStock;
    }

    /**
     * Récupère les produits liés à une opportunité donnée
     */
    @AuraEnabled(cacheable=true)
    public static List<OpportunityProductWrapper> getOpportunityProducts(Id opportunityId) {

        List<OpportunityProductWrapper> results = new List<OpportunityProductWrapper>();

        if (opportunityId == null) {
            return results;
        }

        List<OpportunityLineItem> oliList = [
            SELECT
                Id,
                Quantity,
                UnitPrice,
                TotalPrice,
                PricebookEntry.Product2.Name,
                PricebookEntry.Product2.QuantityInStock__c
            FROM OpportunityLineItem
            WHERE OpportunityId = :opportunityId
        ];

        for (OpportunityLineItem oli : oliList) {

            OpportunityProductWrapper wrap = new OpportunityProductWrapper();
            wrap.id = oli.Id;
            wrap.productName = oli.PricebookEntry.Product2.Name;
            wrap.quantity = oli.Quantity;
            wrap.unitPrice = oli.UnitPrice;
            wrap.totalPrice = oli.TotalPrice;
            wrap.quantityInStock = oli.PricebookEntry.Product2.QuantityInStock__c;

            results.add(wrap);
        }

        return results;
    }
}