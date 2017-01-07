package flixel.graphics.shaders.triangles;

import flixel.system.FlxAssets.FlxShader;

// TODO: implement it...

class FlxTexturedColored extends FlxShader
{
	public static inline var defaultVertexSource:String = 
			"
			attribute vec4 aPosition;
			attribute vec4 aColor;
			
			varying vec2 vTexCoord;
			varying vec4 vColor;
			
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
			uniform vec4 uTrianglesColor;
			
			void main(void) 
			{
				vec4 color = vColor;
				
				vec4 result;
				
				float alpha = color.a * vColor.a * uColor.a;
				//	float alpha = color.a * vColor.a * uColor.a * uTrianglesColor.a;
				result = vec4(color.rgb * alpha, alpha) * vColor *  uColor;
				//	result = vec4(color.rgb * alpha, alpha) * vColor *  uColor * uTrianglesColor;
				
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