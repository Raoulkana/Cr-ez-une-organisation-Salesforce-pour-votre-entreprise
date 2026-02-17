public with sharing class OpportunityProductController {

    /*
     * ===============================
     * READ
     * ===============================
     */
    @AuraEnabled(cacheable=true)
    public static List<OpportunityLineWrapper> getOpportunityProducts(Id opportunityId){

        if(opportunityId == null){
            throw new AuraHandledException('Opportunity Id is required');
        }

        if(!Schema.sObjectType.OpportunityLineItem.isAccessible()){
            throw new AuraHandledException('Access denied.');
        }

        List<OpportunityLineItem> lines = [
            SELECT Id,
                   Quantity,
                   UnitPrice,
                   TotalPrice,
                   PricebookEntry.Product2.Id,
                   PricebookEntry.Product2.Name
            FROM OpportunityLineItem
            WHERE OpportunityId = :opportunityId
        ];

        List<OpportunityLineWrapper> results = new List<OpportunityLineWrapper>();

        for(OpportunityLineItem oli : lines){
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
    public static void deleteOpportunityProduct(Id lineId){

        if(lineId == null){
            throw new AuraHandledException('Line Id is required');
        }

        if(!Schema.sObjectType.OpportunityLineItem.isDeletable()){
            throw new AuraHandledException('Delete not allowed.');
        }

        List<OpportunityLineItem> records =
            [SELECT Id FROM OpportunityLineItem WHERE Id = :lineId LIMIT 1];

        if(records.isEmpty()){
            throw new AuraHandledException('Line not found.');
        }

        delete records[0];
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
    ){

        if(opportunityId == null || pricebookEntryId == null || quantity == null){
            throw new AuraHandledException('Missing required fields.');
        }

        if(quantity <= 0){
            throw new AuraHandledException('Quantity must be greater than 0.');
        }

        if(!Schema.sObjectType.OpportunityLineItem.isCreateable()){
            throw new AuraHandledException('Create not allowed.');
        }

        // Récupération du prix depuis le PricebookEntry (évite hard-coded)
        PricebookEntry pbe = [
            SELECT Id, UnitPrice
            FROM PricebookEntry
            WHERE Id = :pricebookEntryId
            LIMIT 1
        ];

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
    public static void updateQuantity(Id lineId, Decimal quantity){

        if(lineId == null || quantity == null){
            throw new AuraHandledException('Missing required fields.');
        }

        if(quantity <= 0){
            throw new AuraHandledException('Quantity must be greater than 0.');
        }

        if(!Schema.sObjectType.OpportunityLineItem.isUpdateable()){
            throw new AuraHandledException('Update not allowed.');
        }

        List<OpportunityLineItem> records =
            [SELECT Id, Quantity FROM OpportunityLineItem WHERE Id = :lineId LIMIT 1];

        if(records.isEmpty()){
            throw new AuraHandledException('Line not found.');
        }

        OpportunityLineItem oli = records[0];
        oli.Quantity = quantity;

        update oli;
    }

    /*
     * ===============================
     * WRAPPER
     * ===============================
     */
    public class OpportunityLineWrapper {

        @AuraEnabled public Id id;
        @AuraEnabled public String productName;
        @AuraEnabled public Decimal quantity;
        @AuraEnabled public Decimal totalPrice;

        public OpportunityLineWrapper(OpportunityLineItem oli){
            this.id = oli.Id;
            this.productName = oli.PricebookEntry.Product2.Name;
            this.quantity = oli.Quantity;
            this.totalPrice = oli.TotalPrice;
        }
    }
}