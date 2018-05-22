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
    import flash.geom.Rectangle;

    import starling.display.Stage;
    import starling.rendering.FilterEffect;
    import starling.rendering.Painter;
    import starling.textures.Texture;

    /** The DisplacementMapFilter class uses the pixel values from the specified texture (called
     *  the map texture) to perform a displacement of an object. You can use this filter
     *  to apply a warped or mottled effect to any object that inherits from the DisplayObject
     *  class.
     *
     *  <p>The filter uses the following formula:</p>
     *  <listing>dstPixel[x, y] = srcPixel[x + ((componentX(x, y) - 128) &#42; scaleX) / 256,
     *                      y + ((componentY(x, y) - 128) &#42; scaleY) / 256]
     *  </listing>
     *
     *  <p>Where <code>componentX(x, y)</code> gets the componentX property color value from the
     *  map texture at <code>(x - mapX, y - mapY)</code>.</p>
     *
     *  <strong>Clamping to the Edges</strong>
     *
     *  <p>Per default, the filter allows the object to grow beyond its actual bounds to make
     *  room for the displacement (depending on <code>scaleX/Y</code>). If you want to clamp the
     *  displacement to the actual object bounds, set all margins to zero via a call to
     *  <code>filter.padding.setTo()</code>. This works only with rectangular, stage-aligned
     *  objects, though.</p>
     */
    public class DisplacementMapFilter extends FragmentFilter
    {
        private var _mapX:Number;
        private var _mapY:Number;

        // helpers
        private static var sBounds:Rectangle = new Rectangle();

        /** Creates a new displacement map filter that uses the provided map texture. */
        public function DisplacementMapFilter(mapTexture:Texture,
                                              componentX:uint=0, componentY:uint=0,
                                              scaleX:Number=0.0, scaleY:Number=0.0)
        {
            _mapX = _mapY = 0;

            this.mapTexture = mapTexture;
            this.componentX = componentX;
            this.componentY = componentY;
            this.scaleX = scaleX;
            this.scaleY = scaleY;
        }

        /** @private */
        override public function process(painter:Painter, pool:IFilterHelper,
                                         input0:Texture = null, input1:Texture = null,
                                         input2:Texture = null, input3:Texture = null):Texture
        {
            var offsetX:Number = 0.0, offsetY:Number = 0.0;
            var targetBounds:Rectangle = pool.targetBounds;
            var stage:Stage = pool.target.stage;

            if (stage && (targetBounds.x < 0 || targetBounds.y < 0))
            {
                // 'targetBounds' is actually already intersected with the stage bounds.
                // If the target is partially outside the stage at the left or top, we need
                // to adjust the map coordinates accordingly. That's what 'offsetX/Y' is for.

                pool.target.getBounds(stage, sBounds);
                sBounds.inflate(padding.left, padding.top);
                offsetX = sBounds.x - pool.targetBounds.x;
                offsetY = sBounds.y - pool.targetBounds.y;
            }

            updateVertexData(input0, mapTexture, offsetX, offsetY);
            return super.process(painter, pool, input0);
        }

        /** @private */
        override protected function createEffect():FilterEffect
        {
            return new DisplacementMapEffect();
        }

        private function updateVertexData(inputTexture:Texture, mapTexture:Texture,
                                          mapOffsetX:Number=0.0, mapOffsetY:Number=0.0):void
        {
            // The size of input texture and map texture may be different. We need to calculate
            // the right values for the texture coordinates at the filter vertices.

            var mapX:Number = (_mapX + mapOffsetX + padding.left) / mapTexture.width;
            var mapY:Number = (_mapY + mapOffsetY + padding.top)  / mapTexture.height;
            var maxU:Number = inputTexture.width  / mapTexture.width;
            var maxV:Number = inputTexture.height / mapTexture.height;

            mapTexture.setTexCoords(vertexData, 0, "mapTexCoords", -mapX, -mapY);
            mapTexture.setTexCoords(vertexData, 1, "mapTexCoords", -mapX + maxU, -mapY);
            mapTexture.setTexCoords(vertexData, 2, "mapTexCoords", -mapX, -mapY + maxV);
            mapTexture.setTexCoords(vertexData, 3, "mapTexCoords", -mapX + maxU, -mapY + maxV);
        }

        private function updatePadding():void
        {
            var paddingX:Number = Math.ceil(Math.abs(dispEffect.scaleX) / 2);
            var paddingY:Number = Math.ceil(Math.abs(dispEffect.scaleY) / 2);

            padding.setTo(paddingX, paddingX, paddingY, paddingY);
        }

        // properties

        /** Describes which color channel to use in the map image to displace the x result.
         *  Possible values are constants from the BitmapDataChannel class. */
        public function get componentX():uint { return dispEffect.componentX; }
        public function set componentX(value:uint):void
        {
            if (dispEffect.componentX != value)
            {
                dispEffect.componentX = value;
                setRequiresRedraw();
            }
        }

        /** Describes which color channel to use in the map image to displace the y result.
         *  Possible values are constants from the BitmapDataChannel class. */
        public function get componentY():uint { return dispEffect.componentY; }
        public function set componentY(value:uint):void
        {
            if (dispEffect.componentY != value)
            {
                dispEffect.componentY = value;
                setRequiresRedraw();
            }
        }

        /** The multiplier used to scale the x displacement result from the map calculation. */
        public function get scaleX():Number { return dispEffect.scaleX; }
        public function set scaleX(value:Number):void
        {
            if (dispEffect.scaleX != value)
            {
                dispEffect.scaleX = value;
                updatePadding();
            }
        }

        /** The multiplier used to scale the y displacement result from the map calculation. */
        public function get scaleY():Number { return dispEffect.scaleY; }
        public function set scaleY(value:Number):void
        {
            if (dispEffect.scaleY != value)
            {
                dispEffect.scaleY = value;
                updatePadding();
            }
        }

        /** The horizontal offset of the map texture relative to the origin. @default 0 */
        public function get mapX():Number { return _mapX; }
        public function set mapX(value:Number):void { _mapX = value; setRequiresRedraw(); }

        /** The vertical offset of the map texture relative to the origin. @default 0 */
        public function get mapY():Number { return _mapY; }
        public function set mapY(value:Number):void { _mapY = value; setRequiresRedraw(); }

        /** The texture that will be used to calculate displacement. */
        public function get mapTexture():Texture { return dispEffect.mapTexture; }
        public function set mapTexture(value:Texture):void
        {
            if (dispEffect.mapTexture != value)
            {
                dispEffect.mapTexture = value;
                setRequiresRedraw();
            }
        }

        /** Indicates if pixels at the edge of the map texture will be repeated.
         *  Note that this only works if the map texture is a power-of-two texture!
         */
        public function get mapRepeat():Boolean { return dispEffect.mapRepeat; }
        public function set mapRepeat(value:Boolean):void
        {
            if (dispEffect.mapRepeat != value)
            {
                dispEffect.mapRepeat = value;
                setRequiresRedraw();
            }
        }

        private function get dispEffect():DisplacementMapEffect
        {
            return this.effect as DisplacementMapEffect;
        }
    }
}