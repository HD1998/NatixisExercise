import getExpenses from '@salesforce/apex/ExpenseController.getExpenses';
import { api, wire, LightningElement, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { encodeDefaultFieldValues } from 'lightning/pageReferenceUtils';
//import description from '@salesforce/label/c.Description__c'

export default class ExpenseLightningCard extends NavigationMixin (LightningElement) {

    @track data;
    @track error;
    @api recordId;

   /*label = {
        description
    };*/

    //vai buscar os dados das Expenses ao Apex
    @wire(getExpenses, {
        tripId: '$recordId'
    })
    wiredObject({data, error}) {
        if(data) {
            this.data = data;
            this.error = undefined;
        } else if(error) {
            this.error = error;
            this.data = undefined;
        }
    }
    
    
    //evento para chamar a record page da expense clicada
    callRecordPage(event) { 
        /*event.preventDefault();
        event.stopPropagation();*/
        
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: event.target.dataset.recordId, //id da expense clicada
                objectApiName: 'Expense__c', // objectApiName is optional
                actionName: 'view'
            }
        });
    }

    //ao criar no botão de criar ED, abre a standard página de criação de registo de ED
    handleCreateNewED(event) {
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'Expense_Distribution__c', 
                actionName: 'new'
            },
            state: {    //ao abrir a página de criar registo, preenche automaticamente o campo da Expense com a Expense de onde o botão foi criado
                defaultFieldValues: encodeDefaultFieldValues({
                    Expense__c: event.target.dataset.recordId
                }) 
            }
        });
    }
}