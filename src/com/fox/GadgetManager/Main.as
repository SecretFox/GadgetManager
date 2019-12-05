import com.fox.GadgetManager.App

class com.fox.GadgetManager.Main {
	public static function main(swfRoot:MovieClip):Void {
		var s_app = new App(swfRoot);
		swfRoot.onLoad = function() {s_app.Load()};
		swfRoot.onUnload = function() {s_app.Unload()};
		swfRoot.OnModuleActivated = function(config) {s_app.Activate(config)};
		swfRoot.OnModuleDeactivated  = function() {return s_app.Deactivate()};
	}
}