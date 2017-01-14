package flixel.system.render.hardware.gl;

import flixel.system.render.common.FlxCameraView;
import flixel.system.render.hardware.FlxHardwareView;
import flixel.system.render.common.FlxDrawBaseItem;
import openfl.gl.GL;

#if (openfl >= "4.0.0")
import lime.graphics.opengl.GLBuffer;
import lime.utils.Float32Array;
import lime.utils.Int16Array; // UInt32Array;

/**
 * ...
 * @author Zaphod
 */
class FlxDrawHardwareItem<T> extends FlxDrawBaseItem<T>
{
	public static inline var ELEMENTS_PER_TEXTURED_VERTEX:Int = 5;
	public static inline var ELEMENTS_PER_NON_TEXTURED_VERTEX:Int = 3;
	
	public function new() 
	{
		super();
	}
	
	override public function render(view:FlxHardwareView):Void 
	{
		#if !flash
		view.drawItem(this);
		#end
	}
	
	private function setTextureSmoothing(smooth:Bool):Void
	{
		if (smooth) 
		{		
			GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_MAG_FILTER, GL.LINEAR);
			GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_MIN_FILTER, GL.LINEAR);	
		}
		else
		{		
			GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_MAG_FILTER, GL.NEAREST);
			GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_MIN_FILTER, GL.NEAREST);	
		}
	}
}
#end