package flixel.system.render.gl;

import flixel.system.render.common.FlxDrawBaseItem;
import lime.graphics.GLRenderContext;
import lime.utils.Float32Array;
import lime.utils.UInt32Array;
import openfl.display.BitmapData;
import openfl.display.BlendMode;
import openfl.display.DisplayObject;
import openfl.display.Shader;
import openfl.geom.Matrix;
import openfl.geom.Rectangle;

#if !display
import openfl._internal.renderer.RenderSession;
import openfl._internal.renderer.opengl.GLRenderer;
#end

/**
 * ...
 * @author Yanrishatum
 */
class HardwareRenderer extends DisplayObject
{
	public static inline var ELEMENTS_PER_TILE:Int = 8 * 4;
	public static inline var MINIMUM_TILE_COUNT_PER_BUFFER:Int = 10;
	public static inline var BYTES_PER_ELEMENT:Int = 4;
	private static var shader:TileShader;

	private var states:Array<FlxDrawQuadsItem>;
//	private var stateBuffers:Array<AtlasData>;
//	private var stateCounts:Array<Int>;
//	private var stateOffsets:Array<Int>;
	private var stateNum:Int;
	
	#if !flash
	private var __height:Int;
	private var __width:Int;
	#end

	public function new(width:Int, height:Int)
	{
		super();
		
		#if !flash
		__width = width;
		__height = height;
		#end
		
		if (shader == null) 
			shader = new TileShader();
		
		states = [];
	//	stateTextures = new Array();
	//	stateBuffers = new Array();
	//	stateCounts = new Array();
	//	stateOffsets = new Array();
		stateNum = 0;
	}

	public function clear():Void
	{
		// TODO: clear states...
		stateNum = 0;
	}

	public function drawItem(item:FlxDrawQuadsItem):Void
	{
		states[stateNum++] = item;
		
		// TODO: move this code into FlxDrawQuadItem...
		/*
		states[stateNum] = state;
		stateCounts[stateNum] = state.count * 6;
		stateTextures[stateNum] = state.texture;
		stateBuffers[stateNum] = state.data;
		stateOffsets[stateNum] = state.offset * 6 * 4;
		stateNum++;
		*/
	}
	
	#if !flash
	@:access(openfl.geom.Rectangle)
	override private function __getBounds(rect:Rectangle, matrix:Matrix):Void 
	{
		var bounds = Rectangle.__temp;
		bounds.setTo(0, 0, __width, __height);
		bounds.__transform(bounds, matrix);
		rect.__expand(bounds.x, bounds.y, bounds.width, bounds.height);	
	}
	
	override private function __hitTest(x:Float, y:Float, shapeFlag:Bool, stack:Array<DisplayObject>, interactiveOnly:Bool, hitObject:DisplayObject):Bool 
	{
		if (!hitObject.visible || __isMask) 
			return false;
		
		if (mask != null && !mask.__hitTestMask(x, y))
			return false;
		
		__getWorldTransform();
		
		var px = __worldTransform.__transformInverseX(x, y);
		var py = __worldTransform.__transformInverseY(x, y);
		
		if (px > 0 && py > 0 && px <= __width && py <= __height) 
		{
			if (stack != null && !interactiveOnly) 
			{
				stack.push (hitObject);	
			}
			
			return true;
		}
		
		return false;
		
	}
	
	override private function get_height():Float 
	{	
		return __height;	
	}
	
	override private function set_height(value:Float):Float 
	{	
		return __height = Std.int(value);	
	}
	
	override private function get_width():Float 
	{	
		return __width;	
	}
	
	override private function set_width(value:Float):Float 
	{	
		return __width = Std.int(value);	
	}
	
	override public function __renderGL(renderSession:RenderSession):Void 
	{
		var gl:GLRenderContext = renderSession.gl;
		var renderer:GLRenderer = cast renderSession.renderer;
		
		renderSession.shaderManager.setShader(shader);
		gl.uniform1f(shader.data.uAlpha.index, this.__worldAlpha);
		gl.uniformMatrix4fv(shader.data.uMatrix.index, false, renderer.getMatrix(this.__worldTransform));
		
		var blend:BlendMode = null;
		var texture:BitmapData = null;
		
		var i:Int = 0;
		
		// TODO: reset stateNum also...
		
		while (i < stateNum)
		{
			var state:FlxDrawQuadsItem = states[i];
			
			if (blend != state.blending)
			{
				renderSession.blendModeManager.setBlendMode(state.blending);
				blend = state.blending;
			}
			
			if (texture != state.graphics.bitmap)
			{
				texture = state.graphics.bitmap;
				gl.bindTexture(gl.TEXTURE_2D, texture.getTexture(gl));
			}
			
			if (texture != null)
			{
				if (state.antialiasing) 
				{
					gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR);
					gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR);	
				} 
				else 
				{
					gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST);
					gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST);
				}
			}
			
			if (state.glBuffer == null)
			{
				state.glBuffer = gl.createBuffer();
				state.glIndexes = gl.createBuffer();
			}
			
			gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, state.glIndexes);
			
			if (state.indexBufferDirty)
			{
				state.indexBufferDirty = false;
				gl.bufferData(gl.ELEMENT_ARRAY_BUFFER, state.indexes, gl.DYNAMIC_DRAW);
			}
			
			gl.bindBuffer(gl.ARRAY_BUFFER, state.glBuffer);
			
			if (state.vertexBufferDirty)
			{
				state.vertexBufferDirty = false;
				gl.bufferData(gl.ARRAY_BUFFER, state.buffer, gl.DYNAMIC_DRAW);
			}
			
			gl.vertexAttribPointer(shader.data.aPosition.index, 2, gl.FLOAT, false, 8 * Float32Array.BYTES_PER_ELEMENT, 0);
			gl.vertexAttribPointer(shader.data.aTexCoord.index, 2, gl.FLOAT, false, 8 * Float32Array.BYTES_PER_ELEMENT, 2 * Float32Array.BYTES_PER_ELEMENT);
			gl.vertexAttribPointer(shader.data.aColor.index, 4, gl.FLOAT, false, 8 * Float32Array.BYTES_PER_ELEMENT, 4 * Float32Array.BYTES_PER_ELEMENT);
			
		//	gl.drawElements(gl.TRIANGLES, stateCounts[i], gl.UNSIGNED_INT, stateOffsets[i]);
			gl.drawElements(gl.TRIANGLES, state.indexCount, gl.UNSIGNED_INT, 0);
			
			i++;
		}
	}
	#end
	
}