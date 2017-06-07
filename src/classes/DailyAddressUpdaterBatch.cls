/**
* @author: John Schultz
* @date: 2017-06-05
* @description: Batch for updating contact's address to match in-season address.
* @log:
* ----------------------------------------------------------------------------
* Developer       Date          Description
* ----------------------------------------------------------------------------
* John Schultz    2017-06-05    Newly created
*/
global class DailyAddressUpdaterBatch implements Database.Batchable<SObject> {
	
	global Database.QueryLocator start(Database.BatchableContext bc) {
		Integer day = Date.today().day();
		Integer month = Date.today().month();
		
		String q = '';
		q += 'SELECT Id ';
		q += '  , Street__c ';
		q += '  , City__c ';
		q += '  , State__c ';
		q += '  , Postal_Code__c ';
		q += '  , Country__c ';
		q += '  , Current_Address__c ';
		q += '  , Start_Month__c ';
		q += '  , Start_Month_Number__c ';
		q += '  , Start_Day__c ';
		q += '  , End_Month__c ';
		q += '  , End_Month_Number__c ';
		q += '  , End_Day__c ';
		q += '  , Contact__c ';
		q += '  , End_Before_Start__c ';
		q += ' FROM Seasonal_Address__c ';
		q += ' WHERE Invalid__c = false ';
		q += ' AND Current_Address__c = false ';
		q += ' AND Contact__r.Address_Overriden__c = false ';
		
		q += '  AND ( ';
		// end comes before start. reversed dates that cross new year threshold.
		q += '      ( ';
		q += '          End_Before_Start__c = TRUE ';
		q += '          AND ';
		q += '          ( ';
		q += '              ( ';
		q += '                  Start_Month_Number__c > ' + month;
		q += '                  OR ( ';
		q += '                      Start_Month_Number__c = ' + month;
		q += '                      AND Start_Day__c <= ' + day;
		q += '                  ) ';
		q += '              ) ';
		q += '              AND ';
		q += '              ( ';
		q += '                  End_Month_Number__c > ' + month;
		q += '                  OR ( ';
		q += '                      End_Month_Number__c = ' + month;
		q += '                      AND End_Day__c >= ' + day;
		q += '                  ) ';
		q += '              ) ';
		q += '          ) ';
		q += '      ) ';
		q += '      OR ';
		// start comes before end. normal date order.
		q += '      ( ';
		q += '          End_Before_Start__c = FALSE ';
		q += '          AND ';
		q += '          ( ';
		q += '              ( ';
		q += '                  Start_Month_Number__c < ' + month;
		q += '                  OR ( ';
		q += '                      Start_Month_Number__c = ' + month;
		q += '                      AND Start_Day__c <= ' + day;
		q += '                  ) ';
		q += '              ) ';
		q += '              AND ';
		q += '              ( ';
		q += '                  End_Month_Number__c > ' + month;
		q += '                  OR ( ';
		q += '                      End_Month_Number__c = ' + month;
		q += '                      AND End_Day__c >= ' + day;
		q += '                  ) ';
		q += '              ) ';
		q += '          ) ';
		q += '      ) ';
		q += ' ) ';
		
		
		return Database.getQueryLocator(q);
	}
	
	global void execute(Database.BatchableContext bc, List<Seasonal_Address__c> addresses) {
		// disable trigger since we're updating the addresses manually
		SeasonalAddressService.disableAddressUpdateTrigger = true;

		Map<Id, Contact> contacts = SeasonalAddressService.getRelatedContacts(addresses);

		for (Seasonal_Address__c sa : addresses) {
			Contact con = contacts.get(sa.Contact__c);

			// set address to current address
			sa.Current_Address__c = true;
			SeasonalAddressService.existingAddressesToUpdate.add(sa);

			// call method to update related records
			SeasonalAddressService.updateContactAndOtherAddresses(sa, con);
		}

		// commit changes
		SeasonalAddressService.saveUpdatedContactsAndAddresses();
	}
	
	global void finish(Database.BatchableContext bc) {}
}