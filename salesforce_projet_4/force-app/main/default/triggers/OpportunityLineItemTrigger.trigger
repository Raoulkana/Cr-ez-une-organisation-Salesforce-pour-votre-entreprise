trigger OpportunityLineItemTrigger 
on OpportunityLineItem (before insert) {

    if(Trigger.isBefore && Trigger.isInsert){
        OpportunityStockService.updateStock(Trigger.new);
    }
}