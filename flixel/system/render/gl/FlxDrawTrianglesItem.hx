package flixel.system.render.gl;
import flixel.util.FlxColor;
import openfl.geom.ColorTransform;
import flixel.math.FlxMatrix;

import flixel.graphics.frames.FlxFrame;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.system.render.common.DrawItem.DrawData;
import flixel.system.render.common.FlxDrawBaseItem;

// TODO: add culling support???
// gl.enable(gl.CULL_FACE);
// gl.cullFace(gl.FRONT);

/**
 * ...
 * @author Zaphod
 */
class FlxDrawTrianglesItem extends FlxDrawBaseItem<FlxDrawTrianglesItem>
{

	public function new() 
	{
		super();
	}
	
	override public function addQuad(frame:FlxFrame, matrix:FlxMatrix, ?transform:ColorTransform):Void 
	{
		
		
		// TODO: implement it...
		
		/*
		ensureElement();
		
		var rect:FlxRect = frame.frame;
		var uv:FlxRect = frame.uv;
		
		var data:Float32Array = buffer;
		
		// UV
		var uvx:Float = uv.x;
		var uvy:Float = uv.y;
		var uvx2:Float = uv.width;
		var uvy2:Float = uv.height;
		
		// Position
		var x :Float = matrix.__transformX(0, 0); // Top-left
		var y :Float = matrix.__transformY(0, 0);
		var x2:Float = matrix.__transformX(rect.width, 0); // Top-right
		var y2:Float = matrix.__transformY(rect.width, 0);
		var x3:Float = matrix.__transformX(0, rect.height); // Bottom-left
		var y3:Float = matrix.__transformY(0, rect.height);
		var x4:Float = matrix.__transformX(rect.width, rect.height); // Bottom-right
		var y4:Float = matrix.__transformY(rect.width, rect.height);
		
		var r:Float = 1.0;
		var g:Float = 1.0;
		var b:Float = 1.0;
		var a:Float = 1.0;
		
		if (colored && transform != null)
		{
			if (colored)
			{
				r = transform.redMultiplier;
				g = transform.greenMultiplier;
				b = transform.blueMultiplier;
			}
			
			a = transform.alphaMultiplier;
		}
		
		// Set values
		inline function fillTint():Void
		{
			data[vertexPos++] = r;
			data[vertexPos++] = g;
			data[vertexPos++] = b;
			data[vertexPos++] = a;
		}
		
		// Triangle 1, top-left
		data[vertexPos++] = x;
		data[vertexPos++] = y;
		data[vertexPos++] = uvx;
		data[vertexPos++] = uvy;
		fillTint();
		// Triangle 1, top-right
		data[vertexPos++] = x2;
		data[vertexPos++] = y2;
		data[vertexPos++] = uvx2;
		data[vertexPos++] = uvy;
		fillTint();
		// Triangle 1, bottom-left
		data[vertexPos++] = x3;
		data[vertexPos++] = y3;
		data[vertexPos++] = uvx;
		data[vertexPos++] = uvy2;
		fillTint();
		// Triangle 2, bottom-right
		data[vertexPos++] = x4;
		data[vertexPos++] = y4;
		data[vertexPos++] = uvx2;
		data[vertexPos++] = uvy2;
		fillTint();
		
		indexPos += HardwareRenderer.INDICES_PER_TILE;
		vertexBufferDirty = true;
		*/
	}
	
	// TODO: replace position argument with matrix?
	public function addTriangles(vertices:DrawData<Float>, indices:DrawData<Int>, uvData:DrawData<Float>, ?matrix:FlxMatrix, ?transform:ColorTransform):Void
	{
		// TODO: implement it...
		
		
	}
	
	private function ensureElement():Void
	{
		// TODO: implement it...
		
		/*
		if (buffer == null)
		{
			buffer = new Float32Array(HardwareRenderer.MINIMUM_TILE_COUNT_PER_BUFFER * HardwareRenderer.ELEMENTS_PER_TILE);
			indexes = new UInt32Array(HardwareRenderer.MINIMUM_TILE_COUNT_PER_BUFFER * HardwareRenderer.INDICES_PER_TILE);
			
			fillIndexBuffer();
		}
		else if (vertexPos >= buffer.length)
		{
			var oldBuffer:Float32Array = buffer;
			var newNumberOfTiles = currentTilesCapacity + HardwareRenderer.MINIMUM_TILE_COUNT_PER_BUFFER;
			
			buffer = new Float32Array(newNumberOfTiles * HardwareRenderer.ELEMENTS_PER_TILE);
			indexes = new UInt32Array(newNumberOfTiles * HardwareRenderer.INDICES_PER_TILE);
			
			var oldLength:Int = oldBuffer.length;
			for (i in 0...oldLength)
			{
				buffer[i] = oldBuffer[i];
			}
			
			fillIndexBuffer();
		}
		*/
	}
	/*
	private inline function fillIndexBuffer():Void
	{
		var i:Int = 0;
		var vertexOffset:Int = 0;
		
		while (i < indexes.length)
		{
			indexes[i    ] = vertexOffset;//0;
			indexes[i + 1] = vertexOffset + 1;
			indexes[i + 2] = vertexOffset + 2;
			indexes[i + 3] = vertexOffset + 2;
			indexes[i + 4] = vertexOffset + 1;
			indexes[i + 5] = vertexOffset + 3;
			vertexOffset += 4;
			i += HardwareRenderer.INDICES_PER_TILE;
		}
		
		indexBufferDirty = true;
	}
	*/
	
	// TODO: add check if it's possible to add new quad to this item...
	// TODO: add check if it's possible to add new triangles to this item...
}