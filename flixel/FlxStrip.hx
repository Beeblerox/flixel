package flixel;

import flixel.math.FlxRect;
import flixel.system.FlxAssets.FlxGraphicAsset;
import flixel.system.render.common.DrawItem.DrawData;
import flixel.system.render.hardware.gl.Triangles.TrianglesData;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;

/**
 * A very basic rendering component which uses drawTriangles.
 * You have access to vertices, indices and uvtData vectors which are used as data storages for rendering.
 * The whole FlxGraphic object is used as a texture for this sprite.
 * 
 * You must set `dirty` flag to true to make it update its bounds which are used for visibility checks.
 * I had to add this requirement for less calculations every frame.
 * 
 * Use these links for more info about drawTriangles method:
 * @see http://help.adobe.com/en_US/FlashPlatform/reference/actionscript/3/flash/display/Graphics.html#drawTriangles%28%29
 * @see http://help.adobe.com/en_US/as3/dev/WS84753F1C-5ABE-40b1-A2E4-07D7349976C4.html
 * @see http://www.flashandmath.com/advanced/p10triangles/index.html
 * 
 * WARNING: This class is EXTREMELY slow on flash target!
 */
class FlxStrip extends FlxSprite
{
	/**
	 * A Vector of Floats where each pair of numbers is treated as a coordinate location (an x, y pair).
	 */
	public var vertices(get, set):DrawData<Float>;
	/**
	 * A Vector of integers or indexes, where every three indexes define a triangle.
	 */
	public var indices(get, set):DrawData<Int>;
	/**
	 * A Vector of normalized coordinates used to apply texture mapping.
	 */
	public var uvtData(get, set):DrawData<Float>;
	
	public var colors(get, set):DrawData<FlxColor>;
	
	public var repeat:Bool = true;
	
	// TODO: maybe add option to draw triangles on the sprite buffer (for less drawTriangles calls)...
	
	// TODO: maybe optimize FlxStrip, so it will have its own sprite and buffer
	// which will be used for rendering (which means less drawTriangles calls)...
	
	private var bounds:FlxRect = FlxRect.get();
	
	private var data:TrianglesData;
	
	public function new(?X:Float = 0, ?Y:Float = 0, ?SimpleGraphic:FlxGraphicAsset)
	{
		super(X, Y, SimpleGraphic);
		
		data = new TrianglesData();
	}
	
	override public function destroy():Void 
	{
		data = FlxDestroyUtil.destroy(data);
		
		super.destroy();
	}
	
	override public function draw():Void 
	{
		if (alpha == 0 || graphic == null || vertices == null)
			return;
		
		if (dirty && vertices.length >= 6)
		{
			// calculate bounds in local coordinates
			bounds.set(vertices[0], vertices[1], 0, 0);
			var numVertices:Int = vertices.length;
			var i:Int = 2;
			
			while (i < numVertices)
			{
				bounds.inflate(vertices[i], vertices[i + 1]);
				i += 2;
			}
		}
		
		for (camera in cameras)
		{
			if (!camera.visible || !camera.exists)
			{
				continue;
			}
			
			getScreenPosition(_point, camera);
			
			// TODO: not only translate bounds rectangle, 
			// but also scale and rotate it for correct visibility check...
			bounds.offset(_point.x, _point.y);
			
			if (camera.view.bounds.overlaps(bounds))
			{
				_matrix.identity();
				
				_matrix.translate(-origin.x, -origin.y);
				_matrix.scale(scale.x, scale.y);
				
				updateTrig();
				
				if (angle != 0)
					_matrix.rotateWithTrig(_cosAngle, _sinAngle);
				
				_matrix.translate(origin.x, origin.y);
				_matrix.translate(_point.x, _point.y);
				
				camera.drawTriangles(graphic, data, _matrix, colorTransform, blend, repeat, antialiasing);
			}
			
			bounds.offset( -_point.x, -_point.y);
		}
	}
	
	private function get_vertices():DrawData<Float>
	{
		return data.vertices;
	}
	
	private function set_vertices(value:DrawData<Float>):DrawData<Float>
	{
		return data.vertices = value;
	}
	
	private function get_indices():DrawData<Int>
	{
		return data.indices;
	}
	
	private function set_indices(value:DrawData<Int>):DrawData<Int>
	{
		return data.indices = value;
	}
	
	private function get_uvtData():DrawData<Float>
	{
		return data.uvs;
	}
	
	private function set_uvtData(value:DrawData<Float>):DrawData<Float>
	{
		return data.uvs = value;
	}
	
	private function get_colors():DrawData<FlxColor>
	{
		return data.colors;
	}
	
	private function set_colors(value:DrawData<FlxColor>):DrawData<FlxColor>
	{
		return data.colors = value;
	}
}