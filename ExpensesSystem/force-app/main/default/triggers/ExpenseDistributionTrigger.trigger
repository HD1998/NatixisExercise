trigger ExpenseDistributionTrigger on Expense_Distribution__c (before insert, after update) {
	ExpenseDistrTriggerHandler expenseDistrHandler = new ExpenseDistrTriggerHandler();
	if(Trigger.isUpdate) {
        if(Trigger.isAfter) {
            expenseDistrHandler.sendEmail(Trigger.oldMap);
        }
    } else if(Trigger.isInsert) {
        if(Trigger.isBefore) {
            expenseDistrHandler.compositeKey(Trigger.new);
            expenseDistrHandler.preventNewRecord(Trigger.new);
            expenseDistrHandler.calculateAmount(Trigger.new);
        }
    }
}