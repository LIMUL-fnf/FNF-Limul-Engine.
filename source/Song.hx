package;

import Section.SwagSection;
import haxe.Json;
import haxe.format.JsonParser;
import lime.utils.Assets;

#if sys
import sys.io.File;
import sys.FileSystem;
#end

using StringTools;

typedef SwagSong =
{
	var song:String;
	var notes:Array<SwagSection>;
	var events:Array<Dynamic>;
	var bpm:Float;
	var needsVoices:Bool;
	var speed:Float;

	var player1:String;
	var player2:String;
	var gfVersion:String;
	var stage:String;

	var arrowSkin:String;
	var splashSkin:String;
	var validScore:Bool;
	@:optional var composer:String;
	@:optional var musicBy:String;
	@:optional var charter:String;
	@:optional var chartedBy:String;
	/** LIMUL-STAR-RANK: optional per-chart difficulty star number written by the Chart Editor.
	 * Dynamic on purpose - a chart hand-written outside the editor can carry an Int, a Float
	 * ("12.0") or a String ("12"), and getStarRank() is the one place that decides what that
	 * means. Read it through the helper, never field by field. */
	@:optional var starRank:Dynamic;
}

class Song
{
	/** Credits for the built-in Freeplay songs. Mod charts can override these
	 * values by adding composer/musicBy and charter/chartedBy to their chart. */
	public static function getCreditData(songName:String):Array<String>
	{
		switch (Paths.formatToSongPath(songName))
		{
			case 'darnell' | 'lit-up' | '2hot' | 'blazin': return ['Kawai Sprite', 'ninjamuffin99, MtH'];
			case 'tutorial': return ['Kawai Sprite', 'ninjamuffin99, MtH'];
			case 'bopeebo': return ['Kawai Sprite', 'ninjamuffin99, MtH'];
			case 'fresh': return ['Kawai Sprite', 'ninjamuffin99, MtH'];
			case 'dad-battle': return ['Kawai Sprite', 'ninjamuffin99, MtH'];
			case 'spookeez': return ['Kawai Sprite', 'ninjamuffin99, MtH, Spazkid'];
			case 'south': return ['Kawai Sprite', 'ninjamuffin99, MtH'];
			case 'monster': return ['Bassetfilms', 'ninjamuffin99, MtH'];
			case 'pico': return ['Kawai Sprite', 'ninjamuffin99, MtH'];
			case 'philly-nice': return ['Kawai Sprite', 'ninjamuffin99, MtH'];
			case 'blammed': return ['Kawai Sprite', 'ninjamuffin99, MtH'];
			case 'satin-panties': return ['Kawai Sprite', 'ninjamuffin99, MtH'];
			case 'high': return ['Kawai Sprite', 'ninjamuffin99, MtH'];
			case 'milf': return ['Kawai Sprite', 'ninjamuffin99, MtH'];
			case 'cocoa': return ['Kawai Sprite', 'ninjamuffin99, MtH'];
			case 'eggnog': return ['Kawai Sprite', 'ninjamuffin99, MtH'];
			case 'winter-horrorland': return ['Bassetfilms', 'ninjamuffin99, MtH'];
			case 'senpai': return ['Kawai Sprite', 'ninjamuffin99, MtH'];
			case 'roses': return ['Kawai Sprite', 'ninjamuffin99, MtH, Spazkid'];
			case 'thorns': return ['Kawai Sprite', 'ninjamuffin99, MtH'];
			case 'ugh': return ['Kawai Sprite', 'MtH'];
			case 'guns': return ['Kawai Sprite', 'MtH'];
			case 'stress': return ['Kawai Sprite', 'MtH, Spazkid, Hundrec'];
			default: return ['Unknown', 'Unknown'];
		}
	}

	/** Shown whenever a credit slot has no real name behind it - the start-of-song
	 * banner, the Chart Editor's Music By / Charted By boxes and the saved chart all
	 * agree on this one word. */
	public static inline var UNKNOWN_CREDIT:String = 'Unknown';

	/** Chart keys that can hold the music credit, in priority order. */
	public static function musicCreditFields():Array<String> return ['musicBy', 'composer', 'artist', 'music'];

	/** Chart keys that can hold the chart credit, in priority order. */
	public static function chartCreditFields():Array<String> return ['chartedBy', 'charter', 'chartAuthor', 'chartCreator', 'charting'];

	/**
	 * The song name a chart's credits are looked up under.
	 * `SONG.song` is whatever the chart file says and 1.0.x files are free to leave it
	 * out or put a non-string there, so this is the only safe way to read it.
	 */
	public static function getCreditSongName(songJson:Dynamic):String
	{
		if (songJson == null)
			return '';

		var leSong:Dynamic = Reflect.field(songJson, 'song');
		if (leSong == null || !Std.isOfType(leSong, String))
			return '';
		return leSong;
	}

	/**
	 * One credit slot of one chart, decided in exactly one place.
	 * Priority: the chart's own keys, then the built-in table above, then 'Unknown'.
	 */
	public static function readCreditField(songJson:Dynamic, fieldNames:Array<String>, fallback:String):String
	{
		if (songJson != null)
		{
			for (fieldName in fieldNames)
			{
				var value:Dynamic = Reflect.field(songJson, fieldName);
				if (value == null)
					continue;

				var text:String = Std.string(value).trim();
				if (text.length > 0 && text != 'null')
					return text;
			}
		}
		return cleanCredit(fallback);
	}

	/** An empty, null or placeholder-looking credit always reads back as 'Unknown'. */
	public static function cleanCredit(value:String):String
	{
		if (value == null)
			return UNKNOWN_CREDIT;

		var text:String = value.trim();
		if (text.length == 0 || text == 'null')
			return UNKNOWN_CREDIT;
		return text;
	}

	/**
	 * [music credit, chart credit] for a loaded chart.
	 *
	 * PlayState's start-of-song banner and ChartingState's two credit boxes both call
	 * this, which is what keeps them saying the same thing: before, the banner fell back
	 * to getCreditData() while the editor showed empty boxes for the very same song.
	 */
	public static function getSongCredits(songJson:Dynamic):Array<String>
	{
		var defaultCredits:Array<String> = getCreditData(getCreditSongName(songJson));
		return [
			readCreditField(songJson, musicCreditFields(), defaultCredits[0]),
			readCreditField(songJson, chartCreditFields(), defaultCredits[1])
		];
	}

	/**
	 * LIMUL-STAR-RANK: the number the difficulty star HUD prints.
	 *
	 * A chart can override it with a top-level `starRank` (the Chart Editor's "Difficulty Star"
	 * box writes it); anything missing, blank, zero or negative means "no override" and
	 * assets/scripts/limul-difficulty-star.lua keeps using its own per-difficulty table.
	 * This is the only reader, so the editor, the Lua global and a hand-written JSON file all
	 * agree on what "12.0", "12" or "" means.
	 */
	public static inline var NO_STAR_RANK:Int = 0;

	public static function getStarRank(songJson:Dynamic):Int
	{
		if (songJson == null)
			return NO_STAR_RANK;

		var raw:Dynamic = Reflect.field(songJson, 'starRank');
		if (raw == null)
			return NO_STAR_RANK;

		var value:Float = Std.parseFloat(Std.string(raw));
		if (Math.isNaN(value))
			return NO_STAR_RANK;

		var rank:Int = Std.int(value);
		return rank > NO_STAR_RANK ? rank : NO_STAR_RANK;
	}

	/**
	 * Writes the override, and removes the key when there is none. saveLevel() stringifies the
	 * chart wholesale, so a leftover "starRank": 0 would sit in every chart the editor touches -
	 * the same reason the credit boxes delete instead of writing an empty string.
	 */
	public static function setStarRank(songJson:Dynamic, value:Int):Void
	{
		if (songJson == null)
			return;

		if (value <= NO_STAR_RANK)
			Reflect.deleteField(songJson, 'starRank');
		else
			Reflect.setProperty(songJson, 'starRank', value);
	}

	public var song:String;
	public var notes:Array<SwagSection>;
	public var events:Array<Dynamic>;
	public var bpm:Float;
	public var needsVoices:Bool = true;
	public var arrowSkin:String;
	public var splashSkin:String;
	public var speed:Float = 1;
	public var stage:String;
	public var player1:String = 'bf';
	public var player2:String = 'dad';
	public var gfVersion:String = 'gf';

	private static function onLoadJson(songJson:Dynamic) // Convert old charts to newest format
	{
		// Psych 1.0.x charts ("psych_v1") use a different lane space than this fork -
		// re-map them before anything else touches the notes array.
		if (isPsychV1(songJson))
			convertFromPsychV1(songJson);

		if(songJson.gfVersion == null)
		{
			songJson.gfVersion = songJson.player3;
			songJson.player3 = null;
		}

		// Some converted Psych Engine charts serialize an empty events array as
		// an object ({}). Normalize both missing and malformed values before
		// PlayState iterates over them.
		if(songJson.events == null || !Std.isOfType(songJson.events, Array))
		{
			// Psych 1.0.x stores events as an object: {"Event Name": [[time, v1, v2, line], ...]}
			// This fork wants the 0.6.3 array form: [["Event Name", [[time, v1, v2], ...]], ...]
			var fromObject:Array<Dynamic> = eventsObjectToList(songJson.events);
			if (fromObject != null)
			{
				songJson.events = fromObject;
			}
			else
			{
				songJson.events = [];
				for (secNum in 0...songJson.notes.length)
				{
					var sec:SwagSection = songJson.notes[secNum];

					var i:Int = 0;
					var notes:Array<Dynamic> = sec.sectionNotes;
					var len:Int = notes.length;
					while(i < len)
					{
						var note:Array<Dynamic> = notes[i];
						if(note[1] < 0)
						{
							songJson.events.push([note[0], [[note[2], note[3], note[4]]]]);
							notes.remove(note);
							len = notes.length;
						}
						else i++;
					}
				}
			}
		}
	}

	/**
	 * Does this chart use the Psych Engine 1.0 lane space?
	 * 1.0.x writes `format:'psych_v1'` (or 'psych_v1_convert' after Song.convert ran),
	 * and the V-Slice importer stamps `generatedBy:'Psych Engine v1.0b - ...'`.
	 */
	public static function isPsychV1(songJson:Dynamic):Bool
	{
		// An explicit `format` that is not a psych_v1 tag means the file already sits in
		// this fork's lane space - trust it and never convert. This is what stops the
		// double-flip: convertFromPsychV1 used to DELETE the field, so a chart editor
		// save wrote out a file whose only remaining marker was generatedBy, which the
		// heuristic below read as "still 1.0.x" - every later load flipped the note
		// owners again.
		var fmt:String = songJson.format;
		if (fmt != null)
			return fmt.startsWith('psych_v1');
		var gen:String = songJson.generatedBy;
		return gen != null && gen.indexOf('Psych Engine v1.0') >= 0;
	}

	/**
	 * Psych 1.0.x -> this fork.
	 *
	 * In psych_v1 lanes 0-3 are ALWAYS the player and 4-7 ALWAYS the opponent;
	 * `mustHitSection` is only a camera hint. This fork (PlayState.hx) does
	 * `column = lane % 4` and `mustPress = mustHitSection XOR (lane > 3)`, so a raw
	 * 1.0.x file plays half its notes on the wrong side. This is the exact inverse of
	 * Psych 1.0's own Song.convert(): pick the section owner from the note majority,
	 * then push every note into the lane band that this fork reads as that owner.
	 * Ties keep the source flag, empty sections inherit the previous one so the
	 * camera does not jump for no reason.
	 */
	public static function convertFromPsychV1(songJson:Dynamic):Void
	{
		if (songJson.notes == null)
			return;

		var lastFlag:Bool = songJson.mustHitSection == true;
		var sections:Array<Dynamic> = songJson.notes;
		for (sec in sections)
		{
			var sectionNotes:Array<Dynamic> = sec.sectionNotes;
			if (sectionNotes == null)
				continue;

			// 1.0.x charts often omit the flags this fork reads directly.
			if (sec.sectionBeats == null) sec.sectionBeats = 4;
			if (sec.gfSection == null) sec.gfSection = false;
			if (sec.altAnim == null) sec.altAnim = false;
			if (sec.changeBPM == null) sec.changeBPM = false;
			if (sec.typeOfSection == null) sec.typeOfSection = 0;
			if (sec.mustHitSection == null) sec.mustHitSection = lastFlag;

			var playerNotes:Int = 0;
			var opponentNotes:Int = 0;
			for (note in sectionNotes)
			{
				var lane:Int = Std.int(note[1]);
				if (lane < 0) continue; // event row, not a strummable note
				if (lane < 4) ++playerNotes; else ++opponentNotes;
			}

			var flag:Bool = lastFlag;
			if (playerNotes != opponentNotes)
				flag = playerNotes > opponentNotes;
			else if (playerNotes > 0)
				flag = sec.mustHitSection == true;
			sec.mustHitSection = flag;

			for (note in sectionNotes)
			{
				var lane:Int = Std.int(note[1]);
				if (lane < 0) continue;
				var isPlayer:Bool = lane < 4;
				note[1] = (lane % 4) + (if (isPlayer == flag) 0 else 4);
			}

			lastFlag = flag;
		}

		// Do not leave the tag behind: a chart that already sits in this fork's lane
		// space must not be re-flipped if something loads it a second time, and the
		// chart editor should not write it back out.
		// Stamping a marker instead of deleting it is what makes this survive an
		// editor save - the JSON writer keeps unknown fields, so the next load sees
		// format:'limul_native' and isPsychV1() answers no even when the original
		// generatedBy string is still in there.
		songJson.format = 'limul_native';
	}

	/** Converts the 1.0.x event object to the 0.6.3 array-of-pairs form, or null if `events` is not an object. */
	private static function eventsObjectToList(events:Dynamic):Array<Dynamic>
	{
		if (events == null || Std.isOfType(events, Array))
			return null;

		var out:Array<Dynamic> = [];
		for (name in Reflect.fields(events))
		{
			var rows:Array<Dynamic> = Reflect.field(events, name);
			if (rows == null || !Std.isOfType(rows, Array))
				continue;
			var list:Array<Dynamic> = [];
			for (row in rows)
				list.push([row[0], row[1], row[2]]);
			out.push([name, list]);
		}
		return out;
	}

	public function new(song, notes, bpm)
	{
		this.song = song;
		this.notes = notes;
		this.bpm = bpm;
	}

	public static function loadFromJson(jsonInput:String, ?folder:String):SwagSong
	{
		var rawJson = null;
		
		var formattedFolder:String = Paths.formatToSongPath(folder);
		var formattedSong:String = Paths.formatToSongPath(jsonInput);
		#if MODS_ALLOWED
		var moddyFile:String = Paths.modsJson(formattedFolder + '/' + formattedSong);
		if(FileSystem.exists(moddyFile)) {
			rawJson = File.getContent(moddyFile).trim();
		}
		else
		{
			var matchingModChart:String = findModChartWithNormalizedName(formattedFolder, formattedSong);
			if (matchingModChart != null)
				rawJson = File.getContent(matchingModChart).trim();
		}
		#end

		if(rawJson == null) {
			#if sys
			rawJson = File.getContent(Paths.json(formattedFolder + '/' + formattedSong)).trim();
			#else
			rawJson = Assets.getText(Paths.json(formattedFolder + '/' + formattedSong)).trim();
			#end
		}

		while (!rawJson.endsWith("}"))
		{
			rawJson = rawJson.substr(0, rawJson.length - 1);
			// LOL GOING THROUGH THE BULLSHIT TO CLEAN IDK WHATS STRANGE
		}

		// FIX THE CASTING ON WINDOWS/NATIVE
		// Windows???
		// trace(songData);

		// trace('LOADED FROM JSON: ' + songData.notes);
		/* 
			for (i in 0...songData.notes.length)
			{
				trace('LOADED FROM JSON: ' + songData.notes[i].sectionNotes);
				// songData.notes[i].sectionNotes = songData.notes[i].sectionNotes
			}

				daNotes = songData.notes;
				daSong = songData.song;
				daBpm = songData.bpm; */

		var songJson:Dynamic = parseJSONshit(rawJson);
		if(jsonInput != 'events') StageData.loadDirectory(songJson);
		onLoadJson(songJson);
		return songJson;
	}

	#if MODS_ALLOWED
	static function findModChartWithNormalizedName(folder:String, chartName:String):String
	{
		var modFolders:Array<String> = [];
		if (Paths.currentModDirectory != null && Paths.currentModDirectory.length > 0)
			modFolders.push(Paths.currentModDirectory);
		for (mod in Paths.getGlobalMods())
		{
			if (!modFolders.contains(mod))
				modFolders.push(mod);
		}

		for (mod in modFolders)
		{
			var chartDirectory:String = Paths.mods(mod + '/data/' + folder);
			if (!FileSystem.exists(chartDirectory) || !FileSystem.isDirectory(chartDirectory))
				continue;

			var matchingFiles:Array<String> = [];
			for (fileName in FileSystem.readDirectory(chartDirectory))
			{
				if (!fileName.toLowerCase().endsWith('.json'))
					continue;
				var baseName:String = fileName.substr(0, fileName.length - 5);
				if (Paths.formatToSongPath(baseName) == chartName)
				{
					if (baseName == chartName)
						return chartDirectory + '/' + fileName;
					matchingFiles.push(chartDirectory + '/' + fileName);
				}
			}
			if (matchingFiles.length > 0)
			{
				matchingFiles.sort(Reflect.compare);
				return matchingFiles[0];
			}
		}
		return null;
	}
	#end

	public static function parseJSONshit(rawJson:String):SwagSong
	{
		var swagShit:SwagSong = cast Json.parse(rawJson).song;
		swagShit.validScore = true;
		return swagShit;
	}
}
