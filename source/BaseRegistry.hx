package;

import haxe.Constraints;
import sys.FileSystem;
import sys.io.File;

using Lambda;

@:generic
abstract class BaseRegistry<T:(IRegistryEntry<J> & Constructible<String->Void>), J>
{
	public final registryId:String;

	final storageDirectoryPath:String;
	final dataFilePath:String;

	final entries:Map<String, T>;

	public function new(registryId:String, dataFilePath:String, ?storageDirectoryPath:String)
	{
		this.registryId = registryId;
		this.dataFilePath = dataFilePath;
		this.storageDirectoryPath = storageDirectoryPath ?? "assets/data";

		this.entries = new Map<String, T>();
	}

	public function loadEntries():Void
	{
		clearEntries();

		var entryIdList:Array<String> = FileSystem.readDirectory('$storageDirectoryPath/$dataFilePath/');
		trace('Parsing ${entryIdList.length} entries...');
		for (entryId in entryIdList)
		{
			try
			{
				var entry:T = createEntry(entryId);
				if (entry != null)
				{
					trace('	Loaded entry data: ${entry.id}');
					entries.set(entry.id, entry);
				}
			}
			catch (e)
			{
				// Print the error.
				trace('	Failed to load entry data: ${entryId}');
				trace(e);
				continue;
			}
		}
	}

    
	public function listEntryIds():Array<String>
	{
		return [for (i in entries.keys()) i];
	}

	public function countEntries():Int
	{
		return [for (i in entries.keys()) i].length;
	}

    
	public function hasEntry(id:String):Bool
	{
		return entries.exists(id);
	}

	public function fetchEntry(id:String):Null<T>
	{
		return entries.get(id);
	}

	public function toString():String
	{
		return 'Registry(' + registryId + ', ${countEntries()} entries)';
	}

	function loadEntryFile(id:String):{
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

	function clearEntries():Void
	{
		for (entry in entries)
		{
			entry.destroy();
		}

		entries.clear();
	}

	public abstract function parseEntryData(id:String):Null<J>;

	public abstract function parseEntryDataRaw(contents:String, ?fileName:String):Null<J>;

	function createEntry(id:String):Null<T>
	{
		// We enforce that T is Constructible to ensure this is valid.
		return new T(id);
	}
}