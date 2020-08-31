trigger Statement_Trigger on Statement__c (after insert,after update) {
    if(Trigger.isAfter && Trigger.isInsert || Trigger.isUpdate ){
        Rollup_Methods.rollupStatementsToRentalAgreement(trigger.new);
    }
}