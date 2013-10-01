const defaultTabContent = '<div class="output"></div><input type="text" value="" class="input" />';

YUI().use('node', 'event', 'tabview', function (Y) {
//Global elements
    var wsUri = String(window.location);
    wsUri = wsUri.replace('http','ws').replace('index.html','websocket');
    
    var titleCache = String(document.title);
    var messages = 0;
    var activeChannel = "Default"; 

    var tabview = new Y.TabView({
        srcNode: '#tabs'
    });
    tabview.channels = {};

    tabview.on('selectionChange', function (e) {
	activeChannel = e.newVal.channelName;
	if( typeof(tabview.channels[activeChannel]) != 'undefined')
	{
	    var tab = tabview.channels[activeChannel];
	    tab.updates = 0;
	    tab.set('label', '#' + tab.channelName );
	    tab.get('panelNode').one('.input').focus();
	}
    });

    tabview.render();
    var form = Y.one('form');
    ///

    function initWebSocket() {
	websocket = new WebSocket(wsUri);
	websocket.onopen = onOpen ;
	websocket.onclose = onClose;
	websocket.onmessage =  onMessage;
	websocket.onerror = onError;
    }
    
    var clickSubmit = function() {
	if( typeof(tabview.channels[activeChannel]) != 'undefined')
	{
	    var input = tabview.channels[activeChannel].get('panelNode').one('.input');
	    doSend(JSON.stringify(["MSG", activeChannel, input.get('value')]));
	    input.set('value', '');
	}
    }

    function onOpen(evt)
    {
	var name = prompt("Enter a nickname");
	doSend(JSON.stringify(["NICK", name]));

	doSend(JSON.stringify(["JOIN", "Earth"]));
	if(navigator.geolocation)
	{
	    navigator.geolocation.getCurrentPosition( 
		function (pos) {
		    var latlng = new google.maps.LatLng(pos.coords.latitude, pos.coords.longitude);
		    geocoder = new google.maps.Geocoder();
		    geocoder.geocode({'latLng': latlng}, function(results, status) {
			if (status == google.maps.GeocoderStatus.OK) {
			    //console.log(results);
			    city = {};
			    if( results.length > 0 )
			    {
				for( var i=results.length-1; i>=0; i--)
				{
				    if( ( results[i].types.indexOf("locality") != -1 && results[i].types.indexOf("political") != -1) ||
					( results[i].types.indexOf("administrative_area_level_1") != -1 && results[i].types.indexOf("political") != -1) ||
					( results[i].types.indexOf("country") != -1 && results[i].types.indexOf("political") != -1) )
				    {
					doSend(JSON.stringify(["JOIN", results[i].formatted_address]));
				    }
				}
			    }
			}
		    });
		}	
	    );
	}
    }
    
    function onClose(evt)
    {
    }

    function onMessage(evt)
    {
	if( ! document.hasFocus() ) 
	{
	    messages += 1;
	    document.title = titleCache + " (" + messages + ")";
	}
	msg = JSON.parse(evt.data);
	if( msg[0] == "MSG" )
	{
	    writeToTab(msg[1],'<span>' + msg[3] +': ' + msg[2] +'</span>');   
	}
	else if (msg[0] == "JOIN")
	{
	    var tab = new Y.Tab({ label: '#' + msg[1], content: defaultTabContent });
	    tab.channelName = msg[1];
	    tab.updates = 0;
	    tabview.add( tab , 0 ); 
	    tabview.channels[msg[1]] = tab;
	    tabview.selectChild(0);
	    doSend(JSON.stringify(['WHO', msg[1]]));
	};
    }

    function onError(evt)
    {
	writeToScreen('<span style="color: red;">ERROR:' + evt.data + '</span> ');
    }

    function doSend(message)
    {
	websocket.send(message);
    }

    function writeToTab(tabName, message)
    {
	var pre = document.createElement("p");
	pre.style.wordWrap = "break-word";
	pre.style.border = "0px";
	pre.style.margin = '0px';
	pre.innerHTML = message;
	var tab = tabview.channels[tabName];
	if( tabview.get('selection') != tab )
	{
	    tab.updates += 1;
	    tab.set('label', '#' + tab.channelName + ' (' + tab.updates + ')');
	}
	tab.get('panelNode').one('.output').append(pre);
	pre.scrollIntoView(false);
    }

    initWebSocket();

    form.on('submit', function(evt) { 
	clickSubmit();
	evt.preventDefault();
    });

    Y.on('keydown', function(evt) { 
	
	if(evt.keyCode == 13)
	{
	    clickSubmit();
	    evt.preventDefault();
	}
    });

    Y.on('focus', function(e) { document.title=titleCache; messages=0; })
});


