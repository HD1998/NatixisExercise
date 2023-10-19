public class ExpenseTriggerHandler {
	public void updateEDAmount(Map<Id, Expense__c> triggerOldMap, Map<Id, Expense__c> triggerNewMap) {

        List<Expense_Distribution__c> edListToUpdate = new List<Expense_Distribution__c>();
        Set<Id> eIdsSet = new Set<Id>();
        
        //vai buscar os Ids das Expenses caso o Cost tenha sido alterado
        for(Id eId : triggerOldMap.KeySet()) {
            if(triggerOldMap.get(eId).Cost__c != triggerNewMap.get(eId).Cost__c ) {
                eIdsSet.add(eId);
            }
        }

        //Vai buscar as expenses
        List<Expense__c> eList = [SELECT Id, Name, Cost__c, Trip__c, Trip__r.Total_Participants__c FROM Expense__c WHERE Id In :eIdsSet];
        
        //vai buscar as eds correspondentes às expenses
        List<Expense_Distribution__c> edList = [SELECT Id, Name, Paid_Amount__c, Amount__c, Expense__r.Cost__c, Expense__r.Trip__c,
                                                Expense__r.Trip__r.Total_Participants__c
                                                FROM Expense_Distribution__c WHERE Expense__c IN :eList];

        //para cada ed
        for(Expense_Distribution__c ed : edList) {
            //atualiza a amount
            ed.Amount__c = ed.Expense__r.Cost__c / ed.Expense__r.Trip__r.Total_Participants__c;
            
            //altera paid amount caso seja maior que amount
            if(ed.Paid_Amount__c != null && ed.Paid_Amount__c > ed.Amount__c) {
                ed.Paid_Amount__c = ed.Amount__c;
            }
            
            edListToUpdate.add(ed);
        }

        update edListToUpdate;
        
    }
}