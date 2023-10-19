public with sharing class EDController {

    @AuraEnabled(cacheable = true)
    public static List<Expense_Distribution__c> getEDs(String expenseId) {

        //retorna as EDs de cada Expense
        return [SELECT Id, Name, Employee__r.name, Expense__r.name, Paid_Amount__c, Amount__c 
                FROM Expense_Distribution__c 
                WHERE Expense__c = :expenseId order by Employee__r.name];
    }

    @AuraEnabled
    public static void deleteEd(Id edId){
        try {
            delete [SELECT Id FROM Expense_Distribution__c WHERE Id = :edId];  
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /*@AuraEnabled(cacheable = true)
    public static List<Employee__c> getEmployees(){
        return [SELECT Id, Name FROM Employee__c];
    }*/

    /*@AuraEnabled
    public static Boolean deleteEd(Id edId){
        boolean retSt = false;
        try {
            delete [SELECT Id FROM Expense_Distribution__c WHERE Id = :edId];  
            retSt = true;
        } catch (Exception e) {
            //throw new AuraHandledException(e.getMessage());
            retSt = false;
            
        }
        /*Database.DeleteResult[] drList = Database.delete([SELECT Id FROM Expense_Distribution__c WHERE Id = :edId]);
        for(Database.DeleteResult dr : drList) {
            if(dr.isSuccess()) {
                retSt = true;
            } else {
                retSt = false;
            }
        }*/
        
        /*return retSt;
    }*/

}