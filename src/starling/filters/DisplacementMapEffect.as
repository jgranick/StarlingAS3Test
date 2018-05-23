package starling.filters
{
	import flash.display.BitmapDataChannel;
	import flash.display3D.Context3D;
	import flash.display3D.Context3DProgramType;
	import flash.geom.Matrix3D;

	import starling.core.Starling;
	import starling.rendering.FilterEffect;
	import starling.rendering.Program;
	import starling.rendering.VertexDataFormat;
	import starling.textures.Texture;
	import starling.utils.RenderUtil;

	internal class DisplacementMapEffect extends FilterEffect
	{
		public static const VERTEX_FORMAT:VertexDataFormat =
			VertexDataFormat.fromString("position:float2").extend("texCoords:float2").extend("mapTexCoords:float2");

		private var _mapTexture:Texture;
		private var _mapRepeat:Boolean;
		private var _componentX:uint;
		private var _componentY:uint;
		private var _scaleX:Number;
		private var _scaleY:Number;

		// helper objects
		private static var sOffset:Vector.<Number>  = new <Number>[0.5, 0.5, 0.0, 0.0];
		private static var sClampUV:Vector.<Number> = new <Number>[0.0, 0.0, 0.0, 0.0];
		private static var sMatrix:Matrix3D = new Matrix3D();
		private static var sMatrixData:Vector.<Number> =
			new <Number>[0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0];

		public function DisplacementMapEffect()
		{
			_componentX = _componentY = 0;
			_scaleX = _scaleY = 0;
		}

		override protected function createProgram():Program
		{
			if (_mapTexture)
			{
				// vc0-3: mvpMatrix
				// va0:   vertex position
				// va1:   input texture coords
				// va2:   map texture coords

				var vertexShader:String = [
					"m44  op, va0, vc0", // 4x4 matrix transform to output space
					"mov  v0, va1",      // pass input texture coordinates to fragment program
					"mov  v1, va2"       // pass map texture coordinates to fragment program
				].join("\n");

				// v0:    input texCoords
				// v1:    map texCoords
				// fc0:   offset (0.5, 0.5)
				// fc1:   clampUV (max value for U and V, stored in x and y)
				// fc2-5: matrix

				var fragmentShader:String = [
					tex("ft0", "v1", 1, _mapTexture, false), // read map texture
					"sub ft1, ft0, fc0",          // subtract 0.5 -> range [-0.5, 0.5]
					"mul ft1.xy, ft1.xy, ft0.ww", // zero displacement when alpha == 0
					"m44 ft2, ft1, fc2",          // multiply matrix with displacement values
					"add ft3,  v0, ft2",          // add displacement values to texture coords
					"sat ft3.xy, ft3.xy",         // move texture coords into range 0-1
					"min ft3.xy, ft3.xy, fc1.xy", // move texture coords into range 0-maxUV
					tex("oc", "ft3", 0, texture)  // read input texture at displaced coords
				].join("\n");

				return Program.fromSource(vertexShader, fragmentShader);
			}
			else return super.createProgram();
		}

		override protected function beforeDraw(context:Context3D):void
		{
			super.beforeDraw(context);

			if (_mapTexture)
			{
				// already set by super class:
				//
				// vertex constants 0-3: mvpMatrix (3D)
				// vertex attribute 0:   vertex position (FLOAT_2)
				// vertex attribute 1:   texture coordinates (FLOAT_2)
				// texture 0:            input texture

				getMapMatrix(sMatrix);

				sClampUV[0] = texture.width  / texture.root.width  - 0.5 / texture.root.nativeWidth;
				sClampUV[1] = texture.height / texture.root.height - 0.5 / texture.root.nativeHeight;
				var mapRepeat:Boolean = _mapRepeat && _mapTexture.root.isPotTexture;

				vertexFormat.setVertexBufferAt(2, vertexBuffer, "mapTexCoords");
				context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, sOffset);
				context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 1, sClampUV);
				context.setProgramConstantsFromMatrix(Context3DProgramType.FRAGMENT, 2, sMatrix, true);
				RenderUtil.setSamplerStateAt(1, _mapTexture.mipMapping, textureSmoothing, mapRepeat);
				context.setTextureAt(1, _mapTexture.base);
			}
		}

		override protected function afterDraw(context:Context3D):void
		{
			if (_mapTexture)
			{
				context.setVertexBufferAt(2, null);
				context.setTextureAt(1, null);
			}

			super.afterDraw(context);
		}

		override public function get vertexFormat():VertexDataFormat
		{
			return VERTEX_FORMAT;
		}

		/** This matrix maps RGBA values of the map texture to UV-offsets in the input texture. */
		private function getMapMatrix(out:Matrix3D):Matrix3D
		{
			if (out == null) out = new Matrix3D();

			var columnX:int, columnY:int;
			var scale:Number = Starling.contentScaleFactor;
			var textureWidth:Number  = texture.root.nativeWidth;
			var textureHeight:Number = texture.root.nativeHeight;

			for (var i:int=0; i<16; ++i)
				sMatrixData[i] = 0;

			if      (_componentX == BitmapDataChannel.RED)   columnX = 0;
			else if (_componentX == BitmapDataChannel.GREEN) columnX = 1;
			else if (_componentX == BitmapDataChannel.BLUE)  columnX = 2;
			else                                             columnX = 3;

			if      (_componentY == BitmapDataChannel.RED)   columnY = 0;
			else if (_componentY == BitmapDataChannel.GREEN) columnY = 1;
			else if (_componentY == BitmapDataChannel.BLUE)  columnY = 2;
			else                                             columnY = 3;

			sMatrixData[int(columnX * 4    )] = _scaleX * scale / textureWidth;
			sMatrixData[int(columnY * 4 + 1)] = _scaleY * scale / textureHeight;

			out.copyRawDataFrom(sMatrixData);

			return out;
		}

		// properties

		public function get componentX():uint { return _componentX; }
		public function set componentX(value:uint):void { _componentX = value; }

		public function get componentY():uint { return _componentY; }
		public function set componentY(value:uint):void { _componentY = value; }

		public function get scaleX():Number { return _scaleX; }
		public function set scaleX(value:Number):void { _scaleX = value; }

		public function get scaleY():Number { return _scaleY; }
		public function set scaleY(value:Number):void { _scaleY = value; }

		public function get mapTexture():Texture { return _mapTexture; }
		public function set mapTexture(value:Texture):void { _mapTexture = value; }

		public function get mapRepeat():Boolean { return _mapRepeat; }
		public function set mapRepeat(value:Boolean):void { _mapRepeat = value; }
	}

}