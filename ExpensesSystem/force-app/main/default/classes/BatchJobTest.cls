@isTest
public class BatchJobTest {
    
	@isTest
    public static void testBatchJob() {
        List<Employee__c> eList = new List<Employee__c>();
        for(Integer i = 3; i < 13; i++) {
            eList.add(new Employee__c(Name='E' + i, ID_Number__c=String.valueOf(i), ID_Type__c='A', Email__c='testEmail' + i + '@gmail.com'));
        }
        insert eList;
        
        Trip__c t1 = new Trip__c(Name = 'T1', Total_Participants__c = 10);
        insert t1;
        
        List<Expense__c> expList = new List<Expense__c>();
        for(Integer i = 3; i < 13; i++) {
            expList.add(new Expense__c(Name='Exp' + String.valueOf(i), Trip__c = t1.Id,
                                       Cost__c = 200, Responsible__c = eList[i - 3].Id));
        }
        insert expList;
        
        List<Expense_Distribution__c> edList = new List<Expense_Distribution__c>();
        for(Integer i = 3; i < 13; i++) {
            edList.add(new Expense_Distribution__c(Name='ED' + i, Employee__c = eList[i - 3].Id, Expense__c = expList[i - 3].Id, Paid_Amount__c = 1));
            edList.add(new Expense_Distribution__c(Name='ED' + i+100, Employee__c = eList[i - 3].Id, Expense__c = expList[i - 3].Id, Paid_Amount__c = 1));
        }
        insert edList;
        
        Test.startTest();
        Id batchId = Database.executeBatch(new BatchJob());
        Test.stopTest();
        
        System.assertEquals(true, BatchJob.emailSent);
    }
}