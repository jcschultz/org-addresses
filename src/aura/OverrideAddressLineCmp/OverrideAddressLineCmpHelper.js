/**
 * Created by jschultz on 6/6/17.
 */
({
	
	setOverride : function(component, event, helper) {
		var address = component.get('v.address');
		var action = component.get('c.overrideAddress');
		
		action.setParams({'addressId' : address.Id});
		
		action.setCallback(this, function(a) {
			var state = a.getState();
			
			if(component.isValid() && state === 'SUCCESS'){
				$A.get('e.force:closeQuickAction').fire();
				
				var toastEvent = $A.get('e.force:showToast');
				toastEvent.setParams({
					'title': 'Success!',
					'message': 'The address has been manually overridden and will no longer be changed based on dates. To re-enable the seasonal date feature, click the Disable Address Override action button.'
				});
				toastEvent.fire();
				
				$A.get('e.force:refreshView').fire();
			}
			else {
				console.log('ERROR OVERRIDING: ', a.getError());
			}
		});
		
		$A.enqueueAction(action);
	},
	
})