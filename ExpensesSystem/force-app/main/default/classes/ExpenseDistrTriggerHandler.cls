public class ExpenseDistrTriggerHandler {
    
    //after update
	public void sendEmail(Map<Id,Expense_Distribution__c> triggerOldMap) {
        //triggerOldMap contêm os valores antigos dos records alterados.
        
        //newExpenseDistr procura na DB os records alterados com os valores alterados
        List<Expense_Distribution__c> newExpenseDistr = [Select Id, Name, Employee__c, Employee__r.Email__c, Expense__c, Amount__c, Paid_Amount__c FROM Expense_Distribution__c
                            WHERE Id IN :triggerOldMap.keySet()];
        
        //percorre-se a lista de records alterados
        for(Expense_Distribution__c expDist : newExpenseDistr) {
            //procura o record correspondente no mapa
            if(triggerOldMap.get(expDist.Id).Id == expDist.Id) {
                //Verifica se a Paid Amount está a ser alterada
                if(triggerOldMap.get(expDist.Id).Paid_Amount__c != expDist.Paid_Amount__c) {
                    //se a Paid Amount for igual à Amount envia email
                    if(expDist.Paid_Amount__c == expDist.Amount__c) {
                        //estou a receber a mensagem de sucesso do mail manager, mas não estou a receber o mail
                        
                        if(!Test.isRunningTest()) {
                            EmailManager.sendMail(expDist.Employee__r.Email__c, 'Payment Confirmation', 'Your Expense distribution is fully paid.', '');
                        }
                        
                    }
                    
                }
            }
        }
    }
    
    
    //before insert
    //previne a criação de mais Expense Distributions do que Total Participants para a Expense em comum
    public void preventNewRecord(List<Expense_Distribution__c> triggerNew) {
        Set<Id> eIdsSet = new Set<Id>();
        Map<Id, Integer> countOfEdsMap = new Map<Id, Integer>();
        List<String> errorMessageList = new List<String>();
        Integer edCount = 1;
        //percorre as EDs em triggerNew
        for(Expense_Distribution__c ed : triggerNew) {
            //Guarda a lista de Ids da Expense num set (para não repetir valores)
            eIdsSet.add(ed.Expense__c);
            
            //se esta Expense ainda não existir no mapa, adiciona-o com 1 ED
            if(!countOfEdsMap.containsKey(ed.Expense__c)) {
                edCount = 1;
                countOfEdsMap.put(ed.Expense__c, 1);
            } else {	//se já existir, soma 1 à qtd atual de EDs nesta Expense
                edCount = countOfEdsMap.get(ed.Expense__c);
                countOfEdsMap.put(ed.Expense__c, edCount + 1); 
            }
        }
        
        
        //Cria um mapa de expenses (que já contem os valores necessários da trip)
        Map<Id, Expense__c> eMap = new Map<Id, Expense__c>([SELECT Id, Name, Count_Of_EDs__c, Trip__r.Id, Trip__r.Name,
                                                                 Trip__r.Total_Participants__c FROM Expense__c WHERE Id In: eIdsSet]);
        
        
        for(Integer i = 0; i < triggerNew.size(); i++) {
            if(eMap.get(triggerNew[i].Expense__c).Count_Of_EDs__c + countOfEdsMap.get(triggerNew[i].Expense__c) > eMap.get(triggerNew[i].Expense__c).Trip__r.Total_Participants__c) {
                errorMessageList.add('(Name:' + triggerNew[i].Name + ')');
            }
            
            if(errorMessageList.size() > 0 && i == triggerNew.size() - 1) {
                triggerNew[i].addError('The following Expense Distributions can\'t be added because they exceed the limit of EDs for the respetive Expense: '
                                      + errorMessageList);
            }
        }
        
        //Percorre novamente as Eds do triggerNew
        /*for(Expense_Distribution__c ed : triggerNew) {
            
            System.debug('MAP: ' + eMap.get(ed.Expense__c).Count_Of_EDs__c);
            System.debug('MAPName: ' + eMap.get(ed.Expense__c).Name);
            System.debug('MAPCofEDS: ' + countOfEdsMap.get(ed.Expense__c));
            
            //-Fazer o que fiz para a composite key, adicionar os registos a dar erro a uma lista e dar o erro no último registo só
            
            //Se a Count_Of_EDs__c da Expense correspondente à ED atual
            //+ a QtdEds para essa Expense que estou a inserir agora for maior que
            //o Total_Participants__c da Trip correspondente à Expense da ED atual
            if(eMap.get(ed.Expense__c).Count_Of_EDs__c + countOfEdsMap.get(ed.Expense__c) > eMap.get(ed.Expense__c).Trip__r.Total_Participants__c) {
                ed.addError('The amount of Expense Distributions for this Expense already reached its limit');
            }
        }*/
    }
    
    //before insert
    /*public void compositeKey(List<Expense_Distribution__c> triggerNew) {
 
        List<String> empList = new List<String>();
        List<String> expList = new List<String>();
        
        for(Expense_Distribution__c ed : triggerNew) {
            empList.add(ed.Employee__c);
            expList.add(ed.Expense__c);
        }
        System.debug('empList: ' + empList);
        System.debug('expList: ' + expList);
        
        List<Expense_Distribution__c> repetedEDsList = [SELECT Employee__c, Expense__c FROM Expense_Distribution__c WHERE Employee__c
                                  IN :empList AND Expense__c IN:expList];
        
        System.debug('repetedEDsList: ' + repetedEDsList);
        
        if(repetedEDsList.size() > 0){
        	for(Expense_Distribution__c ed : triggerNew) {
                ed.addError('Can\'\'t have more than 1 Expense Distribution per Employee in this Expense.');
            }
        }
    }*/
    public void compositeKey(List<Expense_Distribution__c> triggerNew) {
 
        List<String> empList = new List<String>();
        List<String> expList = new List<String>();
        Set<String> pkSet = new Set<String>();
        List<String> repeatedpkList = new List<String>();
        List<Expense_Distribution__c> errorList = new List<Expense_Distribution__c>();
        List<String> errorMessageList = new List<String>();
        
        //percorre os employees a adicionar
        for(Expense_Distribution__c ed : triggerNew) {
            
            //se ainda não tiver percorrido esta PK, adiciona os valores a listas parar ver na DB
            if(!repeatedpkList.contains(ed.Employee__c + '_' + ed.Expense__c)) {
                empList.add(ed.Employee__c);
            	expList.add(ed.Expense__c);
                repeatedpkList.add(ed.Employee__c + '_' + ed.Expense__c);
                
            } else {	//se já tiver percorrido aquela PK, guarda num array para dar erro depois
                errorList.add(ed);
            }
        }

        //guarda numa lista os employees cuja combinação deste Employee e Expense já exista
        List<Expense_Distribution__c> repetedEDsList = [SELECT Name, Employee__c,  Expense__c FROM Expense_Distribution__c WHERE Employee__c
                                  IN :empList AND Expense__c IN:expList];
        
        //percorre a lista de eds que já existe na DB com estes employee e expense e guarda num Set
        for(Expense_Distribution__c ed : repetedEDsList) {
            pkSet.add(ed.Employee__c + '_' + ed.Expense__c);
        }
        
        if(pkSet.size() > 0){
            //percorre novamente todos as eds inseridas
            for(Integer i = 0; i < triggerNew.size(); i++) {
                //verifica se cada ed contêm a combinação que está no Set ou se já se viu em cima que é repetido
                if(pkSet.contains(triggerNew[i].Employee__c + '_' + triggerNew[i].Expense__c) || errorList.contains(triggerNew[i])) {
                    //se sim não deixa criar
                    errorMessageList.add('(Name:' + triggerNew[i].Name + ')');
                }
                //Se for last record adiciona a mensagem de erro
                if(i == triggerNew.size() - 1) {
                    triggerNew[i].addError('The following records cant be created because the combination of Employee and Expense already exist in the DB: '
                                          + errorMessageList);
                }
            }
        }
    }
    
    
    //before insert
    //calcula a Amount da(s) ED(s) que estão a ser criadas
    public void calculateAmount(List<Expense_Distribution__c> triggerNew) {
        Set<Id> eIdsSet = new Set<Id>();
        //percorre a lista de eds
        for(Expense_Distribution__c ed : triggerNew) {
            //guarda os ids da expense da ed
            eIdsSet.add(ed.Expense__c);
        }
        
        //vai buscar o Cost da Expense e o Total Participants da Trip
        Map<Id, Expense__c> eMap = new Map<Id, Expense__c>([SELECT Id, Name, Cost__c, Trip__r.Total_Participants__c FROM Expense__c WHERE Id in :eIdsSet]);
        
        //volta a percorrer as EDs a ser criadas
        for(Expense_Distribution__c ed : triggerNew) {
            //Altera a Amount
            ed.Amount__c = eMap.get(ed.Expense__c).Cost__c / eMap.get(ed.Expense__c).Trip__r.Total_Participants__c;
            
            //altera paid amount caso seja maior que amount
            if(ed.Paid_Amount__c != null && ed.Paid_Amount__c > ed.Amount__c) {
                ed.Paid_Amount__c = ed.Amount__c;
            }
            
        }
    }
   
}