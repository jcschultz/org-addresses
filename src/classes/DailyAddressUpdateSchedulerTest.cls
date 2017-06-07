/**
 * Created by jschultz on 6/6/17.
 */

@IsTest
private class DailyAddressUpdateSchedulerTest {
	
	static String CRON_EXP = '0 0 0 29 8 ? 2035';
	
	static testMethod void testScheduler() {
		Test.startTest();
		
		String jobId = System.schedule('testing', CRON_EXP, new DailyAddressUpdateScheduler());
		
		CronTrigger testingCron = [SELECT Id, TimesTriggered, NextFireTime FROM CronTrigger WHERE Id = :jobId];
		
		System.assertEquals(0, testingCron.TimesTriggered);
		System.assertEquals('2035-08-29 00:00:00', String.valueOf(testingCron.NextFireTime));
		
		Test.stopTest();
	}
}