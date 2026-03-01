@IsTest
public class UserProfileControllerTest {

    @IsTest
    static void testIsAdminOrCommercial() {

        // 🔹 Profil System Administrator
        Profile adminProfile = [
            SELECT Id 
            FROM Profile 
            WHERE Name = 'System Administrator' 
            LIMIT 1
        ];

        // 🔹 Créer utilisateur admin
        User adminUser = new User(
            FirstName = 'Admin',
            LastName = 'Test',
            Alias = 'admint',
            Email = 'admin' + System.currentTimeMillis() + '@test.com',
            Username = 'admin' + System.currentTimeMillis() + '@test.com',
            CommunityNickname = 'admint' + System.currentTimeMillis(),
            TimeZoneSidKey = 'Europe/Paris',
            LocaleSidKey = 'fr_FR',
            EmailEncodingKey = 'UTF-8',
            ProfileId = adminProfile.Id,
            LanguageLocaleKey = 'fr_FR'
        );
        insert adminUser;

        System.runAs(adminUser) {
            Boolean result = UserProfileController.isAdminOrCommercial();
            System.assertEquals(true, result,
                'Un System Administrator doit être autorisé.');
        }

        // 🔹 Profil Commercial (doit contenir "Commercial")
        Profile commercialProfile = [
            SELECT Id 
            FROM Profile 
            WHERE Name LIKE '%Commercial%' 
            LIMIT 1
        ];

        User commercialUser = new User(
            FirstName = 'Commercial',
            LastName = 'Test',
            Alias = 'comt',
            Email = 'com' + System.currentTimeMillis() + '@test.com',
            Username = 'com' + System.currentTimeMillis() + '@test.com',
            CommunityNickname = 'comt' + System.currentTimeMillis(),
            TimeZoneSidKey = 'Europe/Paris',
            LocaleSidKey = 'fr_FR',
            EmailEncodingKey = 'UTF-8',
            ProfileId = commercialProfile.Id,
            LanguageLocaleKey = 'fr_FR'
        );
        insert commercialUser;

        System.runAs(commercialUser) {
            Boolean result = UserProfileController.isAdminOrCommercial();
            System.assertEquals(true, result,
                'Un profil Commercial doit être autorisé.');
        }

        // 🔹 Profil Standard User
        Profile standardProfile = [
            SELECT Id 
            FROM Profile 
            WHERE Name = 'Standard User' 
            LIMIT 1
        ];

        User standardUser = new User(
            FirstName = 'Standard',
            LastName = 'Test',
            Alias = 'stdt',
            Email = 'standard' + System.currentTimeMillis() + '@test.com',
            Username = 'standard' + System.currentTimeMillis() + '@test.com',
            CommunityNickname = 'stdt' + System.currentTimeMillis(),
            TimeZoneSidKey = 'Europe/Paris',
            LocaleSidKey = 'fr_FR',
            EmailEncodingKey = 'UTF-8',
            ProfileId = standardProfile.Id,
            LanguageLocaleKey = 'fr_FR'
        );
        insert standardUser;

        System.runAs(standardUser) {
            Boolean result = UserProfileController.isAdminOrCommercial();
            System.assertEquals(false, result,
                'Un Standard User ne doit pas être autorisé.');
        }
    }
}