package;

import openfl.display.Sprite;

class Main extends Sprite
{
	public function new()
	{
		super();
		FlxFigureRegistry.init();
		addChild(new FlxGame(0, 0, PlayState, true));
	}
}
