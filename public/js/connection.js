ServerConnection.prototype.onOpen = function onOpen(self)
{
    return function(evt)
    {
	var name = prompt("Enter a nickname");
	self.Nick(name);

	self.Join("Earth");
	self.JoinLocal();
    };
}

ServerConnection.prototype.JoinLocal = function()
{
    if(navigator.geolocation)
    {
	var self = this;
	
	navigator.geolocation.getCurrentPosition( 
	    function (pos) {
		var latlng = new google.maps.LatLng(pos.coords.latitude, pos.coords.longitude);
		var geocoder = new google.maps.Geocoder();
		geocoder.geocode({'latLng': latlng}, function(results, status) {
		    if (status == google.maps.GeocoderStatus.OK) {
			if( results.length > 0 )
			{
			    for( var i=results.length-1; i>=0; i--)
			    {
				if( ( results[i].types.indexOf("locality") != -1 && results[i].types.indexOf("political") != -1) ||
				    ( results[i].types.indexOf("administrative_area_level_1") != -1 && results[i].types.indexOf("political") != -1) ||
				    ( results[i].types.indexOf("country") != -1 && results[i].types.indexOf("political") != -1) )
				{
				    self.Join(results[i].formatted_address);
				}
			    }
			}
		    }
		});
	    }
	);
    }
}

ServerConnection.prototype.onClose = function(self)
{
    return function(evt)
    {
    };
}

ServerConnection.prototype.onMessage = function(self)
{
    return function (evt)
    {
	var msg = JSON.parse(evt.data);
	if(typeof(self.handlers[msg[0]]) != 'undefined') 
	{
	    self.handlers[msg[0]].apply(this, msg.slice(1,msg.length));
	} 
    };
}

ServerConnection.prototype.onError = function(self)
{
    return function(evt)
    {
	//writeToScreen('<span style="color: red;">ERROR:' + evt.data + '</span> ');
    };
}

ServerConnection.prototype.doSend = function(message)
{
    this.websocket.send(JSON.stringify(message));
}

function ServerConnection(wsUri, inProtocol) 
{
    this.websocket = new WebSocket(wsUri);
    this.handlers = inProtocol;

    this.websocket.onopen = this.onOpen(this);
    this.websocket.onclose = this.onClose(this);
    this.websocket.onmessage =  this.onMessage(this);
    this.websocket.onerror = this.onError(this);
}