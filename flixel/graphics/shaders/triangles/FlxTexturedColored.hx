package flixel.graphics.shaders.triangles;

import flixel.system.FlxAssets.FlxShader;

class FlxTexturedColored extends FlxShader
{
	public static inline var defaultVertexSource:String = 
			"
			attribute vec4 aPosition;
			attribute vec2 aTexCoord;
			attribute vec4 aColor;
			
			varying vec2 vTexCoord;
			varying vec4 vColor;
			
			uniform mat4 uMatrix;
			uniform mat4 uModel;
			
			void main(void) 
			{
				vTexCoord = aTexCoord;
				vColor = aColor.bgra;
				gl_Position = uMatrix * uModel * aPosition;
			}";
			
	public static inline var defaultFragmentSource:String = 
			"
			varying vec2 vTexCoord;
			varying vec4 vColor;
			
			uniform sampler2D uImage0;
			
			// 
			uniform vec4 uColor;
			uniform vec4 uColorOffset;
			
			void main(void) 
			{
				vec4 color = texture2D(uImage0, vTexCoord);
				
				vec4 result;
				
				if (color.a == 0.0) 
				{
					result = vec4(0.0, 0.0, 0.0, 0.0);
				} 
				else 
				{
					float alpha = color.a * vColor.a * uColor.a;
					// OpenFl uses textures in bgra format, so we should convert color...
					result = vec4(color.rgb * alpha, alpha) * vColor *  uColor;
				}
				
			//	result = result + uColorOffset;
				result = clamp(result, 0.0, 1.0);
			//	gl_FragColor = color;
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