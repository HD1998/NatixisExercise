public class EmployeeTriggerHandler {
	public void compositeKey(List<Employee__c> triggerNew) {        
        
        List<String> idNumList = new List<String>();
        List<String> idTypeList = new List<String>();
        Set<String> pkSet = new Set<String>();
        List<String> repeatedpkList = new List<String>();
        List<Employee__c> errorList = new List<Employee__c>();
        List<String> errorMessageList = new List<String>();
        
        //percorre os employees a adicionar
        for(Employee__c e : triggerNew) { 
      
            //se ainda não tiver percorrido esta PK, adiciona os valores a listas parar ver na DB
            if(!repeatedpkList.contains(e.ID_Number__c + '_' + e.ID_Type__c)) {
                idNumList.add(e.ID_Number__c);
            	idTypeList.add(e.ID_Type__c);
                repeatedpkList.add(e.ID_Number__c + '_' + e.ID_Type__c);
                
            } else {	//se já tiver percorrido aquela PK, guarda num array para dar erro depois
                errorList.add(e);
            }                  
        }
        
        
        //guarda numa lista os employees cuja combinação deste idNum e idType já exista
        List<Employee__c> repetedEmployeeList = [SELECT Name, ID_Number__c, ID_Type__c FROM Employee__c WHERE ID_Number__c
                                  IN :idNumList AND ID_Type__c IN :idTypeList];
        
        //percorre a lista de employees que já existe na DB com estes número e type e guarda num Set
        for(Employee__c e : repetedEmployeeList) {
            pkSet.add(e.ID_Number__c + '_' + e.ID_Type__c);
        }
        
        
        /*if(pkSet.size() > 0){
            //percorre novamente todos os employees inseridos
        	for(Employee__c e : triggerNew) {
                //verifica se cada employee contêm a combinação que está no Set ou se já se viu em cima que é repetido
                if(pkSet.contains(e.ID_Number__c + '_' + e.ID_Type__c) || errorList.contains(e)) {
                    //se sim não deixa criar
                	e.addError('This combination of ID Number and ID Type already exists');
                }
            }
        }*/
        
        //se o Set tiver valores
        if(pkSet.size() > 0){
            //percorre novamente todos os employees inseridos
            for(Integer i = 0; i < triggerNew.size(); i++) {
                //verifica se cada employee contêm a combinação que está no Set ou se já se viu em cima que é repetido
                if(pkSet.contains(triggerNew[i].ID_Number__c + '_' + triggerNew[i].ID_Type__c) || errorList.contains(triggerNew[i])) {
                    //se sim não deixa criar
                    errorMessageList.add('(Name:' + triggerNew[i].Name + ', ID Number: ' + triggerNew[i].ID_Number__c
                                        + ', ID Type: ' + triggerNew[i].ID_Type__c + ')');
                }
                //Se for last record adiciona a mensagem de erro
                if(i == triggerNew.size() - 1) {
                    triggerNew[i].addError('The following records combination of ID Number and ID Type already exist in the DB: '
                                          + errorMessageList);
                }
            }
        }
    }
}