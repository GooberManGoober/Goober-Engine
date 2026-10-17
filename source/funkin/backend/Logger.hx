package funkin.backend;

import haxe.PosInfos;

import funkin.backend.plugins.DebugTextPlugin;

using funkin.utils.AnsiUtil;

enum abstract Severity(Int) to Int
{
	var PRINT;
	var WARN;
	var ERROR;
	var NOTICE;
	
	public function toString():String
	{
		return switch (this)
		{
			default: ' LOG '.log();
			case WARN: ' WARN '.warning();
			case ERROR: ' ERROR '.error();
			case NOTICE: ' NOTICE '.notice();
		}
	}
}

/**
 * basic custom tracing method
 * 
 * has support for ansi colour, showing the message on screen, and flixel debugger
 */
class Logger
{
	/**
	 * Primary `trace` function
	 * @param data The value to trace
	 * @param severity provides ansi colour coding to better highlight specific messages
	 * @param showInGame whether to have it display in game
	 */
	public static function log(data:Dynamic, severity:Severity = PRINT, showInGame:Bool = false, ?pos:PosInfos)
	{
		#if FLX_DEBUG
		switch (severity)
		{
			case ERROR:
				FlxG.log.error(data, pos);
				
			case WARN:
				FlxG.log.warn(data, pos);
			case NOTICE:
				FlxG.log.notice(data, pos);
				
			case PRINT:
		}
		#end
		
		if (showInGame && ClientPrefs.inDevMode)
		{
			DebugTextPlugin.instance.addText(Std.string(data), getHexColourFromSeverity(severity));
		}
		
		var output:String = '${severity.toString()} ${haxe.Log.formatOutput(data, pos)}';
		
		#if sys
		Sys.println(output);
		#else
		trace(output); // idk others lol!
		#end
	}
	
	public static function getHexColourFromSeverity(severity:Severity)
	{
		return switch (severity)
		{
			case ERROR: 0xffff4040;
			
			case WARN: FlxColor.YELLOW;
			
			case NOTICE: FlxColor.LIME;
			
			default: FlxColor.WHITE;
		}
	}
	
	public static function writeDump(content:String, folder:String, fileName:String) // this isnt really a log.
	{
		#if sys
		if (!FileSystem.exists(folder) && !FileSystem.isDirectory(folder))
		{
			FileSystem.createDirectory(folder);
		}
		
		final dumpPath = '$folder/$fileName' + '_' + Paths.sanitize(Date.now().toString()).replace(':', '_') + '.txt';
		
		try
		{
			File.saveContent(dumpPath, content);
		}
		catch (e) {}
		#end
	}
}
