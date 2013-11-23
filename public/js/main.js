//"use strict";

YUI.GlobalConfig = 
    {
	modules:
	{
	    channeltab: '/js/channeltab.js',
	    usermodel: '/js/usermodel.js'
	}
    };

//Context will be the message itself
UserInterface.prototype.protocol =  function(self)
{
    this[OpCodes.JoinMessage] = function(channel, who)
    {
        if( self.connection.name == who) {
	    var tab = new self.Y.ChannelTab({channelName:channel });
	    self.channels[channel] = tab;
	    self.tabview.add( tab , 0 ); 
	    self.tabview.selectChild(0);
	    self.connection.Who(channel);
        } else {
            var tab = self.channels[channel];
	    if( tab instanceof self.Y.ChannelTab )
	        tab.Join(who);
        }
    }

    this[OpCodes.PartMessage] = function(channel, who) {
	var tab = self.channels[channel];
	if( tab instanceof self.Y.ChannelTab )
	    tab.Part(who);
    }

    this[OpCodes.ChatMessage] = function(channel, message, user) //OutgoingChatMessage
    {
	self.channels[channel].writeToChannel(user, message );

	if( ! document.hasFocus() )
	{
	    self.messages += 1;
	    document.title = self.titleCache + " (" + self.messages + ")";
	}
    }

    this[OpCodes.WhoListMessage] = function(channel, whoList)
    {
	var tab = self.channels[channel];
	if( tab instanceof self.Y.ChannelTab )
	    tab.Who(whoList);
    }

    this[OpCodes.ShutdownMessage] = function ()
    {

    }
}

UserInterface.prototype.clickSubmit = function() {
    var tab = this.tabview.get('selection') ;
    if( tab instanceof this.Y.ChannelTab )
    {
        var inputBox = tab.get('panelNode').one('.input'), inputVal = inputBox.get('value');
        
	if( inputVal.charAt(0) != '/' )
	    this.connection.Chat(tab.get('channelName'), inputVal );
	else
	{
	    var cmd = JSON.stringify(inputVal.substring(1));
	    this.connection[cmd[0]].call(this.connection, cmd.slice(1));
	}
	inputBox.set('value', '');
    }
}

function UserInterface (Y) {
    this.Y = Y;
    var self = this;
    this.messages = 0;
    this.server =  String(window.location).replace('http','ws').replace('index.html','websocket'); //TODO: Fixup
    this.titleCache = String(document.title);
    this.activeChannel = "Default"; 

    this.tabview = new Y.TabView({srcNode: '#tabs' });
    this.channels = {};

    this.connection = new ServerConnection(this.server, new this.protocol(this));

    /*this.tabview.on('selectionChange', function (e) {
	if( e.newVal instanceof Y.ChannelTab )
	{
	    var tab = e.newVal;
	    tab.selected();
	}
    });*/

    this.tabview.render();
    this.form = Y.one('form');

    this.form.on('submit', function(evt) { 
	self.clickSubmit();
	evt.preventDefault();
    });

    Y.on('keydown', function(evt) {
	if( evt.keyCode === 13 )
	{
	    self.clickSubmit();
	    evt.preventDefault();
	}
    });
    
    Y.on('focus', function(e) { document.title=self.titleCache; self.messages=0; })
}

YUI().use('event', 'node', 'node-base',  'tabview', 'model', 'model-list', 'channeltab', function(Y) { new  UserInterface(Y); } )