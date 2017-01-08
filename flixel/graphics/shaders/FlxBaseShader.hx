package flixel.graphics.shaders;
import flixel.system.FlxAssets.FlxShader;

/**
 * ...
 * @author ...
 */

// TODO: use this class as a base for all other shaders???
class FlxBaseShader extends FlxShader
{

	public function new(vertexSource:String, fragmentSource:String) 
	{
		super();
		
		__glVertexSource = vertexSource;
		__glFragmentSource = fragmentSource;
		__glSourceDirty = true;
	}

	
}