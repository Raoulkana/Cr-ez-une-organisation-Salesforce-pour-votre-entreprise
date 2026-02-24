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

        if(pbeIds.isEmpty()){
            return;
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
            if(pbe.Product2Id != null){
                productIds.add(pbe.Product2Id);
            }
        }

        if(productIds.isEmpty()){
            return;
        }

        Map<Id, Product2> productMap = new Map<Id, Product2>(
            [SELECT Id, Stock__c
             FROM Product2
             WHERE Id IN :productIds
             FOR UPDATE]
        );

        // 4️⃣ Calculer les quantités totales par produit (bulk safe)
        Map<Id, Decimal> quantityPerProduct = new Map<Id, Decimal>();

        for(OpportunityLineItem oli : lineItems){

            PricebookEntry pbe = pbeMap.get(oli.PricebookEntryId);
            if(pbe == null) continue;

            Id productId = pbe.Product2Id;
            if(productId == null) continue;

            Decimal qty = oli.Quantity == null ? 0 : oli.Quantity;

            if(quantityPerProduct.containsKey(productId)){
                quantityPerProduct.put(productId,
                    quantityPerProduct.get(productId) + qty);
            } else {
                quantityPerProduct.put(productId, qty);
            }
        }

        // 5️⃣ Vérification stock
        for(Id productId : quantityPerProduct.keySet()){

            Product2 prod = productMap.get(productId);
            if(prod == null) continue;

            Decimal currentStock = prod.Stock__c == null ? 0 : prod.Stock__c;
            Decimal requestedQty = quantityPerProduct.get(productId);

            if(currentStock < requestedQty){

                // Ajouter erreur sur toutes les lignes concernées
                for(OpportunityLineItem oli : lineItems){
                    PricebookEntry pbe = pbeMap.get(oli.PricebookEntryId);
                    if(pbe != null && pbe.Product2Id == productId){
                        oli.addError('Stock insuffisant pour ce produit.');
                    }
                }

            } else {
                prod.Stock__c = currentStock - requestedQty;
            }
        }

        // 6️⃣ Update uniquement si aucune erreur
        if(!productMap.isEmpty()){
            update productMap.values();
        }
    }
}