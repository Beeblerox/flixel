package flixel.tile;

import flash.display.BitmapData;
import flash.geom.Matrix;
import flash.geom.Point;
import flash.geom.Rectangle;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil.IFlxDestroyable;
import openfl.display.BlendMode;
import openfl.geom.ColorTransform;

/**
 * A helper object to keep tilemap drawing performance decent across the new multi-camera system.
 * Pretty much don't even have to think about this class unless you are doing some crazy hacking.
 */
class FlxTilemapBuffer implements IFlxDestroyable
{
	/**
	 * The current X position of the buffer.
	 */
	public var x:Float = 0;
	/**
	 * The current Y position of the buffer.
	 */
	public var y:Float = 0;
	/**
	 * The width of the buffer (usually just a few tiles wider than the camera).
	 */
	public var width:Float = 0;
	/**
	 * The height of the buffer (usually just a few tiles taller than the camera).
	 */
	public var height:Float = 0;
	/**
	 * Whether the buffer needs to be redrawn.
	 */
	public var dirty:Bool = false;
	/**
	 * How many rows of tiles fit in this buffer.
	 */
	public var rows:Int = 0;
	/**
	 * How many columns of tiles fit in this buffer.
	 */
	public var columns:Int = 0;
	/**
	 * Whether or not the coordinates should be rounded during draw(), true by default (recommended for pixel art). 
	 * Only affects tilesheet rendering and rendering using BitmapData.draw() in blitting.
	 * (copyPixels() only renders on whole pixels by nature). Causes draw() to be used if false, which is more expensive.
	 */
	public var pixelPerfectRender:Null<Bool>;
	
	/**
	 * The actual buffer BitmapData. (Only used if FlxG.renderBlit == true)
	 */ 
	public var pixels(default, null):BitmapData;
	
	public var blend:BlendMode;
	
	public var regen:Bool = false;
	
	private var _flashRect:Rectangle;
	private var _matrix:Matrix;
	
	/**
	 * Camera object this buffer will be rendered to
	 */
	@:allow(flixel.tile.FlxTilemap)
	private var _camera:FlxCamera;
	
	/**
	 * Instantiates a new camera-specific buffer for storing the visual tilemap data.
	 * 
	 * @param   TileWidth       The width of the tiles in this tilemap.
	 * @param   TileHeight      The height of the tiles in this tilemap.
	 * @param   WidthInTiles    How many tiles wide the tilemap is.
	 * @param   HeightInTiles   How many tiles tall the tilemap is.
	 * @param   Camera          Which camera this buffer relates to.
	 */
	public function new(TileWidth:Int, TileHeight:Int, WidthInTiles:Int, HeightInTiles:Int,
		?Camera:FlxCamera, ScaleX:Float = 1.0, ScaleY:Float = 1.0)
	{
		_camera = (Camera == null) ? FlxG.camera : Camera;
		updateColumns(TileWidth, WidthInTiles, ScaleX);
		updateRows(TileHeight, HeightInTiles, ScaleY);
		
		if (FlxG.renderBlit)
		{
			pixels = new BitmapData(Std.int(columns * TileWidth), Std.int(rows * TileHeight), true, 0);
			_flashRect = new Rectangle(0, 0, pixels.width, pixels.height);
			_matrix = new Matrix();
		}
		
		dirty = true;
	}
	
	/**
	 * Clean up memory.
	 */
	public function destroy():Void
	{
		_camera = null;
		
		if (FlxG.renderBlit)
		{
			pixels = null;
			blend = null;
			_matrix = null;
		}
	}
	
	/**
	 * Fill the buffer with the specified color.
	 * Default value is transparent.
	 * 
	 * @param	Color	What color to fill with, in 0xAARRGGBB hex format.
	 */
	public function fill(Color:FlxColor = FlxColor.TRANSPARENT):Void
	{
		if (FlxG.renderBlit)
		{
			pixels.fillRect(_flashRect, Color);
		}
	}
	
	/**
	 * Just stamps this buffer onto the specified camera at the specified location.
	 * 
	 * @param	Camera		Which camera to draw the buffer onto.
	 * @param	FlashPoint	Where to draw the buffer at in camera coordinates.
	 */
	public function draw(FlashPoint:Point, ScaleX:Float = 1.0, ScaleY:Float = 1.0):Void
	{
		if (isPixelPerfectRender())
		{
			FlashPoint.x = Math.floor(FlashPoint.x);
			FlashPoint.y = Math.floor(FlashPoint.y);
		}
		
		if (isPixelPerfectRender() && (ScaleX == 1.0 && ScaleY == 1.0) && blend == null)
		{
			_camera.buffer.copyPixels(pixels, _flashRect, FlashPoint, null, null, true);
		}
		else
		{
			_matrix.identity();
			_matrix.scale(ScaleX, ScaleY);
			_matrix.translate(FlashPoint.x, FlashPoint.y);
			_camera.buffer.draw(pixels, _matrix, null, blend);
		}
	}
	
	public function colorTransform(Transform:ColorTransform):Void
	{
		pixels.colorTransform(_flashRect, Transform);
	}
	
	public function updateColumns(TileWidth:Int, WidthInTiles:Int, ScaleX:Float = 1.0, ?Camera:FlxCamera):Void
	{
		WidthInTiles = (WidthInTiles < 0) ? 0 : WidthInTiles;
		columns = Math.ceil(_camera.width / (TileWidth * ScaleX)) + 1;
		columns = (columns > WidthInTiles) ? WidthInTiles : columns;
		width = Std.int(columns * TileWidth * ScaleX);
		dirty = true;
	}
	
	public function updateRows(TileHeight:Int, HeightInTiles:Int, ScaleY:Float = 1.0, ?Camera:FlxCamera):Void
	{
		HeightInTiles = (HeightInTiles < 0) ? 0 : HeightInTiles;
		rows = Math.ceil(Camera.height / (TileHeight * ScaleY)) + 1;
		rows = (rows > HeightInTiles) ? HeightInTiles : rows;
		height = Std.int(rows * TileHeight * ScaleY);	
		dirty = true;
	}

	/**
	 * Check if object is rendered pixel perfect on a specific camera.
	 */
	public function isPixelPerfectRender():Bool
	{
		return pixelPerfectRender == null ? _camera.pixelPerfectRender : pixelPerfectRender;
	}
}
