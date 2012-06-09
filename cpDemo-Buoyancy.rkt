#lang racket

(require htdp/image)
(require 2htdp/universe)
(require "chipmunk-ffi.rkt")

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
                                           (cpv -320.0 240.0)
                                           (cpv 320.0 240.0)
                                           0.0))
                  (cpSpaceAddShape *space (cpSegmentShapeNew
                                           *staticBody
                                           (cpv -320.0 240.0)
                                           (cpv 320.0 240.0)
                                           0.0))
                  (cpSpaceAddShape *space (cpSegmentShapeNew
                                           *staticBody
                                           (cpv -320.0 240.0)
                                           (cpv 320.0 240.0)
                                           0.0))
                  ; Sensor for the water.
                  (cpSpaceAddShape *space (cpSegmentShapeNew
                                           *staticBody
                                           (cpv -320.0 240.0)
                                           (cpv 320.0 240.0)
                                           0.0))))
(cpShapeSetElasticity (list-ref *shapes* 0) 1.0)
(cpShapeSetFriction (list-ref *shapes* 0) 1.0)
(cpShapeSetLayers (list-ref *shapes* 0) NOT_GRABABLE_MASK)