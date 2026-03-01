public with sharing class UserProfileController {

    @AuraEnabled(cacheable=true)
    public static Boolean isAdminOrCommercial() {

        if (!Schema.sObjectType.User.isAccessible()) {
            throw new AuraHandledException('Access denied.');
        }

        User currentUser = [
            SELECT Profile.Name,
                   Profile.PermissionsModifyAllData
            FROM User
            WHERE Id = :UserInfo.getUserId()
            LIMIT 1
        ];

        // ✅ System Admin via permission forte
        if (currentUser.Profile.PermissionsModifyAllData) {
            return true;
        }

        // ✅ Profil Commercial (adaptable)
        if (currentUser.Profile.Name != null &&
            currentUser.Profile.Name.contains('Commercial')) {

            return true;
        }

        return false;
    }
}
