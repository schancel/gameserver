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
    this[1] = function(msg) //JoinMessage
    {
	var tab = new self.Y.ChannelTab({channelName:msg.channel });
	self.channels[msg.channel] = tab;
	self.tabview.add( tab , 0 ); 
	self.tabview.selectChild(0);
//	self.connection.Who(msg.channel);
    }
    this[2] = function(msg) //ChatMessage
    {
	self.channels[channelName].writeToChannel(msg.who, msg.message );

	if( ! document.hasFocus() )
	{
	    self.messages += 1;
	    document.title = self.titleCache + " (" + self.messages + ")";
	}
    }
/*
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
    }*/
}

UserInterface.prototype.clickSubmit = function() {
    var tab = this.tabview.get('selection') ;
    if( tab instanceof this.Y.ChannelTab )
    {
        var inputBox = tab.get('panelNode').one('.input'), inputVal = inputBox.get('value');
        
	if( inputVal.charAt(0) != '/' )
	    this.connection.Msg(tab.get('channelName'), inputVal );
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

//    Y.on('keydown', function(e) { alert('foof'); });

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