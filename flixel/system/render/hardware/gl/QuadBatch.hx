package flixel.system.render.hardware.gl;

import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxFrame;
import flixel.graphics.shaders.tiles.FlxColored;
import flixel.graphics.shaders.tiles.FlxTextured;
import flixel.math.FlxMath;
import flixel.math.FlxMatrix;
import flixel.math.FlxRect;
import flixel.system.FlxAssets.FlxShader;
import flixel.system.render.common.DrawItem.FlxDrawItemType;
import flixel.system.render.common.FlxCameraView;
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
import openfl.geom.Matrix;
import openfl.gl.GL;
import openfl.gl.GLBuffer;
import lime.utils.ArrayBuffer;
import openfl.utils.ArrayBufferView;
import openfl.utils.Float32Array;

/**
 * ...
 * @author Zaphod
 */

// TODO: remove colored quads, colored tiles should be drawn only with triangles...

class QuadBatch extends FlxDrawHardwareItem<QuadBatch>
{
	public static inline var ELEMENTS_PER_VERTEX:Int = 6;
	
	public static var BATCH_SIZE:Int = 2000;
	
	/**
	 * Number of vertices per one quad.
	 */
	public static inline var VERTICES_PER_QUAD:Int = 4;
	/**
	 * Number of indices per one quad.
	 */
	public static inline var INDICES_PER_QUAD:Int = 6;
	
	public static inline var BYTES_PER_INDEX:Int = 2;
	
	/**
	 * Default tile shader.
	 */
	private static var defaultShader:FlxTextured = new FlxTextured();
	
	/**
	 * Helper array for storing uniform matrix coefficients.
	 */
	private static var uMatrix:Float32Array = new Float32Array(16);
	
	/**
	 * Helper array for storing color offsets.
	 */
	private static var uColorOffset:Array<Float> = [];
	
	
	/**
	 * Current texture being used by batch.
	 */
	
	// TODO: use these 2 vars for less state switches on gpu...
	private static var prevTexture:FlxGraphic;
	
	private static var prevShader:FlxGraphic;
	
	// TODO: use this method...
	public static function resetState():Void
	{
		prevTexture = null;
		prevShader = null;
	}
	
	public var roundPixels:Bool = false;
	
	/**
	 * The number of images in the SpriteBatch before it flushes.
	 */
	public var size(default, null):Int = 2000;
	
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
	
	/**
	 * Current number of quads in our batch.
	 */
	public var currentBatchSize(default, null):Int = 0;
	
	private var dirty:Bool = true;
	
	/**
	 * Array for holding render states in our batch...
	 */
	private var states:Array<RenderState> = [];
	
	private var vertexBuffer:GLBuffer;
	private var indexBuffer:GLBuffer;
	
	#if flash
	private var renderSession:Dynamic;
	#else
	private var renderSession:RenderSession;
	#end
	
	private var worldTransform:Matrix;
	
	private var gl:GLRenderContext;
	
	private var renderer:GLRenderer;
	
	public function new(size:Int = 2000) 
	{
		super();
		type = FlxDrawItemType.TILES;
		
		this.size = size;
		
		// The total number of bytes in our batch
		var numBytes:Int = size * Float32Array.BYTES_PER_ELEMENT * VERTICES_PER_QUAD * QuadBatch.ELEMENTS_PER_VERTEX;
		// The total number of indices in our batch
		var numIndices:Int = size * INDICES_PER_QUAD;
		
		vertices = new ArrayBuffer(numBytes);
		positions = new Float32Array(vertices);
		colors = new UInt32Array(vertices);
		indices = new UInt16Array(numIndices);
		
		var indexPos:Int = 0;
		var index:Int = 0;
		
		while (indexPos < numIndices)
		{
			this.indices[indexPos + 0] = index + 0;
			this.indices[indexPos + 1] = index + 1;
			this.indices[indexPos + 2] = index + 2;
			this.indices[indexPos + 3] = index + 1;
			this.indices[indexPos + 4] = index + 3;
			this.indices[indexPos + 5] = index + 2;
			
			indexPos += INDICES_PER_QUAD;
			index += VERTICES_PER_QUAD;
		}
		
		for (i in 0...size)
		{
			states[i] = new RenderState();
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
	
	#if flash
	override public function renderGL(worldTransform:Matrix, renderSession:Dynamic):Void
	#else
	override public function renderGL(worldTransform:Matrix, renderSession:RenderSession):Void
	#end
	{
		setContext(renderSession.gl);
		
		this.worldTransform = worldTransform;
		this.renderSession = renderSession;
		this.renderer = cast renderSession.renderer;
		
		start();
		stop();
	}
	
	public function end():Void
	{
		flush();
	}
	/*
	public function addColorQuad(rect:FlxRect, matrix:FlxMatrix, color:FlxColor, alpha:Float = 1.0, ?blend:BlendMode, ?smoothing:Bool, ?shader:FlxShader):Void
	{
		// check texture..
	//	if (currentBatchSize > size)
	//	{
	//		flush();
	//		currentTexture = texture;
	//	}
		
		var i = currentBatchSize * Float32Array.BYTES_PER_ELEMENT * elementsPerVertex;
		
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
			positions[i + 3] = w * a + intX;				// w * a + 0 * c + tx | 0;
			positions[i + 4] = w * b + intY;				// w * b + 0 * d + ty | 0;
			
			// xy
			positions[i + 6] = h * c + intX;				// 0 * a + h * c + tx | 0;
			positions[i + 7] = h * d + intY;				// 0 * b + h * d + ty | 0;
			
			// xy
			positions[i + 9] = w * a + h * c + intX;
			positions[i + 10] = w * b + h * d + intY;
		}
		else
		{
			// xy
			positions[i] = tx;
			positions[i + 1] = ty;
			
			// xy
			positions[i + 3] = w * a + tx;
			positions[i + 4] = w * b + ty;
			
			// xy
			positions[i + 6] = h * c + tx;
			positions[i + 7] = h * d + ty;
			
			// xy
			positions[i + 9] = w * a + h * c + tx;
			positions[i + 10] = w * b + h * d + ty;
		}
		
		color.alphaFloat = alpha;
		colors[i + 2] = colors[i + 5] = colors[i + 8] = colors[i + 11] = color;
		
		var state:RenderState = states[currentBatchSize];
		state.set(null, null, blend, false);
		
		currentBatchSize++;
	}
	*/
	override public function addQuad(frame:FlxFrame, matrix:FlxMatrix, ?transform:ColorTransform, ?blend:BlendMode, ?smoothing:Bool):Void
	{
		addUVQuad(frame.parent, frame.frame, frame.uv, matrix, transform, blend, smoothing);
	}
	
	override public function addUVQuad(texture:FlxGraphic, rect:FlxRect, uv:FlxRect, matrix:FlxMatrix, ?transform:ColorTransform, ?blend:BlendMode, ?smoothing:Bool):Void
	{
		/*
		// check texture..
		if (currentBatchSize > size)
		{
			flush();
			currentTexture = texture;
		}
		*/
		
		// get the uvs for the texture
		var uvx:Float = uv.x;
		var uvy:Float = uv.y;
		var uvx2:Float = uv.width;
		var uvy2:Float = uv.height;
		
		var i = currentBatchSize * Float32Array.BYTES_PER_ELEMENT * QuadBatch.ELEMENTS_PER_VERTEX;
		
		var w:Float = rect.width;
		var h:Float = rect.height;
		
		var a:Float = matrix.a;
		var b:Float = matrix.b;
		var c:Float = matrix.c;
		var d:Float = matrix.d;
		var tx:Float = matrix.tx;
		var ty:Float = matrix.ty;
		
		var intX:Int, intY:Int;
		
		// TODO: fix data indices...
		
		if (roundPixels)
		{
			intX = Std.int(tx);
			intY = Std.int(ty);
			
			// xy
			positions[i] = intX; 							// 0 * a + 0 * c + tx | 0;
			positions[i + 1] = intY; 						// 0 * b + 0 * d + ty | 0;
			
			// xy
			positions[i + 6] = w * a + intX;				// w * a + 0 * c + tx | 0;
			positions[i + 7] = w * b + intY;				// w * b + 0 * d + ty | 0;
			
			// xy
			positions[i + 12] = h * c + intX;				// 0 * a + h * c + tx | 0;
			positions[i + 13] = h * d + intY;				// 0 * b + h * d + ty | 0;
			
			// xy
			positions[i + 18] = w * a + h * c + intX;
			positions[i + 19] = w * b + h * d + intY;
		}
		else
		{
			// xy
			positions[i] = tx;
			positions[i + 1] = ty;
			
			// xy
			positions[i + 6] = w * a + tx;
			positions[i + 7] = w * b + ty;
			
			// xy
			positions[i + 12] = h * c + tx;
			positions[i + 13] = h * d + ty;
			
			// xy
			positions[i + 18] = w * a + h * c + tx;
			positions[i + 19] = w * b + h * d + ty;
		}
		
		// uv
		positions[i + 2] = uvx;
		positions[i + 3] = uvy;
		
		// uv
		positions[i + 8] = uvx2;
		positions[i + 9] = uvy;
		
		// uv
		positions[i + 14] = uvx;
		positions[i + 15] = uvy2;
		
		// uv
		positions[i + 20] = uvx2;
		positions[i + 21] = uvy2;
		
		var tint = 0xFFFFFF, color = 0xFFFFFFFF;
		
		if (transform != null)
		{
			tint = Std.int(transform.redMultiplier * 255) << 16 | Std.int(transform.greenMultiplier * 255) << 8 | Std.int(transform.blueMultiplier * 255);
			color = (Std.int(transform.alphaMultiplier * 255) & 0xFF) << 24 | tint;
		}
		
		colors[i + 4] = colors[i + 10] = colors[i + 16] = colors[i + 22] = color;
		
		// update color offsets
		if (transform != null)
		{
			tint = Std.int(transform.redOffset) << 16 | Std.int(transform.greenOffset) << 8 | Std.int(transform.blueOffset);
			color = (Std.int(transform.alphaOffset) & 0xFF) << 24 | tint;
		}
		
		colors[i + 5] = colors[i + 11] = colors[i + 17] = colors[i + 23] = color;
		
		var state:RenderState = states[currentBatchSize];
		state.set(texture, transform, blend, smoothing);
		
		currentBatchSize++;
	}
	
	private function flush():Void
	{
		if (currentBatchSize == 0)
			return;
		
		var batchSize:Int = 0;
		var startIndex:Int = 0;
		
		var state:RenderState = states[0];
		
		shader = getShader();
		renderSession.shaderManager.setShader(shader);
		onShaderSwitch();
		
		var currentTexture:FlxGraphic;
		var nextTexture:FlxGraphic;
		currentTexture = nextTexture = state.texture;
		
		var currentBlendMode:BlendMode;
		var nextBlendMode:BlendMode;
		currentBlendMode = nextBlendMode = state.blend;
		renderSession.blendModeManager.setBlendMode(currentBlendMode);
		
		var currentRedOffset:Float = 0.0;
		var currentGreenOffset:Float = 0.0;
		var currentBlueOffset:Float = 0.0;
		var currentAlphaOffset:Float = 0.0;
		
		var nextRedOffset:Float = 0.0;
		var nextGreenOffset:Float = 0.0;
		var nextBlueOffset:Float = 0.0;
		var nextAlphaOffset:Float = 0.0;
		
		currentRedOffset = nextRedOffset = 0.0;
		currentGreenOffset = nextGreenOffset = 0.0;
		currentBlueOffset = nextBlueOffset = 0.0;
		currentAlphaOffset = nextAlphaOffset = 0.0;
		
		uColorOffset[0] = uColorOffset[1] = uColorOffset[2] = uColorOffset[3] = 0.0;
		
		var blendSwap:Bool = false;
		var colorOffsetSwap:Bool = false;
		var textureSwap:Bool = false;
		
		for (i in 0...currentBatchSize)
		{
			state = states[i];
			
			nextTexture = state.texture;
			nextBlendMode = state.blend;
			
			nextRedOffset = state.redOffset;
			nextGreenOffset = state.greenOffset;
			nextBlueOffset = state.blueOffset;
			nextAlphaOffset = state.alphaOffset;
			
			blendSwap = (currentBlendMode != nextBlendMode);
			colorOffsetSwap = (currentRedOffset != nextRedOffset || currentGreenOffset != nextGreenOffset || currentBlueOffset != nextBlueOffset || currentAlphaOffset != nextAlphaOffset);
			textureSwap = (currentTexture != nextTexture);
			
			if (textureSwap || blendSwap || colorOffsetSwap)
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
			}
			
			batchSize++;
		}
		
		renderBatch(currentTexture, batchSize, startIndex);
		
		// then reset the batch!
		currentBatchSize = 0;
	}
	
	private inline function getShader():FlxShader
	{
		return (shader == null) ? defaultShader : shader;
	}
	
	private function onShaderSwitch():Void
	{
		if (dirty)
		{
			dirty = false;
			
			GL.bindBuffer(GL.ARRAY_BUFFER, vertexBuffer);
			GL.bindBuffer(GL.ELEMENT_ARRAY_BUFFER, indexBuffer);
			
			// this is the same for each shader?
			var stride:Int = QuadBatch.ELEMENTS_PER_VERTEX * Float32Array.BYTES_PER_ELEMENT;
			var offset:Int = 0;
			
			GL.vertexAttribPointer(shader.data.aPosition.index, 2, GL.FLOAT, false, stride, offset);
			offset += 2 * 4;
			
			GL.vertexAttribPointer(shader.data.aTexCoord.index, 2, GL.FLOAT, false, stride, offset);
			offset += 2 * 4;
			
			// color attributes will be interpreted as unsigned bytes and normalized
			GL.vertexAttribPointer(shader.data.aColor.index, 4, GL.UNSIGNED_BYTE, true, stride, offset);
			offset += 4;
			
			// TODO: quads also will have color offset attribute, so we'll need to activate it also...
			
			// color offsets will be interpreted as unsigned bytes and normalized
			GL.vertexAttribPointer(shader.data.aColorOffset.index, 4, GL.UNSIGNED_BYTE, true, stride, offset);
		}
		
		// upload the verts to the buffer  
		if (currentBatchSize > 0.5 * size)
		{
			GL.bufferSubData(GL.ARRAY_BUFFER, 0, positions);
		}
		else
		{
			var view = positions.subarray(0, currentBatchSize * Float32Array.BYTES_PER_ELEMENT * QuadBatch.ELEMENTS_PER_VERTEX);
			GL.bufferSubData(GL.ARRAY_BUFFER, 0, view);
		}
	}
	
	private function renderBatch(texture:FlxGraphic, size:Int, startIndex:Int):Void
	{
		if (size == 0)
			return;
		
		if (texture != null)
		{
			GL.activeTexture(GL.TEXTURE0);
			GL.bindTexture(GL.TEXTURE_2D, texture.bitmap.getTexture(gl));
			
			setTextureSmoothing(smoothing);
		}
		else
		{
			GL.activeTexture(GL.TEXTURE0);
			GL.bindTexture(GL.TEXTURE_2D, null);
		}
		
		// TODO: move this uniform setting code into default camera color transform filter...
	//	GL.uniform4f(shader.data.uColor.index, 1.0, 1.0, 1.0, 1.0);
	//	GL.uniform4f(shader.data.uColorOffset.index, uColorOffset[0], uColorOffset[1], uColorOffset[2], uColorOffset[3]);
		// end of todo...
		
		var matrix = renderer.getMatrix(worldTransform);
		var uMatrix:Matrix4 = GLRenderHelper.arrayToMatrix(matrix);
		GL.uniformMatrix4fv(shader.data.uMatrix.index, false, uMatrix);
		
		// now draw those suckas!
		GL.drawElements(GL.TRIANGLES, size * INDICES_PER_QUAD, GL.UNSIGNED_SHORT, startIndex * INDICES_PER_QUAD * BYTES_PER_INDEX);
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
		worldTransform = null;
	}
	
	override public function destroy():Void
	{
		super.destroy();
		
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
		worldTransform = null;
		gl = null;
		
		shader = null;
	}
	
	override public function equals(type:FlxDrawItemType, graphic:FlxGraphic, colored:Bool, hasColorOffsets:Bool = false,
		?blend:BlendMode, smooth:Bool = false, ?shader:FlxShader):Bool
	{
		var hasGraphic:Bool = (graphic != null);
		var bothHasGraphic:Bool = (hasGraphic == textured);
		var hasSameShader:Bool = (this.shader == shader);
		
		return bothHasGraphic && hasSameShader;
	}
	
	override public function set(graphic:FlxGraphic, colored:Bool, hasColorOffsets:Bool = false, ?blend:BlendMode, smooth:Bool = false, ?shader:FlxShader):Void 
	{
		super.set(graphic, colored, hasColorOffsets, blend, smooth, shader);
		
		textured = (graphic != null);
	}
}

class RenderState implements IFlxDestroyable
{
	public var blend:BlendMode;
	public var smoothing:Bool;
	public var texture:FlxGraphic;
	
	public var redOffset:Float;
	public var greenOffset:Float;
	public var blueOffset:Float;
	public var alphaOffset:Float;
	
	public var startIndex:Int = 0;
	public var size:Int = 0;
	
	public function new() {}
	
	public inline function set(texture:FlxGraphic, color:ColorTransform, blend:BlendMode, smooth:Bool = false):Void
	{
		this.texture = texture;
		this.smoothing = smooth;
		this.blend = blend;
		
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
	}
	
}