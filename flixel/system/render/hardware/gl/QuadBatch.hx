package flixel.system.render.hardware.gl;

import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxFrame;
import flixel.graphics.shaders.FlxTexturedShader;
import flixel.math.FlxMath;
import flixel.math.FlxMatrix;
import flixel.math.FlxRect;
import flixel.system.FlxAssets.FlxShader;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;
import flixel.util.FlxDestroyUtil.IFlxDestroyable;
import lime.graphics.GLRenderContext;
import lime.math.Matrix4;
import lime.utils.UInt16Array;
import lime.utils.UInt32Array;
import openfl._internal.renderer.RenderSession;
import openfl._internal.renderer.opengl.GLRenderer;
import openfl.display.BlendMode;
import openfl.display.DisplayObject;
import openfl.display.Shader;
import openfl.geom.ColorTransform;
import openfl.gl.GL;
import openfl.gl.GLBuffer;
import lime.utils.ArrayBuffer;
import openfl.utils.ArrayBufferView;
import openfl.utils.Float32Array;

/**
 * ...
 * @author Zaphod
 */
class QuadBatch implements IFlxDestroyable
{
	public static inline var BYTES_PER_ELEMENT:Int = 4;
	public static inline var VERTICES_PER_QUAD:Int = 4;
	public static inline var INDICES_PER_QUAD:Int = 6;
	
	private static var texturedTileShader:FlxTexturedShader;
	
	private static var uMatrix:Float32Array = new Float32Array(16);
	
	private static var uColorOffset:Array<Float> = [];
	
	/**
	 * Number of elements per vertex in spritebatch.
	 */
	public static inline var ELEMENTS_PER_VERTEX:Int = 5;
	
	public var roundPixels:Bool = false;
	
	/**
	 * The number of images in the SpriteBatch before it flushes.
	 */
	public var size(default, null):Int = 2000;
	
	/**
	 * The total number of bytes in our batch
	 */
	private var numBytes:Int;
	
	/**
	 * The total number of indices in our batch
	 */
	private var numIndices:Int;
	
	/**
	 * Holds the vertices data (positions, uvs, colors)
	 */
	private var vertices:ArrayBuffer;
	
	/**
	 * View on the vertices as a Float32Array
	 */
	private var positions:Float32Array;
	
	/**
	 * View on the vertices as a UInt32Array
	 */
	private var colors:UInt32Array;
	
	/**
	 * Holds the indices
	 */
	private var indices:UInt16Array;
	
	private var lastIndexCount:Int = 0;
	
	private var currentBatchSize:Int = 0;
	
	private var currentBaseTexture:FlxGraphic;
	
	private var dirty:Bool = true;
	
	private var states:Array<RenderState> = [];
	
	private var vertexBuffer:GLBuffer;
	private var indexBuffer:GLBuffer;
	
	private var renderSession:RenderSession;
	
	private var parent:DisplayObject;
	
	private var gl:GLRenderContext;
	
	private var renderer:GLRenderer;
	
	private var shader:FlxShader;
	
	public function new(size:Int = 2000) 
	{
		this.size = size;
		
		numBytes = size * BYTES_PER_ELEMENT * VERTICES_PER_QUAD * ELEMENTS_PER_VERTEX;
		numIndices = size * INDICES_PER_QUAD;
		
		vertices = new ArrayBuffer(numBytes);
		positions = new Float32Array(vertices);
		colors = new UInt32Array(vertices);
		indices = new UInt16Array(numIndices);
		
		var indexPos:Int, index:Int;
		for (i in 0...size)
		{
			indexPos = i * INDICES_PER_QUAD;
			index = i * VERTICES_PER_QUAD;
			indices[indexPos + 0] = index + 0;
			indices[indexPos + 1] = index + 1;
			indices[indexPos + 2] = index + 2;
			indices[indexPos + 3] = index + 2;
			indices[indexPos + 4] = index + 1;
			indices[indexPos + 5] = index + 3;
			
			states[i] = new RenderState();
		}
		
		if (texturedTileShader == null) 
		{
			texturedTileShader = new FlxTexturedShader();
		}
	}
	
	private function setContext(gl:GLRenderContext):Void
	{
		if (this.gl == null || this.gl != gl)
		{
			this.gl = gl;
			
			// create a couple of buffers
			vertexBuffer = GL.createBuffer();
			indexBuffer = GL.createBuffer();
			
			// 65535 is max index, so 65535 / 6 = 10922.
			
			//upload the index data
			GL.bindBuffer(GL.ELEMENT_ARRAY_BUFFER, indexBuffer);
			GL.bufferData(GL.ELEMENT_ARRAY_BUFFER, indices, GL.STATIC_DRAW);
			
			GL.bindBuffer(GL.ARRAY_BUFFER, vertexBuffer);
			GL.bufferData(GL.ARRAY_BUFFER, positions, GL.DYNAMIC_DRAW);
		}
	}
	
	public function begin(parent:DisplayObject, renderSession:RenderSession):Void
	{
		setContext(renderSession.gl);
		
		this.parent = parent;
		this.renderSession = renderSession;
		this.renderer = cast renderSession.renderer;
		
		start();
	}
	
	public function end():Void
	{
		flush();
	}
	
	public function addQuad(frame:FlxFrame, matrix:FlxMatrix, ?transform:ColorTransform, ?blend:BlendMode, ?smoothing:Bool, ?shader:FlxShader):Void
	{
		var texture:FlxGraphic = frame.parent;
		
		// check texture..
		if (currentBatchSize > size)
		{
			flush();
			currentBaseTexture = texture;
		}
		
		// get the uvs for the texture
		var uv:FlxRect = frame.uv;
		var uvx:Float = uv.x;
		var uvy:Float = uv.y;
		var uvx2:Float = uv.width;
		var uvy2:Float = uv.height;
		
		var i = currentBatchSize * BYTES_PER_ELEMENT * ELEMENTS_PER_VERTEX;
		
		var rect:FlxRect = frame.frame;
		var w:Float = rect.width;
		var h:Float = rect.height;
		
		var a:Float = matrix.a;
		var b:Float = matrix.b;
		var c:Float = matrix.c;
		var d:Float = matrix.d;
		var tx:Float = matrix.tx;
		var ty:Float = matrix.ty;
		
		var intX:Int, intY:Int;
		
		if (roundPixels)
		{
			intX = Std.int(tx);
			intY = Std.int(ty);
			
			// xy
			positions[i] = intX; 							// 0 * a + 0 * c + tx | 0;
			positions[i + 1] = intY; 						// 0 * b + 0 * d + ty | 0;
			
			// xy
			positions[i + 5] = w * a + intX;				// w * a + 0 * c + tx | 0;
			positions[i + 6] = w * b + intY;				// w * b + 0 * d + ty | 0;
			
			// xy
			positions[i + 10] = h * c + intX;				// 0 * a + h * c + tx | 0;
			positions[i + 11] = h * d + intY;				// 0 * b + h * d + ty | 0;
			
			// xy
			positions[i + 15] = w * a + h * c + intX;
			positions[i + 16] = w * b + h * d + intY;
		}
		else
		{
			// xy
			positions[i] = tx;
			positions[i + 1] = ty;
			
			// xy
			positions[i + 5] = w * a + tx;
			positions[i + 6] = w * b + ty;
			
			// xy
			positions[i + 10] = h * c + tx;
			positions[i + 11] = h * d + ty;
			
			// xy
			positions[i + 15] = w * a + h * c + tx;
			positions[i + 16] = w * b + h * d + ty;
		}
		
		// uv
		positions[i + 2] = uvx;
		positions[i + 3] = uvy;
		
		// uv
		positions[i + 7] = uvx2;
		positions[i + 8] = uvy;
		
		// uv
		positions[i + 12] = uvx;
		positions[i + 13] = uvy2;
		
		// uv
		positions[i + 17] = uvx2;
		positions[i + 18] = uvy2;
		
		var tint = 0xFFFFFF, color = 0xFFFFFFFF;
		
		if (transform != null)
		{
			tint = Std.int(transform.redMultiplier * 255) << 16 | Std.int(transform.greenMultiplier * 255) << 8 | Std.int(transform.blueMultiplier * 255);
			color = (Std.int(transform.alphaMultiplier * 255) & 0xFF) << 24 | tint;
		}
		
		colors[i + 4] = colors[i + 9] = colors[i + 14] = colors[i + 19] = color;
		
		var state:RenderState = states[currentBatchSize];
		state.set(frame.parent, transform, blend, smoothing, shader);
		
		currentBatchSize++;
	}
	
	private function flush():Void
	{
		if (currentBatchSize == 0)
		{
			return;
		}
		
		// TODO: fix this...
		shader = (states[0].shader != null) ? states[0].shader : texturedTileShader;
		
		if (dirty)
		{
			dirty = false;
			
			GL.bindBuffer(GL.ARRAY_BUFFER, vertexBuffer);
			GL.bindBuffer(GL.ELEMENT_ARRAY_BUFFER, indexBuffer);
			
			// this is the same for each shader?
			var stride:Int = ELEMENTS_PER_VERTEX * BYTES_PER_ELEMENT;
			
			GL.vertexAttribPointer(shader.data.aPosition.index, 2, GL.FLOAT, false, stride, 0);
			GL.vertexAttribPointer(shader.data.aTexCoord.index, 2, GL.FLOAT, false, stride, 2 * 4);
			
			// color attributes will be interpreted as unsigned bytes and normalized
			GL.vertexAttribPointer(shader.data.aColor.index, 4, gl.UNSIGNED_BYTE, true, stride, 4 * 4);
		}
		
		// upload the verts to the buffer  
		if (currentBatchSize > 0.5 * size)
		{
			GL.bufferSubData(GL.ARRAY_BUFFER, 0, positions);
		}
		else
		{
			var view = positions.subarray(0, currentBatchSize * BYTES_PER_ELEMENT * ELEMENTS_PER_VERTEX);
			GL.bufferSubData(GL.ARRAY_BUFFER, 0, view);
		}
		
		var nextTexture:FlxGraphic;
		var nextBlendMode:BlendMode;
		var nextShader:FlxShader;
		var batchSize:Int = 0;
		var startIndex:Int = 0;
		
		var nextRedOffset:Float = 0.0;
		var nextGreenOffset:Float = 0.0;
		var nextBlueOffset:Float = 0.0;
		var nextAlphaOffset:Float = 0.0;
		
		var currentTexture:FlxGraphic = null;
		var currentBlendMode:BlendMode = null;
		var currentShader:FlxShader = null;
		
		var currentRedOffset:Float = 0.0;
		var currentGreenOffset:Float = 0.0;
		var currentBlueOffset:Float = 0.0;
		var currentAlphaOffset:Float = 0.0;
		
		uColorOffset[0] = uColorOffset[1] = uColorOffset[2] = uColorOffset[3] = 0.0;
		
		var blendSwap:Bool = false;
		var shaderSwap:Bool = false;
		var colorOffsetSwap:Bool = false;
		var state:RenderState = null;
		
		for (i in 0...currentBatchSize)
		{
			state = states[i];
			
			nextTexture = state.texture;
			
			nextBlendMode = state.blend;
			nextShader = (state.shader != null) ? state.shader : texturedTileShader;
			
			nextRedOffset = state.redOffset;
			nextGreenOffset = state.greenOffset;
			nextBlueOffset = state.blueOffset;
			nextAlphaOffset = state.alphaOffset;
			
			blendSwap = (currentBlendMode != nextBlendMode);
			shaderSwap = (currentShader != nextShader);
			colorOffsetSwap = (currentRedOffset != nextRedOffset || currentGreenOffset != nextGreenOffset || currentBlueOffset != nextBlueOffset || currentAlphaOffset != nextAlphaOffset);
			
			if ((currentTexture != nextTexture) || blendSwap || shaderSwap || colorOffsetSwap)
			{
				renderBatch(currentTexture, batchSize, startIndex);
				
				startIndex = i;
				batchSize = 0;
				currentTexture = nextTexture;
				
				if (blendSwap)
				{
					currentBlendMode = nextBlendMode;
					this.renderSession.blendModeManager.setBlendMode(currentBlendMode);
				}
				
				if (colorOffsetSwap)
				{
					currentRedOffset = nextRedOffset;
					currentGreenOffset = nextGreenOffset;
					currentBlueOffset = nextBlueOffset;
					currentAlphaOffset = nextAlphaOffset;
					
					uColorOffset[0] = currentRedOffset;
					uColorOffset[1] = currentGreenOffset;
					uColorOffset[2] = currentBlueOffset;
					uColorOffset[3] = currentAlphaOffset;
				}
				
				if (shaderSwap)
				{
					shader = currentShader = nextShader;
					
					// set shader function???
					renderSession.shaderManager.setShader(shader);
				}
			}
			
			batchSize++;
		}
		
		renderBatch(currentTexture, batchSize, startIndex);
		
		// then reset the batch!
		currentBatchSize = 0;
	}
	
	private function renderBatch(texture:FlxGraphic, size:Int, startIndex:Int):Void
	{
		if (size == 0)
		{
			return;
		}
		
		GL.bindTexture(GL.TEXTURE_2D, texture.bitmap.getTexture(gl));
		
		GL.uniform4f(shader.data.uColor.index, 1.0, 1.0, 1.0, 1.0);
		GL.uniform4f(shader.data.uColorOffset.index, uColorOffset[0], uColorOffset[1], uColorOffset[2], uColorOffset[3]);
		
		var matrix = renderer.getMatrix(parent.__worldTransform);
		var uMatrix:Matrix4 = GLRenderHelper.arrayToMatrix(matrix);
		
		GL.uniformMatrix4fv(shader.data.uMatrix.index, false, uMatrix);
		
		// now draw those suckas!
		GL.drawElements(GL.TRIANGLES, size * INDICES_PER_QUAD, GL.UNSIGNED_SHORT, startIndex * INDICES_PER_QUAD * 2);
		
		// increment the draw count
		this.renderSession.drawCount++;
	}
	
	public function start():Void
	{
		dirty = true;
	}
	
	public function stop():Void
	{
		flush();
		
		dirty = true;
		renderSession = null;
		renderer = null;
		parent = null;
	}
	
	public function destroy():Void
	{
		vertices = null;
		indices = null;
		
		positions = null;
		colors = null;
		
		if (vertexBuffer != null)
		{
			GL.deleteBuffer(vertexBuffer);
			vertexBuffer = null;
		}
		
		if (indexBuffer != null)
		{
			GL.deleteBuffer(indexBuffer);
			indexBuffer = null;
		}
		
		states = FlxDestroyUtil.destroyArray(states);
		
		renderSession = null;
		renderer = null;
		parent = null;
		gl = null;
		
		shader = null;
	}
	
}

class RenderState implements IFlxDestroyable
{
	public var blend:BlendMode;
	public var smoothing:Bool;
	public var texture:FlxGraphic;
	public var shader:FlxShader;
	public var redOffset:Float;
	public var greenOffset:Float;
	public var blueOffset:Float;
	public var alphaOffset:Float;
	
	public var startIndex:Int = 0;
	public var size:Int = 0;
	
	public function new() {}
	
	public inline function set(texture:FlxGraphic, color:ColorTransform, blend:BlendMode, smooth:Bool = false, ?shader:FlxShader):Void
	{
		this.texture = texture;
		this.smoothing = smooth;
		this.blend = blend;
		this.shader = shader;
		
		if (color != null)
		{
			this.redOffset = color.redOffset / 255;
			this.greenOffset = color.greenOffset / 255;
			this.blueOffset = color.blueOffset / 255;
			this.alphaOffset = color.alphaOffset / 255;
		}
		else
		{
			this.redOffset = 0;
			this.greenOffset = 0;
			this.blueOffset = 0;
			this.alphaOffset = 0;
		}
	}
	
	public function destroy():Void
	{
		this.texture = null;
		this.blend = null;
		this.shader = null;
	}
	
}