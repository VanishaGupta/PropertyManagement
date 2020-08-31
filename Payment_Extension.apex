public class Payment_Extension {
    public Payment2__c thisPayment {get; set;}
    public Statement__c thisStatement {get; set;}
    public Map<Id,String> recordTypeMap {get;set;}
    public boolean success {get;set;}
    
    public Payment_Extension(ApexPages.StandardController scon){
        if(scon.getRecord() instanceOf Statement__c){
            thisStatement = [Select Id, Name, Rental_Agreement__r.Contact__c, balance__c from Statement__c where id = :scon.getId()];
        }
        success=false;
        recordTypeMap = new Map<Id,String>();
        
        //Query for all record types in payment object and we will store it in map
        for(RecordType r:[Select Id,Name from RecordType where sObjectType='Payment2__c']){
            recordTypeMap.put(r.ID, r.Name);
        }
        
        //instantiate payment object
        thisPayment=new Payment2__c();
        if(scon.getRecord() instanceOf Statement__c){
            thisPayment.Statement__c=scon.getId();
            thisPayment.Amount__c=thisStatement.balance__c;
            
        }
        
        if(getIsGuest()){
            for(Id i:recordTypeMap.keySet()){
                if(recordTypeMap.get(i)=='Credit Card'){
                    thisPayment.RecordTypeId=i;
                }
            }
        }
        else if(scon.getRecord() instanceOf Statement__c)
        {
          Contact renter=
              [Select Id,FirstName, LastName,MailingStreet,MailingCity, MailingState,MailingPostalCode 
               from Contact where ID=:thisStatement.Rental_Agreement__r.Contact__c];
            
           thisPayment.Billing_Name__c=renter.FirstName+' '+renter.LastName;
            thisPayment.Billing_Street__c=renter.MailingStreet;
            thisPayment.Billing_City__c=renter.MailingCity;
            thisPayment.Billing_State__C=renter.MailingState;
            thisPayment.Billing_Postal_Code__c=renter.MailingPostalCode;
            
                
        }
    }
    
    //this method will process and save payments or report any errors
    public PageReference savePayment(){
        success=false;
        String paymentType = recordTypeMap.get(thisPayment.RecordTypeId);
        //validations
        if(validateFields(paymentType)){
            //process credit card payments
            if(paymentType == 'Credit Card'){
                //create a request wrapper for authorize.net
                API_authorizeDotNet.authnetreq_wrapper req=new API_authorizeDotNet.authnetreq_wrapper();
                //set the wrapper values
                req.amt = string.valueOf(thisPayment.Amount__c);
                req.firstname=(thisPayment.Billing_Name__c.contains(' '))?thisPayment.Billing_Name__c.subStringBefore(' '):thisPayment.Billing_Name__c;
                req.lastname=(thisPayment.Billing_Name__c.contains(' '))?thisPayment.Billing_Name__c.subStringAfter(' '):thisPayment.Billing_Name__c;
                req.billstreet=thisPayment.Billing_Street__c;
                req.billcity=thisPayment.Billing_city__c;
                req.billstate=thisPayment.Billing_State__c;
                req.billzip=thisPayment.Billing_Postal_Code__c;
                
                //set credit card information on the request wrapper
                req.ccnum=thisPayment.Credit_Card_Number__c;
                req.ccexp=monthmap.get(thisPayment.Credit_Card_Expiration_month__c)+thisPayment.Expiration_Year__c;
                req.ccsec=thisPayment.credit_card_Security_Card__c;
                
                //give request a name
                req.ordername='Payment of '+[Select Id,Name from Statement__c where ID=:thisPayment.Statement__c].Name;
                //process our authorizedotnet request
                API_authorizeDotNet.Authnetresp_wrapper resp = API_authorizeDotNet.authdotnetCharge(req);
                thisPayment.Authorizenet_Transaction_Id__c=resp.transactionID;
                thisPayment.Authorizenet_Authorization_code__c=resp.authorizationCode;
                thisPayment.Authorizenet_Response__c=resp.responseCode+'|'+resp.responseReasonText;
                
                //if transaction fails
                if(resp.responseCode!='1' ){
                    thisPayment.Status__c='Failed';
                    ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.ERROR,'Payment Failed ! '));
                    ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.ERROR,'resp.responseReasonText'));
                                         
                    return null;
                }
                 
				//successful transaction
				thisPayment.Status__c='Paid';
                thisPayment.Payment_Date__c=system.now();
             	upsert thisPayment;
                success=true;
                ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.CONFIRM,'Payment succesful'));
                
                try{
                    //if there is an email
                    if(thisStatement!=null && thisStatement.Rental_Agreement__r.Contact__r.email != null){
                        //construct my message
                        Messaging.SingleEmailMessage msg=new Messaging.SingleEmailMessage();
                        msg.setToAddresses(new List<String> {thisStatement.Rental_Agreement__r.Contact__r.email});
                        msg.setSubject('Payment Confirmation!');
                        msg.setHtmlBody('Your payment of '+thisPayment.Amount__c+ ' has been succesfully processed. <br/><br/> Thankyou!!');
                        msg.setPlainTextBody('Your payment of '+thisPayment.Amount__c+ ' has been succesfully processed.');
                        
                        //send the email
                        Messaging.sendEmail(new List<Messaging.SingleEmailMessage> {msg});
                    }
                } catch(Exception e){
                    
                }
            }
        }
        else {
            
           ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.ERROR,'Please fill out the details ! '));
        }
        return null;
    }
    
    public boolean validateFields (String paymentType){
        boolean valid=true;
		//check common fields
        if(thisPayment.Statement__c==null)
            valid=false;
		if(thisPayment.Amount__c==null)
			valid=false;            
        if(string.isBlank(thisPayment.Billing_Name__c))
            valid = false;
        if(string.isBlank(thisPayment.Billing_Street__c))
            valid=false;
        if(String.isBlank(thisPayment.Billing_City__c))
            valid=false;
        if(String.isBlank(thisPayment.Billing_State__c))
            valid=false;
        if(String.isBlank(thisPayment.Billing_Postal_Code__c))
            valid=false;
        
        //check fields when payment type is check
        if(paymentType=='Check'){
            if(String.isBlank(thisPayment.Check_Account_Number__c))
                valid=false;
            if(String.isBlank(thisPayment.Check_Routing_Number__c))
                valid=false;
        }
        
        if(paymentType=='Credit Card'){
            if(String.isBlank(thisPayment.Credit_Card_Number__c))
                valid=false;
            if(String.isBlank(thisPayment.Credit_Card_Security_Card__c))
                valid=false;
            if(String.isBlank(thisPayment.Credit_Card_Expiration_month__c))
                valid=false;
        }
        
        return valid;
    }
    
    public boolean getIsGuest(){
        return [select Id,UserType from Profile where ID = :userInfo.getProfileId()].userType=='Guest';
    }
    
    public static Map<String,String> monthmap = new Map<String,String>{
        		'January'=>'01', 'February'=>'02','March'=>'03',
                'April' => '04', 'May' => '05','June' => '06',
                'July' => '07','August' => '08','September'=>'09',
                'October'=>'10','November'=>'11','December'=>'12'
    };
        
    public List<SelectOption> getPaymentRecordTypes(){
        List<SelectOption> temp=new List<SelectOption>();
        temp.add(new SelectOption('','Select Payment Method'));
        
        for(ID i:recordTypeMap.keySet()){
            temp.add(new Selectoption(i,recordTypeMap.get(i)));
        }
        return temp;
    }
    
    public List<SelectOption> getexpirationYears(){
        List<SelectOption> temp=new List<SelectOption>();
        for(Integer i=0;i<5;i++){
            String y=''+System.today().addYears(i).year();
            temp.add(new SelectOption(y,y));
        }
        return temp;
    }
}