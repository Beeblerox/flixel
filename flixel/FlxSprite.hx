package flixel;

import flash.display.BitmapData;
import flash.display.BlendMode;
import flash.geom.ColorTransform;
import flash.geom.Point;
import flash.geom.Rectangle;
import flixel.animation.FlxAnimationController;
import flixel.FlxBasic;
import flixel.FlxG;
import flixel.graphics.FlxTexture;
import flixel.graphics.frames.FlxFrame;
import flixel.graphics.frames.FlxFramesCollection;
import flixel.graphics.frames.FlxTileFrames;
import flixel.graphics.views.FlxAnimated;
import flixel.math.FlxAngle;
import flixel.math.FlxMath;
import flixel.math.FlxMatrix;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.system.FlxAssets.FlxGraphicAsset;
import flixel.util.FlxBitmapDataUtil;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;

@:keep @:bitmap("assets/images/logo/default.png")
private class GraphicDefault extends BitmapData {}

// TODO: add updateSizeFromFrame bool which will tell sprite whether to update it's size to frame's size (when frame setter is called) or not (useful for sprites with adjusted hitbox)
// And don't forget about sprites with clipped frames: what i should do with their size in this case?

// TODO: add option to "center origin" or create special subclass for it

/**
 * The main "game object" class, the sprite is a FlxObject
 * with a bunch of graphics options and abilities, like animation and stamping.
 *
 * Load an image onto a sprite using the loadGraphic*() functions, 
 * or create a base monochromatic rectangle using makeGraphic().
 * The image BitmapData is stored in the pixels field.
 */
class FlxSprite extends FlxBaseSprite
{
	public var animation(get, null):FlxAnimationController;
	
	private function get_animation():FlxAnimationController
	{
		return spriteGraphic.animation;
	}
	
	/**
	 * The actual Flash BitmapData object representing the current display state of the sprite.
	 * WARNING: can be null in FLX_RENDER_TILE mode unless you call getFlxFrameBitmapData() beforehand.
	 */
	public var framePixels(get, set):BitmapData;
	
	private function get_framePixels():BitmapData
	{
		return spriteGraphic.framePixels;
	}
	
	private function set_framePixels(Value:BitmapData):BitmapData
	{
		return spriteGraphic.framePixels = Value;
	}
	
	/**
	 * Set pixels to any BitmapData object.
	 * Automatically adjust graphic size and render helpers.
	 */
	public var pixels(get, set):BitmapData;
	/**
	 * Link to current FlxFrame from loaded atlas
	 */
	public var frame(default, set):FlxFrame;
	
	/**
	 * Set alpha to a number between 0 and 1 to change the opacity of the sprite.
	 */
	public var alpha(default, set):Float = 1.0;
	/**
	 * Set facing using FlxObject.LEFT, RIGHT, UP, and DOWN to take advantage 
	 * of flipped sprites and/or just track player orientation more easily.
	 */
	public var facing(default, set):Int = FlxObject.RIGHT;
	/**
	 * Whether this sprite is flipped on the X axis
	 */
	public var flipX(default, set):Bool = false;
	/**
	 * Whether this sprite is flipped on the Y axis
	 */
	public var flipY(default, set):Bool = false;
	 
	/**
	 * WARNING: The origin of the sprite will default to its center. If you change this, 
	 * the visuals and the collisions will likely be pretty out-of-sync if you do any rotation.
	 */
	public var origin(default, null):FlxPoint;
	/**
	 * Controls the position of the sprite's hitbox. Likely needs to be adjusted after
	 * changing a sprite's width, height or scale.
	 */
	public var offset(default, null):FlxPoint;
	/**
	 * Change the size of your sprite's graphic. NOTE: The hitbox is not automatically adjusted, use updateHitbox for that
	 * (or setGraphicSize(). WARNING: When using blitting (flash), scaling sprites decreases rendering performance by a factor of about x10!
	 */
	public var scale(default, null):FlxPoint;
	/**
	 * Blending modes, just like Photoshop or whatever, e.g. "multiply", "screen", etc.
	 */
	public var blend(default, set):BlendMode;

	/**
	 * Tints the whole sprite to a color (0xRRGGBB format) - similar to OpenGL vertex colors. You can use
	 * 0xAARRGGBB colors, but the alpha value will simply be ignored. To change the opacity use alpha. 
	 */
	public var color(default, set):FlxColor = 0xffffff;
	
	public var colorTransform(default, null):ColorTransform;
	
	/**
	 * Whether or not to use a colorTransform set via setColorTransform.
	 */
	public var useColorTransform(default, null):Bool = false;
	
	/**
	 * Clipping rectangle for this sprite.
	 * Changing it's properties doesn't change graphic of the sprite, so you should reapply clipping rect on sprite again.
	 * Set clipRect to null to discard graphic frame clipping 
	 */
	public var clipRect(get, set):FlxRect;
	
	public var spriteGraphic(default, null):FlxAnimated;
	
	/**
	 * Creates a FlxSprite at a specified position with a specified one-frame graphic. 
	 * If none is provided, a 16x16 image of the HaxeFlixel logo is used.
	 * 
	 * @param	X				The initial X position of the sprite.
	 * @param	Y				The initial Y position of the sprite.
	 * @param	SimpleGraphic	The graphic you want to display (OPTIONAL - for simple stuff only, do NOT use for animated images!).
	 */
	public function new(?X:Float = 0, ?Y:Float = 0, ?SimpleGraphic:FlxGraphicAsset)
	{
		super(X, Y, spriteGraphic = new FlxAnimated(this, SimpleGraphic));
	}
	
	override public function destroy():Void 
	{
		super.destroy();
		spriteGraphic = null;
	}
	
	public function clone():FlxSprite
	{
		return (new FlxSprite()).loadGraphicFromSprite(this);
	}
	
	/**
	 * Load graphic from another FlxSprite and copy its tileSheet data. 
	 * This method can useful for non-flash targets (and is used by the FlxTrail effect).
	 * 
	 * @param	Sprite	The FlxSprite from which you want to load graphic data
	 * @return	This FlxSprite instance (nice for chaining stuff together, if you're into that).
	 */
	public function loadGraphicFromSprite(Sprite:FlxSprite):FlxSprite
	{
		// TODO: move this into graphic
		/*
		frames = Sprite.frames;
		bakedRotationAngle = Sprite.bakedRotationAngle;
		if (bakedRotationAngle > 0)
		{
			width = Sprite.width;
			height = Sprite.height;
			centerOffsets();
		}
		antialiasing = Sprite.antialiasing;
		animation.copyFrom(Sprite.animation);
		graphicLoaded();
		clipRect = Sprite.clipRect;
		*/
		return this;
	}
	
	/**
	 * Load an image from an embedded graphic file.
	 *
 	 * HaxeFlixel's graphic caching system keeps track of loaded image data. 
 	 * When you load an identical copy of a previously used image, by default
 	 * HaxeFlixel copies the previous reference onto the pixels field instead
 	 * of creating another copy of the image data, to save memory.
	 * 
	 * @param	Graphic		The image you want to use.
	 * @param	Animated	Whether the Graphic parameter is a single sprite or a row of sprites.
	 * @param	Width		Optional, specify the width of your sprite (helps FlxSprite figure out what to do with non-square sprites or sprite sheets).
	 * @param	Height		Optional, specify the height of your sprite (helps FlxSprite figure out what to do with non-square sprites or sprite sheets).
	 * @param	Unique		Optional, whether the graphic should be a unique instance in the graphics cache.  Default is false.
	 *				Set this to true if you want to modify the pixels field without changing the pixels of other sprites with the same BitmapData.
	 * @param	Key		Optional, set this parameter if you're loading BitmapData.
	 * @return	This FlxSprite instance (nice for chaining stuff together, if you're into that).
	 */
	public function loadGraphic(Graphic:FlxGraphicAsset, Animated:Bool = false, Width:Int = 0, Height:Int = 0, Unique:Bool = false, ?Key:String):FlxSprite
	{
		graphic.loadGraphic(Graphic, Animated, Width, Height, Unique, Key);
		return this;
	}
	
	/**
	 * Create a pre-rotated sprite sheet from a simple sprite.
	 * This can make a huge difference in graphical performance!
	 * 
	 * @param	Graphic			The image you want to rotate and stamp.
	 * @param	Rotations		The number of rotation frames the final sprite should have.  For small sprites this can be quite a large number (360 even) without any problems.
	 * @param	Frame			If the Graphic has a single row of square animation frames on it, you can specify which of the frames you want to use here.  Default is -1, or "use whole graphic."
	 * @param	AntiAliasing	Whether to use high quality rotations when creating the graphic.  Default is false.
	 * @param	AutoBuffer		Whether to automatically increase the image size to accomodate rotated corners.  Default is false.  Will create frames that are 150% larger on each axis than the original frame or graphic.
	 * @param	Key				Optional, set this parameter if you're loading BitmapData.
	 * @return	This FlxSprite instance (nice for chaining stuff together, if you're into that).
	 */
	public function loadRotatedGraphic(Graphic:FlxGraphicAsset, Rotations:Int = 16, Frame:Int = -1, AntiAliasing:Bool = false, AutoBuffer:Bool = false, ?Key:String):FlxSprite
	{
		return null;
	}
	
	/**
	 * Helper method which makes it possible to use FlxFrames as graphic source for sprite's loadRotatedGraphic() method 
	 * (since it accepts only FlxTexture, BitmapData and String types).
	 * 
	 * @param	frame			Frame to load into this sprite.
	 * @param	rotations		The number of rotation frames the final sprite should have. For small sprites this can be quite a large number (360 even) without any problems.
	 * @param	antiAliasing	Whether to use high quality rotations when creating the graphic. Default is false.
	 * @param	autoBuffer		Whether to automatically increase the image size to accomodate rotated corners.  Default is false.  Will create frames that are 150% larger on each axis than the original frame or graphic.
	 * @return	this FlxSprite with loaded rotated graphic in it.
	 */
	public function loadRotatedFrame(Frame:FlxFrame, Rotations:Int = 16, AntiAliasing:Bool = false, AutoBuffer:Bool = false):FlxSprite
	{
		return null;
	}
	
	/**
	 * This function creates a flat colored rectangular image dynamically.
	 *
 	 * HaxeFlixel's graphic caching system keeps track of loaded image data. 
 	 * When you make an identical copy of a previously used image, by default
 	 * HaxeFlixel copies the previous reference onto the pixels field instead
 	 * of creating another copy of the image data, to save memory.
 	 * 
	 * @param	Width		The width of the sprite you want to generate.
	 * @param	Height		The height of the sprite you want to generate.
	 * @param	Color		Specifies the color of the generated block (ARGB format).
	 * @param	Unique		Whether the graphic should be a unique instance in the graphics cache.  Default is false.
	 *				Set this to true if you want to modify the pixels field without changing the pixels of other sprites with the same BitmapData.
	 * @param	Key		Optional parameter - specify a string key to identify this graphic in the cache.  Trumps Unique flag.
	 * @return	This FlxSprite instance (nice for chaining stuff together, if you're into that).
	 */
	public function makeGraphic(Width:Int, Height:Int, Color:FlxColor = FlxColor.WHITE, Unique:Bool = false, ?Key:String):FlxSprite
	{
		graphic.makeGraphic(Width, Height, Color, Unique, Key);
		return this;
	}
	
	/**
	 * Helper function to set the graphic's dimensions by using scale, allowing you to keep the current aspect ratio
	 * should one of the Integers be <= 0. It might make sense to call updateHitbox() afterwards!
	 * 
	 * @param   Width    How wide the graphic should be. If <= 0, and a Height is set, the aspect ratio will be kept.
	 * @param   Height   How high the graphic should be. If <= 0, and a Width is set, the aspect ratio will be kept.
	 */
	public function setGraphicSize(Width:Int = 0, Height:Int = 0):Void
	{
		spriteGraphic.setGraphicSize(Width, Height);
	}
	
	/**
	 * Called by game loop, updates then blits or renders current frame of animation to the screen
	 */
	override public function draw():Void
	{
		graphic.draw();
		
		/*
		for (camera in cameras)
		{
			if (!camera.visible || !camera.exists || !isOnScreen(camera))
			{
				continue;
			}
			
			#if !FLX_NO_DEBUG
			FlxBasic.visibleCount++;
			#end
		}
		*/
		
		#if !FLX_NO_DEBUG
		if (FlxG.debugger.drawDebug)
		{
			drawDebug();
		}
		#end
	}
	
	/**
	 * Stamps / draws another FlxSprite onto this FlxSprite. 
	 * This function is NOT intended to replace draw()!
	 * 
	 * @param	Brush	The sprite you want to use as a brush or stamp or pen or whatever.
	 * @param	X		The X coordinate of the brush's top left corner on this sprite.
	 * @param	Y		They Y coordinate of the brush's top left corner on this sprite.
	 */
	public function stamp(Brush:FlxSprite, X:Int = 0, Y:Int = 0):Void
	{
		if (Brush.graphic != null)
			spriteGraphic.stamp(Brush.spriteGraphic, X, Y);
	}
	
	/**
	 * Request (or force) that the sprite update the frame before rendering.
	 * Useful if you are doing procedural generation or other weirdness!
	 * 
	 * @param	Force	Force the frame to redraw, even if its not flagged as necessary.
	 */
	public function drawFrame(Force:Bool = false):Void
	{
		spriteGraphic.drawFrame(Force);
	}
	
	/**
	 * Helper function that adjusts the offset automatically to center the bounding box within the graphic.
	 * 
	 * @param	AdjustPosition		Adjusts the actual X and Y position just once to match the offset change. Default is false.
	 */
	public function centerOffsets(AdjustPosition:Bool = false):Void
	{
		spriteGraphic.centerOffsets(AdjustPosition);
	}

	/**
	 * Sets the sprite's origin to its center - useful after adjusting 
	 * scale to make sure rotations work as expected.
	 */
	public inline function centerOrigin():Void
	{
		spriteGraphic.centerOrigin();
	}
	
	/**
	 * Set sprite's color transformation with control over color offsets.
	 * Offsets only work with FLX_RENDER_BLIT.
	 * 
	 * @param	redMultiplier		The value for the red multiplier, in the range from 0 to 1. 
	 * @param	greenMultiplier		The value for the green multiplier, in the range from 0 to 1. 
	 * @param	blueMultiplier		The value for the blue multiplier, in the range from 0 to 1. 
	 * @param	alphaMultiplier		The value for the alpha transparency multiplier, in the range from 0 to 1. 
	 * @param	redOffset			The offset value for the red color channel, in the range from -255 to 255.
	 * @param	greenOffset			The offset value for the green color channel, in the range from -255 to 255. 
	 * @param	blueOffset			The offset for the blue color channel value, in the range from -255 to 255. 
	 * @param	alphaOffset			The offset for alpha transparency channel value, in the range from -255 to 255. 
	 */
	public function setColorTransform(redMultiplier:Float = 1.0, greenMultiplier:Float = 1.0, blueMultiplier:Float = 1.0,
		alphaMultiplier:Float = 1.0, redOffset:Float = 0, greenOffset:Float = 0, blueOffset:Float = 0, alphaOffset:Float = 0):Void
	{
		spriteGraphic.setColorTransform(redMultiplier, greenMultiplier, blueMultiplier, alphaMultiplier, redOffset, greenOffset, blueOffset, alphaOffset);
	}
	
	/**
	 * Retrieves BitmapData of current FlxFrame. Updates framePixels.
	 */
	public function getFlxFrameBitmapData():BitmapData
	{
		return spriteGraphic.getFlxFrameBitmapData();
	}
	
	/**
	 * Returns the result of isSimpleRenderBlit() if FLX_RENDER_BLIT is 
	 * defined or false if FLX_RENDER_TILE is defined.
	 */
	public function isSimpleRender(?camera:FlxCamera):Bool
	{ 
		return graphic.isSimpleRender(camera);
	}
	
	/**
	 * Determines the function used for rendering in blitting: copyPixels() for simple sprites, draw() for complex ones. 
	 * Sprites are considered simple when they have an angle of 0, a scale of 1, don't use blend and pixelPerfectRender is true.
	 * 
	 * @param	camera	If a camera is passed its pixelPerfectRender flag is taken into account
	 */
	public function isSimpleRenderBlit(?camera:FlxCamera):Bool
	{
		return graphic.isSimpleRenderBlit(camera);
	}
	
	/**
	 * Set how a sprite flips when facing in a particular direction.
	 * 
	 * @param	Direction Use constants from FlxObject: LEFT, RIGHT, UP, and DOWN.
	 * 			These may be combined with the bitwise OR operator.
	 * 			E.g. To make a sprite flip horizontally when it is facing both UP and LEFT,
	 * 			use setFacingFlip(FlxObject.LEFT | FlxObject.UP, true, false);
	 * @param	FlipX Whether to flip the sprite on the X axis
	 * @param	FlipY Whether to flip the sprite on the Y axis
	 */
	public inline function setFacingFlip(Direction:Int, FlipX:Bool, FlipY:Bool):Void
	{
		spriteGraphic.setFacingFlip(Direction, FlipX, FlipY);
	}
	
	/**
	 * Sets frames and allows you to save animations in sprite's animation controller
	 * 
	 * @param	Frames				Frames collection to set for this sprite
	 * @param	saveAnimations		Whether to save animations in animation controller or not
	 * @return	This sprite with loaded frames
	 */
	public function setFrames(Frames:FlxFramesCollection, saveAnimations:Bool = true):FlxSprite
	{
		spriteGraphic.setFrames(Frames, saveAnimations);
		return this;
	}
	
	private function get_pixels():BitmapData
	{
		return graphic.pixels;
	}
	
	private function set_pixels(Pixels:BitmapData):BitmapData
	{
		return graphic.pixels = Pixels;
	}
	
	private function set_frame(Value:FlxFrame):FlxFrame
	{
		return graphic.frame = Value;
	}
	
	private function set_facing(Direction:Int):Int
	{		
		return spriteGraphic.facing = Direction;
	}
	
	private function set_alpha(Alpha:Float):Float
	{
		return spriteGraphic.alpha = Alpha;
	}
	
	private function set_color(Color:FlxColor):Int
	{
		return spriteGraphic.color = Color;
	}
	
	override private function set_angle(Value:Float):Float
	{
		angle = Value;
		return spriteGraphic.angle = angle;
	}
	
	private function set_blend(Value:BlendMode):BlendMode 
	{
		return spriteGraphic.blend = Value;
	}
	
	private function get_clipRect():FlxRect
	{
		return spriteGraphic.clipRect;
	}
	
	private function set_clipRect(rect:FlxRect):FlxRect
	{
		return spriteGraphic.clipRect = rect;
	}
	
	private function set_flipX(Value:Bool):Bool
	{
		return spriteGraphic.flipX = Value;
	}
	
	private function set_flipY(Value:Bool):Bool
	{
		return spriteGraphic.flipY = Value;
	}
	
	private function set_antialiasing(value:Bool):Bool
	{
		return graphic.antialiasing = value;
	}
}

interface IFlxSprite extends IFlxBasic 
{
	public var x(default, set):Float;
	public var y(default, set):Float;
	public var alpha(default, set):Float;
	public var angle(default, set):Float;
	public var facing(default, set):Int;
	public var moves(default, set):Bool;
	public var immovable(default, set):Bool;
	
	public var offset(default, null):FlxPoint;
	public var origin(default, null):FlxPoint;
	public var scale(default, null):FlxPoint;
	public var velocity(default, null):FlxPoint;
	public var maxVelocity(default, null):FlxPoint;
	public var acceleration(default, null):FlxPoint;
	public var drag(default, null):FlxPoint;
	public var scrollFactor(get, null):FlxPoint;

	public function reset(X:Float, Y:Float):Void;
	public function setPosition(X:Float = 0, Y:Float = 0):Void;
}
