public with sharing class OpportunityStockService {

    public static void updateStock(List<OpportunityLineItem> lineItems){

        if(lineItems == null || lineItems.isEmpty()){
            return;
        }

        // 1️⃣ Récupérer tous les PricebookEntryId
        Set<Id> pbeIds = new Set<Id>();

        for(OpportunityLineItem oli : lineItems){
            if(oli.PricebookEntryId != null){
                pbeIds.add(oli.PricebookEntryId);
            }
        }

        // 2️⃣ Récupérer les PricebookEntry
        Map<Id, PricebookEntry> pbeMap = new Map<Id, PricebookEntry>(
            [SELECT Id, Product2Id 
             FROM PricebookEntry 
             WHERE Id IN :pbeIds]
        );

        // 3️⃣ Récupérer les Product2
        Set<Id> productIds = new Set<Id>();
        for(PricebookEntry pbe : pbeMap.values()){
            productIds.add(pbe.Product2Id);
        }

        Map<Id, Product2> productMap = new Map<Id, Product2>(
            [SELECT Id, Stock__c 
             FROM Product2 
             WHERE Id IN :productIds]
        );

        // 4️⃣ Vérifier et décrémenter
        for(OpportunityLineItem oli : lineItems){

            PricebookEntry pbe = pbeMap.get(oli.PricebookEntryId);
            Product2 prod = productMap.get(pbe.Product2Id);

            if(prod.Stock__c == null){
                prod.Stock__c = 0;
            }

            if(prod.Stock__c < oli.Quantity){
                oli.addError('Stock insuffisant pour ce produit.');
            } else {
                prod.Stock__c -= oli.Quantity;
            }
        }

        // 5️⃣ Mise à jour
        if(!productMap.isEmpty()){
            update productMap.values();
        }
    }
}