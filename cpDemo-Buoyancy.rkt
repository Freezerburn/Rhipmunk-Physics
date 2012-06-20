#lang racket

(require htdp/image)
(require 2htdp/universe)
(require "chipmunk-ffi.rkt")
(require ffi/unsafe)

; Pre-solve function for water buoyancy in the space.
(define (water-presolve arb space ptr)
  (let
      ([water (_ptr o _cpShape-pointer)]
       [poly (_ptr o _cpShape-pointer)])
    (cpArbiterGetShapes arb water poly)
    (let*
        ([body (cpShapeGetBody poly)]
         [level (cpBB-t (cpShapeGetBB water))]
         [count (cpPolyShapeGetNumVerts poly)]
         [clipped (null)])
      (for/fold ([i 0]
                 [j (sub1 count)])
        ([is (sequence->list (in-range 1 count))])
        (let*
            ([a (cpBodyLocal2World body (cpPolyShapeGetVert poly j))]
             [b (cpBodyLocal2World body (cpPolyShapeGetVert poly i))]
             [a-level (- (cpVect-y a) level)]
             (b-level (- (cpVect-y b) level)))
          (if (< (cpVect-y a) level)
              (set! clipped (cons a clipped))
              0)
          (if (< (* a-level b-level) 0.0)
              (set! clipped (cons (cpvlerp a b
                                           (/ (cpfabs a-level) (+ (cpfabs a-level) (cpfabs b-level))))))
              0)
          (values is is)
          )
        )
      (let*
          ([clippedCount (length clipped)]
           [clippedArea (cpAreaForPoly clippedCount clipped)]
           [displacedMass (* clippedArea FLUID_DENSITY)]
           [centroid (cpCentroidForPoly clippedCount clipped)]
           [r (cpvsub centroid (cpBodyGetPos body))]
           [dt (cpSpaceGetCurrentTimeStep *space)]
           [g (cpSpaceGetGravity *space)])
        (apply_impulse body
                       (cpvmult g
                                (- (* displacedMass dt))
                                r))
        (let*
            ([v_centroid (cpvadd (cpBody-v body) (cpvmult (cpvperp r) (cpBody-w body)))]
             [k (k_scalar_body body r (cpvnormalize_safe v_centroid))]
             [damping (* clippedArea FLUID_DRAG FLUID_DENSITY)]
             [v_coef (cpfexp (- (* damping dt k)))])
          (apply_impulse body
                         (cpvmult (cpvsub (cpvmult v_centroid
                                                   v_coef)
                                          v_centroid)
                                  (/ 1.0 k))
                         r)
          (set-cpBody-w! body
                         (* (cpBody-w body)
                            (cpfexp (* (- (cpMomentForPoly (* FLUID_DRAG
                                                              FLUID_DENSITY
                                                              clippedArea)
                                                           clippedCount
                                                           clipped
                                                           (cpvneg (cpBody-p body))))
                                       dt
                                       (cpBody-i_inv body)))))
          cpTrue
          )
        )
      )
    )
  )

(define *space (cpSpaceNew))
(cpSpaceSetIterations *space 30)
(cpSpaceSetGravity *space (cpv 0.0 -100.0))
(cpSpaceSetDamping *space 0.5)
(cpSpaceSetSleepTimeThreshold *space 0.5)
(cpSpaceSetCollisionSlop *space 0.5)

(define *staticBody (cpSpaceGetStaticBody *space))
(define *bb* (cpBBNew -300.0 -200.0 100.0 0.0))
(define *radius* 5.0)
(define *shapes* (list
                  ; Segments around the edge of the screen.
                  (cpSpaceAddShape *space (cpSegmentShapeNew
                                           *staticBody
                                           (cpv -320.0 -240.0)
                                           (cpv -320.0 240.0)
                                           0.0))
                  (cpSpaceAddShape *space (cpSegmentShapeNew
                                           *staticBody
                                           (cpv 320.0 -240.0)
                                           (cpv 320.0 240.0)
                                           0.0))
                  (cpSpaceAddShape *space (cpSegmentShapeNew
                                           *staticBody
                                           (cpv -320.0 -240.0)
                                           (cpv 320.0 -240.0)
                                           0.0))
                  (cpSpaceAddShape *space (cpSegmentShapeNew
                                           *staticBody
                                           (cpv -320.0 240.0)
                                           (cpv 320.0 240.0)
                                           0.0))
                  ; The edges of the bucket.
                  (cpSpaceAddShape *space (cpSegmentShapeNew
                                           *staticBody
                                           (cpv (cpBB-l *bb*) (cpBB-b *bb*))
                                           (cpv (cpBB-l *bb*) (cpBB-t *bb*))
                                           *radius*))
                  (cpSpaceAddShape *space (cpSegmentShapeNew
                                           *staticBody
                                           (cpv (cpBB-r *bb*) (cpBB-b *bb*))
                                           (cpv (cpBB-r *bb*) (cpBB-t *bb*))
                                           *radius*))
                  (cpSpaceAddShape *space (cpSegmentShapeNew
                                           *staticBody
                                           (cpv (cpBB-l *bb*) (cpBB-b *bb*))
                                           (cpv (cpBB-r *bb*) (cpBB-b *bb*))
                                           *radius*))
                  ; Sensor for the water.
                  (cpSpaceAddShape *space (cpBoxShapeNew2 *staticBody *bb*))))
; Setting up segments around edge of screen.
(cpShapeSetElasticity (list-ref *shapes* 0) 1.0)
(cpShapeSetFriction (list-ref *shapes* 0) 1.0)
(cpShapeSetLayers (list-ref *shapes* 0) NOT_GRABABLE_MASK)

(cpShapeSetElasticity (list-ref *shapes* 1) 1.0)
(cpShapeSetFriction (list-ref *shapes* 1) 1.0)
(cpShapeSetLayers (list-ref *shapes* 1) NOT_GRABABLE_MASK)

(cpShapeSetElasticity (list-ref *shapes* 2) 1.0)
(cpShapeSetFriction (list-ref *shapes* 2) 1.0)
(cpShapeSetLayers (list-ref *shapes* 2) NOT_GRABABLE_MASK)

(cpShapeSetElasticity (list-ref *shapes* 3) 1.0)
(cpShapeSetFriction (list-ref *shapes* 3) 1.0)
(cpShapeSetLayers (list-ref *shapes* 3) NOT_GRABABLE_MASK)

; Setting up edges of the bucket.
(cpShapeSetElasticity (list-ref *shapes* 4) 1.0)
(cpShapeSetFriction (list-ref *shapes* 4) 1.0)
(cpShapeSetLayers (list-ref *shapes* 4) NOT_GRABABLE_MASK)

(cpShapeSetElasticity (list-ref *shapes* 5) 1.0)
(cpShapeSetFriction (list-ref *shapes* 5) 1.0)
(cpShapeSetLayers (list-ref *shapes* 5) NOT_GRABABLE_MASK)

(cpShapeSetElasticity (list-ref *shapes* 6) 1.0)
(cpShapeSetFriction (list-ref *shapes* 6) 1.0)
(cpShapeSetLayers (list-ref *shapes* 6) NOT_GRABABLE_MASK)

; Setting up the sensor for the water.
(cpShapeSetSensor (list-ref *shapes* 7) cpTrue)
(cpShapeSetCollisionType (list-ref *shapes* 7) 1)

; Fluid constants
(define FLUID_DENSITY 0.00014)
(define FLUID_DRAG 2.0)

; First shape that floats in the water.
(define *width1* 200.0)
(define *height1* 50.0)
(define *mass1* (* 0.3 FLUID_DENSITY *width1* *height1*))
(define *moment1* (cpMomentForBox *mass1* *width1* *height1*))

(define *body1 (cpSpaceAddBody *space (cpBodyNew *mass1* *moment1*)))
(cpBodySetPos *body1 (cpv -50.0 -100.0))
(cpBodySetVel *body1 (cpv 0.0 -100.0))
(cpBodySetAngVel *body1 1.0)
(define *body-shape1 (cpSpaceAddShape *space (cpBoxShapeNew *body1 *width1* *height1*)))
(cpShapeSetFriction *body-shape1 0.8)

; Second shape that floats in the water.
(define *width2* 40.0)
(define *height2* (* *width2* 2))
(define *mass2* (* 0.3 FLUID_DENSITY *width2* *height2*))
(define *moment2* (cpMomentForBox *mass2* *width2* *height2*))

(define *body2 (cpSpaceAddBody *space (cpBodyNew *mass2* *moment1*)))
(cpBodySetPos *body2 (cpv -200.0 -50.0))
(cpBodySetVel *body2 (cpv 0.0 -100.0))
(cpBodySetAngVel *body2 1.0)
(define *body-shape2 (cpSpaceAddShape *space (cpBoxShapeNew *body1 *width1* *height1*)))
(cpShapeSetFriction *body-shape2 0.8)

(cpSpaceAddCollisionHandler *space 1 0 
                            #f
                            water-presolve
                            #f
                            #f
                            #f)

(big-bang 0
          [on-tick (lambda (ticks)
                     (let ([dt (/ 1.0 60.0 3.0)])
                       (cpSpaceStep *space dt)
                       (cpSpaceStep *space dt)
                       (cpSpaceStep *space dt)
                       )
                     )
                   (/ 1 60.0)]
          [on-draw (lambda (ticks)
                     (place-image (rectangle 40
                                             80
                                             "solid"
                                             "blue")
                                  (cpVect-x (cpBody-p *body2))
                                  (cpVect-y (cpBody-p *body2))
                                  (empty-scene 640 480))
                     )]
          )