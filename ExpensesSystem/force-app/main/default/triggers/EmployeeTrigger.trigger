trigger EmployeeTrigger on Employee__c (before insert, after update) {
	EmployeeTriggerHandler empHandler = new EmployeeTriggerHandler();
    if(Trigger.isInsert) {
        if(Trigger.isBefore) {
            empHandler.compositeKey(trigger.new);
        }
    }
}