/**
* @author: John Schultz
* @date: 2017-06-05
* @description: Service layer for Seasonal_Address__c object
* @log:
* ----------------------------------------------------------------------------
* Developer       Date          Description
* ----------------------------------------------------------------------------
* John Schultz    2017-06-05    Newly created
*/
public class SeasonalAddressService {
	
	public static List<Contact> contactsToUpdate = new List<Contact>();
	public static List<Seasonal_Address__c> existingAddressesToUpdate = new List<Seasonal_Address__c>();
	public static Boolean disableAddressUpdateTrigger = false;
	
	private static final Map<String, Integer> MONTHS;
	private static final Integer YEAR;
	private static final Date TODAY;
	
	static {
		MONTHS = new Map<String, Integer>{
			'January' => 1,
			'February' => 2,
			'March' => 3,
			'April' => 4,
			'May' => 5,
			'June' => 6,
			'July' => 7,
			'August' => 8,
			'September' => 9,
			'October' => 10,
			'November' => 11,
			'December' => 12
		};
		
		// setting static date for unit tests or today for normal code runs
		TODAY = Test.isRunningTest() ? Date.newInstance(2000, 7, 1) : Date.today();
		YEAR = TODAY.year();
	}

	/**
	* @author: John Schultz
	* @date: 2017-06-05
	* @description: Handles the inserting/updating of addresses and their validation.
	* @param: addresses - List<Seasonal_Address__c>
	* @return: void
	*/
	public static void handleAddressUpdate(List<Seasonal_Address__c> addresses) {
		Map<Id, Contact> contacts;
		
		if (disableAddressUpdateTrigger) {
			return;
		}
		
		for (Seasonal_Address__c sa : addresses) {
			// assign month number
			sa.Start_Month_Number__c = Decimal.valueOf(MONTHS.get(sa.Start_Month__c));
			sa.End_Month_Number__c = Decimal.valueOf(MONTHS.get(sa.End_Month__c));
			
			// set flag for reversed dates. used in batch class.
			if (sa.Start_Month_Number__c > sa.End_Month_Number__c || (sa.Start_Month_Number__c == sa.End_Month_Number__c && sa.Start_Day__c > sa.End_Day__c)) {
				sa.End_Before_Start__c = true;
			}
			
		}
		
		// get the related contacts and existing seasonal addresses
		contacts = getRelatedContacts(addresses);
		
		// validate that no dates overlap with existing dates
		validateNoDateOverlap(addresses, contacts);
		
		for (Seasonal_Address__c sa : addresses) {
			Contact relatedContact = contacts.get(sa.Contact__c);
			
			// if the address is invalid, remove it from the contact (if it's the currently active one).
			if (sa.Invalid__c && sa.Current_Address__c) {
				relatedContact.MailingStreet = null;
				relatedContact.MailingState = null;
				relatedContact.MailingCountry = null;
				relatedContact.MailingPostalCode = null;
				relatedContact.MailingCity = null;
				
				contactsToUpdate.add(relatedContact);
				
				// remove current address flag
				sa.Current_Address__c = false;
			}
			// if the address's date range surrounds today's date, make it active unless an override is in place.
			else {
				AddressDateObject dateObj = generateDates(sa);
				
				if (relatedContact.Address_Overriden__c != true && isDateBetween(dateObj.startDate, dateObj.endDate, TODAY)) {
					// set this address to current
					sa.Current_Address__c = true;
					
					// update contact and other addresses
					updateContactAndOtherAddresses(sa, relatedContact);
				}
			}
		}
		
		// call method to commit changes
		saveUpdatedContactsAndAddresses();
	}
	
	/**
	* @author: John Schultz
	* @date: 2017-06-05
	* @description: Retrieves contacts and existing addresses related to the addresses in the method params.
	* @param: addresses - List<Seasonal_Address__c>
	* @return: Map<Id, Contact>
	*/
	public static Map<Id, Contact> getRelatedContacts(List<Seasonal_Address__c> addresses) {
		Set<Id> contactIds = new Set<Id>();
		Map<Id, Contact> contacts;
		
		for (Seasonal_Address__c sa : addresses) {
			// collect contact IDs
			contactIds.add(sa.Contact__c);
		}
		
		// get contacts
		contacts = new Map<Id, Contact>([
			SELECT
				Id
				, Address_Overriden__c
				, MailingStreet
				, MailingCity
				, MailingState
				, MailingPostalCode
				, MailingCountry
				, (SELECT
				Id
				, Start_Day__c
				, Start_Month__c
				, Start_Month_Number__c
				, End_Day__c
				, End_Month__c
				, End_Month_Number__c
				, Current_Address__c
				, End_Before_Start__c
			FROM Seasonal_Addresses__r
			WHERE Invalid__c = FALSE)
			FROM Contact
			WHERE Id IN :contactIds
		]);
		
		return contacts;
	}
	
	/**
	* @author: John Schultz
	* @date: 2017-06-05
	* @description: Updates the related contact and it's other addresses
	* @param: address - Seasonal_Address__c
	* @param: con - Contact
	* @return: void
	*/
	public static void updateContactAndOtherAddresses(Seasonal_Address__c address, Contact con) {
		// update contact with this new address.
		con.MailingStreet = address.Street__c;
		con.MailingState = address.State__c;
		con.MailingCountry = address.Country__c;
		con.MailingPostalCode = address.Postal_Code__c;
		con.MailingCity = address.City__c;
		contactsToUpdate.add(con);
		
		
		// if other address was previously current, remove that flag
		for (Seasonal_Address__c existing : con.Seasonal_Addresses__r) {
			if (existing.Id != address.Id && existing.Current_Address__c) {
				existing.Current_Address__c = false;
				existingAddressesToUpdate.add(existing);
			}
		}
	}
	
	/**
	* @author: John Schultz
	* @date: 2017-06-05
	* @description: Method for updating the contacts and addresses that have been changed in this class.
	* @return: void
	*/
	public static void saveUpdatedContactsAndAddresses() {
		SavePoint sp = Database.setSavePoint();
		
		try {
			if (!contactsToUpdate.isEmpty()) {
				update contactsToUpdate;
			}
			
			if (!existingAddressesToUpdate.isEmpty()) {
				update existingAddressesToUpdate;
			}
			
			contactsToUpdate.clear();
			existingAddressesToUpdate.clear();
		}
		catch (Exception e) {
			Database.rollback(sp);
			throw e;
		}
	}
	
	/**
	* @author: John Schultz
	* @date: 2017-06-05
	* @description: Validates that the address's dates do not overlap any existing address dates.
	* @param: addresses - List<Seasonal_Address__c
	* @param: contacts - Map<Id, Contact>
	* @return: void
	*/
	public static void validateNoDateOverlap(List<Seasonal_Address__c> addresses, Map<Id, Contact> contacts) {
		for (Seasonal_Address__c sa : addresses) {
			// we only validate if the current address is not invalid
			if (sa.Invalid__c != true) {
				AddressDateObject newDateObj = generateDates(sa);
				Contact ct = contacts.get(sa.Contact__c);
				
				if (ct != null && ct.Seasonal_Addresses__r != null) {
					for (Seasonal_Address__c existingAddress : ct.Seasonal_Addresses__r) {
						// don't compare against itself if this is in an update context.
						if (sa.Id != existingAddress.Id) {
							AddressDateObject existingDateObj = generateDates(existingAddress);
							
							if (isDateBetween(existingDateObj.startDate, existingDateObj.endDate, newDateObj.startDate)
									|| isDateBetween(existingDateObj.startDate, existingDateObj.endDate, newDateObj.endDate)) {
								
								throw new SeasonalAddressException('A existing seasonal address already covers some or all of ' + sa.Start_Month__c + ' ' + sa.Start_Day__c.toPlainString() + ' - ' + sa.End_Month__c + ' ' + sa.End_Day__c.toPlainString());
							}
						}
					}
				}
			}
		}
	}
	
	/**
	* @author: John Schultz
	* @date: 2017-06-06
	* @description: Checks if date falls in between start and end date with consideration for reverse dates.
	* @param: startDate - Date
	* @param: endDate - Date
	* @param: testDate - Date
	* @return: Boolean
	*/
	public static Boolean isDateBetween(Date startDate, Date endDate, Date testDate) {
		return (
			(startDate < endDate && testDate >= startDate && testDate < endDate) ||
			(startDate > endDate && (
				(testDate >= startDate.addYears(-1) && testDate <= endDate) ||
				(testDate >= startDate && testDate <= endDate.addYears(1))
			))
		);
	}
	
	/**
	* @author: John Schultz
	* @date: 2017-06-05
	* @description: Utility method for generating dates
	* @param: address - Seasonal_Address__c
	* @return: AddressDateObject
	*/
	public static AddressDateObject generateDates(Seasonal_Address__c address) {
		AddressDateObject dateObj = new AddressDateObject();
		
		Integer startMonth = Integer.valueOf(address.Start_Month_Number__c);
		Integer startDay = Integer.valueOf(address.Start_Day__c);
		Integer endMonth = Integer.valueOf(address.End_Month_Number__c);
		Integer endDay = Integer.valueOf(address.End_Day__c);
		
		dateObj.startDate = Date.newInstance(YEAR, startMonth, startDay);
		dateObj.endDate = Date.newInstance(YEAR, endMonth, endDay);
		
		return dateObj;
	}
	
	/**
	* @author: John Schultz
	* @date: 2017-06-06
	* @description: Retrieves the addresses related to a specific contact.
	* @param: contactId - String
	* @return: List<Seasonal_Address__c>
	*/
	public static List<Seasonal_Address__c> getAddressesByContactId(String contactId) {
		return new List<Seasonal_Address__c>([SELECT Id, Street__c, City__c, State__c, Country__c, Postal_Code__c, Current_Address__c, Invalid__c FROM Seasonal_Address__c WHERE Contact__c = :contactId ORDER BY Invalid__c, Street__c]);
	}
	
	/**
	* @author: John Schultz
	* @date: 2017-06-06
	* @description: Handles the manual override process.
	* @param: addressIds - array of strings
	* @return: void
	*/
	public static void overrideAddresses(String[] addressIds) {
		// disable trigger since we're updating the addresses manually
		disableAddressUpdateTrigger = true;
		
		
		List<Seasonal_Address__c> addresses = new List<Seasonal_Address__c>([SELECT Id, Street__c, City__c, State__c, Country__c, Postal_Code__c, Contact__c, Current_Address__c FROM Seasonal_Address__c WHERE Id IN :addressIds]);
		Map<Id, Contact> contacts = getRelatedContacts(addresses);
		
		for (Seasonal_Address__c sa : addresses) {
			Contact con = contacts.get(sa.Contact__c);
			
			// set flag on contact that indicates manual override
			con.Address_Overriden__c = true;
			
			// set address to current address
			sa.Current_Address__c = true;
			SeasonalAddressService.existingAddressesToUpdate.add(sa);
			
			// call method to update related records
			SeasonalAddressService.updateContactAndOtherAddresses(sa, con);
		}
		
		// commit changes
		SeasonalAddressService.saveUpdatedContactsAndAddresses();
	}
	
	/**
	* @author: John Schultz
	* @date: 2017-06-06
	* @description: Releases the address override on contact
	* @param: contactIds - array of strings
	* @return: void
	*/
	public static void disableOverride(String[] contactIds) {
		List<Contact> contacts = new List<Contact>([SELECT Id, Address_Overriden__c FROM Contact WHERE Id IN :contactIds]);
		
		for (Contact c : contacts) {
			c.Address_Overriden__c = false;
		}
		
		update contacts;
	}
	
	/**
	* @author: John Schultz
	* @date: 2017-06-06
	* @description: Wrapper class for common dates
	*/
	public class AddressDateObject {
		public Date startDate;
		public Date endDate;
	}
	
	/**
	* @author: John Schultz
	* @date: 2017-06-05
	* @description: Custom exception class
	*/
	public class SeasonalAddressException extends Exception {}
}