package flixel.system.render.hardware.gl;

import flixel.graphics.FlxGraphic;
import flixel.graphics.shaders.triangles.FlxTexturedColored;
import flixel.system.FlxAssets.FlxShader;
import flixel.system.render.common.DrawItem.DrawData;
import flixel.system.render.common.DrawItem.FlxDrawItemType;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;
import flixel.util.FlxDestroyUtil.IFlxDestroyable;
import openfl.display.BlendMode;
import openfl.display.DisplayObject;
import openfl.geom.Matrix;

#if FLX_RENDER_GL
import lime.math.Matrix4;
import lime.utils.UInt16Array;
import lime.utils.UInt32Array;
import openfl.gl.GL;
import openfl.gl.GLBuffer;
import openfl.utils.Float32Array;
import lime.graphics.GLRenderContext;
import openfl._internal.renderer.RenderSession;
import openfl._internal.renderer.opengl.GLRenderer;
#end

/**
 * ...
 * @author ...
 */

class TrianglesData implements IFlxDestroyable
{
	public var numIndices(get, null):Int;
	
	public var dirty(default, set):Bool = true;
	
	public var verticesDirty:Bool = true;
	public var uvtDirty:Bool = true;
	public var colorsDirty:Bool = true;
	public var indicesDirty:Bool = true;
	
	public var vertices(default, set):DrawData<Float> = new DrawData<Float>();
	public var uvs(default, set):DrawData<Float> = new DrawData<Float>();
	public var colors(default, set):DrawData<FlxColor> = new DrawData<FlxColor>();
	public var indices(default, set):DrawData<Int> = new DrawData<Int>();
	
	private var verticesArray:Float32Array;
	private var uvsArray:Float32Array;
	private var colorsArray:UInt32Array;
	private var indicesArray:UInt16Array;
	
	private var verticesBuffer:GLBuffer;
	private var uvsBuffer:GLBuffer;
	private var colorsBuffer:GLBuffer;
	private var indicesBuffer:GLBuffer;
	
	private var gl:GLRenderContext;
	
	public function new()
	{
		
	}
	
	public function destroy():Void
	{
		gl = null;
		
		vertices = null;
		uvs = null;
		colors = null;
		indices = null;
		
		verticesArray = null;
		uvsArray = null;
		colorsArray = null;
		indicesArray = null;
		
		verticesBuffer = FlxDestroyUtil.destroyBuffer(verticesBuffer);
		uvsBuffer = FlxDestroyUtil.destroyBuffer(uvsBuffer);
		colorsBuffer = FlxDestroyUtil.destroyBuffer(colorsBuffer);
		indicesBuffer = FlxDestroyUtil.destroyBuffer(indicesBuffer);
	}
	
	public function setContext(gl:GLRenderContext):Void
	{
		if (this.gl == null || this.gl != gl)
		{
			this.gl = gl;
			
			verticesBuffer = GL.createBuffer();
			uvsBuffer = GL.createBuffer();
			colorsBuffer = GL.createBuffer();
			indicesBuffer = GL.createBuffer();
			/*
			GL.bindBuffer(GL.ARRAY_BUFFER, verticesBuffer);
			GL.bufferData(GL.ARRAY_BUFFER, verticesArray, GL.DYNAMIC_DRAW);
			
			GL.bindBuffer(GL.ARRAY_BUFFER, uvsBuffer);
			GL.bufferData(GL.ARRAY_BUFFER, uvsArray, GL.STATIC_DRAW);
			
			GL.bindBuffer(GL.ARRAY_BUFFER, colorsBuffer);
			GL.bufferData(GL.ARRAY_BUFFER, colorsArray, GL.STATIC_DRAW);
			
			GL.bindBuffer(GL.ELEMENT_ARRAY_BUFFER, indicesBuffer);
			GL.bufferData(GL.ELEMENT_ARRAY_BUFFER, indicesArray, GL.STATIC_DRAW);
			*/
		}
	}
	
	private function set_vertices(value:DrawData<Float>):DrawData<Float>
	{
		verticesDirty = verticesDirty || (value != null);
		return vertices = value;
	}
	
	public function updateVertices():Void
	{
		if (vertices == null)
			return;
		
		if (verticesDirty)
		{
			if (verticesArray == null || verticesArray.length != vertices.length)
				verticesArray = new Float32Array(vertices.length);
			
			for (i in 0...vertices.length)
				verticesArray[i] = vertices[i];
			
			GL.bindBuffer(GL.ARRAY_BUFFER, verticesBuffer);
			GL.bufferData(GL.ARRAY_BUFFER, verticesArray, GL.STATIC_DRAW);
			verticesDirty = false;
		}
		else
		{
			GL.bindBuffer(GL.ARRAY_BUFFER, verticesBuffer);
			GL.bufferSubData(GL.ARRAY_BUFFER, 0, verticesArray);
		}
	}
	
	private function set_uvs(value:DrawData<Float>):DrawData<Float>
	{
		uvtDirty = uvtDirty || (value != null);
		return uvs = value;
	}
	
	public function updateUV():Void
	{
		if (uvs == null)
			return;
		
		if (uvtDirty)
		{
			if (uvsArray == null || uvsArray.length != uvs.length)
				uvsArray = new Float32Array(uvs.length);
			
			for (i in 0...uvs.length)
				uvsArray[i] = uvs[i];
			
			GL.bindBuffer(GL.ARRAY_BUFFER, uvsBuffer);
			GL.bufferData(GL.ARRAY_BUFFER, uvsArray, GL.STATIC_DRAW);
			uvtDirty = false;
		}
		else
		{
			GL.bindBuffer(GL.ARRAY_BUFFER, uvsBuffer);
		}
	}
	
	private function set_colors(value:DrawData<FlxColor>):DrawData<FlxColor>
	{
		colorsDirty = colorsDirty || (value != null);
		return colors = value;
	}
	
	public function updateColors():Void
	{
		if (colors == null)
			return;
		
		if (colorsDirty)
		{
			if (colorsArray == null || colorsArray.length != colors.length)
				colorsArray = new UInt32Array(colors.length);
			
			for (i in 0...colors.length)
				colorsArray[i] = colors[i];
			
			// update the colors
			GL.bindBuffer(GL.ARRAY_BUFFER, colorsBuffer);
			GL.bufferData(GL.ARRAY_BUFFER, colorsArray, GL.STATIC_DRAW);
			colorsDirty = false;
		}
		else
		{
			GL.bindBuffer(GL.ARRAY_BUFFER, colorsBuffer);
		}
	}
	
	private function set_indices(value:DrawData<Int>):DrawData<Int>
	{
		indicesDirty = indicesDirty || (value != null);
		return indices = value;
	}
	
	public function updateIndices():Void
	{
		if (indices == null)
			return;
		
		if (indicesDirty)
		{
			if (indicesArray == null || indicesArray.length != indices.length)
				indicesArray = new UInt16Array(indices.length);
			
			for (i in 0...indices.length)
				indicesArray[i] = indices[i];
			
			GL.bindBuffer(GL.ELEMENT_ARRAY_BUFFER, indicesBuffer);
			GL.bufferData(GL.ELEMENT_ARRAY_BUFFER, indicesArray, GL.STATIC_DRAW);
			indicesDirty = false;
		}
		else
		{
			// dont need to upload!
			GL.bindBuffer(GL.ELEMENT_ARRAY_BUFFER, indicesBuffer);
		}
	}
	
	private function set_dirty(value:Bool):Bool
	{
		verticesDirty = uvtDirty = colorsDirty = indicesDirty = value;
		return dirty = value;
	}
	
	private function get_numIndices():Int
	{
		return (indicesArray != null) ? indicesArray.length : 0;
	}
}
 
class Triangles extends FlxDrawHardwareItem<Triangles>
{
	private static var matrix4:Matrix4 = new Matrix4();
	
	private static var defaultShader:FlxTexturedColored = new FlxTexturedColored();
	
	public var blendMode:BlendMode;
	
	private var worldTransform:Matrix;
	
	public var data:TrianglesData;
	
	/**
	 * Transformation matrix for this item on camera.
	 */
	public var matrix:Matrix;
	
	public function new() 
	{
		super();
		type = FlxDrawItemType.TRIANGLES;
	}
	
	override public function destroy():Void
	{
		worldTransform = null;
		
		shader = null;
		blendMode = null;
		
		data = null;
	}
	
	#if flash
	override public function renderGL(worldTransform:Matrix, renderSession:Dynamic):Void
	#else
	override public function renderGL(worldTransform:Matrix, renderSession:RenderSession):Void
	#end
	{
		this.worldTransform = worldTransform;
		
		// init! init!
		setContext(renderSession.gl);
		
		shader = getShader();
		renderSession.shaderManager.setShader(shader);
		
		renderStrip(renderSession);
	}
	
	private function getShader():FlxShader
	{
		if (shader == null)
		{
			// TODO: implement special strip shader with colors on and off...
			// TODO: and with texture and without...
			
			// TODO: add method for getting default shader based on this item values...
			shader = defaultShader;
		}
		
		return shader;
	}
	
	#if flash
	private function renderStrip(renderSession:Dynamic):Void
	#else
	private function renderStrip(renderSession:RenderSession):Void
	#end
	{
		if (graphics != null)
		{
			GL.activeTexture(GL.TEXTURE0);
			GL.bindTexture(GL.TEXTURE_2D, graphics.bitmap.getTexture(renderSession.gl));
		}
		else
		{
			GL.activeTexture(GL.TEXTURE0);
			GL.bindTexture(GL.TEXTURE_2D, null);
		}
		
		// set uniforms
		GL.uniform4f(shader.data.uColor.index, 1.0, 1.0, 1.0, 1.0);
		// TODO: implement it...
	//	GL.uniform4f(shader.data.uColorOffset.index, uColorOffset[0], uColorOffset[1], uColorOffset[2], uColorOffset[3]);
		
		var renderer:GLRenderer = cast renderSession.renderer;
		var worldMatrix = renderer.getMatrix(worldTransform);
		var uMatrix:Matrix4 = GLRenderHelper.arrayToMatrix(worldMatrix);
		
		GL.uniformMatrix4fv(shader.data.uMatrix.index, false, uMatrix);
		
		matrix4.identity();
		matrix4[0] = matrix.a;
		matrix4[1] = matrix.b;
		matrix4[4] = matrix.c;
		matrix4[5] = matrix.d;
		matrix4[12] = matrix.tx;
		matrix4[13] = matrix.ty;
		
		GL.uniformMatrix4fv(shader.data.uModel.index, false, matrix4);
		
		renderSession.blendModeManager.setBlendMode(blendMode);
		
		data.updateVertices();
		GL.vertexAttribPointer(shader.data.aPosition.index, 2, GL.FLOAT, false, 0, 0);
		
		if (graphics != null)
		{
			// update the uvs
			data.updateUV();
			GL.vertexAttribPointer(shader.data.aTexCoord.index, 2, GL.FLOAT, false, 0, 0);
		}
		
		if (colored)
		{
			// update the colors
			data.updateColors();
			GL.vertexAttribPointer(shader.data.aColor.index, 4, GL.UNSIGNED_BYTE, true, 0, 0);
		}
		
		data.updateIndices();
		data.dirty = false;
		
		GL.drawElements(GL.TRIANGLES, data.numIndices, GL.UNSIGNED_SHORT, 0);
	}
	
	override public function reset():Void 
	{
		super.reset();
		data = null;
		matrix = null;
	}
	
	private function setContext(gl:GLRenderContext):Void
	{
		if (data != null)
			data.setContext(gl);
	}
}