package flixel.graphics.shaders.tiles;

import flixel.graphics.shaders.FlxShader;

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
			
			uniform mat4 uMatrix;
			
			varying vec4 vColor;
			
			void main(void) 
			{
				vColor = aColor.bgra;
				gl_Position = uMatrix * aPosition;
			}";
			
	public static inline var defaultFragmentSource:String = 
			"
			varying vec4 vColor;
			
			uniform sampler2D uImage0;
			
			void main(void) 
			{
				gl_FragColor = vColor;
			}";
	
	public function new(?vertexSource:String, ?fragmentSource:String) 
	{
		super();
		
		#if FLX_RENDER_GL
		__glVertexSource = (vertexSource == null) ? defaultVertexSource : vertexSource;
		__glFragmentSource = (fragmentSource == null) ? defaultFragmentSource : fragmentSource;
		
		__glSourceDirty = true;
		#end
	}

}