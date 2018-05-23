package starling.filters
{
	// import flash.errors.Error;
	import flash.geom.Matrix;
	import flash.geom.Rectangle;

	import starling.display.DisplayObject;
	import starling.display.Mesh;
	import starling.rendering.IndexData;
	import starling.rendering.VertexData;
	import starling.textures.Texture;

	internal class FilterQuad extends Mesh
	{
		private static var sMatrix:Matrix = new Matrix();

		public function FilterQuad(smoothing:String)
		{
			var vertexData:VertexData = new VertexData(null, 4);
			vertexData.numVertices = 4;

			var indexData:IndexData = new IndexData(6);
			indexData.addQuad(0, 1, 2, 3);

			super(vertexData, indexData);

			textureSmoothing = smoothing;
			pixelSnapping = false;
		}

		override public function dispose():void
		{
			disposeTexture();
			super.dispose();
		}

		public function disposeTexture():void
		{
			if (texture)
			{
				texture.dispose();
				texture = null;
			}
		}

		public function moveVertices(sourceSpace:DisplayObject, targetSpace:DisplayObject):void
		{
			if (targetSpace.is3D)
				throw new Error("cannot move vertices into 3D space");
			else if (sourceSpace != targetSpace)
			{
				targetSpace.getTransformationMatrix(sourceSpace, sMatrix).invert(); // ss could be null!
				vertexData.transformPoints("position", sMatrix);
			}
		}

		public function setBounds(bounds:Rectangle):void
		{
			var vertexData:VertexData = this.vertexData;
			var attrName:String = "position";

			vertexData.setPoint(0, attrName, bounds.x, bounds.y);
			vertexData.setPoint(1, attrName, bounds.right, bounds.y);
			vertexData.setPoint(2, attrName, bounds.x, bounds.bottom);
			vertexData.setPoint(3, attrName, bounds.right, bounds.bottom);
		}

		override public function set texture(value:Texture):void
		{
			super.texture = value;
			if (value) value.setupTextureCoordinates(vertexData);
		}
	}
}