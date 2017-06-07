/**
 * Created by jschultz on 6/6/17.
 */

@IsTest
private class SeasonalAddressServiceTest {
	
	static Contact testContact1;
	static List<Seasonal_Address__c> testAddresses;
	
	static {
		testContact1 = new Contact(
			LastName = 'contact1'
		);
		insert testContact1;
		
		testAddresses = new List<Seasonal_Address__c>{
			new Seasonal_Address__c(
				Contact__c = testContact1.Id
				, Start_Day__c = 1
				, Start_Month__c = 'June'
				, End_Day__c = 1
				, End_Month__c = 'August'
				, Current_Address__c = false
				, Invalid__c = false
				, Street__c = '1street'
				, City__c = '1town'
				, State__c = '1NJ'
				, Country__c = '1USA'
				, Postal_Code__c = '11111'
			),
			new Seasonal_Address__c(
				Contact__c = testContact1.Id
				, Start_Day__c = 1
				, Start_Month__c = 'September'
				, End_Day__c = 1
				, End_Month__c = 'October'
				, Current_Address__c = false
				, Invalid__c = false
				, Street__c = '2street'
				, City__c = '2town'
				, State__c = '2NJ'
				, Country__c = '2USA'
				, Postal_Code__c = '22222'
			)
		};
		
	}
	
	static testMethod void testTrigger() {
		Contact con = [SELECT MailingStreet, MailingCity, MailingState, MailingPostalCode, MailingCountry FROM Contact WHERE Id = :testContact1.Id];
		System.assertEquals(null, con.MailingStreet);
		System.assertEquals(null, con.MailingCity);
		System.assertEquals(null, con.MailingState);
		System.assertEquals(null, con.MailingPostalCode);
		System.assertEquals(null, con.MailingCountry);
		
		Test.startTest();
		
		insert testAddresses;
		
		con = [SELECT MailingStreet, MailingCity, MailingState, MailingPostalCode, MailingCountry FROM Contact WHERE Id = :testContact1.Id];
		System.assertEquals(testAddresses[0].Street__c, con.MailingStreet);
		System.assertEquals(testAddresses[0].City__c, con.MailingCity);
		System.assertEquals(testAddresses[0].State__c, con.MailingState);
		System.assertEquals(testAddresses[0].Postal_Code__c, con.MailingPostalCode);
		System.assertEquals(testAddresses[0].Country__c, con.MailingCountry);
		
		Test.stopTest();
	}
	
	static testMethod void testOverlappingDates() {
		Test.startTest();
		
		insert testAddresses;
		
		Seasonal_Address__c overlap = new Seasonal_Address__c(
			Contact__c = testContact1.Id
			, Start_Day__c = 1
			, Start_Month__c = 'April'
			, End_Day__c = 1
			, End_Month__c = 'August'
			, Current_Address__c = false
			, Invalid__c = false
			, Street__c = '3street'
			, City__c = '3town'
			, State__c = '3NJ'
			, Country__c = '3USA'
			, Postal_Code__c = '33333'
		);
		
		try {
			insert overlap;
			
			System.assert(false, 'None shall pass'); // shouldn't get this far due to exception being thrown.
		}
		catch (Exception e) {}
		
		Test.stopTest();
	}
	
	static testMethod void testInvalidation() {
		Test.startTest();
		
		insert testAddresses;
		
		Contact con = [SELECT MailingStreet, MailingCity, MailingState, MailingPostalCode, MailingCountry FROM Contact WHERE Id = :testContact1.Id];
		System.assertEquals(testAddresses[0].Street__c, con.MailingStreet);
		System.assertEquals(testAddresses[0].City__c, con.MailingCity);
		System.assertEquals(testAddresses[0].State__c, con.MailingState);
		System.assertEquals(testAddresses[0].Postal_Code__c, con.MailingPostalCode);
		System.assertEquals(testAddresses[0].Country__c, con.MailingCountry);
		
		Seasonal_Address__c s = [SELECT Id, Invalid__c, Current_Address__c FROM Seasonal_Address__c WHERE Id = :testAddresses[0].Id];
		System.assertEquals(true, s.Current_Address__c);
		System.assertEquals(false, s.Invalid__c);
		
		s.Invalid__c = true;
		update s;
		
		con = [SELECT MailingStreet, MailingCity, MailingState, MailingPostalCode, MailingCountry FROM Contact WHERE Id = :testContact1.Id];
		System.assertEquals(null, con.MailingStreet);
		System.assertEquals(null, con.MailingCity);
		System.assertEquals(null, con.MailingState);
		System.assertEquals(null, con.MailingPostalCode);
		System.assertEquals(null, con.MailingCountry);
		
		s = [SELECT Current_Address__c FROM Seasonal_Address__c WHERE Id = :testAddresses[0].Id];
		System.assertEquals(false, s.Current_Address__c);
		
		Test.stopTest();
	}
	
	static testMethod void testReverseDates() {
		Seasonal_Address__c sa = new Seasonal_Address__c(
			Contact__c = testContact1.Id
			, Start_Day__c = 1
			, Start_Month__c = 'June'
			, End_Day__c = 1
			, End_Month__c = 'January'
			, Current_Address__c = false
			, Invalid__c = false
			, Street__c = '1street'
			, City__c = '1town'
			, State__c = '1NJ'
			, Country__c = '1USA'
			, Postal_Code__c = '11111'
		);
		
		Test.startTest();
		
		insert sa;
		
		Contact con = [SELECT MailingStreet, MailingCity, MailingState, MailingPostalCode, MailingCountry FROM Contact WHERE Id = :testContact1.Id];
		System.assertEquals(sa.Street__c, con.MailingStreet);
		System.assertEquals(sa.City__c, con.MailingCity);
		System.assertEquals(sa.State__c, con.MailingState);
		System.assertEquals(sa.Postal_Code__c, con.MailingPostalCode);
		System.assertEquals(sa.Country__c, con.MailingCountry);
		
		Test.stopTest();
	}
	
	static testMethod void testControllerMethods() {
		Test.startTest();
		
		insert testAddresses;
		
		List<Seasonal_Address__c> retrievedAddresses = OverrideAddressController.getAddresses(testContact1.Id);
		System.assertEquals(2, retrievedAddresses.size());
		
		Contact con = [SELECT MailingStreet, MailingCity, MailingState, MailingPostalCode, MailingCountry, Address_Overriden__c FROM Contact WHERE Id = :testContact1.Id];
		System.assertEquals(testAddresses[0].Street__c, con.MailingStreet);
		System.assertEquals(testAddresses[0].City__c, con.MailingCity);
		System.assertEquals(testAddresses[0].State__c, con.MailingState);
		System.assertEquals(testAddresses[0].Postal_Code__c, con.MailingPostalCode);
		System.assertEquals(testAddresses[0].Country__c, con.MailingCountry);
		System.assertEquals(false, con.Address_Overriden__c);
		
		OverrideAddressController.overrideAddress(testAddresses[1].Id);
		con = [SELECT MailingStreet, MailingCity, MailingState, MailingPostalCode, MailingCountry, Address_Overriden__c FROM Contact WHERE Id = :testContact1.Id];
		System.assertEquals(testAddresses[1].Street__c, con.MailingStreet);
		System.assertEquals(testAddresses[1].City__c, con.MailingCity);
		System.assertEquals(testAddresses[1].State__c, con.MailingState);
		System.assertEquals(testAddresses[1].Postal_Code__c, con.MailingPostalCode);
		System.assertEquals(testAddresses[1].Country__c, con.MailingCountry);
		System.assertEquals(true, con.Address_Overriden__c);
		
		OverrideAddressController.disableOverride(testContact1.Id);
		con = [SELECT Address_Overriden__c FROM Contact WHERE Id = :testContact1.Id];
		System.assertEquals(false, con.Address_Overriden__c);
		
		Test.stopTest();
	}
}