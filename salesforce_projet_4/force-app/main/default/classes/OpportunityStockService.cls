public with sharing class OpportunityStockService {

    public static void updateStock(List<OpportunityLineItem> lineItems) {

        if (lineItems == null || lineItems.isEmpty()) {
            return;
        }

        if (!Schema.sObjectType.Product2.isUpdateable()) {
            throw new AuraHandledException('Stock update not allowed.');
        }

        /* ===============================
           1️⃣ Récupérer PricebookEntry
        =============================== */

        Set<Id> pbeIds = new Set<Id>();
        for (OpportunityLineItem oli : lineItems) {
            if (oli.PricebookEntryId != null) {
                pbeIds.add(oli.PricebookEntryId);
            }
        }

        if (pbeIds.isEmpty()) return;

        Map<Id, PricebookEntry> pbeMap = new Map<Id, PricebookEntry>(
            [SELECT Id, Product2Id
             FROM PricebookEntry
             WHERE Id IN :pbeIds]
        );

        /* ===============================
           2️⃣ Récupérer Product2
        =============================== */

        Set<Id> productIds = new Set<Id>();
        for (PricebookEntry pbe : pbeMap.values()) {
            if (pbe.Product2Id != null) {
                productIds.add(pbe.Product2Id);
            }
        }

        if (productIds.isEmpty()) return;

        Map<Id, Product2> productMap = new Map<Id, Product2>(
            [SELECT Id, QuantityInStock__c
             FROM Product2
             WHERE Id IN :productIds
             FOR UPDATE]
        );

        /* ===============================
           3️⃣ Calcul quantité demandée
        =============================== */

        Map<Id, Decimal> quantityPerProduct = new Map<Id, Decimal>();

        for (OpportunityLineItem oli : lineItems) {

            PricebookEntry pbe = pbeMap.get(oli.PricebookEntryId);
            if (pbe == null || pbe.Product2Id == null) continue;

            Decimal qty = oli.Quantity == null ? 0 : oli.Quantity;

            quantityPerProduct.put(
                pbe.Product2Id,
                quantityPerProduct.containsKey(pbe.Product2Id)
                    ? quantityPerProduct.get(pbe.Product2Id) + qty
                    : qty
            );
        }

        Boolean hasError = false;

        /* ===============================
           4️⃣ Vérification & Décrément
        =============================== */

        for (Id productId : quantityPerProduct.keySet()) {

            Product2 prod = productMap.get(productId);
            if (prod == null) continue;

            Decimal currentStock =
                prod.QuantityInStock__c == null ? 0 : prod.QuantityInStock__c;

            Decimal requestedQty = quantityPerProduct.get(productId);

            if (currentStock < requestedQty) {

                hasError = true;

                for (OpportunityLineItem oli : lineItems) {
                    PricebookEntry pbe = pbeMap.get(oli.PricebookEntryId);
                    if (pbe != null && pbe.Product2Id == productId) {
                        oli.addError(System.Label.Opportunity_Stock_Error);
                    }
                }

            } else {
                prod.QuantityInStock__c = currentStock - requestedQty;
            }
        }

        /* ===============================
           5️⃣ Update uniquement si OK
        =============================== */

        if (!hasError) {
            update productMap.values();
        }
    }
}