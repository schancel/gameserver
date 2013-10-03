//"use strict";

YUI.GlobalConfig = 
    {
	modules:
	{
	    channeltab: '/js/channeltab.js',
	    usermodel: '/js/usermodel.js'
	}
    };

UserInterface.prototype.protocol =  function(self)
{
    this.JOIN = function(channelName)
    {
	var tab = new self.Y.ChannelTab({channelName:channelName });
	self.channels[channelName] = tab;
	self.tabview.add( tab , 0 ); 
	self.tabview.selectChild(0);
	self.connection.Who(channelName);
    }
    this.MSG = function(channelName, message, who)
    {
	self.channels[channelName].writeToChannel(who, message );

	if( ! document.hasFocus() )
	{
	    self.messages += 1;
	    document.title = self.titleCache + " (" + self.messages + ")";
	}
    }

    this.WHO = function(channelName, whoList)
    {
	var tab = self.channels[channelName];
	if( tab instanceof self.Y.ChannelTab )
	    tab.Who(JSON.parse(whoList));
    }

    this.JOINED = function(channelName, who) {
	var tab = self.channels[channelName];
	if( tab instanceof self.Y.ChannelTab )
	    tab.Join(who);
    }

    this.PARTED = function(channelName, who) {
	var tab = self.channels[channelName];
	if( tab instanceof self.Y.ChannelTab )
	    tab.Part(who);
    }
}

UserInterface.prototype.clickSubmit = function() {
    var tab = this.tabview.get('selection') ;
    if( tab instanceof this.Y.ChannelTab )
    {
	var input = tab.get('panelNode').one('.input');
	this.connection.Msg(tab.get('channelName'), input.get('value') );
	input.set('value', '');
    }
}

function UserInterface (Y) {
    this.Y = Y;
    var self = this;
    this.messages = 0;
    this.server =  String(window.location).replace('http','ws').replace('index.html','websocket');
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
	if(evt.keyCode == 13)
	{
	    self.clickSubmit();
	    evt.preventDefault();
	}
    });
    
    Y.on('focus', function(e) { document.title=self.titleCache; self.messages=0; })
}

YUI().use('node', 'event', 'tabview', 'model', 'model-list', 'channeltab', function(Y) { new  UserInterface(Y); } )