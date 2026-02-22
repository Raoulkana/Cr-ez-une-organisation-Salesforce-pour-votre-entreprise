/* eslint-env jest */
import { createElement } from 'lwc';
import OpportunityProductDatatable from 'c/opportunityProductDatatable';

describe('c-opportunity-product-datatable', () => {

    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
    });

    it('component loads', () => {
        const element = createElement('c-opportunity-product-datatable', {
            is: OpportunityProductDatatable
        });

        document.body.appendChild(element);

        expect(element).not.toBeNull();
    });

    it('datatable exists', async () => {
        const element = createElement('c-opportunity-product-datatable', {
            is: OpportunityProductDatatable
        });

        document.body.appendChild(element);

        await Promise.resolve(); // Wait a microtask for initial render

        const datatable = element.shadowRoot.querySelector('lightning-datatable');

        expect(datatable).not.toBeNull();
    });

});
