module user.title;

class Title {

	this(int id, string text, bool unique)
	{
		this.id = id;
		this.text = text;
		this.unique = unique;
		
		if(currentId < id){
			currentId = id;
		}
	}
	
	private static int currentId;

	public static int getNewId(){
		return ++currentId;
	}
	
	private int id;
	private string text;
	private bool unique;
	
	@property public int getId()
	{
		return id;
	}
	
    @property  public bool isUnique()
	{
		return unique;
	}

    override string toString()
    {
        return text;
    }
}

