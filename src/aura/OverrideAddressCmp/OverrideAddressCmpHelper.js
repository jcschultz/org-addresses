/**
 * Created by jschultz on 6/6/17.
 */
({
	
	loadAddresses : function(component, event, helper) {
		var action = component.get('c.getAddresses');
		var contactId = component.get('v.recordId');
		
		action.setParams({'contactId' : contactId});
		
		action.setCallback(this, function(a){
			var state = a.getState();
			var addresses = a.getReturnValue();
			
			if (component.isValid() && state === 'SUCCESS') {
				if (addresses && addresses.length) {
					component.set('v.addresses', addresses);
				}
				else {
					component.set('v.hasError', true);
					component.set('v.errorMsg', 'This contact has no seasonal addresses yet. Please create one first.');
				}
			}
			else {
				component.set('v.hasError', true);
				component.set('v.errorMsg', 'There was an error retrieving the addresses.');
				console.log(a.getError());
			}
		});
		
		$A.enqueueAction(action);
	},
	
})