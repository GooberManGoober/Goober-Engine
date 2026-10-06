package funkin.scripts;

import funkin.backend.FunkinShader.FunkinRuntimeShader;

import extensions.hscript.Sharables;
import extensions.hscript.IrisEx;

import crowplexus.iris.Iris;

import extensions.hscript.InterpEx;

import funkin.backend.plugins.DebugTextPlugin;
import funkin.objects.*;
import funkin.objects.note.*;

@:access(crowplexus.iris.Iris)
@:access(funkin.states.PlayState)
class FunkinScript extends IrisEx implements IFlxDestroyable
{
	/**
	 * List of all accepted hscript extensions
	 */
	public static final H_EXTS:Array<String> = ['hx', 'hxs', 'hscript'];
	
	/**
	 * wrapper for `Paths.getPath` but attempts to append a supported hx extension to its path
	 * @param path 
	 * @return String
	 */
	public static function getPath(path:String):String
	{
		for (extension in H_EXTS)
		{
			final file = '$path.$extension';
			
			final targetPath = Paths.getPath(file, null, true);
			if (FunkinAssets.exists(targetPath)) return targetPath;
			if (FunkinAssets.exists(file)) return file;
		}
		return path;
	}
	
	/**
	 * Helper to check if a path ends with a support hx extension
	 */
	public static function isHxFile(path:String):Bool
	{
		for (extension in H_EXTS)
			if (path.endsWith(extension)) return true;
			
		return false;
	}
	
	/**
	 * Initiates the debugging backend of Iris
	 */
	public static function init()
	{
		#if FLX_DEBUG
		FlxG.console.registerClass(Iris);
		FlxG.console.registerClass(IrisEx);
		FlxG.console.registerClass(FunkinScript);
		#end
		
		// took this from imposter legacy thanks ashley
		inline function formatFileLoc(fileName:String = 'hscript', lineNumber:Int = 0, x:String = '', prefix:String = '')
		{
			var prefix = '[$prefix$fileName:$lineNumber]';
			
			final modPath:String = Paths.mods(Mods.currentModDirectory + '/');
			if (fileName.startsWith(modPath)) prefix = prefix.replace(modPath, '');
			#if ASSET_REDIRECT
			else if (fileName.startsWith(Paths.trail)) prefix = prefix.replace(Paths.trail, '');
			#end
			
			return '$prefix - $x';
		}
		
		Iris.warn = (x, ?pos) -> {
			final output:String = formatFileLoc(pos.fileName, pos.lineNumber, x);
			
			DebugTextPlugin.instance.addText(Std.string(output), Logger.getHexColourFromSeverity(WARN));
			
			Iris.logLevel(ERROR, x, pos);
		}
		
		Iris.error = (x, ?pos) -> {
			final output:String = formatFileLoc(pos.fileName, pos.lineNumber, x);
			
			DebugTextPlugin.instance.addText(Std.string(output), Logger.getHexColourFromSeverity(ERROR));
			
			Iris.logLevel(NONE, x, pos);
		}
		
		Iris.print = (x, ?pos) -> {
			final output:String = formatFileLoc(pos.fileName, pos.lineNumber, x);
			
			DebugTextPlugin.instance.addText(Std.string(output), Logger.getHexColourFromSeverity(PRINT));
			
			Iris.logLevel(NONE, x, pos);
		}
	}
	
	/**
	 * Creates a new `FunkinScript` from a string
	 * @param scriptContent The raw content of a script in a string.
	 * @param name The name of the script.
	 */
	public static function fromString(script:String, ?name:String = "Script", autoExecute:Bool = true, ?shareables:Sharables, ?modFolder:String)
	{
		return new FunkinScript(script, name, autoExecute, shareables, modFolder);
	}
	
	/**
	 * Creates a new `FunkinScript` from a file path
	 * 
	 * Note: there is no safety checking if the file exists.
	 * 
	 * @param file The path to the file
	 * @param name The name of the script. if null, `file` is used.
	 */
	public static function fromFile(file:String, ?name:String, autoExecute:Bool = true, ?shareables:Sharables, ?modFolder:String)
	{
		name ??= file;
		
		modFolder ??= Paths.getModFolder(file, 'scripts');
		
		return new FunkinScript(FunkinAssets.getContent(file), name, autoExecute, shareables, modFolder);
	}
	
	/**
	 * The Exception provided when execution fails.
	 * 
	 * This will be null if parsing succeeded.
	 */
	public var parsingException:Null<haxe.Exception> = null;
	
	/**
	 * @return Bool Whether parsing was successful.
	 */
	public function parsingFailed():Bool // this is more so a function for clarity.
	{
		return parsingException != null;
	}
	
	public var modFolder:Null<String>;
	
	public function new(script:String, ?name:String = "Script", autoExecute:Bool = true, ?shareables:Sharables, ?modFolder:String)
	{
		super(script, {name: name, autoRun: false, autoPreset: false}, shareables);
		
		(cast interp : InterpEx).parent = FlxG.state;
		
		this.modFolder = modFolder;
		
		preset();
		
		if (autoExecute) execute();
	}
	
	override function execute():Dynamic
	{
		final retVal = try
		{
			super.execute();
		}
		catch (e)
		{
			parsingException = e;
			
			Logger.log('[${name}]: PARSING ERROR: $e', ERROR, true);
			null;
		}
		return retVal;
	}
	
	// kept for notescript stuff
	public function executeFunc(func:String, ?parameters:Array<Dynamic>, ?theObject:Any, ?extraVars:Map<String, Dynamic>):Dynamic
	{
		extraVars ??= [];
		
		if (exists(func))
		{
			var daFunc = get(func);
			if (Reflect.isFunction(daFunc))
			{
				var returnVal:Dynamic = null;
				var defaultShit:Map<String, Dynamic> = [];
				
				if (theObject != null) extraVars.set("this", theObject);
				
				for (key in extraVars.keys())
				{
					defaultShit.set(key, get(key));
					set(key, extraVars.get(key));
				}
				
				try
				{
					returnVal = Reflect.callMethod(theObject, daFunc, parameters ?? []);
				}
				catch (e)
				{
					#if sys
					Sys.println(e.message);
					#end
				}
				
				for (key in defaultShit.keys())
				{
					set(key, defaultShit.get(key));
				}
				
				return returnVal;
			}
		}
		return null;
	}
	
	@:inheritDoc
	override function preset()
	{
		super.preset();
		#if hl
		set('Math', hl.HLFixes.HLMath);
		set('Std', hl.HLFixes.HLStd);
		set("trace", Reflect.makeVarArgs(function(x:Array<Dynamic>) {
			var pos = this.interp != null ? this.interp.posInfos() : Iris.getDefaultPos(this.name);
			var v = x.shift();
			if (x.length > 0) pos.customParams = x;
			Iris.print(Std.string(v), pos);
		}));
		#end
		
		set("StringTools", StringTools);
		
		set("Type", Type);
		set("script", this);
		set("Dynamic", Dynamic);
		set('modFolder', modFolder);
		
		set('StringMap', haxe.ds.StringMap);
		set('IntMap', haxe.ds.IntMap);
		set('ObjectMap', haxe.ds.ObjectMap);
		
		set("Main", Main);
		set("Lib", openfl.Lib);
		set("Assets", lime.utils.Assets);
		set("OpenFlAssets", openfl.utils.Assets);
		
		set('curBpm', Conductor.bpm);
		set('crotchet', Conductor.crotchet);
		set('stepCrotchet', Conductor.stepCrotchet);
		set('version', Main.NMV_VERSION.trim());
		set('asset_redirect', #if ASSET_REDIRECT true #else false #end);
		set('foxlite_allowed', #if FOXLITE_ALLOWED true #else false #end);
		set('Defines', funkin.data.Defines);
		
		// set flixel related stuff
		set("FlxG", flixel.FlxG);
		set("FlxSprite", flixel.FlxSprite);
		set("FlxCamera", funkin.backend.FunkinCamera);
		set("FlxMath", flixel.math.FlxMath);
		set("FlxTimer", flixel.util.FlxTimer);
		set("FlxTween", flixel.tweens.FlxTween);
		set("FlxEase", flixel.tweens.FlxEase);
		set("FlxSound", flixel.sound.FlxSound);
		set('FlxText', flixel.text.FlxText);
		set("FlxRuntimeShader", funkin.backend.FunkinShader.FunkinRuntimeShader);
		set("FlxFlicker", flixel.effects.FlxFlicker);
		set('FlxSpriteUtil', flixel.util.FlxSpriteUtil);
		set("FlxBackdrop", flixel.addons.display.FlxBackdrop);
		set("FlxTiledSprite", flixel.addons.display.FlxTiledSprite);
		set('FlxPoint', flixel.math.FlxPoint.FlxBasePoint);
		
		set("FlxTypedGroup", flixel.group.FlxGroup);
		set("FlxSpriteGroup", flixel.group.FlxSpriteGroup);
		set("FlxEmitter", flixel.effects.particles.FlxEmitter);
		
		set('FlxCameraFollowStyle', flixel.FlxCamera.FlxCameraFollowStyle);
		set("FlxTextBorderStyle", flixel.text.FlxText.FlxTextBorderStyle);
		set("FlxBarFillDirection", flixel.ui.FlxBar.FlxBarFillDirection);
		
		set("FlxAnimate", animate.FlxAnimate);
		set("FlxAnimateFrames", animate.FlxAnimateFrames);
		set("FlxSpriteElement", animate.internal.elements.FlxSpriteElement);
		
		set('Controls', funkin.input.Controls);
		
		// abstracts
		set("FlxTextAlign", funkin.utils.MacroUtil.buildAbstract(flixel.text.FlxText.FlxTextAlign));
		set('FlxAxes', funkin.utils.MacroUtil.buildAbstract(flixel.util.FlxAxes));
		set("FlxKey", funkin.utils.MacroUtil.buildAbstract(flixel.input.keyboard.FlxKey));
		set('BlendMode', funkin.utils.MacroUtil.buildAbstract(openfl.display.BlendMode));
		
		set("keyToString", (key:Int) -> {
			return flixel.input.keyboard.FlxKey.toStringMap.get(key);
		});
		set("keyFromString", (str:String) -> {
			return flixel.input.keyboard.FlxKey.fromStringMap.get(str);
		});
		
		// modchart related
		set("ModManager", funkin.game.modchart.ModManager);
		set("SubModifier", funkin.game.modchart.SubModifier);
		set("NoteModifier", funkin.game.modchart.NoteModifier);
		set("ScriptedModifier", funkin.game.modchart.ScriptedModifier);
		set("EventTimeline", funkin.game.modchart.EventTimeline);
		set("Modifier", funkin.game.modchart.Modifier);
		set("StepCallbackEvent", funkin.game.modchart.events.StepCallbackEvent);
		set("CallbackEvent", funkin.game.modchart.events.CallbackEvent);
		set("ModEvent", funkin.game.modchart.events.ModEvent);
		set("EaseEvent", funkin.game.modchart.events.EaseEvent);
		set("SetEvent", funkin.game.modchart.events.SetEvent);
		
		// FNF-specific things
		set("Paths", Paths);
		set("MusicBeatState", funkin.backend.MusicBeatState);
		set("Conductor", funkin.backend.Conductor);
		set("ClientPrefs", funkin.data.ClientPrefs);
		set("CoolUtil", funkin.utils.CoolUtil);
		set('WindowUtil', funkin.utils.WindowUtil);
		
		set("StageData", funkin.data.StageData);
		set("PlayState", PlayState);
		set('FunkinSound', funkin.audio.FunkinSound);
		
		// custom
		set('FlxColor', funkin.scripts.ScriptClasses.ScriptedFlxColor);
		set('Random', funkin.scripts.ScriptClasses.ScriptedFlxRandom);
		
		// script
		set("FunkinScript", FunkinScript);
		set('ScriptConstants', funkin.scripting.ScriptConstants);
		
		// for compat
		set('HScriptState', funkin.scripting.ScriptedState);
		set('HScriptSubState', funkin.scripting.ScriptedSubState);
		
		set('ScriptedState', funkin.scripting.ScriptedState);
		set('ScriptedSubState', funkin.scripting.ScriptedSubState);
		
		set("GameOverSubState", funkin.states.substates.GameOverSubState);

		#if FOXLITE_ALLOWED
		set("FoxCache", foxlite.FoxCache);
		set("FoxCamera", foxlite.FoxCamera);
		set("FoxModel", foxlite.FoxModel);
		set("FoxShader", foxlite.FoxShader);
		set("FoxScene", foxlite.FoxScene);
		set("FoxInstancedModel", foxlite.FoxInstancedModel);

		set("FoxAnimation", foxlite.animation.FoxAnimation);
		set("FoxAnimationBlender", foxlite.animation.FoxAnimationBlender);
		set("FoxAnimationLinker", foxlite.animation.FoxAnimationLinker);
		set("FoxAnimationPlayer", foxlite.animation.FoxAnimationPlayer);
		set("FoxAnimationTrack", foxlite.animation.FoxAnimationTrack);
		set("FoxEaseType", funkin.utils.MacroUtil.buildAbstract(foxlite.animation.FoxEaseType));
		set("FoxKeyframe", foxlite.animation.FoxKeyframe);
		set("FoxLerp", foxlite.animation.FoxLerp);
		set("FoxTrackType", funkin.utils.MacroUtil.buildAbstract(foxlite.animation.FoxTrackType));

		set("FoxColorUtil", foxlite.color.FoxColorUtil);

		set("BoundingBox", foxlite.culling.BoundingBox);
		set("FrustumPlanes", foxlite.culling.FrustumPlanes);

		set("FoxEnvironment", foxlite.environment.FoxEnvironment);

		set("FlxFox3DSprite", foxlite.extras.FlxFox3DSprite);
		set("FoxFPSCamera", foxlite.extras.FoxFPSCamera);
		set("FoxOrbitCamera", foxlite.extras.FoxOrbitCamera);

		set("FlxTypedSignalImpl", funkin.utils.MacroUtil.buildAbstract(foxlite.flixel.FlxTypedSignalImpl));
		set("FoxDirectionalSound", foxlite.flixel.FoxDirectionalSound);
		set("FoxFlxSprite", foxlite.flixel.FoxFlxSprite);
		set("FoxRenderMetrics", foxlite.flixel.FoxRenderMetrics);

		set("FoxFunkinSprite", extensions.foxlite.FoxFunkinSpriteEx);

		set("FoxGroup", foxlite.group.FoxGroup);
		set("FoxObjectGroup", foxlite.group.FoxObjectGroup);
		set("FoxTypedGroup", foxlite.group.FoxTypedGroup);

		set("FoxInstanceChunkData", foxlite.instancing.FoxInstanceChunkData);
		set("FoxInstanceData", foxlite.instancing.FoxInstanceData);
		set("FoxInstanceUpdateMode", funkin.utils.MacroUtil.buildAbstract(foxlite.instancing.FoxInstanceUpdateMode));

		set("FoxAreaLight", foxlite.lights.FoxAreaLight);
		set("FoxAreaLightShape", funkin.utils.MacroUtil.buildAbstract(foxlite.lights.FoxAreaLightShape));
		set("FoxBaseLight", foxlite.lights.FoxBaseLight);
		set("FoxDirectionalLight", foxlite.lights.FoxDirectionalLight);
		set("FoxLightData", foxlite.lights.FoxLightData);
		set("FoxLightType", funkin.utils.MacroUtil.buildAbstract(foxlite.lights.FoxLightType));
		set("FoxPointLight", foxlite.lights.FoxPointLight);
		set("FoxSpotLight", foxlite.lights.FoxSpotLight);

		// set("FoxAWDLoader", foxlite.loaders.FoxAWDLoader); // Will get added later when this is done
		set("FoxGLTFLoader", foxlite.loaders.FoxGLTFLoader);
		set("FoxJSONLoader", foxlite.loaders.FoxJSONLoader);
		set("FoxLoaderUtil", foxlite.loaders.FoxLoaderUtil);
		set("FoxMTLLoader", foxlite.loaders.FoxMTLLoader);
		set("FoxOBJLoader", foxlite.loaders.FoxOBJLoader);

		set("FoxBlendMode", funkin.utils.MacroUtil.buildAbstract(foxlite.material.FoxBlendMode));
		set("FoxDepthCompareMode", funkin.utils.MacroUtil.buildAbstract(foxlite.material.FoxDepthCompareMode));
		set("FoxMaterial", foxlite.material.FoxMaterial);
		set("FoxTriangleFace", funkin.utils.MacroUtil.buildAbstract(foxlite.material.FoxTriangleFace));

		set("FoxMathUtil", foxlite.math.FoxMathUtil);

		set("FoxIndexBuffer", foxlite.mesh.buffer.FoxIndexBuffer);
		set("FoxVertexBuffer", foxlite.mesh.buffer.FoxVertexBuffer);
		set("FoxVertexBufferType", funkin.utils.MacroUtil.buildAbstract(foxlite.mesh.buffer.FoxVertexBufferType));

		set("FoxCubeMesh", foxlite.mesh.FoxCubeMesh);
		set("FoxLineMesh", foxlite.mesh.FoxLineMesh);
		set("FoxMesh", foxlite.mesh.FoxMesh);
		set("FoxQuadFace", funkin.utils.MacroUtil.buildAbstract(foxlite.mesh.FoxQuadFace));
		set("FoxQuadMesh", foxlite.mesh.FoxQuadMesh);

		#if lime_box3d
		set("FoxPhysicsBodyType", funkin.utils.MacroUtil.buildAbstract(foxlite.physics.FoxPhysicsBodyType));
		set("FoxPhysicsWorld", foxlite.physics.FoxPhysicsWorld);
		#end

		set("TypedArray", foxlite.polyfill.TypedArray);
		set("VectorFactory", foxlite.polyfill.VectorFactory);
		
		set("FoxPostProcess", foxlite.post.FoxPostProcess);
		
		set("FoxRenderer", foxlite.renderer.FoxRenderer);
		set("FoxRenderPass", foxlite.renderer.FoxRenderPass);

		set("FoxArmature", foxlite.skin.FoxArmature);
		set("FoxBone", foxlite.skin.FoxBone);
		set("FoxSkinData", foxlite.skin.FoxSkinData);

		set("FoxPanoramaSky", foxlite.sky.FoxPanoramaSky);

		set("FoxStencilAction", foxlite.stencil.FoxStencilAction);
		set("FoxStencilActionType", funkin.utils.MacroUtil.buildAbstract(foxlite.stencil.FoxStencilActionType));
		set("FoxStencilCompareMode", funkin.utils.MacroUtil.buildAbstract(foxlite.stencil.FoxStencilCompareMode));

		set("FoxCubemapSide", funkin.utils.MacroUtil.buildAbstract(foxlite.texture.FoxCubemapSide));
		set("FoxFramebuffer", foxlite.texture.FoxFramebuffer);
		set("FoxFramebufferCubemap", foxlite.texture.FoxFramebufferCubemap);
		set("FoxMipFilter", funkin.utils.MacroUtil.buildAbstract(foxlite.texture.FoxMipFilter));
		set("FoxTexture", foxlite.texture.FoxTexture);
		set("FoxTextureBuffer", foxlite.texture.FoxTextureBuffer);
		set("FoxTextureCubemap", foxlite.texture.FoxTextureCubemap);
		set("FoxTextureFilter", funkin.utils.MacroUtil.buildAbstract(foxlite.texture.FoxTextureFilter));
		set("FoxWrapMode", funkin.utils.MacroUtil.buildAbstract(foxlite.texture.FoxWrapMode));
		#end
		
		// objects
		set("Note", funkin.objects.note.Note);
		set("Bar", funkin.objects.Bar);
		#if VIDEOS_ALLOWED
		set("FunkinVideoSprite", funkin.video.FunkinVideoSprite);
		#end
		set("BackgroundDancer", funkin.objects.stageobjects.BackgroundDancer);
		set("BackgroundGirls", funkin.objects.stageobjects.BackgroundGirls);
		set("HealthIcon", HealthIcon);
		set("Character", funkin.objects.Character);
		set("NoteSplash", NoteSplash);
		set("BGSprite", BGSprite);
		set("StrumNote", StrumNote);
		set("Alphabet", Alphabet);
		set("FunkinSprite", funkin.objects.FunkinSprite);
		
		set("CutsceneHandler", funkin.objects.CutsceneHandler);
		set('DialogueBox', funkin.objects.DialogueBox);
		
		// modchart related
		set("ModManager", funkin.game.modchart.ModManager);
		set("SubModifier", funkin.game.modchart.SubModifier);
		set("NoteModifier", funkin.game.modchart.NoteModifier);
		set("EventTimeline", funkin.game.modchart.EventTimeline);
		set("Modifier", funkin.game.modchart.Modifier);
		set("StepCallbackEvent", funkin.game.modchart.events.StepCallbackEvent);
		set("CallbackEvent", funkin.game.modchart.events.CallbackEvent);
		set("ModEvent", funkin.game.modchart.events.ModEvent);
		set("EaseEvent", funkin.game.modchart.events.EaseEvent);
		set("SetEvent", funkin.game.modchart.events.SetEvent);
		
		set('inGameOver', false);
		
		set("game", FlxG.state);
		
		if ((FlxG.state is PlayState))
		{
			set("inPlaystate", true);
			set('bpm', PlayState.SONG.bpm);
			set('scrollSpeed', PlayState.SONG.speed);
			set('songName', PlayState.SONG.song);
			set('isStoryMode', PlayState.isStoryMode);
			set('difficulty', PlayState.storyMeta.difficulty);
			set('weekRaw', PlayState.storyMeta.curWeek);
			set('seenCutscene', PlayState.seenCutscene);
			set('week', funkin.data.WeekData.weeksList[PlayState.storyMeta.curWeek]);
			set('difficultyName', funkin.backend.Difficulty.difficulties[PlayState.storyMeta.difficulty]);
			set('songLength', FlxG.sound.music.length);
			set('healthGainMult', PlayState.instance.healthGain);
			set('healthLossMult', PlayState.instance.healthLoss);
			set('instakillOnMiss', PlayState.instance.instakillOnMiss);
			set('botPlay', PlayState.instance.cpuControlled);
			set('practice', PlayState.instance.practiceMode);
			set('startedCountdown', false);
			set('mustHitSection', PlayState.SONG?.notes[0]?.mustHitSection ?? false);
			
			set("global", PlayState.instance.variables);
			set("getInstance", funkin.scripting.ScriptConstants.getInstance);
			
			set('setVar', (varName:String, val:Dynamic) -> PlayState.instance.variables.set(varName, val));
			set('getVar', (varName:String) -> PlayState.instance.variables.get(varName));
			
			set('initScript', (path:String) -> {
				path = FunkinScript.getPath(path);
				if (!PlayState.instance.scripts.exists(path)) PlayState.instance.initFunkinScript(path);
			});
		}
		else
		{
			set("inPlaystate", false);
		}
		
		set("newShader", FunkinRuntimeShader.fromPath);
		
		set("newOption", (key:String, type:String, defaultValue:Dynamic, ?settings:funkin.data.ModOptions.OptionSettings) -> {
			funkin.data.ModOptions.add(this.modFolder, key, type, defaultValue, settings);
		});
		set("getOption", funkin.data.ModOptions.getValue);
	}
	
	public function event<T:BasicEvent>(func:String, event:T):T
	{
		call(func, [event]);
		return event;
	}
	
	public function toString():String
	{
		return name;
	}
}
