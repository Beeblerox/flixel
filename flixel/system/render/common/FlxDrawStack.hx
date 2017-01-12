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
import flixel.system.render.common.DrawItem.FlxDrawQuadsCommand;
import flixel.system.render.common.DrawItem.FlxDrawTrianglesCommand;
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

// TODO: make it work with openfl 3.6.1 with "next" flag and without it...

/**
 * ...
 * @author Zaphod
 */
class FlxDrawStack implements IFlxDestroyable
{
	/**
	 * Currently used draw stack item
	 */
	private var _currentCommand:FlxDrawBaseItem<Dynamic>;
	
	/**
	 * Pointer to head of stack with draw items
	 */
	private var _firstCommand:FlxDrawBaseItem<Dynamic>;
	/**
	 * Last draw tiles item
	 */
	private var _lastTexturedQuads:FlxDrawQuadsCommand;
	/**
	 * Last draw tiles item
	 */
	private var _lastColoredQuads:FlxDrawQuadsCommand;
	/**
	 * Last draw triangles item
	 */
	private var _lastTriangles:FlxDrawTrianglesCommand;
	
	public var view:FlxHardwareView;
	
	/**
	 * Draw tiles stack items that can be reused
	 */
	private static var _texturedTilesStorage:FlxDrawQuadsCommand;
	
	/**
	 * Draw tiles stack items that can be reused
	 */
	private static var _coloredTilesStorage:FlxDrawQuadsCommand;
	
	/**
	 * Draw triangles stack items that can be reused
	 */
	private static var _trianglesStorage:FlxDrawTrianglesCommand;
	
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
		destroyDrawItemsChain(_firstCommand);
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
		var itemToReturn:FlxDrawQuadsCommand = null;
		
		if (_currentCommand != null
			&& _currentCommand.equals(FlxDrawItemType.TILES, graphic, colored, hasColorOffsets, blend, smooth, shader) 
			&& _lastTexturedQuads.canAddQuad)
		{
			return _lastTexturedQuads;
		}
		
		if (_texturedTilesStorage != null)
		{
			itemToReturn = _texturedTilesStorage;
			var newHead:FlxDrawQuadsCommand = _texturedTilesStorage.nextTyped;
			itemToReturn.reset();
			_texturedTilesStorage = newHead;
		}
		else
		{
			itemToReturn = new FlxDrawQuadsCommand(FlxCameraView.QUADS_PER_BATCH, true);
		}
		
		itemToReturn.set(graphic, colored, hasColorOffsets, blend, smooth, shader);
		
		itemToReturn.nextTyped = _lastTexturedQuads;
		_lastTexturedQuads = itemToReturn;
		
		if (_firstCommand == null)
		{
			_firstCommand = itemToReturn;
		}
		
		if (_currentCommand != null)
		{
			_currentCommand.next = itemToReturn;
		}
		
		_currentCommand = itemToReturn;
		
		return itemToReturn;
	}
	
	@:noCompletion
	public function getColoredTilesCommand(?blend:BlendMode, ?shader:FlxShader)
	{
		var itemToReturn:FlxDrawQuadsCommand = null;
		
		if (_currentCommand != null
			&& _currentCommand.equals(FlxDrawItemType.TILES, null, true, false, blend, false, shader) 
			&& _lastColoredQuads.canAddQuad)
		{
			return _lastColoredQuads;
		}
		
		if (_coloredTilesStorage != null)
		{
			itemToReturn = _coloredTilesStorage;
			var newHead:FlxDrawQuadsCommand = _coloredTilesStorage.nextTyped;
			itemToReturn.reset();
			_coloredTilesStorage = newHead;
		}
		else
		{
			itemToReturn = new FlxDrawQuadsCommand(FlxCameraView.QUADS_PER_BATCH, false);
		}
		
		itemToReturn.set(null, true, false, blend, false, shader);
		
		itemToReturn.nextTyped = _lastColoredQuads;
		_lastColoredQuads = itemToReturn;
		
		if (_firstCommand == null)
		{
			_firstCommand = itemToReturn;
		}
		
		if (_currentCommand != null)
		{
			_currentCommand.next = itemToReturn;
		}
		
		_currentCommand = itemToReturn;
		
		return itemToReturn;
	}
	
	@:noCompletion
	public function getNewTrianglesCommand(graphic:FlxGraphic, smooth:Bool = false,
		colored:Bool = false, ?blend:BlendMode, ?shader:FlxShader):FlxDrawTrianglesCommand
	{
		var itemToReturn:FlxDrawTrianglesCommand = null;
		
		if (_trianglesStorage != null)
		{
			itemToReturn = _trianglesStorage;
			var newHead:FlxDrawTrianglesCommand = _trianglesStorage.nextTyped;
			itemToReturn.reset();
			_trianglesStorage = newHead;
		}
		else
		{
			itemToReturn = new FlxDrawTrianglesCommand();
		}
		
		itemToReturn.set(graphic, colored, false, blend, smooth, shader);
		
		itemToReturn.nextTyped = _lastTriangles;
		_lastTriangles = itemToReturn;
		
		if (_firstCommand == null)
		{
			_firstCommand = itemToReturn;
		}
		
		if (_currentCommand != null)
		{
			_currentCommand.next = itemToReturn;
		}
		
		_currentCommand = itemToReturn;
		
		return itemToReturn;
	}
	
	@:noCompletion
	public function getTrianglesCommand(graphic:FlxGraphic, smooth:Bool = false,
		colored:Bool = false, ?blend:BlendMode, ?shader:FlxShader, numTriangles:Int):FlxDrawTrianglesCommand
	{
		if (!FlxCameraView.BATCH_TRIANGLES)
		{
			return getNewTrianglesCommand(graphic, smooth, colored, blend, shader);
		}
		else if (_currentCommand != null
			&& _currentCommand.equals(FlxDrawItemType.TRIANGLES, graphic, colored, false, blend, smooth, shader)
			&& _lastTriangles.canAddTriangles(numTriangles))
		{	
			return _lastTriangles;
		}
		
		return getNewTrianglesCommand(graphic, smooth, colored, blend, shader);
	}
	
	/*
	@:noCompletion
	public function getNewDrawTrianglesItem(graphic:FlxGraphic, smooth:Bool = false,
		colored:Bool = false, ?blend:BlendMode, ?shader:FlxShader):FlxDrawTrianglesItem
	{
		var itemToReturn:FlxDrawTrianglesCommand = null;
		
		if (_storageTrianglesHead != null)
		{
			itemToReturn = _trianglesStorage;
			var newHead:FlxDrawTrianglesCommand = _trianglesStorage.nextTyped;
			itemToReturn.reset();
			_storageTrianglesHead = newHead;
		}
		else
		{
			itemToReturn = new FlxDrawTrianglesCommand();
		}
		
		itemToReturn.set(graphic, colored, false, blend, smooth, shader);
		
		itemToReturn.nextTyped = _headTriangles;
		_headTriangles = itemToReturn;
		
		if (_firstCommand == null)
		{
			_firstCommand = itemToReturn;
		}
		
		if (_currentCommand != null)
		{
			_currentCommand.next = itemToReturn;
		}
		
		_currentCommand = itemToReturn;
		
		return itemToReturn;
	}
	*/
	
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
		var currTiles:FlxDrawQuadsCommand = _lastTexturedQuads;
		var newTilesHead:FlxDrawQuadsCommand;
		
		while (currTiles != null)
		{
			newTilesHead = currTiles.nextTyped;
			currTiles.reset();
			currTiles.nextTyped = _texturedTilesStorage;
			_texturedTilesStorage = currTiles;
			currTiles = newTilesHead;
		}
		
		currTiles = _lastColoredQuads;
		
		while (currTiles != null)
		{
			newTilesHead = currTiles.nextTyped;
			currTiles.reset();
			currTiles.nextTyped = _coloredTilesStorage;
			_coloredTilesStorage = currTiles;
			currTiles = newTilesHead;
		}
		
		var currTriangles:FlxDrawTrianglesCommand = _lastTriangles;
		var newTrianglesHead:FlxDrawTrianglesCommand;
		
		while (currTriangles != null)
		{
			newTrianglesHead = currTriangles.nextTyped;
			currTriangles.reset();
			currTriangles.nextTyped = _trianglesStorage;
			_trianglesStorage = currTriangles;
			currTriangles = newTrianglesHead;
		}
		
		_currentCommand = null;
		_firstCommand = null;
		_lastTexturedQuads = null;
		_lastColoredQuads = null;
		_lastTriangles = null;
	}
	
	public function render():Void
	{
		var currItem:FlxDrawBaseItem<Dynamic> = _firstCommand;
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
	
	// TODO: put back triangle batching for openfl less than 4.0...
	
	// TODO: add support for repeat (it's true by default)
	public function drawTriangles(graphic:FlxGraphic, data:TrianglesData, ?matrix:FlxMatrix, ?transform:ColorTransform, ?blend:BlendMode, 
		repeat:Bool = true, smoothing:Bool = false, ?shader:FlxShader):Void
	{
		#if FLX_RENDER_GL
		var isColored:Bool = data.colored;
		var drawItem = getTrianglesCommand(graphic, smoothing, isColored, blend, shader);
		drawItem.data = data;
		drawItem.matrix = matrix;
		drawItem.color = transform;
		#else
		
		// TODO: fix this...
		
		#end
	}
	
	public function drawUVQuad(graphic:FlxGraphic, rect:FlxRect, uv:FlxRect, matrix:FlxMatrix,
		?transform:ColorTransform, ?blend:BlendMode, ?smoothing:Bool = false, ?shader:FlxShader):Void
	{
		var isColored = (transform != null && transform.hasRGBMultipliers());
		var hasColorOffsets:Bool = (transform != null && transform.hasRGBAOffsets());
	//	#if (openfl >= "4.0.0")
		var drawItem = getTexturedTilesCommand(graphic, isColored, hasColorOffsets, blend, smoothing, shader);
	//	#else
	//	var drawItem = startTrianglesBatch(graphic, smoothing, isColored, blend, shader, FlxCameraView.VERTICES_PER_TILE, FlxCameraView.INDICES_PER_TILE);
	//	#end
		
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