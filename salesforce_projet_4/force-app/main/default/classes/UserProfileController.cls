public with sharing class UserProfileController {
  @AuraEnabled(cacheable=true)
  public static Boolean isAdminOrCommercial() {
    Id profileId = UserInfo.getProfileId();

    if (!Schema.sObjectType.Profile.isAccessible()) {
      AuraHandledException ex = new AuraHandledException(
        'Accès au profil non autorisé.'
      );
      ex.setMessage('Accès au profil non autorisé.');
      throw ex;
    }

    Profile p = [
      SELECT PermissionsModifyAllData, Name
      FROM Profile
      WHERE Id = :profileId
      LIMIT 1
    ];

    // ✅ Admin via permission système
    if (p.PermissionsModifyAllData) {
      return true;
    }

    // ✅ Commercial si profil contient le mot
    if (p.Name != null && p.Name.toLowerCase().contains('commercial')) {
      return true;
    }

    return false;
  }
}
