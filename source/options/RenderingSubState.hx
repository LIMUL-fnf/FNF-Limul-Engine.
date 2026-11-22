package options;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;

class RenderingSubState extends BaseOptionsMenu
{
	public function new()
	{
		title = 'Graphics';
		rpcTitle = 'Graphics Settings Menu'; //for Discord Rich Presence

		var option:Option = new Option('Low Quality',
			'If checked, disables some background details,\ndecreases loading times and improves performance.',
			'lowQuality',
			'bool',
			false);
		option.onChange = onChangeLowQuality;
		addOption(option);

		var option:Option = new Option('Anti-Aliasing',
			'If unchecked, disables anti-aliasing, increases performance\nat the cost of sharper visuals.',
			'globalAntialiasing',
			'bool',
			true);
		option.showBoyfriend = true;
		option.onChange = onChangeAntiAliasing;
		addOption(option);

		var option:Option = new Option('Shaders',
			'If unchecked, disables shaders.\nIt\'s used for some visual effects, and also CPU intensive for weaker PCs.',
			'shaders',
			'bool',
			true);
		addOption(option);

		var option:Option = new Option('GPU Caching',
			"If checked, allows the GPU to be used for caching textures, decreasing RAM usage.\nDon't turn this on if you have a shitty Graphics Card.",
			'cacheOnGPU',
			'bool',
			true);
		addOption(option);

		#if !html5
		#if desktop
		var option:Option = new Option('Resolution: ',
			'What resolution do you want the game to run in?',
			'resolution',
			'string',
			'1280x720',
			['16x9','32x18','64x36','128x72','214x120','256x144','480x270','640x360','960x540','1280x720','1920x1080','2560x1440','3840x2160']);
		addOption(option);
		option.onChange = onChangeResolution;
		#end

		var option:Option = new Option('Framerate',
			"Pretty self explanatory, isn't it?",
			'framerate',
			'int',
			60);
		addOption(option);

		option.minValue = 60;
		option.maxValue = 1000;
		option.displayFormat = '%v FPS';
		option.onChange = onChangeFramerate;

		#if desktop
		var option:Option = new Option('V-Sync',
			"Syncs frames to your monitor's refresh rate to remove screen tearing.\nTakes effect after restarting the game.",
			'vsync',
			'bool',
			false);
		addOption(option);
		option.onChange = ClientPrefs.writeVsyncBootFlag;
		#end
		#end

		super();
	}

	function onChangeAntiAliasing()
	{
		FlxSprite.defaultAntialiasing = ClientPrefs.globalAntialiasing;
		for (sprite in members)
		{
			var sprite:Dynamic = sprite;
			var sprite:FlxSprite = sprite;
			if(sprite != null && (sprite is FlxSprite) && !(sprite is FlxText)) {
				sprite.antialiasing = ClientPrefs.globalAntialiasing;
			}
		}
	}

	function onChangeLowQuality()
	{
		ClientPrefs.applyPerformanceSettings();
	}

	function onChangeResolution()
	{
		var resolutionValue:String = ClientPrefs.resolution;
		if (resolutionValue == null) return;
		var parts:Array<String> = resolutionValue.split('x');
		if (parts.length != 2) return;
		var width:Null<Int> = Std.parseInt(parts[0]);
		var height:Null<Int> = Std.parseInt(parts[1]);
		if (width == null || height == null || width < 1 || height < 1) return;
		FlxG.resizeGame(width, height);
		lime.app.Application.current.window.width = width;
		lime.app.Application.current.window.height = height;
	}

	function onChangeFramerate()
	{
		if(ClientPrefs.framerate > FlxG.drawFramerate)
		{
			FlxG.updateFramerate = ClientPrefs.framerate;
			FlxG.drawFramerate = ClientPrefs.framerate;
		}
		else
		{
			FlxG.drawFramerate = ClientPrefs.framerate;
			FlxG.updateFramerate = ClientPrefs.framerate;
		}
	}
}
