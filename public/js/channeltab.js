YUI.add('channeltab', 
	function(Y) {
	    function ChannelTab(config) {
		const defaultTabContent = '<div class="displayBlock"><table class="output"></table><input type="text" value="" placeholder="Type message here and press enter..." class="input" /></div><div class="users"></div>';
		ChannelTab.superclass.constructor.apply(this, 
							[{
							    label: '#' + config.channelName, 
							    content: defaultTabContent
							}] );

		this.set('channelName', config.channelName);
		//Y.get('channels')[config.channelName] = this;

		var columns = [ {key: 'Username', width:'20%'}];// {key: 'Username', sortable:true} ];

		this.UserDT = new Y.DataTable({recordType: Y.UserModel,
						    columns: columns, 
						    autoSync: true});

		this.after('selectedChange', this.selected);
	    }
	    
	    ChannelTab.ATTRS = {
		channelName: {
		    value: null
		},
		updates:
		{
		    value: 0
		}
	    };
	    	    
	    Y.extend(ChannelTab, Y.Tab, { 
		selected: function(e)
		{
		    if( e.newVal >= 1)
		    {
			this.set('updates', 0);
			this.set('label', '#' + this.get('channelName'));
		    }
		},
		
		render: function(srcNode)
		{
		    ChannelTab.superclass.render.call(this,srcNode);
		    this.UserDT.render(this.get('panelNode').one('.users'));
		},
		
		Who: function(whoList)
		{
		    for( i = 0; i < whoList.length; i++){
			var who = whoList[i];
			if(this.UserDT.data.getById(who) == null)
			    this.UserDT.addRow(new Y.UserModel({Username: who}));
		    }
		},

		Join: function(who) {
		    if(this.UserDT.data.getById(who) == null)
			this.UserDT.addRow(new Y.UserModel({Username: who}));
		    this.writeToChannel( "JOINED", who);
		} ,

		Part: function(who) 
		{
		    this.UserDT.removeRow(who);
		    this.writeToChannel("PARTED", who);
		},

		writeToChannel: function(title, message)
		{
		    var pre = document.createElement("tr");
		    var titleTd = document.createElement("td");
		    var messageTd = document.createElement("td");

		    titleTd.innerHTML = title;
		    messageTd.innerHTML = message;
		    pre.appendChild(titleTd);
		    pre.appendChild(messageTd);
		    
		    if( this.get('selected') == 0 )
		    {
			this.set('updates', this.get('updates') + 1);
			this.set('label', '#' + this.get('channelName') + ' (' + this.get('updates') + ')');
		    }

		    this.get('panelNode').one('.output').append(pre);
		    pre.scrollIntoView(false);
		}
		
	    });

	    ChannelTab.NAME = ChannelTab.superclass.constructor.NAME;
	    Y.ChannelTab = ChannelTab;
	}, 
	'1.0.0',
	{ requires: [ 'node', 'tabview', 'model', 'datatable', 'usermodel' ] });