import { LightningElement, api, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import getOpportunityProducts from '@salesforce/apex/OpportunityProductController.getOpportunityProducts';
import deleteOpportunityProduct from '@salesforce/apex/OpportunityProductController.deleteOpportunityProduct';
import isAdminOrCommercial from '@salesforce/apex/UserProfileController.isAdminOrCommercial';

/* ===============================
   CUSTOM LABELS
=============================== */
import OL_Title from '@salesforce/label/c.OL_Title';
import OL_No_Products from '@salesforce/label/c.OL_No_Products';
import OL_Quantity_Error from '@salesforce/label/c.OL_Quantity_Error';
import OL_Error_Title from '@salesforce/label/c.OL_Error_Title';
import OL_Not_Authorized from '@salesforce/label/c.OL_Not_Authorized';

import OL_Product from '@salesforce/label/c.OL_Product';
import OL_Unit_Price from '@salesforce/label/c.OL_Unit_Price';
import OL_Total_Price from '@salesforce/label/c.OL_Total_Price';
import OL_Quantity from '@salesforce/label/c.OL_Quantity';
import OL_Stock from '@salesforce/label/c.OL_Stock';
import OL_Delete from '@salesforce/label/c.OL_Delete';
import OL_View_Product from '@salesforce/label/c.OL_View_Product';
import OL_Select_Pricebook from '@salesforce/label/c.OL_Select_Pricebook';

export default class OpportunityProductDatatable extends NavigationMixin(LightningElement) {

    @api recordId;

    @track data = [];
    @track showContent = false;
    @track hasData = false;
    @track hasQuantityError = false;
    @track isLoading = true;

    isAuthorizedProfile = false;

    labels = {
        OL_Title,
        OL_No_Products,
        OL_Quantity_Error,
        OL_Error_Title,
        OL_Not_Authorized,
        OL_Select_Pricebook
    };

    columns = [];

    connectedCallback() {
        this.initializeComponent();
    }

    /* ===============================
       INITIALISATION
    =============================== */
    async initializeComponent() {
        try {
            const result = await isAdminOrCommercial();

            // result = true uniquement si Admin
            this.isAuthorizedProfile = result;

            this.showContent = true; // Tout le monde voit les produits

            this.initializeColumns();
            this.loadProducts();

        } catch (error) {
            this.showContent = false;
            this.showToast(
                this.labels.OL_Error_Title,
                error?.body?.message || 'Erreur profil',
                'error'
            );
        }
    }

    initializeColumns() {

        const baseColumns = [
            {
                label: OL_Product,
                fieldName: 'productName',
                cellAttributes: { class: { fieldName: 'rowClass' } }
            },
            {
                label: OL_Unit_Price,
                fieldName: 'unitPrice',
                type: 'currency',
                cellAttributes: { class: { fieldName: 'rowClass' } }
            },
            {
                label: OL_Total_Price,
                fieldName: 'totalPrice',
                type: 'currency',
                cellAttributes: { class: { fieldName: 'rowClass' } }
            },
            {
                label: OL_Quantity,
                fieldName: 'quantity',
                type: 'number',
                cellAttributes: { class: { fieldName: 'rowClass' } }
            },
            {
                label: OL_Stock,
                fieldName: 'quantityInStock',
                type: 'number',
                cellAttributes: { class: { fieldName: 'rowClass' } }
            }
        ];

        // Colonnes actions (Admin uniquement)
        const actionColumns = this.isAuthorizedProfile ? [
            //suppression
            {
                type: 'button-icon',
                fixedWidth: 50,
                typeAttributes: {
                    iconName: 'utility:delete',
                    name: 'delete',
                    title: OL_Delete,
                    variant: 'bare',
                    alternativeText: OL_Delete
                }
            },
            //voir produit
            {
                type: 'button',
                typeAttributes: {
                    label: OL_View_Product,
                    name: 'view_product',
                    iconName: 'utility:preview',
                    variant: 'base'
                }
            }
        ] : [];

        this.columns = [...baseColumns, ...actionColumns];
    }

    /* ===============================
       CHARGEMENT PRODUITS
    =============================== */
    loadProducts() {
        getOpportunityProducts({ opportunityId: this.recordId })
            .then(result => {
                this.data = result.map(item => ({
                    ...item,
                    isError: item.quantity > item.quantityInStock,
                    rowClass: item.quantity > item.quantityInStock ? 'error-row' : ''
                }));

                this.hasData = this.data.length > 0;
                this.checkQuantityErrors();
                this.isLoading = false;
            })
            .catch(error => {
                this.data = [];
                this.hasData = false;
                this.isLoading = false;
                this.showToast(
                    this.labels.OL_Error_Title,
                    error?.body?.message || 'Erreur chargement produits',
                    'error'
                );
            });
    }

    /* ===============================
       VALIDATION QUANTITÉ
    =============================== */
    checkQuantityErrors() {
        this.hasQuantityError = this.data.some(item => item.quantity > item.quantityInStock);

        if (this.hasQuantityError) {
            this.showToast(
                this.labels.OL_Error_Title,
                this.labels.OL_Quantity_Error,
                'warning'
            );
        }
    }

    /* ===============================
       ACTIONS DATATABLE
    =============================== */
    handleRowAction(event) {

        // Sécurité supplémentaire
        if (!this.isAuthorizedProfile) {
            this.showToast(
                this.labels.OL_Error_Title,
                this.labels.OL_Not_Authorized,
                'error'
            );
            return;
        }

        const actionName = event.detail.action.name;
        const row = event.detail.row;

        if (actionName === 'delete') {
            if (!row.Id) {
                this.showToast(this.labels.OL_Error_Title, 'Id produit invalide', 'error');
                return;
            }
            this.deleteProduct(row.Id);
        }

        if (actionName === 'view_product') {
            this.navigateToProduct(row.productId);
        }
    }

    /* ===============================
       SUPPRESSION
    =============================== */
    deleteProduct(lineId) {
        deleteOpportunityProduct({ lineId })
            .then(() => {
                this.showToast('Succès', 'Produit supprimé avec succès', 'success');
                this.loadProducts();
            })
            .catch(error => {
                this.showToast(
                    this.labels.OL_Error_Title,
                    error?.body?.message || 'Erreur suppression',
                    'error'
                );
            });
    }

    /* ===============================
       NAVIGATION
    =============================== */
    navigateToProduct(productId) {
        if (!productId) return;

        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: productId,
                objectApiName: 'Product2',
                actionName: 'view'
            }
        });
    }

    /* ===============================
       TOAST UTILITY
    =============================== */
    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({ title, message, variant })
        );
    }

    /* ===============================
       HELPERS
    =============================== */
    get showNoProducts() {
        return !this.hasData && !this.isLoading;
    }
}