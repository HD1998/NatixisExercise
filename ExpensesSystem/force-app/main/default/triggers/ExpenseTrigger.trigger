trigger ExpenseTrigger on Expense__c (after update) {
	ExpenseTriggerHandler expenseHandler = new ExpenseTriggerHandler();
    if(Trigger.isUpdate) {
        if(Trigger.isAfter) {
            expenseHandler.updateEDAmount(Trigger.OldMap, Trigger.NewMap);
        }
    }
}