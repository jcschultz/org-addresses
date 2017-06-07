/**
 * Created by jschultz on 6/6/17.
 */
({
	
	handleClick : function(component, event, helper) {
		console.log('handleClick');
		helper.setOverride(component, event, helper);
	},
	
})