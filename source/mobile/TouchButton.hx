package mobile;

#if mobile
import flixel.input.FlxInput;
import flixel.input.IFlxInput;

// Minimal IFlxInput wrapper over FlxInput<Int>, the same pattern flixel uses for FlxButton.
class TouchButton implements IFlxInput
{
	public var justPressed(get, never):Bool;
	public var pressed(get, never):Bool;
	public var justReleased(get, never):Bool;
	public var released(get, never):Bool;

	var input:FlxInput<Int>;

	public function new(id:Int)
	{
		input = new FlxInput(id);
	}

	public inline function press():Void
		input.press();

	public inline function release():Void
		input.release();

	public inline function update():Void
		input.update();

	inline function get_justPressed():Bool
		return input.justPressed;

	inline function get_pressed():Bool
		return input.pressed;

	inline function get_justReleased():Bool
		return input.justReleased;

	inline function get_released():Bool
		return input.released;
}
#end
