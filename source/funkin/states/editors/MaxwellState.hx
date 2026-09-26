package funkin.states.editors;

#if FOXLITE_ALLOWED
import funkin.states.MainMenuState;
import funkin.Mods;

import foxlite.animation.FoxAnimationPlayer;
import foxlite.loaders.FoxGLTFLoader;
import foxlite.FoxScene;
import foxlite.extras.FoxFPSCamera;
import foxlite.flixel.FoxFlxSprite;
import foxlite.flixel.FoxRenderMetrics;
import foxlite.renderer.FoxRenderer;

using StringTools;

class MaxwellState extends MusicBeatState
{
    var scene:FoxScene;
    var cam:FoxFPSCamera;

    var player:FoxAnimationPlayer;
    var maxwell:Dynamic;
    
    override function create()
    {
        super.create();

        FoxRenderer.forceSyncLoading = true;

        // Scene
        scene = new FoxScene(FlxG.width, FlxG.height);
        scene.scrollFactor.set(0, 0);
        add(scene); 

        // Camera
        cam = new FoxFPSCamera();
        cam.enableControls = false;
        cam.bgColor = FlxColor.GRAY;

        scene.foxCameras.push(cam);

        maxwell = FoxGLTFLoader.load("models/Maxwell/scene.gltf");
        if (maxwell != null)
        {
            scene.add(maxwell.scenes[0]); // Add a gltf scene

            player = maxwell.scenes[0].animation;
            player.play("Take 001");
            player.curAnim.loop = true; // Set animation to loop
        }

        add(new FoxRenderMetrics());
    }

    override function destroy()
    {
        super.destroy();
        
        scene?.destroy();
    }

    override function update(elapsed)
    {
        super.update(elapsed);

        if (FlxG.keys.justPressed.SPACE && maxwell != null) player.playing = !player.playing;
        
        if (controls.BACK) FlxG.switchState(new MainMenuState());

        if(!cam.enableControls) {
            cam.angleX = -0.260;
            cam.angleY = -1;
            cam.angleZ = 0;

            cam.x = -50;
            cam.y = 45;
            cam.z = 40;
        }

        if(FlxG.keys.justPressed.BREAK) {
            cam.enableControls = !cam.enableControls;
            if(cam.enableControls) {
                cam.targetAngle.copyFrom(cam.rotation);
            }
        }
    }
}
#end