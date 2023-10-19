public with sharing class Fields {
    @AuraEnabled
    public string name{ get; set; }
    @AuraEnabled
    public string expenseName{ get; set; }
    @AuraEnabled
    public string employeeName{ get; set; }
    @AuraEnabled
    public Decimal paidAmount{ get; set; }
    @AuraEnabled
    public Decimal amount{ get; set; }
}