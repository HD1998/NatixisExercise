public class BatchJob implements Database.Batchable<sObject> {
    
    public static Boolean emailSent = false;
    
	public Database.QueryLocator start(Database.BatchableContext bc) {
        // collect the batches of records or objects to be passed to execute
        System.debug('Start');
        return Database.getQueryLocator('SELECT ID, Name, Email__c FROM Employee__c ');
    }
    
    //envia email para cada email em batch
    public void execute(Database.BatchableContext bc, List<Employee__c> empList){
        System.debug('EXECUTE');	
        
        //Retira as Expenses e EDs dos Employees
        List<Expense__c> expList = [SELECT Id, Name, Status__c, Description__c, Total_Paid_Amount__c, Total_Unpaid_Employees__c, Cost__c, Responsible__c, Responsible__r.Email__c,
                                    (SELECT Id, Name, Employee__c, Employee__r.Name, Paid_Amount__c, Amount__c FROM Expenses_Distribution__r)
                                    FROM Expense__c WHERE Responsible__c In :empList];
        
        //Se não existirem expenses para estes employees retorna
        if(expList == null || expList.size() == 0) {
            return;
        }
        
        Map<String, List<Expense__c>> expMap = new Map<String, List<Expense__c>>();
        
        //preenche o mapa com Email, Lista de Expenses e EDs desse Employee
        for(Expense__c exp : expList) {
            if(!expMap.containsKey(exp.Responsible__r.Email__c)) {
                expMap.put(exp.Responsible__r.Email__c, new List<Expense__c> {exp});
            } else {
                expMap.get(exp.Responsible__r.Email__c).add(exp);
            }
        }
        
        
        //fazer try catch
        
        //if(!Test.isRunningTest()) {
            List<String> emailsList = new List<String>();
		
            for(Employee__c e : empList) {
                emailsList.add(e.Email__c);
            }
            
            List<Messaging.SingleEmailMessage> mailList = new List<Messaging.SingleEmailMessage>();
            for(String emailAddress : emailsList) {
                
                //se o email atual não tiver expenses a mostrar passa ao seguinte
                if(expMap.get(emailAddress) == null || expMap.get(emailAddress).size() == 0) {
                    continue;
                }
                
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                
                mail.setToAddresses(new List<String> {emailAddress});                                        
                mail.setSubject('Email diário de records');
                
                String htmlBody = '<html>' + 
                    '<head>' +
                        '<style>' +
                            'th {border-top: 1px solid #dddddd; border-right: 1px solid #dddddd;}' + 
                            'tbody, td {border-top: 1px solid #dddddd; border-right: 1px solid #dddddd;' +
                                'border-bottom: 1px solid #dddddd;}' +
                            'tbody, tr, th, td {border-left: 1px solid #dddddd; }' +    
                        '</style>' +
                    '</head>' +
                    '<body>';
                
                //Mostra os dados, por Employee, da Expense e EDs, como na página da Trip
                for(Expense__c exp : expMap.get(emailAddress)) {
                    htmlBody += '<h1>' + exp.Name + '</h1>';
                    htmlBody += '<p>Description: ' + exp.Description__c + '</p>';
                    htmlBody += '<p>Status: ' + exp.Status__c + '</p>';
                    htmlBody += '<p>Total Paid Amount: ' + exp.Total_Paid_Amount__c + '</p>';
                    htmlBody += '<p>Total Unpaid Employees: ' + exp.Total_Unpaid_Employees__c + '</p>';
                    htmlBody += '<p>Cost: ' + exp.Cost__c + '</p>';
                    htmlBody += '<table cellspacing="0", width="100%"><thead><tr><th>Name</th><th>Employee</th><th>Paid Amount</th><th>Amount</th></tr></thead><tbody>';
                    
                    for(Expense_Distribution__c ed : exp.Expenses_Distribution__r) {
                        htmlBody += '<tr>';
                        htmlBody += '<td>' + ed.Name + '</td>';
                        htmlBody += '<td>' + ed.Employee__r.Name + '</td>';
                        htmlBody += '<td>' + ed.Paid_Amount__c + '</td>';
                        htmlBody += '<td>' + ed.Amount__c + '</td>';
                        htmlBody += '</tr>';
                    }
                    htmlBody += '</tbody></table>';
                }
                
                htmlBody += '</tbody></html>';
                
                System.debug(htmlBody);
                
                mail.setHtmlBody(htmlBody);
                
                mailList.add(mail);
            }
           
            Map<String,System.OrgLimit> limitsMap = OrgLimits.getMap();
            System.OrgLimit emailLimit = limitsMap.get('SingleEmail');
        
            if(!Test.isRunningTest()) {
                //se a quantidade de emails a enviar for maior que a quantidade que ainda posso enviar hoje
                if(mailList.size() > emailLimit.getLimit()  - emailLimit.getValue()) {
                    return;
                }
        
			
            	Messaging.sendEmail(mailList);
            } else {
                emailSent = true;
            }
        //}	
        //System.debug('Count: ' + count);
        System.debug('EndExecute');
        
    }
    
    public void finish(Database.BatchableContext bc){
        // execute any post-processing operations
        System.debug('FINISH');
        AsyncApexJob job = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email FROM AsyncApexJob
                           WHERE Id = :bc.getJobId()];
        System.debug('BatchJob: ' + job);
        //System.debug('RC: ' + count);
        System.debug('NAO ESTOUROU');
    }
}