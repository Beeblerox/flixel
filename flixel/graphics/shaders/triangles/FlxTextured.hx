package flixel.graphics.shaders.triangles;

import flixel.system.FlxAssets.FlxShader;

class FlxTextured extends FlxShader
{
	public static inline var defaultVertexSource:String = 
			"
			attribute vec4 aPosition;
			attribute vec2 aTexCoord;
			
			uniform mat4 uMatrix;
			uniform mat4 uModel;
			
			void main(void) 
			{
				vTexCoord = aTexCoord;
				gl_Position = uMatrix * uModel * aPosition;
			}";
			
	public static inline var defaultFragmentSource:String = 
			"
			varying vec2 vTexCoord;
			
			uniform sampler2D uImage0;
			uniform vec4 uColor;
			uniform vec4 uColorOffset;
			
			void main(void) 
			{
				vec4 color = texture2D(uImage0, vTexCoord);
				float alpha = color.a * uColor.a;
				// OpenFl uses textures in bgra format, so we should convert color...
				vec4 result = vec4(color.rgb * alpha, alpha) * uColor.bgra + uColorOffset.bgra;
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