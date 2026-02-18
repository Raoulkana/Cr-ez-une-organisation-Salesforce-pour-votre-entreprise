@IsTest
public class UserProfileControllerTest {

    @IsTest
    static void testIsAdminOrCommercial() {

        // 🔹 Récupérer profil System Administrator (existe toujours)
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
            CommunityNickname = 'admint',
            TimeZoneSidKey = 'Europe/Paris',
            LocaleSidKey = 'fr_FR',
            EmailEncodingKey = 'UTF-8',
            ProfileId = adminProfile.Id,
            LanguageLocaleKey = 'fr'
        );
        insert adminUser;

        // 🔹 Exécution en runAs admin
        System.runAs(adminUser) {
            Boolean result = UserProfileController.isAdminOrCommercial();
            System.assertEquals(true, result,
                'Un System Administrator doit être autorisé.');
        }

        // 🔹 Récupérer un profil Standard User (existe toujours)
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
            CommunityNickname = 'stdt',
            TimeZoneSidKey = 'Europe/Paris',
            LocaleSidKey = 'fr_FR',
            EmailEncodingKey = 'UTF-8',
            ProfileId = standardProfile.Id,
            LanguageLocaleKey = 'fr'
        );
        insert standardUser;

        System.runAs(standardUser) {
            Boolean result2 = UserProfileController.isAdminOrCommercial();
            System.assertEquals(false, result2,
                'Un Standard User ne doit pas être autorisé.');
        }
    }
}