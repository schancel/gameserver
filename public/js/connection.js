ServerConnection.prototype.onOpen = function onOpen(self)
{
    return function(evt)
    {
	var name = prompt("Enter a nickname");
	//self.Nick(name);

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
        var data = new Uint8Array(evt.data);
	var msg = msgpack.unpack(data.subarray(1));
	if(typeof(self.handlers[data[0]]) != 'undefined') 
	{
	    self.handlers[data[0]].apply(this, msg);
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

ServerConnection.prototype.doSend = function(type, message)
{
    var i ;var packed = []
    packed = msgpack.pack(message);
    var foo = new Uint8Array(packed.length+1);
    foo[0] = type || 0; //TODO: get message type;
    foo.set(packed,1);

    this.websocket.send(foo);
}

function ServerConnection(wsUri, inProtocol) 
{
    this.websocket = new WebSocket(wsUri);
    this.handlers = inProtocol;
    this.websocket.binaryType = "arraybuffer";

    this.websocket.onopen = this.onOpen(this);
    this.websocket.onclose = this.onClose(this);
    this.websocket.onmessage =  this.onMessage(this);
    this.websocket.onerror = this.onError(this);
}