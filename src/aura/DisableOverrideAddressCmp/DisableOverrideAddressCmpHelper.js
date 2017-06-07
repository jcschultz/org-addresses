/**
 * Created by jschultz on 6/6/17.
 */
({
	disableOverride : function(component, event, helper) {
		var contactId = component.get('v.recordId');
		var action = component.get('c.disableOverride');
		
		action.setParams({'contactId' : contactId});
		
		action.setCallback(this, function(a){
			var state = a.getState();
			
			if(component.isValid() && state === 'SUCCESS'){
				component.set('v.hasError', false);
				$A.get('e.force:closeQuickAction').fire();
				
				var toastEvent = $A.get('e.force:showToast');
				toastEvent.setParams({
					'title': 'Success!',
					'message': 'The manual address override has been disabled. The address will automatically be set, based on the date ranges, during the daily address update.'
				});
				toastEvent.fire();
				$A.get('e.force:refreshView').fire();
			}
			else {
				component.set('v.hasError', true);
				component.set('v.errorMsg', 'There was an error disabling the address override.');
				console.log('ERROR OVERRIDING: ', a.getError());
			}
		});
		
		$A.enqueueAction(action);
	},
})