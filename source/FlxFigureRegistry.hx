package;

import sys.io.File;

class FlxFigureRegistry extends BaseRegistry<FlxFigureEntry, FlxRawFigure>
{
	public static var instance(get, never):FlxFigureRegistry;

	static var _instance:Null<FlxFigureRegistry> = null;
	static function get_instance():FlxFigureRegistry
	{
		if (_instance == null) _instance = new FlxFigureRegistry();
		return _instance;
	}

	public static function init() {
		if (_instance == null) _instance = new FlxFigureRegistry();
	}

	public function new()
	{
		super('FIGURES', 'figures');
	}

	public function parseEntryData(id:String):Null<FlxRawFigure>
	{
		switch (loadEntryFile(id))
		{
			case {fileName: fileName, contents: contents}:
				return FlxRawFigure.deserializationCSV(contents);
			default:
				return null;
		}
	}

	public function parseEntryDataRaw(contents:String, ?fileName:String):Null<FlxRawFigure>
	{
		return FlxRawFigure.deserializationCSV(contents);
	}

	override function loadEntryFile(id:String):{
		fileName:String,
		contents:String
	}
	{
		var entryFilePath:String = '$storageDirectoryPath/$dataFilePath/$id';
		var rawJson:String = File.getContent(entryFilePath).trim();
		return {
			fileName: entryFilePath,
			contents: rawJson
		};
	}
}

class FlxFigureEntry implements IRegistryEntry<FlxRawFigure> {
	
	public var id:String;

	public var data:FlxRawFigure;

	public function new(id:String)
	{
		this.id = id;
		data = FlxFigureRegistry.instance.parseEntryData(id);

		if (data == null)
		{
			throw 'Could not parse level data for id: $id';
		}
	}

	public function destroy():Void
	{
		data = null;
	}
	public function toString():String
	{
		return 'FlxFigureEntry($id)';
	}

}