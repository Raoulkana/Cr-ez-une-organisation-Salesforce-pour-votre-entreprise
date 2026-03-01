/* eslint-env jest */
import { createElement } from 'lwc';
import OpportunityProductDatatable from 'c/opportunityProductDatatable';

import isAdminOrCommercial from '@salesforce/apex/UserProfileController.isAdminOrCommercial';
import getOpportunityProducts from '@salesforce/apex/OpportunityProductController.getOpportunityProducts';

// Mock Apex
jest.mock(
    '@salesforce/apex/UserProfileController.isAdminOrCommercial',
    () => {
        return { default: jest.fn() };
    },
    { virtual: true }
);

jest.mock(
    '@salesforce/apex/OpportunityProductController.getOpportunityProducts',
    () => {
        return { default: jest.fn() };
    },
    { virtual: true }
);

describe('c-opportunity-product-datatable', () => {

    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        jest.clearAllMocks();
    });

    it('component loads', () => {

        isAdminOrCommercial.mockResolvedValue(true);
        getOpportunityProducts.mockResolvedValue([]);

        const element = createElement('c-opportunity-product-datatable', {
            is: OpportunityProductDatatable
        });

        document.body.appendChild(element);

        expect(element).not.toBeNull();
    });

    it('datatable exists when authorized', async () => {

        isAdminOrCommercial.mockResolvedValue(true);
        getOpportunityProducts.mockResolvedValue([
            {
                Id: '001',
                quantity: 2,
                quantityInStock: 5
            }
        ]);

        const element = createElement('c-opportunity-product-datatable', {
            is: OpportunityProductDatatable
        });

        document.body.appendChild(element);

        await Promise.resolve();
        await Promise.resolve(); // flush async Apex

        const datatable =
            element.shadowRoot.querySelector('lightning-datatable');

        expect(datatable).not.toBeNull();
    });

});