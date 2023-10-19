public with sharing class ExpenseController {
    @AuraEnabled(cacheable = true)
    public static List<Expense__c> getExpenses(String tripId){
        return [SELECT Id, Name, Status__c, Cost__c, Description__c, Total_Paid_Amount__c, Total_Unpaid_Employees__c FROM Expense__c WHERE Trip__c = :tripId];
    }
}