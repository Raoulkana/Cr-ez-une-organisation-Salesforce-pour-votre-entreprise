@IsTest
public class UserProfileControllerTest {

    @IsTest
    static void testIsAdminOrCommercial() {
        // 1️⃣ Récupérer un profil clonable pour test
        // Ici, "Commercial" est un profil standard que l'on peut utiliser dans les tests
        Profile p = [SELECT Id FROM Profile WHERE Name='Commercial' LIMIT 1];

        // 2️⃣ Créer un utilisateur test avec ce profil
        User u = new User(
            FirstName = 'Test',
            LastName = 'User',
            Alias = 'tuser',
            Email = 'testuser' + System.currentTimeMillis() + '@example.com',
            Username = 'testuser' + System.currentTimeMillis() + '@example.com',
            CommunityNickname = 'tuser',
            TimeZoneSidKey = 'Europe/Paris',
            LocaleSidKey = 'fr_FR',
            EmailEncodingKey = 'UTF-8',
            ProfileId = p.Id,
            LanguageLocaleKey = 'fr'
        );
        insert u;

        // 3️⃣ Exécuter la méthode en tant qu'utilisateur créé
        System.runAs(u) {
            Boolean result = UserProfileController.isAdminOrCommercial();

            // 4️⃣ Vérification : doit retourner true pour le profil Commercial
            System.assertEquals(true, result, 'La méthode doit retourner true pour un profil Commercial.');
        }

        // 5️⃣ Optionnel : test pour un utilisateur non autorisé
        Profile p2 = [SELECT Id FROM Profile WHERE Name='Standard User' LIMIT 1];

        User u2 = new User(
            FirstName = 'Test',
            LastName = 'User2',
            Alias = 'tuser2',
            Email = 'testuser2' + System.currentTimeMillis() + '@example.com',
            Username = 'testuser2' + System.currentTimeMillis() + '@example.com',
            CommunityNickname = 'tuser2',
            TimeZoneSidKey = 'Europe/Paris',
            LocaleSidKey = 'fr_FR',
            EmailEncodingKey = 'UTF-8',
            ProfileId = p2.Id,
            LanguageLocaleKey = 'fr'
        );
        insert u2;

        System.runAs(u2) {
            Boolean result2 = UserProfileController.isAdminOrCommercial();
            System.assertEquals(false, result2, 'La méthode doit retourner false pour un profil non autorisé.');
        }
    }
}