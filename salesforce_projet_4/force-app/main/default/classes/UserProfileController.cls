public with sharing class UserProfileController {

  @AuraEnabled(cacheable=true)
  public static Boolean isAdminOrCommercial() {

    if (!Schema.sObjectType.User.isAccessible()) {
      throw new AuraHandledException('Access denied.');
    }

    User currentUser = [
      SELECT Profile.PermissionsModifyAllData
      FROM User
      WHERE Id = :UserInfo.getUserId()
      LIMIT 1
    ];

    // 🔒 Maintenant retourne TRUE uniquement pour Admin
    return currentUser.Profile.PermissionsModifyAllData;
  }
}