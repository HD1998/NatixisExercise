import { LightningElement, api, wire } from 'lwc';
import LightningConfirm from 'lightning/confirm';
import deleteFile from '@salesforce/apex/FileUploaderController.deleteFile';
import getFileData from '@salesforce/apex/FileUploaderController.getFileData';
import upsertEmployee from '@salesforce/apex/FileUploaderController.upsertEmployee';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class FileUploader extends LightningElement {
    @api recordId
    error;

    //formato de ficheiros aceites no upload
    get acceptedFormats() {
        return ['.txt'];
    }

    //quando o ficheiro acaba de dar upload
    handleUploadFinished(event) {
        const uploadedFiles = event.detail.files;

        try {
            //obtém o número de employees dentro do ficheiro   
            getFileData({fileId: uploadedFiles[0].documentId})  // uploadedFiles[0] porque só é possível inserir um ficheiro de cada vez
            .then((listOfEmployees) => {
                
                //método para tratar do ok ou cancel no pop-up
                this.handleConfirmClick(listOfEmployees);

            })
            .catch((error) => {
                console.log('Err: ' + error);
            });

            //tenta apagar o file na DB
            deleteFile({fileId: uploadedFiles[0].documentId});
            
            
        } catch(error) {
            this.error = error;
        }

    }

    //pop-up que abre ao clicar no done
    async handleConfirmClick(listOfEmployees) {
        let result;
        console.log('NME: ' + JSON.stringify(listOfEmployees));
        let nrEmployees = listOfEmployees ? listOfEmployees.length : 0;
        //janela pop-up
        if(nrEmployees == 0) {
            result = await LightningConfirm.open({
                message: 'No employees found in uploaded file',
                label: 'Invalid File',
                theme: 'error'
            });
        } else {
            result = await LightningConfirm.open({
                message: 'You are trying to upload ' +  nrEmployees + ' valid employees. Do you wish to confirm ?',
                variant: 'headerless'
            });
        }
        

        //se clicar no OK e existirem employees, dá upsert à lista de employees na DB, se não não faz nada
        if (result && nrEmployees > 0) {
            upsertEmployee({empList: listOfEmployees})
            .then((toastMessage) => {
                let title = toastMessage == 'Records Updated' ? 'Success' : toastMessage.substring(0, 13) == 'The following' ? 'Warning' : 'Something went wrong';
                let variant = toastMessage == 'Records Updated' ? 'success' : toastMessage.substring(0, 13) == 'The following' ? 'warning' : 'error';
                this.showToast(title, toastMessage, variant);
            })
            .catch((error) => {
                console.log('ErrToast: ' + error);
            });
        }
    }

    //mostra um toast
    showToast(title, message, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
        });
        this.dispatchEvent(evt);
    }
}