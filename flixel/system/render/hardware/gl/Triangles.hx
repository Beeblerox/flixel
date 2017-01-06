package flixel.system.render.hardware.gl;

import flixel.graphics.FlxGraphic;
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
	// TODO: use it...
	public var batchable:Bool = false;
	
	public var textured:Bool = true;
	
	public var dirty(default, set):Bool = true;
	
	public var hasData(get, null):Bool;
	
	public var verticesDirty:Bool = true;
	public var uvtDirty:Bool = true;
	public var colorsDirty:Bool = true;
	public var indicesDirty:Bool = true;
	
	public var vertices(default, set):DrawData<Float>;
	public var uvs(default, set):DrawData<Float>;
	public var colors(default, set):DrawData<FlxColor>;
	public var indices(default, set):DrawData<Int>;
	
	@:allow(flixel.system.render.hardware.gl.Triangles)
	private var verticesArray:Float32Array;
	@:allow(flixel.system.render.hardware.gl.Triangles)
	private var uvsArray:Float32Array;
	@:allow(flixel.system.render.hardware.gl.Triangles)
	private var colorsArray:UInt32Array;
	@:allow(flixel.system.render.hardware.gl.Triangles)
	private var indicesArray:UInt16Array;
	
	@:allow(flixel.system.render.hardware.gl.Triangles)
	private var verticesBuffer:GLBuffer;
	@:allow(flixel.system.render.hardware.gl.Triangles)
	private var uvsBuffer:GLBuffer;
	@:allow(flixel.system.render.hardware.gl.Triangles)
	private var colorsBuffer:GLBuffer;
	@:allow(flixel.system.render.hardware.gl.Triangles)
	private var indicesBuffer:GLBuffer;
	
	private var gl:GLRenderContext;
	
	public function new(textured:Bool = true)
	{
		this.textured = textured;
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
			
			GL.bindBuffer(GL.ARRAY_BUFFER, verticesBuffer);
			GL.bufferData(GL.ARRAY_BUFFER, verticesArray, GL.DYNAMIC_DRAW);
			
			GL.bindBuffer(GL.ARRAY_BUFFER, uvsBuffer);
			GL.bufferData(GL.ARRAY_BUFFER, uvsArray, GL.STATIC_DRAW);
			
			GL.bindBuffer(GL.ARRAY_BUFFER, colorsBuffer);
			GL.bufferData(GL.ARRAY_BUFFER, colorsArray, GL.STATIC_DRAW);
			
			GL.bindBuffer(GL.ELEMENT_ARRAY_BUFFER, indicesBuffer);
			GL.bufferData(GL.ELEMENT_ARRAY_BUFFER, indicesArray, GL.STATIC_DRAW);
		}
	}
	
	private function set_vertices(value:DrawData<Float>):DrawData<Float>
	{
		verticesDirty = verticesDirty || (value != null);
		return vertices = value;
	}
	
	public function updateVertices():Void
	{
		if (verticesDirty && vertices != null)
		{
			if (verticesArray == null || verticesArray.length != vertices.length)
				verticesArray = new Float32Array(vertices.length);
			
			for (i in 0...vertices.length)
				verticesArray[i] = vertices[i];
				
			verticesDirty = false;
		}
	}
	
	private function set_uvs(value:DrawData<Float>):DrawData<Float>
	{
		uvtDirty = uvtDirty || (value != null);
		return uvs = value;
	}
	
	public function updateUV():Void
	{
		if (uvtDirty && uvs != null)
		{
			if (uvsArray == null || uvsArray.length != uvs.length)
				uvsArray = new Float32Array(uvs.length);
			
			for (i in 0...uvs.length)
				uvsArray[i] = uvs[i];
				
			uvtDirty = false;
		}
	}
	
	private function set_colors(value:DrawData<FlxColor>):DrawData<FlxColor>
	{
		colorsDirty = colorsDirty || (value != null);
		return colors = value;
	}
	
	public function updateColors():Void
	{
		if (colorsDirty && colors != null)
		{
			if (colorsArray == null || colorsArray.length != colors.length)
				colorsArray = new UInt32Array(colors.length);
			
			for (i in 0...colors.length)
				colorsArray[i] = colors[i];
				
			colorsDirty = false;
		}
	}
	
	private function set_indices(value:DrawData<Int>):DrawData<Int>
	{
		indicesDirty = indicesDirty || (value != null);
		return indices = value;
	}
	
	public function updateIndices():Void
	{
		if (indicesDirty && indices != null)
		{
			if (indicesArray == null || indicesArray.length != indices.length)
				indicesArray = new UInt16Array(indices.length);
			
			for (i in 0...indices.length)
				indicesArray[i] = indices[i];
				
			indicesDirty = false;
		}
	}
	
	private function set_dirty(value:Bool):Bool
	{
		verticesDirty = uvtDirty = colorsDirty = indicesDirty = value;
		return dirty = value;
	}
	
	private function get_hasData():Bool
	{
		var result:Bool = (vertices != null && vertices.length >= 6) && (colors != null && colors.length >= 3) && (indices != null && indices.length >= 3);
		
		if (textured)
			result = result && (uvs != null && uvs.length >= 6);
		
		return result;
	}
}
 
class Triangles extends FlxDrawHardwareItem<Triangles>
{
	public var blendMode:BlendMode;
	
	#if !flash
	private var renderSession:RenderSession;
	#end
	
	private var worldTransform:Matrix;
	private var renderer:GLRenderer;
	
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
		renderSession = null;
		worldTransform = null;
		renderer = null;
		
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
		this.renderSession = renderSession;
		this.renderer = cast renderSession.renderer;
		
		// init! init!
		setContext(renderSession.gl);
		
		// TODO: implement special strip shader with colors on and off...
		renderSession.shaderManager.setShader(shader);
		
		renderStrip(renderSession);
	}
	
	#if flash
	private function renderStrip(renderSession:Dynamic):Void
	#else
	private function renderStrip(renderSession:RenderSession):Void
	#end
	{
		GL.activeTexture(GL.TEXTURE0);
		GL.bindTexture(GL.TEXTURE_2D, graphics.bitmap.getTexture(renderSession.gl));
		
		// set uniforms
		GL.uniform4f(shader.data.uColor.index, 1.0, 1.0, 1.0, 1.0);
		// TODO: implement it...
	//	GL.uniform4f(shader.data.uColorOffset.index, uColorOffset[0], uColorOffset[1], uColorOffset[2], uColorOffset[3]);
		
		var matrix = renderer.getMatrix(worldTransform);
		var uMatrix:Matrix4 = GLRenderHelper.arrayToMatrix(matrix);
		
		GL.uniformMatrix4fv(shader.data.uMatrix.index, false, uMatrix);
		
		this.renderSession.blendModeManager.setBlendMode(blendMode);
		
		/*
		if (data.verticesDirty)
		{
			GL.bindBuffer(GL.ARRAY_BUFFER, data.verticesBuffer);
			GL.bufferSubData(GL.ARRAY_BUFFER, 0, data.verticesArray);
			GL.vertexAttribPointer(shader.data.aPosition.index, 2, GL.FLOAT, false, 0, 0);
			data.verticesDirty = false;
		}
		*/
		
		if (!data.dirty)
		{
			GL.bindBuffer(GL.ARRAY_BUFFER, data.verticesBuffer);
			GL.bufferSubData(GL.ARRAY_BUFFER, 0, data.verticesArray);
			GL.vertexAttribPointer(shader.data.aPosition.index, 2, GL.FLOAT, false, 0, 0);
			
			// update the uvs
			GL.bindBuffer(GL.ARRAY_BUFFER, data.uvsBuffer);
			GL.vertexAttribPointer(shader.data.aTexCoord.index, 2, GL.FLOAT, false, 0, 0);
			
			// update the colors
			GL.bindBuffer(GL.ARRAY_BUFFER, data.colorsBuffer);
			GL.vertexAttribPointer(shader.data.aColor.index, 4, GL.UNSIGNED_BYTE, true, 0, 0);
			
			// dont need to upload!
			GL.bindBuffer(GL.ELEMENT_ARRAY_BUFFER, data.indicesBuffer);
		}
		else
		{
			data.dirty = false;
			
			GL.bindBuffer(GL.ARRAY_BUFFER, data.verticesBuffer);
			GL.bufferData(GL.ARRAY_BUFFER, data.verticesArray, GL.STATIC_DRAW);
			GL.vertexAttribPointer(shader.data.aPosition.index, 2, GL.FLOAT, false, 0, 0);
			
			// update the uvs
			GL.bindBuffer(GL.ARRAY_BUFFER, data.uvsBuffer);
			GL.bufferData(GL.ARRAY_BUFFER, data.uvsArray, GL.STATIC_DRAW);
			GL.vertexAttribPointer(shader.data.aTexCoord.index, 2, GL.FLOAT, false, 0, 0);
			
			// update the colors
			GL.bindBuffer(GL.ARRAY_BUFFER, data.colorsBuffer);
			GL.bufferData(GL.ARRAY_BUFFER, data.colorsArray, GL.STATIC_DRAW);
			GL.vertexAttribPointer(shader.data.aColor.index, 4, GL.UNSIGNED_BYTE, true, 0, 0);
			
			GL.bindBuffer(GL.ELEMENT_ARRAY_BUFFER, data.indicesBuffer);
			GL.bufferData(GL.ELEMENT_ARRAY_BUFFER, data.indicesArray, GL.STATIC_DRAW);
		}
		
		GL.drawElements(GL.TRIANGLES, data.indicesArray.length, GL.UNSIGNED_SHORT, 0);
	}
	
	private function setContext(gl:GLRenderContext):Void
	{
		if (data != null)
			data.setContext(gl);
	}
	
	
}