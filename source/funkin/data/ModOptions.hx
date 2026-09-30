package funkin.data;

import flixel.util.FlxSave;

class ModOption implements flixel.util.FlxDestroyUtil.IFlxDestroyable
{
	public var key:String;
	public var type:String;
	public var value:Dynamic;
	public var defaultValue:Dynamic;
	public var settings:OptionSettings;
	
	public function new(key:String, type:String, value:Dynamic, ?settings:OptionSettings)
	{
		this.key = key;
		this.type = type.toLowerCase();
		this.value = value;
		this.defaultValue = value;
		
		this.settings = settings;
		validateSettings();
	}
	
	public function validateSettings()
	{
		settings.description ??= 'No description provided.';
		
		settings.onChange ??= null;
		settings.callback ??= null;
		
		settings.options ??= ['Option 1', 'Option 2'];
		settings.displayFormat ??= '%v';
		
		settings.stepSize ??= 1;
		settings.minValue ??= null;
		settings.maxValue ??= null;
		settings.decimals ??= 1;
	}
	
	public function toString():String return '(key: $key, type: $type, value: $value)';
	
	public function destroy()
	{
		key = '';
		value = null;
		type = '';
	}
}

typedef OptionSettings =
{
	var description:String;
	var onChange:Void->Void;
	var callback:Void->Void;
	
	// for strings
	var options:Array<String>;
	var displayFormat:String;
	
	// for steppers
	var stepSize:Null<Float>;
	var minValue:Null<Float>;
	var maxValue:Null<Float>;
	var decimals:Null<Int>;
}

class ModOptionObject extends funkin.states.options.Option
{
	public function new(option:ModOption)
	{
		super(option.key, option.settings.description, option.key, option.type, option.defaultValue, option.settings.options);
		
		switch (this.type)
		{
			case 'int':
				this.minValue = option.settings.minValue;
				this.maxValue = option.settings.maxValue;
				this.changeValue = option.settings.stepSize;
			case 'float':
				this.minValue = option.settings.minValue;
				this.maxValue = option.settings.maxValue;
				this.changeValue = option.settings.stepSize;
				this.decimals = option.settings.decimals;
			case 'string':
				this.displayFormat = option.settings.displayFormat;
		}
	}
	
	override public function getValue():Dynamic
	{
		return ModOptions.getValue(variable);
	}
	
	override public function setValue(value:Dynamic)
	{
		ModOptions.setValue(variable, value);
	}
}

class ModOptions
{
	public static var currentMod:String = '';
	public static var options:Map<String, ModOption> = new Map();
	public static var length(get, never):Int;
	
	private static function get_length()
	{
		var count = 0;
		for (key in options.keys())
			count++;
			
		return count;
	}
	
	private static function getSave(mod:String):FlxSave
	{
		var save = new FlxSave();
		save.bind('mods/$mod');
		
		return save;
	}
	
	public static function init(?modName:String = 'NMV-Base-Game')
	{
		currentMod = modName;
		for (i in options.keys())
		{
			var option = options.get(i);
			option = FlxDestroyUtil.destroy(option);
		}
		options.clear();
		
		var save = getSave(modName);
		if (save != null && save.data.options != null) CoolUtil.copyMapValues(save.data.options, options);
		
		save = FlxDestroyUtil.destroy(save);
	}
	
	public static function flush()
	{
		var save = getSave(currentMod);
		save.data.options = options;
		save.close();
	}
	
	public static function add(key:String, type:String = 'string', defaultValue:Dynamic = 'null', ?settings:OptionSettings)
	{
		if (!options.exists(key))
		{
			if (defaultValue == 'null')
			{
				switch (type.toLowerCase())
				{
					case 'bool':
						defaultValue = false;
					case 'int' | 'float':
						defaultValue = 0;
					case 'string':
						defaultValue = '';
					default:
						type = 'null';
				}
			}
			
			if (type != 'null')
			{
				var option = new ModOption(key, type, defaultValue, settings);
				options.set(key, option);
				
				trace(option);
			}
			else Logger.log('Unable to create custom option [$key]. Is your option type incorrect / null?', ERROR);
		}
		flush();
	}
	
	public static function get(key:String):ModOption
	{
		if (options.exists(key))
		{
			final option = options.get(key);
			
			if (option == null || option.type == 'null')
			{
				Logger.log('Custom Option [$key] returned null. Does it exist / was it created properly?', ERROR);
				return null;
			}
			
			return option;
		}
		
		return null;
	}
	
	public static function setValue(key:String, value:Dynamic)
	{
		final option = get(key);
		// trace(key);
		option.value = value;
		
		options.set(key, option);
	}
	
	public static function getValue(key:String):Dynamic
	{
		final option = get(key);
		
		if (option != null) return option.value;
		
		return null;
	}
}
