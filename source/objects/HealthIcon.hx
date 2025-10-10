package objects;

class HealthIcon extends FlxSprite
{
	public var sprTracker:FlxSprite;
	private var isOldIcon:Bool = false;
	private var isPlayer:Bool = false;
	private var char:String = '';

	private var isAnimated:Bool = false;
	private var isShakeable:Bool = false;

	public function new(char:String = 'bf', isPlayer:Bool = false, isAnimated:Bool = false, canShake:Bool = false, ?allowGPU:Bool = true)
	{
		super();
		isOldIcon = (char == 'bf-old');
		this.isPlayer = isPlayer;
		this.isAnimated = isAnimated;
		this.isShakeable = canShake;
		changeIcon(char, isAnimated, canShake, allowGPU);
		scrollFactor.set();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (isShakeable)
			shake(2.7, 2, 0.1);

		if (sprTracker != null)
			setPosition(sprTracker.x + sprTracker.width + 12, sprTracker.y - 30);
	}

	private var iconOffsets:Array<Float> = [0, 0];
	public function changeIcon(char:String, ?allowGPU:Bool = true) {
		if(this.char != char) {
			var name:String = 'icons/' + char;
			if(!Paths.fileExists('images/' + name + '.png', IMAGE)) name = 'icons/icon-' + char; //Older versions of psych engine's support
			if(!Paths.fileExists('images/' + name + '.png', IMAGE)) name = 'icons/icon-face'; //Prevents crash from missing icon
			
			var graphic = Paths.image(name, allowGPU);

			if (!isAnimated)
			{
				loadGraphic(graphic, true, Math.floor(graphic.width / 2), Math.floor(graphic.height));
				iconOffsets[0] = (width - 150) / 2;
				iconOffsets[1] = (height - 150) / 2;
			}
			else
			{
				frames = Paths.getSparrowAtlas(name);
				iconOffsets[0] = (width - 150) / 2;
				iconOffsets[1] = (width - 150) / 2;
			}
			updateHitbox();

			if (!isAnimated)
			{
				animation.add(char, [0, 1], 0, false, isPlayer);
				animation.play(char);
			}
			else
			{
				animation.addByPrefix(char + "Neutral", "icon neutral", 24, true, isPlayer);
				animation.addByPrefix(char + "Losing", "icon losing", 24, true, isPlayer);
				animation.play(char + "Neutral");
			}

			this.char = char;
			this.isAnimated = isAnimated;
			this.isShakeable = isShakeable;

			if(char.endsWith('-pixel'))
				antialiasing = false;
			else
				antialiasing = ClientPrefs.data.antialiasing;
		}
	}

	override function updateHitbox()
	{
		super.updateHitbox();
		offset.x = iconOffsets[0];
		offset.y = iconOffsets[1];
	}

	public function getCharacter():String {
		return char;
	}
}
