package objects;

import shaders.RGBPalette;
import shaders.RGBPalette.RGBShaderReference;

class SustainSplash extends FlxSprite {
	public var rgbShader:RGBShaderReference;
	public var strum:StrumNote;
	override public function new(strum:StrumNote) {
		super();
		this.strum = strum;

		@:privateAccess
		if (!PlayState.isPixelStage)
			rgbShader = new RGBShaderReference(this, Note.initializeGlobalRGBShader(strum.noteData));

		frames = Paths.getSparrowAtlas(PlayState.isPixelStage ? "pixelUI/pixelNoteHoldCover" : "noteSplashes/sustain_cover");
		animation.addByPrefix('cover', 'holdCoverStart0', 24, false);
		animation.addByPrefix('splash', 'holdCoverEnd0', 24, false);
		animation.addByPrefix('loop', 'holdCover0', 24);
		animation.play("loop");
		updateHitbox();
		visible = false;
		antialiasing = PlayState.isPixelStage ? false : ClientPrefs.data.antialiasing;
	}

	public var updatedThisFrame:Bool = false;

	public inline function show() {
		updatedThisFrame = true;
		visible = true;
		if (animation.curAnim.name != "loop") {
			animation.play("cover");
			center();
		}
	}
	public inline function hide(miss:Bool = false) {
		if (animation.curAnim.name == "splash") return;

		updatedThisFrame = true;
		if (miss) visible = false;
		if (animation.curAnim.name != "splash") {
			animation.play("splash");
			center();
		}
	}

	override public function update(elapsed:Float) {
		super.update(elapsed);
		updatedThisFrame = false;

		scale.set(strum.scale.x / 0.7, strum.scale.y / 0.7);
		updateHitbox();

		if (animation.curAnim.finished) {
			if (animation.curAnim.name == "cover") animation.play("loop");
			if (animation.curAnim.name == "splash") visible = false;
		}

		alpha = strum.alpha;
		
		center();
	}

	public function center() {
		centerOffsets();
		setPosition(strum.x, strum.y);
		offset.set(PlayState.isPixelStage ? -185 : 106.25, PlayState.isPixelStage ? -25 : 100);
	}
}