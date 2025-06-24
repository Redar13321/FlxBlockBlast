package;

import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxFrame;
import flixel.math.FlxMatrix;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.system.FlxAssets.FlxShader;
import flixel.util.FlxDestroyUtil;
import openfl.display.BlendMode;
import openfl.geom.ColorTransform;
import openfl.geom.Point;
import openfl.geom.Rectangle;

using flixel.util.FlxColorTransformUtil;

@:access(openfl.geom.ColorTransform)
class FlxFigure extends FlxSprite
{
	public var tileSize(default, null):FlxPoint;
	// public var tileGraphic(default, set):FlxGraphic;
	public var figureRaw(default, set):FlxRawFigure;
	
	var _visibleIndexes:Null<Array<Int>> = null;

	public function new(X:Float = 0, Y:Float = 0, ?raw:FlxRawFigure) {
		super(X, Y);
		figureRaw = raw;
		_updateVisibleIndexes();
	}

	public override function initVars()
	{
		super.initVars();
		tileSize = FlxPoint.get();
	}

	public override function destroy()
	{
		super.destroy();
		tileSize = FlxDestroyUtil.put(tileSize);
	}

	override function resetHelpers()
	{
		// if (figureRaw != null)
		// {
		// 	resetFrameSize();
		// 	resetSizeFromFrame();
		// 	_flashRect2.x = 0;
		// 	_flashRect2.y = 0;

		// 	if (graphic != null)
		// 	{
		// 		_flashRect2.width = graphic.width;
		// 		_flashRect2.height = graphic.height;
		// 	}

		// 	centerOrigin();

		// 	if (FlxG.renderBlit)
		// 	{
		// 		dirty = true;
		// 		updateFramePixels();
		// 	}
		// }
		// else
		{
			if (frame != null)
			{
				tileSize.set(frame.sourceSize.x, frame.sourceSize.y);
				if (figureRaw != null)
				{
					frame.sourceSize.x *= figureRaw.width;
					frame.sourceSize.y *= figureRaw.height;
				}
			}
			else
			{
				tileSize.set(1, 1);
			}
			super.resetHelpers();
			if (frame != null && figureRaw != null)
			{
				frame.sourceSize.x /= figureRaw.width;
				frame.sourceSize.y /= figureRaw.height;
			}
		}
	}
	inline function _updateVisibleIndexes()
	{
		if (figureRaw != null)
			_visibleIndexes = [for (i in 0...figureRaw.width * figureRaw.height) i].filter(i -> figureRaw.getPixelByIndex(i).alpha != 0);
		else
			_visibleIndexes = null;
		// trace(_visibleIndexes);
	}
			
	function set_figureRaw(newData:FlxRawFigure):FlxRawFigure {
		// if (!figureRaw.equals(newData))
		{
			figureRaw = newData;
			_updateVisibleIndexes();
		}
		return figureRaw;
	}
	// function set_tileGraphic(newGraphic:FlxGraphic):FlxGraphic {
	// 	graphic = tileGraphic = newGraphic;
	// 	return tileGraphic;
	// }

	public override function draw()
	{
		if (figureRaw != null && _visibleIndexes != null && _visibleIndexes.length != 0)
			super.draw();
	}

	override function drawFrameComplex(frame:FlxFrame, camera:FlxCamera):Void
	{
		final matrix = this._matrix; // TODO: Just use local?
		frame.prepareMatrix(matrix, FlxFrameAngle.ANGLE_0, checkFlipX(), checkFlipY());
		// matrix.scale(frameWidth / tileSize.x, frameHeight / tileSize.y);
		matrix.translate(-origin.x, -origin.y);
		matrix.scale(scale.x, scale.y);

		if (bakedRotationAngle <= 0)
		{
			updateTrig();

			if (angle != 0)
				matrix.rotateWithTrig(_cosAngle, _sinAngle);
		}

		getScreenPosition(_point, camera).subtract(offset);
		_point.add(origin.x, origin.y);
		matrix.translate(_point.x, _point.y);

		// var isColored:Bool = (colorTransform != null #if !html5 && colorTransform.hasRGBMultipliers() #end);
		// var hasColorOffsets:Bool = (colorTransform != null && colorTransform.hasRGBAOffsets());

		var drawItem = camera.startQuadBatch(frame.parent, true, true, blend, antialiasing, shader);

		var _tempPoint = FlxPoint.get();
		var tileOffset = FlxPoint.get().copyFrom(tileSize).scale(scale.x, scale.y);
		// tileOffset.subtract(origin.x, origin.y);
		// if (angle != 0)
		// 	tileOffset.rotateByDegrees(angle);
		// tileOffset.add(_point.x, _point.y);
		if (isPixelPerfectRender(camera))
		{
			matrix.tx = Math.floor(matrix.tx);
			matrix.ty = Math.floor(matrix.ty);
			tileOffset.floor();
		}

		var _tempColortransform = new ColorTransform();
		for (i in _visibleIndexes)
		{
			figureRaw.getPositionByIndex(i, _tempPoint);
			_tempPoint.scalePoint(tileOffset);

			matrix.translate(_tempPoint.x, _tempPoint.y);

			_tempColortransform.__copyFrom(this.colorTransform);
			_tempColortransform.scaleMultipliers(figureRaw.getPixelByIndex(i));

			drawItem.addQuad(frame, matrix, _tempColortransform);

			matrix.translate(-_tempPoint.x, -_tempPoint.y);
		}
		_tempPoint.put();
		tileOffset.put();
	}
}