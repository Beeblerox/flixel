package flixel.graphics.shaders;

import flixel.system.FlxAssets.FlxShader;

class FlxBaseShader extends FlxShader
{
	public function new(vertexSource:String, fragmentSource:String) 
	{
		super();
		
		#if FLX_RENDER_GL
		__glVertexSource = vertexSource;
		__glFragmentSource = fragmentSource;
		__glSourceDirty = true;
		#end
	}
}