package building;

import sys.io.File;

using building.utils.AnsiUtil;

/**
* A script which executes before the game is built.
*/
class Prebuild
{
	static inline final BUILD_TIME_FILE:String = '.build_time';

	static function main():Void
	{
		var start:Float = Sys.time();
		Sys.println(' LOG '.log() + " Performing pre-build tasks...");

		saveBuildTime();

		var end:Float = Sys.time();
		var duration:Float = end - start;
		Sys.println(' LOG '.log() + ' Finished pre-build tasks in $duration seconds.');
	}

	static function saveBuildTime():Void
	{
		// Postbuild.hx reads this file and computes the total build duration.
		var fo:sys.io.FileOutput = File.write(BUILD_TIME_FILE);
		var now:Float = Sys.time();
		fo.writeDouble(now);
		fo.close();
	}
}