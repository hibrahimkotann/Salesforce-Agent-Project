import { LightningElement, api, wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getOpportunities from '@salesforce/apex/OpportunityTableController.getOpportunities';
import updateCloseDate from '@salesforce/apex/OpportunityTableController.updateCloseDate';

const COLUMNS = [
    { label: 'Fırsat Adı', fieldName: 'Name', type: 'text', sortable: true },
    { label: 'Aşama', fieldName: 'StageName', type: 'text' },
    {
        label: 'Tutar',
        fieldName: 'Amount',
        type: 'currency',
        typeAttributes: { currencyCode: 'USD', minimumFractionDigits: 0 }
    },
    { label: 'Kapanış Tarihi', fieldName: 'CloseDate', type: 'date' },
    { label: 'Olasılık (%)', fieldName: 'Probability', type: 'percent', typeAttributes: { maximumFractionDigits: 0 } },
    {
        type: 'action',
        typeAttributes: {
            rowActions: [
                { label: 'Bugüne Çek', name: 'close_today', iconName: 'utility:date_input' }
            ]
        }
    }
];

export default class OpportunityTable extends LightningElement {
    @api recordId;

    columns = COLUMNS;
    wiredResult;

    @wire(getOpportunities, { accountId: '$recordId' })
    wiredOpportunities(result) {
        this.wiredResult = result;
    }

    get opportunityData() {
        return this.wiredResult?.data ?? [];
    }

    get hasOpportunities() {
        return this.opportunityData.length > 0;
    }

    get hasError() {
        return !!this.wiredResult?.error;
    }

    get opportunityCount() {
        return this.opportunityData.length;
    }

    async handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;

        if (actionName !== 'close_today') {
            return;
        }

        try {
            await updateCloseDate({ opportunityId: row.Id });

            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Başarılı',
                    message: `"${row.Name}" kapanış tarihi bugüne güncellendi.`,
                    variant: 'success'
                })
            );

            await refreshApex(this.wiredResult);
        } catch (error) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Hata',
                    message: error?.body?.message || 'Güncelleme sırasında bir hata oluştu.',
                    variant: 'error'
                })
            );
        }
    }
}
