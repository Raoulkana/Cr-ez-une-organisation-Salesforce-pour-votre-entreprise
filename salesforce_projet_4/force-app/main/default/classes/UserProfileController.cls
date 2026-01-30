public with sharing class UserProfileController {

    /**
     * Vérifie si l'utilisateur courant
     * est System Administrator ou Commercial
     */
    @AuraEnabled(cacheable=true)
    public static Boolean isAdminOrCommercial() {

        // Récupération du profil de l'utilisateur courant
        Profile p = [
            SELECT Name
            FROM Profile
            WHERE Id = :UserInfo.getProfileId()
            LIMIT 1
        ];

        // Normalisation du nom du profil
        String profileName = p.Name.toLowerCase();

        // Vérification des profils autorisés
        if (
            profileName.contains('system administrator') ||
            profileName.contains('commercial')
        ) {
            return true;
        }

        return false;
    }
}