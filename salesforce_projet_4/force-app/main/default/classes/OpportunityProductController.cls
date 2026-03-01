public with sharing class OpportunityProductController {

    /*
     * ===============================
     * READ
     * ===============================
     */
    @AuraEnabled(cacheable=true)
    public static List<OpportunityLineWrapper> getOpportunityProducts(Id opportunityId) {

        if (opportunityId == null) {
            throw new AuraHandledException('Opportunity Id is required');
        }

        if (!Schema.sObjectType.OpportunityLineItem.isAccessible()) {
            throw new AuraHandledException('Access denied.');
        }

        List<OpportunityLineItem> lines = [
            SELECT
                Id,
                Quantity,
                UnitPrice,
                TotalPrice,
                PricebookEntryId,
                PricebookEntry.Product2.Id,
                PricebookEntry.Product2.Name,
                PricebookEntry.Product2.QuantityInStock__c
            FROM OpportunityLineItem
            WHERE OpportunityId = :opportunityId
        ];

        List<OpportunityLineWrapper> results = new List<OpportunityLineWrapper>();

        for (OpportunityLineItem oli : lines) {
            results.add(new OpportunityLineWrapper(oli));
        }

        return results;
    }

    /*
     * ===============================
     * DELETE
     * ===============================
     */
    @AuraEnabled
    public static void deleteOpportunityProduct(Id lineId) {

        if (lineId == null) {
            throw new AuraHandledException('Line Id is required');
        }

        if (!Schema.sObjectType.OpportunityLineItem.isDeletable()) {
            throw new AuraHandledException('Delete not allowed.');
        }

        List<OpportunityLineItem> lines = [
            SELECT Id
            FROM OpportunityLineItem
            WHERE Id = :lineId
            LIMIT 1
        ];

        if (lines.isEmpty()) {
            throw new AuraHandledException('Line not found.');
        }

        delete lines[0];
    }

    /*
     * ===============================
     * CREATE
     * ===============================
     */
    @AuraEnabled
    public static Id createOpportunityProduct(
        Id opportunityId,
        Id pricebookEntryId,
        Decimal quantity
    ) {

        if (opportunityId == null || pricebookEntryId == null || quantity == null) {
            throw new AuraHandledException('Missing required fields.');
        }

        if (quantity <= 0) {
            throw new AuraHandledException('Quantity must be greater than 0.');
        }

        if (!Schema.sObjectType.OpportunityLineItem.isCreateable()) {
            throw new AuraHandledException('Create not allowed.');
        }

        PricebookEntry pbe = [
            SELECT Id, UnitPrice, IsActive
            FROM PricebookEntry
            WHERE Id = :pricebookEntryId
            LIMIT 1
        ];

        if (!pbe.IsActive) {
            throw new AuraHandledException('Pricebook entry is not active.');
        }

        OpportunityLineItem oli = new OpportunityLineItem(
            OpportunityId = opportunityId,
            PricebookEntryId = pricebookEntryId,
            Quantity = quantity,
            UnitPrice = pbe.UnitPrice
        );

        insert oli;

        return oli.Id;
    }

    /*
     * ===============================
     * UPDATE
     * ===============================
     */
    @AuraEnabled
    public static void updateQuantity(Id lineId, Decimal quantity) {

        if (lineId == null || quantity == null) {
            throw new AuraHandledException('Missing required fields.');
        }

        if (quantity <= 0) {
            throw new AuraHandledException('Quantity must be greater than 0.');
        }

        if (!Schema.sObjectType.OpportunityLineItem.isUpdateable()) {
            throw new AuraHandledException('Update not allowed.');
        }

        List<OpportunityLineItem> lines = [
            SELECT Id, Quantity
            FROM OpportunityLineItem
            WHERE Id = :lineId
            LIMIT 1
        ];

        if (lines.isEmpty()) {
            throw new AuraHandledException('Line not found.');
        }

        OpportunityLineItem oli = lines[0];
        oli.Quantity = quantity;
        update oli;
    }

    /*
     * ===============================
     * WRAPPER
     * ===============================
     */
    public class OpportunityLineWrapper {

        @AuraEnabled public Id Id;
        @AuraEnabled public String productName;
        @AuraEnabled public Id productId;
        @AuraEnabled public Decimal quantity;
        @AuraEnabled public Decimal unitPrice;
        @AuraEnabled public Decimal totalPrice;

        // 🔥 NOUVEAU CHAMP OBLIGATOIRE
        @AuraEnabled public Decimal quantityInStock;

        public OpportunityLineWrapper(OpportunityLineItem oli) {

            this.Id = oli.Id;
            this.quantity = oli.Quantity;
            this.unitPrice = oli.UnitPrice;
            this.totalPrice = oli.TotalPrice;

            if (oli.PricebookEntry != null &&
                oli.PricebookEntry.Product2 != null) {

                this.productName = oli.PricebookEntry.Product2.Name;
                this.productId = oli.PricebookEntry.Product2.Id;

                // 🔥 IMPORTANT : stock exposé au LWC
                this.quantityInStock =
                    oli.PricebookEntry.Product2.QuantityInStock__c;
            }
        }
    }
}