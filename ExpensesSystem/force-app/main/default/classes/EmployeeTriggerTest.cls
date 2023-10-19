@isTest
public class EmployeeTriggerTest {
    
    //CRIAÇÃO DE DADOS (A DB ESTÁ VAZIA ANTES DISTO)
	@TestSetup
    public static void setup() {
        
        //Criação de 5 Employees
        List<Employee__c> eList = new List<Employee__c>();
        for(Integer i = 0; i < 200; i++) {
            Employee__c e = new Employee__c(Name='E' + i, ID_Number__c=String.valueOf(i), ID_Type__c='A', Email__c='aa@gg' + i + '.com');
            eList.add(e);
        }
        insert eList;
    }
    
    @isTest
    public static void testCompositePKInsertOneRecordFail() {
        //caso a testar: verifica se consegue inserir este registo (com este IdNum e IDType) na DB. Não consegue porque já existe (criei no setup)
        Employee__c e = new Employee__c(Name='E3', ID_Number__c='1', ID_Type__c='A', Email__c='aa@gg.com');
        
        Test.startTest();
        try {
            Database.insert(e, true);
        } catch (DMLException ex) {
            String msg = 'The following records combination of ID Number and ID Type already exist in the DB: '
                           + '((Name:' + e.Name + ', ID Number: ' + e.ID_Number__c
                                        + ', ID Type: ' + e.ID_Type__c + '))';
        	System.assertEquals(msg, ex.getDmlMessage(0));
        } catch (Exception ex) {
            ex.getMessage();
        }
        Test.stopTest();
    }
    
    @isTest
    public static void testCompositePKInsertOneRecordSuccess() {
    	//caso a testar, verifica se consegue inserir este registo (com este IdNum e IDType) na DB. Consegue porque ainda não existe (não está nos criados no setup)
        Employee__c e = new Employee__c(Name='E3', ID_Number__c='1', ID_Type__c='B', Email__c='aa@gg.com');
        
        Test.startTest();
        //inserts, updates e assim
        Database.SaveResult sr = Database.insert(e, true);
        Test.stopTest();
        
        //Query aos objetos pós update
        Employee__c emp = [SELECT Id, Name, ID_Number__c, ID_Type__c FROM Employee__c WHERE ID_Number__c = '1' AND ID_Type__c = 'B'];
        
        //asserts
        System.Assert(sr.isSuccess());
        System.Assert(sr.getErrors().size() == 0);
        //verifica se o record que está na DB com ID_Number__c = '1' AND ID_Type__c = 'B' é o que foi criado agora (mesmo Id)
        System.assertEquals(e.Id, emp.Id);
    }
    
    @isTest
    public static void testCompositePKInsertMultipleRecordFail() {
        //caso a testar: verifica se consegue inserir estes registos (com este IdNum e IDType) na DB. Não consegue porque já existem na DB (criados no setup)
        
        List<Employee__c> eList = new List<Employee__c>();
        
        String errorMessageRecords = '((Name:';
        
        eList.add(new Employee__c(Name='E10', ID_Number__c='1', ID_Type__c='A', Email__c='aa@gg10.com'));
        errorMessageRecords += eList[0].Name + ', ID Number: ' + eList[0].ID_Number__c
                                        + ', ID Type: ' + eList[0].ID_Type__c + '), ';
        
        for(Integer i = 0; i < 200; i++) {
            Employee__c e = new Employee__c(Name='E' + i, ID_Number__c=String.valueOf(i), ID_Type__c='A', Email__c='aa@gg' + i + '.com');
            eList.add(e);
            
            if (i < 8) {
                errorMessageRecords += '(Name:' + e.Name + ', ID Number: ' + e.ID_Number__c
                                        + ', ID Type: ' + e.ID_Type__c + '), ';
            } else if(i == 8) {
                errorMessageRecords += '(Name:' + e.Name + ', ID Number: ' + e.ID_Number__c
                                        + ', ID Type: ' + e.ID_Type__c + '), ...)';
            }
        }
        
        Test.startTest();
        try {
            Database.insert(eList, true);
        } catch (DMLException ex) {
            String msg = 'The following records combination of ID Number and ID Type already exist in the DB: '
                           + errorMessageRecords;
        	System.assertEquals(msg, ex.getDmlMessage(0));
        } catch (Exception ex) {
            ex.getMessage();
        }
        Test.stopTest();
    }
    
    
    @isTest //testar multiple record success
    public static void testCompositePKInsertMultipleRecordSuccess() {
        //caso a testar, verifica se consegue inserir estes registos (com este IdNum e IDType) na DB. Consegue porque não existem na DB ainda (diferentes do no setup)
        
        List<Employee__c> eList = new List<Employee__c>();
        List<String> alphabet = new List<String>{'B', 'C', 'D', 'E', 'F'};
            //fazer com numeros de 201 a 400 ( e mudar no setup, fazer de 1 a 200)
            
        for(Integer i = 201; i < 400; i++) {
            Employee__c e = new Employee__c(Name='E' + i, ID_Number__c= String.valueOf(i), ID_Type__c= 'B', Email__c='aa@gg' + i + '.com');
            eList.add(e);
        }
        
        Test.startTest();
        //inserts, updates e assim
        Database.SaveResult[] srList = Database.insert(eList, true);
        Test.stopTest();
        
        //Vai buscar à DB os registos com estas combinações de ID_Number__c e ID_Type__c
        List<Employee__c> empList = [SELECT Id, Name, ID_Number__c, ID_Type__c FROM Employee__c WHERE ID_Type__c = 'B' Order By ID_Number__c];
       
        //asserts
        //verifica se os records que estão na DB com os ID_Number__c e ID_Type__c inseridos são os mesmos que os criados agora (mesmo Id)
        for(Integer i = 0; i < empList.size() - 1; i++) {
            System.assertEquals(eList[i].Id, empList[i].Id);
        }
        
        for(Database.SaveResult sr : srList) {
            System.Assert(sr.isSuccess());
        	System.Assert(sr.getErrors().size() == 0);
        }
    }
}