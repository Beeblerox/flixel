package flixel.system.render.hardware.gl;

import flixel.graphics.FlxGraphic;
import flixel.system.FlxAssets.FlxShader;
import flixel.system.render.common.DrawItem.FlxDrawItemType;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;
import flixel.util.FlxDestroyUtil.IFlxDestroyable;
import lime.math.Matrix4;
import lime.utils.UInt16Array;
import lime.utils.UInt32Array;
import openfl.display.BlendMode;
import openfl.display.DisplayObject;
import openfl.geom.Matrix;
import openfl.gl.GL;
import openfl.gl.GLBuffer;
import openfl.utils.Float32Array;
import openfl._internal.renderer.RenderSession;
import lime.graphics.GLRenderContext;
import openfl._internal.renderer.opengl.GLRenderer;

/**
 * ...
 * @author ...
 */

class TrianglesData implements IFlxDestroyable
{
	// TODO: use it...
	public var batchable:Bool = false;
	
	public var dirty:Bool = true;
	
	public var vertices(null, set):Array<Float>;
	public var uvs(null, set):Array<Float>;
	public var colors(null, set):Array<FlxColor>;
	public var indices(null, set):Array<Int>;
	
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
	
	public function new()
	{
		
	}
	
	public function destroy():Void
	{
		gl = null;
		
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
	
	private function set_vertices(value:Array<Float>):Array<Float>
	{
		if (value == null)
			return value;
		
		if (verticesArray == null || verticesArray.length != value.length)
			verticesArray = new Float32Array(value.length);
		
		for (i in 0...value.length)
			verticesArray[i] = value[i];
		
		return value;
	}
	
	private function set_uvs(value:Array<Float>):Array<Float>
	{
		if (value == null)
			return value;
		
		if (uvsArray == null || uvsArray.length != value.length)
			uvsArray = new Float32Array(value.length);
		
		for (i in 0...value.length)
			uvsArray[i] = value[i];
		
		dirty = true;
		return value;
	}
	
	private function set_colors(value:Array<FlxColor>):Array<FlxColor>
	{
		if (value == null)
			return value;
		
		if (colorsArray == null || colorsArray.length != value.length)
			colorsArray = new UInt32Array(value.length);
		
		for (i in 0...value.length)
			verticesArray[i] = value[i];
		
		dirty = true;
		return value;
	}
	
	private function set_indices(value:Array<Int>):Array<Int>
	{
		if (value == null)
			return value;
		
		if (indicesArray == null || indicesArray.length != value.length)
			indicesArray = new UInt16Array(value.length);
		
		for (i in 0...value.length)
			indicesArray[i] = value[i];
		
		dirty = true;
		return value;
	}
}
 
class Triangles extends FlxDrawHardwareItem<Triangles>
{
	public var texture:FlxGraphic;
	
//	public var shader:FlxShader;
	
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
		GL.bindTexture(GL.TEXTURE_2D, texture.bitmap.getTexture(renderSession.gl));
		
		// set uniforms
		GL.uniform4f(shader.data.uColor.index, 1.0, 1.0, 1.0, 1.0);
		// TODO: implement it...
	//	GL.uniform4f(shader.data.uColorOffset.index, uColorOffset[0], uColorOffset[1], uColorOffset[2], uColorOffset[3]);
		
		var matrix = renderer.getMatrix(worldTransform);
		var uMatrix:Matrix4 = GLRenderHelper.arrayToMatrix(matrix);
		
		GL.uniformMatrix4fv(shader.data.uMatrix.index, false, uMatrix);
		
		this.renderSession.blendModeManager.setBlendMode(blendMode);
		
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