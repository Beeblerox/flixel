package flixel.system.render.gl;

import flixel.graphics.FlxMaterial;
import flixel.graphics.FlxTrianglesData;
import flixel.graphics.frames.FlxFrame;
import flixel.math.FlxMatrix;
import flixel.math.FlxRect;
import flixel.system.render.common.DrawCommand.FlxDrawItemType;
import flixel.system.render.common.FlxCameraView;
import flixel.system.render.common.FlxDrawBaseCommand;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;
import lime.graphics.GLRenderContext;
import openfl.Vector;
import openfl.display.BitmapData;
import openfl.display.DisplayObjectContainer;
import openfl.display.Graphics;
import openfl.display.Sprite;
import openfl.geom.ColorTransform;
import openfl.geom.Point;
import openfl.geom.Rectangle;
import openfl.gl.GL;

class FlxGLView extends FlxCameraView
{
	public var renderTexture(get, null):RenderTexture;
	
	private static var _fillRect:FlxRect = FlxRect.get();
	
	/**
	 * Used to render buffer to screen space.
	 * NOTE: We don't recommend modifying this directly unless you are fairly experienced.
	 * Uses include 3D projection, advanced display list modification, and more.
	 * This is container for everything else that is used by camera and rendered to the camera.
	 * 
	 * Its position is modified by `updateFlashSpritePosition()` which is called every frame.
	 */
	public var flashSprite:Sprite = new Sprite();
	
	/**
	 * Internal sprite, used for correct trimming of camera viewport.
	 * It is a child of `flashSprite`.
	 * Its position is modified by `updateScrollRect()` method, which is called on camera's resize and scale events.
	 */
	private var _scrollRect:Sprite = new Sprite();
	
	/**
	 * Sprite used for actual rendering in tile render mode (instead of `_flashBitmap` for blitting).
	 * Its graphics is used as a drawing surface for `drawTriangles()` and `drawTiles()` methods.
	 * It is a child of `_scrollRect` `Sprite` (which trims graphics that should be invisible).
	 * Its position is modified by `updateInternalSpritePositions()`, which is called on camera's resize and scale events.
	 */
	private var _canvas:CanvasGL; // TODO: implement canvas version of this class for js target...
	
	#if FLX_DEBUG
	/**
	 * Sprite for visual effects (flash and fade) and drawDebug information 
	 * (bounding boxes are drawn on it) for tile render mode.
	 * It is a child of `_scrollRect` `Sprite` (which trims graphics that should be invisible).
	 * Its position is modified by `updateInternalSpritePositions()`, which is called on camera's resize and scale events.
	 */
	public var debugLayer:GLDebugRenderer;
	#end
	
	private var context:GLContextHelper;
	
	/**
	 * Helper matrix object. Used in tile render mode when camera's zoom is less than initialZoom
	 * (it is applied to all objects rendered on the camera at such circumstances).
	 */
	private var _renderMatrix:FlxMatrix = new FlxMatrix();
	
	/**
	 * Logical flag for tracking whether to apply _renderMatrix transformation to objects or not.
	 */
	private var _useRenderMatrix:Bool = false;
	
	public function new(camera:FlxCamera) 
	{
		super(camera);
		
		context = FlxG.game.glContextHelper;
		
		flashSprite.addChild(_scrollRect);
	//	_scrollRect.scrollRect = new Rectangle(); // TODO: fix scroll rects...
		
		_canvas = new CanvasGL(camera.width, camera.height, context);
		_scrollRect.addChild(_canvas);
		
		#if FLX_DEBUG
		debugLayer = new GLDebugRenderer(camera.width, camera.height, context);
		_scrollRect.addChild(debugLayer);
		#end
	}
	
	override public function destroy():Void 
	{
		super.destroy();
		
		context = null;
		
		FlxDestroyUtil.removeChild(flashSprite, _scrollRect);
		
		#if FLX_DEBUG
		FlxDestroyUtil.removeChild(_scrollRect, debugLayer);
		debugLayer = null;
		#end
		
		FlxDestroyUtil.removeChild(_scrollRect, _canvas);
		_canvas = FlxDestroyUtil.destroy(_canvas);
		
		_textureQuads = FlxDestroyUtil.destroy(_textureQuads);
		_colorQuads = FlxDestroyUtil.destroy(_colorQuads);
		_triangles = FlxDestroyUtil.destroy(_triangles);
		_singleTextureQuad = FlxDestroyUtil.destroy(_singleTextureQuad);
		_singleColorQuad = FlxDestroyUtil.destroy(_singleColorQuad);
		_currentCommand = null;
		_helperMatrix = null;
		
		flashSprite = null;
		_scrollRect = null;
		_renderMatrix = null;
	}
	
	override public function drawPixels(?frame:FlxFrame, ?pixels:BitmapData, material:FlxMaterial, matrix:FlxMatrix,
		?transform:ColorTransform):Void
	{
		_helperMatrix.copyFrom(matrix);
		if (_useRenderMatrix)
			_helperMatrix.concat(_renderMatrix);
		else
			_helperMatrix.translate( -viewOffsetX, -viewOffsetY);
		
		var bitmap = frame.parent.bitmap;
		var drawItem = (material.batchable) ? getTextureQuads(bitmap, material) : getSingleTextureQuad(bitmap, material);
		drawItem.addQuad(frame, matrix, transform, material);
	}
	
	override public function copyPixels(?frame:FlxFrame, ?pixels:BitmapData, material:FlxMaterial, ?sourceRect:Rectangle,
		destPoint:Point, ?transform:ColorTransform):Void
	{
		_helperMatrix.identity();
		_helperMatrix.translate(destPoint.x + frame.offset.x, destPoint.y + frame.offset.y);
		
		if (_useRenderMatrix)
			_helperMatrix.concat(_renderMatrix);
		else
			_helperMatrix.translate( -viewOffsetX, -viewOffsetY);
		
		var bitmap = frame.parent.bitmap;
		var drawItem = (material.batchable) ? getTextureQuads(bitmap, material) : getSingleTextureQuad(bitmap, material);
		drawItem.addQuad(frame, _helperMatrix, transform, material);
	}
	
	override public function drawTriangles(bitmap:BitmapData, material:FlxMaterial, data:FlxTrianglesData, ?matrix:FlxMatrix, ?transform:ColorTransform):Void 
	{
		_helperMatrix.copyFrom(matrix);
		
		if (_useRenderMatrix)
			_helperMatrix.concat(_renderMatrix);
		else
			_helperMatrix.translate( -viewOffsetX, -viewOffsetY);
		
		var drawItem = getTriangles(bitmap, material);
		drawItem.data = data;
		drawItem.matrix = _helperMatrix;
		drawItem.color = transform;
		drawItem.flush();
	}
	
	override public function drawUVQuad(bitmap:BitmapData, material:FlxMaterial, rect:FlxRect, uv:FlxRect, matrix:FlxMatrix,
		?transform:ColorTransform):Void
	{
		_helperMatrix.copyFrom(matrix);
		
		if (_useRenderMatrix)
			_helperMatrix.concat(_renderMatrix);
		else
			_helperMatrix.translate( -viewOffsetX, -viewOffsetY);
		
		var drawItem = (material.batchable) ? getTextureQuads(bitmap, material) : getSingleTextureQuad(bitmap, material);
		drawItem.addUVQuad(bitmap, rect, uv, _helperMatrix, transform, material);
	}
	
	override public function drawColorQuad(material:FlxMaterial, rect:FlxRect, matrix:FlxMatrix, color:FlxColor, alpha:Float = 1.0):Void
	{
		_helperMatrix.copyFrom(matrix);
		if (_useRenderMatrix)
			_helperMatrix.concat(_renderMatrix);
		else
			_helperMatrix.translate( -viewOffsetX, -viewOffsetY);
		
		var drawItem = (material.batchable) ? getColorQuads(material) : getSingleColorQuad(material);
		drawItem.addColorQuad(rect, _helperMatrix, color, alpha, material);
	}
	
	override public function updateOffset():Void 
	{
		super.updateOffset();
		_canvas.resize(camera.width, camera.height);
	}
	
	override public function updatePosition():Void 
	{
		if (flashSprite != null)
		{
			flashSprite.x = camera.x * FlxG.scaleMode.scale.x + _flashOffset.x;
			flashSprite.y = camera.y * FlxG.scaleMode.scale.y + _flashOffset.y;
		}
	}
	
	override public function updateScrollRect():Void 
	{
		/*
		var rect:Rectangle = (_scrollRect != null) ? _scrollRect.scrollRect : null;
		
		if (rect != null)
		{
			rect.x = rect.y = 0;
			rect.width = camera.width * camera.initialZoom * FlxG.scaleMode.scale.x;
			rect.height = camera.height * camera.initialZoom * FlxG.scaleMode.scale.y;
			_scrollRect.scrollRect = rect;
			_scrollRect.x = -0.5 * rect.width;
			_scrollRect.y = -0.5 * rect.height;
		}
		*/
		
		_scrollRect.x = -0.5 * camera.width * camera.initialZoom * FlxG.scaleMode.scale.x;
		_scrollRect.y = -0.5 * camera.height * camera.initialZoom * FlxG.scaleMode.scale.y;
	}
	
	override public function updateInternals():Void 
	{
		if (_canvas != null)
		{
			_canvas.x = -0.5 * camera.width * (camera.scaleX - camera.initialZoom) * FlxG.scaleMode.scale.x;
			_canvas.y = -0.5 * camera.height * (camera.scaleY - camera.initialZoom) * FlxG.scaleMode.scale.y;
			
			_canvas.scaleX = camera.totalScaleX;
			_canvas.scaleY = camera.totalScaleY;
			
			#if FLX_DEBUG
			if (debugLayer != null)
			{
				debugLayer.x = _canvas.x;
				debugLayer.y = _canvas.y;
				
				debugLayer.scaleX = _canvas.scaleX;
				debugLayer.scaleY = _canvas.scaleY;
			}
			#end
		}
	}
	
	override public function updateFilters():Void 
	{
		_canvas.filters = camera.filtersEnabled ? _filters : null;
	}
	
	override public function checkResize():Void 
	{
		var w = camera.width;
		var h = camera.height;
		
		if (w != buffer.width || h != buffer.height)
		{
			_canvas.resize(w, h);
			
			// TODO: try to implement screen FlxSprite (like on flash target)...
		//	screen.pixels = _buffer;
		//	screen.origin.set();
		}
		
		updateRenderMatrix();
	}
	
	private inline function updateRenderMatrix():Void
	{
		_renderMatrix.identity();
		_renderMatrix.translate(-viewOffsetX, -viewOffsetY);
		_renderMatrix.scale(camera.scaleX, camera.scaleY);
  		
		_useRenderMatrix = (camera.scaleX < camera.initialZoom) || (camera.scaleY < camera.initialZoom);
  	}
	
	override public function updateScale():Void 
	{
		updateRenderMatrix();
		
		if (_useRenderMatrix)
		{
			_canvas.scaleX = camera.initialZoom * FlxG.scaleMode.scale.x;
			_canvas.scaleY = camera.initialZoom * FlxG.scaleMode.scale.y;
		}
		else
		{
			_canvas.scaleX = camera.totalScaleX;
			_canvas.scaleY = camera.totalScaleY;
		}
		
		super.updateScale();
	}
	
	override public function fill(Color:FlxColor, BlendAlpha:Bool = true, FxAlpha:Float = 1.0):Void 
	{
		// i'm drawing rect with these parameters to avoid light lines at the top and left of the camera,
		// which could appear while cameras fading
		_fillRect.set(viewOffsetX - 1, viewOffsetY - 1, viewWidth + 2, viewHeight + 2);
		
		_helperMatrix.identity();
		var drawItem = getSingleColorQuad(DefaultColorMaterial);
		drawItem.addColorQuad(_fillRect, _helperMatrix, Color, FxAlpha, DefaultColorMaterial);
	}
	
	override public function drawFX(FxColor:FlxColor, FxAlpha:Float = 1.0):Void 
	{
		var alphaComponent:Float = FxColor.alpha;
		fill(FxColor.to24Bit(), true, ((alphaComponent <= 0) ? 0xff : alphaComponent) * FxAlpha / 255);
	}
	
	override public function lock(useBufferLocking:Bool):Void 
	{
		context.shaderManager.setShader(null);
		
		var matrix = _canvas.projection;
		_textureQuads.prepare(matrix, context, renderTexture);
		_colorQuads.prepare(matrix, context, renderTexture);
		_triangles.prepare(matrix, context, renderTexture);
		_singleTextureQuad.prepare(matrix, context, renderTexture);
		_singleColorQuad.prepare(matrix, context, renderTexture);
		_currentCommand = null;
		
		_canvas.clear();
		
		// Clearing camera's debug sprite
		#if FLX_DEBUG
		debugLayer.prepare();
		debugLayer.clear();
		#end
		fill(camera.bgColor.to24Bit(), camera.useBgAlphaBlending, camera.bgColor.alphaFloat);
	}
	
	override public function unlock(useBufferLocking:Bool):Void 
	{
		render();
		#if FLX_DEBUG
		debugLayer.finish();
		#end
		context.resetFrameBuffer();
	}
	
	override public function offsetView(X:Float, Y:Float):Void 
	{
		flashSprite.x += X;
		flashSprite.y += Y;
	}
	
	override public function drawDebugRect(x:Float, y:Float, width:Float, height:Float, color:Int, thickness:Float = 1.0, alpha:Float = 1.0):Void 
	{
		var drawColor:FlxColor = color;
		drawColor.alphaFloat = alpha;
		debugLayer.rect(x, y, width, height, drawColor, thickness);
	}
	
	override public function drawDebugLine(x1:Float, y1:Float, x2:Float, y2:Float, color:Int, thickness:Float = 1.0, alpha:Float = 1.0):Void 
	{
		var drawColor:FlxColor = color;
		drawColor.alphaFloat = alpha;
		debugLayer.line(x1, y1, x2, y2, drawColor, thickness);
	}
	
	override public function drawDebugFilledRect(x:Float, y:Float, width:Float, height:Float, color:Int, alpha:Float = 1.0):Void 
	{
		var drawColor:FlxColor = color;
		drawColor.alphaFloat = alpha;
		debugLayer.fillRect(x, y, width, height, color);
	}
	
	override public function drawDebugTriangles(matrix:FlxMatrix, data:FlxTrianglesData, color:Int, thickness:Float = 1, alpha:Float = 1.0):Void
	{
		var drawColor:FlxColor = color;
		drawColor.alphaFloat = alpha;
		debugLayer.triangles(matrix, data.vertices, data.indices, drawColor, thickness);
	}
	
	override private function set_color(Color:FlxColor):FlxColor 
	{
		var colorTransform:ColorTransform = _canvas.transform.colorTransform;
		colorTransform.redMultiplier = Color.redFloat;
		colorTransform.greenMultiplier = Color.greenFloat;
		colorTransform.blueMultiplier = Color.blueFloat;
		_canvas.transform.colorTransform = colorTransform;
		return Color;
	}
	
	override private function set_alpha(Alpha:Float):Float 
	{
		return _canvas.alpha = Alpha;
	}
	
	override private function set_angle(Angle:Float):Float 
	{
		if (flashSprite != null)
			flashSprite.rotation = Angle;
		
		return Angle;
	}
	
	override private function set_visible(visible:Bool):Bool 
	{
		if (flashSprite != null)
			flashSprite.visible = visible;
		
		return visible;
	}
	
	override function get_display():DisplayObjectContainer 
	{
		return flashSprite;
	}
	
	override function get_canvas():DisplayObjectContainer 
	{
		return _canvas;
	}
	
	// Draw stack related code...
	
	private static var DefaultColorMaterial:FlxMaterial = new FlxMaterial();
	
	/**
	 * Currently used draw stack item
	 */
	private var _currentCommand:FlxDrawHardwareCommand<Dynamic>;
	
	private var _singleTextureQuad:FlxDrawQuadsCommand = new FlxDrawQuadsCommand(true, 1);
	
	private var _singleColorQuad:FlxDrawQuadsCommand = new FlxDrawQuadsCommand(false, 1);
	
	/**
	 * Last draw tiles item
	 */
	private var _textureQuads:FlxDrawQuadsCommand = new FlxDrawQuadsCommand(true);
	/**
	 * Last draw tiles item
	 */
	private var _colorQuads:FlxDrawQuadsCommand = new FlxDrawQuadsCommand(false);
	/**
	 * Last draw triangles item
	 */
	private var _triangles:FlxDrawTrianglesCommand = new FlxDrawTrianglesCommand();
	
	private var _helperMatrix:FlxMatrix = new FlxMatrix();
	
	private inline function getTextureQuads(bitmap:BitmapData, material:FlxMaterial)
	{
		if (_currentCommand != null && _currentCommand != _textureQuads)
			_currentCommand.flush();
		
		_currentCommand = _textureQuads;
		return _textureQuads;
	}
	
	// TODO: request drawCommand (optimization for drawing sequence of quads with the same material)...
	
	private inline function getColorQuads(material:FlxMaterial)
	{
		if (_currentCommand != null && _currentCommand != _colorQuads)
			_currentCommand.flush();
		
		_currentCommand = _colorQuads;
		return _colorQuads;
	}
	
	private inline function getSingleTextureQuad(bitmap:BitmapData, material:FlxMaterial)
	{
		if (_currentCommand != null)
			_currentCommand.flush();
		
		_currentCommand = _singleTextureQuad;
		return _singleTextureQuad;
	}
	
	private inline function getSingleColorQuad(material:FlxMaterial)
	{
		if (_currentCommand != null)
			_currentCommand.flush();
		
		_currentCommand = _singleColorQuad;
		return _singleColorQuad;
	}
	
	private inline function getTriangles(bitmap:BitmapData, material:FlxMaterial):FlxDrawTrianglesCommand
	{
		if (_currentCommand != null)
			_currentCommand.flush();
		
		_currentCommand = null;  // i don't batch triangles...
		_triangles.set(bitmap, true, false, material);
		return _triangles;
	}
	
	override private inline function render():Void
	{
		if (_currentCommand != null)
			_currentCommand.flush();
	}
	
	// TODO: rename it to buffer...
	private function get_renderTexture():RenderTexture
	{
		if (_canvas != null)
			return _canvas.buffer;
		
		return null;
	}
	
}