public class ScheduledJob implements Schedulable {
    
    public void execute(SchedulableContext ctx) {   
            
        BatchJob batchJob = new BatchJob();
        //corre o batch
        Id batchId = Database.executeBatch(batchJob, 10);
        
        AsyncApexJob job = [SELECT Id, Status, JobItemsProcessed, TotalJobItems, NumberOfErrors FROM AsyncApexJob WHERE ID = :batchId ];
        
        System.debug('Scheduled Job: ' + job);
    }
}