package starling.filters
{
	import flash.display3D.Context3D;
	import flash.display3D.Context3DProgramType;
	import flash.errors.ArgumentError;

	import starling.rendering.FilterEffect;
	import starling.rendering.Program;

	internal class ColorMatrixEffect extends FilterEffect
	{
		private var _userMatrix:Vector.<Number>;   // offset in range 0-255
		private var _shaderMatrix:Vector.<Number>; // offset in range 0-1, changed order

		private static const MIN_COLOR:Vector.<Number> = new <Number>[0, 0, 0, 0.0001];
		private static const IDENTITY:Array = [1,0,0,0,0,  0,1,0,0,0,  0,0,1,0,0,  0,0,0,1,0];

		// helpers
		private static var sMatrix:Vector.<Number> = new Vector.<Number>(20, true);

		public function ColorMatrixEffect():void
		{
			_userMatrix   = new <Number>[];
			_shaderMatrix = new <Number>[];

			this.matrix = null;
		}

		override protected function createProgram():Program
		{
			var vertexShader:String = FilterEffect.STD_VERTEX_SHADER;
			var fragmentShader:String = [
				tex("ft0", "v0", 0, texture),      // read texture color
				"max ft0, ft0, fc5              ", // avoid division through zero in next step
				"div ft0.xyz, ft0.xyz, ft0.www  ", // restore original (non-PMA) RGB values
				"m44 ft0, ft0, fc0              ", // multiply color with 4x4 matrix
				"add ft0, ft0, fc4              ", // add offset
				"mul ft0.xyz, ft0.xyz, ft0.www  ", // multiply with alpha again (PMA)
				"mov oc, ft0                    "  // copy to output
			].join("\n");

			return Program.fromSource(vertexShader, fragmentShader);
		}

		override protected function beforeDraw(context:Context3D):void
		{
			super.beforeDraw(context);

			context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, _shaderMatrix);
			context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 5, MIN_COLOR);
		}

		// matrix manipulation

		public function reset():void
		{
			matrix = null;
		}

		/** Concatenates the current matrix with another one. */
		public function concat(matrix:Vector.<Number>):void
		{
			var i:int = 0;

			for (var y:int=0; y<4; ++y)
			{
				for (var x:int=0; x<5; ++x)
				{
					sMatrix[i+x] = matrix[i    ] * _userMatrix[x     ] +
								matrix[i + 1] * _userMatrix[x +  5] +
								matrix[i + 2] * _userMatrix[x + 10] +
								matrix[i + 3] * _userMatrix[x + 15] +
								(x == 4 ? matrix[i + 4] : 0);
				}

				i += 5;
			}

			copyMatrix(sMatrix, _userMatrix);
			updateShaderMatrix();
		}

		private function copyMatrix(from:Vector.<Number>, to:Vector.<Number>):void
		{
			for (var i:int=0; i<20; ++i)
				to[i] = from[i];
		}

		private function updateShaderMatrix():void
		{
			// the shader needs the matrix components in a different order,
			// and it needs the offsets in the range 0-1.

			_shaderMatrix.length = 0;
			_shaderMatrix.push(
				_userMatrix[0 ], _userMatrix[ 1], _userMatrix[ 2], _userMatrix[ 3],
				_userMatrix[5 ], _userMatrix[ 6], _userMatrix[ 7], _userMatrix[ 8],
				_userMatrix[10], _userMatrix[11], _userMatrix[12], _userMatrix[13],
				_userMatrix[15], _userMatrix[16], _userMatrix[17], _userMatrix[18],
				_userMatrix[ 4] / 255.0, _userMatrix[9] / 255.0,  _userMatrix[14] / 255.0,
				_userMatrix[19] / 255.0
			);
		}

		// properties

		public function get matrix():Vector.<Number> { return _userMatrix; }
		public function set matrix(value:Vector.<Number>):void
		{
			if (value && value.length != 20)
				throw new ArgumentError("Invalid matrix length: must be 20");

			if (value == null)
			{
				_userMatrix.length = 0;
				_userMatrix.push.apply(_userMatrix, IDENTITY);
			}
			else
			{
				copyMatrix(value, _userMatrix);
			}

			updateShaderMatrix();
		}
	}
}