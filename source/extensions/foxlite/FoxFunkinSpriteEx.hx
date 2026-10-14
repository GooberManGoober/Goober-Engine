package extensions.foxlite;

#if FOXLITE_ALLOWED
import foxlite.material.FoxMaterial;
import foxlite.material.FoxTriangleFace;

import foxlite.FoxShader;

import foxlite.funkin.FoxFunkinSprite;
import funkin.objects.FunkinSprite;

class FoxFunkinSpriteEx extends FoxFunkinSprite
{
    var funkinSprite:FunkinSprite = null;
    
    override function new(target:FunkinSprite, materialOrShader:Any, ?spritePixelSize:Float)
    {
        var _material:FoxMaterial = null;

		if(Std.isOfType(materialOrShader, FoxShader)) {
			_material = FoxMaterial.create((materialOrShader:FoxShader) ?? FoxShader.fromAsset(FoxShader.BASIC));
			_material.shadowCulling = FoxTriangleFace.NONE; // Render shadow for front and back faces
		}
		else if(Std.isOfType(materialOrShader, FoxMaterial)) _material = materialOrShader;
        
        super(target, _material, spritePixelSize);

        funkinSprite = target;
    }
    
    override function calculateOffsetMatrix() {
        var angle = sprite.frame.angle;
		sprite.frame.prepareMatrix(_matrix, angle, sprite.flipX, sprite.flipY);
		if (angle == -90) {
			final srcX = sprite.frame.sourceSize.x;
			final srcY = sprite.frame.sourceSize.y;
			var aspect = srcX / srcY;
			_matrix.translate(-srcX/aspect, srcY*aspect);
		}
		_matrix.translate(-sprite.origin.x, -sprite.origin.y);
        
		if (funkinSprite != null) _matrix.translate(-funkinSprite?._transformedAnimOffset.x, -funkinSprite?._transformedAnimOffset.y); // shi man idk
	}
}
#end