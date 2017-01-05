package flixel.system.render.common;

import flash.display.Graphics;
import flixel.FlxCamera;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxFrame;
import flixel.math.FlxMatrix;
import flixel.math.FlxRect;
import flixel.system.FlxAssets.FlxShader;
import flixel.system.render.common.DrawItem.DrawData;
import flixel.system.render.common.DrawItem.FlxDrawItemType;
import flixel.system.render.common.DrawItem.FlxDrawQuadsItem;
import flixel.system.render.common.DrawItem.FlxDrawTrianglesItem;
import flixel.system.render.hardware.FlxHardwareView;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;
import flixel.util.FlxDestroyUtil.IFlxDestroyable;
import openfl.display.BitmapData;
import openfl.display.BlendMode;
import openfl.geom.ColorTransform;
import openfl.geom.Point;
import openfl.geom.Rectangle;

using flixel.util.FlxColorTransformUtil;

// TODO: add method for drawing color triangles...

/**
 * ...
 * @author Zaphod
 */
class FlxDrawStackGL implements IFlxDestroyable
{
	/**
	 * Currently used draw stack item
	 */
	private var _currentDrawItem:FlxDrawBaseItem<Dynamic>;
	/**
	 * Pointer to head of stack with draw items
	 */
	private var _headOfDrawStack:FlxDrawBaseItem<Dynamic>;
	/**
	 * Last draw tiles item
	 */
	private var _headTiles:FlxDrawQuadsItem;
	
	public var view:FlxHardwareView;
	
	/**
	 * Draw tiles stack items that can be reused
	 */
	private static var _storageTilesHead:FlxDrawQuadsItem;
	
	private var _helperMatrix:FlxMatrix = new FlxMatrix();
	
	public function new(view:FlxHardwareView) 
	{
		this.view = view;
	}
	
	public function destroy():Void
	{
		destroyDrawStackItems();
		_helperMatrix = null;
		view = null;
	}
	
	private function destroyDrawStackItems():Void
	{
		destroyDrawItemsChain(_headOfDrawStack);
		destroyDrawItemsChain(_storageTilesHead);
		destroyDrawItemsChain(_storageTrianglesHead);
	}
	
	private function destroyDrawItemsChain(item:FlxDrawBaseItem<Dynamic>):Void
	{
		var next:FlxDrawBaseItem<Dynamic>;
		while (item != null)
		{
			next = item.next;
			item = FlxDestroyUtil.destroy(item);
			item = next;
		}
	}
	
	@:noCompletion
	public function startQuadBatch(graphic:FlxGraphic, colored:Bool, hasColorOffsets:Bool = false,
		?blend:BlendMode, smooth:Bool = false, ?shader:FlxShader)
	{
		var itemToReturn:FlxDrawQuadsItem = null;
		
		if (_currentDrawItem != null /* && _currentDrawItem.type == FlxDrawItemType.TILES*/ 
			&& _currentDrawItem.equals(FlxDrawItemType.TILES, graphic, colored, hasColorOffsets, blend, smooth, shader)
			&& FlxDrawBaseItem.canAddQuadToQuadsItem(_headTiles))
		{	
			return _headTiles;
		}
		
		if (_storageTilesHead != null)
		{
			itemToReturn = _storageTilesHead;
			var newHead:FlxDrawQuadsItem = _storageTilesHead.nextTyped;
			itemToReturn.reset();
			_storageTilesHead = newHead;
		}
		else
		{
			itemToReturn = new FlxDrawQuadsItem();
		}
		
		itemToReturn.set(graphic, colored, hasColorOffsets, blend, smooth, shader);
		
		itemToReturn.nextTyped = _headTiles;
		_headTiles = itemToReturn;
		
		if (_headOfDrawStack == null)
		{
			_headOfDrawStack = itemToReturn;
		}
		
		if (_currentDrawItem != null)
		{
			_currentDrawItem.next = itemToReturn;
		}
		
		_currentDrawItem = itemToReturn;
		
		return itemToReturn;
	}
	
	public function fillRect(rect:FlxRect, color:FlxColor, alpha:Float = 1.0):Void
	{
		_helperMatrix.identity();
		var drawItem = startQuadBatch(null, true, false);
		drawItem.addColorQuad(rect, _helperMatrix, color, alpha);
	}
	
	@:noCompletion
	public function clearDrawStack():Void
	{	
		var currTiles:FlxDrawQuadsItem = _headTiles;
		var newTilesHead:FlxDrawQuadsItem;
		
		while (currTiles != null)
		{
			newTilesHead = currTiles.nextTyped;
			currTiles.reset();
			currTiles.nextTyped = _storageTilesHead;
			_storageTilesHead = currTiles;
			currTiles = newTilesHead;
		}
		
		_currentDrawItem = null;
		_headOfDrawStack = null;
		_headTiles = null;
	}
	
	public function render():Void
	{
		var currItem:FlxDrawBaseItem<Dynamic> = _headOfDrawStack;
		while (currItem != null)
		{
			currItem.render(view);
			currItem = currItem.next;
		}
	}
	
	public function drawPixels(?frame:FlxFrame, ?pixels:BitmapData, matrix:FlxMatrix,
		?transform:ColorTransform, ?blend:BlendMode, ?smoothing:Bool = false, ?shader:FlxShader):Void
	{
		var isColored = (transform != null && transform.hasRGBMultipliers());
		var hasColorOffsets:Bool = (transform != null && transform.hasRGBAOffsets());
		var drawItem = startQuadBatch(frame.parent, isColored, hasColorOffsets, blend, smoothing, shader);
		
		if (hasColorOffsets)
			drawItem.setOffsets(transform);
		
		drawItem.addQuad(frame, matrix, transform);
	}
	
	public function copyPixels(?frame:FlxFrame, ?pixels:BitmapData, ?sourceRect:Rectangle,
		destPoint:Point, ?transform:ColorTransform, ?blend:BlendMode, ?smoothing:Bool = false, ?shader:FlxShader):Void
	{
		_helperMatrix.identity();
		_helperMatrix.translate(destPoint.x + frame.offset.x, destPoint.y + frame.offset.y);
		
		var isColored = (transform != null && transform.hasRGBMultipliers());
		var hasColorOffsets:Bool = (transform != null && transform.hasRGBAOffsets());
		
		var drawItem = startQuadBatch(frame.parent, isColored, hasColorOffsets, blend, smoothing, shader);
		
		if (hasColorOffsets)
			drawItem.setOffsets(transform);
		
		drawItem.addQuad(frame, _helperMatrix, transform);
	}
	
	// TODO: add support for repeat (it's true by default)
	// TODO: support color offsets for this method also
	public function drawTriangles(graphic:FlxGraphic, vertices:DrawData<Float>, indices:DrawData<Int>,
		uvtData:DrawData<Float>, ?matrix:FlxMatrix, ?transform:ColorTransform, ?blend:BlendMode, 
		repeat:Bool = true, smoothing:Bool = false, ?shader:FlxShader):Void
	{
		
	}
	
	public function drawUVQuad(graphic:FlxGraphic, rect:FlxRect, uv:FlxRect, matrix:FlxMatrix,
		?transform:ColorTransform, ?blend:BlendMode, ?smoothing:Bool = false, ?shader:FlxShader):Void
	{
		var isColored = (transform != null && transform.hasRGBMultipliers());
		var hasColorOffsets:Bool = (transform != null && transform.hasRGBAOffsets());
		#if (openfl >= "4.0.0")
		var drawItem = startQuadBatch(graphic, isColored, hasColorOffsets, blend, smoothing, shader);
		#else
		var drawItem = startTrianglesBatch(graphic, smoothing, isColored, blend, shader, FlxCameraView.VERTICES_PER_TILE, FlxCameraView.INDICES_PER_TILE);
		#end
		
		if (hasColorOffsets)
			drawItem.setOffsets(transform);
		
		drawItem.addUVQuad(rect, uv, matrix, transform);
	}
	
	public function drawColorQuad(rect:FlxRect, matrix:FlxMatrix, color:FlxColor, alpha:Float = 1.0, ?blend:BlendMode, ?smoothing:Bool = false, ?shader:FlxShader):Void
	{
		
	}
}