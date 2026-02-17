public with sharing class UserProfileController {

    /**
     * Vérifie si l'utilisateur courant
     * est System Administrator ou Commercial
     */
    @AuraEnabled(cacheable=true)
    public static Boolean isAdminOrCommercial() {

        Id profileId = UserInfo.getProfileId();

        // Vérifie l'accessibilité du profil
        if(!Schema.sObjectType.Profile.isAccessible()){
            throw new AuraHandledException('Accès au profil non autorisé.');
        }

        // Récupération du nom du profil
        List<Profile> profiles = [
            SELECT Name
            FROM Profile
            WHERE Id = :profileId
            LIMIT 1
        ];

        if(profiles.isEmpty()){
            throw new AuraHandledException('Profil introuvable.');
        }

        String profileName = profiles[0].Name.toLowerCase();

        // Vérification des profils autorisés
        return profileName.contains('system administrator') || profileName.contains('commercial');
    }
}