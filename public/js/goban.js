YUI.add('goban', 
	function(Y) {
	    function Goban() {
		this.init.apply(this, arguments);
	    }
	    Goban.NAME = "Goban"
	    Goban.ATTRS = {
		boardSize: {value: 19},
		stoneSize: {value:20}
	    };
	    Y.extend(Goban, Y.Widget, {
		init: function(domContainer, boardSize, player, crop) {
		    if(typeof player == 'undefined') return;
		    this.player = player;
		    this.boardSize = parseInt(boardSize);
		    
		    Goban.superclass.constructor.apply(this, arguments);

		    this.Graphics = new Y.Graphic({
			render: domContainer,
			autoSize: 'sizeGraphicToContent',
		    });
		    this.srcNode = Y.one(domContainer);

		    this.set('boardSize', boardSize || 19);
		    this.set('stoneSize', 20);

		    this.boardSize = this.get('boardSize');
		    
		    Y.one(document).on('windowresize', this.resizeBoard, this );

		    //Y.Node(this.Graphics.get('node')).on('dblclick', this.handleDblClick, this);
		    
		    Y.one(this.Graphics.get('node')).on('mousedown', this.handleMouseDown, this);
		    Y.one(this.Graphics.get('node')).on('mouseover', this.handleHover, this);
		    Y.one(this.Graphics.get('node')).on('mouseup', this.handleMouseUp, this);

		    this.renderCache = {
			stones: [].setLength(boardSize * boardSize, 0)
		    }
		    this.resizeBoard();  //resize it for the first time... (heh..)
		},
		getXY: function(evt)
		{
		    var stoneSize = this.get('stoneSize');
		    var XY = this.Graphics.getXY();
		    var stoneX = Math.floor( (evt.pageX - XY[0])/stoneSize );
		    var stoneY = Math.floor( (evt.pageY - XY[1])/stoneSize );
		    return [stoneX, stoneY, evt.pageX, evt.pageY];
		},
		resizeBoard: function()
		{
		    var rect = this.srcNode.get('region');
		    var totalWidth = Math.min(rect.width, rect.height);
		    var stoneSize = Math.floor(totalWidth / this.get('boardSize'));
		    this.set('stoneSize', stoneSize);
		    this.Graphics.set('height', totalWidth);
		    this.Graphics.set('width', totalWidth);
		    this.redrawBoard();
		},
		redrawBoard: function()
		{
		    this.Graphics.clear();
		    var boardSize = this.get('boardSize');
		    var stoneSize = this.get('stoneSize');

		    var bgRect = this.Graphics.addShape({
			type: Y.Rect,
			fill: { color: "#FFFFCC" },
			x: 0,
			y: 0,
			height: boardSize * stoneSize,
			width: boardSize * stoneSize,
		    });
		    

		    var myPath = this.Graphics.addShape({
			type: Y.Path,
			fill: {
			    color: "#9aa"
			},
			stroke: {
			    weight: 1,
			    color: "#000"
			}
		    });
		    
		    for(var i = 0.5; i<=boardSize; i++)
		    {
			myPath.moveTo(stoneSize*i,
				      stoneSize/2);
			myPath.lineTo(stoneSize*i,
				      (boardSize-0.5)*stoneSize );
			myPath.moveTo(stoneSize/2,   
				      stoneSize*i );
			myPath.lineTo( (boardSize-0.5)*stoneSize,
				       i*stoneSize);
		    }

		    var renderedStones = this.renderCache.stones;
		    for( var i = 0; i < renderedStones.length; i++)
		    {
			if(renderedStones[i])
			{
			    this.renderStone({x: i%boardSize, y:Math.floor(i/boardSize)}, renderedStones[i].get('fill').color);
			}
		    }

		    myPath.end();

		},
		clear: function()
		{
		    
		    redrawBoard();
		},
		renderStone: function(pt, color)
		{
		    var boardSize = this.get('boardSize');
		    var stoneSize = this.get('stoneSize');
		    if(color == 'empty' )	
		    {
			if( this.renderCache.stones[pt.x + pt.y*boardSize] )
			{
			    //alert(this.renderCache.stones[pt.x + pt.y*boardSize] );
			    this.Graphics.removeShape(this.renderCache.stones[pt.x + pt.y*boardSize])
			    this.renderCache.stones[pt.x + pt.y*boardSize] = 0;
			}
		    } else
		    {
			var bgRect = this.Graphics.addShape({
			    type: Y.Circle,
			    radius: stoneSize/2*.95,
			    fill: {
				color: color
			    },
			    stroke: {
				weight: 1,
				color: "black"
			    },
			    x: stoneSize*pt.x,
			    y: stoneSize*pt.y
			});

			this.renderCache.stones[pt.x + pt.y*boardSize] = bgRect;
		    }
		    return null;
		},
		renderMarker: function(pt, type) {
		    /*if (this.renderCache.markers[pt.x][pt.y]) {
		      var marker = document.getElementById(this.uniq + "marker-" + pt.x + "-" + pt.y);
		      if (marker) {
		      marker.parentNode.removeChild(marker);
		      }
		      }
		      if (type == "empty" || !type) { 
		      this.renderCache.markers[pt.x][pt.y] = 0;
		      return null;
		      }
		      this.renderCache.markers[pt.x][pt.y] = 1;
		      if (type) {
		      var text = "";
		      switch (type) {
		      case "triangle":
		      case "square":
		      case "circle":
		      case "ex":
		      case "territory-white":
		      case "territory-black":
		      case "dim":
		      case "current":
		      break;
		      default:
		      if (type.indexOf("var:") == 0) {
		      text = type.substring(4);
		      type = "variation";
		      } else {
		      text = type;
		      type = "label";
		      }
		      break;
		      }
		      var div = document.createElement("div");
		      div.id = this.uniq + "marker-" + pt.x + "-" + pt.y;
		      div.className = "point marker " + type;
		      try {
		      div.style.left = (pt.x * this.pointWidth + this.margin - this.scrollX) + "px";
		      div.style.top = (pt.y * this.pointHeight + this.margin - this.scrollY) + "px";
		      } catch (e) {}
		      div.appendChild(document.createTextNode(text));
		      this.domNode.appendChild(div);
		      return div;
		      }*/
		    return null;
		},

		setCursor: function(cursor) {
		    this.srcNode.setStyle('cursor', cursor);
		},
		handleHover: function(e) {
		    var xy = this.getXY(e);
		    this.player.handleBoardHover(xy[0], xy[1], xy[2], xy[3], e);
		},
		handleMouseDown: function(e) {
		    var xy = this.getXY(e);
		    this.player.handleBoardMouseDown(xy[0], xy[1], xy[2], xy[3], e);
		},
		handleMouseUp: function(e) {
		    var xy = this.getXY(e);
		    this.player.handleBoardMouseUp(xy[0], xy[1]);
		},
		showRegion: function(bounds) {
		    return null;
		},
		hideRegion: function() { 
		    return null;
		},
		crop: function(crop) {
		    return null;
		}
	    });
	    
	    Y.Goban = Goban;
	}, 
	'1.0.0',
	{ requires: [ 'graphics', 'widget', 'event'  ] });