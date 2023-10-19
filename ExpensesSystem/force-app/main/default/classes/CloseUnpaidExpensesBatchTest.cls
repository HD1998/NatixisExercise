@isTest
public class CloseUnpaidExpensesBatchTest {
	
    @isTest
    public static void testBatchJob() {
        List<Employee__c> eList = new List<Employee__c>();
        for(Integer i = 0; i < 200; i++) {
            eList.add(new Employee__c(Name='E' + i, ID_Number__c=String.valueOf(i), ID_Type__c='A', Email__c='testEmail' + i + '@gmail.com'));
        }
        insert eList;
        
        Trip__c t1 = new Trip__c(Name = 'T1', Total_Participants__c = 10);
        insert t1;
        
        List<Expense__c> expList = new List<Expense__c>();
        for(Integer i = 0; i < 200; i++) {
            expList.add(new Expense__c(Name='Exp' + String.valueOf(i), Trip__c = t1.Id,
                                       Cost__c = 200, Responsible__c = eList[i].Id));
        }
        insert expList;
        
        List<Expense_Distribution__c> edList = new List<Expense_Distribution__c>();
        for(Integer i = 0; i < 200; i++) {
            edList.add(new Expense_Distribution__c(Name='ED' + i, Employee__c = eList[i].Id, Expense__c = expList[i].Id, Paid_Amount__c = 1));
            edList.add(new Expense_Distribution__c(Name='ED' + i+100, Employee__c = eList[i].Id, Expense__c = expList[i].Id, Paid_Amount__c = 1));
        }
        insert edList;
        
        Expense_Distribution__c ed = [SELECT Id, Name FROM Expense_Distribution__c WHERE Name = 'ED1'];
        
        Test.startTest();
        CloseUnpaidExpensesBatch cueb = new CloseUnpaidExpensesBatch();
        Id batchId = Database.executeBatch(cueb, 200);
        Test.stopTest();
        
        
        List<Expense__c> updatedList = [SELECT Id, Status__c, (SELECT Id, Name FROM Expenses_Distribution__r) FROM Expense__c WHERE Status__c = 'Paid'];
        System.assertEquals(200, updatedList.size());
        
        for(Expense__c e : updatedList) {
            System.assertNotEquals(0, e.Expenses_Distribution__r.size());
            /*if(e.Expenses_Distribution__r[0].Name == 'ED1') {
                System.assertEquals(ed.CreatedDate, e.Expenses_Distribution__r[0].CreatedDate);
                System.assertEquals(ed.Number__c, e.Expenses_Distribution__r[0].Number__c);
            }*/
            
        }
        
    }
}