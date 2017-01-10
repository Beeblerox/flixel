package flixel.system.render.common;

import flash.display.Graphics;
import flixel.FlxCamera;
import flixel.graphics.FlxGraphic;
import flixel.graphics.TrianglesData;
import flixel.graphics.frames.FlxFrame;
import flixel.math.FlxMatrix;
import flixel.math.FlxRect;
import flixel.system.FlxAssets.FlxShader;
import flixel.system.render.common.DrawItem.DrawData;
import flixel.system.render.common.DrawItem.FlxDrawItemType;
import flixel.system.render.hardware.FlxHardwareView;
import flixel.system.render.hardware.gl.QuadBatch;
import flixel.system.render.hardware.gl.Triangles;
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
class FlxDrawStack implements IFlxDestroyable
{
	/**
	 * Currently used draw stack item
	 */
	private var _currentDrawItem:FlxDrawBaseItem<Dynamic>;
	
	/**
	 * Pointer to head of stack with draw items
	 */
	private var _lastCommand:FlxDrawBaseItem<Dynamic>;
	/**
	 * Last draw tiles item
	 */
	private var _lastTexturedTiles:QuadBatch;
	/**
	 * Last draw tiles item
	 */
	private var _lastColoredTiles:QuadBatch;
	/**
	 * Last draw triangles item
	 */
	private var _lastTriangles:Triangles;
	
	public var view:FlxHardwareView;
	
	/**
	 * Draw tiles stack items that can be reused
	 */
	private static var _texturedTilesStorage:QuadBatch;
	
	/**
	 * Draw tiles stack items that can be reused
	 */
	private static var _coloredTilesStorage:QuadBatch;
	
	/**
	 * Draw triangles stack items that can be reused
	 */
	private static var _trianglesStorage:Triangles;
	
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
		destroyDrawItemsChain(_lastCommand);
		destroyDrawItemsChain(_texturedTilesStorage);
		destroyDrawItemsChain(_coloredTilesStorage);
		destroyDrawItemsChain(_trianglesStorage);
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
	public function getTexturedTilesCommand(graphic:FlxGraphic, colored:Bool, hasColorOffsets:Bool = false,
		?blend:BlendMode, smooth:Bool = false, ?shader:FlxShader)
	{
		var itemToReturn:QuadBatch = null;
		
		if (_currentDrawItem != null
			&& _currentDrawItem.equals(FlxDrawItemType.TILES, graphic, colored, hasColorOffsets, blend, smooth, shader)
			&& FlxDrawBaseItem.canAddQuadToQuadsItem(_lastTexturedTiles))
		{
			return _lastTexturedTiles;
		}
		
		if (_texturedTilesStorage != null)
		{
			itemToReturn = _texturedTilesStorage;
			var newHead:QuadBatch = _texturedTilesStorage.nextTyped;
			itemToReturn.reset();
			_texturedTilesStorage = newHead;
		}
		else
		{
			itemToReturn = new QuadBatch(QuadBatch.BATCH_SIZE, true);
		}
		
		itemToReturn.set(graphic, colored, hasColorOffsets, blend, smooth, shader);
		
		itemToReturn.nextTyped = _lastTexturedTiles;
		_lastTexturedTiles = itemToReturn;
		
		if (_lastCommand == null)
		{
			_lastCommand = itemToReturn;
		}
		
		if (_currentDrawItem != null)
		{
			_currentDrawItem.next = itemToReturn;
		}
		
		_currentDrawItem = itemToReturn;
		
		return itemToReturn;
	}
	
	@:noCompletion
	public function getColoredTilesCommand(?blend:BlendMode, ?shader:FlxShader)
	{
		var itemToReturn:QuadBatch = null;
		
		if (_currentDrawItem != null
			&& _currentDrawItem.equals(FlxDrawItemType.TILES, null, true, false, blend, false, shader)
			&& FlxDrawBaseItem.canAddQuadToQuadsItem(_lastColoredTiles))
		{
			return _lastColoredTiles;
		}
		
		if (_coloredTilesStorage != null)
		{
			itemToReturn = _coloredTilesStorage;
			var newHead:QuadBatch = _coloredTilesStorage.nextTyped;
			itemToReturn.reset();
			_coloredTilesStorage = newHead;
		}
		else
		{
			itemToReturn = new QuadBatch(QuadBatch.BATCH_SIZE, false);
		}
		
		itemToReturn.set(null, true, false, blend, false, shader);
		
		itemToReturn.nextTyped = _lastColoredTiles;
		_lastColoredTiles = itemToReturn;
		
		if (_lastCommand == null)
		{
			_lastCommand = itemToReturn;
		}
		
		if (_currentDrawItem != null)
		{
			_currentDrawItem.next = itemToReturn;
		}
		
		_currentDrawItem = itemToReturn;
		
		return itemToReturn;
	}
	
	@:noCompletion
	public function getTrianglesCommand(graphic:FlxGraphic, smooth:Bool = false,
		colored:Bool = false, ?blend:BlendMode, ?shader:FlxShader):Triangles
	{
		var itemToReturn:Triangles = null;
		
		if (_trianglesStorage != null)
		{
			itemToReturn = _trianglesStorage;
			var newHead:Triangles = _trianglesStorage.nextTyped;
			itemToReturn.reset();
			_trianglesStorage = newHead;
		}
		else
		{
			itemToReturn = new Triangles();
		}
		
		itemToReturn.set(graphic, colored, false, blend, smooth, shader);
		
		itemToReturn.nextTyped = _lastTriangles;
		_lastTriangles = itemToReturn;
		
		if (_lastCommand == null)
		{
			_lastCommand = itemToReturn;
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
		#if FLX_RENDER_GL
		_helperMatrix.identity();
		
		var drawItem = getColoredTilesCommand(null, null);
		drawItem.addColorQuad(rect, _helperMatrix, color, alpha);
		#else
		var graphic:Graphics = view.canvas.graphics;
		var camera:FlxCamera = view.camera;
		graphic.beginFill(color, alpha);
		graphic.drawRect(rect.x, rect.y, rect.width, rect.height);
		graphic.endFill();
		#end
	}
	
	@:noCompletion
	public function clearDrawStack():Void
	{	
		var currTiles:QuadBatch = _lastTexturedTiles;
		var newTilesHead:QuadBatch;
		
		while (currTiles != null)
		{
			newTilesHead = currTiles.nextTyped;
			currTiles.reset();
			currTiles.nextTyped = _texturedTilesStorage;
			_texturedTilesStorage = currTiles;
			currTiles = newTilesHead;
		}
		
		currTiles = _lastColoredTiles;
		
		while (currTiles != null)
		{
			newTilesHead = currTiles.nextTyped;
			currTiles.reset();
			currTiles.nextTyped = _coloredTilesStorage;
			_coloredTilesStorage = currTiles;
			currTiles = newTilesHead;
		}
		
		var currTriangles:Triangles = _lastTriangles;
		var newTrianglesHead:Triangles;
		
		while (currTriangles != null)
		{
			newTrianglesHead = currTriangles.nextTyped;
			currTriangles.reset();
			currTriangles.nextTyped = _trianglesStorage;
			_trianglesStorage = currTriangles;
			currTriangles = newTrianglesHead;
		}
		
		_currentDrawItem = null;
		_lastCommand = null;
		_lastTexturedTiles = null;
		_lastColoredTiles = null;
		_lastTriangles = null;
	}
	
	public function render():Void
	{
		var currItem:FlxDrawBaseItem<Dynamic> = _lastCommand;
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
		var drawItem = getTexturedTilesCommand(frame.parent, isColored, hasColorOffsets, blend, smoothing, shader);
		
		if (hasColorOffsets)
			drawItem.setOffsets(transform);
		
		drawItem.addQuad(frame, matrix, transform, blend, smoothing);
	}
	
	public function copyPixels(?frame:FlxFrame, ?pixels:BitmapData, ?sourceRect:Rectangle,
		destPoint:Point, ?transform:ColorTransform, ?blend:BlendMode, ?smoothing:Bool = false, ?shader:FlxShader):Void
	{
		_helperMatrix.identity();
		_helperMatrix.translate(destPoint.x + frame.offset.x, destPoint.y + frame.offset.y);
		
		var isColored = (transform != null && transform.hasRGBMultipliers());
		var hasColorOffsets:Bool = (transform != null && transform.hasRGBAOffsets());
		
		var drawItem = getTexturedTilesCommand(frame.parent, isColored, hasColorOffsets, blend, smoothing, shader);
		
		if (hasColorOffsets)
			drawItem.setOffsets(transform);
		
		drawItem.addQuad(frame, _helperMatrix, transform, blend, smoothing);
	}
	
	// TODO: add support for repeat (it's true by default)
	public function drawTriangles(graphic:FlxGraphic, data:TrianglesData, ?matrix:FlxMatrix, ?transform:ColorTransform, ?blend:BlendMode, 
		repeat:Bool = true, smoothing:Bool = false, ?shader:FlxShader):Void
	{
		var isColored:Bool = data.colored;
		
		var drawItem = getTrianglesCommand(graphic, smoothing, isColored, blend, shader);
		
		drawItem.data = data;
		drawItem.matrix = matrix;
		drawItem.color = transform;
	}
	
	public function drawUVQuad(graphic:FlxGraphic, rect:FlxRect, uv:FlxRect, matrix:FlxMatrix,
		?transform:ColorTransform, ?blend:BlendMode, ?smoothing:Bool = false, ?shader:FlxShader):Void
	{
		var isColored = (transform != null && transform.hasRGBMultipliers());
		var hasColorOffsets:Bool = (transform != null && transform.hasRGBAOffsets());
		#if (openfl >= "4.0.0")
		var drawItem = getTexturedTilesCommand(graphic, isColored, hasColorOffsets, blend, smoothing, shader);
		#else
		var drawItem = startTrianglesBatch(graphic, smoothing, isColored, blend, shader, FlxCameraView.VERTICES_PER_TILE, FlxCameraView.INDICES_PER_TILE);
		#end
		
		if (hasColorOffsets)
			drawItem.setOffsets(transform);
		
		drawItem.addUVQuad(graphic, rect, uv, matrix, transform);
	}
	
	public function drawColorQuad(rect:FlxRect, matrix:FlxMatrix, color:FlxColor, alpha:Float = 1.0, ?blend:BlendMode, ?smoothing:Bool = false, ?shader:FlxShader):Void
	{
		// TODO: fix this...
		
		/*
		#if (openfl >= "4.0.0")
		var drawItem = getTexturedTilesCommand(null, true, false, blend, smoothing, shader);
		#else
		var drawItem = getNewDrawTrianglesItem(null, smoothing, true, blend, shader);
		#end
		drawItem.addColorQuad(rect, matrix, color, alpha, blend, smoothing);
		*/
		
	}
}