package flixel.system.render.hardware.gl;

import flixel.graphics.FlxGraphic;
import flixel.graphics.TrianglesData;
import flixel.system.FlxAssets.FlxShader;
import flixel.system.render.common.DrawItem.FlxDrawItemType;
import flixel.util.FlxDestroyUtil;
import flixel.util.FlxDestroyUtil.IFlxDestroyable;
import openfl.display.BlendMode;
import openfl.geom.ColorTransform;
import openfl.geom.Matrix;

#if FLX_RENDER_GL
import flixel.graphics.shaders.triangles.FlxColored;
import flixel.graphics.shaders.triangles.FlxSingleColored;
import flixel.graphics.shaders.triangles.FlxTextured;
import flixel.graphics.shaders.triangles.FlxTexturedColored;

import lime.math.Matrix4;
import openfl.gl.GL;
import lime.graphics.GLRenderContext;
import openfl._internal.renderer.RenderSession;
import openfl._internal.renderer.opengl.GLRenderer;

class Triangles extends FlxDrawHardwareItem<Triangles>
{
	private static var matrix4:Matrix4 = new Matrix4();
	
	/**
	 * Default tile shader.
	 */
	private static var defaultTextureColoredShader:FlxTexturedColored = new FlxTexturedColored();
	private static var defaultTexturedShader:FlxTextured = new FlxTextured();
	private static var defaultColoredShader:FlxColored = new FlxColored();
	private static var defaultSingleColoredShader:FlxSingleColored = new FlxSingleColored();
	
	public var blendMode:BlendMode;
	
	private var worldTransform:Matrix;
	
	public var data:TrianglesData;
	
	/**
	 * Transformation matrix for this item on camera.
	 */
	public var matrix:Matrix;
	
	/**
	 * Color transform for this item.
	 */
	public var color:ColorTransform;
	
	public function new() 
	{
		super();
		type = FlxDrawItemType.TRIANGLES;
	}
	
	override public function destroy():Void
	{
		worldTransform = null;
		
		shader = null;
		blendMode = null;
		
		data = null;
		matrix = null;
		color = null;
	}
	
	override public function renderGL(worldTransform:Matrix, renderSession:RenderSession):Void
	{
		this.worldTransform = worldTransform;
		
		// init! init!
		setContext(renderSession.gl);
		
		shader = getShader();
		renderSession.shaderManager.setShader(shader);
		
		renderStrip(renderSession);
	}
	
	private function getShader():FlxShader
	{
		if (shader != null)
			return shader;
			
		if (textured)
			shader = (colored) ? defaultTextureColoredShader : defaultTexturedShader;
		else
			shader = (colored) ? defaultColoredShader : defaultSingleColoredShader;
		
		return shader;
	}
	
	private function renderStrip(renderSession:RenderSession):Void
	{
		if (textured)
		{
			GL.activeTexture(GL.TEXTURE0);
			GL.bindTexture(GL.TEXTURE_2D, graphics.bitmap.getTexture(renderSession.gl));
			
			setTextureSmoothing(smoothing);
		}
		else
		{
			GL.activeTexture(GL.TEXTURE0);
			GL.bindTexture(GL.TEXTURE_2D, null);
		}
		
		var red:Float = 1.0;
		var green:Float = 1.0;
		var blue:Float = 1.0;
		var alpha:Float = 1.0;
		
		var redOffset:Float = 0.0;
		var greenOffset:Float = 0.0;
		var blueOffset:Float = 0.0;
		var alphaOffset:Float = 0.0;
		
		if (color != null)
		{
			red = color.redMultiplier;
			green = color.greenMultiplier;
			blue = color.blueMultiplier;
			alpha = color.alphaMultiplier;
			
			redOffset = color.redOffset / 255;
			greenOffset = color.greenOffset / 255;
			blueOffset = color.blueOffset / 255;
			alphaOffset = color.alphaOffset / 255;
		}
		
		// set uniforms
		GL.uniform4f(shader.data.uColor.index, red, green, blue, alpha);
		GL.uniform4f(shader.data.uColorOffset.index, redOffset, greenOffset, blueOffset, alphaOffset);
		
		var renderer:GLRenderer = cast renderSession.renderer;
		var worldMatrix = renderer.getMatrix(worldTransform);
		var uMatrix:Matrix4 = GLRenderHelper.arrayToMatrix(worldMatrix);
		
		GL.uniformMatrix4fv(shader.data.uMatrix.index, false, uMatrix);
		
		// set transform matrix for all triangles in this item:
		matrix4.identity();
		matrix4[0] = matrix.a;
		matrix4[1] = matrix.b;
		matrix4[4] = matrix.c;
		matrix4[5] = matrix.d;
		matrix4[12] = matrix.tx;
		matrix4[13] = matrix.ty;
		GL.uniformMatrix4fv(shader.data.uModel.index, false, matrix4);
		
		renderSession.blendModeManager.setBlendMode(blendMode);
		
		data.updateVertices();
		GL.vertexAttribPointer(shader.data.aPosition.index, 2, GL.FLOAT, false, 0, 0);
		
		if (textured)
		{
			// update the uvs
			data.updateUV();
			GL.vertexAttribPointer(shader.data.aTexCoord.index, 2, GL.FLOAT, false, 0, 0);
		}
		
		if (colored)
		{
			// update the colors
			data.updateColors();
			GL.vertexAttribPointer(shader.data.aColor.index, 4, GL.UNSIGNED_BYTE, true, 0, 0);
		}
		
		data.updateIndices();
		data.dirty = false;
		
		GL.drawElements(GL.TRIANGLES, data.numIndices, GL.UNSIGNED_SHORT, 0);
	}
	
	override public function reset():Void 
	{
		super.reset();
		data = null;
		matrix = null;
		color = null;
	}
	
	private function setContext(gl:GLRenderContext):Void
	{
		if (data != null)
			data.setContext(gl);
	}
}

#else
class Triangles extends FlxDrawHardwareItem<Triangles>
{
	public var data:TrianglesData;
	public var matrix:Matrix;
	public var color:ColorTransform;
}
#end