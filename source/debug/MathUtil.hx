package debug;

class MathUtil
{
	/**
		FlxMath.lerp but accounts for FPS.
	**/
	public static inline function fpsLerp(v1:Float, v2:Float, ratio:Float) return FlxMath.lerp(v1, v2, getElapsedLerp(ratio, FlxG.elapsed));

	public static function easeInOutCirc(x:Float):Float
	{
		if (x <= 0.0) return 0.0;
		if (x >= 1.0) return 1.0;
		var result:Float = (x < 0.5) ? (1 - Math.sqrt(1 - 4 * x * x)) / 2 : (Math.sqrt(1 - 4 * (1 - x) * (1 - x)) + 1) / 2;
		return (result == Math.NaN) ? 1.0 : result;
	}

	public static function easeInOutBack(x:Float, c:Float = 1.70158):Float
	{
		if (x <= 0.0) return 0.0;
		if (x >= 1.0) return 1.0;
		var result:Float = (x < 0.5) ? (2 * x * x * ((c + 1) * 2 * x - c)) / 2 : (1 - 2 * (1 - x) * (1 - x) * ((c + 1) * 2 * (1 - x) - c)) / 2;
		return (result == Math.NaN) ? 1.0 : result;
	}

	public static function easeInBack(x:Float, c:Float = 1.70158):Float
	{
		if (x <= 0.0) return 0.0;
		if (x >= 1.0) return 1.0;
		return (1 + c) * x * x * x - c * x * x;
	}

	public static function easeOutBack(x:Float, c:Float = 1.70158):Float
	{
		if (x <= 0.0) return 0.0;
		if (x >= 1.0) return 1.0;
		return 1 + (c + 1) * Math.pow(x - 1, 3) + c * Math.pow(x - 1, 2);
	}
	
	/**
		crude version of FlxMath.wrap. supports floats though
	**/
	public static function wrap(value:Float, min:Float, max:Float):Float
	{
		if (value < min) return max;
		else if (value > max) return min;
		else return value;
	}

    /**
	 * Adjusts the given lerp to account for the time that has passed
	 * 
	 * @param   lerp     The ratio to lerp in 1/60th of a second
	 * @param   elapsed  The amount of time that has actually passed
	 * @since 6.0.0
	 */
	public static function getElapsedLerp(lerp:Float, elapsed:Float):Float
	{
		return 1.0 - Math.pow(1.0 - lerp, elapsed * 60);
	}
	
	/**
	 * Alternative to `FlxMath.roundDecimal` but floors the value rather than rounding it
	 * @param value The number 
	 * @param precision The number of decimals
	 * @return The floored value
	 */
	public static function floorDecimal(value:Float, decimals:Int):Float
	{
		if (decimals < 1) return Math.floor(value);
		
		var tempMult:Float = 1;
		for (i in 0...decimals)
			tempMult *= 10;
			
		var newValue:Float = Math.floor(value * tempMult);
		return newValue / tempMult;
	}
	
	/**
		Makes a number array
		* @param	min starting number. default is 0
		* @param	max ending number
		* @return the new array
	**/
	public static inline function numberArray(?min:Int, max:Int):Array<Int>
	{
		if (min == null) min = 0;
		return [for (i in min...max) i];
	}
	
	/**
	 * Clamps/Bounds a value.
	 */
	public static overload extern inline function clamp(input:Float, min:Float, max:Float):Float
	{
		return FlxMath.bound(input, min, max);
	}
	
	/**
	 * Clamps/Bounds a value.
	 */
	public static overload extern inline function clamp(input:Int, min:Int, max:Int):Float
	{
		if (input < min) input = min;
		if (input > max) input = max;
		return input;
	}
}