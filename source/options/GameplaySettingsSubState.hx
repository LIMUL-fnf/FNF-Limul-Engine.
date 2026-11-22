package options;

#if desktop
import Discord.DiscordClient;
#end
#if sys
import sys.FileSystem;
import sys.io.File;
#end
import flash.text.TextField;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.FlxGridOverlay;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.ui.FlxButton;
import flixel.util.FlxColor;
import lime.utils.Assets;
import flixel.FlxSubState;
import flash.text.TextField;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.util.FlxSave;
import haxe.Json;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;
import flixel.input.keyboard.FlxKey;
import flixel.graphics.FlxGraphic;
import Controls;

using StringTools;

class GameplaySettingsSubState extends BaseOptionsMenu
{
	public function new()
	{
		title = 'Gameplay Settings';
		rpcTitle = 'Gameplay Settings Menu'; //for Discord Rich Presence

		var option:Option = new Option('Controller Mode',
			'Check this if you want to play with\na controller instead of using your Keyboard.',
			'controllerMode',
			'bool',
			false);
		addOption(option);

		#if mobile
		var option:Option = new Option('Touch Controls',
			"If checked, tap and hold anywhere on the four lanes\nto play notes, V-Slice style.",
			'touchControls',
			'bool',
			true);
		addOption(option);
		#end

		//I'd suggest using "Downscroll" as an example for making your own option since it is the simplest here
		var option:Option = new Option('Downscroll', //Name
			'If checked, notes go Down instead of Up, simple enough.', //Description
			'downScroll', //Save data variable name
			'bool', //Variable type
			false); //Default value
		addOption(option);

		var option:Option = new Option('Middlescroll',
			'If checked, your notes get centered.',
			'middleScroll',
			'bool',
			false);
		addOption(option);

		var option:Option = new Option('Opponent Notes',
			'If unchecked, opponent notes get hidden.',
			'opponentStrums',
			'bool',
			true);
		addOption(option);

		var option:Option = new Option('Ghost Tapping',
			"If checked, you won't get misses from pressing keys\nwhile there are no notes able to be hit.",
			'ghostTapping',
			'bool',
			true);
		addOption(option);

		var option:Option = new Option('Auto Pause',
			"If checked, the game automatically pauses\nwhen the window loses focus.",
			'autoPause',
			'bool',
			true);
		option.onChange = onChangeAutoPause;
		addOption(option);

		var option:Option = new Option('CrossFade Mode:',
			'What mode should CrossFade be in?\nAffects the ghost trail left by characters on section changes.',
			'crossFadeMode',
			'string',
			'Mid-Fight Masses',
			['Mid-Fight Masses', 'Static', 'Eccentric', 'Off']);
		addOption(option);

		var option:Option = new Option('BF CrossFade Limit',
			'Determines the maximum amount of CrossFade\nechoes the player can have.',
			'boyfriendCrossFadeLimit',
			'int',
			1);
		addOption(option);
		option.minValue = 1;
		option.maxValue = 10;

		var option:Option = new Option('Opponent CrossFade Limit',
			'Determines the maximum amount of CrossFade\nechoes the opponent can have.',
			'crossFadeLimit',
			'int',
			4);
		addOption(option);
		option.minValue = 1;
		option.maxValue = 10;

		var option:Option = new Option('Disable Reset Button',
			"If checked, pressing Reset won't do anything.",
			'noReset',
			'bool',
			false);
		addOption(option);

		var option:Option = new Option('Hitsound Volume',
			'Funny notes does \"Tick!\" when you hit them."',
			'hitsoundVolume',
			'percent',
			0);
		addOption(option);
		option.scrollSpeed = 1.6;
		option.minValue = 0.0;
		option.maxValue = 1;
		option.changeValue = 0.1;
		option.decimals = 1;
		option.onChange = onChangeHitsoundVolume;

		var hitsoundList:Array<String> = ['osu!mania', 'Dave and Bambi', 'Indie Cross', 'Snap', 'Clap', 'Generic Click', 'Keyboard Click', 'Vine Boom', 'ADOFAI', 'Discord Ping', "i'm spongebob!", 'FIRE IN THE HOLE', 'Vivziepop', 'WEGA SCREAM', 'none'];
		#if sys
		for (cand in ['assets/shared/sounds/hitsounds/list.txt', 'assets/sounds/hitsounds/list.txt'])
		{
			if (!FileSystem.exists(cand)) continue;
			var lines:Array<String> = File.getContent(cand).trim().split('\n');
			if (lines.length > 0)
			{
				for (i in 0...lines.length) lines[i] = lines[i].trim();
				lines.push('none');
				hitsoundList = lines;
			}
			break;
		}
		#end
		var option:Option = new Option('Hitsound Type',
			'Which sound plays when you hit a note.',
			'hitsoundType',
			'string',
			'osu!mania',
			hitsoundList);
		option.onChange = onChangeHitsoundVolume;
		addOption(option);

		var option:Option = new Option('Rating Offset',
			'Changes how late/early you have to hit for a "Sick!"\nHigher values mean you have to hit later.',
			'ratingOffset',
			'int',
			0);
		option.displayFormat = '%vms';
		option.scrollSpeed = 20;
		option.minValue = -30;
		option.maxValue = 30;
		addOption(option);

		var option:Option = new Option('Sick! Hit Window',
			'Changes the amount of time you have\nfor hitting a "Sick!" in milliseconds.',
			'sickWindow',
			'int',
			45);
		option.displayFormat = '%vms';
		option.scrollSpeed = 15;
		option.minValue = 15;
		option.maxValue = 45;
		addOption(option);

		var option:Option = new Option('Good Hit Window',
			'Changes the amount of time you have\nfor hitting a "Good" in milliseconds.',
			'goodWindow',
			'int',
			90);
		option.displayFormat = '%vms';
		option.scrollSpeed = 30;
		option.minValue = 15;
		option.maxValue = 90;
		addOption(option);

		var option:Option = new Option('Bad Hit Window',
			'Changes the amount of time you have\nfor hitting a "Bad" in milliseconds.',
			'badWindow',
			'int',
			135);
		option.displayFormat = '%vms';
		option.scrollSpeed = 60;
		option.minValue = 15;
		option.maxValue = 135;
		addOption(option);

		var option:Option = new Option('Safe Frames',
			'Changes how many frames you have for\nhitting a note earlier or late.',
			'safeFrames',
			'float',
			10);
		option.scrollSpeed = 5;
		option.minValue = 2;
		option.maxValue = 10;
		option.changeValue = 0.1;
		addOption(option);

		super();
	}

	function onChangeHitsoundVolume()
	{
		if (ClientPrefs.hitsoundType == 'none')
			return;
		FlxG.sound.play(Paths.sound('hitsounds/' + ClientPrefs.hitsoundType.toLowerCase()), ClientPrefs.hitsoundVolume);
	}

	function onChangeAutoPause()
	{
		FlxG.autoPause = ClientPrefs.autoPause;
	}
}
