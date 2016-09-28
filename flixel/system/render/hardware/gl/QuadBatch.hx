package flixel.system.render.hardware.gl;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxFrame;
import flixel.math.FlxMatrix;
import flixel.math.FlxRect;
import flixel.system.FlxAssets.FlxShader;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil.IFlxDestroyable;
import lime.graphics.GLRenderContext;
import lime.utils.UInt16Array;
import lime.utils.UInt32Array;
import openfl._internal.renderer.RenderSession;
import openfl.display.BlendMode;
import openfl.display.Shader;
import openfl.geom.ColorTransform;
import openfl.gl.GL;
import openfl.gl.GLBuffer;
import openfl.utils.ArrayBuffer;
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
	
	/**
	 * Number of elements per vertex in spritebatch.
	 */
	public static inline var ELEMENTS_PER_VERTEX(default, never):Int = 5;
	
	public var roundPixels:Bool = false;
	
	/**
	 * The number of images in the SpriteBatch before it flushes.
	 */
	public var size(default, null):Int = 2000;
	
	/**
	 * The total number of bytes in our batch
	 */
	private var numVertices:Int; // TODO: rename it to something like numBytes...
	
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
	
	private var drawing:Bool = false;
	
	private var currentBatchSize:Int = 0;
	
	private var currentBaseTexture:FlxGraphic;
	
	private var dirty:Bool = true;
	
	private var textures:Array<FlxGraphic> = [];
	
	private var blendModes:Array<BlendMode> = [];
	
	private var shaders:Array<Shader> = [];
	
	private var gl:GLRenderContext;
	
	private var vertexBuffer:GLBuffer;
	private var indexBuffer:GLBuffer;
	
	private var renderSession:RenderSession;
	
	public function new(size:Int = 2000) 
	{
		this.size = size;
		
		numVertices = size * BYTES_PER_ELEMENT * VERTICES_PER_QUAD * ELEMENTS_PER_VERTEX;
		numIndices = size * INDICES_PER_QUAD;
		
		vertices = new ArrayBuffer(numVertices);
		positions = new Float32Array(vertices);
		colors = new UInt32Array(vertices);
		indices = new UInt16Array(numIndices);
		
		var indexPos:Int, index:Int;
		for (i in 0...size) //, j=0; i < numIndices; i += 6, j += 4)
		{
			indexPos = i * INDICES_PER_QUAD;
			index = i * VERTICES_PER_QUAD;
			indices[indexPos + 0] = index + 0;
			indices[indexPos + 1] = index + 1;
			indices[indexPos + 2] = index + 2;
			indices[indexPos + 3] = index + 0;
			indices[indexPos + 4] = index + 2;
			indices[indexPos + 5] = index + 3;
		}
	}
	
	private function setContext(gl:GLRenderContext):Void
	{
		if (this.gl == null || this.gl != gl)
		{
			// TODO: clean previous data if there was some...
			
			this.gl = gl;
			
			// create a couple of buffers
			vertexBuffer = GL.createBuffer();
			indexBuffer = GL.createBuffer();
			
			// 65535 is max index, so 65535 / 6 = 10922.
			
			//upload the index data
			GL.bindBuffer(GL.ELEMENT_ARRAY_BUFFER, indexBuffer);
			GL.bufferData(GL.ELEMENT_ARRAY_BUFFER, indices, GL.STATIC_DRAW);
			
			GL.bindBuffer(GL.ARRAY_BUFFER, vertexBuffer);
			GL.bufferData(GL.ARRAY_BUFFER, vertices, GL.DYNAMIC_DRAW);
			
			// TODO: create shaders...
			
		}
	}
	
	private function begin(renderSession:RenderSession):Void
	{
		this.renderSession = renderSession;
	//	this.shader = this.renderSession.shaderManager.defaultShader;
		start();
	}
	
	private function end():Void
	{
		flush();
	}
	
	public function addQuad(frame:FlxFrame, matrix:FlxMatrix, ?transform:ColorTransform):Void
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
		
		if (roundPixels)
		{
			// xy
			positions[i] = tx | 0; 							// 0 * a + 0 * c + tx | 0;
			positions[i + 1] = ty | 0; 						// 0 * b + 0 * d + ty | 0;
			
			// xy
			positions[i + 5] = w * a + tx | 0;				// w * a + 0 * c + tx | 0;
			positions[i + 6] = w * b + ty | 0;				// w * b + 0 * d + ty | 0;
			
			// xy
			positions[i + 10] = h * c + tx | 0;				// 0 * a + h * c + tx | 0;
			positions[i + 11] = h * d + ty | 0;				// 0 * b + h * d + ty | 0;
			
			// xy
			positions[i + 15] = w * a + h * c + tx | 0;
			positions[i + 16] = w * b + h * d + ty | 0;
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
			positions[i + 15] = w * a + h * c + tx | 0;
			positions[i + 16] = w * b + h * d + ty | 0;
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
		
		// TODO: continue from here...
		
		var r:Float = 1.0;
		var g:Float = 1.0;
		var b:Float = 1.0;
		var a:Float = 1.0;
		
		if (transform != null)
		{
			if (colored)
			{
				r = transform.redMultiplier;
				g = transform.greenMultiplier;
				b = transform.blueMultiplier;
			}
			
			a = transform.alphaMultiplier;
		}
		
		colors[i + 4] = colors[i + 9] = colors[i + 14] = colors[i + 19] = FlxColor.fromRGBFloat(r, g, b, a);
		
		currentBatchSize++;
	}
	
	private function flush():Void
	{
		if (currentBatchSize == 0)
		{
			return;
		}
		
		if (dirty)
		{
			dirty = false;
			
			// TODO: set shader here...
			
			GL.bindBuffer(GL.ARRAY_BUFFER, vertexBuffer);
			GL.bindBuffer(GL.ELEMENT_ARRAY_BUFFER, indexBuffer);
			
			// this is the same for each shader?
			var stride:Int = ELEMENTS_PER_VERTEX * BYTES_PER_ELEMENT;
			
			GL.vertexAttribPointer(shader.data.aVertexPosition.index, 2, GL.FLOAT, false, stride, 0);
			GL.vertexAttribPointer(shader.data.aTextureCoord.index, 2, GL.FLOAT, false, stride, 2 * 4);
		}
		
		// upload the verts to the buffer  
		if (currentBatchSize > 0.5 * size)
		{
			GL.bufferSubData(GL.ARRAY_BUFFER, 0, vertices);
		}
		else
		{
			var view = positions.subarray(0, currentBatchSize * BYTES_PER_ELEMENT * ELEMENTS_PER_VERTEX);
			GL.bufferSubData(GL.ARRAY_BUFFER, 0, view);
		}
		
		// TODO: continue from here...
		
		var nextTexture:FlxGraphic;
		var nextBlendMode:BlendMode;
		var nextShader:FlxShader;
		var batchSize:Int = 0;
		var start:Int = 0;
		
		var currentBaseTexture:FlxGraphic = null;
		var currentBlendMode:BlendMode = null;
		var currentShader:FlxShader = null;
		
		var blendSwap:Bool = false;
		var shaderSwap:Bool = false;
		var sprite;
		
		for (var i = 0, j = this.currentBatchSize; i < j; i++) {
			
			sprite = this.sprites[i];
			
			if (sprite.tilingTexture)
			{
				nextTexture = sprite.tilingTexture.baseTexture;
			}
			else
			{
				nextTexture = sprite.texture.baseTexture;
			}
			
			nextBlendMode = sprite.blendMode;
			nextShader = sprite.shader || this.defaultShader;
			
			blendSwap = currentBlendMode !== nextBlendMode;
			shaderSwap = currentShader !== nextShader; // should I use _UIDS???
			
			var skip = nextTexture.skipRender;
			
			if (skip && sprite.children.length > 0)
			{
				skip = false;
			}
			
			if ((currentBaseTexture !== nextTexture && !skip) || blendSwap || shaderSwap)
			{
				this.renderBatch(currentBaseTexture, batchSize, start);
				
				start = i;
				batchSize = 0;
				currentBaseTexture = nextTexture;
				
				if (blendSwap)
				{
					currentBlendMode = nextBlendMode;
					this.renderSession.blendModeManager.setBlendMode(currentBlendMode);
				}
				
				if (shaderSwap)
				{
					currentShader = nextShader;
					
					shader = currentShader.shaders[gl.id];
					
					if (!shader)
					{
						shader = new PIXI.PixiShader(gl);
						
						shader.fragmentSrc = currentShader.fragmentSrc;
						shader.uniforms = currentShader.uniforms;
						shader.init();
						
						currentShader.shaders[gl.id] = shader;
					}
					
					// set shader function???
					this.renderSession.shaderManager.setShader(shader);
					
					if (shader.dirty)
					{
						shader.syncUniforms();
					}
					
					// both these only need to be set if they are changing..
					// set the projection
					var projection = this.renderSession.projection;
					gl.uniform2f(shader.projectionVector, projection.x, projection.y);
					
					// TODO - this is temporary!
					var offsetVector = this.renderSession.offset;
					gl.uniform2f(shader.offsetVector, offsetVector.x, offsetVector.y);
					
					// set the pointers
				}
			}
			
			batchSize++;
		}
		
		this.renderBatch(currentBaseTexture, batchSize, start);
		
		// then reset the batch!
		currentBatchSize = 0;
	}
	
	private function renderBatch(texture, size, startIndex):Void
	{
		if (size === 0)
		{
			return;
		}
		
		var gl = this.gl;
		
		// check if a texture is dirty..
		if (texture._dirty[gl.id])
		{
			if (!this.renderSession.renderer.updateTexture(texture))
			{
				//  If updateTexture returns false then we cannot render it, so bail out now
				return;
			}
		}
		else
		{
			// bind the current texture
			gl.bindTexture(gl.TEXTURE_2D, texture._glTextures[gl.id]);
		}
		
		// now draw those suckas!
		gl.drawElements(gl.TRIANGLES, size * 6, gl.UNSIGNED_SHORT, startIndex * 6 * 2);
		
		// increment the draw count
		this.renderSession.drawCount++;
	}
	
	private function start():Void
	{
		dirty = true;
	}
	
	private function stop():Void
	{
		flush();
		dirty = true;
	}
	
	public function destroy():Void
	{
		vertices = null;
		indices = null;
		
		positions = null;
		colors = null;
		
		/*
		this.gl.deleteBuffer(this.vertexBuffer);
		this.gl.deleteBuffer(this.indexBuffer);
		
		this.currentBaseTexture = null;
		
		
		*/
		
		gl = null;
	}
	
}

class RenderState
{
	public var blend:BlendMode;
	public var smoothing:Bool;
	public var texture:FlxGraphic;
	public var shader:FlxShader;
	public var redOffset:Float;
	public var greenOffset:Float;
	public var blueOffset:Float;
	public var alphaOffset:Float;
	
	public inline function equals(texture:FlxGraphic, color:ColorTransform, blend:BlendMode, smooth:Bool = false, ?shader:FlxShader):Bool
	{
		return (this.texture == texture 
			&& this.blend == blend
			&& this.smoothing == smooth
			&& this.shader == shader
			&& this.redOffset == color.redOffset
			&& this.greenOffset == color.greenOffset
			&& this.blueOffset == color.blueOffset
			&& this.alphaOffset = color.alphaOffset);
	}
	
	public inline function set(texture:FlxGraphic, color:ColorTransform, blend:BlendMode, smooth:Bool = false, ?shader:FlxShader):Void
	{
		this.texture = texture;
		this.smoothing = smooth;
		this.blend = blend;
		this.shader = shader;
		
		this.redOffset = color.redOffset;
		this.greenOffset = color.greenOffset;
		this.blueOffset = color.blueOffset;
		this.alphaOffset = color.alphaOffset;
	}
}