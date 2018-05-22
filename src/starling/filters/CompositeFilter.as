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
    import flash.geom.Point;

    import starling.rendering.FilterEffect;
    import starling.rendering.Painter;
    import starling.textures.Texture;
    import starling.utils.MathUtil;

    /** The CompositeFilter class allows to combine several layers of textures into one texture.
     *  It's mainly used as a building block for more complex filters; e.g. the DropShadowFilter
     *  uses this class to draw the shadow (the result of a BlurFilter) behind an object.
     */
    public class CompositeFilter extends FragmentFilter
    {
        /** Creates a new instance. */
        public function CompositeFilter()
        { }

        /** Combines up to four input textures into one new texture,
         *  adhering to the properties of each layer. */
        override public function process(painter:Painter, helper:IFilterHelper,
                                         input0:Texture = null, input1:Texture = null,
                                         input2:Texture = null, input3:Texture = null):Texture
        {
            compositeEffect.texture = input0;
            compositeEffect.getLayerAt(1).texture = input1;
            compositeEffect.getLayerAt(2).texture = input2;
            compositeEffect.getLayerAt(3).texture = input3;

            if (input1) input1.setupTextureCoordinates(vertexData, 0, "texCoords1");
            if (input2) input2.setupTextureCoordinates(vertexData, 0, "texCoords2");
            if (input3) input3.setupTextureCoordinates(vertexData, 0, "texCoords3");

            return super.process(painter, helper, input0, input1, input2, input3);
        }

        /** @private */
        override protected function createEffect():FilterEffect
        {
            return new CompositeEffect();
        }

        /** Returns the position (in points) at which a certain layer will be drawn. */
        public function getOffsetAt(layerID:int, out:Point=null):Point
        {
            if (out == null) out = new Point();

            out.x = compositeEffect.getLayerAt(layerID).x;
            out.y = compositeEffect.getLayerAt(layerID).y;

            return out;
        }

        /** Indicates the position (in points) at which a certain layer will be drawn. */
        public function setOffsetAt(layerID:int, x:Number, y:Number):void
        {
            compositeEffect.getLayerAt(layerID).x = x;
            compositeEffect.getLayerAt(layerID).y = y;
        }

        /** Returns the RGB color with which a layer is tinted when it is being drawn.
         *  @default 0xffffff */
        public function getColorAt(layerID:int):uint
        {
            return compositeEffect.getLayerAt(layerID).color;
        }

        /** Adjusts the RGB color with which a layer is tinted when it is being drawn.
         *  If <code>replace</code> is enabled, the pixels are not tinted, but instead
         *  the RGB channels will replace the texture's color entirely.
         */
        public function setColorAt(layerID:int, color:uint, replace:Boolean=false):void
        {
            compositeEffect.getLayerAt(layerID).color = color;
            compositeEffect.getLayerAt(layerID).replaceColor = replace;
        }

        /** Indicates the alpha value with which the layer is drawn.
         *  @default 1.0 */
        public function getAlphaAt(layerID:int):Number
        {
            return compositeEffect.getLayerAt(layerID).alpha;
        }

        /** Adjusts the alpha value with which the layer is drawn. */
        public function setAlphaAt(layerID:int, alpha:Number):void
        {
            compositeEffect.getLayerAt(layerID).alpha = alpha;
        }

        private function get compositeEffect():CompositeEffect
        {
            return this.effect as CompositeEffect;
        }
    }
}