package;


interface IRegistryEntry<T>
{
	public var id:String;
    
    // public function new(id:String):Void;
    public function destroy():Void;
    public function toString():String;
    
    // Can't make an interface field private I guess.
	public var data:T;
    // Can't make a static field required by an interface I guess.
    // private static function _fetchData(id:String):Null<T>;
}
