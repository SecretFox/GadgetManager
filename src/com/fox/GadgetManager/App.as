import com.GameInterface.Game.CharacterBase;
import com.GameInterface.Game.Character;
import com.GameInterface.InventoryItem;
import com.GameInterface.Tooltip.TooltipDataProvider;
import com.Utils.Colors;
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
	private var m_Size:Number
	private var m_MovieClips:Array;
	private var m_Gadgets:Array;
	private var WeaponID32:ID32;
	private var WeaponInventory:Inventory;
	private var PlayerID32:ID32;
	private var PlayerInventory:Inventory;
	static var RarityColours = new Array(0xFFFFFF, 0x00ff16, 0x02b6ff, 0xd565f8, 0xF29F05, 0xE62738);
	private var open:Boolean;
	private var Tooltip:TooltipInterface;
	private var DestroyFunction:Function;

	public function App(swfRoot: MovieClip) {
		m_swfRoot = swfRoot;
	}

	public function Load() {
		PlayerID32 = new ID32(_global.Enums.InvType.e_Type_GC_BackpackContainer, ((Character.GetClientCharacter()).GetID()).GetInstance());
		PlayerInventory = new Inventory(PlayerID32)
		WeaponID32 = new ID32(_global.Enums.InvType.e_Type_GC_WeaponContainer, ((Character.GetClientCharacter()).GetID()).GetInstance());
		WeaponInventory = new Inventory(WeaponID32)
		open = false;
		DestroyFunction = Delegate.create(this, Destroy);

	}

	public function Activate() {
		if (_root.abilitybar.m_GadgetSlot && !m_swfRoot.Arrow) {
			m_Size = _root.abilitybar.m_GadgetSlot._height;
			DrawArrow();
			CharacterBase.SignalCharacterEnteredReticuleMode.Connect(Destroy,this);
		} else if (!m_swfRoot.Arrow) {
			setTimeout(Delegate.create(this, Activate), 50);
		}
	}

	private function DrawArrow() {
		GadgetPosition = {x:_root.abilitybar.m_GadgetSlot._x, y:_root.abilitybar.m_GadgetSlot._y};
		_root.abilitybar.localToGlobal(GadgetPosition);
		var Arrow:MovieClip = m_swfRoot.attachMovie("src.assets.arrow.png", "Arrow", m_swfRoot.getNextHighestDepth(), {_x:GadgetPosition.x});
		Arrow._y = GadgetPosition.y - Arrow._height;
		Arrow._width = _root.abilitybar.m_GadgetSlot._width;

		Arrow.onPress = Delegate.create(this, function() {
			if (this.open) {
				this.open = false;
				this.Destroy();
			} else {
				this.open = true;
				this.Start();
			}
		});
	}

	private function Start() {
		GadgetPosition = {x:_root.abilitybar.m_GadgetSlot._x, y:_root.abilitybar.m_GadgetSlot._y - 20};
		_root.abilitybar.localToGlobal(GadgetPosition);
		m_MovieClips = new Array();
		GetGadgets();
		DrawGadgets();
	}

	private function DrawGadgets() {
		GadgetPosition.y -= m_Size+5;
		var gadget = m_Gadgets.pop();
		DrawIcon(gadget);
	}

	public function DrawIcon(Gadget:InventoryItem) {
		if (Gadget) {
			var m_Container:MovieClip = m_swfRoot.createEmptyMovieClip("m_" + Gadget.m_Name+"_"+Gadget.m_ACGItem.m_TemplateID0, m_swfRoot.getNextHighestDepth());
			m_Container._x = GadgetPosition.x;
			m_Container._y = GadgetPosition.y;

			var m_BackGround = m_Container.attachMovie("GadgetBackground", "m_Background", m_Container.getNextHighestDepth());
			var m_Stroke = m_Container.attachMovie("GadgetStroke", "m_stroke", m_Container.getNextHighestDepth());
			var m_Icon = m_Container.createEmptyMovieClip("m_Icon", m_Container.getNextHighestDepth());
			m_Icon._xscale = m_Size;
			m_Icon._yscale = m_Size;
			m_Icon._x = 1;
			m_Icon._y = 2;

			var mclistener:Object = new Object();
			//timeout creates a nice cascading effect
			mclistener.onLoadComplete = setTimeout(Delegate.create(this, DrawGadgets),50);
			m_IconLoader  = new MovieClipLoader();
			m_IconLoader.addListener( mclistener );
			var icon:com.Utils.ID32 = Gadget.m_Icon;
			var iconString:String = Format.Printf( "rdb:%.0f:%.0f", icon.GetType(), icon.GetInstance() );
			m_IconLoader.loadClip( iconString, m_Icon );
			Colors.ApplyColor( m_BackGround, 0x1B1B1B);
			Colors.ApplyColor( m_Stroke, RarityColours[Gadget.m_Rarity - 1]);
			m_Container.onPress = Delegate.create(this, function() {
				this.WeaponInventory.AddItem(this.PlayerID32, Gadget.m_InventoryPos, -1);
				this.DestroyFunction();
			});
			m_Container.onRollOver = Delegate.create(this, function() {
				this.Tooltip.Close();
				var m_TooltipData:TooltipData = TooltipDataProvider.GetACGItemTooltip(Gadget.m_ACGItem, Gadget.m_Rank);
				m_TooltipData.m_Title = "<font size='13'>" + Gadget.m_Name+ "</font>";
				m_TooltipData.m_Color = this.RarityColours[Gadget.m_Rarity - 1];
				this.Tooltip = TooltipManager.GetInstance().ShowTooltip(undefined, TooltipInterface.e_OrientationVertical, 0.1, m_TooltipData);
			});
			m_Container.onRollOut = Delegate.create(this, function() {
				this.Tooltip.Close();
			});
			m_MovieClips.push(m_Container);
		}
	}

	public function Destroy() {
		for (var clip in m_MovieClips) {
			m_MovieClips[clip].removeMovieClip();
		}
		this.Tooltip.Close();
		open = false;
	}

	public function Deactivate() {
		CharacterBase.SignalCharacterEnteredReticuleMode.Disconnect(Destroy, this);
		Destroy();
	}

	private function GetGadgets() {
		m_Gadgets = new Array();
		var inventorySize = PlayerInventory.GetMaxItems();
		for (var counter:Number = 0; counter < inventorySize ; counter++) {
			var item:InventoryItem = PlayerInventory.GetItemAt(counter);
			if (item.m_RealType == 30050 && item.m_IsBoundToPlayer == true) {
				m_Gadgets.push(item);
			}
		}
		m_Gadgets.sortOn("m_Rarity",Array.DESCENDING);
		//10 gadgets max should do?
		m_Gadgets.splice(10);
		m_Gadgets.sortOn("m_Rarity");
	}
}