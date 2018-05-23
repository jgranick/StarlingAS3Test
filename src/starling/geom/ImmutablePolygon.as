package starling.geom
{
	// import flash.errors.Error;
	// import flash.errors.IllegalOperationError;
	import flash.utils.getQualifiedClassName;

	import starling.geom.Polygon;
	import starling.rendering.IndexData;

	internal class ImmutablePolygon extends Polygon
	{
		private var _frozen:Boolean;

		public function ImmutablePolygon(vertices:Array)
		{
			super(vertices);
			_frozen = true;
		}

		override public function addVertices(...args):void
		{
			if (_frozen) throw getImmutableError();
			else super.addVertices.apply(this, args);
		}

		override public function setVertex(index:int, x:Number, y:Number):void
		{
			if (_frozen) throw getImmutableError();
			else super.setVertex(index, x, y);
		}

		override public function reverse():void
		{
			if (_frozen) throw getImmutableError();
			else super.reverse();
		}

		override public function set numVertices(value:int):void
		{
			if (_frozen) throw getImmutableError();
			else super.reverse();
		}

		private function getImmutableError():Error
		{
			var className:String = getQualifiedClassName(this).split("::").pop();
			var msg:String = className + " cannot be modified. Call 'clone' to create a mutable copy.";
			// return new IllegalOperationError(msg);
			return new Error(msg);
		}
	}
}