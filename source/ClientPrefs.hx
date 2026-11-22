package;

import flixel.FlxG;
import flixel.util.FlxSave;
import flixel.input.keyboard.FlxKey;
import flixel.graphics.FlxGraphic;
import Controls;
import openfl.Lib;
import openfl.display.StageQuality;

class ClientPrefs {
	public static var downScroll:Bool = false;
	public static var middleScroll:Bool = false;
	public static var opponentStrums:Bool = true;
	public static var showFPS:Bool = true;
	public static var advancedFPS:Bool = false;
	public static var flashing:Bool = true;
	public static var globalAntialiasing:Bool = true;
	public static var noteSplashes:Bool = true;
	public static var lowQuality:Bool = false;
	public static var shaders:Bool = true;
	public static var framerate:Int = 60;
	public static var vsync:Bool = false;
	public static var cursing:Bool = true;
	public static var violence:Bool = true;
	public static var camZooms:Bool = true;
	public static var camBopAmount:String = 'On';
	public static var hideHud:Bool = false;
	public static var noteOffset:Int = 0;
	public static var arrowHSV:Array<Array<Int>> = [[0, 0, 0], [0, 0, 0], [0, 0, 0], [0, 0, 0]];
	public static var ghostTapping:Bool = true;
	public static var timeBarType:String = 'Time Left';
	public static var scoreZoom:Bool = true;
	public static var noReset:Bool = false;
	public static var healthBarAlpha:Float = 1;
	public static var controllerMode:Bool = false;
	public static var touchControls:Bool = true;
	public static var hitsoundVolume:Float = 0;
	public static var hitsoundType:String = 'osu!mania';
	public static var pauseMusic:String = 'Tea Time';
	public static var checkForUpdates:Bool = true;
	public static var comboStacking = false;
	public static var ratingPopups:Bool = true;
	public static var comboPopups:Bool = true;
	public static var showComboInfo:Bool = true;
	public static var showNPS:Bool = true;
	public static var showNotes:Bool = true;
	public static var botplayText:Bool = true;
	public static var songIntroCredits:Bool = true;
	public static var difficultyStar:Bool = true;
	public static var autoPause:Bool = true;
	public static var noteSplashAlpha:Float = 0.6;
	public static var noteSplashSkin:String = 'Default';
	public static var bgDim:Float = 0;
	public static var showComboBreaks:Bool = false;
	public static var noteSkin:String = 'Default';
	public static var discordRPC:Bool = true;
	private static inline var PERFORMANCE_PROFILE_VERSION:Int = 1;
	public static var maxNotesOnScreen:Int = 0;
	public static var maxNoteSplashesPerSecond:Int = 16;
	public static var opponentLightStrum:Bool = true;
	public static var playerLightStrum:Bool = true;
	public static var noSpawnFunc:Bool = false;
	public static var noHitFuncs:Bool = false;
	public static var crossFadeMode:String = 'Mid-Fight Masses';
	public static var crossFadeLimit:Int = 4;
	public static var boyfriendCrossFadeLimit:Int = 1;
	public static var dynamicSpawnTime:Bool = false;
	public static var noteSpawnTime:Float = 1;
	public static var oppNoteAlpha:Float = 0.65;
	public static var oppNoteSplashes:Bool = true;
	public static var botLightStrum:Bool = true;
	public static var noSkipFuncs:Bool = false;
	public static var scoreStyle:String = 'Psych Engine';
	public static var timeBarStyle:String = 'Vanilla';
	public static var healthBarStyle:String = 'Vanilla';
	public static var smoothHealth:Bool = true;
	public static var smoothHealthSpeed:Float = 1;
	public static var watermarkStyle:String = 'Vanilla';
	public static var botTxtStyle:String = 'Vanilla';
	public static var strumLitStyle:String = 'Full Anim';
	public static var bfIconStyle:String = 'Default';
	public static var ratingType:String = 'Default';
	public static var simplePopups:Bool = false;
	public static var showMS:Bool = false;
	public static var botWatermark:Bool = true;
	public static var enableGC:Bool = true;
	public static var lessBotLag:Bool = false;
	public static var charsAndBG:Bool = true;
	// LIMUL-GPU-CACHE: on by default now. Every decoded atlas (character sheets alone run past
	// 100 MB each) used to keep a CPU-side RGBA copy for the whole session; Paths.cacheGraphicOnGPU
	// uploads the texture and drops that copy, which is the single biggest RAM item in a song.
	public static var cacheOnGPU:Bool = true;
	public static var resolution:String = '1280x720';

	// Game Renderer (JS Engine parity)
	public static var ffmpegMode:Bool = false;
	public static var targetFPS:Float = 60;
	public static var unlockFPS:Bool = false;
	public static var renderBitrate:Float = 5.0;
	public static var vidEncoder:String = 'libx264';
	public static var oldFFmpegMode:Bool = false;
	public static var renderGCRate:Float = 5.0;
	public static var lossless:Bool = false;
	public static var quality:Int = 50;

	/** Applies renderer settings without touching gameplay, mod data, or scripts. */
	public static function applyPerformanceSettings():Void
	{
		if (Lib.current != null && Lib.current.stage != null)
			Lib.current.stage.quality = lowQuality ? StageQuality.LOW : StageQuality.HIGH;
	}

	/**
	 * Lime 8.3.2 takes vsync only as a window-creation attribute and offers no runtime setter,
	 * so the choice is persisted next to the executable and ApplicationMain.hx reads it before
	 * the window exists. That is why the option says "takes effect after restarting".
	 */
	public static function writeVsyncBootFlag():Void
	{
		#if desktop
		try
		{
			var path:String = haxe.io.Path.join([haxe.io.Path.directory(Sys.programPath()), 'vsync.txt']);
			sys.io.File.saveContent(path, vsync ? 'true' : 'false');
		}
		catch (e:Dynamic) {}
		#end
	}

	public static var gameplaySettings:Map<String, Dynamic> = [
		'scrollspeed' => 1.0,
		'scrolltype' => 'multiplicative', 
		// anyone reading this, amod is multiplicative speed mod, cmod is constant speed mod, and xmod is bpm based speed mod.
		// an amod example would be chartSpeed * multiplier
		// cmod would just be constantSpeed = chartSpeed
		// and xmod basically works by basing the speed on the bpm.
		// iirc (beatsPerSecond * (conductorToNoteDifference / 1000)) * noteSize (110 or something like that depending on it, prolly just use note.height)
		// bps is calculated by bpm / 60
		// oh yeah and you'd have to actually convert the difference to seconds which I already do, because this is based on beats and stuff. but it should work
		// just fine. but I wont implement it because I don't know how you handle sustains and other stuff like that.
		// oh yeah when you calculate the bps divide it by the songSpeed or rate because it wont scroll correctly when speeds exist.
		'songspeed' => 1.0,
		'healthgain' => 1.0,
		'healthloss' => 1.0,
		'opponentnotedrain' => false,
		'iconbouncestyle' => 'Psych Engine',
		'instakill' => false,
		'practice' => false,
		'botplay' => false,
		'opponentplay' => false
	];

	public static var comboOffset:Array<Int> = [0, 0, 0, 0];
	public static var ratingOffset:Int = 0;
	public static var sickWindow:Int = 45;
	public static var goodWindow:Int = 90;
	public static var badWindow:Int = 135;
	public static var safeFrames:Float = 10;

	//Every key has two binds, add your key bind down here and then add your control on options/ControlsSubState.hx and Controls.hx
	public static var keyBinds:Map<String, Array<FlxKey>> = [
		//Key Bind, Name for ControlsSubState
		'note_left'		=> [A, LEFT],
		'note_down'		=> [S, DOWN],
		'note_up'		=> [W, UP],
		'note_right'	=> [D, RIGHT],
		
		'ui_left'		=> [A, LEFT],
		'ui_down'		=> [S, DOWN],
		'ui_up'			=> [W, UP],
		'ui_right'		=> [D, RIGHT],
		
		'accept'		=> [SPACE, ENTER],
		'back'			=> [BACKSPACE, ESCAPE],
		'pause'			=> [ENTER, ESCAPE],
		'reset'			=> [R, NONE],
		
		'volume_mute'	=> [ZERO, NONE],
		'volume_up'		=> [NUMPADPLUS, PLUS],
		'volume_down'	=> [NUMPADMINUS, MINUS],
		
		'debug_1'		=> [SEVEN, NONE],
		'debug_2'		=> [EIGHT, NONE]
	];
	public static var defaultKeys:Map<String, Array<FlxKey>> = null;

	public static function loadDefaultKeys() {
		defaultKeys = keyBinds.copy();
		//trace(defaultKeys);
	}

	public static function saveSettings() {
		FlxG.save.data.downScroll = downScroll;
		FlxG.save.data.middleScroll = middleScroll;
		FlxG.save.data.opponentStrums = opponentStrums;
		FlxG.save.data.showFPS = showFPS;
		FlxG.save.data.advancedFPS = advancedFPS;
		FlxG.save.data.flashing = flashing;
		FlxG.save.data.globalAntialiasing = globalAntialiasing;
		FlxG.save.data.noteSplashes = noteSplashes;
		FlxG.save.data.lowQuality = lowQuality;
		FlxG.save.data.shaders = shaders;
		FlxG.save.data.framerate = framerate;
		FlxG.save.data.vsync = vsync;
		//FlxG.save.data.cursing = cursing;
		//FlxG.save.data.violence = violence;
		FlxG.save.data.camZooms = camZooms;
		FlxG.save.data.camBopAmount = camBopAmount;
		FlxG.save.data.noteOffset = noteOffset;
		FlxG.save.data.hideHud = hideHud;
		FlxG.save.data.arrowHSV = arrowHSV;
		FlxG.save.data.ghostTapping = ghostTapping;
		FlxG.save.data.timeBarType = timeBarType;
		FlxG.save.data.scoreZoom = scoreZoom;
		FlxG.save.data.noReset = noReset;
		FlxG.save.data.healthBarAlpha = healthBarAlpha;
		FlxG.save.data.comboOffset = comboOffset;
		FlxG.save.data.achievementsMap = Achievements.achievementsMap;
		FlxG.save.data.henchmenDeath = Achievements.henchmenDeath;

		FlxG.save.data.ratingOffset = ratingOffset;
		FlxG.save.data.sickWindow = sickWindow;
		FlxG.save.data.goodWindow = goodWindow;
		FlxG.save.data.badWindow = badWindow;
		FlxG.save.data.safeFrames = safeFrames;
		FlxG.save.data.gameplaySettings = gameplaySettings;
		FlxG.save.data.controllerMode = controllerMode;
		FlxG.save.data.touchControls = touchControls;
		FlxG.save.data.hitsoundVolume = hitsoundVolume;
		FlxG.save.data.hitsoundType = hitsoundType;
		FlxG.save.data.pauseMusic = pauseMusic;
		FlxG.save.data.checkForUpdates = checkForUpdates;
		FlxG.save.data.comboStacking = comboStacking;
		FlxG.save.data.ratingPopups = ratingPopups;
		FlxG.save.data.comboPopups = comboPopups;
		FlxG.save.data.showComboInfo = showComboInfo;
		FlxG.save.data.showNPS = showNPS;
		FlxG.save.data.showNotes = showNotes;
		FlxG.save.data.botplayText = botplayText;
		FlxG.save.data.songIntroCredits = songIntroCredits;
		FlxG.save.data.difficultyStar = difficultyStar;
		FlxG.save.data.autoPause = autoPause;
		FlxG.save.data.noteSplashAlpha = noteSplashAlpha;
		FlxG.save.data.noteSplashSkin = noteSplashSkin;
		FlxG.save.data.bgDim = bgDim;
		FlxG.save.data.showComboBreaks = showComboBreaks;
		FlxG.save.data.noteSkin = noteSkin;
		FlxG.save.data.discordRPC = discordRPC;
		FlxG.save.data.maxNotesOnScreen = maxNotesOnScreen;
		FlxG.save.data.maxRenderedNoteCount = maxNotesOnScreen;
		FlxG.save.data.maxNoteSplashesPerSecond = maxNoteSplashesPerSecond;
		FlxG.save.data.opponentLightStrum = opponentLightStrum;
		FlxG.save.data.playerLightStrum = playerLightStrum;
		FlxG.save.data.noSpawnFunc = noSpawnFunc;
		FlxG.save.data.noHitFuncs = noHitFuncs;
		FlxG.save.data.crossFadeMode = crossFadeMode;
		FlxG.save.data.crossFadeLimit = crossFadeLimit;
		FlxG.save.data.boyfriendCrossFadeLimit = boyfriendCrossFadeLimit;
		FlxG.save.data.dynamicSpawnTime = dynamicSpawnTime;
		FlxG.save.data.noteSpawnTime = noteSpawnTime;
		FlxG.save.data.oppNoteAlpha = oppNoteAlpha;
		FlxG.save.data.oppNoteSplashes = oppNoteSplashes;
		FlxG.save.data.botLightStrum = botLightStrum;
		FlxG.save.data.noSkipFuncs = noSkipFuncs;
		FlxG.save.data.scoreStyle = scoreStyle;
		FlxG.save.data.timeBarStyle = timeBarStyle;
		FlxG.save.data.healthBarStyle = healthBarStyle;
		FlxG.save.data.smoothHealth = smoothHealth;
		FlxG.save.data.smoothHealthSpeed = smoothHealthSpeed;
		FlxG.save.data.watermarkStyle = watermarkStyle;
		FlxG.save.data.botTxtStyle = botTxtStyle;
		FlxG.save.data.strumLitStyle = strumLitStyle;
		FlxG.save.data.bfIconStyle = bfIconStyle;
		FlxG.save.data.ratingType = ratingType;
		FlxG.save.data.simplePopups = simplePopups;
		FlxG.save.data.showMS = showMS;
		FlxG.save.data.botWatermark = botWatermark;
		FlxG.save.data.enableGC = enableGC;
		FlxG.save.data.lessBotLag = lessBotLag;
		FlxG.save.data.charsAndBG = charsAndBG;
		FlxG.save.data.cacheOnGPU = cacheOnGPU;
		FlxG.save.data.resolution = resolution;
		FlxG.save.data.ffmpegMode = ffmpegMode;
		FlxG.save.data.targetFPS = targetFPS;
		FlxG.save.data.unlockFPS = unlockFPS;
		FlxG.save.data.renderBitrate = renderBitrate;
		FlxG.save.data.vidEncoder = vidEncoder;
		FlxG.save.data.oldFFmpegMode = oldFFmpegMode;
		FlxG.save.data.renderGCRate = renderGCRate;
		FlxG.save.data.lossless = lossless;
		FlxG.save.data.quality = quality;
	
		FlxG.save.flush();

		var save:FlxSave = new FlxSave();
		save.bind('controls_v2', 'Limul'); //Placing this in a separate save so that it can be manually deleted without removing your Score and stuff
		save.data.customControls = keyBinds;
		save.flush();
		FlxG.log.add("Settings saved!");
	}

	public static function loadPrefs() {
		// Give new installs a lightweight baseline. Existing users can change these
		// settings later in Visuals and UI; no chart, mod, or script data is changed.
		if(FlxG.save.data.performanceProfileVersion == null) {
			globalAntialiasing = false;
			lowQuality = true;
			shaders = false;
			noteSplashes = false;
			flashing = false;
			FlxG.save.data.performanceProfileVersion = PERFORMANCE_PROFILE_VERSION;
		}
		if(FlxG.save.data.downScroll != null) {
			downScroll = FlxG.save.data.downScroll;
		}
		if(FlxG.save.data.middleScroll != null) {
			middleScroll = FlxG.save.data.middleScroll;
		}
		if(FlxG.save.data.opponentStrums != null) {
			opponentStrums = FlxG.save.data.opponentStrums;
		}
		if(FlxG.save.data.showFPS != null) {
			showFPS = FlxG.save.data.showFPS;
			if(Main.fpsVar != null) {
				Main.fpsVar.visible = showFPS;
			}
		}
		if(FlxG.save.data.advancedFPS != null) {
			advancedFPS = FlxG.save.data.advancedFPS;
		}
		if(FlxG.save.data.flashing != null) {
			flashing = FlxG.save.data.flashing;
		}
		if(FlxG.save.data.globalAntialiasing != null) {
			globalAntialiasing = FlxG.save.data.globalAntialiasing;
		}
		if(FlxG.save.data.noteSplashes != null) {
			noteSplashes = FlxG.save.data.noteSplashes;
		}
		if(FlxG.save.data.lowQuality != null) {
			lowQuality = FlxG.save.data.lowQuality;
		}
		applyPerformanceSettings();
		if(FlxG.save.data.shaders != null) {
			shaders = FlxG.save.data.shaders;
		}
		if(FlxG.save.data.framerate != null) {
			framerate = FlxG.save.data.framerate;
			if(framerate > FlxG.drawFramerate) {
				FlxG.updateFramerate = framerate;
				FlxG.drawFramerate = framerate;
			} else {
				FlxG.drawFramerate = framerate;
				FlxG.updateFramerate = framerate;
			}
		}
		if(FlxG.save.data.vsync != null) {
			vsync = FlxG.save.data.vsync;
		}
		writeVsyncBootFlag();
		/*if(FlxG.save.data.cursing != null) {
			cursing = FlxG.save.data.cursing;
		}
		if(FlxG.save.data.violence != null) {
			violence = FlxG.save.data.violence;
		}*/
		if(FlxG.save.data.camZooms != null) {
			camZooms = FlxG.save.data.camZooms;
		}
		if(FlxG.save.data.camBopAmount != null && Std.isOfType(FlxG.save.data.camBopAmount, String)) {
			camBopAmount = FlxG.save.data.camBopAmount;
			if (camBopAmount != 'On' && camBopAmount != 'Reduced' && camBopAmount != 'Off')
				camBopAmount = 'On';
		}
		if(FlxG.save.data.hideHud != null) {
			hideHud = FlxG.save.data.hideHud;
		}
		if(FlxG.save.data.noteOffset != null) {
			noteOffset = FlxG.save.data.noteOffset;
		}
		if(FlxG.save.data.arrowHSV != null) {
			arrowHSV = FlxG.save.data.arrowHSV;
		}
		if(FlxG.save.data.ghostTapping != null) {
			ghostTapping = FlxG.save.data.ghostTapping;
		}
		if(FlxG.save.data.timeBarType != null) {
			timeBarType = FlxG.save.data.timeBarType;
		}
		if(FlxG.save.data.scoreZoom != null) {
			scoreZoom = FlxG.save.data.scoreZoom;
		}
		if(FlxG.save.data.noReset != null) {
			noReset = FlxG.save.data.noReset;
		}
		if(FlxG.save.data.healthBarAlpha != null) {
			healthBarAlpha = FlxG.save.data.healthBarAlpha;
		}
		if(FlxG.save.data.comboOffset != null) {
			comboOffset = FlxG.save.data.comboOffset;
		}
		
		if(FlxG.save.data.ratingOffset != null) {
			ratingOffset = FlxG.save.data.ratingOffset;
		}
		if(FlxG.save.data.sickWindow != null) {
			sickWindow = FlxG.save.data.sickWindow;
		}
		if(FlxG.save.data.goodWindow != null) {
			goodWindow = FlxG.save.data.goodWindow;
		}
		if(FlxG.save.data.badWindow != null) {
			badWindow = FlxG.save.data.badWindow;
		}
		if(FlxG.save.data.safeFrames != null) {
			safeFrames = FlxG.save.data.safeFrames;
		}
		if(FlxG.save.data.controllerMode != null) {
			controllerMode = FlxG.save.data.controllerMode;
		}
		if(FlxG.save.data.touchControls != null) {
			touchControls = FlxG.save.data.touchControls;
		}
		if(FlxG.save.data.hitsoundVolume != null) {
			hitsoundVolume = FlxG.save.data.hitsoundVolume;
		}
		if(FlxG.save.data.hitsoundType != null) {
			hitsoundType = FlxG.save.data.hitsoundType;
		}
		if(FlxG.save.data.pauseMusic != null) {
			pauseMusic = FlxG.save.data.pauseMusic;
		}
		if(FlxG.save.data.gameplaySettings != null)
		{
			var savedMap:Map<String, Dynamic> = FlxG.save.data.gameplaySettings;
			for (name => value in savedMap)
			{
				gameplaySettings.set(name, value);
			}
			var bounceStyle:Dynamic = gameplaySettings.get('iconbouncestyle');
			if (bounceStyle != null)
				gameplaySettings.set('iconbouncestyle', IconBounce.normalize(Std.string(bounceStyle)));
		}
		
		// flixel automatically saves your volume!
		if(FlxG.save.data.volume != null)
		{
			FlxG.sound.volume = FlxG.save.data.volume;
		}
		if (FlxG.save.data.mute != null)
		{
			FlxG.sound.muted = FlxG.save.data.mute;
		}
		if (FlxG.save.data.checkForUpdates != null)
		{
			checkForUpdates = FlxG.save.data.checkForUpdates;
		}
		if (FlxG.save.data.comboStacking != null)
			comboStacking = FlxG.save.data.comboStacking;
		if (FlxG.save.data.ratingPopups != null)
			ratingPopups = FlxG.save.data.ratingPopups;
		if (FlxG.save.data.comboPopups != null)
			comboPopups = FlxG.save.data.comboPopups;
		if (FlxG.save.data.showComboInfo != null)
			showComboInfo = FlxG.save.data.showComboInfo;
		if (FlxG.save.data.showNPS != null)
			showNPS = FlxG.save.data.showNPS;
		if (FlxG.save.data.showNotes != null)
			showNotes = FlxG.save.data.showNotes;
		if (FlxG.save.data.botplayText != null)
			botplayText = FlxG.save.data.botplayText;
		if (FlxG.save.data.songIntroCredits != null)
			songIntroCredits = FlxG.save.data.songIntroCredits;
		if (FlxG.save.data.difficultyStar != null)
			difficultyStar = FlxG.save.data.difficultyStar;
		if (FlxG.save.data.autoPause != null)
			autoPause = FlxG.save.data.autoPause;
		if (FlxG.save.data.noteSplashAlpha != null)
			noteSplashAlpha = FlxG.save.data.noteSplashAlpha;
		if (FlxG.save.data.noteSplashSkin != null && Std.isOfType(FlxG.save.data.noteSplashSkin, String))
		{
			noteSplashSkin = FlxG.save.data.noteSplashSkin;
			if (noteSplashSkin.length < 1) noteSplashSkin = 'Default';
		}
		if (FlxG.save.data.bgDim != null)
			bgDim = FlxG.save.data.bgDim;
		if (FlxG.save.data.showComboBreaks != null)
			showComboBreaks = FlxG.save.data.showComboBreaks;
		if (FlxG.save.data.noteSkin != null)
			noteSkin = FlxG.save.data.noteSkin;
		if (FlxG.save.data.discordRPC != null)
			discordRPC = FlxG.save.data.discordRPC;
		FlxG.autoPause = autoPause;
		if(FlxG.save.data.maxNotesOnScreen != null)
			maxNotesOnScreen = FlxG.save.data.maxNotesOnScreen;
		else if(FlxG.save.data.maxRenderedNoteCount != null)
			maxNotesOnScreen = FlxG.save.data.maxRenderedNoteCount;
		else if(FlxG.save.data.maxRenderedNotes != null)
			maxNotesOnScreen = FlxG.save.data.maxRenderedNotes;
		if(FlxG.save.data.maxNoteSplashesPerSecond != null)
			maxNoteSplashesPerSecond = FlxG.save.data.maxNoteSplashesPerSecond;
		if(FlxG.save.data.opponentLightStrum != null)
			opponentLightStrum = FlxG.save.data.opponentLightStrum;
		if(FlxG.save.data.playerLightStrum != null)
			playerLightStrum = FlxG.save.data.playerLightStrum;
		if(FlxG.save.data.noSpawnFunc != null)
			noSpawnFunc = FlxG.save.data.noSpawnFunc;
		if(FlxG.save.data.noHitFuncs != null)
			noHitFuncs = FlxG.save.data.noHitFuncs;
		if(FlxG.save.data.crossFadeMode != null)
			crossFadeMode = FlxG.save.data.crossFadeMode;
		if(FlxG.save.data.crossFadeLimit != null)
			crossFadeLimit = FlxG.save.data.crossFadeLimit;
		if(FlxG.save.data.boyfriendCrossFadeLimit != null)
			boyfriendCrossFadeLimit = FlxG.save.data.boyfriendCrossFadeLimit;
		if(FlxG.save.data.dynamicSpawnTime != null)
			dynamicSpawnTime = FlxG.save.data.dynamicSpawnTime;
		if(FlxG.save.data.noteSpawnTime != null)
			noteSpawnTime = FlxG.save.data.noteSpawnTime;
		if(FlxG.save.data.oppNoteAlpha != null)
			oppNoteAlpha = FlxG.save.data.oppNoteAlpha;
		if(FlxG.save.data.oppNoteSplashes != null)
			oppNoteSplashes = FlxG.save.data.oppNoteSplashes;
		if(FlxG.save.data.botLightStrum != null)
			botLightStrum = FlxG.save.data.botLightStrum;
		if(FlxG.save.data.noSkipFuncs != null)
			noSkipFuncs = FlxG.save.data.noSkipFuncs;
		if(FlxG.save.data.scoreStyle != null)
			scoreStyle = FlxG.save.data.scoreStyle;
		if(FlxG.save.data.timeBarStyle != null)
			timeBarStyle = FlxG.save.data.timeBarStyle;
		if(FlxG.save.data.healthBarStyle != null)
			healthBarStyle = FlxG.save.data.healthBarStyle;
		if(FlxG.save.data.smoothHealth != null)
			smoothHealth = FlxG.save.data.smoothHealth;
		if(FlxG.save.data.smoothHealthSpeed != null)
			smoothHealthSpeed = FlxG.save.data.smoothHealthSpeed;
		if(FlxG.save.data.watermarkStyle != null)
			watermarkStyle = FlxG.save.data.watermarkStyle;
		if(FlxG.save.data.botTxtStyle != null)
			botTxtStyle = FlxG.save.data.botTxtStyle;
		if(FlxG.save.data.strumLitStyle != null)
			strumLitStyle = FlxG.save.data.strumLitStyle;
		if(FlxG.save.data.bfIconStyle != null)
			bfIconStyle = FlxG.save.data.bfIconStyle;
		if(FlxG.save.data.ratingType != null)
			ratingType = FlxG.save.data.ratingType;
		if(FlxG.save.data.simplePopups != null)
			simplePopups = FlxG.save.data.simplePopups;
		if(FlxG.save.data.showMS != null)
			showMS = FlxG.save.data.showMS;
		if(FlxG.save.data.botWatermark != null)
			botWatermark = FlxG.save.data.botWatermark;
		if (FlxG.save.data.enableGC != null)
			enableGC = FlxG.save.data.enableGC;
		if (FlxG.save.data.lessBotLag != null)
			lessBotLag = FlxG.save.data.lessBotLag;
		if (FlxG.save.data.charsAndBG != null)
			charsAndBG = FlxG.save.data.charsAndBG;
		// LIMUL-GPU-CACHE: existing saves already have cacheOnGPU=false written by the first-run
		// saveSettings(), so a plain default bump would never reach them. Flip it exactly once per
		// save; whoever turns it back off in Options keeps it off afterwards.
		if (FlxG.save.data.gpuCacheDefault == null)
		{
			FlxG.save.data.cacheOnGPU = true;
			FlxG.save.data.gpuCacheDefault = true;
			FlxG.save.flush();
		}
		if (FlxG.save.data.cacheOnGPU != null)
			cacheOnGPU = FlxG.save.data.cacheOnGPU;
		if (FlxG.save.data.resolution != null)
			resolution = FlxG.save.data.resolution;
		if (FlxG.save.data.ffmpegMode != null)
			ffmpegMode = FlxG.save.data.ffmpegMode;
		if (FlxG.save.data.targetFPS != null)
			targetFPS = FlxG.save.data.targetFPS;
		if (FlxG.save.data.unlockFPS != null)
			unlockFPS = FlxG.save.data.unlockFPS;
		if (FlxG.save.data.renderBitrate != null)
			renderBitrate = FlxG.save.data.renderBitrate;
		if (FlxG.save.data.vidEncoder != null)
			vidEncoder = FlxG.save.data.vidEncoder;
		if (FlxG.save.data.oldFFmpegMode != null)
			oldFFmpegMode = FlxG.save.data.oldFFmpegMode;
		if (FlxG.save.data.renderGCRate != null)
			renderGCRate = FlxG.save.data.renderGCRate;
		if (FlxG.save.data.lossless != null)
			lossless = FlxG.save.data.lossless;
		if (FlxG.save.data.quality != null)
			quality = FlxG.save.data.quality;
		if (targetFPS < 1)
			targetFPS = 60;

		var save:FlxSave = new FlxSave();
		save.bind('controls_v2', 'Limul');
		if(save != null && save.data.customControls != null) {
			var loadedControls:Map<String, Array<FlxKey>> = save.data.customControls;
			for (control => keys in loadedControls) {
				keyBinds.set(control, keys);
			}
			reloadControls();
		}
	}

	inline public static function getGameplaySetting(name:String, defaultValue:Dynamic):Dynamic {
		return /*PlayState.isStoryMode ? defaultValue : */ (gameplaySettings.exists(name) ? gameplaySettings.get(name) : defaultValue);
	}

	public static function reloadControls() {
		PlayerSettings.player1.controls.setKeyboardScheme(KeyboardScheme.Solo);

		TitleState.muteKeys = copyKey(keyBinds.get('volume_mute'));
		TitleState.volumeDownKeys = copyKey(keyBinds.get('volume_down'));
		TitleState.volumeUpKeys = copyKey(keyBinds.get('volume_up'));
		FlxG.sound.muteKeys = TitleState.muteKeys;
		FlxG.sound.volumeDownKeys = TitleState.volumeDownKeys;
		FlxG.sound.volumeUpKeys = TitleState.volumeUpKeys;
	}
	public static function copyKey(arrayToCopy:Array<FlxKey>):Array<FlxKey> {
		var copiedArray:Array<FlxKey> = arrayToCopy.copy();
		var i:Int = 0;
		var len:Int = copiedArray.length;

		while (i < len) {
			if(copiedArray[i] == NONE) {
				copiedArray.remove(NONE);
				--i;
			}
			i++;
			len = copiedArray.length;
		}
		return copiedArray;
	}
}
