/**
* @author: John Schultz
* @date: 2017-06-06
* @description: Schedulable class for scheduling the address updater.
* @log:
* ----------------------------------------------------------------------------
* Developer       Date          Description
* ----------------------------------------------------------------------------
* John Schultz    2017-06-06    Newly created
*/
global class DailyAddressUpdateScheduler implements Schedulable {
	global void execute(SchedulableContext sc) {
		DailyAddressUpdaterBatch daub = new DailyAddressUpdaterBatch();
		ID jobId = Database.executeBatch(daub);
	}
}