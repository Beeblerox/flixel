package flixel.graphics.shaders.tiles;

import flixel.system.FlxAssets.FlxShader;

/**
 * ...
 * @author Yanrishatum
 */
class FlxColored extends FlxShader
{
	public static inline var defaultVertexSource:String = 
			"
			attribute vec4 aPosition;
			attribute vec4 aColor;
			
			varying vec4 vColor;
			
			uniform mat4 uMatrix;
			
			void main(void) 
			{
				vColor = aColor;
				gl_Position = uMatrix * aPosition;
			}";
			
	public static inline var defaultFragmentSource:String = 
			"
			varying vec4 vColor;
			
			uniform vec4 uColor;
			uniform vec4 uColorOffset;
			
			void main(void) 
			{
				vec4 result = vColor * uColor + uColorOffset;
				result = clamp(result, 0.0, 1.0);
				gl_FragColor = result;
			}";
	
	public function new(?vertexSource:String, ?fragmentSource:String) 
	{
		super();
		
		__glVertexSource = (vertexSource == null) ? defaultVertexSource : vertexSource;
		__glFragmentSource = (fragmentSource == null) ? defaultFragmentSource : fragmentSource;
		
		__glSourceDirty = true;
	}
}