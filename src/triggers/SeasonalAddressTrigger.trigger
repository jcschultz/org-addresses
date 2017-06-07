/**
* @author: John Schultz
* @date: 2017-06-05
* @description: Trigger for Seasonal_Address__c object
* @log:
* ----------------------------------------------------------------------------
* Developer       Date          Description
* ----------------------------------------------------------------------------
* John Schultz    2017-06-05    Newly created
*/
trigger SeasonalAddressTrigger on Seasonal_Address__c (before insert, before update) {
    SeasonalAddressService.handleAddressUpdate(Trigger.new);
}