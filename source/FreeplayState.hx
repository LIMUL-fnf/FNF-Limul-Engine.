package;

#if desktop
import Discord.DiscordClient;
#end
import editors.ChartingState;
import flash.text.TextField;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.ui.FlxUIInputText;
import flixel.addons.transition.FlxTransitionableState;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.graphics.frames.FlxFrame;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flxanimate.FlxAnimate;
import lime.utils.Assets;
import flixel.sound.FlxSound;
import openfl.utils.Assets as OpenFlAssets;
import openfl.utils.AssetType;
import openfl.display.BitmapData;
import openfl.display.BlendMode;
import openfl.filters.BitmapFilterQuality;
import openfl.filters.GlowFilter;
import openfl.geom.ColorTransform;
import openfl.geom.Matrix;
import openfl.geom.Point;
import WeekData;
#if sys
import sys.FileSystem;
import sys.io.File;
#end

using StringTools;

// What the V-Slice card actually prints. The full SwagSong is parsed, mined for these four
// values and dropped again; keeping the chart objects around pinned every note array of every
// song the cursor ever touched (398 songs x several difficulties is a lot of arrays).
private typedef VSlicePreview = {
	var music:String;
	var chart:String;
	var rank:Int;
	var bpm:Int;
}

class FreeplayState extends MusicBeatState
{
	var songs:Array<SongMetadata> = [];
	private var filteredSongs:Array<Int> = [];
	private var filteredSongPositions:Array<Int> = [];
	private var searchLabel:FlxText;
	private var searchField:FlxUIInputText;
	private var searchHint:FlxText;
	private var searchQuery:String = '';
	private var lastSearchText:String = '';

	var selector:FlxText;
	private static var curSelected:Int = 0;
	var curDifficulty:Int = -1;
	private static var lastDifficultyName:String = '';

	var scoreBG:FlxSprite;
	var scoreText:FlxText;
	var diffText:FlxText;
	var lerpScore:Int = 0;
	var lerpRating:Float = 0;
	var intendedScore:Int = 0;
	var intendedRating:Float = 0;
	private var lastScoreText:String = '';
	private var lastHighscoreWidth:Float = -1;
	// LIMUL-FREEPLAY-SCALE: the score/rating labels only move while the lerp is catching up.
	// Rebuilding the split/joined strings every frame was a steady string-allocation stream
	// while nothing on screen changed.
	private var lastLerpScore:Float = -1e9;
	private var lastLerpRating:Float = -1e9;

	private var grpSongs:FlxTypedGroup<FlxSprite>;
	private var curPlaying:Bool = false;

	private var iconArray:Array<HealthIcon> = [];

	// V-SLICE-FREEPLAY (2026-11-15): the real FNF 1.0 Freeplay layout, built from the assets
	// P-Slice ships. The whole screen changes, not just the list: a light card with the scrolling
	// marquee and mascot DJ on the left, the black FREEPLAY header with difficulty plates and the
	// letter sorter, the capsule list in the middle and the tilted album cover on the right.
	// The stock 0.6.3 list is still behind the Other option for anyone who wants it back.
	private var vsliceHud:Bool = false;
	private var grpCapsules:FlxTypedGroup<FlxSprite>;
	private var capsuleArray:Array<FlxSprite> = [];
	private var highscoreArt:FlxSprite;
	private var vsliceAlbum:FlxSprite;
	private var vsliceStars:Array<FlxSprite> = [];
	private var vsliceCredits:FlxText;
	private var vsliceAlbumId:String = '';
	private var vsliceStarKey:String = '';
	private var vslicePreviewCache:Map<String, VSlicePreview> = new Map();
	private var vsliceTime:Float = 0;

	private var vsliceTopBar:FlxSprite;
	private var vsliceTitle:FlxText;
	private var vsliceOstText:FlxText;
	private var vsliceBackCard:FlxSprite;
	private var vsliceOrangeStrip:FlxSprite;
	private var vsliceOrangeEdge:FlxSprite;
	private var vsliceAlbumTitle:FlxSprite;
	private var vsliceTitleGlow:FlxSprite;
	private var vsliceGlowFor:Int = -1;
	private var vsliceGlowBmd:BitmapData;
	private static inline var GLOW_PAD:Int = 12;
	private var vsliceLetters:Array<FlxSprite> = [];
	private var vsliceLetterArrows:Array<FlxSprite> = [];
	private var vsliceLetterSeparators:Array<FlxSprite> = [];
	private var vsliceLetterFilters:Array<String> = [];
	private static var vsliceLetterIndex:Int = 2;
	private var vsliceDiffArt:FlxSprite;
	private var vsliceDiffKey:String = '';
	private var vsliceDiffArrowArt:Array<FlxSprite> = [];
	private var vsliceStylePico:Bool = false;
	private var vsliceStyleInit:Bool = false;

	private var vsliceDj:FlxAnimate;
	private var vsliceDjAtlas:String = '';
	private var vsliceDjState:String = 'idle';
	private var vsliceConfirmTimer:Float = -1;
	private var vsliceConfirmAction:Void->Void;

	private var vsliceRowBpm:Array<FlxSprite> = [];
	private var vsliceRowDiff:Array<FlxSprite> = [];
	private var vsliceRowY:Array<Float> = [];
	private var vsliceRowClip:Array<Bool> = [];
	private var vsliceRowPixel:Array<FlxSprite> = [];
	private var vsliceRowDigit:Array<FlxSprite> = [];
	// P-Slice hangs the whole bottom strip on every SongMenuItem, not just the selected one:
	// three BPM digits (185 + i*11, 88.5), the week name (298, 91), the score rank (420, 41)
	// and the NEW tag (454, 9). These arrays keep that per-row state (SongMenuItem.hx:119-173).
	private var vsliceRowWeek:Array<FlxSprite> = [];
	private var vsliceRowSmall:Array<FlxSprite> = [];
	private var vsliceRowRank:Array<FlxSprite> = [];
	private var vsliceRowRankName:Array<String> = [];
	private var vsliceRowNew:Array<FlxSprite> = [];
	private var vsliceBpmCache:Map<Int, Int> = new Map();
	private var vsliceBpmQueue:Array<Int> = [];
	private var vslicePlayedSongs:Map<String, Bool> = new Map();
	// LIMUL-FREEPLAY-SCALE: updateVSliceRows() runs for every visible row on every frame and used
	// to rebuild the formatted song key (lowercase + dash replacement) and the highscore rank
	// string each time. Keys are made once per row; the rank map is dropped when the difficulty
	// changes, which is the only thing besides restarting Freeplay that can alter it.
	private var vsliceSongKeys:Map<Int, String> = new Map();
	private var vsliceRankCache:Map<Int, String> = new Map();
	private var vsliceRankDiff:Int = -999;
	private var vsliceRatingSel:Int = -999;
	private var vsliceRatingDiff:Int = -999;
	private var vsliceRatingValue:Int = -1;
	private var vsliceAtlasCapsule:FlxAtlasFrames;
	private var vsliceAtlasCapsulePico:FlxAtlasFrames;
	private var vsliceAtlasBig:FlxAtlasFrames;
	private var vsliceAtlasSmall:FlxAtlasFrames;
	private var vsliceAtlasRank:FlxAtlasFrames;
	private var vsliceAtlasNew:FlxAtlasFrames;
	private var vsliceAtlasCapsuleText:FlxAtlasFrames;
	private var vsliceWeekGraphics:Map<String, FlxGraphic> = new Map();
	private var vsliceClearBox:FlxSprite;
	private var vsliceClearText:FlxText;
	private var vsliceScoreDigits:Array<FlxSprite> = [];
	private var vsliceScoreValue:Int = -1;
	private var vsliceDigitAtlas:String = '';
	#if FREEPLAY
	private var vsliceDbgText:FlxText;
	#end

	private static var NUM_NAMES:Array<String> = ['ZERO', 'ONE', 'TWO', 'THREE', 'FOUR', 'FIVE', 'SIX', 'SEVEN', 'EIGHT', 'NINE'];
	private static var VS_DIGIT_DIVISORS:Array<Int> = [100, 10, 1];
	// P-Slice's AlbumRoll has no white sleeve: the 262 px cover sits straight on the background,
	// with the stars along its top edge and the title art underneath (AlbumRoll.hx:49-62). On our
	// 720p canvas the reference screenshot shows that block a touch larger, so the cover is drawn
	// at the width the retired sleeve used to occupy.
	private static inline var ALBUM_CARD_WIDTH:Float = 290;
	private static inline var ALBUM_CARD_X:Float = 938;
	private static inline var ALBUM_CARD_TOP:Float = 250;
	// Star sprites are the 113 px atlas frames; the target screenshot shows ~25 px of visible
	// star with ~29 px between star origins, so 26 px portraits with a 3 px gap match the strip.
	private static inline var ALBUM_STAR_SIZE:Float = 26;
	private static inline var ALBUM_STAR_GAP:Float = 3;
	private static inline var VS_ROW_GAP:Float = 10;
	// P-Slice's SongMenuItem is 612x132 and shrinks only the capsule art by realScaled (0.8); every
	// label inside stays at its raw local pixel offset and native font size (CustomAnimControl.hx:10,
	// SongMenuItem.hx:126-224).
	private static inline var VS_CAPSULE_SCALE:Float = 0.8;
	// P-Slice's SongMenuItem places the first ("Random"-offset) capsule at 270 + 60*sin(index)
	// horizontally and steps it by (capsuleHeight * scale + 10) vertically; the selected entry rests
	// one step below the top edge of the scroll view.
	private static inline var VS_LIST_X:Float = 270;
	private static inline var VS_LIST_Y:Float = 235.6;
	private static inline var VS_LIST_CLIP_TOP:Float = 96;
	// Children of a SongMenuItem sit in the unscaled 612x132 canvas; only the capsule sprite itself
	// is scaled, so local offsets like the title (159,45) are used as-is.
	private static inline var VS_CHILD_SCALE:Float = 1.0;

	// LIMUL-FREEPLAY-SCALE (2026-11-02): the first cut of this built rows only inside a window
	// around the selection (ROW_BUILD) and switched the ones outside it off (exists/visible =
	// false, ROW_LIVE = 12). The geometry argued that was safe - Alphabet places a menu item at
	// targetY * 1.3 * distancePerItem.y, about 110 px per row, so the screen shows ~7 rows and a
	// +/-12 live window is far wider than the viewport. In game it was still wrong: rows started
	// losing their titles, so the whole hide-rows mechanism is gone. Freeplay behaves exactly like
	// stock now - every row is created on entry and none of them is ever switched off. What
	// survives is the part that cannot change what is on screen: the row is built in ONE place
	// (buildRow) instead of inline, and the score/rating text is only recomposed when the composed
	// string or FlxG.width actually changed (see updateScore). Entering a menu with a few dozen
	// songs costs what it cost in stock Psych 0.6.3 - that is a price worth paying over rows that
	// quietly disappear.
	private var rowTexts:Array<FlxSprite> = [];

	// LIMUL-FREEPLAY-SCALE (2026-11-05, part 2): what stops the menu from feeling responsive once
	// there are a few hundred rows is not drawing them, it is the work repeated per key press and per
	// frame across ALL of them:
	//   * FlxSpriteGroup.alpha propagates to every letter (FlxSpriteGroup.hx:726 -> transformChildren),
	//     so the old "walk every row and set alpha" loops cost rows x letters per selection change -
	//     and holding an arrow key runs changeSelection several times a frame.
	//   * the per-song difficulty filter stat()'d the chart folder on every selection change, so the
	//     custom Erect/Nightmare names cost disk I/O each time the cursor moved.
	//   * every letter of every row ran FlxSprite.update() once per frame even though a letter is one
	//     static frame; only the group lerps toward targetY.
	// All three are fixed by doing less of the same thing, never by switching rows off - see the
	// note above about why the row-hiding experiment was reverted.
	private var lastSelected:Int = -1;
	private var difficultyCache:Map<String, Array<String>> = new Map();

	// LIMUL-FREEPLAY-MOUSE (2026-11-09): MainMenuState hides the cursor and nothing here turned it
	// back on, so Freeplay opened with an invisible pointer even though the wheel and the row click
	// were already wired. The cursor is shown for the visit and put back to whatever the previous
	// menu wanted when the state dies - PlayState has no visibility handling of its own and would
	// otherwise inherit a cursor floating over the notes.
	private var prevMouseVisible:Bool = true;

	var bg:FlxSprite;
	var intendedColor:Int;
	var colorTween:FlxTween;
	var hintBar:FlxSprite;

	override function create()
	{
		//Paths.clearStoredMemory();
		//Paths.clearUnusedMemory();

		prevMouseVisible = FlxG.mouse.visible;
		FlxG.mouse.visible = true;

		persistentUpdate = true;
		PlayState.isStoryMode = false;
		WeekData.reloadWeekFiles(false);

		#if desktop
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null);
		#end

		for (i in 0...WeekData.weeksList.length) {
			if(weekIsLocked(WeekData.weeksList[i])) continue;

			var leWeek:WeekData = WeekData.weeksLoaded.get(WeekData.weeksList[i]);
			var leSongs:Array<String> = [];
			var leChars:Array<String> = [];

			for (j in 0...leWeek.songs.length)
			{
				leSongs.push(leWeek.songs[j][0]);
				leChars.push(leWeek.songs[j][1]);
			}

			WeekData.setDirectoryFromWeek(leWeek);
			for (song in leWeek.songs)
			{
				var colors:Array<Int> = song[2];
				if(colors == null || colors.length < 3)
				{
					colors = [146, 113, 253];
				}
				addSong(song[0], i, song[1], FlxColor.fromRGB(colors[0], colors[1], colors[2]));
			}
		}
		WeekData.loadTheFirstEnabledMod();

		/*		//KIND OF BROKEN NOW AND ALSO PRETTY USELESS//

		var initSonglist = CoolUtil.coolTextFile(Paths.txt('freeplaySonglist'));
		for (i in 0...initSonglist.length)
		{
			if(initSonglist[i] != null && initSonglist[i].length > 0) {
				var songArray:Array<String> = initSonglist[i].split(":");
				addSong(songArray[0], 0, songArray[1], Std.parseInt(songArray[2]));
			}
		}*/

		// V-Slice is the only Freeplay UI now. The old toggle let the engine fall back to the
		// pre-0.6.3 list, which no longer lays out correctly (all rows collapsed into one band
		// over the menuDesat background), so that path is retired instead of being selectable.
		vsliceHud = true;

		bg = new FlxSprite();
		if (vsliceHud)
		{
			bg.loadGraphic(Paths.image('freeplay/freeplayBGdad'));
			bg.setGraphicSize(0, FlxG.height + 1);
			bg.updateHitbox();
			bg.x = 388;
			bg.antialiasing = true;
			bg.color = 0xFF9C9C9C;
		}
		else
		{
			bg.loadGraphic(Paths.image('menuDesat'));
			bg.antialiasing = ClientPrefs.globalAntialiasing;
		}
		add(bg);
		if (!vsliceHud) bg.screenCenter();

		if (vsliceHud)
		{
			buildVSliceBacking();

			// The mascot DJ sits behind the list, exactly like P-Slice draws its FreeplayDJ before
			// the capsules. The atlas position (640,366) and the offset are the ones its player
			// registry stores for the BF/Pico freeplay DJs.
			vsliceDj = new FlxAnimate(640, 366);
			vsliceDj.antialiasing = true;
			vsliceDj.visible = vsliceDj.active = false;
			add(vsliceDj);

			grpCapsules = new FlxTypedGroup<FlxSprite>();
			add(grpCapsules);
		}

		grpSongs = new FlxTypedGroup<FlxSprite>();
		add(grpSongs);

		if (vsliceHud)
		{
			// One pre-filtered glow plate is shared by the whole list: it is rebuilt only when the
			// selection changes and always sits under every title (inserted at index 0).
			vsliceTitleGlow = new FlxSprite();
			vsliceTitleGlow.antialiasing = true;
			vsliceTitleGlow.visible = false;
			grpSongs.insert(0, vsliceTitleGlow);
		}

		for (i in 0...songs.length)
		{
			rowTexts.push(null);
			iconArray.push(null);
			capsuleArray.push(null);
			vsliceRowBpm.push(null);
			vsliceRowDiff.push(null);
			vsliceRowY.push(0);
			vsliceRowClip.push(true);
			vsliceRowPixel.push(null);
			vsliceRowDigit.push(null);
			vsliceRowDigit.push(null);
			vsliceRowWeek.push(null);
			vsliceRowRank.push(null);
			vsliceRowRankName.push('');
			vsliceRowNew.push(null);
			for (n in 0...3)
				vsliceRowSmall.push(null);
			filteredSongs.push(i);
		}
		// curSelected is static and can come back from a previous visit larger than the list the
		// modded weeks currently produce, so clamp it BEFORE any row reads it as its anchor.
		if (songs.length == 0)
			curSelected = -1;
		else if (curSelected >= songs.length || curSelected < 0)
			curSelected = 0;
		if (vsliceHud)
			buildVSlicePlayedMap();
		for (i in 0...songs.length)
		{
			buildRow(i);
		}
		WeekData.setDirectoryFromWeek();

		if (vsliceHud)
		{
			buildVSliceChrome();
		}

		scoreText = new FlxText(FlxG.width * 0.7, 5, 0, "", 32);
		scoreText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, RIGHT);

		scoreBG = new FlxSprite(scoreText.x - 6, 0).makeGraphic(1, 66, 0xFF000000);
		scoreBG.alpha = 0.6;
		add(scoreBG);

		diffText = new FlxText(scoreText.x, scoreText.y + 36, 0, "", 24);
		diffText.font = scoreText.font;
		add(diffText);

		add(scoreText);

		if (vsliceHud)
		{
			highscoreArt = new FlxSprite();
			highscoreArt.loadGraphic(Paths.image('freeplay/highscoreLabel'));
			highscoreArt.antialiasing = true;
			highscoreArt.scrollFactor.set();
			highscoreArt.x = FlxG.width - 420;
			highscoreArt.y = 70;
			add(highscoreArt);

			// Seven cyan digital digits, the FreeplayScore of 1.0: 45 px apart, sat on the same line
			// as the P-Slice header (FreeplayScore.hx:50, FreeplayState.hx:346).
			for (i in 0...7)
			{
				var digit:FlxSprite = new FlxSprite(FlxG.width - 353 + i * 45, 120);
				digit.frames = Paths.getSparrowAtlas('freeplay/digital_numbers');
				for (n in NUM_NAMES) digit.animation.addByPrefix(n, n + ' DIGITAL', 24, false);
				digit.animation.play('ZERO', true, false, 0);
				digit.setGraphicSize(Std.int(digit.width * 0.4));
				digit.updateHitbox();
				digit.centerOffsets(false);
				digit.antialiasing = true;
				digit.scrollFactor.set();
				add(digit);
				vsliceScoreDigits.push(digit);
			}
			vsliceDigitAtlas = 'freeplay/digital_numbers';
			setVSliceScore(0);

			// CLEARED box from 1.0's header: completion percentage of the selected song, sitting
			// between the HIGHSCORE wordmark and the score digits.
			vsliceClearBox = new FlxSprite(FlxG.width - 115, 65);
			vsliceClearBox.loadGraphic(Paths.image('freeplay/clearBox'));
			vsliceClearBox.antialiasing = false;
			vsliceClearBox.scrollFactor.set();
			add(vsliceClearBox);

			vsliceClearText = new FlxText(FlxG.width - 95, 87, 0, '0', 30);
			vsliceClearText.setFormat(Paths.font('5by7.ttf'), 30, FlxColor.WHITE, LEFT);
			vsliceClearText.antialiasing = false;
			vsliceClearText.scrollFactor.set();
			add(vsliceClearText);

			scoreBG.visible = false;
			scoreText.visible = false;
			diffText.visible = false;

			#if FREEPLAY
			vsliceDbgText = new FlxText(10, 200, 0, '', 18);
			vsliceDbgText.setFormat(Paths.font('5by7.ttf'), 18, FlxColor.LIME, LEFT);
			vsliceDbgText.text = 'FlxG ' + FlxG.width + 'x' + FlxG.height
				+ '\nstage ' + FlxG.stage.stageWidth + 'x' + FlxG.stage.stageHeight
				+ '\nwin ' + FlxG.stage.window.width + 'x' + FlxG.stage.window.height
				+ '\nscaleClass ' + Type.getClassName(Type.getClass(FlxG.scaleMode))
				+ '\ncam ' + FlxG.camera.zoom
				+ '\niconDarnell ' + Paths.fileExists('images/freeplay/icons/darnellpixel.png', IMAGE)
				+ '\nhsW ' + highscoreArt.width + ' hsX ' + highscoreArt.x;
			vsliceDbgText.scrollFactor.set();
			add(vsliceDbgText);
			#end

			// Album roll, right side: the cover sits straight on the starfield (P-Slice AlbumRoll has
			// no sleeve), ten rating stars straddle its top edge and the title art overlaps its
			// lower-left corner. The title is moved to the top of the draw list after the credits.
			vsliceAlbum = new FlxSprite();
			vsliceAlbum.antialiasing = true;
			vsliceAlbum.angle = 8;
			vsliceAlbum.visible = false;
			add(vsliceAlbum);

			for (i in 0...10)
			{
				var star:FlxSprite = new FlxSprite();
				star.loadGraphic(Paths.image('star1'));
				star.antialiasing = true;
				star.angle = 8;
				star.visible = false;
				add(star);
				vsliceStars.push(star);
			}

			vsliceCredits = new FlxText(0, 0, 285, '', 12);
			vsliceCredits.setFormat(Paths.font("vcr.ttf"), 12, 0xFF3A3A4A, RIGHT);
			vsliceCredits.angle = 8;
			vsliceCredits.scrollFactor.set();
			vsliceCredits.visible = false;
			add(vsliceCredits);

			// AlbumRoll.hx adds newAlbumArt, then difficultyStars, then the title, so the title art
			// draws over the cover's lower edge. Re-add ours at the end of this block to match.
			if (vsliceAlbumTitle != null)
			{
				remove(vsliceAlbumTitle);
				add(vsliceAlbumTitle);
			}
		}

		if (!vsliceHud && curSelected >= 0)
		{
			bg.color = songs[curSelected].color;
			intendedColor = bg.color;
		}

		if(lastDifficultyName == '')
		{
			lastDifficultyName = CoolUtil.defaultDifficulty;
		}
		curDifficulty = Math.round(Math.max(0, CoolUtil.defaultDifficulties.indexOf(lastDifficultyName)));
		
		// V-Slice has no search box and no hint strip: the letter sorter is the way through the
		// list, and the bottom of the screen belongs to the DJ. Both widgets are stock-Limul
		// chrome, so they are only built for the retired pre-V-Slice layout.
		if (!vsliceHud)
		{
			searchLabel = new FlxText(0, 0, 360, 'SEARCH SONGS', 16);
			searchLabel.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT);
			searchLabel.scrollFactor.set();
			add(searchLabel);
			searchField = new FlxUIInputText(0, 0, 360, '', 18, FlxColor.WHITE, 0xFF202020);
			searchField.fieldBorderColor = FlxColor.WHITE;
			searchField.fieldBorderThickness = 1;
			add(searchField);
			searchHint = new FlxText(8, 4, 344, 'Click here and type a song name', 16);
			searchHint.setFormat(Paths.font("vcr.ttf"), 16, 0xFFAAAAAA, LEFT);
			searchHint.scrollFactor.set();
			searchHint.cameras = searchField.cameras;
			add(searchHint);
		}
		positionSearchField();

		refreshSongFilter('');
		changeDiff();

		// LIMUL-FREEPLAY-SCALE: stock Psych built a four letter Alphabet("swag") here, never added it
		// to the state and never read it again - a leftover from the "JUST DOIN THIS SHIT FOR TESTING"
		// block below. It is four letters of sprite construction for nothing, so it is gone.

		// JUST DOIN THIS SHIT FOR TESTING!!!
		/* 
			var md:String = Markdown.markdownToHtml(Assets.getText('CHANGELOG.md'));

			var texFel:TextField = new TextField();
			texFel.width = FlxG.width;
			texFel.height = FlxG.height;
			// texFel.
			texFel.htmlText = md;

			FlxG.stage.addChild(texFel);

			// scoreText.textField.htmlText = md;

			trace(md);
		 */

		// Pre-V-Slice layout only: the V-Slice screen has no bottom hint strip (the DJ owns that space).
		if (!vsliceHud)
		{
			hintBar = new FlxSprite(0, FlxG.height - 26).makeGraphic(FlxG.width, 26, 0xFF000000);
			hintBar.alpha = 0.6;
			add(hintBar);

			var leText:String;
			#if PRELOAD_ALL
			leText = "Click song: select / again: play / wheel: browse / right click: back / SPACE: listen / CTRL: changers / RESET: score";
			var size:Int = 16;
			#else
			leText = "Click song: select / again: play / wheel: browse / right click: back / CTRL: changers / RESET: score";
			var size:Int = 18;
			#end
			var text:FlxText = new FlxText(hintBar.x, hintBar.y + 4, FlxG.width, leText, size);
			text.setFormat(Paths.font("vcr.ttf"), size, FlxColor.WHITE, RIGHT);
			text.scrollFactor.set();
			add(text);
		}

		super.create();
	}

	override function closeSubState() {
		changeSelection(0, false);
		persistentUpdate = true;
		super.closeSubState();
	}

	override function destroy()
	{
		FlxG.mouse.visible = prevMouseVisible;
		destroyFreeplayVocals();
		// The preview track is FlxG.sound.music, which outlives the state; without this the inst
		// keeps playing under the main menu after leaving with RIGHT CLICK.
		if (instPlaying != -1 && FlxG.sound.music != null)
			FlxG.sound.music.stop();
		super.destroy();
	}

	public function addSong(songName:String, weekNum:Int, songCharacter:String, color:Int)
	{
		var weekName:String = weekNum >= 0 && weekNum < WeekData.weeksList.length ? WeekData.weeksList[weekNum] : null;
		songs.push(new SongMetadata(songName, weekNum, songCharacter, color, albumFor(songName, weekName)));
	}

	private function refreshSongFilter(query:String):Void
	{
		lastSearchText = query;
		searchQuery = query.trim().toLowerCase();
		filteredSongs = [];
		filteredSongPositions = [];
		for (i in 0...songs.length)
			filteredSongPositions.push(-1);
		for (i in 0...songs.length)
		{
			if ((searchQuery.length == 0 || songs[i].songName.toLowerCase().contains(searchQuery))
				&& (!vsliceHud || songMatchesLetterFilter(songs[i].songName)))
			{
				filteredSongs.push(i);
				filteredSongPositions[i] = filteredSongs.length - 1;
			}
		}

		if (filteredSongs.length == 0)
		{
			curSelected = -1;
			for (i in 0...rowTexts.length)
			{
				if (rowTexts[i] != null) rowTexts[i].visible = false;
				if (i < vsliceRowClip.length) vsliceRowClip[i] = false;
				if (iconArray[i] != null) iconArray[i].visible = false;
			}
			intendedScore = 0;
			intendedRating = 0;
			diffText.text = 'No songs found';
			if (vsliceHud)
			{
				diffText.visible = true;
				diffText.color = FlxColor.WHITE;
				diffText.x = 640 - diffText.width * 0.5;
				diffText.y = 36;
				refreshVSliceCard();
			}
			return;
		}

		if (!filteredSongs.contains(curSelected))
			curSelected = filteredSongs[0];
		changeSelection(0, false);
	}

	// LIMUL-FREEPLAY-SCALE: builds one row (text + icon) exactly the way the old inline create()
	// loop did, just in one place so changeSelection() can address rows by their real index.
	private function buildRow(i:Int):Void
	{
		if (i < 0 || i >= songs.length) return;
		if (rowTexts[i] != null) return;

		var songText:FlxSprite;
		if (vsliceHud)
		{
			// P-Slice's CapsuleText is a plain white 5by7 label inside the capsule window
			// (SongMenuItem.hx:175, CapsuleText.hx:53); only the selected capsule gets the soft cyan
			// GlowFilter halo (CapsuleText.hx:88-94). The halo cannot live on the FlxText itself -
			// flixel bakes the text field into a bitmap - so updateVSliceRows keeps one pre-filtered
			// glow sprite behind the selected row (refreshVSliceTitleGlow).
			var title:FlxText = new FlxText(0, 0, 290, songs[i].songName, 32);
			title.setFormat(Paths.font('5by7.ttf'), 32, FlxColor.WHITE, LEFT);
			title.wordWrap = false;
			title.antialiasing = false;
			songText = title;
		}
		else
		{
			var alpha:Alphabet = new Alphabet(90, 320, songs[i].songName, true);
			if (alpha.width > 980)
				alpha.scaleX = 980 / alpha.width;
			alpha.snapToPosition();

			// LIMUL-FREEPLAY-SCALE: an AlphaCharacter is one static frame (animation.addByPrefix of a
			// single frame, Alphabet.hx:371), so FlxSprite.update() on it only ever advances a
			// one-frame animation. Only the group lerps toward targetY. FlxGroup.draw() decides on
			// exists/visible and never looks at active (FlxGroup.hx:152-165), so this cannot dim a title.
			for (letter in alpha.letters)
				letter.active = false;
			songText = alpha;
		}
		grpSongs.add(songText);
		rowTexts[i] = songText;

		// The icon lives in the folder of ITS week, so the mod directory is swapped per row and
		// handed back afterwards - create() used to leave it on the last row and reset it once.
		var lastModDirectory:String = Paths.currentModDirectory;
		Paths.currentModDirectory = songs[i].folder;
		var icon:HealthIcon = new HealthIcon(songs[i].songCharacter);
		icon.sprTracker = songText;
		iconArray[i] = icon;
		add(icon);
		Paths.currentModDirectory = lastModDirectory;

		if (i != curSelected)
		{
			songText.alpha = 0.6;
			icon.alpha = 0.6;
		}

		if (vsliceHud)
		{
			icon.sprTracker = null;
			icon.scale.set(0.58, 0.58);
			icon.updateHitbox();
			buildVSliceRow(i);

			// P-Slice draws a tiny pixel character in the capsule nose and only falls back to the
			// ordinary HealthIcon for characters that have no freeplay icon (PixelatedIcon.hx).
			var pixel:FlxSprite = buildVSlicePixelIcon(songs[i].songCharacter);
			if (pixel != null)
			{
				icon.visible = icon.exists = false;
				add(pixel);
				vsliceRowPixel[i] = pixel;
			}
		}
	}

	private static function vslicePixelIconName(char:String):String
	{
		var name:String = char;
		if (name.startsWith('icon-')) name = name.substr(5);
		if (name.endsWith('-playable')) name = name.substr(0, name.length - 9);
		if (name.indexOf('senpai') >= 0) return 'senpai-pixel';
		if (name.indexOf('spirit') >= 0) return 'spirit-pixel';
		if (name.indexOf('parents') >= 0) return 'parents';
		return name;
	}

	private function buildVSlicePixelIcon(char:String):FlxSprite
	{
		var pixel:FlxSprite = createFreeplayPixelIcon(char);
		if (pixel == null) return null;
		pixel.scale.set(2 * VS_CHILD_SCALE, 2 * VS_CHILD_SCALE);
		pixel.updateHitbox();
		return pixel;
	}

	/** PixelatedIcon of P-Slice: freeplay/icons/<character>pixel sparrow, idle at 10 fps, scale 2. */
	public static function createFreeplayPixelIcon(char:String):FlxSprite
	{
		var name:String = vslicePixelIconName(char);
		if (!Paths.fileExists('images/freeplay/icons/' + name + 'pixel.png', IMAGE))
			return null;

		var pixel:FlxSprite = new FlxSprite();
		pixel.frames = Paths.getSparrowAtlas('freeplay/icons/' + name + 'pixel');
		pixel.animation.addByPrefix('idle', 'idle', 10, true);
		pixel.animation.play('idle');
		pixel.antialiasing = false;
		pixel.scale.set(2, 2);
		pixel.updateHitbox();
		return pixel;
	}

	private function buildVSliceRow(i:Int):Void
	{
		var capsule:FlxSprite = new FlxSprite();
		applyVSliceCapsuleSkin(capsule, i == curSelected);
		capsule.antialiasing = true;
		capsule.scale.set(VS_CAPSULE_SCALE, VS_CAPSULE_SCALE);
		grpCapsules.add(capsule);
		capsuleArray[i] = capsule;

		// Every capsule carries its own BPM / DIFFICULTY word art, the same static labels P-Slice
		// draws at the bottom of each SongMenuItem (SongMenuItem.hx:119-149).
		var bpm:FlxSprite = new FlxSprite();
		bpm.loadGraphic(Paths.image('freeplay/freeplayCapsule/bpmtext'));
		bpm.antialiasing = true;
		bpm.scale.set(0.9 * VS_CHILD_SCALE, 0.9 * VS_CHILD_SCALE);
		bpm.visible = false;
		add(bpm);
		vsliceRowBpm[i] = bpm;

		var diff:FlxSprite = new FlxSprite();
		diff.loadGraphic(Paths.image('freeplay/freeplayCapsule/difficultytext'));
		diff.antialiasing = true;
		diff.scale.set(0.9 * VS_CHILD_SCALE, 0.9 * VS_CHILD_SCALE);
		diff.visible = false;
		add(diff);
		vsliceRowDiff[i] = diff;

		// One atlas parse serves all ~400 rows; Paths.getSparrowAtlas re-reads the XML per call.
		if (vsliceAtlasBig == null)
		{
			vsliceAtlasBig = Paths.getSparrowAtlas('freeplay/freeplayCapsule/bignumbers');
			vsliceAtlasSmall = Paths.getSparrowAtlas('freeplay/freeplayCapsule/smallnumbers');
			vsliceAtlasNew = Paths.getSparrowAtlas('freeplay/freeplayCapsule/new');
			vsliceAtlasRank = Paths.getSparrowAtlas('freeplay/rankbadges');
		}

		for (n in 0...2)
		{
			var digit:FlxSprite = new FlxSprite();
			digit.frames = vsliceAtlasBig;
			for (k in NUM_NAMES) digit.animation.addByPrefix(k, k, 1, false);
			digit.animation.play('ZERO', true, false, 0);
			digit.scale.set(0.9 * VS_CHILD_SCALE, 0.9 * VS_CHILD_SCALE);
			digit.antialiasing = true;
			digit.visible = false;
			add(digit);
			vsliceRowDigit[i * 2 + n] = digit;
		}

		// Three shrinking BPM digits at (185 + i*11, 88.5), filled from the chart's starting BPM.
		for (n in 0...3)
		{
			var small:FlxSprite = new FlxSprite();
			small.frames = vsliceAtlasSmall;
			for (k in NUM_NAMES) small.animation.addByPrefix(k, k, 1, false);
			small.animation.play('ZERO', true, false, 0);
			small.scale.set(0.9 * VS_CHILD_SCALE, 0.9 * VS_CHILD_SCALE);
			small.antialiasing = true;
			small.visible = false;
			add(small);
			vsliceRowSmall[i * 3 + n] = small;
		}

		// Week name, the pixel "TUTORIAL" label AtlasText prints at (298, 91) from the V-Slice
		// capsule-text font. The baked graphic is shared by every row of the same week.
		var weekLabel:String = vsliceWeekName(i);
		var weekGraphic:FlxGraphic = vsliceWeekGraphic(weekLabel);
		var week:FlxSprite;
		if (weekGraphic != null)
		{
			week = new FlxSprite();
			week.loadGraphic(weekGraphic);
			week.antialiasing = false;
		}
		else
		{
			// Fallback for a missing atlas: the TTF label this used before.
			var fallback:FlxText = new FlxText(0, 0, 0, weekLabel, 16);
			fallback.setFormat(Paths.font('5by7.ttf'), 16, 0xFFE3DEEC, LEFT);
			fallback.antialiasing = false;
			week = fallback;
		}
		week.visible = false;
		add(week);
		vsliceRowWeek[i] = week;

		// FreeplayRank: one badge per capsule at (420, 41) in the score's rank colours, ADD blend.
		var rank:FlxSprite = new FlxSprite();
		rank.frames = vsliceAtlasRank;
		for (prefix in ['PERFECT rank0', 'EXCELLENT rank0', 'GREAT rank0', 'GOOD rank0', 'LOSS rank0', 'PERFECT rank GOLD'])
			rank.animation.addByPrefix(prefix, prefix, 24, false);
		rank.scale.set(0.9, 0.9);
		rank.antialiasing = true;
		rank.blend = BlendMode.ADD;
		rank.visible = false;
		add(rank);
		vsliceRowRank[i] = rank;

		// NEW tag at (454, 9) until the song has a score; each row starts at a different frame so
		// the bubbling arrows do not march in lockstep (SongMenuItem.hx:421-425).
		var fresh:FlxSprite = new FlxSprite();
		fresh.frames = vsliceAtlasNew;
		fresh.animation.addByPrefix('idle', 'NEW notif', 24, true);
		fresh.animation.play('idle', true);
		if (fresh.animation.curAnim != null)
		{
			var frames:Int = fresh.animation.curAnim.numFrames;
			fresh.animation.curAnim.curFrame = frames - ((fresh.ID * 4) % frames) - 1;
		}
		fresh.scale.set(0.9, 0.9);
		fresh.antialiasing = true;
		fresh.visible = false;
		add(fresh);
		vsliceRowNew[i] = fresh;
	}

	/**
	 * Which songs already have a score in any difficulty. One pass over the save's score map
	 * instead of a Highscore.getScore() call per row - that one writes a 0 entry for every song
	 * it is asked about and would bloat funkin.sol with ~400 dummy scores on entry.
	 */
	private function buildVSlicePlayedMap():Void
	{
		vslicePlayedSongs = new Map();
		if (songs.length == 0) return;
		var bases:Map<String, Bool> = new Map();
		for (meta in songs) bases.set(Paths.formatToSongPath(meta.songName), true);
		for (key in Highscore.songScores.keys())
		{
			if (Highscore.songScores.get(key) <= 0) continue;
			if (bases.exists(key))
			{
				vslicePlayedSongs.set(key, true);
				continue;
			}
			var dash:Int = key.lastIndexOf('-');
			if (dash > 0)
			{
				var trimmed:String = key.substr(0, dash);
				if (bases.exists(trimmed)) vslicePlayedSongs.set(trimmed, true);
			}
		}
	}

	private function vsliceSongKey(i:Int):String
	{
		var key:String = vsliceSongKeys.get(i);
		if (key == null)
		{
			key = Paths.formatToSongPath(songs[i].songName);
			vsliceSongKeys.set(i, key);
		}
		return key;
	}

	private function vsliceSongPlayed(i:Int):Bool
	{
		if (i < 0 || i >= songs.length) return true;
		return vslicePlayedSongs.exists(vsliceSongKey(i));
	}

	/** P-Slice prints the song's starting BPM inside its capsule; read it straight from the chart text. */
	private function vsliceSongBpm(i:Int):Int
	{
		if (i < 0 || i >= songs.length) return 0;
		if (vsliceBpmCache.exists(i)) return vsliceBpmCache.get(i);

		var bpm:Int = 0;
		#if sys
		var lastModDirectory:String = Paths.currentModDirectory;
		Paths.currentModDirectory = songs[i].folder;
		var base:String = Paths.formatToSongPath(songs[i].songName);
		var candidates:Array<Int> = [];
		if (curDifficulty >= 0) candidates.push(curDifficulty);
		if (curDifficulty != 0) candidates.push(0);
		if (curDifficulty != 1) candidates.push(1);

		for (diff in candidates)
		{
			if (bpm > 0) break;
			var formatted:String = Highscore.formatSong(songs[i].songName, diff);
			var raw:String = null;
			#if MODS_ALLOWED
			var moddy:String = Paths.modsJson(base + '/' + formatted);
			try
			{
				if (FileSystem.exists(moddy)) raw = File.getContent(moddy);
			}
			catch (e:Dynamic) raw = null;
			#end
			if (raw == null)
			{
				try raw = File.getContent(Paths.json(base + '/' + formatted))
				catch (e:Dynamic) raw = null;
			}
			if (raw != null) bpm = vsliceScanBpm(raw);
		}

		Paths.currentModDirectory = lastModDirectory;
		#end

		vsliceBpmCache.set(i, bpm);
		return bpm;
	}

	/**
	 * The chart's first "bpm" out of its raw text. Json.parse over a 300 KB note array is the
	 * expensive part of Song.loadFromJson, and the header carries the value right at the top.
	 */
	private static function vsliceScanBpm(raw:String):Int
	{
		var idx:Int = raw.indexOf('"bpm"');
		if (idx < 0) return 0;
		var colon:Int = raw.indexOf(':', idx + 5);
		if (colon < 0) return 0;
		var start:Int = colon + 1;
		while (start < raw.length && StringTools.isSpace(raw, start))
			start++;
		var stop:Int = start;
		while (stop < raw.length)
		{
			var c:String = raw.charAt(stop);
			if (c == '-' || c == '+' || c == '.' || (c >= '0' && c <= '9')) stop++;
			else break;
		}
		var value:Float = Std.parseFloat(raw.substring(start, stop));
		if (value < 1 || value > 1000) return 0;
		return Math.round(value);
	}

	private function queueVSliceBpm(i:Int):Void
	{
		if (vsliceBpmCache.exists(i) || vsliceBpmQueue.indexOf(i) >= 0) return;
		vsliceBpmQueue.push(i);
	}

	// Marked-style rating per difficulty (the same numbers the corner star HUD uses), printed as
	// the capsule's two big digits. A chart's own `starRank` overrides it for the selected row -
	// refreshVSliceCard already parsed that file, so the value comes out of the preview cache.
	private static var DIFFICULTY_RATINGS:Array<Int> = [1, 2, 3, 12, 13, 14];

	private function vsliceDifficultyRating(i:Int):Int
	{
		var diff:Int = curDifficulty < 0 ? 0 : curDifficulty;
		if (i == curSelected && i >= 0 && i < songs.length)
		{
			if (i == vsliceRatingSel && diff == vsliceRatingDiff)
				return vsliceRatingValue;

			var cacheKey:String = songs[i].folder + '|' + vsliceSongKey(i) + '|' + diff;
			var preview:VSlicePreview = vslicePreviewCache.get(cacheKey);
			var value:Int = (preview != null && preview.rank > 0) ? preview.rank
				: (diff < DIFFICULTY_RATINGS.length ? DIFFICULTY_RATINGS[diff] : 0);
			vsliceRatingSel = i;
			vsliceRatingDiff = diff;
			vsliceRatingValue = value;
			return value;
		}
		if (diff < DIFFICULTY_RATINGS.length) return DIFFICULTY_RATINGS[diff];
		return 0;
	}

	private function vsliceRankFor(i:Int):String
	{
		if (i < 0 || i >= songs.length) return '';
		var diff:Int = curDifficulty < 0 ? 0 : curDifficulty;
		if (vsliceRankDiff != diff)
		{
			vsliceRankDiff = diff;
			vsliceRankCache = new Map();
		}

		var cached:String = vsliceRankCache.get(i);
		if (cached != null) return cached;

		var key:String = Highscore.formatSong(songs[i].songName, diff);
		var rank:String = '';
		if (Highscore.songScores.exists(key) && Highscore.songScores.get(key) > 0)
		{
			var acc:Float = Highscore.songRating.exists(key) ? Highscore.songRating.get(key) : 0;
			if (acc >= 1) rank = 'PERFECT rank GOLD';
			else if (acc >= 0.9) rank = 'EXCELLENT rank0';
			else if (acc >= 0.8) rank = 'GREAT rank0';
			else if (acc >= 0.6) rank = 'GOOD rank0';
			else rank = 'LOSS rank0';
		}
		vsliceRankCache.set(i, rank);
		return rank;
	}

	private function vsliceWeekName(i:Int):String
	{
		var w:Int = songs[i].week;
		if (w < 0 || w >= WeekData.weeksList.length) return '';
		var file:String = WeekData.weeksList[w];
		var lower:String = file.toLowerCase();
		if (lower.indexOf('weekend') == 0)
			return 'WEEKEND ' + file.substr(7);
		if (lower.indexOf('week') == 0)
			return 'WEEK ' + file.substr(4);
		if (lower == 'tutorial') return 'TUTORIAL';
		return file.replace('-', ' ').toUpperCase();
	}

	/**
	 * The week name P-Slice renders with its AtlasText pixel font (`fonts/capsule-text`), the same
	 * atlas V-Slice prints "TUTORIAL" with. AtlasText lays one sprite per letter out in a group;
	 * with ~400 rows that ends up as thousands of live sprites, so the text is baked once per
	 * distinct label into a BitmapData and every row shares the resulting graphic.
	 */
	private function vsliceWeekGraphic(label:String):FlxGraphic
	{
		if (label == null || label == '') return null;
		var cached:FlxGraphic = vsliceWeekGraphics.get(label);
		if (cached != null) return cached;

		if (vsliceAtlasCapsuleText == null) vsliceAtlasCapsuleText = Paths.getSparrowAtlas('fonts/capsule-text');
		if (vsliceAtlasCapsuleText == null) return null;

		var lineHeight:Float = 24;
		var spaceWidth:Float = 5;
		var width:Float = 0;
		var cursor:Float = 0;
		var frames:Array<FlxFrame> = [];
		for (i in 0...label.length)
		{
			var ch:String = label.charAt(i);
			if (ch == ' ')
			{
				frames.push(null);
				cursor += spaceWidth;
				continue;
			}
			var frame:FlxFrame = vsliceFindFontFrame(ch);
			frames.push(frame);
			if (frame == null) continue;
			cursor += frame.sourceSize.x;
			if (cursor > width) width = cursor;
		}
		if (width < 1) return null;

		var bmd:BitmapData = new BitmapData(Std.int(Math.ceil(width)), Std.int(lineHeight), true, 0x00000000);
		cursor = 0;
		for (frame in frames)
		{
			if (frame == null)
			{
				cursor += spaceWidth;
				continue;
			}
			// mergeAlpha=true: paint() must not clear the rectangle it is about to stamp onto.
			frame.paint(bmd, new Point(cursor, 0), true, false);
			cursor += frame.sourceSize.x;
		}

		// The atlas glyphs are P-Slice's dark navy, drawn for its light capsule. Our capsule art
		// is the dark V-Slice pill, so the baked text is recoloured once here (constant RGB, the
		// anti-aliased alpha untouched) instead of tinting a dark texture brighter per row.
		bmd.colorTransform(bmd.rect, new ColorTransform(0, 0, 0, 1, 0xE3, 0xDE, 0xEC, 0));

		var graphic:FlxGraphic = FlxGraphic.fromBitmapData(bmd, true, 'vslice-week-' + label, true);
		vsliceWeekGraphics.set(label, graphic);
		return graphic;
	}

	private function vsliceFindFontFrame(ch:String):FlxFrame
	{
		var prefix:String = ch;
		switch (ch)
		{
			case '&': prefix = '-andpersand-';
			case "'": prefix = '-apostrophe-';
			case ',': prefix = '-comma-';
			case '!': prefix = '-exclamation point-';
			case '.': prefix = '-period-';
			case '?': prefix = '-question mark-';
			case '"': prefix = '-quote-';
			case '/': prefix = '-forward slash-';
		}
		for (frame in vsliceAtlasCapsuleText.frames)
		{
			if (frame.name.startsWith(prefix)) return frame;
		}
		return null;
	}

	private function updateVSliceRows(elapsed:Float):Void
	{
		vsliceTime += elapsed;
		var bob:Float = Math.sin(vsliceTime * 6) * 4;
		var glowShown:Bool = false;
		var selPos:Int = (curSelected >= 0 && curSelected < filteredSongPositions.length) ? filteredSongPositions[curSelected] : -1;
		var rowStep:Float = 132 * VS_CAPSULE_SCALE + VS_ROW_GAP;
		// LIMUL-FREEPLAY-SCALE: both lerp factors and the clip edge are the same for every row, so
		// they are computed once instead of two boundTo calls per row per frame.
		var yLerp:Float = CoolUtil.boundTo(elapsed * 9.6, 0, 1);
		var xLerp:Float = CoolUtil.boundTo(elapsed * 12, 0, 1);
		var clipBottom:Float = FlxG.height - 10;

		for (i in 0...songs.length)
		{
			var row:FlxSprite = rowTexts[i];
			var capsule:FlxSprite = capsuleArray[i];
			if (row == null || capsule == null) continue;

			var icon:HealthIcon = iconArray[i];
			var pixel:FlxSprite = i < vsliceRowPixel.length ? vsliceRowPixel[i] : null;
			var bpmLabel:FlxSprite = i < vsliceRowBpm.length ? vsliceRowBpm[i] : null;
			var diffLabel:FlxSprite = i < vsliceRowDiff.length ? vsliceRowDiff[i] : null;
			var bigA:FlxSprite = i < vsliceRowDigit.length ? vsliceRowDigit[i * 2] : null;
			var bigB:FlxSprite = i < vsliceRowDigit.length ? vsliceRowDigit[i * 2 + 1] : null;
			var weekLabel:FlxSprite = i < vsliceRowWeek.length ? vsliceRowWeek[i] : null;
			var rankBadge:FlxSprite = i < vsliceRowRank.length ? vsliceRowRank[i] : null;
			var newBadge:FlxSprite = i < vsliceRowNew.length ? vsliceRowNew[i] : null;
			var filtered:Bool = i < vsliceRowClip.length ? vsliceRowClip[i] : row.visible;
			if (!filtered)
			{
				capsule.visible = capsule.exists = false;
				row.visible = row.exists = false;
				if (icon != null) icon.visible = icon.exists = false;
				if (pixel != null) pixel.visible = pixel.exists = false;
				if (bpmLabel != null) bpmLabel.visible = bpmLabel.exists = false;
				if (diffLabel != null) diffLabel.visible = diffLabel.exists = false;
				if (bigA != null) bigA.visible = bigA.exists = false;
				if (bigB != null) bigB.visible = bigB.exists = false;
				if (weekLabel != null) weekLabel.visible = weekLabel.exists = false;
				if (rankBadge != null) rankBadge.visible = rankBadge.exists = false;
				if (newBadge != null) newBadge.visible = newBadge.exists = false;
				for (n in 0...3)
				{
					var small:FlxSprite = vsliceRowSmall[i * 3 + n];
					if (small != null) small.visible = small.exists = false;
				}
				continue;
			}

			var selected:Bool = i == curSelected;
			var rating:Int = vsliceDifficultyRating(i);
			var pos:Int = filteredSongPositions[i];
			var delta:Float = (pos < 0 || selPos < 0) ? 0 : pos - selPos;

			// P-Slice layouts: y = index * (capsuleHeight * scale + 10) + 120, x = 270 + 60*sin(index).
			var targetY:Float = VS_LIST_Y + delta * rowStep;
			var anchorY:Float = vsliceRowY[i];
			if (Math.abs(anchorY - targetY) > 800) anchorY = targetY;
			anchorY = FlxMath.lerp(anchorY, targetY, yLerp);
			vsliceRowY[i] = anchorY;

			var targetX:Float = VS_LIST_X + 60 * Math.sin(delta + 1) + (selected ? bob * 0.35 : 0);
			if (Math.abs(capsule.x - targetX) > 400) capsule.x = targetX;
			capsule.x = FlxMath.lerp(capsule.x, targetX, xLerp);
			capsule.y = anchorY;
			// P-Slice nudges the unselected capsule art 5 px left inside its frame (SongMenuItem.hx:689).
			capsule.offset.x = selected ? 0 : -5;

			// The scroll view of 1.0 clips its children; without a mask here, rows that slid above
			// the header would draw straight over the letter sorter.
			var show:Bool = anchorY >= VS_LIST_CLIP_TOP && anchorY <= clipBottom;
			// LIMUL-FREEPLAY-SCALE: with ~400 songs only a handful of rows are on screen, yet every
			// row used to run the per-letter group transforms below. Off-screen rows keep just their
			// scroll lerp, and exists=false stops their preUpdate/animation walk and draw test too.
			// Absolute x/y are re-applied on entry, so the frozen letters land exactly where they
			// would have when culled invisibly.
			capsule.visible = capsule.exists = show;
			row.visible = row.exists = show;
			if (icon != null) icon.visible = icon.exists = show && pixel == null;
			if (pixel != null) pixel.visible = pixel.exists = show;
			if (bpmLabel != null) bpmLabel.visible = bpmLabel.exists = show;
			if (diffLabel != null) diffLabel.visible = diffLabel.exists = show;
			if (bigA != null) bigA.visible = bigA.exists = show && rating > 0;
			if (bigB != null) bigB.visible = bigB.exists = show && rating > 0;
			if (weekLabel != null) weekLabel.visible = weekLabel.exists = show;
			for (n in 0...3)
			{
				var small:FlxSprite = vsliceRowSmall[i * 3 + n];
				if (small != null) small.visible = small.exists = show;
			}
			if (rankBadge != null) rankBadge.visible = rankBadge.exists = show;
			if (newBadge != null) newBadge.visible = newBadge.exists = show;
			if (!show) continue;

			capsule.alpha = 1;
			row.x = capsule.x + 159 * VS_CHILD_SCALE;
			row.y = anchorY + 45 * VS_CHILD_SCALE;

			// CapsuleText's GlowFilter follows the selected capsule (CapsuleText.hx:88-94). FlxText
			// bakes its text field into a bitmap, so the halo is a separate pre-filtered sprite that
			// is rebuilt only when the cursor lands on another song.
			if (vsliceTitleGlow != null && selected)
			{
				if (vsliceGlowFor != i)
				{
					vsliceGlowFor = i;
					refreshVSliceTitleGlow(Std.isOfType(row, FlxText) ? cast(row, FlxText) : null);
				}
				vsliceTitleGlow.x = row.x - GLOW_PAD;
				vsliceTitleGlow.y = row.y - GLOW_PAD;
				vsliceTitleGlow.visible = vsliceTitleGlow.exists = true;
				glowShown = true;
			}

			if (pixel != null)
			{
				pixel.x = capsule.x + 60 * VS_CHILD_SCALE + (selected ? bob * 0.25 : 0);
				pixel.y = capsule.y + 14 * VS_CHILD_SCALE;
			}
			else if (icon != null)
			{
				icon.alpha = selected ? 1 : 0.55;
				icon.x = capsule.x + 60 * VS_CHILD_SCALE + (selected ? bob * 0.25 : 0);
				icon.y = capsule.y + 14 * VS_CHILD_SCALE;
			}
			if (bpmLabel != null)
			{
				bpmLabel.x = capsule.x + 144 * VS_CHILD_SCALE;
				bpmLabel.y = capsule.y + 87 * VS_CHILD_SCALE;
			}
			if (diffLabel != null)
			{
				diffLabel.x = capsule.x + 414 * VS_CHILD_SCALE;
				diffLabel.y = capsule.y + 87 * VS_CHILD_SCALE;
			}
			if (bigA != null) bigA.x = capsule.x + 466 * VS_CHILD_SCALE;
			if (bigB != null) bigB.x = capsule.x + 496 * VS_CHILD_SCALE;
			if (bigA != null)
			{
				var high:Int = Std.int(rating / 10);
				setPixelDigit(bigA, high);
				bigA.y = capsule.y + 32 * VS_CHILD_SCALE;
				bigA.centerOffsets(false);
				if (high == 1) bigA.offset.x -= 4 * VS_CHILD_SCALE;
			}
			if (bigB != null)
			{
				var low:Int = rating % 10;
				setPixelDigit(bigB, low);
				bigB.y = capsule.y + 32 * VS_CHILD_SCALE;
				bigB.centerOffsets(false);
				if (low == 1) bigB.offset.x -= 4 * VS_CHILD_SCALE;
			}

			// Week name at the bottom of the capsule (AtlasText at 298, 91 in SongMenuItem).
			if (weekLabel != null)
			{
				weekLabel.x = capsule.x + 298 * VS_CHILD_SCALE;
				weekLabel.y = capsule.y + 91 * VS_CHILD_SCALE;
			}

			// The three shrinking BPM digits; SongMenuItem.updateBPM shifts the block by 5 px when
			// the hundreds digit is a one and pulls the tens/ones in when the tens digit is a one.
			var bpm:Int = 0;
			if (vsliceBpmCache.exists(i)) bpm = vsliceBpmCache.get(i);
			else queueVSliceBpm(i);
			var showBpm:Bool = bpm > 0;
			var shiftX:Float = 191;
			if (Math.floor(bpm / 100) == 1) shiftX = 186;
			var tempShift:Float = 0;
			var tens:Int = Math.floor(bpm / 10) % 10;
			for (n in 0...3)
			{
				var spr:FlxSprite = vsliceRowSmall[i * 3 + n];
				if (spr == null) continue;
				spr.visible = spr.exists = showBpm;
				if (!showBpm) continue;
				if (n == 1 && tens == 1) tempShift = -4;
				// LIMUL-FREEPLAY-SCALE: 10^(2-n) as a lookup instead of a Math.pow per digit.
				var digit:Int = Std.int(bpm / VS_DIGIT_DIVISORS[n]) % 10;
				setPixelDigit(spr, digit);
				spr.x = capsule.x + shiftX + n * 11 + tempShift;
				spr.y = capsule.y + 88.5 * VS_CHILD_SCALE;
			}

			// Score rank badge of the current difficulty (FreeplayRank at 420, 41).
			if (rankBadge != null)
			{
				var prefix:String = vsliceRankFor(i);
				rankBadge.visible = rankBadge.exists = prefix != '';
				if (prefix != '')
				{
					if (vsliceRowRankName[i] != prefix)
					{
						vsliceRowRankName[i] = prefix;
						rankBadge.animation.play(prefix, true);
						rankBadge.centerOffsets(false);
						if (prefix == 'GOOD rank0' || prefix == 'GREAT rank0') rankBadge.offset.y -= 8;
					}
					rankBadge.x = capsule.x + 420 * VS_CHILD_SCALE;
					rankBadge.y = capsule.y + 41 * VS_CHILD_SCALE;
				}
			}

			// NEW tag until the song has a score on any difficulty (the second half of the proof
			// is P-Slice's songData.isNew, SongMenuItem.hx:420).
			if (newBadge != null)
			{
				var isNew:Bool = !vsliceSongPlayed(i);
				newBadge.visible = newBadge.exists = isNew;
				if (isNew)
				{
					newBadge.x = capsule.x + 454 * VS_CHILD_SCALE;
					newBadge.y = capsule.y + 9 * VS_CHILD_SCALE;
				}
			}
		}

		// Chart headers are read one per frame; visible rows never wait behind a full 400-row scan.
		if (vsliceTitleGlow != null && !glowShown)
			vsliceTitleGlow.visible = vsliceTitleGlow.exists = false;
		var bpmBudget:Int = 2;
		while (bpmBudget > 0 && vsliceBpmQueue.length > 0)
		{
			var rowIndex:Int = vsliceBpmQueue.shift();
			vsliceSongBpm(rowIndex);
			bpmBudget--;
		}
	}

	private function setPixelDigit(spr:FlxSprite, digit:Int):Void
	{
		if (digit < 0) digit = 0;
		if (digit > 9) digit = 9;
		var name:String = NUM_NAMES[digit];
		if (spr.animation.curAnim == null || spr.animation.curAnim.name != name)
			spr.animation.play(name, true);
	}

	private function applyVSliceCapsuleSkin(capsule:FlxSprite, selected:Bool):Void
	{
		if (vsliceStylePico)
		{
			// Shared atlas: Paths.getSparrowAtlas parses the XML on every call, and applyVSliceStyle
			// re-skins every capsule (398 of them) whenever the selection crosses a week style.
			if (vsliceAtlasCapsulePico == null) vsliceAtlasCapsulePico = Paths.getSparrowAtlas('freeplay/capsule_pico');
			capsule.frames = vsliceAtlasCapsulePico;
			capsule.animation.addByPrefix('sel', 'mp3 capsule w backing0', 10, true);
			capsule.animation.addByPrefix('idle', 'mp3 capsule w backing NOT SELECTED', 10, true);
		}
		else
		{
			if (vsliceAtlasCapsule == null) vsliceAtlasCapsule = Paths.getSparrowAtlas('freeplay/vsliceCapsule');
			capsule.frames = vsliceAtlasCapsule;
			capsule.animation.addByPrefix('sel', 'sel', 10, true);
			capsule.animation.addByPrefix('idle', 'idle', 10, true);
		}
		capsule.animation.play(selected ? 'sel' : 'idle');
	}

	private function isPicoWeek(week:Int):Bool
	{
		if (week < 0 || week >= WeekData.weeksList.length) return false;
		return WeekData.weeksList[week].toLowerCase().indexOf('weekend1') >= 0;
	}

	// The V-Slice style (BF or Pico) is picked per week, exactly like P-Slice's freeplay styles,
	// and only rebuilt when the selection crosses into another style - the capsules keep their
	// own atlas, so a 400-song list must not be re-skinned on every arrow press.
	private function applyVSliceStyle():Void
	{
		if (!vsliceHud || curSelected < 0 || curSelected >= songs.length) return;
		var pico:Bool = isPicoWeek(songs[curSelected].week);
		if (vsliceStyleInit && pico == vsliceStylePico) return;
		vsliceStylePico = pico;
		vsliceStyleInit = true;

		if (bg != null)
		{
			bg.loadGraphic(Paths.image(pico ? 'freeplay/freeplayBGdadPico' : 'freeplay/freeplayBGdad'));
			bg.setGraphicSize(0, FlxG.height + 1);
			bg.updateHitbox();
			bg.x = 388;
			bg.color = 0xFF9C9C9C;
		}
		applyVSliceDjSkin();

		for (arrow in vsliceDiffArrowArt)
		{
			arrow.frames = Paths.getSparrowAtlas(vsliceStylePico ? 'freeplay/selector_pico' : 'freeplay/selector');
			arrow.animation.addByPrefix('loop', 'arrow pointer loop', 15, true);
			arrow.animation.play('loop');
		}

		var digitAtlas:String = pico ? 'freeplay/digital_numbers_pico' : 'freeplay/digital_numbers';
		if (vsliceScoreDigits.length > 0 && vsliceDigitAtlas != digitAtlas)
		{
			vsliceDigitAtlas = digitAtlas;
			var digitFrames = Paths.getSparrowAtlas(digitAtlas);
			for (digit in vsliceScoreDigits)
			{
				digit.frames = digitFrames;
				for (n in NUM_NAMES) digit.animation.addByPrefix(n, n + ' DIGITAL', 24, false);
			}
			vsliceScoreValue = -1;
		}

		for (i in 0...capsuleArray.length)
		{
			var capsule:FlxSprite = capsuleArray[i];
			if (capsule == null) continue;
			applyVSliceCapsuleSkin(capsule, i == curSelected);
		}
	}

	private function applyVSliceDjSkin():Void
	{
		if (vsliceDj == null) return;
		var pico:Bool = vsliceStylePico;
		var atlas:String = pico ? 'freeplay/freeplay-pico' : 'freeplay/freeplay-boyfriend';
		if (vsliceDjAtlas == atlas) return;
		vsliceDjAtlas = atlas;

		Paths.loadAnimateAtlas(vsliceDj, atlas);
		if (pico)
		{
			vsliceDj.anim.addBySymbolIndices('intro', 'pico dj intro', [for (i in 0...17) i], 24, false);
			vsliceDj.anim.addBySymbolIndices('idle', 'Pico DJ', [for (i in 0...14) i], 24, true);
			vsliceDj.anim.addBySymbolIndices('confirm', 'Pico DJ confirm', [for (i in 0...20) i], 24, false);
		}
		else
		{
			vsliceDj.anim.addBySymbolIndices('intro', 'boyfriend dj intro', [for (i in 0...17) i], 24, false);
			vsliceDj.anim.addBySymbolIndices('idle', 'Boyfriend DJ', [for (i in 0...14) i], 24, true);
			vsliceDj.anim.addBySymbolIndices('confirm', 'Boyfriend DJ confirm', [for (i in 0...30) i], 24, false);
		}
		vsliceDj.anim.onComplete.add(vsliceDjFinished);
		vsliceDj.visible = vsliceDj.active = true;
		vsliceDj.anim.play('intro');
		vsliceDjState = 'intro';
	}

	private function vsliceDjFinished():Void
	{
		if (vsliceDjState == 'intro')
		{
			vsliceDjState = 'idle';
			if (vsliceDj != null) vsliceDj.anim.play('idle');
		}
	}

	private function updateVSliceDj(elapsed:Float):Void
	{
		if (vsliceConfirmTimer < 0) return;
		vsliceConfirmTimer -= elapsed;
		if (vsliceConfirmTimer > 0) return;

		vsliceConfirmTimer = -1;
		var action:Void->Void = vsliceConfirmAction;
		vsliceConfirmAction = null;
		persistentUpdate = false;
		if (action != null) action();
	}

	private function updateVSliceHeader(elapsed:Float):Void
	{
		// The marquee rows scroll themselves (BGScrollingText.update), exactly like P-Slice.
		setVSliceScore(Std.int(lerpScore));
	}

	private function setVSliceScore(value:Int):Void
	{
		if (value == vsliceScoreValue || vsliceScoreDigits.length == 0) return;
		vsliceScoreValue = value;
		var digits:String = Std.string(value < 0 ? 0 : value);
		if (digits.length > vsliceScoreDigits.length)
			digits = digits.substr(digits.length - vsliceScoreDigits.length);
		while (digits.length < vsliceScoreDigits.length)
			digits = '0' + digits;

		for (i in 0...vsliceScoreDigits.length)
		{
			var digit:Int = Std.parseInt(digits.charAt(i));
			var spr:FlxSprite = vsliceScoreDigits[i];
			var name:String = NUM_NAMES[digit];
			if (spr.animation.curAnim != null && spr.animation.curAnim.name == name) continue;
			spr.animation.play(name, true, false, 0);
			spr.updateHitbox();
			if (digit == 1) spr.offset.x -= 15;
			else spr.centerOffsets(false);
		}
	}

	// The left half of 1.0's Freeplay: light card that slides in, the mustard band and the big
	// scrolling marquee lines. The DJ is added on top by create().
	private function buildVSliceBacking():Void
	{
		var cardScale:Float = FlxG.height / 760;
		vsliceBackCard = new FlxSprite(-524 * cardScale, 0);
		vsliceBackCard.loadGraphic(Paths.image('freeplay/pinkBack'));
		vsliceBackCard.setGraphicSize(Std.int(524 * cardScale), FlxG.height);
		vsliceBackCard.updateHitbox();
		vsliceBackCard.color = 0xFFFFD4E9;
		vsliceBackCard.antialiasing = true;
		add(vsliceBackCard);
		FlxTween.tween(vsliceBackCard, {x: 0}, 0.6, {ease: FlxEase.quartOut});

		vsliceOrangeEdge = new FlxSprite(0, 440).makeGraphic(100, 74, 0xFFFFD400);
		add(vsliceOrangeEdge);
		vsliceOrangeStrip = new FlxSprite(84, 440).makeGraphic(440, 74, 0xFFFEDA00);
		add(vsliceOrangeStrip);

		// Marquee rows exactly where P-Slice's BoyfriendCard puts its BGScrollingText lines
		// (BoyfriendCard.hx:85-90): 160/285/397 are the 43 px "more ways"/"nuts" rows, 220/335 are
		// the 60 px "BOYFRIEND" rows and the sixth rides the mustard band at 450. Each line is
		// tiled by BGScrollingText, so the card always shows continuous words. `speed` stays in
		// P-Slice's pixels-per-60th-second units (6.8 / -3.8 / 3.5).
		var texts:Array<String> = ['HOT BLOODED IN MORE WAYS THAN ONE', 'BOYFRIEND', 'PROTECT YO NUTS',
			'BOYFRIEND', 'HOT BLOODED IN MORE WAYS THAN ONE', 'BOYFRIEND'];
		var sizes:Array<Int> = [43, 60, 43, 60, 43, 60];
		var ys:Array<Float> = [160, 220, 285, 335, 397, 450];
		var speeds:Array<Float> = [6.8, -3.8, 3.5, -3.8, 6.8, -3.8];
		var colors:Array<Int> = [0xFFFFF383, 0xFFFF9963, 0xFFFFFFFF, 0xFFFF9963, 0xFFFFF383, 0xFFFEA400];
		var widths:Array<Float> = [FlxG.width, FlxG.width / 2, FlxG.width / 2, FlxG.width / 2, FlxG.width, FlxG.width / 2];
		for (i in 0...texts.length)
		{
			var marquee:BGScrollingText = new BGScrollingText(0, ys[i], texts[i], widths[i], i % 2 == 0, sizes[i]);
			marquee.color = colors[i];
			marquee.speed = speeds[i];
			marquee.scrollFactor.set();
			marquee.clipRight = 524 * cardScale;
			add(marquee);
		}
	}

	private function buildVSliceChrome():Void
	{
		// The black overhang is the first thing drawn; the difficulty plate, the letters and the
		// score all sit on top of it, exactly like 1.0's Freeplay header.
		vsliceTopBar = new FlxSprite(0, 0).makeGraphic(FlxG.width, 64, 0xFF000000);
		add(vsliceTopBar);

		vsliceTitle = new FlxText(8, 8, 0, 'FREEPLAY', 48);
		vsliceTitle.setFormat(Paths.font("vcr.ttf"), 48, FlxColor.WHITE, LEFT);
		vsliceTitle.scrollFactor.set();
		add(vsliceTitle);

		vsliceOstText = new FlxText(0, 6, 0, 'OFFICIAL OST', 44);
		vsliceOstText.setFormat(Paths.font("vcr.ttf"), 44, FlxColor.WHITE, RIGHT);
		vsliceOstText.scrollFactor.set();
		vsliceOstText.x = FlxG.width - vsliceOstText.width - 12;
		add(vsliceOstText);

		// P-Slice's AlbumRoll is just the tilted cover, the stars and the title art - there is no
		// white sleeve behind it (AlbumRoll.hx:49-62). The cover, stars and credits are created
		// right after the chrome, in create(); the title is re-added there so it draws over the
		// cover's lower edge (AlbumRoll.hx:206).
		vsliceAlbumTitle = new FlxSprite();
		vsliceAlbumTitle.antialiasing = true;
		vsliceAlbumTitle.angle = 8;
		vsliceAlbumTitle.visible = false;
		add(vsliceAlbumTitle);

		vsliceDiffArt = new FlxSprite();
		vsliceDiffArt.antialiasing = true;
		vsliceDiffArt.visible = false;
		add(vsliceDiffArt);

		for (side in 0...2)
		{
			var arrow:FlxSprite = new FlxSprite();
			arrow.frames = Paths.getSparrowAtlas('freeplay/selector');
			arrow.animation.addByPrefix('loop', 'arrow pointer loop', 15, true);
			arrow.animation.play('loop');
			arrow.antialiasing = true;
			arrow.flipX = side == 0;
			arrow.scale.set(1.2, 1.2);
			arrow.visible = false;
			add(arrow);
			vsliceDiffArrowArt.push(arrow);
		}

		var atlas = Paths.getSparrowAtlas('freeplay/letterStuff');
		// P-Slice's LetterSort order: '#', the favourites heart, ALL, then A-Z. ALL is the middle
		// slot on entry (curSelection starts at 2 there for exactly this reason).
		vsliceLetterFilters = ['#', 'fav', 'ALL'];
		for (i in 0...26)
			vsliceLetterFilters.push(String.fromCharCode(65 + i));

		for (i in 0...5)
		{
			var letter:FlxSprite = new FlxSprite();
			letter.frames = atlas;
			for (filter in vsliceLetterFilters)
				letter.animation.addByPrefix(filter, vsliceLetterPrefix(filter), 1, false);
			letter.antialiasing = false;
			add(letter);
			vsliceLetters.push(letter);
		}

		for (i in 0...4)
		{
			var dot:FlxSprite = new FlxSprite().loadGraphic(Paths.image('freeplay/seperator'));
			dot.alpha = 0.85;
			add(dot);
			vsliceLetterSeparators.push(dot);
		}

		for (side in 0...2)
		{
			var arrow:FlxSprite = new FlxSprite().loadGraphic(Paths.image('freeplay/miniArrow'));
			arrow.antialiasing = false;
			arrow.flipX = side == 0;
			add(arrow);
			vsliceLetterArrows.push(arrow);
		}
		updateVSliceLetters();
	}

	private function vsliceLetterPrefix(filter:String):String
	{
		if (filter == 'ALL') return 'ALL instance';
		if (filter == '#') return '# instance';
		if (filter == 'fav') return 'fav instance';
		return filter.toLowerCase() + ' instance';
	}

	private function updateVSliceLetters():Void
	{
		// LetterSort in P-Slice: the group sits at (400, 75), letter pivots at +50 -> five 80 px
		// slots starting at 450 with their centres on y=125. The middle letter is full size and
		// the neighbours are 0.8, each darkened by |i-2|/6. The row hangs under the black header,
		// not over the capsules.
		var total:Int = vsliceLetterFilters.length;
		var step:Float = 80;
		var baseX:Float = 450;
		var midY:Float = 125;
		for (i in 0...vsliceLetters.length)
		{
			var filter:String = vsliceLetterFilters[((vsliceLetterIndex + i - 2) % total + total) % total];
			var letter:FlxSprite = vsliceLetters[i];
			letter.animation.play(filter);
			letter.visible = true;
			var letterScale:Float = i == 2 ? 1 : 0.8;
			letter.scale.set(letterScale, letterScale);
			letter.color = i == 2 ? 0xFFFFFFFF : whiteShade(Math.abs(i - 2) / 6);
			// frameWidth/Height are the unscaled atlas frames; width/height already include the
			// scale, so using them here would shift the letter half a slot to the left.
			letter.x = baseX + i * step - letter.frameWidth * letterScale * 0.5;
			letter.y = midY - letter.frameHeight * letterScale * 0.5;
		}
		for (i in 0...vsliceLetterSeparators.length)
		{
			var dot:FlxSprite = vsliceLetterSeparators[i];
			dot.x = baseX + i * step + step * 0.5 - dot.width * 0.5;
			dot.y = midY - dot.height * 0.5;
			dot.alpha = 0.75;
		}
		var left:FlxSprite = vsliceLetterArrows[0];
		var right:FlxSprite = vsliceLetterArrows[1];
		left.x = 380;
		left.y = 90;
		right.x = 780;
		right.y = 90;
	}

	private static inline function whiteShade(darken:Float):Int
	{
		var c:Int = Std.int(255 * (1 - darken));
		return 0xFF000000 | (c << 16) | (c << 8) | c;
	}

	private function changeVSliceLetter(diff:Int):Void
	{
		var total:Int = vsliceLetterFilters.length;
		vsliceLetterIndex = ((vsliceLetterIndex + diff) % total + total) % total;
		updateVSliceLetters();
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
		refreshSongFilter(searchField != null ? searchField.text : '');
	}

	private function selectVSliceLetter(slot:Int):Void
	{
		var total:Int = vsliceLetterFilters.length;
		var picked:Int = ((vsliceLetterIndex + slot - 2) % total + total) % total;
		if (picked == vsliceLetterIndex) return;
		vsliceLetterIndex = picked;
		updateVSliceLetters();
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
		refreshSongFilter(searchField != null ? searchField.text : '');
	}

	private function songMatchesLetterFilter(name:String):Bool
	{
		var filter:String = vsliceLetterFilters.length > 0 ? vsliceLetterFilters[vsliceLetterIndex] : 'ALL';
		// 0.6.3 has no favourites store, so that slot behaves like "show everything".
		if (filter == 'ALL' || filter == 'fav' || filter.length == 0) return true;
		var first:String = name.substr(0, 1).toUpperCase();
		if (filter == '#') return first >= '0' && first <= '9';
		return first == filter;
	}

	private static var DIFF_ART:Map<String, String> = [
		'easy' => 'freeplayeasy', 'normal' => 'freeplaynormal', 'hard' => 'freeplayhard',
		'erect' => 'freeplayerect', 'nightmare' => 'freeplaynightmare'
	];

	private function refreshVSliceDiffArt():Void
	{
		if (!vsliceHud || vsliceDiffArt == null) return;
		var hasSel:Bool = !(curSelected < 0 || curSelected >= songs.length || curDifficulty < 0 || curDifficulty >= CoolUtil.difficulties.length);
		for (arrow in vsliceDiffArrowArt)
			arrow.visible = hasSel;
		if (!hasSel)
		{
			vsliceDiffArt.visible = false;
			diffText.visible = false;
			return;
		}

		var diffName:String = CoolUtil.difficulties[curDifficulty];
		var artKey:String = DIFF_ART.get(diffName.toLowerCase());
		if (artKey == null)
		{
			vsliceDiffArt.visible = false;
			vsliceDiffKey = '';
			diffText.visible = true;
			diffText.color = 0xFFFFFFFF;
			diffText.text = diffName.toUpperCase();
			diffText.x = 205 - diffText.width * 0.5;
			diffText.y = 98;
		}
		else
		{
			diffText.visible = false;
			vsliceDiffArt.visible = true;
			if (vsliceDiffKey != artKey)
			{
				vsliceDiffKey = artKey;
				if (artKey == 'freeplaynightmare')
				{
					vsliceDiffArt.frames = Paths.getSparrowAtlas('freeplay/difficulties/' + artKey);
					vsliceDiffArt.animation.addByPrefix('idle', 'idle', 24, true);
					vsliceDiffArt.animation.play('idle');
				}
				else
				{
					vsliceDiffArt.loadGraphic(Paths.image('freeplay/difficulties/' + artKey));
				}
				vsliceDiffArt.scale.set(1.05, 1.05);
				vsliceDiffArt.updateHitbox();
			}
			vsliceDiffArt.x = 205 - vsliceDiffArt.width * 0.5;
			vsliceDiffArt.y = 118 - vsliceDiffArt.height * 0.5;
		}

		vsliceDiffArrowArt[0].x = 26;
		vsliceDiffArrowArt[0].y = 70;
		vsliceDiffArrowArt[1].x = 332;
		vsliceDiffArrowArt[1].y = 70;
	}

	private function vsliceChromeHover():Bool
	{
		if (FlxG.mouse.y < 172) return true;
		for (letter in vsliceLetters)
			if (FlxG.mouse.overlaps(letter)) return true;
		for (arrow in vsliceLetterArrows)
			if (FlxG.mouse.overlaps(arrow)) return true;
		return false;
	}

	// Pointer route for the V-Slice chrome (letter filter, difficulty plates). Returns true when
	// the click belonged to the chrome, so the song list below must not also act on it.
	private function vsliceChromeClick():Bool
	{
		if (!vsliceHud || !FlxG.mouse.justPressed || vsliceConfirmTimer >= 0) return false;
		for (i in 0...vsliceLetters.length)
		{
			if (FlxG.mouse.overlaps(vsliceLetters[i]))
			{
				selectVSliceLetter(i);
				return true;
			}
		}
		for (i in 0...vsliceLetterArrows.length)
		{
			if (FlxG.mouse.overlaps(vsliceLetterArrows[i]))
			{
				changeVSliceLetter(i == 0 ? -1 : 1);
				return true;
			}
		}
		if (vsliceDiffArt.visible && FlxG.mouse.overlaps(vsliceDiffArt) && vsliceDiffArt.width > 0)
		{
			changeDiff(FlxG.mouse.x < vsliceDiffArt.x + vsliceDiffArt.width * 0.5 ? -1 : 1);
			FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
			return true;
		}
		for (i in 0...vsliceDiffArrowArt.length)
		{
			if (vsliceDiffArrowArt[i].visible && FlxG.mouse.overlaps(vsliceDiffArrowArt[i]))
			{
				changeDiff(i == 0 ? -1 : 1);
				FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
				return true;
			}
		}
		return false;
	}

	// V-Slice album cards: the cover each built-in song shows in 1.0's Freeplay, taken from that
	// game's own metadata (albumId). Mod songs walk back to their week's volume, then to the
	// placeholder cover.
	private static var ALBUM_BY_SONG:Map<String, String> = [
		'tutorial' => 'volume1', 'bopeebo' => 'volume1', 'fresh' => 'volume1', 'dad-battle' => 'volume1',
		'spookeez' => 'volume1', 'south' => 'volume1', 'monster' => 'volume1', 'pico' => 'volume1',
		'philly-nice' => 'volume1', 'blammed' => 'volume1', 'satin-panties' => 'volume1', 'high' => 'volume1',
		'milf' => 'volume1', 'cocoa' => 'volume1', 'eggnog' => 'volume1', 'winter-horrorland' => 'volume1',
		'senpai' => 'volume2alt', 'roses' => 'volume2alt', 'thorns' => 'volume2alt',
		'ugh' => 'volume2', 'guns' => 'volume2', 'stress' => 'volume2',
		'darnell' => 'volume3', 'lit-up' => 'volume3', '2hot' => 'volume3', 'blazin' => 'volume3'
	];

	private static var ALBUM_BY_WEEK:Map<String, String> = [
		'tutorial' => 'volume1', 'week1' => 'volume1', 'week2' => 'volume1', 'week3' => 'volume1',
		'week4' => 'volume1', 'week5' => 'volume1', 'week6' => 'volume2alt', 'week7' => 'volume2',
		'weekend1' => 'volume3'
	];

	private function albumFor(songName:String, weekName:String):String
	{
		var album:String = ALBUM_BY_SONG.get(Paths.formatToSongPath(songName));
		if (album == null && weekName != null) album = ALBUM_BY_WEEK.get(weekName.toLowerCase());
		return album != null ? album : 'default';
	}

	/**
	 * Bakes P-Slice's capsule glow: a GlowFilter pass over a padded copy of the selected title's
	 * bitmap (CapsuleText.hx:88-94 applies the same filter to its text field). Only one such
	 * texture exists at a time, so the ~400-row list stays a single extra draw call.
	 */
	private function refreshVSliceTitleGlow(title:FlxText):Void
	{
		if (vsliceTitleGlow == null) return;
		if (title == null || title.graphic == null)
		{
			if (vsliceGlowFor != -1) vsliceTitleGlow.visible = false;
			return;
		}

		@:privateAccess title.regenGraphic();
		var src:BitmapData = title.graphic != null ? title.graphic.bitmap : null;
		if (src == null || src.width <= 0 || src.height <= 0)
		{
			vsliceTitleGlow.visible = false;
			return;
		}

		var padded:BitmapData = new BitmapData(src.width + GLOW_PAD * 2, src.height + GLOW_PAD * 2, true, 0);
		padded.draw(src, new Matrix(1, 0, 0, 1, GLOW_PAD, GLOW_PAD));
		var glow:BitmapData = new BitmapData(padded.width, padded.height, true, 0);
		glow.applyFilter(padded, padded.rect, new Point(0, 0), new GlowFilter(0xFF00CCFF, 1, 8, 8, 1.8, BitmapFilterQuality.MEDIUM));
		padded.dispose();

		var previous:BitmapData = vsliceGlowBmd;
		vsliceGlowBmd = glow;
		vsliceTitleGlow.loadGraphic(glow);
		if (previous != null) previous.dispose();
	}

	private function refreshVSliceCard():Void
	{
		if (!vsliceHud || vsliceAlbum == null) return;
		applyVSliceStyle();
		if (curSelected < 0 || curSelected >= songs.length)
		{
			vsliceAlbum.visible = false;
			for (star in vsliceStars) star.visible = false;
			if (vsliceCredits != null) vsliceCredits.visible = false;
			if (vsliceAlbumTitle != null) vsliceAlbumTitle.visible = false;
			return;
		}

		var meta:SongMetadata = songs[curSelected];
		if (meta.album != vsliceAlbumId)
		{
			vsliceAlbumId = meta.album;
			vsliceAlbum.loadGraphic(Paths.image('freeplay/albums/' + (meta.album == 'volume2alt' ? 'volume2-alt' : meta.album)));
			var coverScale:Float = ALBUM_CARD_WIDTH / vsliceAlbum.width;
			vsliceAlbum.scale.set(coverScale, coverScale);
			vsliceAlbum.updateHitbox();
			vsliceAlbum.y = ALBUM_CARD_TOP;

			var titleKey:String = vsliceAlbumTextKey(meta.album);
			vsliceAlbumTitle.visible = titleKey != null;
			if (titleKey != null)
			{
				vsliceAlbumTitle.frames = Paths.getSparrowAtlas('freeplay/albumTitles/' + titleKey + '-text');
				vsliceAlbumTitle.animation.addByPrefix('idle', 'idle', 12, true);
				vsliceAlbumTitle.animation.play('idle');
			}
		}
		vsliceAlbum.visible = true;

		var cacheKey:String = meta.folder + '|' + Paths.formatToSongPath(meta.songName) + '|' + curDifficulty;
		var preview:VSlicePreview = vslicePreviewCache.get(cacheKey);
		if (preview == null)
		{
			// Credits and the star rank live in the chart itself, so the card reads the same file
			// Play would load - one parse per (song, difficulty, mod folder) per menu visit, after
			// which only the four values the card renders are kept.
			var chart:Dynamic = null;
			try
			{
				chart = Song.loadFromJson(Highscore.formatSong(meta.songName, curDifficulty), meta.songName);
			}
			catch (e:Dynamic)
			{
				chart = null;
			}
			var credits:Array<String> = chart != null ? Song.getSongCredits(chart) : Song.getCreditData(meta.songName);
			var rank:Int = chart != null ? Song.getStarRank(chart) : Song.NO_STAR_RANK;
			var bpm:Int = 0;
			if (chart != null && chart.bpm != null)
				bpm = Std.int(chart.bpm);
			chart = null;
			preview = {music: credits[0], chart: credits[1], rank: rank, bpm: bpm};
			vslicePreviewCache.set(cacheKey, preview);
		}

		vsliceCredits.text = 'MUSIC BY  ' + preview.music + '\nCHARTED BY  ' + preview.chart;
		vsliceCredits.visible = true;

		// The selected row's capsule already has its BPM from this parse; hand it to the per-row
		// digit strip so the row that matters never waits for the lazy chart-text reader.
		if (preview.bpm > 0) vsliceBpmCache.set(curSelected, preview.bpm);

		// V-Slice shows the same difficulty rating twice: as the capsule's two digits and as that
		// many stars on the album (DifficultyStars plays rating*100 of its strip). Use the rating
		// table the corner star HUD uses, with the chart's own starRank winning for this row.
		var rating:Int = preview.rank;
		if (rating <= 0 && curDifficulty >= 0 && curDifficulty < DIFFICULTY_RATINGS.length)
			rating = DIFFICULTY_RATINGS[curDifficulty];
		if (rating <= 0) rating = 3;

		var flameTier:Bool = rating > 10;
		var filled:Int = rating;
		if (filled < 1) filled = 1;
		if (filled > 10) filled = 10;

		var starKey:String = flameTier ? 'star2' : 'star1';
		if (starKey != vsliceStarKey)
		{
			vsliceStarKey = starKey;
			for (star in vsliceStars) star.loadGraphic(Paths.image(starKey));
		}
		for (i in 0...vsliceStars.length)
		{
			var star:FlxSprite = vsliceStars[i];
			star.visible = true;
			star.alpha = i < filled ? 1 : 0.18;
			var starScale:Float = ALBUM_STAR_SIZE / 113;
			star.scale.set(starScale, starScale);
			star.updateHitbox();
		}
		positionVSliceCard();
	}

	private function vsliceAlbumTextKey(album:String):String
	{
		if (album == null || album == 'default') return null;
		if (album == 'volume2alt') return 'volume2';
		return album;
	}

	private function positionVSliceCard():Void
	{
		if (vsliceAlbum == null || !vsliceAlbum.visible) return;
		vsliceAlbum.x = ALBUM_CARD_X;
		vsliceAlbum.y = ALBUM_CARD_TOP;

		if (vsliceAlbumTitle != null && vsliceAlbumTitle.visible)
		{
			// P-Slice draws the title art under the cover, rotated with it (AlbumRoll.hx:202).
			var titleScale:Float = 300 / Math.max(1, vsliceAlbumTitle.frameWidth);
			vsliceAlbumTitle.scale.set(titleScale, titleScale);
			vsliceAlbumTitle.updateHitbox();
			vsliceAlbumTitle.x = 934;
			vsliceAlbumTitle.y = 530;
		}

		// P-Slice's DifficultyStars plays a strip of up to ten stars along the cover's top
		// edge; the row follows the cover tilt, so each step drops by tan(8 deg) * spacing.
		var count:Int = vsliceStars.length;
		var totalWidth:Float = count * ALBUM_STAR_SIZE + (count - 1) * ALBUM_STAR_GAP;
		var startX:Float = ALBUM_CARD_X + (ALBUM_CARD_WIDTH - totalWidth) * 0.5;
		var step:Float = ALBUM_STAR_SIZE + ALBUM_STAR_GAP;
		var tilt:Float = Math.tan(8 * Math.PI / 180) * step;
		for (i in 0...count)
		{
			vsliceStars[i].x = startX + i * step;
			vsliceStars[i].y = 236 + i * tilt;
		}
		if (vsliceCredits != null)
		{
			vsliceCredits.x = 952;
			vsliceCredits.y = 648;
		}
	}

	// LIMUL-FREEPLAY-MOUSE: song index under the pointer, or -1. Letters sit in world space at their
	// row's y (rows are 156 px apart), so the cheap y filter leaves the per-letter hit test to the
	// two or three rows that can actually be under the cursor - the rest of a 400-song list is only
	// a Float comparison per row.
	private function songUnderMouse():Int
	{
		for (songIndex in 0...songs.length)
		{
			var row:FlxSprite = rowTexts[songIndex];
			if (row == null || !row.visible) continue;
			if (Math.abs(FlxG.mouse.y - row.y) > 170) continue;

			if (FlxG.mouse.overlaps(row)) return songIndex;
			var pixel:FlxSprite = vsliceRowPixel[songIndex];
			if (pixel != null && pixel.visible && FlxG.mouse.overlaps(pixel)) return songIndex;
			var icon:HealthIcon = iconArray[songIndex];
			if (icon != null && icon.visible && FlxG.mouse.overlaps(icon)) return songIndex;
			var capsule:FlxSprite = capsuleArray[songIndex];
			if (vsliceHud && capsule != null && capsule.visible && FlxG.mouse.overlaps(capsule)) return songIndex;
		}
		return -1;
	}

	function weekIsLocked(name:String):Bool {
		var leWeek:WeekData = WeekData.weeksLoaded.get(name);
		return (!leWeek.startUnlocked && leWeek.weekBefore.length > 0 && (!StoryMenuState.weekCompleted.exists(leWeek.weekBefore) || !StoryMenuState.weekCompleted.get(leWeek.weekBefore)));
	}

	// LIMUL-FREEPLAY-SCALE: the difficulty list for a song is decided by two things - what the week
	// json declares and which chart files exist on disk - and neither of them can change while the
	// menu is open. Stock rebuilt it (with one Paths.fileExists per custom name) on every selection
	// change; here it is computed once per (song, week list) pair and a copy is handed out, because
	// CoolUtil.difficulties is a static array other states also assign to.
	//
	// Per-song filtering still hides the extra Erect/Nightmare style names when this song has no
	// chart for them, otherwise Freeplay would let you pick a difficulty that crashes on the missing
	// file. The stock Easy/Normal/Hard names are never filtered, so a week that only ships the base
	// charts keeps working as before.
	function difficultiesFor(songName:String):Array<String>
	{
		var diffStr:String = WeekData.getCurrentWeek().difficulties;
		if(diffStr != null) diffStr = diffStr.trim(); //Fuck you HTML5

		var key:String = Paths.formatToSongPath(songName) + '|' + (diffStr == null ? '' : diffStr);
		var cached:Array<String> = difficultyCache.get(key);
		if(cached != null) return cached.copy();

		var list:Array<String> = CoolUtil.defaultDifficulties.copy();
		if(diffStr != null && diffStr.length > 0)
		{
			var diffs:Array<String> = diffStr.split(',');
			var i:Int = diffs.length - 1;
			while (i > 0)
			{
				if(diffs[i] != null)
				{
					diffs[i] = diffs[i].trim();
					if(diffs[i].length < 1) diffs.remove(diffs[i]);
				}
				--i;
			}

			if(diffs.length > 0 && diffs[0].length > 0)
			{
				list = diffs;
			}
		}

		var defaultNames:Array<String> = [];
		for(def in CoolUtil.defaultDifficulties)
		{
			defaultNames.push(Paths.formatToSongPath(def));
		}
		defaultNames.push(Paths.formatToSongPath(CoolUtil.defaultDifficulty));

		var formattedSong:String = Paths.formatToSongPath(songName);
		var chartFolder:String = 'data/' + formattedSong;
		var checkIndex:Int = list.length - 1;
		while (checkIndex >= 0)
		{
			var formatted:String = Paths.formatToSongPath(list[checkIndex]);
			if(!defaultNames.contains(formatted)
				&& !Paths.fileExists('$chartFolder/$formattedSong-$formatted.json', TEXT))
			{
				list.remove(list[checkIndex]);
			}
			--checkIndex;
		}

		difficultyCache.set(key, list);
		return list.copy();
	}

	/*public function addWeek(songs:Array<String>, weekNum:Int, weekColor:Int, ?songCharacters:Array<String>)
	{
		if (songCharacters == null)
			songCharacters = ['bf'];

		var num:Int = 0;
		for (song in songs)
		{
			addSong(song, weekNum, songCharacters[num]);
			this.songs[this.songs.length-1].color = weekColor;

			if (songCharacters.length != 1)
				num++;
		}
	}*/

	var instPlaying:Int = -1;
	public static var vocals:FlxSound = null;
	var holdTime:Float = 0;
	override function update(elapsed:Float)
	{
		if (searchHint != null) searchHint.visible = searchField.text.length == 0 && !searchField.hasFocus;
		if (searchField != null && searchField.text != lastSearchText)
			refreshSongFilter(searchField.text);

		if (vsliceHud)
		{
			updateVSliceRows(elapsed);
			updateVSliceDj(elapsed);
			updateVSliceHeader(elapsed);
			#if FREEPLAY
			if (vsliceDbgText != null)
			{
				var sc:FlxSprite = (curSelected >= 0 && curSelected < capsuleArray.length) ? capsuleArray[curSelected] : null;
				vsliceDbgText.text = 'FlxG ' + FlxG.width + 'x' + FlxG.height
					+ ' stage ' + FlxG.stage.stageWidth + 'x' + FlxG.stage.stageHeight
					+ ' scaleCls ' + Type.getClassName(Type.getClass(FlxG.scaleMode))
					+ '\nsel ' + (sc != null ? Math.round(sc.x) + ',' + Math.round(sc.y) + ' w' + Math.round(sc.width) + ' s' + sc.scale.x : 'null')
					+ '\ncamScroll ' + Math.round(FlxG.camera.scroll.x) + ',' + Math.round(FlxG.camera.scroll.y) + ' zoom ' + FlxG.camera.zoom
					+ '\ncurSel ' + curSelected + ' selPos ' + (curSelected < filteredSongPositions.length ? filteredSongPositions[curSelected] : -1)
					+ ' rowText0 ' + (rowTexts.length > 0 && rowTexts[0] != null ? Math.round(rowTexts[0].x) + ',' + Math.round(rowTexts[0].y) : 'null')
					+ '\niconDarnell ' + Paths.fileExists('images/freeplay/icons/darnellpixel.png', IMAGE)
					+ '\nhsX ' + Math.round(highscoreArt.x) + ' hsW ' + highscoreArt.width;
			}
			#end
		}

		if (FlxG.sound.music != null && FlxG.sound.music.volume < 0.7)
		{
			FlxG.sound.music.volume += 0.5 * FlxG.elapsed;
		}

		lerpScore = Math.floor(FlxMath.lerp(lerpScore, intendedScore, CoolUtil.boundTo(elapsed * 24, 0, 1)));
		lerpRating = FlxMath.lerp(lerpRating, intendedRating, CoolUtil.boundTo(elapsed * 12, 0, 1));

		if (Math.abs(lerpScore - intendedScore) <= 10)
			lerpScore = intendedScore;
		if (Math.abs(lerpRating - intendedRating) <= 0.01)
			lerpRating = intendedRating;

		// LIMUL-FREEPLAY-SCALE: everything below builds strings (split, join, number formatting),
		// so it only runs while the lerp is moving or after a resize.
		if (lerpScore != lastLerpScore || lerpRating != lastLerpRating || FlxG.width != lastHighscoreWidth)
		{
			lastLerpScore = lerpScore;
			lastLerpRating = lerpRating;

			var ratingSplit:Array<String> = Std.string(Highscore.floorDecimal(lerpRating * 100, 2)).split('.');
			if(ratingSplit.length < 2) { //No decimals, add an empty space
				ratingSplit.push('');
			}
			
			while(ratingSplit[1].length < 2) { //Less than 2 decimals in it, add decimals then
				ratingSplit[1] += '0';
			}

			// P-Slice's CLEARED counter is the lerped Highscore rating, shown as whole percent and kept
			// right-aligned against the % baked into clearBox.png. FlxSprite.offset subtracts from the
			// draw position, so the one-digit case needs the negative shift (P-Slice's 3/2/1 -> +10/0/-24).
			if (vsliceClearText != null)
			{
				var clearedPct:Int = intendedScore > 0 ? Std.int(lerpRating * 100) : 0;
				var clearedStr:String = Std.string(clearedPct);
				if (clearedStr != vsliceClearText.text)
					vsliceClearText.text = clearedStr;
				// the field starts at '0' too, so the offset cannot ride on the text change alone
				vsliceClearText.offset.x = clearedPct >= 100 ? 10 : (clearedPct >= 10 ? 0 : -24);
			}

			// LIMUL-FREEPLAY-SCALE: assigning .text makes FlxText re-layout the whole string, and this
			// ran on every single frame (up to 520 of them a second) for a value that only moves while
			// the score is lerping up. It now writes on change; a window resize still repositions.
			var nextScoreText:String = (vsliceHud ? '' : 'PERSONAL BEST: ') + lerpScore + ' (' + ratingSplit.join('.') + '%)';
			if (nextScoreText != lastScoreText || FlxG.width != lastHighscoreWidth)
			{
				lastScoreText = nextScoreText;
				lastHighscoreWidth = FlxG.width;
				scoreText.text = nextScoreText;
				positionHighscore();
			}
		}

		var upP = controls.UI_UP_P;
		var downP = controls.UI_DOWN_P;
		var accepted:Bool = controls.ACCEPT;
		var space = FlxG.keys.justPressed.SPACE;
		var ctrl = FlxG.keys.justPressed.CONTROL;
		var searchFocused:Bool = searchField != null && searchField.hasFocus;
		var mouseOverSearch:Bool = searchField != null && searchField.visible && FlxG.mouse.overlaps(searchField);
		// The scoreboard renders above the list, so the pointer over it must not grab a row that
		// happens to sit underneath. scoreBG is scaled on X at runtime and FlxObject.overlapsPoint
		// ignores scale, so its box is derived from the label's x instead.
		var mouseOverScore:Bool = scoreBG != null && scoreText != null
			&& FlxG.mouse.y >= scoreBG.y && FlxG.mouse.y <= scoreBG.y + scoreBG.height
			&& FlxG.mouse.x >= scoreText.x - 6;
		var overHintBar:Bool = hintBar != null && FlxG.mouse.y >= hintBar.y;
		var overVSliceChrome:Bool = vsliceHud && vsliceChromeHover();
		if (vsliceHud && vsliceChromeClick())
			overVSliceChrome = true;
		// P-Slice locks the list while the mascot plays its confirm animation; moving the cursor
		// there would swap CoolUtil.difficulties under the captured song index before the launch.
		if (!searchFocused && filteredSongs.length > 0 && curSelected >= 0 && vsliceConfirmTimer < 0)
		{
			if (!mouseOverSearch && !mouseOverScore && !overHintBar && !overVSliceChrome)
			{
				// LIMUL-FREEPLAY-MOUSE: hover follows the pointer, but only when it actually moved -
				// otherwise a parked cursor would keep stealing the selection from the arrow keys.
				if (FlxG.mouse.justMoved)
				{
					var hovered:Int = songUnderMouse();
					if (hovered >= 0 && hovered != curSelected)
					{
						FlxG.sound.play(Paths.sound('scrollMenu'), 0.2);
						changeSelection(filteredSongPositions[hovered] - filteredSongPositions[curSelected], false);
					}
				}

				if (FlxG.mouse.justPressed)
				{
					var clicked:Int = songUnderMouse();
					if (clicked >= 0)
					{
						if (clicked == curSelected)
							accepted = true;
						else
						{
							changeSelection(filteredSongPositions[clicked] - filteredSongPositions[curSelected], false);
							changeDiff();
						}
					}
				}
			}
			// Clicking the left or right half of the difficulty label is the mouse version of
			// LEFT/RIGHT - the label already draws the < > arrows around the name.
			else if (mouseOverScore && FlxG.mouse.justPressed && diffText != null && CoolUtil.difficulties.length > 1
				&& FlxG.mouse.x >= diffText.x && FlxG.mouse.x <= diffText.x + diffText.width
				&& FlxG.mouse.y >= diffText.y && FlxG.mouse.y <= diffText.y + diffText.height)
			{
				changeDiff(FlxG.mouse.x < diffText.x + diffText.width * 0.5 ? -1 : 1);
				FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
			}
		}
		if (searchFocused && (controls.BACK || FlxG.keys.justPressed.ENTER))
			searchField.hasFocus = false;

		var shiftMult:Int = 1;
		if(FlxG.keys.pressed.SHIFT) shiftMult = 3;

		if(!searchFocused && filteredSongs.length > 1 && vsliceConfirmTimer < 0)
		{
			if (upP)
			{
				changeSelection(-shiftMult);
				holdTime = 0;
			}
			if (downP)
			{
				changeSelection(shiftMult);
				holdTime = 0;
			}

			if(controls.UI_DOWN || controls.UI_UP)
			{
				var checkLastHold:Int = Math.floor((holdTime - 0.5) * 10);
				holdTime += elapsed;
				var checkNewHold:Int = Math.floor((holdTime - 0.5) * 10);

				if(holdTime > 0.5 && checkNewHold - checkLastHold > 0)
				{
					changeSelection((checkNewHold - checkLastHold) * (controls.UI_UP ? -shiftMult : shiftMult));
					changeDiff();
				}
			}

			if(FlxG.mouse.wheel != 0)
			{
				FlxG.sound.play(Paths.sound('scrollMenu'), 0.2);
				changeSelection(-shiftMult * FlxG.mouse.wheel, false);
				changeDiff();
			}
		}

		if (!searchFocused && vsliceConfirmTimer < 0 && controls.UI_LEFT_P)
			changeDiff(-1);
		else if (!searchFocused && vsliceConfirmTimer < 0 && controls.UI_RIGHT_P)
			changeDiff(1);
		else if (!searchFocused && vsliceConfirmTimer < 0 && (upP || downP)) changeDiff();

		// LIMUL-FREEPLAY-MOUSE: right click is the pointer's BACK key; the search field keeps its
		// focus click, hence the same searchFocused gate the keyboard BACK already has.
		if (!searchFocused && (controls.BACK || FlxG.mouse.justPressedRight))
		{
			persistentUpdate = false;
			if(colorTween != null) {
				colorTween.cancel();
			}
			FlxG.sound.play(Paths.sound('cancelMenu'));
			MusicBeatState.switchState(new MainMenuState());
		}

		if(!searchFocused && ctrl)
		{
			persistentUpdate = false;
			openSubState(new GameplayChangersSubstate());
		}
		else if(!searchFocused && filteredSongs.length > 0 && space)
		{
			if(instPlaying != curSelected)
			{
				#if PRELOAD_ALL
				destroyFreeplayVocals();
				FlxG.sound.music.volume = 0;
				Paths.currentModDirectory = songs[curSelected].folder;
				var poop:String = Highscore.formatSong(songs[curSelected].songName.toLowerCase(), curDifficulty);
				PlayState.SONG = Song.loadFromJson(poop, songs[curSelected].songName.toLowerCase());
				// LIMUL-FREEPLAY-SCALE: loadEmbedded() with its default startPlaying decodes the
				// track, opens a 100ms transform and then still goes through FlxSound.play(), whose
				// gain ramp allocates a Float32Array per call and can make flixel unload the menu
				// music samples. Nothing is heard before SPACE anyway, so the buffer is fetched
				// without starting playback and the play() below opens it once.
				vocals = new FlxSound();
				if (PlayState.SONG.needsVoices)
					vocals.loadEmbedded(Paths.voices(PlayState.SONG.song), false);

				FlxG.sound.list.add(vocals);
				FlxG.sound.playMusic(Paths.inst(PlayState.SONG.song), 0.7);
				vocals.play();
				vocals.persist = true;
				vocals.looped = true;
				vocals.volume = 0.7;
				instPlaying = curSelected;
				#end
			}
		}

		else if (!searchFocused && filteredSongs.length > 0 && accepted)
		{
			if (vsliceHud && vsliceConfirmTimer < 0)
			{
				// P-Slice lets the mascot play its confirm animation before switching states.
				var charting:Bool = FlxG.keys.pressed.SHIFT;
				var songIndex:Int = curSelected;
				var difficulty:Int = curDifficulty;
				vsliceConfirmTimer = vsliceStylePico ? 0.8 : 1.1;
				vsliceConfirmAction = function() startSelectedSong(charting, songIndex, difficulty);
				if (vsliceDj != null)
				{
					vsliceDjState = 'confirm';
					vsliceDj.anim.play('confirm');
				}
				FlxG.sound.play(Paths.sound('confirmMenu'));
			}
			else if (!vsliceHud)
			{
				startSelectedSong(FlxG.keys.pressed.SHIFT, curSelected, curDifficulty);
			}
		}
		else if(!searchFocused && filteredSongs.length > 0 && controls.RESET)
		{
			persistentUpdate = false;
			openSubState(new ResetScoreSubState(songs[curSelected].songName, curDifficulty, songs[curSelected].songCharacter));
			FlxG.sound.play(Paths.sound('scrollMenu'));
		}
		super.update(elapsed);
	}

	function startSelectedSong(charting:Bool, songIndex:Int, difficulty:Int):Void
	{
		persistentUpdate = false;
		var songLowercase:String = Paths.formatToSongPath(songs[songIndex].songName);
		// CoolUtil.difficulties is a global that changeSelection() swaps per song. If it shrank
		// under the captured index (the P-Slice confirm animation delays the actual launch),
		// getDifficultyFilePath() would return '-null' and file_contents would crash on it.
		if (difficulty < 0 || difficulty >= CoolUtil.difficulties.length)
			difficulty = Std.int(Math.max(0, Math.min(difficulty, CoolUtil.difficulties.length - 1)));
		var poop:String = Highscore.formatSong(songLowercase, difficulty);
		trace(poop);

		PlayState.SONG = Song.loadFromJson(poop, songLowercase);
		PlayState.isStoryMode = false;
		PlayState.storyDifficulty = difficulty;

		trace('CURRENT WEEK: ' + WeekData.getWeekFileName());
		if(colorTween != null) {
			colorTween.cancel();
		}

		if (charting){
			LoadingState.loadAndSwitchState(new ChartingState());
		}else{
			LoadingState.loadAndSwitchState(new PlayState());
		}

		if (FlxG.sound.music != null) FlxG.sound.music.volume = 0;

		destroyFreeplayVocals();
	}

	public static function destroyFreeplayVocals() {
		if(vocals != null) {
			vocals.stop();
			vocals.destroy();
		}
		vocals = null;
	}

	function changeDiff(change:Int = 0)
	{
		if (curSelected < 0 || curSelected >= songs.length || CoolUtil.difficulties.length == 0)
			return;

		curDifficulty += change;

		if (curDifficulty < 0)
			curDifficulty = CoolUtil.difficulties.length-1;
		if (curDifficulty >= CoolUtil.difficulties.length)
			curDifficulty = 0;

		lastDifficultyName = CoolUtil.difficulties[curDifficulty];

		#if !switch
		intendedScore = Highscore.getScore(songs[curSelected].songName, curDifficulty);
		intendedRating = Highscore.getRating(songs[curSelected].songName, curDifficulty);
		#end

		PlayState.storyDifficulty = curDifficulty;
		// LIMUL-104-FREEPLAY-LABEL: Psych 1.0.4 FreeplayState.hx:502-506 only wraps the name in
		// angle brackets when there is actually more than one difficulty to cycle through.
		if (CoolUtil.difficulties.length > 1)
			diffText.text = '< ' + CoolUtil.difficultyString() + ' >';
		else
			diffText.text = CoolUtil.difficultyString();
		positionHighscore();
		// The star row and the chart credit follow the difficulty, so the card has to be refreshed
		// when left/right changes it - changeSelection ends with changeDiff(), which lands here.
		refreshVSliceCard();
		refreshVSliceDiffArt();
	}

	function changeSelection(change:Int = 0, playSound:Bool = true)
	{
		if (filteredSongs.length == 0)
			return;
		if(playSound) FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

		var selectedPosition:Int = curSelected >= 0 && curSelected < filteredSongPositions.length
			? filteredSongPositions[curSelected]
			: -1;
		if (selectedPosition < 0) selectedPosition = 0;
		selectedPosition = (selectedPosition + change) % filteredSongs.length;
		if (selectedPosition < 0) selectedPosition += filteredSongs.length;
		curSelected = filteredSongs[selectedPosition];
			
		if (vsliceHud) applyVSliceStyle();

		var newColor:Int = songs[curSelected].color;
		if(!vsliceHud && newColor != intendedColor) {
			if(colorTween != null) {
				colorTween.cancel();
			}
			intendedColor = newColor;
			colorTween = FlxTween.color(bg, 1, bg.color, intendedColor, {
				onComplete: function(twn:FlxTween) {
					colorTween = null;
				}
			});
		}

		// selector.y = (70 * curSelected) + 30;

		#if !switch
		intendedScore = Highscore.getScore(songs[curSelected].songName, curDifficulty);
		intendedRating = Highscore.getRating(songs[curSelected].songName, curDifficulty);
		#end

		// LIMUL-FREEPLAY-SCALE: the old code walked grpSongs.members with a counter (bullShit) and
		// assumed that the position inside the group WAS the row number. Rows are addressed by their
		// real index now, and only the two rows whose brightness actually changes get touched:
		// FlxSpriteGroup.alpha rewrites every letter of the group (FlxSpriteGroup.hx:726), so the
		// previous "set 0.6 on all N rows" loops cost N x letters per key press - and holding an
		// arrow calls changeSelection several times a frame. targetY still has to reach every row,
		// because wrapping from the last song back to the first makes all of them glide; that write
		// is a plain Int on the group (Alphabet.hx:30) which nothing else reads until the row updates.
		if (lastSelected != curSelected)
		{
			if (lastSelected >= 0 && lastSelected < rowTexts.length)
			{
				if (rowTexts[lastSelected] != null)
					rowTexts[lastSelected].alpha = 0.6;
				if (iconArray[lastSelected] != null)
					iconArray[lastSelected].alpha = 0.6;
			}
			if (curSelected >= 0 && curSelected < rowTexts.length)
			{
				if (rowTexts[curSelected] != null)
					rowTexts[curSelected].alpha = 1;
				if (iconArray[curSelected] != null)
					iconArray[curSelected].alpha = 1;
			}
			if (vsliceHud)
			{
				if (lastSelected >= 0 && lastSelected < capsuleArray.length && capsuleArray[lastSelected] != null)
					capsuleArray[lastSelected].animation.play('idle');
				if (curSelected >= 0 && curSelected < capsuleArray.length && capsuleArray[curSelected] != null)
					capsuleArray[curSelected].animation.play('sel');
			}
			lastSelected = curSelected;
		}

		var rowIndex:Int = 0;
		while (rowIndex < rowTexts.length)
		{
			var text:FlxSprite = rowTexts[rowIndex];
			if (text != null)
			{
				var visiblePosition:Int = filteredSongPositions[rowIndex];
				// In V-Slice the capsule list owns row visibility (it also clips rows that slid
				// under the header), so changeSelection only records the filter result here.
				if (!vsliceHud) text.visible = visiblePosition >= 0;
				if (rowIndex < vsliceRowClip.length) vsliceRowClip[rowIndex] = visiblePosition >= 0;
				if (visiblePosition >= 0 && !vsliceHud)
					(cast text : Alphabet).targetY = visiblePosition - selectedPosition;
			}
			if (iconArray[rowIndex] != null)
				iconArray[rowIndex].visible = filteredSongPositions[rowIndex] >= 0;
			++rowIndex;
		}
		
		Paths.currentModDirectory = songs[curSelected].folder;
		PlayState.storyWeek = songs[curSelected].week;

		// LIMUL-FREEPLAY-SCALE: this used to rebuild the list inline, which meant one
		// Paths.fileExists() disk stat per custom difficulty per selection change (Erect/Nightmare
		// style names are custom, so a Weekend 1 row paid 2 of them every time the cursor moved).
		// difficultiesFor() does the same work once per song per menu visit.
		CoolUtil.difficulties = difficultiesFor(songs[curSelected].songName);

		if(CoolUtil.difficulties.length < 1)
		{
			CoolUtil.difficulties = CoolUtil.defaultDifficulties.copy();
		}
		
		if(CoolUtil.difficulties.contains(CoolUtil.defaultDifficulty))
		{
			curDifficulty = Math.round(Math.max(0, CoolUtil.defaultDifficulties.indexOf(CoolUtil.defaultDifficulty)));
		}
		else
		{
			curDifficulty = 0;
		}

		var newPos:Int = CoolUtil.difficulties.indexOf(lastDifficultyName);
		//trace('Pos of ' + lastDifficultyName + ' is ' + newPos);
		if(newPos > -1)
		{
			curDifficulty = newPos;
		}

		// LIMUL-104-FREEPLAY-LABEL: 1.0.4 ends changeSelection() with changeDiff() (FreeplayState.hx:557).
		// Stock 0.6.3 only re-rendered the difficulty label inside changeDiff(), i.e. on a left/right
		// key press, while the block above rebuilds CoolUtil.difficulties for every song and can shrink
		// it (the per-week Erect/Nightmare/Fucked entries are dropped when that song has no chart for
		// them). So the label used to keep showing the previous song's difficulty - on Weekend 1 that
		// means '< ERECT >' sitting over a song that only has Easy/Normal/Hard - and PlayState.storyDifficulty
		// was never brought back in sync with the filtered list. changeDiff(0) changes nothing but the
		// bookkeeping: it clamps the index, refreshes lastDifficultyName, sets storyDifficulty and
		// redraws the text.
		changeDiff(0);
	}

	private function positionHighscore() {
		if (vsliceHud)
		{
			if (highscoreArt != null)
			{
				highscoreArt.x = FlxG.width - 420;
				highscoreArt.y = 70;
			}
			scoreText.x = FlxG.width - scoreText.width - 10;
			scoreText.y = 38;
			diffText.x = FlxG.width - diffText.width - 10;
			diffText.y = 38;
			positionVSliceCard();
			positionSearchField();
			return;
		}

		scoreText.x = FlxG.width - scoreText.width - 6;

		scoreBG.scale.x = FlxG.width - scoreText.x + 6;
		scoreBG.x = FlxG.width - (scoreBG.scale.x / 2);
		diffText.x = Std.int(scoreBG.x + (scoreBG.width / 2));
		diffText.x -= diffText.width / 2;
		positionSearchField();
	}

	private function positionSearchField():Void
	{
		if (searchField == null || searchLabel == null || diffText == null)
			return;

		if (vsliceHud)
		{
			searchField.width = 300;
			searchField.x = 16;
			searchField.y = FlxG.height - 70;
		}
		else
		{
			searchField.x = Math.max(12, FlxG.width - 370);
			searchField.y = diffText.y + diffText.height + 8;
			searchField.width = Math.min(358, FlxG.width - searchField.x - 12);
		}
		searchLabel.x = searchField.x;
		searchLabel.y = searchField.y - searchLabel.height - 2;
		searchHint.x = searchField.x + 8;
		searchHint.y = searchField.y + 4;
	}
}

class SongMetadata
{
	public var songName:String = "";
	public var week:Int = 0;
	public var songCharacter:String = "";
	public var color:Int = -7179779;
	public var folder:String = "";
	public var album:String = "default";

	public function new(song:String, week:Int, songCharacter:String, color:Int, album:String = "default")
	{
		this.songName = song;
		this.week = week;
		this.songCharacter = songCharacter;
		this.color = color;
		this.album = album;
		this.folder = Paths.currentModDirectory;
		if(this.folder == null) this.folder = '';
	}
}
