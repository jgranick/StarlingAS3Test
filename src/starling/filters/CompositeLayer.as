package starling.filters
{
	import starling.textures.Texture;
	
	internal class CompositeLayer
	{
		public var texture:Texture;
		public var x:Number;
		public var y:Number;
		public var color:uint;
		public var alpha:Number;
		public var replaceColor:Boolean;

		public function CompositeLayer()
		{
			x = y = 0;
			alpha = 1.0;
			color = 0xffffff;
		}
	}
}