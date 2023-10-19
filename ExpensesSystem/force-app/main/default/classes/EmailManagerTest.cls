@isTest
public class EmailManagerTest {
    
    @isTest
    public static void testSendEmailSuccess() {
        
        //String[] address = new String[] {'hugodaniel.ferreira@natixis.com'} ;
        String address = 'hugodaniel.ferreira@natixis.com';
        String subject = 'IT WORKS';
        String body = 'Lets goo';
        
        Test.startTest();
        Boolean res = EmailManager.sendMail(address, subject, body, '{"success": "true" }');
        Test.stopTest();
        
        System.assertEquals(true, res);
        
    }
    
    @isTest
    public static void testSendEmailSuccessBULK() {
        
        //String[] address = new String[] {'hugodaniel.ferreira@natixis.com' , 'alexandre.esteves@natixis.com'};
        String address = 'hugodaniel.ferreira@natixis.com';
        String subject = 'IT WORKS';
        String body = 'Lets goo';
        
        List<Boolean> res = new List<Boolean>();
        
        Test.startTest();
        for(Integer i = 0; i < 200; i++) {
            res.add(EmailManager.sendMail(address, subject, body, '{"success": "true" }'));
        }        
        Test.stopTest();
        
        for(Integer i = 0; i < 200; i++) {
            System.assertEquals(true, res[i]);
        }  
        
    }
    
    @isTest
    public static void testSendEmailFail() {
        
        String address = null;
        String subject = null;
        String body = 'fdsfds';
        
        Test.startTest();
        Boolean res = EmailManager.sendMail(address, subject, body, '{"success": "false" }');
        Test.stopTest();
        
        System.assertEquals(false, res);
        
    }
    
    @isTest
    public static void testSendEmailFailBULK() {
        
        String address = null;
        String subject = null;
        String body = 'fdsfds';
        
        List<Boolean> res = new List<Boolean>();
        
        Test.startTest();
        for(Integer i = 0; i < 200; i++) {
            res.add(EmailManager.sendMail(address, subject, body, '{"success": "false" }'));
        }        
        Test.stopTest();
        
        for(Integer i = 0; i < 200; i++) {
            System.assertEquals(false, res[i]);
        }  
        
    }
}