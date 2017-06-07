/**
* @author: John Schultz
* @date: 2017-06-06
* @description: Controller for Overriding address component
* @log:
* ----------------------------------------------------------------------------
* Developer       Date          Description
* ----------------------------------------------------------------------------
* John Schultz    2017-06-06    Newly created
*/
public with sharing class OverrideAddressController {
	
	/**
	* @author: John Schultz
	* @date: 2017-06-06
	* @description: Aura enabled method for retrieving addresses related to a contact.
	* @param: contactId - String
	* @return: List<Seasonal_Address__c>
	*/
	@AuraEnabled
	public static List<Seasonal_Address__c> getAddresses(String contactId) {
		return SeasonalAddressService.getAddressesByContactId(contactId);
	}
	
	/**
	* @author: John Schultz
	* @date: 2017-06-06
	* @description: Allows user to override address
	* @param: addressId - String
	* @return: Boolean
	*/
	@AuraEnabled
	public static Boolean overrideAddress(String addressId) {
		SeasonalAddressService.overrideAddresses(new List<String>{addressId});
		return true;
	}
	
	/**
	* @author: John Schultz
	* @date: 2017-06-06
	* @description: Allows user to disable the address override
	* @param: contactId - String
	* @return: Boolean
	*/
	@AuraEnabled
	public static Boolean disableOverride(String contactId) {
		SeasonalAddressService.disableOverride(new List<String>{contactId});
		return true;
	}
	
}