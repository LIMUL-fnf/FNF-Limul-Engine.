package mobile;

#if mobile
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.util.FlxColor;

/**
 * V-Slice style touch layer for phones and tablets: four full-height tap lanes
 * (LEFT / DOWN / UP / RIGHT, same order as the keyboard binds) plus a pause button.
 * Lane presses go through PlayState.touchPressLane/touchReleaseLane and are mirrored into
 * the NOTE_* actions (via Controls.addTouchInput), so hold notes behave like keyboard holds.
 */
class TouchControls extends FlxTypedGroup<FlxSprite>
{
	static inline var LANE_COUNT:Int = 4;
	static inline var ARROW_WIDTH:Int = 56;
	static inline var ARROW_HEIGHT:Int = 44;
	static inline var PAUSE_RADIUS:Float = 22;
	static inline var PAUSE_MARGIN:Float = 16;
	static inline var PAUSE_HIT_RADIUS:Float = 38;

	public var buttons:Array<TouchButton> = [];

	var play:PlayState;
	var laneWidth:Float;
	var laneTouch:Array<Int> = [];
	var laneHighlights:Array<FlxSprite> = [];
	var pauseTouch:Int = -1;
	var pauseButton:TouchButton;
	var pauseCenterX:Float;
	var pauseCenterY:Float;

	public function new(play:PlayState, cam:FlxCamera)
	{
		super();
		this.play = play;
		cameras = [cam];

		laneWidth = FlxG.width / LANE_COUNT;

		for (i in 0...LANE_COUNT)
		{
			var highlight = new FlxSprite(i * laneWidth, 0);
			highlight.makeGraphic(Std.int(laneWidth) + 1, Std.int(FlxG.height), FlxColor.WHITE);
			highlight.alpha = 0;
			highlight.scrollFactor.set();
			add(highlight);
			laneHighlights.push(highlight);
			laneTouch.push(-1);
			buttons.push(new TouchButton(i));

			var arrow = new FlxSprite(i * laneWidth + (laneWidth - ARROW_WIDTH) * 0.5, FlxG.height - ARROW_HEIGHT - 28);
			arrow.loadGraphic(TouchGraphics.arrow(i));
			arrow.alpha = 0.18;
			arrow.scrollFactor.set();
			add(arrow);

			if (i > 0)
			{
				var sep = new FlxSprite(i * laneWidth - 1, 0);
				sep.makeGraphic(2, Std.int(FlxG.height), FlxColor.WHITE);
				sep.alpha = 0.05;
				sep.scrollFactor.set();
				add(sep);
			}
		}

		pauseCenterX = FlxG.width - PAUSE_RADIUS - PAUSE_MARGIN;
		pauseCenterY = PAUSE_RADIUS + PAUSE_MARGIN;

		var pauseBg = new FlxSprite(pauseCenterX - PAUSE_RADIUS, pauseCenterY - PAUSE_RADIUS);
		pauseBg.loadGraphic(TouchGraphics.circle(PAUSE_RADIUS));
		pauseBg.alpha = 0.22;
		pauseBg.scrollFactor.set();
		add(pauseBg);

		var pauseBars = new FlxSprite(pauseCenterX - 6.5, pauseCenterY - 9);
		pauseBars.loadGraphic(TouchGraphics.bars());
		pauseBars.alpha = 0.6;
		pauseBars.scrollFactor.set();
		add(pauseBars);

		pauseButton = new TouchButton(LANE_COUNT);
	}

	override function update(elapsed:Float):Void
	{
		for (button in buttons)
			button.update();
		pauseButton.update();

		for (touch in FlxG.touches.list)
		{
			if (touch.justPressed)
			{
				var dx:Float = touch.screenX - pauseCenterX;
				var dy:Float = touch.screenY - pauseCenterY;
				if (dx * dx + dy * dy <= PAUSE_HIT_RADIUS * PAUSE_HIT_RADIUS)
				{
					pauseTouch = touch.touchPointID;
					pauseButton.press();
					play.touchPause();
				}
				else
				{
					var lane = Std.int(touch.screenX / laneWidth);
					if (lane >= 0 && lane < LANE_COUNT && laneTouch[lane] == -1)
						pressLane(lane, touch.touchPointID);
				}
			}
			else if (touch.justReleased)
			{
				var lane = laneOfTouch(touch.touchPointID);
				if (lane > -1) releaseLane(lane);

				if (pauseTouch == touch.touchPointID)
				{
					pauseTouch = -1;
					pauseButton.release();
				}
			}
		}

		// Safety net: a finger lifted while the state was paused (or a touch the manager
		// recycled early) must never leave a lane or the pause glyph stuck down.
		for (lane in 0...LANE_COUNT)
		{
			if (laneTouch[lane] == -1) continue;
			var touch = FlxG.touches.getByID(laneTouch[lane]);
			if (touch == null || touch.released) releaseLane(lane);
		}
		if (pauseTouch != -1)
		{
			var touch = FlxG.touches.getByID(pauseTouch);
			if (touch == null || touch.released)
			{
				pauseTouch = -1;
				pauseButton.release();
			}
		}

		super.update(elapsed);
	}

	function laneOfTouch(touchID:Int):Int
	{
		for (lane in 0...LANE_COUNT)
		{
			if (laneTouch[lane] == touchID) return lane;
		}
		return -1;
	}

	function pressLane(lane:Int, touchID:Int):Void
	{
		laneTouch[lane] = touchID;
		buttons[lane].press();
		laneHighlights[lane].alpha = 0.12;
		play.touchPressLane(lane);
	}

	function releaseLane(lane:Int):Void
	{
		laneTouch[lane] = -1;
		buttons[lane].release();
		laneHighlights[lane].alpha = 0;
		play.touchReleaseLane(lane);
	}
}
#end
