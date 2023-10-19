public class TripTriggerHandler {

    public void updateEDAmount(Map<Id, Trip__c> triggerOldMap, Map<Id, Trip__c> triggerNewMap) {
        Set<Id> tIdsSet = new Set<Id>();
        
        //percorre a lista de trips a serem atualizadas
        for(Id tId : triggerOldMap.KeySet()) {
            //se o nr de participantes tiver sido alterado, guarda os ids das trips num set
            if(triggerOldMap.get(tId).Total_Participants__c != triggerNewMap.get(tId).Total_Participants__c ) {                
                tIdsSet.add(tId);
            }
        }
        
        //Vai buscar as expenses correspondentes a estas trips
        List<Expense__c> eList = [SELECT Id, Name, Cost__c, Trip__c, Trip__r.Total_Participants__c FROM Expense__c WHERE Trip__c In :tIdsSet];
 
        //Vai buscar as EDs correspondentes a estas Expenses
        List<Expense_Distribution__c> edList = [SELECT Id, Name, Paid_Amount__c, Amount__c, Expense__r.Cost__c, Expense__r.Trip__c 
                                                FROM Expense_Distribution__c WHERE Expense__c IN :eList];
        
        List<Expense_Distribution__c> edListToUpdate = new List<Expense_Distribution__c>();
        
        //Percorre a lista de EDs
        for(Expense_Distribution__c ed : edList) {
            //define-lhes nova Amount
            ed.Amount__c = ed.Expense__r.Cost__c / triggerNewMap.get(ed.Expense__r.Trip__c ).Total_Participants__c;
            
            //altera paid amount caso seja maior que amount
            if(ed.Paid_Amount__c != null && ed.Paid_Amount__c > ed.Amount__c) {
                ed.Paid_Amount__c = ed.Amount__c;
            }
            edListToUpdate.add(ed);
        }
       
        update edListToUpdate;
    }
}