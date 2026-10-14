package funkin.states.editors;

import haxe.ui.backend.flixel.UIState;

import funkin.video.FunkinVideoSprite;

import openfl.Lib;

class ModchartEditorState extends UIState
{
    /**
     * I do actually want to make this a real editor, but because I have no idea how it should look/behave, it's just a joke state for now
    */
    
    override function create()
    {
        super.create();

        var joobi:FlxSprite = new FlxSprite(0, 0).loadGraphic(Paths.image("editors/joobiLaugh"));
        joobi.screenCenter();
        add(joobi);

        var text:FlxText = new FlxText(0, 600, FlxG.width, "I am NOT adding that shit.", 24);
        text.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
        text.borderSize = 1.25;
        add(text);

        new FlxTimer().start(5, (t:FlxTimer) -> {
            FlxG.switchState(new MainMenuState());
        });
    }
}