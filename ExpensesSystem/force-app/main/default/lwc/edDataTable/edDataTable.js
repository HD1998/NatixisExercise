import { LightningElement, api, wire, track } from 'lwc';
import getEDs from '@salesforce/apex/EDController.getEDs';
import deleteEd from '@salesforce/apex/EDController.deleteEd';

const actions = [
    { label : 'Delete', name: 'delete'}
];

const columns = [
    { label: 'Name', fieldName: 'NameURL', type: 'url', editable: true, typeAttributes: {label: {fieldName: 'Name'}} },  //typeAttribute serve para pôr os nomes das EDs em vez dos IDs
    /*{ label: 'Name', fieldName: 'Name' }, */
    /*{ label: 'Expense', fieldName: 'ExpenseName'},*/
    { label: 'Employee', fieldName: 'EmployeeName', editable: true},
    { label: 'Paid Amount', fieldName: 'PaidAmount', type : "currency", sortable : true, editable: true},
    { label: 'Amount', fieldName: 'Amount',  type : "currency"},
    { type: 'action', typeAttributes: { rowActions: actions}},
]

export default class EDDataTable extends LightningElement {
    columns = columns;
    //o valor do recordId é recebido pelo expenseLightningCard (é o id da expense a cada iteração do loop no expensiveLightningCard)
    @api recordId;
    @track data;
    @track error

    defaultSortDirection = 'asc';
    sortDirection = 'asc';
    sortedBy;
    draftValues = [];
    

    //vai buscar os dados das EDs ao Apex
    @wire(getEDs, {
        expenseId: '$recordId'
    })
    wiredObject({data, error}) {
        if(data) {

            //percorre todas as EDs, e atribui o valor de cada campo à coluna correspondente 
            let edsData = data.map( ed => {
                let NameURL = `/${ed.Id}`;  //link para a record page
                return { 
                        NameURL,
                        id : ed.Id,
                        Name : ed.Name,
                        //ExpenseName : ed["Expense__r"]["Name"],
                        EmployeeName : ed["Employee__r"]["Name"],
                        PaidAmount : ed.Paid_Amount__c,
                        Amount : ed.Amount__c
                     };
            })


            //atribui os dados
            this.data = edsData;    
            this.error = undefined;
        } else if(error) {
            this.error = error;
            this.data = undefined;
        }
    }

    // Used to sort the 'PaidAmount' column
    sortBy(field, reverse, primer) {
        console.log('PRIMER: ' + primer);
        const key = primer
            ? function (x) {
                console.log('x: ' + x);
                console.log('x[field]: ' + x[field]);
                console.log('primer(x[field]): ' + primer(x[field]));
                  return primer(x[field]);
              }
            : function (x) {
                console.log('ELSE ');
                console.log('x: ' + JSON.stringify(x));
                console.log('x[field]: ' + x[field]);
                  return x[field];
              };

        return function (a, b) {
            console.log('A: ' + JSON.stringify(a));
            console.log('B: ' + JSON.stringify(b));
            console.log('KEYA: ' + key(a));
            console.log('KEYB: ' + key(b));
            a = key(a);
            b = key(b);
            console.log('REVERESE: ' + reverse * ((a > b) - (b > a)));
            return reverse * ((a > b) - (b > a));
        };
    }

    onHandleSort(event) {
        console.log('EventDetail: ' + JSON.stringify(event.detail));
        const { fieldName: sortedBy, sortDirection } = event.detail;
        console.log('Field: ' + sortedBy);
        console.log('Field: ' + sortDirection);
        const cloneData = [...this.data];

        cloneData.sort(this.sortBy(sortedBy, sortDirection === 'asc' ? 1 : -1));
        this.data = cloneData;
        this.sortDirection = sortDirection;
        this.sortedBy = sortedBy;
    }


    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
    }

    handleRowAction(event) {
        
        const { id } = event.detail.row;    //id da row clicada
        const index = this.findRowIndexById(id);    //index da row clicada
        
        if (index !== -1) { //se for index existente, remove da data

            try {   //tenta apagar o registo selecionado da DB
                deleteEd({edId: id});
                //this.showToast('Register Vote', 'Your vote was succesfully registered', 'success');
                //se conseguir apaga a row
                this.data = this.data
                .slice(0, index)
                .concat(this.data.slice(index + 1));
            } catch(error) {    //se não conseguir mostra o erro
                this.error = error; 
                //this.showToast('Something went wrong', error.body.message, 'error');
            }

            


            /*let isDeleted = deleteEd({edId: id});
            console.log('HELLOO');
            console.log(isDeleted);
            //SE O DELETE FOR SUCESSO FAZ ISTO
            if(isDeleted) {
                this.data = this.data
                .slice(0, index)
                .concat(this.data.slice(index + 1));
            }*/
        }
        

        //falta dar delete da row na db

    }

    findRowIndexById(id) {
        let ret = -1;
        this.data.some((row, index) => {    //percorre as rows da tabela, e se algum id for igual ao id da row clicada retorna o correspondente
            if (row.id === id) {
                ret = index;
                return true;
            }
            return false;
        });
        return ret;
    }

    handleSave(event) {

    }

}