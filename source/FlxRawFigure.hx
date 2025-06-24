package;

import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.util.FlxArrayUtil;
import flixel.util.FlxColor;

abstract FlxRawFigure(Array<FlxColor>) from Array<Int> to Array<Int> to Array<FlxColor>
{
    public var width(get, set):Int;
    public var height(get, set):Int;
	public function new(width:UInt, height:UInt, ?data:Array<FlxColor>)
	{
		this = data?.copy() ?? [];

		var totalLength = width * height;
		// trace(totalLength, width, height);
		// trace(this.length);
		if (this.length > totalLength)
			this.splice(totalLength, this.length);
		else
			while (this.length < totalLength)
				this.push(FlxColor.TRANSPARENT);

		this.unshift(height);
		this.unshift(width);
	}
	public function getPixelByIndex(index:UInt):FlxColor
	{
		return this[index + 2] ?? FlxColor.TRANSPARENT;
	}
	public inline function setPixelByIndex(index:UInt, color:FlxColor) {
		this[index + 2] = color;
	}
	public inline function getPixel(x:UInt, y:UInt):FlxColor {
		return getPixelByIndex(x + y * width);
	}
	public inline function setPixel(x:UInt, y:UInt, color:FlxColor) {
		setPixelByIndex(x + y * width, color);
	}
	public function getPositionByIndex(index:UInt, ?point:FlxPoint):FlxPoint
	{
		point ??= FlxPoint.get();
		return point.set(index % width, Math.floor(index / width) % height);
	}

	public inline function equals(i:FlxRawFigure):Bool {
		return FlxArrayUtil.equals(this, i);
	}
	public function merge(i:FlxRawFigure, offsetX:Int = 0, offsetY:Int = 0):FlxRawFigure {
		
		var data = cloneData();
		var newData = i.cloneData();
		
		var totalMinWidth:Int = FlxMath.minInt(width, i.width);
		var totalMinHeight:Int = FlxMath.minInt(height, i.height);
		var totalMaxWidth:Int = FlxMath.maxInt(width, i.width);
		var totalMaxHeight:Int = FlxMath.maxInt(height, i.height);

		offsetX = Math.floor(FlxMath.bound(offsetX, -totalMaxWidth, totalMaxWidth));
		offsetY = Math.floor(FlxMath.bound(offsetY, -totalMaxHeight, totalMaxHeight));

		var prevData = [];
		prevData.resize(totalMaxHeight * totalMaxWidth);
		for (y in totalMinWidth...totalMaxWidth)
		{
			for (x in totalMinHeight...totalMaxHeight)
			{
				prevData[x + y * totalMaxWidth] = x < width || y < height ? newData[x - offsetX + (y - offsetY) * i.width] : data[x + y * width];
			}
		}

		return new FlxRawFigure(totalMaxWidth, totalMaxHeight);
	}
	public function resize(newWidth:UInt, newHeight:UInt)
	{
		if (newWidth == width && newHeight == height) return;

		var newTotalLength = newWidth * newHeight;
		var prevData = cloneData();
		for (y in 0...newHeight)
		{
			for (x in 0...newWidth)
			{
				this[x + y * newWidth] = x >= width || y >= height ? 0 : prevData[x + y * width];
			}
		}
		this.splice(2 + newTotalLength, this.length); // remove unchaged part

	}
	public function cloneData():Array<FlxColor>
	{
		var data = this.copy();
		data.splice(0, 2);
		return data;
	}
	public inline function clone():FlxRawFigure
	{
		return this.copy();
	}
	public static function deserializationCSV(input:String):Null<FlxRawFigure>
	{
		var readPos:Int = 0;
		// var neededToFillIt:Bool = false;
		var totalWidth:Int = 1;
		var totalHeight:Int = 1;
		var firstLine = true;
		var i:Int = 0;
		var arr:Array<FlxColor> = [];
		var nextBool:Null<Bool> = null; // todo: allow forse color?
		while (true)
		{
			switch StringTools.fastCodeAt(input, readPos++)
			{
				case ','.code | ';'.code:
					i++;
					if (nextBool == null)
						arr.push(FlxColor.TRANSPARENT);
					else
						nextBool = null;

				case 10: // LF
					if (i != 0)
					{
						if (firstLine)
							totalWidth = i + 1;
						// else if (totalWidth != i)
						// 	while (arr.length - totalHeight * totalWidth <= i)
						// 	{
						// 		arr.push(FlxColor.TRANSPARENT);
						// 	}
						firstLine = false;
					}
					totalHeight++;
					i = 0;
					nextBool = null;

				case ' '.code | '\t'.code | 13:

				case c:
					if (StringTools.isEof(c))
						break;
					if (nextBool == null)
					{
						nextBool = c != '0'.code;
						arr.push(nextBool ? FlxColor.WHITE : FlxColor.TRANSPARENT);
					}
			}
		}
		if (arr.length != 0 && totalWidth == 0)
		{
			totalWidth = 1;
		}
		if (totalHeight == 0 || totalWidth == 0)
			return null;
		else if (i == 0 && totalHeight > 1 && totalWidth > 0)
		{
			totalHeight--;
		}
		return new FlxRawFigure(totalWidth, totalHeight, arr);
	}

	public function forEach(job:(index:UInt) -> FlxColor)
	{
		var i:UInt = 2;
		while (i < this.length)
		{
			setPixelByIndex(i - 2, job(i - 2));
			i++;
		}
	}

	inline function get_width() return this[0];
	inline function set_width(i) return this[0] = i;
	inline function get_height() return this[1];
	inline function set_height(i) return this[1] = i;
}