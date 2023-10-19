@isTest
public class EDTriggerTest {
    
    //CRIAÇÃO DE DADOS (A DB ESTÁ VAZIA ANTES DISTO)
    @TestSetup
    public static void setup() {
        List<Expense_Distribution__c> edList = new List<Expense_Distribution__c>();
        List<Employee__c> eList = new List<Employee__c>();
        List<Trip__c> tList = new List<Trip__c>();
        List<Expense__c> expList = new List<Expense__c>();
        
        //Criação de Trips para testes
        Trip__c t1 = new Trip__c(Name='T1', Total_Participants__c = 20);
        Trip__c t2 = new Trip__c(Name='T2', Total_Participants__c = 2);
        Trip__c t3 = new Trip__c(Name='T3', Total_Participants__c = 6);
        Trip__c t4 = new Trip__c(Name='T4', Total_Participants__c = 400);
        tList.add(t1);
        tList.add(t2);
        tList.add(t3);
        tList.add(t4);
        insert tList;
        
        //Criação de Expenses com as respetivas Trips
        Expense__c exp1 = new Expense__c(Name='Exp1', Trip__c = t1.Id, Cost__c = 200);
        Expense__c exp2 = new Expense__c(Name='Exp2', Trip__c = t2.Id, Cost__c = 100);
        Expense__c exp3 = new Expense__c(Name='Exp3', Trip__c = t3.Id, Cost__c = 600);
        Expense__c exp44 = new Expense__c(Name='Exp44', Trip__c = t4.Id, Cost__c = 800);
        expList.add(exp1);
        expList.add(exp2);
        expList.add(exp3);
        expList.add(exp44);
        insert expList;
        
        //Criação de 5 Employees
        for(Integer i = 0; i < 200; i++) {
            Employee__c e = new Employee__c(Name='E' + i, ID_Number__c=String.valueOf(i), ID_Type__c='A', Email__c='aa@gg' + i + '.com');
            eList.add(e);
        }
        insert eList;
        
        //Criação de 5 EDs para os Employees e para a Expense correspondente
        for(Integer i = 0; i < 200; i++) {
            Expense_Distribution__c ed = new Expense_Distribution__c(Name='ED' + i, Employee__c = eList[i].Id, Expense__c = exp44.Id, Paid_Amount__c = 1);
            edList.add(ed);
        }
        insert edList;
    }
    
    //COMPOSITE PK TESTS
    
    @isTest
    public static void testCompositePKInsertOneRecordFail() {
        //caso a testar: verifica se consegue inserir este registo (com este Employee__c e Expense__c) na DB. Não consegue porque já existe (criei no setup)
        
        Expense__c exp = [SELECT Id, Name FROM Expense__c WHERE Name = 'Exp1'];
        
        Employee__c e = [SELECT Id, Name FROM Employee__c WHERE Name = 'E1'];
        
        Expense_Distribution__c ed = new Expense_Distribution__c(Name='ED1', Employee__c = e.Id, Expense__c = exp.Id);
       
        
        Test.startTest();
        //inserts, updates e assim
        try {
            Database.insert(ed, true);
        } catch (DMLException ex) {
            //asserts
			System.debug('EXCEPTION: ' + ex.getDMLMessage(0));
        	System.assertEquals('The following records cant be created because the combination of Employee and Expense already exist in the DB: '
                           + '((Name:' + ed.Name + '))', ex.getDMLMessage(0));
        } catch (Exception ex) {
            ex.getMessage();
        }
        Test.stopTest();
    }
    
    @isTest
    public static void testCompositePKInsertOneRecordSuccess() {
    	//caso a testar: verifica se consegue inserir este registo (com este Employee__c e Expense__c) na DB. Consegue porque ainda não existe
    	//(não está nos criados no setup)
        
        Expense__c exp = [SELECT Id, Name FROM Expense__c WHERE Name = 'Exp1'];

        Employee__c e = new Employee__c(Name='E10', ID_Number__c='1', ID_Type__c='B', Email__c='aa@gg.com');
        insert e;
        
        Expense_Distribution__c ed = new Expense_Distribution__c(Name='ED1', Employee__c = e.Id, Expense__c = exp.Id);
        
        
        Test.startTest();
        //inserts, updates e assim
        Database.SaveResult sr = Database.insert(ed, true);
        Test.stopTest();
        
        Expense_Distribution__c expdist = [SELECT Id, Name, Employee__r.Name, Expense__r.Name FROM Expense_Distribution__c WHERE Employee__r.Name = 'E10'
                                          AND Expense__r.Name = 'Exp1'];
        
        //asserts
        System.Assert(sr.isSuccess());
        System.Assert(sr.getErrors().size() == 0);
        //verifica o record que está na DB com o que foi criado agora (mesmo Id)
        System.assertEquals(ed.Id, expdist.Id);
    }
    
    @isTest //testar multiple record success
    public static void testCompositePKInsertMultipleRecordSuccess() {
        //caso a testar: verifica se consegue inserir estes registos (com este Employee__c e Expense__c) na DB. Consegue porque não existem na DB ainda 
        //(diferentes do no setup)
        
        List<Employee__c> eList = [SELECT Id, Name FROM Employee__c];
        Trip__c t = [SELECT Id, Name FROM Trip__c WHERE Name = 'T4'];
        List<Expense_Distribution__c> edList = new List<Expense_Distribution__c>();
        
        Expense__c exp = new Expense__c(Name='Exp4', Trip__c = t.Id, Cost__c = 200);
        insert exp;
        
        for(Integer i = 0; i < 200; i++) {
            Expense_Distribution__c ed = new Expense_Distribution__c(Name='ED' + i, Employee__c = eList[i].Id, Expense__c = exp.Id);
            edList.add(ed);
        }
        
        Test.startTest();
        //inserts, updates e assim
        Database.SaveResult[] srList = Database.insert(edList, true);
        Test.stopTest();
        
        //Vai buscar à DB os registos com estas combinações de Employee__c e Expense__c
        List<Expense_Distribution__c> expdistList = [SELECT Id, Name, Employee__r.Name, Expense__r.Name FROM Expense_Distribution__c WHERE Expense__r.Name = 'Exp4'
                                                    Order By Id];
       
        //asserts
        //verifica se os records que estão na DB com os Employee__c e Expense__c inseridos são os mesmos que os criados agora (mesmo Id)
        for(Integer i = 0; i < expdistList.size(); i++) {
            System.assertEquals(edList[i].Id, expdistList[i].Id);
        }
        
        for(Database.SaveResult sr : srList) {
            System.Assert(sr.isSuccess());
        	System.Assert(sr.getErrors().size() == 0);
        }
    }
    
    @isTest
    public static void testCompositePKInsertMultipleRecordFail() {
        //caso a testar: verifica se consegue inserir estes registos (com este Employee__c e Expense__c) na DB. Não consegue porque já existem na DB 
        //(criados no setup)
        List<Expense_Distribution__c> edList = new List<Expense_Distribution__c>();
        List<Employee__c> eList = [SELECT Id, Name FROM Employee__c];
        Expense__c exp1 = [SELECT Id, Name FROM Expense__c WHERE Name = 'Exp44'];
        String edNames = '((Name:';
        
        edList.add(new Expense_Distribution__c(Name='ED0', Employee__c = eList[0].Id, Expense__c = exp1.Id, Paid_Amount__c = 1));
        edNames += edList[0].Name + '), ';
        
        for(Integer i = 0; i < 200; i++) {
            Expense_Distribution__c ed = new Expense_Distribution__c(Name='ED' + i, Employee__c = eList[i].Id, Expense__c = exp1.Id, Paid_Amount__c = 1);
            edList.add(ed);
            
            if (i < 8) {
                edNames += '(Name:' + ed.Name + '), ';
            } else if(i == 8) {
                edNames += '(Name:' + ed.Name + '), ...)';
            }
        }
        
        Test.startTest();
        //inserts, updates e assim
        try {
            Database.insert(edList, true);
        } catch (DMLException ex) {
            String msg = 'The following records cant be created because the combination of Employee and Expense already exist in the DB: '
                           + edNames;
        	System.assertEquals(msg, ex.getDmlMessage(0));
        } catch (Exception ex) {
            ex.getMessage();
        }
        Test.stopTest();
        
    }
    
    
    //SENDEMAIL TESTS
    
    @isTest	//testa o método sendEmail do EDTrigger			
    public static void testSendEmailBulkSuccess() {
        //vai buscar as EDs criadas no setup()
        List<Expense_Distribution__c> edList = [SELECT Id, Name, Paid_Amount__c, Amount__c FROM Expense_Distribution__c];
        
        //por cada ed iguala a Paid_Amount à Amount
        for(Expense_Distribution__c ed : edList) {
            ed.Paid_Amount__c = ed.Amount__c;
        }
        
        Test.startTest();
        Database.SaveResult[] srList = Database.update(edList, true);
        Test.stopTest();
        
        //verifica se o email foi enviado
        //verifica se os registos foram atualizados
        for(Database.SaveResult sr : srList) {
            System.Assert(sr.isSuccess());
        	System.Assert(sr.getErrors().size() == 0);
        }
    }
    
    //PREVENTNEWRECORD TESTS
    
    @isTest //testa o método preventNewRecord do EDTrigger (fail = previne que os records sejam inseridos)
    public static void testPreventNewRecordBulkFail() {
        List<Expense_Distribution__c> edList = new List<Expense_Distribution__c>();
        
        Trip__c t = [SELECT Id, Name, Total_Participants__c FROM Trip__c WHERE Name = 'T2'];
        Expense__c exp = [SELECT Id, Name, Cost__c, Trip__c, Trip__r.Total_Participants__c, Count_Of_EDs__c FROM Expense__c WHERE Name = 'Exp2'];
        
        List<Employee__c> eList = [SELECT Id, Name FROM Employee__c];
        
        String edNames = '(';
        
        for(Integer i = 0; i < 200; i++) {
            Expense_Distribution__c ed = new Expense_Distribution__c(Name='ED' + i, Employee__c = eList[i].Id, Expense__c = exp.Id, Paid_Amount__c = 1);
            edList.add(ed);
            
            if (i < 9) {
                edNames += '(Name:' + ed.Name + '), ';
            } else if(i == 9) {
                edNames += '(Name:' + ed.Name + '), ...)';
            }
        }
        
        Test.startTest();
        try {
            Database.insert(edList, true);
        } catch (DMLException ex) {
            String msg = 'The following Expense Distributions can\'t be added because they exceed the limit of EDs for the respetive Expense: '
                           + edNames;
        	System.assertEquals(msg, ex.getDmlMessage(0));
        } catch (Exception ex) {
            ex.getMessage();
        }
        Test.stopTest();
        
    }
    
    @isTest //testa o método preventNewRecord do EDTrigger (success = os records são corretamente inseridos)
    public static void testPreventNewRecordBulkSuccess() {
        
        List<Expense_Distribution__c> edList = new List<Expense_Distribution__c>();        
        List<Employee__c> eList = new List<Employee__c>();
        
        Trip__c t = [SELECT Id, Name, Total_Participants__c FROM Trip__c WHERE Name = 'T4'];
        Expense__c exp = [SELECT Id, Name, Cost__c, Trip__c, Trip__r.Total_Participants__c, Count_Of_EDs__c FROM Expense__c WHERE Name = 'Exp44'];
        
        //List<Employee__c> eList = [SELECT Id, Name FROM Employee__c];
        for(Integer i = 200; i < 400; i++) {
            Employee__c e = new Employee__c(Name='E' + i, ID_Number__c=String.valueOf(i), ID_Type__c='A', Email__c='aa@gg' + i + '.com');
            eList.add(e);
        }
        insert eList;
        
        //inserir registos novos que ainda não existam na DB para esta Expense, nem mais EDs que o Total Participants da Trip
        for(Integer i = 200; i < 400; i++) {
            Expense_Distribution__c ed = new Expense_Distribution__c(Name='ED' + i, Employee__c = eList[i-200].Id, Expense__c = exp.Id, Paid_Amount__c = 1);
            edList.add(ed);
        }
        
        
        Test.startTest();
        Database.SaveResult[] srList = Database.insert(edList, true);
        Test.stopTest();
        
        //asserts
        for(Database.SaveResult sr : srList) {
            System.Assert(sr.isSuccess());
            System.Assert(sr.getErrors().size() == 0);  
        }
    }
    
    //CALCULATEAMOUNT TESTS
    
    @isTest
    public static void testCalculateAmountSuccess() {
        //VERIFICAR SE A AMOUNT ESTÁ PREENCHIDA APÓS CRIAÇÃO
        List<Expense_Distribution__c> edList = new List<Expense_Distribution__c>();       
        List<Employee__c> eList = new List<Employee__c>();
        
        Trip__c t = [SELECT Id, Name, Total_Participants__c FROM Trip__c WHERE Name = 'T4'];
        Expense__c exp = [SELECT Id, Name, Cost__c, Trip__c, Trip__r.Total_Participants__c, Count_Of_EDs__c FROM Expense__c WHERE Name = 'Exp44'];
        
        //List<Employee__c> eList = [SELECT Id, Name FROM Employee__c];
        
        for(Integer i = 200; i < 400; i++) {
            Employee__c e = new Employee__c(Name='E' + i, ID_Number__c=String.valueOf(i), ID_Type__c='A', Email__c='aa@gg' + i + '.com');
            eList.add(e);
        }
        
        Test.startTest();
        
        insert eList;
        
        //inserir registos novos que ainda não existam na DB para esta Expense, nem mais EDs que o Total Participants da Trip
        for(Integer i = 200; i < 400; i++) {
            Expense_Distribution__c ed = new Expense_Distribution__c(Name='ExpDist200', Employee__c = eList[i-200].Id, Expense__c = exp.Id, Paid_Amount__c = 1,
                                                                     Amount__c = 0 );
            if(i == 200 || i == 201) {
                ed.Paid_Amount__c = 150;
            }
            edList.add(ed);
        }
        
        
        Database.SaveResult[] srList = Database.insert(edList, true);
        Test.stopTest();
        
        //Query aos objetos pós insert
        List<Expense_Distribution__c> expDistList = [SELECT Id, Name, Amount__c, Paid_Amount__c FROM Expense_Distribution__c WHERE Name = 'ExpDist200'
                                                    Order By Id];
        
        //asserts
        for(Integer i = 0; i < expDistList.size(); i++) {
            if(i == 0 || i == 1) {
                System.assertEquals(2, expDistList[i].Paid_Amount__c);
            }
            else {
                System.assertEquals(1, expDistList[i].Paid_Amount__c);
            }
            
            System.assertEquals(edList[i].Id, expDistList[i].Id);
            System.assertNotEquals(null, expDistList[i].Amount__c);
            System.assertEquals(2, expDistList[i].Amount__c);
        }
        
        for(Database.SaveResult sr : srList) {
            System.Assert(sr.isSuccess());
            System.Assert(sr.getErrors().size() == 0);  
        }
        
    }
    
}