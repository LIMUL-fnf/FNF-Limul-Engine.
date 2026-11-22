package mobile;

#if mobile
import Controls;
import Controls.Action;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.util.FlxColor;
import openfl.display.BitmapData;

/**
 * On-screen menu pad for phones and tablets. The menus are keyboard driven, so these buttons
 * feed the same Controls UI actions (left/down/up/right/accept/back); keyboard and gamepad keep
 * working alongside. Added by MusicBeatState/MusicBeatSubstate to every menu, never in PlayState,
 * which has its own V-Slice style lane touch controls.
 */
class MobileMenuControls extends FlxTypedGroup<FlxSprite>
{
	static inline var BUTTON_W:Int = 76;
	static inline var BUTTON_H:Int = 76;
	static inline var GAP:Float = 12;
	static inline var MARGIN:Float = 18;
	static inline var BG_ALPHA:Float = 0.14;
	static inline var BG_ALPHA_PRESSED:Float = 0.30;
	static inline var GLYPH_ALPHA:Float = 0.55;

	public var buttons:Array<TouchButton> = [];

	var controls:Controls;
	var widgets:Array<MenuWidget> = [];

	public function new(controls:Controls)
	{
		super();
		this.controls = controls;

		var camerasList = FlxG.cameras.list;
		cameras = [camerasList[camerasList.length - 1]];

		var bottomY:Float = FlxG.height - BUTTON_H - MARGIN;
		var colLeft:Float = MARGIN;
		var colMid:Float = MARGIN + BUTTON_W + GAP;
		var colRight:Float = MARGIN + (BUTTON_W + GAP) * 2;
		var acceptX:Float = FlxG.width - MARGIN - BUTTON_W;
		var backX:Float = acceptX - BUTTON_W - GAP;

		addWidget(Action.UI_UP, TouchGraphics.arrow(2), colMid, bottomY - BUTTON_H - GAP);
		addWidget(Action.UI_LEFT, TouchGraphics.arrow(0), colLeft, bottomY);
		addWidget(Action.UI_DOWN, TouchGraphics.arrow(1), colMid, bottomY);
		addWidget(Action.UI_RIGHT, TouchGraphics.arrow(3), colRight, bottomY);
		addWidget(Action.BACK, TouchGraphics.cross(), backX, bottomY);
		addWidget(Action.ACCEPT, TouchGraphics.check(), acceptX, bottomY);
	}

	override function update(elapsed:Float):Void
	{
		for (button in buttons)
			button.update();

		for (touch in FlxG.touches.list)
		{
			if (touch.justPressed)
			{
				for (widget in widgets)
				{
					if (widget.touchID != -1) continue;
					if (touch.screenX >= widget.x && touch.screenX <= widget.x + BUTTON_W
						&& touch.screenY >= widget.y && touch.screenY <= widget.y + BUTTON_H)
					{
						widget.touchID = touch.touchPointID;
						widget.button.press();
						widget.bg.alpha = BG_ALPHA_PRESSED;
						break;
					}
				}
			}
			else if (touch.justReleased)
			{
				for (widget in widgets)
				{
					if (widget.touchID == touch.touchPointID) releaseWidget(widget);
				}
			}
		}

		// Safety net for touches the manager recycled early or that ended while another
		// substate had the update loop (see releaseAll()).
		for (widget in widgets)
		{
			if (widget.touchID == -1) continue;
			var touch = FlxG.touches.getByID(widget.touchID);
			if (touch == null || touch.released) releaseWidget(widget);
		}

		super.update(elapsed);
	}

	public function releaseAll():Void
	{
		for (widget in widgets)
		{
			if (widget.touchID != -1) releaseWidget(widget);
		}
	}

	function releaseWidget(widget:MenuWidget):Void
	{
		widget.touchID = -1;
		widget.button.release();
		widget.bg.alpha = BG_ALPHA;
	}

	function addWidget(action:Action, glyph:BitmapData, x:Float, y:Float):Void
	{
		var bg = new FlxSprite(x, y);
		bg.makeGraphic(BUTTON_W, BUTTON_H, FlxColor.WHITE);
		bg.alpha = BG_ALPHA;
		bg.scrollFactor.set();
		add(bg);

		var icon = new FlxSprite(x + (BUTTON_W - glyph.width) * 0.5, y + (BUTTON_H - glyph.height) * 0.5);
		icon.loadGraphic(glyph);
		icon.alpha = GLYPH_ALPHA;
		icon.scrollFactor.set();
		add(icon);

		var button = new TouchButton(buttons.length);
		buttons.push(button);
		controls.addTouchUIInput(this, action, button);
		widgets.push(new MenuWidget(button, bg, x, y));
	}

	override function destroy():Void
	{
		controls.removeTouchInputs(this);
		super.destroy();
	}
}

class MenuWidget
{
	public var button(default, null):TouchButton;
	public var bg(default, null):FlxSprite;
	public var x(default, null):Float;
	public var y(default, null):Float;
	public var touchID:Int = -1;

	public function new(button:TouchButton, bg:FlxSprite, x:Float, y:Float)
	{
		this.button = button;
		this.bg = bg;
		this.x = x;
		this.y = y;
	}
}
#end
