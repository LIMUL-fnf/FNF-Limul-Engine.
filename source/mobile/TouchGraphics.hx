package mobile;

#if mobile
import openfl.display.BitmapData;
import openfl.display.Shape;

// Bitmap glyphs for the on-screen controls, drawn at startup so no extra art is needed.
class TouchGraphics
{
	public static function arrow(dir:Int):BitmapData
	{
		return make(56, 44, function(shape)
		{
			shape.graphics.beginFill(0xFFFFFF);
			switch (dir)
			{
				case 0: // left
					shape.graphics.moveTo(10, 22);
					shape.graphics.lineTo(46, 4);
					shape.graphics.lineTo(46, 40);
				case 1: // down
					shape.graphics.moveTo(28, 40);
					shape.graphics.lineTo(6, 4);
					shape.graphics.lineTo(50, 4);
				case 2: // up
					shape.graphics.moveTo(28, 4);
					shape.graphics.lineTo(6, 40);
					shape.graphics.lineTo(50, 40);
				default: // right
					shape.graphics.moveTo(46, 22);
					shape.graphics.lineTo(10, 4);
					shape.graphics.lineTo(10, 40);
			}
			shape.graphics.endFill();
		});
	}

	public static function circle(radius:Float):BitmapData
	{
		var size:Int = Std.int(radius * 2);
		return make(size, size, function(shape)
		{
			shape.graphics.beginFill(0xFFFFFF);
			shape.graphics.drawCircle(radius, radius, radius);
			shape.graphics.endFill();
		});
	}

	public static function bars():BitmapData
	{
		return make(13, 18, function(shape)
		{
			shape.graphics.beginFill(0xFFFFFF);
			shape.graphics.drawRect(0, 0, 5, 18);
			shape.graphics.drawRect(8, 0, 5, 18);
			shape.graphics.endFill();
		});
	}

	public static function check():BitmapData
	{
		return make(28, 28, function(shape)
		{
			shape.graphics.lineStyle(5, 0xFFFFFF, 1);
			shape.graphics.moveTo(4, 14);
			shape.graphics.lineTo(11, 21);
			shape.graphics.lineTo(24, 6);
		});
	}

	public static function cross():BitmapData
	{
		return make(28, 28, function(shape)
		{
			shape.graphics.lineStyle(5, 0xFFFFFF, 1);
			shape.graphics.moveTo(5, 5);
			shape.graphics.lineTo(23, 23);
			shape.graphics.moveTo(23, 5);
			shape.graphics.lineTo(5, 23);
		});
	}

	static function make(width:Int, height:Int, draw:Shape->Void):BitmapData
	{
		var shape = new Shape();
		draw(shape);
		var bitmap = new BitmapData(width, height, true, 0x00000000);
		bitmap.draw(shape);
		return bitmap;
	}
}
#end
