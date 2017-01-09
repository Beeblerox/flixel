package flixel.graphics.shaders.triangles;

import flixel.system.FlxAssets.FlxShader;

class FlxSingleColored extends FlxShader
{
	public static inline var defaultVertexSource:String = 
			"
			attribute vec4 aPosition;
			
			uniform mat4 uMatrix;
			uniform mat4 uModel;
			
			void main(void) 
			{
				gl_Position = uMatrix * uModel * aPosition;
			}";
			
	public static inline var defaultFragmentSource:String = 
			"
			uniform vec4 uColor;
			uniform vec4 uColorOffset;
			
			void main(void) 
			{
				vec4 result = uColor + uColorOffset;
				gl_FragColor = clamp(result, 0.0, 1.0);
			}";
	
	public function new(?vertexSource:String, ?fragmentSource:String) 
	{
		super();
		
		__glVertexSource = (vertexSource == null) ? defaultVertexSource : vertexSource;
		__glFragmentSource = (fragmentSource == null) ? defaultFragmentSource : fragmentSource;
		
		__glSourceDirty = true;
	}

}