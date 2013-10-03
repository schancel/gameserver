YUI.add('usermodel', 
	function(Y)	{		     
	    Y.UserModel = Y.Base.create('userModel', Y.Model, [], 
					{
					    idAttribute: 'Username',
					}, { 
					    ATTRS:  {
						Username: { 
						    value: null
						}, 
						Rank: 
						{
						    value: "5d"
						},
						DisplayName:
						{
						    valueFn:
						    function()
						    {
							return this.get('Username') + this.get('Rank')
						    }
						}
					    }
					} ); 
	}, 
	'1.0.0',
	{ requires: ['model' ] });