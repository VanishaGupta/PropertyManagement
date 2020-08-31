public class API_authorizeDotNet {
	public static String APILOGIN;
    public static String APITRANSKEY;
    
    public static void getAuthNetCreds(){

        Autherize_Net_Settings__c apiLoginSettings=Autherize_Net_Settings__c.getInstance('API Login ID');
        Autherize_Net_Settings__c apitranskeysetting=Autherize_Net_Settings__c.getInstance('TransKey');
        
         system.debug('apiLoginSettings '+ apiLoginSettings);
         system.debug('apiTransKey '+apitranskeysetting);
        
        APILOGIN=apiLoginSettings.Value__c;
        APITRANSKEY=apitranskeysetting.Value__c;
        
        system.debug('APILOGIN '+APILOGIN);
        system.debug('APITransKey '+APITransKey);
       
    }
    
    public static authnetresp_wrapper authdotnetCharge(authnetreq_wrapper input){
        getAuthNetCreds();
        //construct our request
        HTTPRequest req=new HTTPRequest();
        req.setEndpoint('https://test.authorize.net/gateway/transact.dll');
        req.setMethod('POST');
        //build message 
        Map<String,String> messageString=new Map<String,String>();
        messageString.put('x_login', APILOGIN);
        messageString.put('x_tran_key', APITransKey);
        messageString.put('x_version','3.1');
        messageString.put('x_delim_data', 'TRUE');
        messageString.put('x_delim_char', ';');
        messageString.put('x_relay_response', 'FALSE');
        messageString.put('x_type','AUTH_CAPTURE');
        messageString.put('x_method', 'CC');
        
        //transaction specific info
        messageString.put('x_card_num', input.ccnum);
        messageString.put('x_exp_date', input.ccexp);
        messageString.put('x_card_code', input.ccsec);
        
        //transaction amount
        messageString.put('x_amount',input.amt);
        
        //description
        messageString.put('x_description','Your transaction '+input.ordername);
        
        //billinginfo
        messageString.put('x_first_name', input.firstname);
        messageString.put('x_last_name', input.lastname);
        messageString.put('x_address', input.billstreet);
        messageString.put('x_city', input.billcity);
        messageString.put('x_state', input.billstate);
        messageString.put('x_zip', input.billzip);
        
        //encode the message component
        String encodedMsg='';
        
        for(String s:messageString.keySet()){
            String v=messageString.get(s);
            //fix null values
            if(string.isBlank(v)){
                v='';
            }
            else {
                encodedMsg+=s+'='+EncodingUtil.urlEncode(v, 'UTF-8')+'&';
            }
        }
        
        //add message termination
        encodedMsg+='endofdata';
        system.debug('Encoded message '+encodedMsg);
        req.setBody(encodedMsg);
        
        
       //send and collect the response 
       HTTP http=new HTTP();
       String resp=http.send(req).getbody(); //response from payment gateway
        System.debug('Response from Authorize.Net '+resp);
        
        //split response by delimeter
        List<String> responses=resp.split(';');
        Authnetresp_wrapper parsedResponse=parseIntoResponseWrapper(responses);
        
        return parsedResponse;
        
    }
    
    public static Authnetresp_wrapper parseIntoResponseWrapper(List<String> input){
        Authnetresp_wrapper temp = new Authnetresp_wrapper();
        temp.responseCode = input[0];
    temp.ResponseSubcode = input[1];
    temp.ResponseReasonCode =input[2];
    temp.ResponseReasonText=input[3];
    temp.AuthorizationCode=input[4];
    temp.AVSResponse= input[5];
    temp.TransactionID=input[6];
    temp.InvoiceNumber= input[7];
    temp.Description= input[8];
    temp.Amount= input[9];
    temp.Method= input[10];
    temp.TransactionType= input[11];
    temp.CustomerID= input[12];
    temp.FirstName= input[13];
    temp.LastName= input[14];
    temp.Company= input[15];
    temp.Address= input[16];
    temp.City= input[17];
    temp.State= input[18];
    temp.ZIPCode= input[19];
    temp.Country= input[20];
    temp.Phone= input[21];
    temp.Fax= input[22];
    temp.EmailAddress= input[23];
    temp.ShipToFirstName= input[24];
    temp.ShipToLastName= input[25];
    temp.ShipToCompany= input[26];
    temp.ShipToAddress= input[27];
    temp.ShipToCity= input[28];
    temp.ShipToState= input[29];
    temp.ShipToZIPCode= input[30];
    temp.ShipToCountry= input[31];
    temp.Tax= input[32];
    temp.Duty= input[33];
    temp.Freight= input[34];
    temp.TaxExempt= input[35];
    temp.PurchaseOrderNumber= input[36];
    temp.MD5Hash= input[37];
    temp.CardCodeResponse= input[38];
    temp.CardholderAuthenticationVerificationResponse= input[39];
    temp.AccountNumber= input[40];
    temp.CardType= input[41];
    temp.SplitTenderID= input[42];
    temp.RequestedAmount= input[43];
    temp.BalanceOnCard= input[44];
    return temp;
    }
    
    public class authnetreq_wrapper{
        public string ordername{get;set;}
        public string ccnum{get;set;}
        public string ccexp{get;set;}
        public string ccsec{get;set;}
        public string amt{get;set;}
        public string firstname{get;set;}
        public string lastname{get;set;}
        public string billstreet{get;set;}
        public string billcity{get;set;}
        public string billstate{get;set;}
        public string billzip{get;set;}
		public string transid{get;set;}
        public string routingnumber{get;set;}
        public string accountnumber{get;set;}
        public string bankaccounttype{get;set;}
        public string bankname{get;set;}
        public string bankaccountname{get;set;}
     	
            public authnetreq_wrapper(){
            
        }
    }
    
    public class Authnetresp_wrapper
    {
        public String responseCode {get;set;}
        public String responseSubCode {get;set;}
        public String responseReasonCode {get;set;}
        public String responseReasonText {get;set;}
        public String authorizationCode {get;set;}
        public String AVSResponse {get;set;}
        public String transactionID {get;set;}
        public String invoiceNumber {get;set;}
        public String description {get;set;}
        public String amount {get;set;}
        public String method {get;set;}
        public String transactionType {get;set;}
        public String customerID {get;set;}
        public String firstname {get;set;}
        public String lastname {get;set;}
        public String company {get;set;}
        public String address {get;set;}
        public String city {get;set;}
        public String state {get;set;}
        public String ZIPcode {get;set;}
        public String country {get;set;}
        public String phone{get;set;}
		public String fax{get;set;}
        public String emailAddress{get;set;}
        public String shipToFirstName {get;set;}
        public String shipToLastName {get;set;}
        public String ShipToCompany {get;set;}
        public String shipToAddress {get;set;}
        public String ShipToCity {get;set;}
        public String shipToState {get;set;}
        public String shipToZipCode {get;set;}
        public String shipToCountry {get;set;}
        public String tax {get;set;}
        public String duty {get;set;}
        public String freight {get;set;}
        public String taxExempt {get;set;}
        public String purchaseOrderNumber {get;set;}
        public String MD5Hash {get;set;}
        public String cardCodeResponse {get;set;}
        public String cardHolderAuthenticationVerificationResponse {get;set;}
        public String accountNumber {get;set;}
        public String cardType {get;set;}
        public String splitTenderID {get;set;}
        public String requestedAmount {get;set;}
        public String balanceOnCard {get;set;}
 		        
        public Authnetresp_wrapper(){
            
        }
    
}
}