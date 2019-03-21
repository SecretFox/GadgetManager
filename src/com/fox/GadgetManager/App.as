import com.GameInterface.DistributedValue;
import com.GameInterface.DistributedValueBase;
import com.GameInterface.Game.CharacterBase;
import com.GameInterface.Game.Character;
import com.GameInterface.InventoryItem;
import com.GameInterface.Tooltip.TooltipDataProvider;
import com.Utils.Colors;
import com.Utils.Draw;
import com.Utils.Format;
import mx.utils.Delegate;
import com.Utils.ID32;
import com.GameInterface.Inventory;
import com.GameInterface.Tooltip.TooltipData;
import com.GameInterface.Tooltip.TooltipInterface;
import com.GameInterface.Tooltip.TooltipManager;

class com.fox.GadgetManager.App {
	private var m_swfRoot:MovieClip;
	private var m_IconLoader:MovieClipLoader;
	private var GadgetPosition:Object
	private var m_MovieClips:Array;
	private var m_Gadgets:Array;
	private var WeaponID32:ID32;
	private var WeaponInventory:Inventory;
	private var PlayerID32:ID32;
	private var PlayerInventory:Inventory;
	private var Tooltip:TooltipInterface;
	private var m_Resize:DistributedValue;
	private var m_MoveX:DistributedValue;
	private var m_MoveY:DistributedValue;
	private var Arrow:MovieClip;
	private var GadgetContainer:MovieClip
	private var m_BG:MovieClip

	public function App(swfRoot: MovieClip) {
		m_swfRoot = swfRoot;
	}

	public function Load() {
		PlayerID32 = new ID32(_global.Enums.InvType.e_Type_GC_BackpackContainer, ((Character.GetClientCharacter()).GetID()).GetInstance());
		PlayerInventory = new Inventory(PlayerID32)
		WeaponID32 = new ID32(_global.Enums.InvType.e_Type_GC_WeaponContainer, ((Character.GetClientCharacter()).GetID()).GetInstance());
		WeaponInventory = new Inventory(WeaponID32)
		m_Resize = DistributedValue.Create("AbilityBarScale");
		m_Resize.SignalChanged.Connect(Reposition, this);
		m_MoveX = DistributedValue.Create("AbilityBarX");
		m_MoveX.SignalChanged.Connect(Reposition, this);
		m_MoveY = DistributedValue.Create("AbilityBarY");
		m_MoveY.SignalChanged.Connect(Reposition, this);
		CharacterBase.SignalCharacterEnteredReticuleMode.Connect(Destroy, this);
	}
	
	public function Unload() {
		m_Resize.SignalChanged.Disconnect(Reposition, this);
		m_MoveX.SignalChanged.Disconnect(Reposition, this);
		m_MoveY.SignalChanged.Disconnect(Reposition, this);
		CharacterBase.SignalCharacterEnteredReticuleMode.Disconnect(Destroy, this);
		Destroy();
	}
	
	public function Activate() {
		if (!Arrow && _root.abilitybar.m_GadgetSlot) Reposition();
		else if (!Arrow) setTimeout(Delegate.create(this, Activate), 50);
	}
	
	private function Reposition(){
		Arrow.removeMovieClip();
		DrawArrow();
		Destroy();
	}

	private function DrawArrow() {
		GadgetPosition = {x:_root.abilitybar.m_GadgetSlot._x, y:_root.abilitybar.m_GadgetSlot._y};
		_root.abilitybar.localToGlobal(GadgetPosition);
		Arrow = m_swfRoot.attachMovie("src.assets.arrow.png", "Arrow", m_swfRoot.getNextHighestDepth());
		// Bad scaling
		
		var scalingFactor = DistributedValueBase.GetDValue("AbilityBarScale") / 100
		var org = Arrow._width
		Arrow._x = GadgetPosition.x + _root.abilitybar.m_GadgetSlot._width/8*scalingFactor;
		Arrow._xscale *= scalingFactor * 0.75;
		Arrow._yscale = Arrow._xscale * 0.6;
		Arrow._y = GadgetPosition.y - Arrow._height - 4*scalingFactor;



		Arrow.onPress = Delegate.create(this, function() {
			if (this.GadgetContainer){
				this.Destroy();
			}else{
				this.Start();
			}
		});
	}

	private function Start() {
		m_MovieClips = new Array();
		GadgetContainer = m_swfRoot.createEmptyMovieClip("m_Gadgets", m_swfRoot.getNextHighestDepth());
		m_BG = GadgetContainer.createEmptyMovieClip("m_BG", GadgetContainer.getNextHighestDepth());
		GetGadgets();
		DrawGadgets();
	}

	private function DrawGadgets() {
		var gadget = m_Gadgets.pop();
		if (gadget){
			DrawIcon(gadget);
		} else{
			// Could draw the BG after each gadget,but it looks alright like this
			m_BG.clear();
			Draw.DrawRectangle(m_BG,
			m_MovieClips[0]._x - m_MovieClips[0]._width / 4,
			Arrow._y - GadgetContainer._height - m_MovieClips[0]._height/4 ,
			GadgetContainer._width + m_MovieClips[0]._width/2,
			GadgetContainer._height + m_MovieClips[0]._height/4,
			0x000000, 70, [4, 4, 4, 4],
			1, 0xFFFFFF, 0, true, false)
		}
	}

	public function DrawIcon(Gadget:InventoryItem) {
		var m_Container:MovieClip = GadgetContainer.createEmptyMovieClip("m_" + Gadget.m_Name+"_"+Gadget.m_ACGItem.m_TemplateID0, GadgetContainer.getNextHighestDepth());
		var m_BackGround = m_Container.attachMovie("GadgetBackground", "m_Background", m_Container.getNextHighestDepth());
		var m_Stroke = m_Container.attachMovie("GadgetStroke", "m_stroke", m_Container.getNextHighestDepth());
		var m_Icon = m_Container.createEmptyMovieClip("m_Icon", m_Container.getNextHighestDepth());
		m_Icon._xscale = m_Stroke._width - 4;
		m_Icon._yscale = m_Stroke._width - 4;
		m_Container._x = Arrow._x + Math.floor(m_MovieClips.length / 10) * (m_Container._width+2);
		m_Container._y = Arrow._y - (10-(m_MovieClips.length % 10)) * (m_Container._height+2) ;
		m_Icon._x = 1;
		m_Icon._y = 2;

		var mclistener:Object = new Object();
		mclistener.onLoadComplete = Delegate.create(this, DrawGadgets);
		m_IconLoader  = new MovieClipLoader();
		m_IconLoader.addListener( mclistener );
		var icon:com.Utils.ID32 = Gadget.m_Icon;
		var iconString:String = Format.Printf( "rdb:%.0f:%.0f", icon.GetType(), icon.GetInstance() );
		m_IconLoader.loadClip( iconString, m_Icon );
		if (!Gadget["equipped"]){
			Colors.ApplyColor( m_BackGround, 0x1B1B1B);
			m_Container.onPress = Delegate.create(this, function() {
				this.WeaponInventory.AddItem(this.PlayerID32, Gadget.m_InventoryPos, -1);
				this.Destroy()
			});
		}
		else Colors.ApplyColor( m_BackGround, 0x17A003);
		Colors.ApplyColor( m_Stroke, Colors.GetItemRarityColor(Gadget.m_Rarity));
		m_Container.onRollOver = Delegate.create(this, function() {
			this.Tooltip.Close();
			var m_TooltipData:TooltipData = TooltipDataProvider.GetACGItemTooltip(Gadget.m_ACGItem, Gadget.m_Rank);
			m_TooltipData.m_Title = "<font size='13'>" + Gadget.m_Name+ "</font>";
			m_TooltipData.m_Color = Colors.GetItemRarityColor(Gadget.m_Rarity);
			this.Tooltip = TooltipManager.GetInstance().ShowTooltip(undefined, TooltipInterface.e_OrientationVertical, 0.1, m_TooltipData);
		});
		m_Container.onRollOut = Delegate.create(this, function() {
			this.Tooltip.Close();
		});
		m_MovieClips.push(m_Container);
	}

	public function Destroy() {
		for (var clip in m_MovieClips) {
			m_MovieClips[clip].removeMovieClip();
		}
		m_MovieClips = new Array();
		Tooltip.Close();
		GadgetContainer.removeMovieClip();
		m_BG.removeMovieClip();
	}

	private function GetGadgets() {
		m_Gadgets = new Array();
		var inventorySize = PlayerInventory.GetMaxItems();
		for (var counter:Number = 0; counter < inventorySize ; counter++) {
			var item:InventoryItem = PlayerInventory.GetItemAt(counter);
			if (item.m_RealType == 30050 && item.m_IsBoundToPlayer) {
				m_Gadgets.push(item);
			}
		}
		var gadget = _root.abilitybar_3_.m_GadgetSlot.m_GadgetItem;
		if (gadget){
			gadget.equipped = true;
			m_Gadgets.push(gadget);
		}
		m_Gadgets.sortOn(["m_Rarity","m_Name"],[Array.NUMERIC | Array.CASEINSENSITIVE, Array.DESCENDING]);
	}
}