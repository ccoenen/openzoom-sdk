////////////////////////////////////////////////////////////////////////////////
//
//  OpenZoom
//
//  Copyright (c) 2007–2008, Daniel Gasienica <daniel@gasienica.ch>
//
//  OpenZoom is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  OpenZoom is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with OpenZoom. If not, see <http://www.gnu.org/licenses/>.
//
////////////////////////////////////////////////////////////////////////////////
package org.openzoom.flash.viewport
{

import flash.events.Event;
import flash.events.EventDispatcher;
import flash.geom.Point;
import flash.geom.Rectangle;

import org.openzoom.flash.events.ViewportEvent;
import org.openzoom.flash.scene.IReadonlyMultiScaleScene;
import org.openzoom.flash.viewport.transformers.NullTransformer;
import org.openzoom.flash.viewport.transformers.TweenerTransformer;

//------------------------------------------------------------------------------
//
//  Events
//
//------------------------------------------------------------------------------

/**
 * @inheritDoc
 */
[Event(name="resize", type="org.openzoom.events.ViewportEvent")]

/**
 * @inheritDoc
 */
[Event(name="transformStart", type="org.openzoom.events.ViewportEvent")]

/**
 * @inheritDoc
 */
[Event(name="transform", type="org.openzoom.events.ViewportEvent")]

/**
 * @inheritDoc
 */
[Event(name="transformEnd", type="org.openzoom.events.ViewportEvent")]


/**
 * IViewport implementation that is based on a normalized [0, 1] coordinate system.
 */
public class NormalizedViewport extends EventDispatcher
                                implements INormalizedViewport,
                                           IReadonlyViewport,
                                           INormalizedViewportContainer,
                                           ITransformerViewport
{
    //--------------------------------------------------------------------------
    //
    //  Class constants
    //
    //--------------------------------------------------------------------------

//    private static const NULL_CONSTRAINT  : IViewportConstraint  = new NullViewportConstraint()
    private static const NULL_TRANSFORMER : IViewportTransformer = new NullTransformer()

    //--------------------------------------------------------------------------
    //
    //  Constructor
    //
    //--------------------------------------------------------------------------

    /**
     * Constructor.
     */
    public function NormalizedViewport( viewportWidth : Number,
                                        viewportHeight : Number,
                                        scene : IReadonlyMultiScaleScene )
    {
        _scene = scene
        _scene.addEventListener( Event.RESIZE,
                                 scene_resizeHandler,
                                 false, 0, true )
        
        _transform = ViewportTransform.fromValues( 0, 0, 1, 1, 1,
                                                   viewportWidth,
                                                   viewportHeight,
                                                   scene.sceneWidth,
                                                   scene.sceneHeight )
        
        // FIXME
        NULL_TRANSFORMER.viewport = this
        
        // FIXME
//      transformer = NULL_TRANSFORMER
        transformer = new TweenerTransformer()
    }

    //--------------------------------------------------------------------------
    //
    //  Properties
    //
    //--------------------------------------------------------------------------

    //----------------------------------
    //  zoom
    //----------------------------------

    [Bindable(event="transformUpdate")]
    
    /**
     * @inheritDoc
     */
    public function get zoom() : Number
    {
        return _transform.zoom
    }

    public function set zoom( value : Number ) : void
    {
        zoomTo( value )
    }

    //----------------------------------
    //  scale
    //----------------------------------

    [Bindable(event="transformUpdate")]
    
    /**
     * @inheritDoc
     */ 
    public function get scale() : Number
    {
        return _transform.scale
    }
     
    public function set scale( value : Number ) : void
    {
    	var t : IViewportTransform = getTargetTransform()
        t.scale = value
    	applyTransform( t )
    }
 
//    //----------------------------------
//    //  constraint
//    //----------------------------------
//    
//    private var _constraint : IViewportConstraint = NULL_CONSTRAINT
//
//    public function get constraint() : IViewportConstraint
//    {
//        return _constraint
//    }
//    
//    public function set constraint( value : IViewportConstraint ) : void
//    {
//        if( value )
//           _constraint = value
//        else
//           _constraint = NULL_CONSTRAINT
//    }

    //----------------------------------
    //  transformer
    //----------------------------------

    /**
     * @private
     * Storage for the transformer property.
     */
    private var _transformer : IViewportTransformer

    /**
     * @inheritDoc
     */ 
    public function get transformer() : IViewportTransformer
    {
        return _transformer
    }

    /**
     * @inheritDoc
     */
    public function set transformer( value : IViewportTransformer ) : void
    {
    	if( _transformer )
    	{
    	   _transformer.stop()
           _transformer.viewport = null    		
    	}
    	
        if( value )
           _transformer = value
        else
           _transformer = NULL_TRANSFORMER
           
        _transformer.viewport = this
    }

    //----------------------------------
    //  transform
    //----------------------------------

    /**
     * @private
     * Storage for the transform property.
     */
    private var _transform : IViewportTransform

    [Bindable(event="transformUpdate")]
    
    /**
     * @inheritDoc
     */
    public function get transform() : IViewportTransform
    {   	
    	return _transform.clone()
    }

    public function set transform( value : IViewportTransform ) : void
    {
        var oldTransform : IViewportTransform = _transform.clone()
        _transform = value.clone()
        dispatchUpdateTransformEvent( oldTransform )
    }
    
    //----------------------------------
    //  scene
    //----------------------------------
    
    /**
     * @private
     * Storage for the scene property.
     */
    private var _scene : IReadonlyMultiScaleScene

    /**
     * @inheritDoc
     */ 
    public function get scene() : IReadonlyMultiScaleScene
    {
        return _scene
    }
    
    //----------------------------------
    //  viewportWidth
    //----------------------------------
    
    [Bindable(event="resize")]
    
    /**
     * @inheritDoc
     */
    public function get viewportWidth() : Number
    {
        return _transform.viewportWidth
    }
    
    //----------------------------------
    //  viewportHeight
    //----------------------------------
    
    [Bindable(event="resize")]
    
    /**
     * @inheritDoc
     */
    public function get viewportHeight() : Number
    {
        return _transform.viewportHeight
    }

    //--------------------------------------------------------------------------
    //
    //  Methods: Zooming
    //
    //--------------------------------------------------------------------------

    /**
     * @inheritDoc
     */
    public function zoomTo( zoom : Number,
                            transformX : Number = 0.5,
                            transformY : Number = 0.5,
                            immediately : Boolean = false ) : void
    {
    	var t : IViewportTransform = getTargetTransform()
        t.zoomTo( zoom, transformX, transformY )
        applyTransform( t, immediately )
    }
    
    /**
     * @inheritDoc
     */
    public function zoomBy( factor : Number,
                            transformX : Number = 0.5,
                            transformY : Number = 0.5,
                            immediately : Boolean = false ) : void
    {
        var t : IViewportTransform = getTargetTransform()
    	t.zoomBy( factor, transformX, transformY )
        applyTransform( t, immediately )
    }

    //--------------------------------------------------------------------------
    //
    //  Methods: Panning
    //
    //--------------------------------------------------------------------------

    /**
     * @inheritDoc
     */
    public function panTo( x : Number, y : Number,
                           immediately : Boolean = false ) : void
    {
        var t : IViewportTransform = getTargetTransform()
        t.panTo( x, y )
        applyTransform( t, immediately )
    }
    
    /**
     * @inheritDoc
     */
    public function panBy( deltaX : Number, deltaY : Number,
                           immediately : Boolean = false ) : void
    {
        var t : IViewportTransform = getTargetTransform()
        t.panBy( deltaX, deltaY )
        applyTransform( t, immediately )
    }

    /**
     * @inheritDoc
     */
    public function panCenterTo( x : Number, y : Number,
                                 immediately : Boolean = false ) : void
    {
        var t : IViewportTransform = getTargetTransform()
        t.panCenterTo( x, y )
        applyTransform( t, immediately )
    }

    /**
     * @inheritDoc
     */
    public function showRect( rect : Rectangle, scale : Number = 1.0, 
                              immediately : Boolean = false ) : void
    {
        var t : IViewportTransform = getTargetTransform()
        t.showRect( rect, scale )
        applyTransform( t, immediately )
    }
    
    /**
     * @inheritDoc
     */
    public function showAll( immediately : Boolean = false ) : void
    {
        var t : IViewportTransform = getTargetTransform()
        t.showAll()
        applyTransform( t, immediately )
    }

    //--------------------------------------------------------------------------
    //
    //  Methods: Coordinate transformations
    //
    //--------------------------------------------------------------------------

    /**
     * @inheritDoc
     */ 
    public function localToScene( point : Point ) : Point
    {
        var p : Point = new Point()
        p.x = ( x * scene.sceneWidth ) 
              + ( point.x / viewportWidth )  * ( width  * scene.sceneWidth )
        p.y = ( y * scene.sceneHeight )
              + ( point.y / viewportHeight ) * ( height * scene.sceneHeight )
        return p
    }
    
    /**
     * @inheritDoc
     */
    public function sceneToLocal( point : Point ) : Point
    {
        var p : Point = new Point()
        p.x = ( point.x - ( x  * scene.sceneWidth ))
              / ( width  * scene.sceneWidth ) * viewportWidth
        p.y = ( point.y - ( y  * scene.sceneHeight ))
              / ( height * scene.sceneHeight ) * viewportHeight
        return p
    }

    //--------------------------------------------------------------------------
    //
    //  Methods: IViewport / flash.geom.Rectangle
    //
    //--------------------------------------------------------------------------
    
    /**
     * @inheritDoc
     */
    public function contains( x : Number, y : Number ) : Boolean
    {
    	// FIXME: Delegate to Rectangle object.
        return ( x >= left ) && ( x <= right ) && ( y >= top ) && ( y <= bottom )
    }
    
    /**
     * @inheritDoc
     */
    public function intersects( toIntersect : Rectangle ) : Boolean
    {
    	// FIXME: Circumvent normalization / denormalization
    	var sceneViewport : Rectangle = new Rectangle( x * scene.sceneWidth,
                                                       y * scene.sceneHeight, 
                                                       width * scene.sceneWidth,
                                                       height * scene.sceneHeight )
        return sceneViewport.intersects( denormalizeRectangle( toIntersect ))
    }
    
    /**
     * @inheritDoc
     */
    public function intersection( toIntersect : Rectangle ) : Rectangle
    {
        // FIXME: Circumvent normalization / denormalization
        var sceneViewport : Rectangle = new Rectangle( x * scene.sceneWidth,
                                                       y * scene.sceneHeight, 
                                                       width * scene.sceneWidth,
                                                       height * scene.sceneHeight )
        return sceneViewport.intersection( denormalizeRectangle( toIntersect ))
    }

    //--------------------------------------------------------------------------
    //
    //  Properties: IViewport
    //
    //--------------------------------------------------------------------------
    
    //----------------------------------
    //  x
    //----------------------------------
    
    [Bindable(event="transformUpdate")]
    
    /**
     * @inheritDoc
     */
    public function get x() : Number
    {
        return _transform.x
    }
    
    public function set x( value : Number ) : void
    {
    	var t : IViewportTransform = getTargetTransform()
    	t.x = value
    	applyTransform( t )
    }
    
    //----------------------------------
    //  y
    //----------------------------------
    
    [Bindable(event="transformUpdate")]
    
    /**
     * @inheritDoc
     */
    public function get y() : Number
    {
       return _transform.y
    }
    
    public function set y( value : Number ) : void
    {
        var t : IViewportTransform = getTargetTransform()
        t.y = value
        applyTransform( t )
    }
    
    //----------------------------------
    //  width
    //----------------------------------
    
    [Bindable(event="transformUpdate")]
    
    /**
     * @inheritDoc
     */
    public function get width() : Number
    {
        return _transform.width
    }
    
    public function set width( value : Number ) : void
    {
    	var t : IViewportTransform = getTargetTransform()
    	t.width = value
    	applyTransform( t )
    }
    
    //----------------------------------
    //  height
    //----------------------------------
    
    [Bindable(event="transformUpdate")]
    
    /**
     * @inheritDoc
     */
    public function get height() : Number
    {
        return _transform.height
    }
    
    public function set height( value : Number ) : void
    {
        var t : IViewportTransform = getTargetTransform()
        t.height = value
        applyTransform( t )
    }
    
    //----------------------------------
    //  left
    //----------------------------------
    
    [Bindable(event="transformUpdate")]
    
    /**
     * @inheritDoc
     */
    public function get left() : Number
    {
        return _transform.left
    }
    
    //----------------------------------
    //  right
    //----------------------------------
    
    [Bindable(event="transformUpdate")]
    
    /**
     * @inheritDoc
     */
    public function get right() : Number
    {
        return _transform.right
    }
    
    //----------------------------------
    //  top
    //----------------------------------
    
    [Bindable(event="transformUpdate")]
    
    /**
     * @inheritDoc
     */
    public function get top() : Number
    {
        return _transform.top
    }
    
    //----------------------------------
    //  bottom
    //----------------------------------
    
    [Bindable(event="transformUpdate")]
    
    /**
     * @inheritDoc
     */
    public function get bottom() : Number
    {
        return _transform.bottom
    }
    
    //----------------------------------
    //  topLeft
    //----------------------------------
    
    [Bindable(event="transformUpdate")]
    
    /**
     * @inheritDoc
     */
    public function get topLeft() : Point
    {
        return _transform.topLeft
    }
    
    //----------------------------------
    //  bottomRight
    //----------------------------------
    
    [Bindable(event="transformUpdate")]
    
    /**
     * @inheritDoc
     */
    public function get bottomRight() : Point
    {
        return _transform.bottomRight
    }

    //--------------------------------------------------------------------------
    //
    //  Methods: Transform Events
    //
    //--------------------------------------------------------------------------
    
    /**
     * @inheritDoc
     */
    public function beginTransform() : void
    {
        dispatchEvent( new ViewportEvent( ViewportEvent.TRANSFORM_START ))
    }
    
    /**
     * @private
     * Dispatches a transformUpdate event along with a copy
     * of the transform previously applied to this viewport.
     */
    private function dispatchUpdateTransformEvent( oldTransform : IViewportTransform
                                                       = null ) : void
    {
        dispatchEvent( new ViewportEvent( ViewportEvent.TRANSFORM_UPDATE,
                           false, false, oldTransform ))
    }
    
    /**
     * @inheritDoc
     */
    public function endTransform() : void
    {
        dispatchEvent( new ViewportEvent( ViewportEvent.TRANSFORM_END ))
    }
    
    //--------------------------------------------------------------------------
    //
    //  Methods: Internal
    //
    //--------------------------------------------------------------------------
    
    /**
     * @private
     */ 
    private function getTargetTransform() : IViewportTransform
    {
        var t : IViewportTransform = transformer.target
        return t
    }

    /**
     * @private
     */
    private function applyTransform( transform : IViewportTransform,
                                     immediately : Boolean = false ) : void
    {
        transformer.transform( transform, immediately )
    }
    
    /**
     * @private
     */
    private function reinitializeTransform( viewportWidth : Number,
                                            viewportHeight : Number ) : void
    {
        var old : IViewportTransform = transform
        var t : IViewportTransformContainer =
            ViewportTransform.fromValues( old.x, old.y,
                                           old.width, old.height, old.zoom,
                                           viewportWidth, viewportHeight,
                                           _scene.sceneWidth, _scene.sceneHeight ) 
        applyTransform( t, true )
    }
    
    //--------------------------------------------------------------------------
    //
    //  Methods: IViewportContainer
    //
    //--------------------------------------------------------------------------
    
    /**
     * @inheritDoc
     */
    public function setSize( width : Number, height : Number ) : void
    {
        if( viewportWidth == width && viewportHeight == height )
            return
        
        reinitializeTransform( width, height )
        
        dispatchEvent( new ViewportEvent( ViewportEvent.RESIZE, false, false ))
    }
    
    //--------------------------------------------------------------------------
    //
    //  Methods: Coordinate conversion
    //
    //--------------------------------------------------------------------------
    
    /**
     * @private
     */ 
    private function normalizeX( value : Number ) : Number
    {
        return value / scene.sceneWidth
    }

    /**
     * @private
     */
    private function normalizeY( value : Number ) : Number
    {
        return value / scene.sceneHeight
    }
    
    /**
     * @private
     */
    private function normalizeRectangle( value : Rectangle ) : Rectangle
    {
        return new Rectangle( normalizeX( value.x ),
                              normalizeY( value.y ),
                              normalizeX( value.width ),
                              normalizeY( value.height ))
    }
    
    /**
     * @private
     */
    private function normalizePoint( value : Point ) : Point
    {
        return new Point( normalizeX( value.x ),
                          normalizeY( value.y ))
    }
    
    /**
     * @private
     */ 
    private function denormalizeX( value : Number ) : Number
    {
        return value * scene.sceneWidth
    }

    /**
     * @private
     */
    private function denormalizeY( value : Number ) : Number
    {
        return value * scene.sceneHeight
    }
    
    /**
     * @private
     */
    private function denormalizePoint( value : Point ) : Point
    {
        return new Point( denormalizeX( value.x ),
                          denormalizeY( value.y ))
    }
    
    /**
     * @private
     */
    private function denormalizeRectangle( value : Rectangle ) : Rectangle
    {
        return new Rectangle( denormalizeX( value.x ),
                              denormalizeY( value.y ),
                              denormalizeX( value.width ),
                              denormalizeY( value.height ))
    }
    
    //--------------------------------------------------------------------------
    //
    //  Event handlers
    //
    //--------------------------------------------------------------------------
    
    /**
     * @private
     */
    private function scene_resizeHandler( event : Event ) : void
    {
    	reinitializeTransform( viewportWidth, viewportHeight )
    }
    
    //--------------------------------------------------------------------------
    //
    //  Methods: Debug
    //
    //--------------------------------------------------------------------------
    
    /**
     * @inheritDoc
     */
    override public function toString() : String
    {
        return "[NormalizedViewport]" + "\n"
               + "x=" + x + "\n" 
               + "y=" + y  + "\n"
               + "z=" + zoom + "\n"
               + "w=" + width + "\n"
               + "h=" + height + "\n"
               + "sW=" + scene.sceneWidth + "\n"
               + "sH=" + scene.sceneHeight
    }
}

}