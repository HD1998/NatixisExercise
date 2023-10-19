public class CloseUnpaidExpensesBatch implements Database.Batchable<sObject> {
    public Database.QueryLocator start(Database.BatchableContext bc) {
        System.debug('Start');
        return Database.getQueryLocator('SELECT Id, Name, DaysSinceCreation__c, Status__c, Trip__c, Cost__c, Responsible__c, '
                                        + '(SELECT Id, Name, Expense__c, Employee__c, Paid_Amount__c, Number__c, CreatedDate, CreatedById FROM Expenses_Distribution__r) '
                                        + 'FROM Expense__c WHERE DaysSinceCreation__c < 2 AND Status__c != \'Paid\'');		//Para testar meter este 60 a 0
    }
    
    public void execute(Database.BatchableContext bc, List<Expense__c> expList) {
        
        System.debug(expList);
        
        List<Expense__c> newExpensesList = new List<Expense__c>();
        Map<Id, List<Expense_Distribution__c>> expEDMap = new Map<Id, List<Expense_Distribution__c>>();
        List<Expense_Distribution__c> edList = new List<Expense_Distribution__c>();
        
        //Percorre a lista de expenses e fecha-as. Cria Expenses novas no seu lugar
        for(Expense__c exp : expList) {
            exp.Status__c = 'Paid';
            Expense__c newExpense = new Expense__c(Name = exp.Name + 'New',
                                               Trip__c = exp.Trip__c,
                                               Status__c = 'New',
                                               Cost__c = exp.Cost__c,
                                               Responsible__c = exp.Responsible__c,
											   Closed_Expense__c = exp.Id);
            
            for(Expense_Distribution__c ed : exp.Expenses_Distribution__r) {
                // adiciona ao mapa o Id da Expense a fechar e a Lista de EDs 
                if(!expEDMap.containsKey(exp.Id)) {
                    expEDMap.put(exp.Id, new List<Expense_Distribution__c> {ed});
                } else {
                    expEDMap.get(exp.Id).add(ed);
                }
            }
            newExpensesList.add(newExpense);
        }
        
        try {
            update expList;
        	insert newExpensesList;
        } catch(DmlException ex) {
			System.debug(ex.getMessage());   
            return;
        } catch(Exception ex) {
            System.debug(ex.getMessage());
            return;
        }
        
        
        //percorre as novas expenses
        for(Expense__c exp : newExpensesList) {
            
            //percorre as EDs das expenses antigas
            for(Expense_Distribution__c ed : expEDMap.get(exp.Closed_Expense__c)) {
                
                //cloneia as EDs para as associar às novas Expenses
                Expense_Distribution__c clonedEd = ed.clone(false, true, true, true);
                clonedEd.Expense__c = exp.Id;
                clonedEd.Employee__c = ed.Employee__c;
                clonedEd.Name = ed.Name;
                clonedEd.Paid_Amount__c = ed.Paid_Amount__c;
                
                System.debug('CD: ' + ed.Number__c);
                System.debug('CDC: ' + clonedEd.Number__c);
                
                edList.add(clonedEd);
            }
        }
        
        try {
            insert edList;
        } catch(DmlException ex) {
			System.debug(ex.getMessage());   
        } catch(Exception ex) {
            System.debug(ex.getMessage());
        }
        
        for(Expense_Distribution__c ed : edList) {
            System.debug('ED: ' + ed);
        }
        
        List<Expense_Distribution__c> dbList = [SELECT Id, Name, Number__c FROM Expense_Distribution__c];
        System.debug('Lista de EDs: ' + dbList);
        
    }
    
    public void finish(Database.BatchableContext bc) {
        AsyncApexJob job = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email FROM AsyncApexJob
                           WHERE Id = :bc.getJobId()];
        System.debug('BatchJob: ' + job);
    }
}