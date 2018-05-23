package starling.geom
{
	import starling.geom.ImmutablePolygon;
	import starling.rendering.IndexData;
	
	internal class Rectangle extends ImmutablePolygon
	{
		private var _x:Number;
		private var _y:Number;
		private var _width:Number;
		private var _height:Number;

		public function Rectangle(x:Number, y:Number, width:Number, height:Number)
		{
			_x = x;
			_y = y;
			_width = width;
			_height = height;

			super([x, y, x + width, y, x + width, y + height, x, y + height]);
		}

		override public function triangulate(indexData:IndexData=null, offset:int=0):IndexData
		{
			if (indexData == null) indexData = new IndexData(6);

			indexData.addTriangle(offset,     offset + 1, offset + 3);
			indexData.addTriangle(offset + 1, offset + 2, offset + 3);

			return indexData;
		}

		override public function contains(x:Number, y:Number):Boolean
		{
			return x >= _x && x <= _x + _width &&
				y >= _y && y <= _y + _height;
		}

		override public function get area():Number
		{
			return _width * _height;
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