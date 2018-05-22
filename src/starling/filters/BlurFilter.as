// =================================================================================================
//
//	Starling Framework
//	Copyright Gamua GmbH. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package starling.filters
{
    import starling.core.Starling;
    import starling.rendering.FilterEffect;
    import starling.rendering.Painter;
    import starling.textures.Texture;
    import starling.utils.MathUtil;

    /** The BlurFilter applies a Gaussian blur to an object. The strength of the blur can be
     *  set for x- and y-axis separately. */
    public class BlurFilter extends FragmentFilter
    {
        private var _blurX:Number;
        private var _blurY:Number;
        private var _quality:Number;

        /** Create a new BlurFilter.
         *
         *  <p>The blur is rendered for each direction (x and y) separately; the number of
         *  draw calls add up. The blur value itself is internally multiplied with the current
         *  <code>contentScaleFactor</code> in order to guarantee a consistent look on HiDPI
         *  displays (dubbed 'totalBlur' below).</p>
         *
         *  <p>The number of draw calls per blur value is the following:</p>
         *  <ul><li>totalBlur &lt;= 1: 1 draw call</li>
         *      <li>totalBlur &lt;= 2: 2 draw calls</li>
         *      <li>totalBlur &lt;= 4: 3 draw calls</li>
         *      <li>totalBlur &lt;= 8: 4 draw calls</li>
         *      <li>... etc.</li>
         *  </ul>
         */
        public function BlurFilter(blurX:Number=1.0, blurY:Number=1.0, resolution:Number=1.0)
        {
            _blurX = Math.abs(blurX);
            _blurY = Math.abs(blurY);
            _quality = 1.0;
            this.resolution = resolution;
            this.maintainResolutionAcrossPasses = true;
        }

        /** @private */
        override public function process(painter:Painter, helper:IFilterHelper,
                                         input0:Texture = null, input1:Texture = null,
                                         input2:Texture = null, input3:Texture = null):Texture
        {
            var effect:BlurEffect = this.effect as BlurEffect;

            if (_blurX == 0 && _blurY == 0)
            {
                effect.strength = 0;
                return super.process(painter, helper, input0);
            }

            var inTexture:Texture;
            var outTexture:Texture = input0;
            var strengthX:Number = totalBlurX;
            var strengthY:Number = totalBlurY;

            effect.quality = _quality;
            effect.direction = BlurEffect.HORIZONTAL;

            while (strengthX > 0)
            {
                effect.strength = strengthX;

                inTexture = outTexture;
                outTexture = super.process(painter, helper, inTexture);

                if (inTexture != input0) helper.putTexture(inTexture);
                if (strengthX <= 1) break; else strengthX /= 2;
            }

            effect.direction = BlurEffect.VERTICAL;

            while (strengthY > 0)
            {
                effect.strength = strengthY;

                inTexture = outTexture;
                outTexture = super.process(painter, helper, inTexture);

                if (inTexture != input0) helper.putTexture(inTexture);
                if (strengthY <= 1) break; else strengthY /= 2;
            }

            return outTexture;
        }

        /** @private */
        override protected function createEffect():FilterEffect
        {
            return new BlurEffect();
        }

        /** @private */
        override public function set resolution(value:Number):void
        {
            super.resolution = value;
            updatePadding();
        }

        private function updatePadding():void
        {
            var paddingX:Number = _blurX ? (totalBlurX * 3 + 2) / (resolution * _quality) : 0;
            var paddingY:Number = _blurY ? (totalBlurY * 3 + 2) / (resolution * _quality) : 0;

            padding.setTo(paddingX, paddingX, paddingY, paddingY);
        }

        /** @private */
        override public function get numPasses():int
        {
            if (_blurX == 0 && _blurY == 0) return 1;
            else return getNumPasses(totalBlurX) + getNumPasses(totalBlurY);
        }

        private static function getNumPasses(blur:Number):int
        {
            var numPasses:int = 1;
            while (blur > 1) { numPasses += 1; blur /= 2; }
            return numPasses;
        }

        /** The blur values scaled by the current contentScaleFactor. */
        private function get totalBlurX():Number { return _blurX * Starling.contentScaleFactor; }
        private function get totalBlurY():Number { return _blurY * Starling.contentScaleFactor; }

        /** The blur factor in x-direction. */
        public function get blurX():Number { return _blurX; }
        public function set blurX(value:Number):void
        {
            if (_blurX != value)
            {
                _blurX = Math.abs(value);
                updatePadding();
            }

        }

        /** The blur factor in y-direction. */
        public function get blurY():Number { return _blurY; }
        public function set blurY(value:Number):void
        {
            if (_blurY != value)
            {
                _blurY = Math.abs(value);
                updatePadding();
            }
        }

        /** The quality of the blur effect. Low values will look as if the target was drawn
         *  multiple times in close proximity (range: 0.1 - 1).
         *
         *  <p>Typically, it's better to reduce the filter resolution instead; however, if that
         *  is not an option (e.g. when using the BlurFilter as part of a composite filter),
         *  this property may provide an alternative.</p>
         *
         *  @default 1.0
         */
        public function get quality():Number { return _quality; }
        public function set quality(value:Number):void
        {
            if (_quality != value)
            {
                _quality = MathUtil.clamp(value, 0.1, 1.0);
                updatePadding();
            }
        }
    }
}