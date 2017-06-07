/**
 * Created by jschultz on 6/6/17.
 */

@IsTest
private class DailyAddressUpdaterBatchTest {
	static Contact testContact1;
	static Seasonal_Address__c testAddress;
	
	static {
		testContact1 = new Contact(
			LastName = 'contact1'
		);
		insert testContact1;
		
		testAddress = new Seasonal_Address__c(
			Contact__c = testContact1.Id
			, Start_Day__c = 1
			, Start_Month__c = 'June'
			, Start_Month_Number__c = 6
			, End_Day__c = 1
			, End_Month__c = 'August'
			, End_Month_Number__c = 8
			, Current_Address__c = false
			, Invalid__c = false
			, Street__c = '1street'
			, City__c = '1town'
			, State__c = '1NJ'
			, Country__c = '1USA'
			, Postal_Code__c = '11111'
			);
		
		SeasonalAddressService.disableAddressUpdateTrigger = true;
		
		insert testAddress;
		
	}
	
	static testMethod void testBatch() {
		Test.startTest();
		
		DailyAddressUpdaterBatch batch = new DailyAddressUpdaterBatch();
		Database.executeBatch(batch);
		
		Test.stopTest();
		
		Contact con = [SELECT MailingStreet, MailingCity, MailingState, MailingPostalCode, MailingCountry FROM Contact WHERE Id = :testContact1.Id];
		System.assertEquals(testAddress.Street__c, con.MailingStreet);
		System.assertEquals(testAddress.City__c, con.MailingCity);
		System.assertEquals(testAddress.State__c, con.MailingState);
		System.assertEquals(testAddress.Postal_Code__c, con.MailingPostalCode);
		System.assertEquals(testAddress.Country__c, con.MailingCountry);
	}
}