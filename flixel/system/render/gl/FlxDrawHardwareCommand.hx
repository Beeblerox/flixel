package flixel.system.render.gl;

import flixel.graphics.shaders.FlxShader;
import flixel.system.render.common.FlxDrawBaseCommand;
import flixel.system.render.gl.FlxRenderTexture;
import lime.graphics.GLRenderContext;
import openfl.gl.GL;

#if FLX_RENDER_GL
import flixel.system.render.gl.GLContextHelper;
import lime.math.Matrix4;

/**
 * ...
 * @author Zaphod
 */
class FlxDrawHardwareCommand<T> extends FlxDrawBaseCommand<T>
{
	private var uniformMatrix:Matrix4;
	
	private var context:GLContextHelper;
	
	private var gl:GLRenderContext;
	
	private var buffer:FlxRenderTexture;
	
	public function new() 
	{
		super();
	}
	
	public function prepare(context:GLContextHelper, buffer:FlxRenderTexture):Void 
	{
		this.uniformMatrix = buffer.projection;
		this.context = context;
		this.buffer = buffer;
		context.currentBuffer = null;
	}
	
	public function flush():Void {}
	
	private function setShader(shader:FlxShader):FlxShader 
	{
		return shader;
	}
	
	override public function destroy():Void 
	{
		uniformMatrix = null;
		context = null;
		gl = null;
		buffer = null;
		
		super.destroy();
	}
	
	private function setContext(context:GLContextHelper):Void 
	{
		this.context = context;
		this.gl = context.gl;
	}
	
}
#end