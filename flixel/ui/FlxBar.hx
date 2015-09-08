package flixel.ui;

import flash.display.BitmapData;
import flash.geom.Point;
import flash.geom.Rectangle;
import flixel.FlxBaseSprite;
import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.FlxTexture;
import flixel.graphics.frames.FlxFrame;
import flixel.graphics.frames.FlxFramesCollection;
import flixel.graphics.frames.FlxImageFrame;
import flixel.graphics.tile.FlxDrawTilesItem;
import flixel.graphics.views.FlxBarView;
import flixel.system.FlxAssets.FlxGraphicAsset;
import flixel.ui.FlxBar.FlxBarFillDirection;
import flixel.math.FlxAngle;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;
import flixel.util.FlxGradient;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.util.FlxStringUtil;

// TODO: better handling bars with borders (don't take border into account while drawing its front).

/**
 * FlxBar is a quick and easy way to create a graphical bar which can
 * be used as part of your UI/HUD, or positioned next to a sprite. 
 * It could represent a loader, progress or health bar.
 * 
 * @link http://www.photonstorm.com
 * @author Richard Davey / Photon Storm
 */
class FlxBar extends FlxBaseSprite<FlxBarView>
{
	/**
	 * If false, the bar is tracking its parent
	 * (the position is synchronized with the parent's position).
	 */
	public var fixedPosition:Bool = true;
	/**
	 * The positionOffset controls how far offset the FlxBar is from the parent sprite (if at all)
	 */
	public var positionOffset(default, null):FlxPoint;
	/**
	 * If this FlxBar should be killed when its empty
	 */
	public var killOnEmpty:Bool = false;
	/**
	 * The percentage of how full the bar is (a value between 0 and 100)
	 */
	public var percent(get, set):Float;
	/**
	 * The current value - must always be between min and max
	 */
	@:isVar
	public var value(get, set):Float;
	/**
	 * The minimum value the bar can be (can never be >= max)
	 */
	public var min(default, null):Float;
	/**
	 * The maximum value the bar can be (can never be <= min)
	 */
	public var max(default, null):Float;
	/**
	 * How wide is the range of this bar? (max - min)
	 */
	public var range(default, null):Float;
	/**
	 * What 1% of the bar is equal to in terms of value (range / 100)
	 */
	public var pct(default, null):Float;
	/**
	 * This function will be called when value will hit it's minimum
	 */
	public var emptyCallback:Void->Void;
	/**
	 * This function will be called when value will hit it's maximum
	 */
	public var filledCallback:Void->Void;
	/**
	 * Object to track value from/
	 */
	public var parent:Dynamic;
	/**
	 * Property of parent object to track.
	 */
	public var parentVariable:String;
	
	/**
	 * The direction from which the health bar will fill-up. Default is from left to right. Change takes effect immediately.
	 */
	public var fillDirection(get, set):FlxBarFillDirection;	
	
	/**
	 * Create a new FlxBar Object
	 * 
	 * @param	x			The x coordinate location of the resulting bar (in world pixels)
	 * @param	y			The y coordinate location of the resulting bar (in world pixels)
	 * @param	direction 	The fill direction, LEFT_TO_RIGHT by default
	 * @param	width		The width of the bar in pixels
	 * @param	height		The height of the bar in pixels
	 * @param	parentRef	A reference to an object in your game that you wish the bar to track
	 * @param	variable	The variable of the object that is used to determine the bar position. For example if the parent was an FlxSprite this could be "health" to track the health value
	 * @param	min			The minimum value. I.e. for a progress bar this would be zero (nothing loaded yet)
	 * @param	max			The maximum value the bar can reach. I.e. for a progress bar this would typically be 100.
	 * @param	showBorder	Include a 1px border around the bar? (if true it adds +2 to width and height to accommodate it)
	 */
	public function new(x:Float = 0, y:Float = 0, ?direction:FlxBarFillDirection, width:Int = 100, height:Int = 10, ?parentRef:Dynamic, variable:String = "", min:Float = 0, max:Float = 100, showBorder:Bool = false)
	{
		super(x, y);
		
		graphic = new FlxBarView(this, direction, width, height, showBorder);
		
		if (parentRef != null)
		{
			parent = parentRef;
			parentVariable = variable;
		}
		
		setRange(min, max);
	}
	
	override public function destroy():Void 
	{
		positionOffset = FlxDestroyUtil.put(positionOffset);
		
		parent = null;
		positionOffset = null;
		emptyCallback = null;
		filledCallback = null;
		
		super.destroy();
	}
	
	/**
	 * Track the parent FlxSprites x/y coordinates. For example if you wanted your sprite to have a floating health-bar above their head.
	 * If your health bar is 10px tall and you wanted it to appear above your sprite, then set offsetY to be -10
	 * If you wanted it to appear below your sprite, and your sprite was 32px tall, then set offsetY to be 32. Same applies to offsetX.
	 * 
	 * @param	offsetX		The offset on X in relation to the origin x/y of the parent
	 * @param	offsetY		The offset on Y in relation to the origin x/y of the parent
	 * @see		stopTrackingParent
	 */
	public function trackParent(offsetX:Int, offsetY:Int):Void
	{
		fixedPosition = false;
		positionOffset = FlxPoint.get(offsetX, offsetY);
		
		if (Reflect.hasField(parent, "scrollFactor"))
		{
			scrollFactor.x = parent.scrollFactor.x;
			scrollFactor.y = parent.scrollFactor.y;
		}
	}
	
	/**
	 * Sets a parent for this FlxBar. Instantly replaces any previously set parent and refreshes the bar.
	 * 
	 * @param	parentRef	A reference to an object in your game that you wish the bar to track
	 * @param	variable	The variable of the object that is used to determine the bar position. For example if the parent was an FlxSprite this could be "health" to track the health value
	 * @param	track		If you wish the FlxBar to track the x/y coordinates of parent set to true (default false)
	 * @param	offsetX		The offset on X in relation to the origin x/y of the parent
	 * @param	offsetY		The offset on Y in relation to the origin x/y of the parent
	 */
	public function setParent(parentRef:Dynamic, variable:String, track:Bool = false, offsetX:Int = 0, offsetY:Int = 0):Void
	{
		parent = parentRef;
		parentVariable = variable;
		
		if (track)
			trackParent(offsetX, offsetY);
		
		updateValueFromParent();
	}
	
	/**
	 * Tells the health bar to stop following the parent sprite. The given posX and posY values are where it will remain on-screen.
	 * 
	 * @param	posX	X coordinate of the health bar now it's no longer tracking the parent sprite
	 * @param	posY	Y coordinate of the health bar now it's no longer tracking the parent sprite
	 */
	public function stopTrackingParent(posX:Int, posY:Int):Void
	{
		fixedPosition = true;
		x = posX;
		y = posY;
	}
	
	/**
	 * Sets callbacks which will be triggered when the value of this FlxBar reaches min or max.
	 * Functions will only be called once and not again until the value changes.
	 * Optionally the FlxBar can be killed if it reaches min, but if will fire the empty callback first (if set)
	 * 
	 * @param	onEmpty			The function that is called if the value of this FlxBar reaches min
	 * @param	onFilled		The function that is called if the value of this FlxBar reaches max
	 * @param	killOnEmpty		If set it will call FlxBar.kill() if the value reaches min
	 */
	public function setCallbacks(onEmpty:Void->Void, onFilled:Void->Void, killOnEmpty:Bool = false):Void
	{
		emptyCallback = (onEmpty != null) ? onEmpty: emptyCallback;
		filledCallback = (onFilled != null) ? onFilled : filledCallback;
		this.killOnEmpty = killOnEmpty;
	}
	
	/**
	 * Set the minimum and maximum allowed values for the FlxBar
	 * 
	 * @param	min			The minimum value. I.e. for a progress bar this would be zero (nothing loaded yet)
	 * @param	max			The maximum value the bar can reach. I.e. for a progress bar this would typically be 100.
	 */
	public function setRange(min:Float, max:Float):Void
	{
		if (max <= min)
		{
			throw "FlxBar: max cannot be less than or equal to min";
			return;
		}
		
		this.min = min;
		this.max = max;
		this.range = max - min;
		this.pct = range / 100;
		
		graphic.fillDirection = fillDirection;
		
		if (!Math.isNaN(value))
		{
			value = Math.max(min, Math.min(value, max));
		}
		else
		{
			value = min;
		}
	}
	
	/**
	 * Creates a solid-colour filled health bar in the given colours, with optional 1px thick border.
	 * All colour values are in 0xAARRGGBB format, so if you want a slightly transparent health bar give it lower AA values.
	 * 
	 * @param	empty		The color of the bar when empty in 0xAARRGGBB format (the background colour)
	 * @param	fill		The color of the bar when full in 0xAARRGGBB format (the foreground colour)
	 * @param	showBorder	Should the bar be outlined with a 1px solid border?
	 * @param	border		The border colour in 0xAARRGGBB format
	 * @return	This FlxBar object with generated images for front and backround.
	 */
	public function createFilledBar(empty:Int, fill:Int, showBorder:Bool = false, border:Int = 0xffffffff):FlxBar
	{
		graphic.createFilledBar(empty, fill, showBorder);
		return this;
	}
	
	/**
	 * Creates a solid-colour filled background for health bar in the given colour, with optional 1px thick border.
	 * 
	 * @param	empty			The color of the bar when empty in 0xAARRGGBB format (the background colour)
	 * @param	showBorder		Should the bar be outlined with a 1px solid border?
	 * @param	border			The border colour in 0xAARRGGBB format
	 * @return	This FlxBar object with generated image for rendering health bar backround.
	 */
	public function createColoredEmptyBar(empty:Int, showBorder:Bool = false, border:Int = 0xffffffff):FlxBar
	{
		graphic.createColoredEmptyBar(empty, showBorder, border);
		return this;
	}
	
	/**
	 * Creates a solid-colour filled foreground for health bar in the given colour, with optional 1px thick border.
	 * @param	fill		The color of the bar when full in 0xAARRGGBB format (the foreground colour)
	 * @param	showBorder	Should the bar be outlined with a 1px solid border?
	 * @param	border		The border colour in 0xAARRGGBB format
	 * @return	This FlxBar object with generated image for rendering actual values.
	 */
	public function createColoredFilledBar(fill:Int, showBorder:Bool = false, border:Int = 0xffffffff):FlxBar
	{
		createColoredFilledBar(fill, showBorder, border);
		return this;
	}
	
	/**
	 * Creates a gradient filled health bar using the given colour ranges, with optional 1px thick border.
	 * All colour values are in 0xAARRGGBB format, so if you want a slightly transparent health bar give it lower AA values.
	 * 
	 * @param	empty		Array of colour values used to create the gradient of the health bar when empty, each colour must be in 0xAARRGGBB format (the background colour)
	 * @param	fill		Array of colour values used to create the gradient of the health bar when full, each colour must be in 0xAARRGGBB format (the foreground colour)
	 * @param	chunkSize	If you want a more old-skool looking chunky gradient, increase this value!
	 * @param	rotation	Angle of the gradient in degrees. 90 = top to bottom, 180 = left to right. Any angle is valid
	 * @param	showBorder	Should the bar be outlined with a 1px solid border?
	 * @param	border		The border colour in 0xAARRGGBB format
	 * @return 	This FlxBar object with generated images for front and backround.
	 */
	public function createGradientBar(empty:Array<Int>, fill:Array<Int>, chunkSize:Int = 1, rotation:Int = 180, showBorder:Bool = false, border:Int = 0xffffffff):FlxBar
	{
		graphic.createGradientBar(empty, fill, chunkSize, rotation, showBorder, border);
		return this;
	}
	
	/**
	 * Creates a gradient filled background for health bar using the given colour range, with optional 1px thick border.
	 * 
	 * @param	empty			Array of colour values used to create the gradient of the health bar when empty, each colour must be in 0xAARRGGBB format (the background colour)
	 * @param	chunkSize		If you want a more old-skool looking chunky gradient, increase this value!
	 * @param	rotation		Angle of the gradient in degrees. 90 = top to bottom, 180 = left to right. Any angle is valid
	 * @param	showBorder		Should the bar be outlined with a 1px solid border?
	 * @param	border			The border colour in 0xAARRGGBB format
	 * @return 	This FlxBar object with generated image for backround rendering.
	 */
	public function createGradientEmptyBar(empty:Array<Int>, chunkSize:Int = 1, rotation:Int = 180, showBorder:Bool = false, border:Int = 0xffffffff):FlxBar
	{
		graphic.createGradientEmptyBar(empty, chunkSize, rotation, showBorder, border);
		return this;
	}
	
	/**
	 * Creates a gradient filled foreground for health bar using the given colour range, with optional 1px thick border.
	 * 
	 * @param	fill		Array of colour values used to create the gradient of the health bar when full, each colour must be in 0xAARRGGBB format (the foreground colour)
	 * @param	chunkSize	If you want a more old-skool looking chunky gradient, increase this value!
	 * @param	rotation	Angle of the gradient in degrees. 90 = top to bottom, 180 = left to right. Any angle is valid
	 * @param	showBorder	Should the bar be outlined with a 1px solid border?
	 * @param	border		The border colour in 0xAARRGGBB format
	 * @return 	This FlxBar object with generated image for rendering actual values.
	 */
	public function createGradientFilledBar(fill:Array<Int>, chunkSize:Int = 1, rotation:Int = 180, showBorder:Bool = false, border:Int = 0xffffffff):FlxBar
	{
		graphic.createGradientFilledBar(fill, chunkSize, rotation, showBorder, border);
		return this;
	}
	
	/**
	 * Creates a health bar filled using the given bitmap images.
	 * You can provide "empty" (background) and "fill" (foreground) images. either one or both images (empty / fill), and use the optional empty/fill colour values 
	 * All colour values are in 0xAARRGGBB format, so if you want a slightly transparent health bar give it lower AA values.
	 * NOTE: This method doesn't check if the empty image doesn't have the same size as fill image.
	 * 
	 * @param	empty				Bitmap image used as the background (empty part) of the health bar, if null the emptyBackground colour is used
	 * @param	fill				Bitmap image used as the foreground (filled part) of the health bar, if null the fillBackground colour is used
	 * @param	emptyBackground		If no background (empty) image is given, use this colour value instead. 0xAARRGGBB format
	 * @param	fillBackground		If no foreground (fill) image is given, use this colour value instead. 0xAARRGGBB format
	 * @return	This FlxBar object with generated images for front and backround.
	 */
	public function createImageBar(?empty:FlxGraphicAsset, ?fill:FlxGraphicAsset, emptyBackground:Int = 0xff000000, fillBackground:Int = 0xff00ff00):FlxBar
	{
		graphic.createImageBar(empty, fill, emptyBackground, fillBackground);
		return this;
	}
	
	/**
	 * Loads given bitmap image for health bar background.
	 * 
	 * @param	empty				Bitmap image used as the background (empty part) of the health bar, if null the emptyBackground colour is used
	 * @param	emptyBackground		If no background (empty) image is given, use this colour value instead. 0xAARRGGBB format
	 * @return	This FlxBar object with generated image for backround rendering.
	 */
	public function createImageEmptyBar(?empty:FlxGraphicAsset, emptyBackground:Int = 0xff000000):FlxBar
	{
		graphic.createImageEmptyBar(empty, emptyBackground);
		return this;
	}
	
	/**
	 * Loads given bitmap image for health bar foreground.
	 * 
	 * @param	fill				Bitmap image used as the foreground (filled part) of the health bar, if null the fillBackground colour is used
	 * @param	fillBackground		If no foreground (fill) image is given, use this colour value instead. 0xAARRGGBB format
	 * @return	This FlxBar object with generated image for rendering actual values.
	 */
	public function createImageFilledBar(?fill:FlxGraphicAsset, fillBackground:Int = 0xff00ff00):FlxBar
	{
		graphic.createImageFilledBar(fill, fillBackground);
		return this;
	}
	
	private function get_fillDirection():FlxBarFillDirection
	{
		return graphic.fillDirection;
	}
	
	private function set_fillDirection(direction:FlxBarFillDirection):FlxBarFillDirection
	{
		return graphic.fillDirection = direction;
	}
	
	private function updateValueFromParent():Void
	{
		value = Reflect.getProperty(parent, parentVariable);
	}
	
	/**
	 * Updates health bar view according its current value.
	 * Called when the health bar detects a change in the health of the parent.
	 */
	public inline function updateBar():Void
	{
		graphic.updateBar();
	}
	
	override public function update(elapsed:Float):Void
	{
		if (parent != null)
		{
			if (Reflect.getProperty(parent, parentVariable) != value)
			{
				updateValueFromParent();
			}
			
			if (fixedPosition == false)
			{
				x = parent.x + positionOffset.x;
				y = parent.y + positionOffset.y;
			}
		}
		
		super.update(elapsed);
	}
	
	override public function toString():String
	{
		return FlxStringUtil.getDebugString([ 
			LabelValuePair.weak("min", min),
			LabelValuePair.weak("max", max),
			LabelValuePair.weak("range", range),
			LabelValuePair.weak("%", pct),
			LabelValuePair.weak("value", value)]);
	}
	
	private function get_percent():Float
	{
		#if neko
		if (value == null) 
			value = min;
		#end

		if (value > max)
			return 100;
		
		return Math.floor((value / range) * 100);
	}

	private function set_percent(newPct:Float):Float
	{
		if (newPct >= 0 && newPct <= 100)
			value = pct * newPct;
		
		return newPct;
	}
	
	private function set_value(newValue:Float):Float
	{
		value = Math.max(min, Math.min(newValue, max));
		
		if (value == min && emptyCallback != null)
			emptyCallback();
		
		if (value == max && filledCallback != null)
			filledCallback();
		
		if (value == min && killOnEmpty)
			kill();
		
		updateBar();
		return newValue;
	}
	
	private function get_value():Float
	{
		return value;
	}
}

enum FlxBarFillDirection
{
	LEFT_TO_RIGHT;
	RIGHT_TO_LEFT;
	TOP_TO_BOTTOM;
	BOTTOM_TO_TOP;
	HORIZONTAL_INSIDE_OUT;
	HORIZONTAL_OUTSIDE_IN;
	VERTICAL_INSIDE_OUT;
	VERTICAL_OUTSIDE_IN;
}