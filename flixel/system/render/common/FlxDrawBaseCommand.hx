package flixel.system.render.common;

import flixel.graphics.FlxGraphic;
import flixel.graphics.FlxMaterial;
import flixel.graphics.frames.FlxFrame;
import flixel.math.FlxMatrix;
import flixel.math.FlxRect;
import flixel.graphics.shaders.FlxShader;
import flixel.system.render.common.DrawItem.FlxDrawItemType;
import flixel.system.render.hardware.FlxHardwareView;
import flixel.util.FlxDestroyUtil.IFlxDestroyable;
import openfl.display.BlendMode;
import openfl.geom.ColorTransform;

#if (openfl < "4.0.0")
import openfl.display.Tilesheet;
#end

/**
 * ...
 * @author Zaphod
 */
class FlxDrawBaseCommand<T> implements IFlxDestroyable
{
	#if (openfl < "4.0.0")
	public static function blendToInt(blend:BlendMode):Int
	{
		if (blend == null)
			return Tilesheet.TILE_BLEND_NORMAL;
		
		return switch (blend)
		{
			case BlendMode.ADD:
				Tilesheet.TILE_BLEND_ADD;
			#if !flash
			case BlendMode.MULTIPLY:
				Tilesheet.TILE_BLEND_MULTIPLY;
			case BlendMode.SCREEN:
				Tilesheet.TILE_BLEND_SCREEN;
			case BlendMode.SUBTRACT:
				Tilesheet.TILE_BLEND_SUBTRACT;
			#if !lime_legacy
			case BlendMode.DARKEN:
				Tilesheet.TILE_BLEND_DARKEN;
			case BlendMode.LIGHTEN:
				Tilesheet.TILE_BLEND_LIGHTEN;
			case BlendMode.OVERLAY:
				Tilesheet.TILE_BLEND_OVERLAY;
			case BlendMode.HARDLIGHT:
				Tilesheet.TILE_BLEND_HARDLIGHT;
			case BlendMode.DIFFERENCE:
				Tilesheet.TILE_BLEND_DIFFERENCE;
			case BlendMode.INVERT:
				Tilesheet.TILE_BLEND_INVERT;
			#end
			#end
			default:
				Tilesheet.TILE_BLEND_NORMAL;
		}
	}
	#end
	
	public var nextTyped:T;
	
	public var next:FlxDrawBaseCommand<T>;
	
	public var graphics:FlxGraphic;
	public var material:FlxMaterial;
	public var shader:FlxShader;
	public var colored:Bool = false;
	public var hasColorOffsets:Bool = false;
	
	public var type:FlxDrawItemType;
	
	public var numVertices(get, never):Int;
	
	public var numTriangles(get, never):Int;
	
	public var elementsPerVertex(get, null):Int;
	
	public var textured(get, null):Bool;
	
	public function new() {}
	
	public function reset():Void
	{
		graphics = null;
		material = null;
		shader = null;
		hasColorOffsets = false;
		colored = false;
		nextTyped = null;
		next = null;
	}
	
	public function destroy():Void
	{
		graphics = null;
		material = null;
		shader = null;
		next = null;
		nextTyped = null;
		type = null;
	}
	
	public function render(view:FlxHardwareView):Void {}
	
	public function addQuad(frame:FlxFrame, matrix:FlxMatrix, ?transform:ColorTransform, material:FlxMaterial):Void {}
	
	public function addUVQuad(texture:FlxGraphic, rect:FlxRect, uv:FlxRect, matrix:FlxMatrix, ?transform:ColorTransform, material:FlxMaterial):Void {}
	
	public function equals(type:FlxDrawItemType, graphic:FlxGraphic, colored:Bool, hasColorOffsets:Bool = false, material:FlxMaterial):Bool
	{
		if (hasColorOffsets)	return false;
		
		return (this.type == type 
			&& this.graphics == graphic 
			&& this.colored == colored
			&& this.hasColorOffsets == hasColorOffsets
			&& this.material.blendMode == material.blendMode
			&& this.material.smoothing == material.smoothing
			&& this.material.repeat == material.repeat
			&& this.shader == material.shader);
	}
	
	public function set(graphic:FlxGraphic, colored:Bool, hasColorOffsets:Bool = false, material:FlxMaterial):Void
	{
		this.graphics = graphic;
		this.material = material;
		this.shader = material.shader;
		this.colored = colored;
		this.hasColorOffsets = hasColorOffsets;
	}
	
	private function get_numVertices():Int
	{
		return 0;
	}
	
	private function get_numTriangles():Int
	{
		return 0;
	}
	
	private function get_elementsPerVertex():Int
	{
		return 0;
	}
	
	private inline function get_textured():Bool
	{
		return (graphics != null);
	}
}
