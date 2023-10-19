@isTest
public class ExpenseTriggerTest {

    //CRIAÇÃO DE DADOS (A DB ESTÁ VAZIA ANTES DISTO)
    @TestSetup
    public static void setup() {
        //Criar Trip
        Trip__c t = new Trip__c(Name = 'T1', Total_Participants__c = 200);
        insert t;
        
        //Criar 2 Expenses
        List<Expense__c> expList = new List<Expense__c>();
        for(Integer i = 0; i < 2; i++) {
            Integer cost = 15000;
            if(i == 1) {
                cost = 25000;
            }
            Expense__c exp = new Expense__c(Name = 'Exp' + String.valueOf(i), Trip__c = t.Id, Cost__c = cost);
            expList.add(exp);
        }
        insert expList;
        
        //Criar 4 Employees
        List<Employee__c> eList = new List<Employee__c>();
        for(Integer i = 0; i < 200; i++) {
            Employee__c e = new Employee__c(Name = 'E' + String.valueOf(i), ID_number__c = String.valueOf(i), Id_Type__c = 'A',
                                            Email__c = 'emailE' + String.valueOf(i) + '@xx.com');
            eList.add(e);
        }
        insert eList;
        
        //Criar 2 EDs por Expense (4 Total)
        Id expId = expList[0].Id;
        List<Expense_Distribution__c> edList = new List<Expense_Distribution__c>();
        for(Integer i = 0; i < 200; i++) {
            
            if(i > 99) {
                expId = expList[1].Id;
            }
            
            Expense_Distribution__c ed = new Expense_Distribution__c(Name = 'ED' + String.valueOf(i),
                                                                     Expense__c = expId, Employee__c = eList[i].Id, Paid_Amount__c = 85);
            edList.add(ed);
        }
        //NOTA: AO FAZER ESTE INSERT, DÁ TRIGGER AO calculateAmount DO EDTRIGGERHANDLER, LOGO A PAID_AMOUNT, TENDO EM CONTA OS VALORES DA AMOUNT, VAI SER ALTERADA
        //E A AMOUNT VAI SER DEFINIDA LOGO AQUI
        insert edList;
    }
    
    @isTest
    public static void testUpdateEDAmount() {
        Trip__c t = new Trip__c(Name = 'T2', Total_Participants__c = 6);
        insert t;
        
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
        exp.Cost__c = 300;        
        

        Test.startTest();
        Database.SaveResult sr = Database.update(exp, true);
        Test.stopTest();
        
        Trip__c tAfter = [SELECT Id, Name, Total_Participants__c FROM Trip__c WHERE Name = 'T2'];
        Expense__c expAfter = [SELECT Id, Name, Trip__c FROM Expense__c WHERE Trip__c = :tAfter.Id];
        Expense_Distribution__c edAfter = [SELECT Id, Name, Expense__c, Expense__r.Trip__c, Amount__c, Paid_Amount__c FROM Expense_Distribution__c
                                                    WHERE Expense__c = :expAfter.Id];
        
        //Após o update do Total_Participants__c da Trip verifica se a ED correspondente a esta Trip têm a Amount e a Paid Amount alteradas
        System.assertNotEquals(null, edAfter.Amount__c);            
        //PaidAmount é maior que Amount logo foi alterada
        System.assertEquals(50, edAfter.Amount__c);
        System.assertEquals(50, edAfter.Paid_Amount__c);
        System.assertEquals(edAfter.Amount__c, edAfter.Paid_Amount__c);
        
        System.Assert(sr.isSuccess());
        System.Assert(sr.getErrors().size() == 0);  
        
    }
    
    //testa se as amounts das EDs foram alteradas conforme a alteração do Cost das Expenses correspondentes (são sempre)
    //Verifica ainda se as Paid Amounts foram alteradas conforme deveriam (ou não)
    @isTest
    public static void testUpdateEDAmountBulk() {
        
        //Query às Expenses existentes na DB (criadas no setup)
        List<Expense__c> expList = [SELECT Id, Name, Cost__c FROM Expense__c];

        //Altera o Cost de cada Expense
        for(Expense__c exp : expList) {
            exp.Cost__c -= 5000;
        }
        
        Test.startTest();
        Database.SaveResult[] srList = Database.update(expList, true);
        Test.stopTest();
        
        //Query aos objetos pós update
        List<Expense__c> expUPDTList = [SELECT Id, Name, Cost__c FROM Expense__c];
        List<Expense_Distribution__c> edUPDTList = [SELECT Id, Name, Expense__c, Expense__r.Cost__c, Amount__c, Paid_Amount__c FROM Expense_Distribution__c 
                                                    WHERE Expense__c In :expUPDTList Order By Id];

        
        //Após o update do Cost__c da Expense verifica se as EDs correspondentes a estas Expenses têm a Amount e a Paid Amount alteradas
        for(Integer i = 0; i < expUPDTList.size(); i++) {
            System.assertNotEquals(null, edUPDTList[i].Amount__c);
            if(i < 100) {	//PaidAmount é maior que Amount logo foi alterada
            	System.assertEquals(50, edUPDTList[i].Amount__c);
            	System.assertEquals(50, edUPDTList[i].Paid_Amount__c);
            	System.assertEquals(edUPDTList[i].Amount__c, edUPDTList[i].Paid_Amount__c);
            } else {	//PaidAmount é igual a Amount logo não foi alterada
            	System.assertEquals(100, edUPDTList[i].Amount__c);
            	System.assertEquals(85, edUPDTList[i].Paid_Amount__c);
            	System.assertNotEquals(edUPDTList[i].Amount__c, edUPDTList[i].Paid_Amount__c);
            }
        }
        
        for(Database.SaveResult sr : srList) {
            System.Assert(sr.isSuccess());
            System.Assert(sr.getErrors().size() == 0);  
        }
        
    }
}