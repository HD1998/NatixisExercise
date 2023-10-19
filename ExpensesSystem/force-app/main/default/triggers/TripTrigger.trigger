trigger TripTrigger on Trip__c (after update) {
	TripTriggerHandler tripHandler = new TripTriggerHandler();
    if(Trigger.isUpdate) {
        if(Trigger.isAfter) {
            tripHandler.updateEDAmount(Trigger.OldMap, Trigger.NewMap);
        }
    }
}