import { LightningElement, api, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

import getOpportunityProducts from '@salesforce/apex/OpportunityProductController.getOpportunityProducts';
import deleteOpportunityProduct from '@salesforce/apex/OpportunityProductController.deleteOpportunityProduct';
import isAdminOrCommercial from '@salesforce/apex/UserProfileController.isAdminOrCommercial';

import OL_Title from '@salesforce/label/c.OL_Title';
import OL_No_Products from '@salesforce/label/c.OL_No_Products';
import OL_Quantity_Error from '@salesforce/label/c.OL_Quantity_Error';
import OL_Error_Title from '@salesforce/label/c.OL_Error_Title';
import OL_Not_Authorized from '@salesforce/label/c.OL_Not_Authorized';

export default class OpportunityProductDatatable extends NavigationMixin(LightningElement) {

    @api recordId;
    @track data = [];
    @track showContent = false;
    @track hasData = false;
    @track hasQuantityError = false;

    labels = {
        OL_Title,
        OL_No_Products,
        OL_Quantity_Error,
        OL_Error_Title,
        OL_Not_Authorized
    };

    columns = [];

    connectedCallback() {
        this.initializeComponent();
    }

    async initializeComponent() {
        try {
            const result = await isAdminOrCommercial();
            this.showContent = result;

            if (result) {
                this.initializeColumns();
                this.loadProducts();
            }
        } catch (error) {
            console.error('Erreur profil', error);
        }
    }

    initializeColumns() {

        this.columns = [
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
                    name: 'delete',
                    title: 'Supprimer',
                    variant: 'bare',
                    alternativeText: 'Supprimer'
                }
            },

            {
                type: 'button',
                typeAttributes: {
                    label: 'Voir produit',
                    name: 'view_product',
                    iconName: 'utility:preview',
                    variant: 'base'
                }
            }
        ];
    }

    loadProducts() {
        getOpportunityProducts({ opportunityId: this.recordId })
            .then(result => {

                this.data = result.map(item => {
                    return {
                        ...item,
                        productName: item.PricebookEntry.Product2.Name
                    };
                });

                this.hasData = this.data.length > 0;
                this.checkQuantityErrors();

            })
            .catch(error => {
                console.error('Erreur chargement produits', error);
            });
    }

    checkQuantityErrors() {
        this.hasQuantityError = this.data.some(item => item.quantity <= 0);
    }

    handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;

        if (actionName === 'delete') {
            this.deleteProduct(row.Id);
        }

        if (actionName === 'view_product') {
            this.navigateToProduct(row.PricebookEntry.Product2.Id);
        }
    }

    deleteProduct(productId) {
        deleteOpportunityProduct({ productId })
            .then(() => {
                this.loadProducts();
            })
            .catch(error => {
                console.error('Erreur suppression', error);
            });
    }

    navigateToProduct(productId) {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: productId,
                actionName: 'view'
            }
        });
    }
}