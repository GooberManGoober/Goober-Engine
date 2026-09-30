package funkin.states.options;

import funkin.data.ModOptions;
import funkin.data.ModOptions.ModOptionObject;

using StringTools;

class ModOptionsSubState extends BaseOptionsMenu
{
	public function new()
	{
		title = '${Mods.currentModDirectory} Options';
		rpcTitle = 'Custom Mod Options';
		
		for (key in ModOptions.options.keys())
		{
			final option = ModOptions.options.get(key);
			
			var obj:ModOptionObject = new ModOptionObject(option);
			obj.options = option.settings.options;
			addOption(obj);
		}
		
		super();
	}
}
