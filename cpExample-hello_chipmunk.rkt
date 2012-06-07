#lang racket

(require htdp/image)
(require 2htdp/universe)
(require "chipmunk-ffi.rkt")

; A 2D vector initialized to represent the pull of gravity.
(define *gravity
  (cpv 0.0 100.0))

; Create an empty space
(define *space
  (cpSpaceNew))
(cpSpaceSetGravity *space *gravity)

; Add a static line segment shape for the ground.
; We'll make it slightly tiled so the ball will roll off.
; We attach it to space->staticBody to tell Chipmunk it shouldn't be movable.
(define *ground-start* (cpv 40.0 85.0))
(define *ground-end* (cpv 80.0 95.0))
(define *ground
  (cpSegmentShapeNew (cpSpaceGetStaticBody *space) *ground-start* *ground-end* 0.0))
(cpShapeSetFriction *ground 1.0)
(cpSpaceAddShape *space *ground)

; Now let's make a ball that falls onto the line and rolls off.
; First we need to make a cpBody to hold the physical properties of the object.
; These include the mass, position, velocity, angle, etc. of the object.
; Then we attack collision shapes to the cpBody to give it a size and shape.
(define radius 5.0)
(define mass 1.0)

; The moment of inertia is like mass for rotation.
; Use the cpMomentFor*() functions to help you approximate it.
(define moment
  (cpMomentForCircle mass 0.0 radius (cpvzero)))

; The cpSpaceAdd*() functions return the thing that you are adding.
; It's convenient to create and add an object in one line.
(define *ballBody
  (cpSpaceAddBody *space (cpBodyNew mass moment)))
(cpBodySetPos *ballBody (cpv 60.0 15.0))

; Now we create the collision shape for the ball.
; You can create multiple collision shapes that point to the same body.
; They will all be attached to the body and move around to follow it.
(define *ballShape
  (cpSpaceAddShape *space (cpCircleShapeNew *ballBody radius (cpvzero))))
(cpShapeSetFriction *ballShape 0.7)

; Now that it's all set up, we simulate all the objects in the space by
; stepping forward through time in small increments called steps.
; It is *highly* recommended to use a fixed size time step.
(define *tick-rate* (/ 1 120.0))
(define *canvas* 
  (empty-scene 100.0 100.0))
(big-bang 0
          [on-tick
           (lambda (state)
             (cpSpaceStep *space *tick-rate*)
             (+ state 1))
           *tick-rate*]
          [on-draw
           (lambda (state)
             (let
                 ([pos (cpBodyGetPos *ballBody)]
                  [vel (cpBodyGetVel *ballBody)])
               (add-line
                (add-line
                 (place-image
                  (circle radius 'solid 'blue)
                  (cpVect-x pos)
                  (cpVect-y pos)
                  *canvas*)
                 (cpVect-x pos)
                 (cpVect-y pos)
                 (+ (cpVect-x pos) (cpVect-x vel))
                 (+ (cpVect-y pos) (cpVect-y vel))
                 'black)
                (cpVect-x *ground-start*)
                (cpVect-y *ground-start*)
                (cpVect-x *ground-end*)
                (cpVect-y *ground-end*)
                'green
                )))]
          )

; Clean up our objects and exit!
(cpShapeFree *ballShape)
(cpBodyFree *ballBody)
(cpShapeFree *ground)
(cpSpaceFree *space)
                
                 