package funkin.states.editors;

import funkin.Mods;

import haxe.Json;

import haxe.ui.backend.flixel.UIState;
import haxe.ui.containers.dialogs.CollapsibleDialog;

using funkin.states.editors.ui.ToolKitUtils;

@:build(haxe.ui.ComponentBuilder.build("assets/excluded/ui/modMetaEditor.xml"))
class ModMetaDialog extends CollapsibleDialog {}

class ModMetaEditorState extends UIState
{
	var dialog:ModMetaDialog;

	var bg:FlxSprite;
	var box:FlxSprite;
	var description:FlxText;
	var checkbox:FlxSprite;
	var name:FlxText;
	var icon:FlxSprite;

	var directoryTxt:FlxText;

	var modPack:ModMeta;
	var modPackName:String;

	var isTextFieldFocused:Bool = false;

	public function new(shitFuck:String)
	{
		super();
		
		modPackName = shitFuck;
		modPack = Mods.getPack(shitFuck);
	}
	
	override function create()
	{
		super.create();
		
		FlxG.mouse.visible = true;

		bg = new FlxSprite().loadGraphic(Paths.image("menus/menuDesat"));
		add(bg);
		
		box = new FlxSprite().loadGraphic(Paths.image("menus/mods/menubox"));
		// box.scale.set(1.3, 1.3);
		box.updateHitbox();
		box.screenCenter().x += 135;
		add(box);
		
		var text = (modPack == null || modPack.description == null) ? "No description provided." : modPack.description;

		description = new FlxText();
		description.setFormat(Paths.DEFAULT_FONT, 28, FlxColor.WHITE, FlxTextAlign.LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		description.fieldWidth = box.width - 20;
		description.text = text;
		description.setPosition(box.x + 10, box.y + 65);
		add(description);
		
		
		var iPath = modPack == null ? Paths.image("branding/icon/fallback") : Paths.image(modPack.iconFile);
		if (iPath == null) iPath = Paths.image("branding/icon/fallback");

		icon = new FlxSprite();
		icon.loadGraphic(iPath);
		icon.setGraphicSize(45);
		icon.updateHitbox();
		icon.setPosition(box.x + 15, box.y);
		add(icon);

		name = new FlxText();
		name.setFormat(Paths.DEFAULT_FONT, 40, FlxColor.WHITE, FlxTextAlign.CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		name.text = (modPack == null ? Mods.currentModDirectory : modPack.name);
		name.setPosition(icon.x + icon.width + 10, icon.y + (icon.height - name.height) / 2);
		add(name);
		
		add(new FlxSprite().loadGraphic(Paths.image("menus/mods/menuborder1")));
		add(new FlxSprite(685, 645).loadGraphic(Paths.image("menus/mods/menuborder2")));

		var textBG:FlxSprite = new FlxSprite(0, FlxG.height - 42).makeGraphic(FlxG.width, 42, 0xFF000000);
		textBG.alpha = 0.6;
		add(textBG);
		
		directoryTxt = new FlxText(textBG.x, textBG.y + 4, FlxG.width, 'Loaded Mod Directory: ${Mods.currentModDirectory}', 32);
		directoryTxt.setFormat(Paths.DEFAULT_FONT, 32, FlxColor.WHITE, CENTER);
		directoryTxt.scrollFactor.set();
		directoryTxt.text = directoryTxt.text.toUpperCase();
		add(directoryTxt);
		
		dialog = new ModMetaDialog();
		dialog.showDialog(false);
		add(dialog);

		dialog.x = 10;
		dialog.y = box.y;
		dialog.bindDialogToView(box.y);

		bindDialog();
	}
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		
		ToolKitUtils.update();

		isTextFieldFocused = (ToolKitUtils.currentFocus != null);
		
		if (!isTextFieldFocused)
		{
			if (FlxG.keys.pressed.CONTROL)
			{
				if (FlxG.keys.justPressed.S) saveMetaToFile(FlxG.keys.pressed.SHIFT);
			}
		}
		
		if (FlxG.mouse.justPressed || FlxG.mouse.justPressedRight) FlxG.sound.play(Paths.sound('ui/mouseClick'));

		if (!isTextFieldFocused)
		{
			FlxG.sound.muteKeys = ClientPrefs.muteKeys;
			FlxG.sound.volumeDownKeys = ClientPrefs.volumeDownKeys;
			FlxG.sound.volumeUpKeys = ClientPrefs.volumeUpKeys;
		}
		else
		{
			FlxG.sound.muteKeys = [];
			FlxG.sound.volumeDownKeys = [];
			FlxG.sound.volumeUpKeys = [];
		}
		
		if (FlxG.keys.justPressed.ESCAPE)
		{
			FlxG.switchState(() -> {
				new funkin.states.ModsState();
			});
		}
	}

	function bindDialog()
	{
		dialog.modNameTextField.value = modPack.name;
		dialog.descTextField.value = modPack.description;
		dialog.iconFileTextField.value = modPack.iconFile;

		dialog.windowTitleTextField.value = modPack.windowTitle;
		dialog.defaultTransitionTextField.value = modPack.defaultTransition;
		dialog.discordClientIDTextField.value = modPack.discordClientID;

		dialog.globalCheckbox.selected = modPack.global;

		if (modPack.stateRedirects != null)
		{
			dialog.titleStateTextField.value = modPack.stateRedirects.get('TitleState');
			dialog.storyMenuStateTextField.value = modPack.stateRedirects.get('StoryMenuState');
			dialog.mainMenuStateTextField.value = modPack.stateRedirects.get('MainMenuState');
			dialog.freeplayStateTextField.value = modPack.stateRedirects.get('FreeplayState');
			dialog.creditsStateTextField.value = modPack.stateRedirects.get('CreditsState');
			dialog.optionsStateTextField.value = modPack.stateRedirects.get('OptionsState');
		}

		dialog.defaultFontTextField.value = modPack.defaultFont;
		dialog.uiPrefixTextField.value = modPack.uiPrefix;
		dialog.comboPrefixTextField.value = modPack.comboPrefix;
		dialog.ratingsPrefixTextField.value = modPack.ratingsPrefix;
		dialog.countdownPrefixTextField.value = modPack.countdownPrefix;
		dialog.defaultHUDTextField.value = modPack.defaultHUDClass;
		
		dialog.modNameTextField.onChange = function(event) {
			name.text = dialog.modNameTextField.value;
		}

		dialog.descTextField.onChange = function(event) {
			description.text = dialog.descTextField.value;
			if (dialog.descTextField.value == null || dialog.descTextField.value.description == null) description.text = "No description provided.";
			else description.text = dialog.descTextField.value;
		}

		dialog.iconFileTextField.onChange = function(event) {
			var iPath;
			if ((Paths.fileExists('images/' + dialog.iconFileTextField.value + '.png'))) iPath = Paths.image(dialog.iconFileTextField.value);
			else iPath = Paths.image("branding/icon/fallback");
			icon.loadGraphic(iPath);

			icon.setGraphicSize(45);
			icon.updateHitbox();
			icon.setPosition(box.x + 15, box.y);
		}

		dialog.defaultFontTextField.onChange = function(event) {
			directoryTxt.font = name.font = description.font = dialog.defaultFontTextField.value;
			if (dialog.defaultFontTextField.value == "" || dialog.defaultFontTextField.value == null) directoryTxt.font = name.font = description.font = Paths.DEFAULT_FONT;
			else directoryTxt.font = name.font = description.font = dialog.defaultFontTextField.value;
		}

		dialog.saveButton.onClick = (ev) -> saveMetaToFile(true);
	}

	function saveMetaToFile(showDialog:Bool = true)
	{
		final json = {
			"name": dialog.modNameTextField.value,
			"global": dialog.globalCheckbox.selected,
			"description": dialog.descTextField.value,
		};

		if (dialog.iconFileTextField.value != null && dialog.iconFileTextField.value != "")
			Reflect.setField(json, "iconFile", dialog.iconFileTextField.value);
		if (dialog.windowTitleTextField.value != null && dialog.windowTitleTextField.value != "")
			Reflect.setField(json, "windowTitle", dialog.windowTitleTextField.value);
		if (dialog.defaultTransitionTextField.value != null && dialog.defaultTransitionTextField.value != "")
			Reflect.setField(json, "defaultTransition", dialog.defaultTransitionTextField.value);
		if (dialog.discordClientIDTextField.value != null && dialog.discordClientIDTextField.value != "")
			Reflect.setField(json, "discordClientID", dialog.discordClientIDTextField.value);

		var redirects = {};

		if (dialog.titleStateTextField.value != null && dialog.titleStateTextField.value != "")
			Reflect.setField(redirects, "TitleState", dialog.titleStateTextField.value);
		if (dialog.storyMenuStateTextField.value != null && dialog.storyMenuStateTextField.value != "")
			Reflect.setField(redirects, "StoryMenuState", dialog.storyMenuStateTextField.value);
		if (dialog.mainMenuStateTextField.value != null && dialog.mainMenuStateTextField.value != "")
			Reflect.setField(redirects, "MainMenuState", dialog.mainMenuStateTextField.value);
		if (dialog.freeplayStateTextField.value != null && dialog.freeplayStateTextField.value != "")
			Reflect.setField(redirects, "FreeplayState", dialog.freeplayStateTextField.value);
		if (dialog.creditsStateTextField.value != null && dialog.creditsStateTextField.value != "")
			Reflect.setField(redirects, "CreditsState", dialog.creditsStateTextField.value);
		if (dialog.optionsStateTextField.value != null && dialog.optionsStateTextField.value != "")
			Reflect.setField(redirects, "OptionsState", dialog.optionsStateTextField.value);

		if (redirects != { }) Reflect.setField(json, "stateRedirects", redirects);

		if (dialog.defaultFontTextField.value != null && dialog.defaultFontTextField.value != "")
			Reflect.setField(json, "defaultFont", dialog.defaultFontTextField.value);
		if (dialog.uiPrefixTextField.value != null && dialog.uiPrefixTextField.value != "")
			Reflect.setField(json, "uiPrefix", dialog.uiPrefixTextField.value);
		if (dialog.comboPrefixTextField.value != null && dialog.comboPrefixTextField.value != "")
			Reflect.setField(json, "comboPrefix", dialog.comboPrefixTextField.value);
		if (dialog.ratingsPrefixTextField.value != null && dialog.ratingsPrefixTextField.value != "")
			Reflect.setField(json, "ratingsPrefix", dialog.ratingsPrefixTextField.value);
		if (dialog.countdownPrefixTextField.value != null && dialog.countdownPrefixTextField.value != "")
			Reflect.setField(json, "countdownPrefix", dialog.countdownPrefixTextField.value);

		if (dialog.defaultHUDTextField.value != null && dialog.defaultHUDTextField.value != "")
			Reflect.setField(json, "defaultHUDClass", dialog.defaultHUDTextField.value);

		final dataToSave:String = Json.stringify(json, "\t");
		
		if (dataToSave.length > 0)
		{
			if (showDialog)
			{
				function onFileSave(path:String)
				{
					ToolKitUtils.makeNotification('Metadata File Saving', 'Successfully saved.', Success);
					FlxG.sound.play(Paths.sound('ui/success'));
				}
				
				function onFileCancel()
				{
					ToolKitUtils.makeNotification('Metadata File Saving', 'Saving was canceled.', Info);
					FlxG.sound.play(Paths.sound('ui/warn'));
				}
				
				FileUtil.saveFile(dataToSave, 'meta.json', onFileSave, onFileCancel);
			}
			else
			{
				ToolKitUtils.makeNotification('Metadata File Saving', 'Successfully saved.', Success);
				var path:String = 'content/$modPackName/meta.json';
				
				ToolKitUtils.makeNotification('Metadata File Saving', 'Successfully saved to $path.', Success);
				FlxG.sound.play(Paths.sound('ui/success'));
				
				FileUtil.saveFileToPath(dataToSave, 'meta.json');
				FileUtil.saveFileToPath(dataToSave, path);
			}
		}
	}
}
