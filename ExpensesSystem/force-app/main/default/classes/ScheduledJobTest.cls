@isTest
public class ScheduledJobTest {

    public static String CRON_EXP = '0 0 0 ? * * *';
    
    @isTest
    public static void testScheduledJob() {

        Test.startTest();
        String jobId = System.schedule('ScheduledJobTest', CRON_EXP, new ScheduledJob());
        Test.stopTest();
        
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, 
         NextFireTime
         FROM CronTrigger WHERE id = :jobId];
        
        System.assertEquals('2023-01-04 00:00:00', String.valueOf(ct.NextFireTime));
    }
}