trigger OpportunityLineItemTrigger
on OpportunityLineItem (before insert, before update) {

    if(Trigger.isBefore){
        OpportunityStockService.handleStock(
            Trigger.new,
            Trigger.oldMap
        );
    }
}