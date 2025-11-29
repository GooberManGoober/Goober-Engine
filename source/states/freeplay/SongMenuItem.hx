package states.freeplay;

import backend.funkin.Scoring.ScoringRank;
import states.freeplay.FreeplayState.FreeplaySongData;
import states.freeplay.FreeplayState.FreeplaySongData;
import flixel.group.FlxGroup;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.text.FlxText;
import flixel.util.FlxTimer;
import openfl.display.BlendMode;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.addons.effects.FlxTrail;
import flixel.util.FlxColor;
import backend.funkin.MathUtil;
import states.freeplay.PixelatedIcon;

class SongMenuItem extends FlxSpriteGroup
{
  public var capsule:FlxSprite;

  var pixelIcon:PixelatedIcon;

  /**
   * Modify this by calling `init()`
   * If `null`, assume this SongMenuItem is for the "Random Song" option.
   */
  public var songData(default, null):Null<FreeplaySongData> = null;

  public var selected(default, set):Bool;

  public var songText:CapsuleText;
  public var favIconBlurred:FlxSprite;
  public var favIcon:FlxSprite;

  public var ranking:FreeplayRank;
  public var blurredRanking:FreeplayRank;

  public var fakeRanking:FreeplayRank;
  public var fakeBlurredRanking:FreeplayRank;

  var ranks:Array<String> = ["fail", "average", "great", "excellent", "perfect", "perfectsick"];

  public var targetPos:FlxPoint = new FlxPoint();
  public var doLerp:Bool = false;
  public var doJumpIn:Bool = false;

  public var doJumpOut:Bool = false;

  public var onConfirm:Void->Void;

  var impactThing:FlxSprite;

  public var sparkle:FlxSprite;

  var sparkleTimer:FlxTimer;

  public function new(x:Float, y:Float)
  {
    super(x, y);

    capsule = new FlxSprite();
    capsule.frames = Paths.getSparrowAtlas('freeplay/freeplayCapsule');
    capsule.animation.addByPrefix('selected', 'mp3 capsule w backing0', 24);
    capsule.animation.addByPrefix('unselected', 'mp3 capsule w backing NOT SELECTED', 24);
    // capsule.animation
    add(capsule);

    // var debugNumber2:CapsuleNumber = new CapsuleNumber(0, 0, true, 2);
    // add(debugNumber2);

    // doesn't get added, simply is here to help with visibility of things for the pop in!
    grpHide = new FlxGroup();

    fakeRanking = new FreeplayRank(420, 41);
    add(fakeRanking);

    fakeBlurredRanking = new FreeplayRank(fakeRanking.x, fakeRanking.y);
    add(fakeBlurredRanking);

    fakeRanking.visible = false;
    fakeBlurredRanking.visible = false;

    ranking = new FreeplayRank(420, 41);
    add(ranking);

    blurredRanking = new FreeplayRank(ranking.x, ranking.y);
    add(blurredRanking);

    sparkle = new FlxSprite(ranking.x, ranking.y);
    sparkle.frames = Paths.getSparrowAtlas('freeplay/sparkle');
    sparkle.animation.addByPrefix('sparkle', 'sparkle', 24, false);
    sparkle.animation.play('sparkle', true);
    sparkle.scale.set(0.8, 0.8);
    sparkle.blend = BlendMode.ADD;

    sparkle.visible = false;
    sparkle.alpha = 0.7;

    add(sparkle);

    songText = new CapsuleText(capsule.width * 0.26, 45, 'Random', Std.int(40 * realScaled));
    add(songText);
    grpHide.add(songText);

    pixelIcon = new PixelatedIcon(60,14);
    add(pixelIcon);
    grpHide.add(pixelIcon);

    favIconBlurred = new FlxSprite(380, 40);
    favIconBlurred.frames = Paths.getSparrowAtlas('freeplay/favHeart');
    favIconBlurred.animation.addByPrefix('fav', 'favorite heart', 24, false);
    favIconBlurred.animation.play('fav');
    favIconBlurred.setGraphicSize(50, 50);
    favIconBlurred.blend = BlendMode.ADD;
    favIconBlurred.visible = false;
    add(favIconBlurred);

    favIcon = new FlxSprite(favIconBlurred.x, favIconBlurred.y);
    favIcon.frames = Paths.getSparrowAtlas('freeplay/favHeart');
    favIcon.animation.addByPrefix('fav', 'favorite heart', 24, false);
    favIcon.animation.play('fav');
    favIcon.setGraphicSize(50, 50);
    favIcon.visible = false;
    favIcon.blend = BlendMode.ADD;
    add(favIcon);

    setVisibleGrp(false);
  }

  function sparkleEffect(timer:FlxTimer):Void
  {
    sparkle.setPosition(FlxG.random.float(ranking.x - 20, ranking.x + 3), FlxG.random.float(ranking.y - 29, ranking.y + 4));
    sparkle.animation.play('sparkle', true);
    sparkleTimer = new FlxTimer().start(FlxG.random.float(1.2, 4.5), sparkleEffect);
  }

  // no way to grab weeks rn, so this needs to be done :/
  // negative values mean weekends
  function checkWeek(id:Int):Void
  {
    // trace(name);
    var weekNum:Int = id;
  }

  /**
   * Checks whether the song is favorited, and/or has a rank, and adjusts the clipping
   * for the scenario when the text could be too long
   */
  public function checkClip():Void
  {
    var clipSize:Int = 290;
    var clipType:Int = 0;

    if (ranking.visible)
    {
      favIconBlurred.x = this.x + 370;
      favIcon.x = favIconBlurred.x;
      clipType += 1;
    }
    else
    {
      favIconBlurred.x = favIcon.x = this.x + 405;
    }

    if (favIcon.visible) clipType += 1;

    switch (clipType)
    {
      case 2:
        clipSize = 210;
      case 1:
        clipSize = 245;
    }
    songText.clipWidth = clipSize;
  }

  var evilTrail:FlxTrail;

  public function fadeAnim():Void
  {
    impactThing = new FlxSprite(0, 0);
    impactThing.frames = capsule.frames;
    impactThing.frame = capsule.frame;
    impactThing.updateHitbox();
    // impactThing.x = capsule.x;
    // impactThing.y = capsule.y;
    // picoFade.stamp(this, 0, 0);
    impactThing.alpha = 0;
    //impactThing.zIndex = capsule.zIndex - 3;
    add(impactThing);
    FlxTween.tween(impactThing.scale, {x: 2.5, y: 2.5}, 0.5);
    // FlxTween.tween(impactThing, {alpha: 0}, 0.5);

    evilTrail = new FlxTrail(impactThing, null, 15, 2, 0.01, 0.069);
    evilTrail.blend = BlendMode.ADD;
    //evilTrail.zIndex = capsule.zIndex - 5;
    FlxTween.tween(evilTrail, {alpha: 0}, 0.6,
      {
        ease: FlxEase.quadOut,
        onComplete: function(_) {
          remove(evilTrail);
        }
      });
    add(evilTrail);

    switch (ranking.rank)
    {
      case SHIT:
        evilTrail.color = 0xFF6044FF;
      case GOOD:
        evilTrail.color = 0xFFEF8764;
      case GREAT:
        evilTrail.color = 0xFFEAF6FF;
      case EXCELLENT:
        evilTrail.color = 0xFFFDCB42;
      case PERFECT:
        evilTrail.color = 0xFFFF58B4;
      case PERFECT_GOLD:
        evilTrail.color = 0xFFFFB619;
    }
  }

  public function getTrailColor():FlxColor
  {
    return evilTrail.color;
  }

  function updateScoringRank(newRank:Null<ScoringRank>):Void
  {
    if (sparkleTimer != null) sparkleTimer.cancel();
    sparkle.visible = false;

    this.ranking.rank = newRank;
    this.blurredRanking.rank = newRank;

    if (newRank == PERFECT_GOLD)
    {
      sparkleTimer = new FlxTimer().start(1, sparkleEffect);
      sparkle.visible = true;
    }
  }

  function textAppear():Void //* ANIM SHIT. This is broken!
  {
    songText.scale.x = 1.7;
    songText.scale.y = 0.2;

    new FlxTimer().start(1 / 24, function(_) {
      songText.scale.x = 0.4;
      songText.scale.y = 1.4;
    });

    new FlxTimer().start(2 / 24, function(_) {
      songText.scale.x = songText.scale.y = 1;
    });

    new FlxTimer().start(4 / 24, function(_) { // Attempting fallback in case the previous one fails!
      songText.scale.x = songText.scale.y = 1;
    });
  }

  function setVisibleGrp(value:Bool):Void
  {
    for (spr in grpHide.members)
    {
      spr.visible = value;
    }

    if (value) textAppear();

    updateSelected();
  }

  public function init(?x:Float, ?y:Float, songData:Null<FreeplaySongData>):Void
  {
    if (x != null) this.x = x;
    if (y != null) this.y = y;
    this.songData = songData;

    // Update capsule text.
    songText.text = songData?.songName ?? 'Random';
    // Update capsule character.
    if (songData?.songCharacter != null) pixelIcon.setCharacter(songData.songCharacter);
    updateScoringRank(songData?.scoringRank);
    // Update opacity, offsets, etc.
    updateSelected();

    checkWeek(songData?.levelId);
  }

  var frameInTicker:Float = 0;
  var frameInTypeBeat:Int = 0;

  var frameOutTicker:Float = 0;
  var frameOutTypeBeat:Int = 0;

  var xFrames:Array<Float> = [1.7, 1.8, 0.85, 0.85, 0.97, 0.97, 1];
  var xPosLerpLol:Array<Float> = [0.9, 0.4, 0.16, 0.16, 0.22, 0.22, 0.245]; // NUMBERS ARE JANK CUZ THE SCALING OR WHATEVER
  var xPosOutLerpLol:Array<Float> = [0.245, 0.75, 0.98, 0.98, 1.2]; // NUMBERS ARE JANK CUZ THE SCALING OR WHATEVER

  public var realScaled:Float = 0.8;

  public function initJumpIn(maxTimer:Float, ?force:Bool):Void
  {
    frameInTypeBeat = 0;

    new FlxTimer().start((1 / 24) * maxTimer, function(doShit) {
      doJumpIn = true;
    });

    new FlxTimer().start((0.09 * maxTimer) + 0.85, function(lerpTmr) {
      doLerp = true;
    });

    if (force)
    {
      visible = true;
      capsule.alpha = 1;
      setVisibleGrp(true);
    }
    else
    {
      new FlxTimer().start((xFrames.length / 24) * 2.5, function(_) {
        visible = true;
        capsule.alpha = 1;
        setVisibleGrp(true);
      });
    }
  }

  var grpHide:FlxGroup;

  public function forcePosition():Void
  {
    visible = true;
    capsule.alpha = 1;
    updateSelected();
    doLerp = true;
    doJumpIn = false;
    doJumpOut = false;

    frameInTypeBeat = xFrames.length;
    frameOutTypeBeat = 0;

    capsule.scale.x = xFrames[frameInTypeBeat - 1];
    capsule.scale.y = 1 / xFrames[frameInTypeBeat - 1];
    // x = FlxG.width * xPosLerpLol[Std.int(Math.min(frameInTypeBeat - 1, xPosLerpLol.length - 1))];

    x = targetPos.x;
    y = targetPos.y;

    capsule.scale.x *= realScaled;
    capsule.scale.y *= realScaled;

    setVisibleGrp(true);
  }

  override function update(elapsed:Float):Void
  {
    if (impactThing != null) impactThing.angle = capsule.angle;

    if (doJumpIn)
    {
      frameInTicker += elapsed;

      if (frameInTicker >= 1 / 24 && frameInTypeBeat < xFrames.length)
      {
        frameInTicker = 0;

        capsule.scale.x = xFrames[frameInTypeBeat];
        capsule.scale.y = 1 / xFrames[frameInTypeBeat];
        x = FlxG.width * xPosLerpLol[Std.int(Math.min(frameInTypeBeat, xPosLerpLol.length - 1))];

        capsule.scale.x *= realScaled;
        capsule.scale.y *= realScaled;

        frameInTypeBeat += 1;
      }
    }

    if (doJumpOut)
    {
      frameOutTicker += elapsed;

      if (frameOutTicker >= 1 / 24 && frameOutTypeBeat < xFrames.length)
      {
        frameOutTicker = 0;

        capsule.scale.x = xFrames[frameOutTypeBeat];
        capsule.scale.y = 1 / xFrames[frameOutTypeBeat];
        x = FlxG.width * xPosOutLerpLol[Std.int(Math.min(frameOutTypeBeat, xPosOutLerpLol.length - 1))];

        capsule.scale.x *= realScaled;
        capsule.scale.y *= realScaled;

        frameOutTypeBeat += 1;
      }
    }

    if (doLerp)
    {
      x = MathUtil.coolLerp(x, targetPos.x, 0.3);
      y = MathUtil.coolLerp(y, targetPos.y, 0.4);
    }

    super.update(elapsed);
  }

  public function intendedY(index:Int):Float
  {
    return (index * ((height * realScaled) + 10)) + 120;
  }

  function set_selected(value:Bool):Bool
  {
    // cute one liners, lol!
    selected = value;
    updateSelected();
    return selected;
  }

  /**
   * Play any animations associated with selecting this song.
   */
  public function confirm():Void
  {
    if (songText != null) songText.flickerText();
    if (pixelIcon != null && pixelIcon.visible)
    {
      pixelIcon.animation.play('confirm');
    }
  }

  function updateSelected():Void
  {
    songText.alpha = this.selected ? 1 : 0.6;
    songText.blurredText.visible = this.selected ? true : false;
    capsule.offset.x = this.selected ? 0 : -5;
    capsule.animation.play(this.selected ? "selected" : "unselected");
    ranking.alpha = this.selected ? 1 : 0.7;
    favIcon.alpha = this.selected ? 1 : 0.6;
    favIconBlurred.alpha = this.selected ? 1 : 0;
    ranking.color = this.selected ? 0xFFFFFFFF : 0xFFAAAAAA;

    if (songText.tooLong) songText.resetText();

    if (selected && songText.tooLong) songText.initMove();
  }
}

class FreeplayRank extends FlxSprite
{
  public var rank(default, set):Null<ScoringRank> = null;

  function set_rank(val:Null<ScoringRank>):Null<ScoringRank>
  {
    rank = val;

    if (rank == null || val == null)
    {
      this.visible = false;
    }
    else
    {
      this.visible = true;

      animation.play(val.getFreeplayRankIconAsset(), true, false);

      centerOffsets(false);

      switch (val)
      {
        case SHIT:
        // offset.x -= 1;
        case GOOD:
          // offset.x -= 1;
          offset.y -= 8;
        case GREAT:
          // offset.x -= 1;
          offset.y -= 8;
        case EXCELLENT:
        // offset.y += 5;
        case PERFECT:
        // offset.y += 5;
        case PERFECT_GOLD:
        // offset.y += 5;
        default:
          centerOffsets(false);
          this.visible = false;
      }
      updateHitbox();
    }

    return rank = val;
  }

  public var baseX:Float = 0;
  public var baseY:Float = 0;

  public function new(x:Float, y:Float)
  {
    super(x, y);

    frames = Paths.getSparrowAtlas('freeplay/rankbadges');

    animation.addByPrefix('PERFECT', 'PERFECT rank0', 24, false);
    animation.addByPrefix('EXCELLENT', 'EXCELLENT rank0', 24, false);
    animation.addByPrefix('GOOD', 'GOOD rank0', 24, false);
    animation.addByPrefix('PERFECTSICK', 'PERFECT rank GOLD', 24, false);
    animation.addByPrefix('GREAT', 'GREAT rank0', 24, false);
    animation.addByPrefix('LOSS', 'LOSS rank0', 24, false);

    blend = BlendMode.ADD;

    this.rank = null;

    // setGraphicSize(Std.int(width * 0.9));
    scale.set(0.9, 0.9);
    updateHitbox();
  }
}