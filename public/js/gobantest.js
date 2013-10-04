YUI.GlobalConfig = 
    {
        filter: 'raw',
	modules:
	{
	    channeltab: '/js/channeltab.js',
	    usermodel: '/js/usermodel.js',
	    goban: '/js/goban.js'
	}
    };

YUI().use('goban', function(Y)
	{
	    //var renderer = new Y.Goban({srcNode: '#goban'});

	    var params = {},
	    pairs = location.search ? location.search.substring(1).split(/&/) : [],
	    i, keyval;
	    for (i = 0; i < pairs.length; i++) {
		keyval = pairs[i].split(/\=/);
		params[keyval[0]] = keyval[1];
	    }
	    window.player = new eidogo.Player({
		container:       "player-container",
		renderer:        Y.Goban,
		//theme:           "compact",
		sgfUrl:          "sgf/" + (params.sgf ? params.sgf : "example.sgf")
		//enableShortcuts: true
	    }); 

	    //renderer.player = window.player;
	});