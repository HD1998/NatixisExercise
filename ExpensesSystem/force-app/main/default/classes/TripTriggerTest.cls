@isTest
public class TripTriggerTest {
	
    //CRIAÇÃO DE DADOS (A DB ESTÁ VAZIA ANTES DISTO)
    @TestSetup
    public static void setup() {
        //Criar 2 Trips
        List<Trip__c> tList = new List<Trip__c>();
        for(Integer i = 1; i < 4; i++) {
            Integer totPart = 300;
            if (i == 2) {
                totPart = 700;
            } else if (i == 3) {
                totPart = 5;
            }
            Trip__c t = new Trip__c(Name = 'T' + String.valueOf(i), Total_Participants__c = totPart);
            tList.add(t);
        }
        insert tList;
        
        //Criar 2 Expenses por Trip
        Id tId = tList[0].Id;
        List<Expense__c> expList = new List<Expense__c>();
        for(Integer i = 0; i < 4; i++) {
            if(i > 1) {
                tId = tList[1].Id;
            }
            Expense__c exp = new Expense__c(Name = 'Exp' + String.valueOf(i), Trip__c = tId, Cost__c = 10000);
            expList.add(exp);
        }
        insert expList;
        
        //Criar 8 Employees
        List<Employee__c> eList = new List<Employee__c>();
        for(Integer i = 0; i < 200; i++) {
            Employee__c e = new Employee__c(Name = 'E' + String.valueOf(i), ID_number__c = String.valueOf(i), Id_Type__c = 'A',
                                            Email__c = 'emailE' + String.valueOf(i) + '@xx.com');
            eList.add(e);
        }
        insert eList;
        
        //Criar 2 EDs por Expense
        Id expId = expList[0].Id;
        List<Expense_Distribution__c> edList = new List<Expense_Distribution__c>();
        for(Integer i = 0; i < 200; i++) {
            if( i >= 50 && i < 100) {
                expId = expList[1].Id;
            } else if( i >= 100 && i < 150) {
                expId = expList[2].Id;
            } else if( i >= 150 && i < 200) {
                expId = expList[3].Id;
            }
            
            Expense_Distribution__c ed = new Expense_Distribution__c(Name = 'ED' + String.valueOf(i), Expense__c = expId, Employee__c = eList[i].Id, Paid_Amount__c = 20);
            edList.add(ed);
        }
        insert edList;
    }
    
    @isTest
    public static void testUpdateEDAmount() {
        Trip__c t = [SELECT Id, Name, Total_Participants__c FROM Trip__c WHERE Name = 'T3'];
        
        //Criar Employee
        Employee__c e = New Employee__c(Name = 'E500', ID_number__c = '500', Id_Type__c = 'A',
                                            Email__c = 'emailE500@xx.com');
        insert e;
        
        //Criar Expense com esta trip
        Expense__c exp = new Expense__c(Name = 'Exp3', Trip__c = t.Id, Cost__c = 600);
        insert exp;
        //Criar ED com esta expense
        Expense_Distribution__c ed = new Expense_Distribution__c(Name = 'ED500' , Expense__c = exp.Id, Employee__c = e.Id, Paid_Amount__c = 120);
        insert ed;
        
        //alterar participantes da trip
        t.Total_Participants__c = 6;        
        

        Test.startTest();
        Database.SaveResult sr = Database.update(t, true);
        Test.stopTest();
        
        Trip__c tAfter = [SELECT Id, Name, Total_Participants__c FROM Trip__c WHERE Name = 'T3'];
        Expense__c expAfter = [SELECT Id, Name, Trip__c FROM Expense__c WHERE Trip__c = :tAfter.Id];
        Expense_Distribution__c edAfter = [SELECT Id, Name, Expense__c, Expense__r.Trip__c, Amount__c, Paid_Amount__c FROM Expense_Distribution__c
                                                    WHERE Expense__c = :expAfter.Id];
        
        //Após o update do Total_Participants__c da Trip verifica se a ED correspondente a esta Trip têm a Amount e a Paid Amount alteradas
        System.assertNotEquals(null, edAfter.Amount__c);            
        //PaidAmount é maior que Amount logo foi alterada
        System.assertEquals(100, edAfter.Amount__c);
        System.assertEquals(100, edAfter.Paid_Amount__c);
        System.assertEquals(edAfter.Amount__c, edAfter.Paid_Amount__c);
        
        System.Assert(sr.isSuccess());
        System.Assert(sr.getErrors().size() == 0);  
        
    }
    
    //testa se as amounts das EDs foram alteradas conforme a alteração do TotalParticipants das Trips correspondentes (são sempre)
    //Verifica ainda se as Paid Amounts foram alteradas conforme deveriam (ou não)
    @isTest	
    public static void testUpdateEDAmountBulk() {
        
        //Query às Trips existentes na DB (criadas no setup)
        List<Trip__c> tList = [SELECT Id, Name, Total_Participants__c FROM Trip__c WHERE Name = 'T1' OR Name = 'T2'];
 
        //Altera o TotalParticipants de cada trip
        for(Trip__c t : tList) {
            t.Total_Participants__c += 100;
        }
        
        Test.startTest();
        Database.SaveResult[] srList = Database.update(tList, true);
        Test.stopTest();
        
        //Query aos objetos pós update
        List<Trip__c> tUPDTList = [SELECT Id, Name, Total_Participants__c FROM Trip__c WHERE Name = 'T1' OR Name = 'T2'];
        List<Expense__c> expUPDTList = [SELECT Id, Name, Trip__c FROM Expense__c WHERE Trip__c In :tUPDTList];
        List<Expense_Distribution__c> edUPDTList = [SELECT Id, Name, Expense__c, Expense__r.Trip__c, Amount__c, Paid_Amount__c FROM Expense_Distribution__c
                                                    WHERE Expense__c In :expUPDTList Order By Id];
        
        //Após o update do Total_Participants__c da Trip verifica se as EDs correspondentes a estas Trips têm a Amount e a Paid Amount alteradas
        for(Integer i = 0; i < edUPDTList.size(); i++) {
            System.assertNotEquals(null, edUPDTList[i].Amount__c);
            if(i < 100) {	//PaidAmount é menor que Amount logo não foi alterada
            	System.assertEquals(25, edUPDTList[i].Amount__c);
            	System.assertEquals(20, edUPDTList[i].Paid_Amount__c);
            	System.assertNotEquals(edUPDTList[i].Amount__c, edUPDTList[i].Paid_Amount__c);
            } else {	//PaidAmount é maior que Amount logo foi alterada
            	System.assertEquals(12.5, edUPDTList[i].Amount__c);
            	System.assertEquals(12.5, edUPDTList[i].Paid_Amount__c);
            	System.assertEquals(edUPDTList[i].Amount__c, edUPDTList[i].Paid_Amount__c);
            }
        }
        
        for(Database.SaveResult sr : srList) {
            System.Assert(sr.isSuccess());
            System.Assert(sr.getErrors().size() == 0);  
        }
    }
}