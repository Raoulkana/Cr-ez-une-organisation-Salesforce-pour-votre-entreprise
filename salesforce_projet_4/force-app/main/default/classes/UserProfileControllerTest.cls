@IsTest
public class UserProfileControllerTest {

    @IsTest
    static void testIsAdminOrCommercial() {

        // 🔹 PROFIL ADMIN
        Profile adminProfile = [
            SELECT Id 
            FROM Profile 
            WHERE Name = 'System Administrator' 
            LIMIT 1
        ];

        User adminUser = new User(
            FirstName = 'Admin',
            LastName = 'Test',
            Alias = 'admnt',
            Email = 'admin' + System.currentTimeMillis() + '@test.com',
            Username = 'admin' + System.currentTimeMillis() + '@test.com',
            CommunityNickname = 'admnt' + System.currentTimeMillis(),
            TimeZoneSidKey = 'Europe/Paris',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = adminProfile.Id,
            LanguageLocaleKey = 'en_US'
        );
        insert adminUser;

        System.runAs(adminUser) {
            Boolean result = UserProfileController.isAdminOrCommercial();
            System.assertEquals(true, result,
                'Un System Administrator doit être autorisé.');
        }

        // 🔹 PROFIL COMMERCIAL (sécurisé)
        Profile commercialProfile;
        List<Profile> commercialProfiles = [
            SELECT Id 
            FROM Profile 
            WHERE Name LIKE '%Commercial%' 
            LIMIT 1
        ];

        if (!commercialProfiles.isEmpty()) {
            commercialProfile = commercialProfiles[0];

            User commercialUser = new User(
                FirstName = 'Commercial',
                LastName = 'Test',
                Alias = 'comt',
                Email = 'com' + System.currentTimeMillis() + '@test.com',
                Username = 'com' + System.currentTimeMillis() + '@test.com',
                CommunityNickname = 'comt' + System.currentTimeMillis(),
                TimeZoneSidKey = 'Europe/Paris',
                LocaleSidKey = 'en_US',
                EmailEncodingKey = 'UTF-8',
                ProfileId = commercialProfile.Id,
                LanguageLocaleKey = 'en_US'
            );
            insert commercialUser;

            System.runAs(commercialUser) {
                Boolean result = UserProfileController.isAdminOrCommercial();
                System.assertEquals(true, result,
                    'Un profil Commercial doit être autorisé.');
            }
        }

        // 🔹 PROFIL STANDARD USER
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
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = standardProfile.Id,
            LanguageLocaleKey = 'en_US'
        );
        insert standardUser;

        System.runAs(standardUser) {
            Boolean result = UserProfileController.isAdminOrCommercial();
            System.assertEquals(false, result,
                'Un Standard User ne doit pas être autorisé.');
        }
    }
}