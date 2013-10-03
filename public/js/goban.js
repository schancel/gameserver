YUI.add('goban', 
	function(Y) {
	    function Goban(config) {
		Goban.superclass.constructor.apply(this, arguments);
	    }
	    
	    ChannelTab.ATTRS = {
	    };
	    	    
	    Y.extend(ChannelTab, Y.Widget, { 
	    });

	    Y.Goban = Goban;
	}, 
	'1.0.0',
	{ requires: [  ] });