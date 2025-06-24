package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.math.FlxPoint;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;

class PlayState extends FlxState
{
	var gridWidth:Int = 8;
	var gridHeight:Int = 8;
	var blockSize:Int = 50;
	var gridOffsetX:Int = 50;
	var gridOffsetY:Int = 50;

	var gridBGSpr:FlxSprite;
	var gridSpr:FlxFigure;
	var grid(get, set):FlxRawFigure;
	var currentPiece:FlxFigure;
	var nextPieces:Array<FlxFigure>;
	var score:Int = 0;
	var scoreText:FlxText;
	var movesLeft:Int = 25;
	var movesText:FlxText;

	var pieceShapes:Array<String>;

	override function create()
	{
		FlxFigureRegistry.instance.loadEntries();
		pieceShapes = FlxFigureRegistry.instance.listEntryIds();

		camera.bgColor = FlxColor.GRAY.getDarkened(0.3);
		super.create();
		resetGrid();

		initUI();

		createNextPieces(3);
	}

	function resetGrid():Void
	{
		var padding = 4;
		add(gridBGSpr = new FlxSprite(gridOffsetX - padding,
			gridOffsetY - padding).makeGraphic(gridWidth * blockSize + padding * 2, gridHeight * blockSize + padding * 2));
		gridSpr = constructFlxFigure(gridOffsetX, gridOffsetY, new FlxRawFigure(gridWidth, gridHeight));
		add(gridSpr);
		// grid = [for (y in 0...gridHeight) [for (x in 0...gridWidth) 0]];
	}

	function initUI():Void
	{
		// Score text
		scoreText = new FlxText(450, 50, 0, "Score: 0", 24);
		scoreText.color = FlxColor.BLACK;
		add(scoreText);

		// // Moves left
		// movesText = new FlxText(450, 100, 0, "Moves: 25", 24);
		// movesText.color = FlxColor.BLACK;
		// add(movesText);

		// // Instructions
		// var instructions = new FlxText(450, 150, 200, "Click to place blocks\n" + "Clear blocks by surrounding them\n" + "Complete levels to progress", 16);
		// instructions.color = FlxColor.BLACK;
		// add(instructions);
	}

	function constructFlxFigure(x, y, ?data):FlxFigure
	{
		var spr = new FlxFigure(x, y, data);
		spr.loadGraphic("assets/images/grid.png");
		return spr;
	}

	// var colors = [FlxColor.RED, FlxColor.BLUE, FlxColor.GREEN, FlxColor.YELLOW];
	var colors = [
		for (i in 0...18)
			FlxColor.fromHSB(FlxG.random.int(-10, 10) + i * 20, FlxG.random.float(0.8, 1.0), 1.0)
	];

	function createNextPieces(count:Int):Void
	{
		// Clear existing next pieces
		if (nextPieces != null)
		{
			for (piece in nextPieces)
			{
				remove(piece);
				piece.destroy();
			}
		}

		var _x = 0;
		nextPieces = [];
		var random = FlxG.random;
		for (i in 0...count)
		{
			var key = random.getObject(pieceShapes);
			var data = FlxFigureRegistry.instance.fetchEntry(key).data;
			if (data == null)
				continue;

			// trace(data.width, data.height);
			// trace(key);

			// var color = FlxColor.fromRGB(random.int(100, 255), random.int(100, 255), random.int(100, 255), 255);
			var color = random.getObject(colors);
			var piece = constructFlxFigure(11 + _x, 5, data);
			piece.color = color;
			nextPieces.push(piece);
			add(piece);

			_x += data.width * blockSize + 5;
		}
	}

	override public function update(elapsed:Float):Void
	{
		if (FlxG.keys.pressed.R)
		{
			FlxG.resetState();
			return;
		}

		super.update(elapsed);
		// Handle piece selection and placement
		if (FlxG.mouse.justPressed)
		{
			// Check if clicked on a next piece
			for (piece in nextPieces)
			{
				if (FlxG.mouse.overlaps(piece))
				{
					currentPiece = piece;
					currentPiece.alpha = 0.8;
					break;
				}
			}
		}

		if (currentPiece != null)
		{
			// Handle piece dragging
			if (FlxG.mouse.pressed)
			{
				// Snap to grid while dragging
				var gridX = Math.floor((FlxG.mouse.x - gridOffsetX) / blockSize - currentPiece.figureRaw.width / 4);
				var gridY = Math.floor((FlxG.mouse.y - gridOffsetY) / blockSize - currentPiece.figureRaw.height / 4);

				// Keep piece within grid bounds
				gridX = Math.floor(Math.max(0, Math.min(gridX, gridWidth - currentPiece.figureRaw.width)));
				gridY = Math.floor(Math.max(0, Math.min(gridY, gridHeight - currentPiece.figureRaw.height)));

				currentPiece.x = gridOffsetX + gridX * blockSize;
				currentPiece.y = gridOffsetY + gridY * blockSize;
			}

			// Handle piece placement
			if (FlxG.mouse.justReleased)
			{
				var gridX = Math.floor((currentPiece.x - gridOffsetX) / blockSize);
				var gridY = Math.floor((currentPiece.y - gridOffsetY) / blockSize);
				if (canPlacePiece(currentPiece, gridX, gridY))
				{
					placePiece(currentPiece, gridX, gridY);
					checkClearedBlocks();
					// movesLeft--;
					// movesText.text = "Moves: " + movesLeft;

					nextPieces.remove(currentPiece);
					currentPiece.destroy();

					if (nextPieces.length == 0)
					{
						// Replace used piece
						createNextPieces(3);
					}

					// Game over check
					if (movesLeft <= 0)
					{
						FlxG.resetState();
						// FlxG.switchState(new GameOverState(score));
					}
				}
				else
				{
					currentPiece.alpha = 0.9;
				}
				// Reset current piece
				currentPiece = null;
			}
		}
	}

	function canPlacePiece(piece:FlxFigure, gridX:Int, gridY:Int):Bool
	{
		for (x in 0...piece.figureRaw.width)
		{
			for (y in 0...piece.figureRaw.height)
			{
				if (piece.figureRaw.getPixel(x, y) != FlxColor.TRANSPARENT)
				{
					var checkX = gridX + x;
					var checkY = gridY + y;

					// Check if out of bounds
					if (checkX < 0 || checkX >= gridWidth || checkY < 0 || checkY >= gridHeight)
					{
						return false;
					}

					// Check if space is already occupied

					if (grid.getPixel(checkX, checkY) != FlxColor.TRANSPARENT)
					{
						return false;
					}
				}
			}
		}
		return true;
	}

	function placePiece(piece:FlxFigure, gridX:Int, gridY:Int):Void
	{
		var thatColor = piece.color.getDarkened(0.2);
		for (x in 0...piece.figureRaw.width)
		{
			for (y in 0...piece.figureRaw.height)
			{
				if (piece.figureRaw.getPixel(x, y) != FlxColor.TRANSPARENT)
				{
					var placeX = gridX + x;
					var placeY = gridY + y;

					grid.setPixel(placeX, placeY, thatColor * piece.figureRaw.getPixel(x, y));
				}
			}
		}
		grid = grid;
	}

	var _blocksToClear:List<UInt> = new List();

	function checkClearedBlocks():Void
	{
		var scoreToAdd = 0;

		for (x in 0...grid.width)
		{
			var addIt = true;
			for (y in 0...grid.height)
			{
				if (grid.getPixel(x, y) == FlxColor.TRANSPARENT)
				{
					addIt = false;
					break;
				}
			}
			if (addIt)
			{
				for (y in 0...grid.height)
					_blocksToClear.push(x + y * grid.width);
				scoreToAdd += 10;
			}
		}

		for (y in 0...grid.height)
		{
			var addIt = true;
			for (x in 0...grid.width)
			{
				if (grid.getPixel(x, y) == FlxColor.TRANSPARENT)
				{
					addIt = false;
					break;
				}
			}
			if (addIt)
			{
				for (x in 0...grid.width)
					_blocksToClear.push(x + y * grid.width);
				scoreToAdd += 10;
			}
		}

		for (index in _blocksToClear)
		{
			grid.setPixelByIndex(index, FlxColor.TRANSPARENT);
		}
		if (_blocksToClear.length != 0)
			_blocksToClear.clear();

		// Update score
		if (scoreToAdd > 0)
		{
			score += scoreToAdd;
			scoreText.text = "Score: " + score;
		}
	}

	inline function get_grid()
	{
		return gridSpr.figureRaw;
	}

	inline function set_grid(i)
	{
		return gridSpr.figureRaw = i;
	}
}
