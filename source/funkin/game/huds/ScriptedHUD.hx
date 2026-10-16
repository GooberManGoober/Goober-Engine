package funkin.game.huds;

import funkin.scripts.FunkinScript;

class ScriptedHUD extends BaseHUD
{
    public var script:Null<FunkinScript> = null;

    public function new(parent:PlayState, name:String = '', hscriptPath:String)
	{
		this.parent = parent;
		
		script = FunkinScript.fromFile(hscriptPath, name, true, PlayState.instance?.scripts?.scriptShareables);
		
		if (script == null || script.parsingFailed())
		{
			Logger.log('HUD script "$hscriptPath" could not be loaded', WARN);
			
			script = FlxDestroyUtil.destroy(script);
		}
		else @:privateAccess (cast script.interp : extensions.hscript.InterpEx).parent = this;

        this.parent = parent;

		super(parent);

		init();

		if (script.exists('onLoad')) script.call('onLoad');
	}

    override function onSongStart()
    {
        if (script.exists('onSongStart')) script.call('onSongStart');
    }

    override function update(elapsed:Float)
	{
		if (script.exists('onUpdate')) script.call('onUpdate', [elapsed]);
        
        super.update(elapsed);

        if (script.exists('onUpdatePost')) script.call('onUpdatePost', [elapsed]);
	}
	
	override function beatHit()
	{
		if (script.exists('onBeatHit')) script.call('onBeatHit');
	}
	
	override function onCharacterChange()
	{
		if (script.exists('onCharacterChange')) script.call('onCharacterChange');
	}
	
	override function onHealthChange(health:Float)
	{
		if (script.exists('onHealthChange')) script.call('onHealthChange', [health]);
	}

    override public function onUpdateScore(score:Int = 0, accuracy:Float = 0, misses:Int = 0, missed:Bool = false):Void
    {
        if (script.exists('onUpdateScore')) script.call('onUpdateScore', [score, accuracy, misses, missed]);
    }
	
	override function popUpScore(daRating:funkin.game.Rating, combo:Int, note:funkin.objects.note.Note)
	{
		if (script.exists('onPopUpScore')) script.call('onPopUpScore', [daRating, combo, note]);
		
		if (script.exists('onPopUpScorePost')) script.call('onPopUpScorePost', [daRating, combo, note]);
	}
	
	override function cachePopUpScore()
	{
		if (script.exists('cachePopUpScore')) script.call('cachePopUpScore');
	}

    public override function destroy():Void
	{
		if (script.exists('onDestroy')) script.executeFunc('onDestroy');
		script.destroy();
		script = null;
		
		super.destroy();
	}
}