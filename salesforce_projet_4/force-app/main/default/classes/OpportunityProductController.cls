public with sharing class OpportunityProductController {

  /*
   * ===============================
   * MÉTHODE DE SÉCURITÉ ADMIN
   * ===============================
   */
  private static void checkAdminAccess() {
    User currentUser = [
      SELECT Profile.PermissionsModifyAllData
      FROM User
      WHERE Id = :UserInfo.getUserId()
      LIMIT 1
    ];

    if (!currentUser.Profile.PermissionsModifyAllData) {
      throw new AuraHandledException('Only Admin can perform this action.');
    }
  }

  /*
   * ===============================
   * READ (Autorisé pour tous)
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
      SELECT Id, Quantity, UnitPrice, TotalPrice, PricebookEntryId
      FROM OpportunityLineItem
      WHERE OpportunityId = :opportunityId
    ];

    if (lines.isEmpty()) {
      return new List<OpportunityLineWrapper>();
    }

    Set<Id> pbeIds = new Set<Id>();
    for (OpportunityLineItem oli : lines) {
      pbeIds.add(oli.PricebookEntryId);
    }

    Map<Id, PricebookEntry> pbeMap = new Map<Id, PricebookEntry>(
      [
        SELECT Id, Product2Id, Product2.Name, Product2.QuantityInStock__c
        FROM PricebookEntry
        WHERE Id IN :pbeIds
      ]
    );

    List<OpportunityLineWrapper> results = new List<OpportunityLineWrapper>();

    for (OpportunityLineItem oli : lines) {
      PricebookEntry pbe = pbeMap.get(oli.PricebookEntryId);

      results.add(
        new OpportunityLineWrapper(
          oli.Id,
          oli.Quantity,
          oli.UnitPrice,
          oli.TotalPrice,
          pbe?.Product2Id,
          pbe?.Product2?.Name,
          pbe?.Product2?.QuantityInStock__c
        )
      );
    }

    return results;
  }

  /*
   * ===============================
   * DELETE (Admin uniquement)
   * ===============================
   */
  @AuraEnabled
  public static void deleteOpportunityProduct(Id lineId) {

    checkAdminAccess(); // 🔒 sécurité serveur

    if (lineId == null) {
      throw new AuraHandledException('Line Id is required');
    }

    if (!Schema.sObjectType.OpportunityLineItem.isDeletable()) {
      throw new AuraHandledException('Delete not allowed.');
    }

    OpportunityLineItem oli = [
      SELECT Id
      FROM OpportunityLineItem
      WHERE Id = :lineId
      LIMIT 1
    ];

    delete oli;
  }

  /*
   * ===============================
   * CREATE (Admin uniquement)
   * ===============================
   */
  @AuraEnabled
  public static Id createOpportunityProduct(
    Id opportunityId,
    Id pricebookEntryId,
    Decimal quantity
  ) {

    checkAdminAccess(); // 🔒 sécurité serveur

    if (opportunityId == null || pricebookEntryId == null || quantity == null) {
      throw new AuraHandledException('Missing required fields.');
    }

    if (quantity <= 0) {
      throw new AuraHandledException('Quantity must be greater than 0.');
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
   * UPDATE (Admin uniquement)
   * ===============================
   */
  @AuraEnabled
  public static void updateQuantity(Id lineId, Decimal quantity) {

    checkAdminAccess(); // 🔒 sécurité serveur

    if (lineId == null || quantity == null) {
      throw new AuraHandledException('Missing required fields.');
    }

    if (quantity <= 0) {
      throw new AuraHandledException('Quantity must be greater than 0.');
    }

    OpportunityLineItem oli = [
      SELECT Id, Quantity
      FROM OpportunityLineItem
      WHERE Id = :lineId
      LIMIT 1
    ];

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
    @AuraEnabled public Decimal quantityInStock;

    public OpportunityLineWrapper(
      Id Id,
      Decimal quantity,
      Decimal unitPrice,
      Decimal totalPrice,
      Id productId,
      String productName,
      Decimal quantityInStock
    ) {
      this.Id = Id;
      this.quantity = quantity;
      this.unitPrice = unitPrice;
      this.totalPrice = totalPrice;
      this.productId = productId;
      this.productName = productName;
      this.quantityInStock = quantityInStock;
    }
  }
}
