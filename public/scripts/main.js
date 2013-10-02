const defaultTabContent = '<table class="output"></table><input type="text" value="" class="input" />';

UserInterface.prototype.protocol =  function(self)
{
    this.JOIN = function(channelName)
    {
	var tab = new self.Y.Tab({ label: '#' + channelName, content: defaultTabContent });
	tab.channelName = channelName;
	tab.updates = 0;
	self.tabview.add( tab , 0 ); 
	self.tabview.channels[channelName] = tab;
	self.tabview.selectChild(0);
    }
    this.MSG = function(channelName, message, who)
    {
	self.writeToChannel(channelName, who, message );   
    }
}

UserInterface.prototype.clickSubmit = function() {
    if( typeof(this.tabview.channels[this.activeChannel]) != 'undefined')
    {
	var input = this.tabview.channels[this.activeChannel].get('panelNode').one('.input');
	this.connection.Msg(this.activeChannel, input.get('value') );
	input.set('value', '');
    }
}

UserInterface.prototype.writeToChannel = function(tabName, title, message)
{
    var pre = document.createElement("tr");
    var titleTd = document.createElement("td");
    var messageTd = document.createElement("td");

    titleTd.innerHTML = title;
    messageTd.innerHTML = message;
    pre.appendChild(titleTd);
    pre.appendChild(messageTd);
    
    var tab = this.tabview.channels[tabName];
    if( this.tabview.get('selection') != tab )
    {
	tab.updates += 1;
	tab.set('label', '#' + tab.channelName + ' (' + tab.updates + ')');
    }
    if( ! document.hasFocus() )
    {
	this.messages += 1;
	document.title = this.titleCache + " (" + this.messages + ")";
    }

    tab.get('panelNode').one('.output').append(pre);
    pre.scrollIntoView(false);
}

function UserInterface (Y) {
    this.Y = Y;
    var self = this;
    this.messages = 0;
    this.server =  String(window.location).replace('http','ws').replace('index.html','websocket');
    this.titleCache = String(document.title);
    this.activeChannel = "Default"; 

    this.tabview = new Y.TabView({srcNode: '#tabs' });
    this.tabview.channels = {};

    this.connection = new ServerConnection(this.server, new this.protocol(this));

    this.tabview.on('selectionChange', function (e) {
	self.activeChannel = e.newVal.channelName;
	if( typeof(self.activeChannel) != 'undefined' && typeof(self.tabview.channels[self.activeChannel]) != 'undefined')
	{
	    var tab = self.tabview.channels[self.activeChannel];
	    tab.updates = 0;
	    tab.set('label', '#' + tab.channelName );
	    tab.get('panelNode').one('.input').focus();
	}
    });

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

YUI().use('node', 'event', 'tabview', function(Y) { new  UserInterface(Y); } )