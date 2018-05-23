package starling.geom
{
	import starling.geom.ImmutablePolygon;
	import starling.rendering.IndexData;
	
	internal class Ellipse extends ImmutablePolygon
	{
		private var _x:Number;
		private var _y:Number;
		private var _radiusX:Number;
		private var _radiusY:Number;

		public function Ellipse(x:Number, y:Number, radiusX:Number, radiusY:Number, numSides:int = -1)
		{
			_x = x;
			_y = y;
			_radiusX = radiusX;
			_radiusY = radiusY;

			super(getVertices(numSides));
		}

		private function getVertices(numSides:int):Array
		{
			if (numSides < 0) numSides = Math.PI * (_radiusX + _radiusY) / 4.0;
			if (numSides < 6) numSides = 6;

			var vertices:Array = [];
			var angleDelta:Number = 2 * Math.PI / numSides;
			var angle:Number = 0;

			for (var i:int=0; i<numSides; ++i)
			{
				vertices[i * 2    ] = Math.cos(angle) * _radiusX + _x;
				vertices[i * 2 + 1] = Math.sin(angle) * _radiusY + _y;
				angle += angleDelta;
			}

			return vertices;
		}

		override public function triangulate(indexData:IndexData=null, offset:int=0):IndexData
		{
			if (indexData == null) indexData = new IndexData((numVertices - 2) * 3);

			var from:uint = 1;
			var to:uint = numVertices - 1;

			for (var i:int=from; i<to; ++i)
				indexData.addTriangle(offset, offset + i, offset + i + 1);

			return indexData;
		}

		override public function contains(x:Number, y:Number):Boolean
		{
			var vx:Number = x - _x;
			var vy:Number = y - _y;

			var a:Number = vx / _radiusX;
			var b:Number = vy / _radiusY;

			return a * a + b * b <= 1;
		}

		override public function get area():Number
		{
			return Math.PI * _radiusX * _radiusY;
		}

		override public function get isSimple():Boolean
		{
			return true;
		}

		override public function get isConvex():Boolean
		{
			return true;
		}
	}
}