package flixel.system.render.hardware.gl;
import openfl.display.Shader;
import openfl.gl.GL;
import openfl.gl.GLBuffer;

#if FLX_RENDER_GL
import lime.math.Matrix4;
import openfl.display.DisplayObject;
import openfl.filters.ShaderFilter;

class GLUtils 
{
	/**
	 * Helper variables for less object instantiation
	 */
	public static var _matrix:Array<Float> = [];
	public static var _matrix4:Matrix4 = new Matrix4();
	
	public static inline function matrixToArray(matrix:Matrix4):Array<Float>
	{
		for (i in 0...16)
			_matrix[i] = matrix[i];
		
		return _matrix;
	}
	
	public static inline function arrayToMatrix(array:Array<Float>):Matrix4
	{
		for (i in 0...16)
			_matrix4[i] = array[i];
		
		return _matrix4;
	}
	
	/**
	 * Checks how many render passes specified object has.
	 * 
	 * @param	object	display object to check
	 * @return	Number of render passes for specified object
	 */
	public static function getObjectNumPasses(object:DisplayObject):Int
	{
		if (object == null || object.filters == null)
			return 0;
		
		var passes:Int = 0;
		
		for (filter in object.filters)
		{
			if (Std.is(filter, ShaderFilter))
				passes++;
		}
		
		return passes;
	}
	
	public static function destroyBuffer(buffer:GLBuffer):GLBuffer
	{
		if (buffer != null)
			GL.deleteBuffer(buffer);
		
		return null;
	}
	
	public static function destroyShader(shader:Shader):Shader
	{
		if (shader != null)
		{
			if (shader.glProgram != null)
			{
				GL.deleteProgram(shader.glProgram);
			//	shader.glProgram = null;
			}
			
			shader.data = null;
			shader.byteCode = null;
			shader.glVertexSource = null;
			shader.glFragmentSource = null;
		//	gl = null;
		}
		
		return null;
	}
}
#end