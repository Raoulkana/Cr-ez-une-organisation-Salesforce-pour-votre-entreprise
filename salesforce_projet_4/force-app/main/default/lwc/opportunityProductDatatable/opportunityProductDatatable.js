import { LightningElement, api, track } from 'lwc';
import getOpportunityProducts from '@salesforce/apex/OpportunityProductController.getOpportunityProducts';
import isAdminOrCommercial from '@salesforce/apex/UserProfileController.isAdminOrCommercial';

export default class OpportunityProductDatatable extends LightningElement {

    @api recordId; // Id de l'opportunité
    @track data = [];
    @track showContent = false;
    @track hasData = false;

    columns = [
        { label: 'Produit', fieldName: 'productName' },
        { label: 'Prix unitaire', fieldName: 'unitPrice', type: 'currency' },
        { label: 'Prix total', fieldName: 'totalPrice', type: 'currency' },
        { label: 'Quantité', fieldName: 'quantity', type: 'number' },
        { label: 'Quantité restante', fieldName: 'quantityInStock', type: 'number' },

        {
            type: 'button-icon',
            fixedWidth: 50,
            typeAttributes: {
                iconName: 'utility:delete',
                title: 'Supprimer',
                variant: 'bare',
                alternativeText: 'Supprimer'
            }
        },
        {
            type: 'button',
            label: 'Voir produit',
            typeAttributes: {
                label: 'Voir produit',
                name: 'view_product',
                iconName: 'utility:preview',
                variant: 'base'
            }
        }
    ];

    connectedCallback() {
        isAdminOrCommercial()
            .then(result => {
                this.showContent = result;
                if (result) {
                    this.loadProducts();
                }
            })
            .catch(error => {
                console.error('Erreur profil', error);
            });
    }

    loadProducts() {
        getOpportunityProducts({ opportunityId: this.recordId })
            .then(result => {
                this.data = result;
                this.hasData = result && result.length > 0;
            })
            .catch(error => {
                console.error('Erreur chargement produits', error);
            });
    }
}