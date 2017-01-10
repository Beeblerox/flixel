package flixel.graphics.shaders.triangles;

import flixel.system.FlxAssets.FlxShader;

// TODO: check this later...
class FlxColored extends FlxShader
{
	public static inline var defaultVertexSource:String = 
			"
			attribute vec4 aPosition;
			attribute vec4 aColor;
			
			uniform mat4 uMatrix;
			uniform mat4 uModel;
			
			void main(void) 
			{
				vColor = aColor;
				gl_Position = uMatrix * uModel * aPosition;
			}";
			
	public static inline var defaultFragmentSource:String = 
			"
			varying vec4 vColor;
			
			uniform vec4 uColor;
			uniform vec4 uColorOffset;
			
			void main(void) 
			{
				vec4 result = vColor *  uColor + uColorOffset;
				gl_FragColor = clamp(result, 0.0, 1.0);
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