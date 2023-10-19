public with sharing class FileUploaderController {
    @AuraEnabled
    public static void deleteFile(Id fileId){
        try {
            delete [SELECT Id, Title FROM ContentDocument
            WHERE Id = :fileId];
        } catch (Exception e) {
            System.debug('Delete Fail: ' + e.getMessage());
        }
    }

    //método para obter o texto que vem no ficheiro txt, deserializa-lo e devolver uma lista de employees
    @AuraEnabled(cacheable=true)
    public static List<Employee__c> getFileData(Id fileId){
        List<Employee__c> empsToUpsert;
        String fileData;
        
        try {
            ContentVersion cv = [SELECT Id, Title, IsLatest, VersionData
            FROM ContentVersion 
            WHERE ContentDocumentId = :fileId
            AND IsLatest = true];

            //text dentro do ficheiro txt
            fileData = cv.VersionData.toString();

            //funcao para fazer o deserialize
            empsToUpsert = deserializeJSON(fileData);

        } catch (Exception e) {
            System.debug('Get File Data Fail: ' + e.getMessage());
        }

        return empsToUpsert;
    }

    //método para obter uma lista de employees a partir do ficheiro txt importado
    public static List<Employee__c> deserializeJSON(String jsonString) {

        //listas com os valores das picklists (existentes no Apex) para estes dois fields
        List<String> pickListNationalityList = getEmployeePickListValues('Nationality');
        List<String> pickListGenderList = getEmployeePickListValues('Gender');  
        
        //usa a class EmployeeJSON que criei no ficheiro JSON
        EmployeeJSON.EmployeesList employeesList = (EmployeeJSON.EmployeesList) System.JSON.deserialize(jsonString, EmployeeJSON.EmployeesList.class);
        
        //list de employees a dar upsert
        List<Employee__c> empsToUpsert = new List<Employee__c>();

        //percorre os employees do JSON, os objetos são uma lista do tipo EmployeeItem (classe criada no ficheiro JSON)
        for(EmployeeJSON.EmployeeItem employee : employeesList.employees) {
            //fazer aqui a verificação dos fields required (se estão ou não preenchidos)
            if(employee.name != null && employee.name != ''
            && employee.idNum != null && employee.idNum != ''
            && employee.idType != null && employee.idType != ''
            && employee.email != null && employee.email != '') {

                String nationality = '';
                String gender = '';
                Date bDate;

                //caso a primeira letra da nacionalidade venha em lower case, passa-a a uppercase (é assim que está nos valores da picklist nationality)
                if(employee.nationality != null && employee.nationality != '') {
                    nationality = employee.nationality.substring(0,1).toUpperCase()
                    + employee.nationality.substring(1);
                }

                //caso a primeira letra do gender venha em lower case, passa-a a uppercase (é assim que está nos valores da picklist gender)
                if(employee.gender != null && employee.gender != '') {
                    gender = employee.gender.substring(0,1).toUpperCase()
                    + employee.gender.substring(1);
                }
                
                //verifica se a data é válida, se não devolve null
                try {
                    bDate = Date.parse(employee.birthdate);
                } catch(Exception e) {
                    bDate = null;
                }
                
                //cria o employee para dar upsert com os dados do ficheiro JSON
                Employee__c e = new Employee__c();
                e.Name = employee.name;
                e.Last_Name__c = employee.lastName;
                e.ID_Number__c = employee.idNum;
                e.ID_Type__c = employee.idType;
                e.Nationality__c = pickListNationalityList.contains(nationality) ? nationality : '';
                e.Gender__c = pickListGenderList.contains(gender) ? gender : '';
                e.Birthdate__c = bDate;
                e.Email__c = employee.email;         
                    
                empsToUpsert.add(e);
            }
        }
    
        return empsToUpsert;
    }

    //Vai buscar os valores das picklists que é possível selecionar (para o campo Gender por exemplo) ao criar novo Employee(no Apex)
    public static List<String> getEmployeePickListValues(String field) {
        List<String> pickList = new List<String>();
        List<Schema.PicklistEntry> pickListVals;
        
        if(field == 'Nationality') {
            Schema.DescribeFieldResult nationalityResult = Employee__c.Nationality__c.getDescribe();
            pickListVals = nationalityResult.getPicklistValues();
            
        } else if(field  == 'Gender') {
            Schema.DescribeFieldResult genderResult = Employee__c.Gender__c.getDescribe();
            pickListVals = genderResult.getPicklistValues();    
        }
        
        for( Schema.PicklistEntry pickListVal : pickListVals){
            pickList.add(pickListVal.getLabel());
        } 
        
        return pickList;
    }

    //método para dar upsert aos employees válidos
    @AuraEnabled
    public static String upsertEmployee(List<Employee__c> empList){

        List<String> errorsOcurred = new List<String>();
        try {
            List<String> compositePKList = new List<String>();

            //percorre a lista de Employees a inserir e cria uma lista com CompositePK de cada um
            for(Employee__c e : empList) {
                compositePKList.add(e.ID_Number__c + '_' + e.ID_Type__c);
            }

            //retira os ids dos registos que já existem na DB com aquele CompositePK
            List<Employee__c> empWithIdList = [SELECT Id, Name, ID_Number__c, ID_Type__c FROM Employee__c WHERE CompositePK__c IN :compositePKList];

            //por cada Employee que já existe na DB
            for(Employee__c e : empWithIdList) {
                //por cada Employee a inserir
                for(Employee__c emp : empList) {
                    //se a CompositePK (IDNum + IDType) do Employee a inserir for igual a algum da lista que tem os Ids 
                    if (emp.ID_Number__c == e.ID_Number__c && emp.ID_Type__c == e.ID_Type__c) {
                        emp.Id = e.Id;  //atribui o Id correspondente
                        continue;
                    }
                }
            }
                                                
            Database.UpsertResult[] srList = Database.upsert(empList, false); //all or none a false (insire todos os registos passados)
            for(Database.UpsertResult sr : srList) {
                for(Database.Error err : sr.getErrors()) {
                    System.debug('ERR: ' + err.getMessage());
                    errorsOcurred.add(err.getMessage());
                }
            }
        } catch (DMLException e) {
            //retorna os erros dos que não dão para inserir, para fazer um toast
            return e.getDmlMessage(0);
        } catch (Exception e) {
            //retorna os erros dos que não dão para inserir, para fazer um toast
            return e.getMessage();
        }

        if(errorsOcurred.size() > 0) {
            return 'The following errors occured: ' + errorsOcurred + '. The rest of the records were successfully updated.';
        }
        return 'Records Updated';
    }

}
