trigger Payment_Trigger on Payment2__c (after insert, after update) {
	if(Trigger.isAfter && Trigger.isInsert || Trigger.isUpdate ){
        Rollup_Methods.rollupPaymentsToRentalAgreement(trigger.newMap);
    }
}