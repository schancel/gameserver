module user.title;

class Title {

	this(int id, string text, boolean unique)
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
	private String text;
	private boolean unique;
	
	public int getId()
	{
		return id;
	}
	
	public string getText()
	{
		return text;
	}
	
	public boolean isUnique()
	{
		return unique;
	}
}

