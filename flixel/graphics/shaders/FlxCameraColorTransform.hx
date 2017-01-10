package flixel.graphics.shaders;
import flixel.system.FlxAssets.FlxShader;

// TODO: use it...
class FlxCameraColorTransform extends FlxShader
{
	public static inline var defaultVertexSource:String = 
			"
			attribute vec4 aPosition;
			attribute vec2 aTexCoord;
			attribute vec4 aColor;
			
			varying vec2 vTexCoord;
			
			// TODO: implement it for camera...
			varying vec4 vColor;
			
			uniform mat4 uMatrix;
			
			void main(void) 
			{
				vTexCoord = aTexCoord;
				// OpenFl uses textures in bgra format, so we should convert color...
				vColor = aColor.bgra;
				gl_Position = uMatrix * aPosition;
			}";
			
	public static inline var defaultFragmentSource:String = 
			"
			varying vec2 vTexCoord;
			varying vec4 vColor;
			
			uniform sampler2D uImage0;
			
			uniform vec4 uColor;
			uniform vec4 uColorOffset;
			
			void main(void) 
			{
				vec4 color = texture2D(uImage0, vTexCoord);
				
				float alpha = color.a * vColor.a * uColor.a;
				vec4 result = vec4(color.rgb * alpha, alpha) * vColor *  uColor;
				
				result = result + uColorOffset;
				result = clamp(result, 0.0, 1.0);
				gl_FragColor = result;
			}";
	
	public function new() 
	{
		super(defaultVertexSource, defaultFragmentSource);
	}
	
}