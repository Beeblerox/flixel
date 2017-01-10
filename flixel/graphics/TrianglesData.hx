package flixel.graphics;
import flixel.system.render.common.DrawItem.DrawData;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;

#if FLX_RENDER_GL
import lime.graphics.GLRenderContext;
import lime.utils.UInt16Array;
import lime.utils.UInt32Array;
import openfl.gl.GL;
import openfl.gl.GLBuffer;
import openfl.utils.Float32Array;
#end

// TODO: fix this for flash target

class TrianglesData implements IFlxDestroyable
{
	public static function getQuadData(width:Float = 100, height:Float = 100, color:FlxColor = FlxColor.WHITE):TrianglesData
	{
		var data:TrianglesData = new TrianglesData();
		
		data.vertices[0] = 0.0;
		data.vertices[1] = 0.0;
		data.vertices[2] = width;
		data.vertices[3] = 0.0;
		data.vertices[4] = width;
		data.vertices[5] = height;
		data.vertices[6] = 0;
		data.vertices[7] = height;
		
		data.uvs[0] = 0.0;
		data.uvs[1] = 0.0;
		data.uvs[2] = 1.0;
		data.uvs[3] = 0.0;
		data.uvs[4] = 1.0;
		data.uvs[5] = 1.0;
		data.uvs[6] = 0;
		data.uvs[7] = 1.0;
		
		data.colors[0] = color;
		data.colors[1] = color;
		data.colors[2] = color;
		data.colors[3] = color;
		
		data.indices[0] = 0;
		data.indices[1] = 1;
		data.indices[2] = 2;
		data.indices[3] = 2;
		data.indices[4] = 3;
		data.indices[5] = 0;
		
		return data;
	}
	
	public var numIndices(get, null):Int;
	
	public var colored(get, null):Bool;
	
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
	
	public function new() { }
	
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
	
	private function get_colored():Bool
	{
		return (colors != null) && (colors.length > 0);
	}
}