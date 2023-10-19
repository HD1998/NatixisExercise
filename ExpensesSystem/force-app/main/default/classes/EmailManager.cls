public class EmailManager {
    // Public method
    public static Boolean sendMail(String address, String subject, String body, String jsonStr) {
        // Create an email message object
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        String[] toAddresses = new String[] {address};
        mail.setToAddresses(toAddresses);
        mail.setSubject(subject);
        mail.setPlainTextBody(body);
        
        Boolean sendResult = true;
        // Pass this email message to the built-in sendEmail method 
        // of the Messaging class
         
        if(!Test.isRunningTest()) {
            try{
            Messaging.SendEmailResult[] results = Messaging.sendEmail(
                                 new Messaging.SingleEmailMessage[] { mail });
            for (Messaging.SendEmailResult res : results) {
                if (res.isSuccess()) {
                    System.debug('Email sent successfully');
                }
            }
        	
            } catch (Exception ex) {
                sendResult = false;
                System.debug('The following errors occurred: ' + ex.getMessage());             
            }
            
            return sendResult;
        } else {
            Messaging.SendEmailResult result = (Messaging.SendEmailResult) Json.deserialize(jsonStr, Messaging.SendEmailResult.class);
            System.debug('Res: ' + result.isSuccess());
            //try {
                if (result.isSuccess()) {
                    System.debug('Email sent successfully');
                } else {
                    sendResult = false;
                	System.debug('The following errors occurred: ' + result.getErrors());      
                }
            /*} catch (Exception ex) {
                sendResult = false;
                System.debug('The following errors occurred: ' + ex.getMessage());             
            }*/
            
            return sendResult;
        }
        
    }
}