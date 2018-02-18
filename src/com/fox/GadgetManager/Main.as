import com.fox.GadgetManager.App

class com.fox.GadgetManager.Main
{
	private static var s_app:App;
	
	public static function main(swfRoot:MovieClip):Void
	{
		s_app = new App(swfRoot);
		swfRoot.onLoad = OnLoad;
		swfRoot.OnModuleActivated = OnActivated;
		swfRoot.OnModuleDeactivated = OnDeactivated;
	}

	public function Main() { }
	
	public static function OnLoad()
	{
		s_app.Load();
	}
	public static function OnActivated()
	{
		s_app.Activate();
	}

	public static function OnDeactivated()
	{
		s_app.Deactivate();
	}
}