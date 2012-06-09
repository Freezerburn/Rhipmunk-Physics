#lang scheme

; TODOTODO: Make ffi bindings lazy to reduce startup time.

(require ffi/unsafe
         ffi/unsafe/define
         rnrs/arithmetic/bitwise-6)

(define chipmunk (ffi-lib "mychipmunk"))
(define-ffi-definer define-chipmunk chipmunk)

(define-syntax (defchipmunk stx)
  (syntax-case stx ()
    [(defchipmunk name #:ptr type)
     #`(begin (provide name)
              (define name
                (let ()
                  (define-chipmunk ptr _pointer
                    #:c-id #,(datum->syntax
                              #'name
                              (string->symbol
                               (format "_~a" (syntax->datum #'name)))))
                  (function-ptr ptr type))))]
    [(defchipmunk name type)
     #'(begin (provide name)
              (define-chipmunk name type))]))

; ***********************************************
; * Start of Chipmunk type definitions
; ***********************************************

(define _cpFloat _double)
(define cpFloat? real?)
(define _cpDataPointer _pointer)
(define _size_t _ulong)
(define _cpHashValue _size_t)
(define _cpBool _bool)
(define _cpTimeStamp _uint)
(define _cpCollisionType _uint)
(define _cpGroup _uint)
(define _cpLayers _uint)
(define GRABABLE_MASK (arithmetic-shift 1 31))
(define NOT_GRABABLE_MASK (bitwise-not GRABABLE_MASK))

; ***********************************************
; * End of Chipmunk type definitions
; ***********************************************

; -----------------------------------------------

; ***********************************************
; * Start of Chipmunk struct definitions
; ***********************************************

; Definition of Chipmunk Vector
(define-cstruct _cpVect
                ([x _cpFloat]
                 [y _cpFloat]))
; Definition of Chipmunk rigid body functions for _cpBody
(define _cpBodyVelocityFunc
  (_fun _pointer _cpVect _cpFloat _cpFloat -> _void))
(define _cpBodyPositionFunc
  (_fun _pointer _cpFloat -> _void))
; Definition of Chipmunk Body
(define-cstruct _cpBody
                (; Integration Functions
                 [velocity_func _cpBodyVelocityFunc]
                 [position_func _cpBodyPositionFunc]
                 ; Mass Properties
                 [m _cpFloat]
                 [m_inv _cpFloat]
                 [i _cpFloat]
                 [i_inv _cpFloat]
                 ; Positional Properties
                 [p _cpVect]
                 [v _cpVect]
                 [f _cpVect]
                 [a _cpFloat]
                 [w _cpFloat]
                 [t _cpFloat]
                 [rot _cpVect]
                 ; User Definable Fields
                 [data _cpDataPointer]
                 ; Internally Used Fields
                 [v_bias _cpVect]
                 [w_bias _cpFloat]))
; Definition of Chipmunk Space
(define-cstruct _cpSpace
                ([iterations _int]
                 [gravity _cpVect]
                 [damping _cpFloat]
                 [idleSpeedThreshold _cpFloat]
                 [sleepTimeThreshold _cpFloat]
                 [collisionSlop _cpFloat]
                 [collisionBias _cpFloat]
                 [collisionPersistence _cpFloat]
                 [enableContactGraph _cpBool]
                 [data _cpDataPointer]
                 [staticBody _cpBody-pointer]))
; Definition of Chipmunk Arbiter
; which is 'A colliding pair of shapes'.
(define-cstruct _cpArbiter
                (
                ; Calculated value to use for the elasticity coefficient.
                ; Override in a pre-solve collision handler for custom behavior.
                [e _cpFloat]
                ; Calculated value to use for the friction coefficient.
                ; Override in a pre-solve collision handler for custom behavior.
                [u _cpFloat]
                ; Calculated value to use for applying surface velocities.
                ; Override in a pre-solve collision handler for custom behavior.
                [surface_vr _cpVect]))
; Definition of 'Collision begin event function callback type'.
(define _cpCollisionBeginFunc
  (_fun _cpArbiter-pointer
        _cpSpace-pointer
        _pointer
        -> _cpBool))
; Definitoin of 'Collision pre-solve event function callback type'.
(define _cpCollisionPreSolveFunc
  (_fun _cpArbiter-pointer
        _cpSpace-pointer
        _pointer
        -> _cpBool))
; Definition of 'Collision post-solve event function callback type'.
(define _cpCollisionPostSolveFunc
  (_fun _cpArbiter-pointer
        _cpSpace-pointer
        _pointer
        -> _void))
; Definition of 'Collision separate event function callback type'.
(define _cpCollisionSeparateFunc
  (_fun _cpArbiter-pointer
        _cpSpace-pointer
        _pointer
        -> _void))
; Definition of cpBB, 'Chipmunk's axis-aligned 2D bounding box
; type. (left, bottom, right. top)'.
(define-cstruct _cpBB
  ([l _cpFloat]
   [b _cpFloat]
   [r _cpFloat]
   [t _cpFloat]))
; Definition of cpShape, 'Opaque collision shape struct'.
(define-cstruct _cpShape
  ([body _cpBody-pointer]
   [bb _cpBB]
   [sensor _cpBool]
   [e _cpFloat]
   [u _cpFloat]
   [surface_v _cpVect]
   [data _cpDataPointer]
   [collision_type _cpCollisionType]
   [group _cpGroup]
   [layers _cpLayers]))

; ***********************************************
; * End of Chipmunk struct definitions
; ***********************************************

; -----------------------------------------------

; ***********************************************
; * Start of Chipmunk Space definitions
; ***********************************************

; ***
; cpSpace creation functions
; ***
; Definition for Space Allocation
(defchipmunk cpSpaceAlloc (_fun -> _cpSpace-pointer))
; Definition for Space Initialization
(defchipmunk cpSpaceInit (_fun _cpSpace-pointer -> _cpSpace-pointer))
; Definition for New Space Construction
;  Equivalent to: cpSpaceAlloc + spSpaceInit
(defchipmunk cpSpaceNew (_fun -> _cpSpace-pointer))
; ***
; cpSpace destruction functions
; ***
; Definition for cpSpace Destruction
(defchipmunk cpSpaceDestroy (_fun _cpSpace-pointer -> _void))
; Definition for Freeing cpSpace
(defchipmunk cpSpaceFree (_fun _cpSpace-pointer -> _void))
; Definition for adding a cpShape to a cpSpace
(defchipmunk cpSpaceAddShape
  (_fun _cpSpace-pointer _cpShape-pointer -> _cpShape-pointer))
; Definition for adding a cpBody to a cpSpace
(defchipmunk cpSpaceAddBody
  (_fun _cpSpace-pointer _cpBody-pointer -> _cpBody-pointer))

; ********
; Getters and Setters Start
; ********
; Iterations Getter
(defchipmunk cpSpaceGetIterations #:ptr (_fun _cpSpace-pointer -> _int))
; Iterations Setter
(defchipmunk cpSpaceSetIterations #:ptr (_fun _cpSpace-pointer _int -> _void))
; Gravity Getter
(defchipmunk cpSpaceGetGravity #:ptr (_fun _cpSpace-pointer -> _cpVect))
; Gravity Setter
(defchipmunk cpSpaceSetGravity #:ptr (_fun _cpSpace-pointer _cpVect -> _void))
; Damping Getter
(defchipmunk cpSpaceGetDamping #:ptr (_fun _cpSpace-pointer -> _cpFloat))
; Damping Setter
(defchipmunk cpSpaceSetDamping #:ptr (_fun _cpSpace-pointer _cpFloat -> _void))
; Idle Speed Threshold Getter
(defchipmunk cpSpaceGetIdleSpeedThreshold
  #:ptr (_fun _cpSpace-pointer -> _cpFloat))
; Idle Speed Threshold Setter
(defchipmunk cpSpaceSetIdleSpeedThreshold
  #:ptr (_fun _cpSpace-pointer _cpFloat -> _void))
; Sleep Time Threshold Getter
(defchipmunk cpSpaceGetSleepTimeThreshold
  #:ptr (_fun _cpSpace-pointer -> _cpFloat))
; Sleep Time Threshold Setter
(defchipmunk cpSpaceSetSleepTimeThreshold
  #:ptr (_fun _cpSpace-pointer _cpFloat -> _void))
; Collision Slop Getter
(defchipmunk cpSpaceGetCollisionSlop
  #:ptr (_fun _cpSpace-pointer -> _cpFloat))
; Collision Slop Setter
(defchipmunk cpSpaceSetCollisionSlop
  #:ptr (_fun _cpSpace-pointer _cpFloat -> _void))
; Collision Bias Getter
(defchipmunk cpSpaceGetCollisionBias
  #:ptr (_fun _cpSpace-pointer -> _cpFloat))
; Collision Bias Setter
(defchipmunk cpSpaceSetCollisionBias
  #:ptr (_fun _cpSpace-pointer _cpFloat -> _void))
; Collision Persistence Getter
(defchipmunk cpSpaceGetCollisionPersistence
  #:ptr (_fun _cpSpace-pointer -> _cpTimeStamp))
; Collisoin Persistence Setter
(defchipmunk cpSpaceSetCollisionPersistence
  #:ptr (_fun _cpSpace-pointer _cpTimeStamp -> _void))
; Enable Contact Graph Getter
(defchipmunk cpSpaceGetEnableContactGraph
  #:ptr (_fun _cpSpace-pointer -> _cpBool))
; Enable Contact Graph Setter
(defchipmunk cpSpaceSetEnableContactGraph
  #:ptr (_fun _cpSpace-pointer _cpBool -> _void))
; User Data Getter
(defchipmunk cpSpaceGetUserData
  #:ptr (_fun _cpSpace-pointer -> _cpDataPointer))
; User Data Setter
(defchipmunk cpSpaceSetUserData
  #:ptr (_fun _cpSpace-pointer _cpDataPointer -> _void))
; Static Body Getter
(defchipmunk cpSpaceGetStaticBody
  #:ptr (_fun _cpSpace-pointer -> _cpBody-pointer))
; Current Time Step Getter
(defchipmunk cpSpaceGetCurrentTimeStep
  #:ptr (_fun _cpSpace-pointer -> _cpFloat))
; ********
; Getters and Setters End
; ********
; Collision Handlers Start
; ********
; Default Collision Handler
(defchipmunk cpSpaceSetDefaultCollisionHandler
  (_fun _cpSpace-pointer
        _cpCollisionBeginFunc
        _cpCollisionPreSolveFunc
        _cpCollisionPostSolveFunc
        _cpCollisionSeparateFunc
        _pointer
        -> _void))
; ********
; Collision Handlers End
; ********
(defchipmunk cpSpaceStep (_fun _cpSpace-pointer _cpFloat -> _void))

; ***********************************************
; * End of Chipmunk Space definitions
; ***********************************************

; -----------------------------------------------

; ***********************************************
; * Start of Chipmunk Bounding Box operation definitions.
; ***********************************************
(defchipmunk cpBBNew
  #:ptr (_fun _cpFloat _cpFloat _cpFloat _cpFloat -> _cpBB))
; ********
; Getters and Setters Start
; ********
; ********
; Getters and Setters End
; ********
; ***********************************************
; * End of Chipmunk Bounding Box operation definitions.
; ***********************************************

; -----------------------------------------------

; ***********************************************
; * Start of Chipmunk Body operation definitions.
; ***********************************************

(defchipmunk cpBodyNew
  (_fun _cpFloat _cpFloat -> _cpBody-pointer))
(defchipmunk cpBodyFree
  (_fun _cpBody-pointer -> _void))
(defchipmunk cpCircleShapeNew
  (_fun _cpBody-pointer _cpFloat _cpVect -> _cpShape-pointer))
; Wake up a sleeping or idle body.
(defchipmunk cpBodyActivate
  (_fun _cpBody-pointer -> _void))
; ********
; Getters and Setters Start
; ********
(defchipmunk cpBodyGetPos #:ptr (_fun _cpBody-pointer -> _cpVect))
(defchipmunk cpBodySetPos (_fun _cpBody-pointer _cpVect -> _void))
(defchipmunk cpBodyGetVel #:ptr (_fun _cpBody-pointer -> _cpVect))
; ********
; Getters and Setters End
; ********

; ***********************************************
; * End of Chipmunk Body operation definitions.
; ***********************************************

; -----------------------------------------------

; ***********************************************
; * Start of Chipmunk Shape operation definitions.
; ***********************************************

; Shape Destruction Definition.
(defchipmunk cpShapeDestroy
  (_fun _cpShape-pointer -> _void))
; Destroy and Free a Shape Definition
(defchipmunk cpShapeFree
  (_fun _cpShape-pointer -> _void))
; Update, cache, and return the bounding box of a shape based on the body it's attached to.
(defchipmunk cpShapeCacheBB
  (_fun _cpShape-pointer -> _cpBB))
; Updated, cache, and return the bounding box of a shape with an explicit transformation.
(defchipmunk cpShapeUpdate
  (_fun _cpShape-pointer _cpVect _cpVect -> _cpBB))
; Test if a point lies within a shape.
(defchipmunk cpShapePointQuery
  (_fun _cpShape-pointer _cpVect -> _cpBool))
; New shape segment creation definition.
(defchipmunk cpSegmentShapeNew
  (_fun _cpBody-pointer _cpVect _cpVect _cpFloat -> _cpShape-pointer))
; ********
; Getters and Setters Start
; ********
; Get the cpBody from a cpShape.
(defchipmunk cpShapeGetBody
  #:ptr (_fun _cpShape-pointer -> _cpBody-pointer))
; Set the cpBody in a cpShape.
(defchipmunk cpShapeSetBody
  #:ptr (_fun _cpShape-pointer _cpBody-pointer -> _void))
; Set the cpBB in a cpShape.
(defchipmunk cpShapeGetBB
  #:ptr (_fun _cpShape-pointer -> _cpBB))
; Get the sensor in a cpShape.
(defchipmunk cpShapeGetSensor
  #:ptr (_fun _cpShape-pointer -> _cpBool))
; Set the sensor in the cpShape.
(defchipmunk cpShapeSetSensor
  #:ptr (_fun _cpShape-pointer _cpBool -> _void))
; Get the elasticity from a cpShape.
(defchipmunk cpShapeGetElasticity
  #:ptr (_fun _cpShape-pointer -> _cpFloat))
; Set the elasticity in a cpShape.
(defchipmunk cpShapeSetElasticity
  #:ptr (_fun _cpShape-pointer _cpFloat -> _void))
; Get the friction from a cpShape.
(defchipmunk cpShapeGetFriction
  #:ptr (_fun _cpShape-pointer -> _cpFloat))
; Set the friction in a cpShape
(defchipmunk cpShapeSetFriction
  #:ptr (_fun _cpShape-pointer _cpFloat -> _void))
; Get the Surface Velocity from a cpShape.
(defchipmunk cpShapeGetSurfaceVelocity
  #:ptr (_fun _cpShape-pointer -> _cpVect))
; Set the Surface Velocity in a cpShape.
(defchipmunk cpShapeSetSurfaceVelocity
  #:ptr (_fun _cpShape-pointer _cpVect -> _cpVect))
; Get the UserData from a cpShape.
(defchipmunk cpShapeGetUserData
  #:ptr (_fun _cpShape-pointer -> _cpDataPointer))
; Set the UserData in a cpShape.
(defchipmunk cpShapeSetUserData
  #:ptr (_fun _cpShape-pointer _cpDataPointer -> _void))
; Get the Collision Type from a cpShape.
(defchipmunk cpShapeGetCollisionType
  #:ptr (_fun _cpShape-pointer -> _cpCollisionType))
; Set the Collision Type in a cpShape.
(defchipmunk cpShapeSetCollisionType
  #:ptr (_fun _cpShape-pointer _cpCollisionType -> _void))
; Get the Group from a cpShape.
(defchipmunk cpShapeGetGroup
  #:ptr (_fun _cpShape-pointer -> _cpGroup))
; Set the Group in a cpShape.
(defchipmunk cpShapeSetGroup
  #:ptr (_fun _cpShape-pointer _cpGroup -> _void))
; Get the Layer from a cpShape.
(defchipmunk cpShapeGetLayers
  #:ptr (_fun _cpShape-pointer -> _cpLayers))
; Set the Layer in a cpShape.
(defchipmunk cpShapeSetLayers
  #:ptr (_fun _cpShape-pointer _cpLayers -> _void))
; ********
; Getters and Setters End
; ********

; ***********************************************
; * End of Chipmunk Shape operation definitions.
; ***********************************************

; -----------------------------------------------

; ***********************************************
; * Start of vector operation definitions.
; ***********************************************
;(define (cpv x y)
  ;(make-cpVect x y))
(defchipmunk cpv #:ptr (_fun _cpFloat _cpFloat -> _cpVect))
(define (cpvzero) (cpv 0.0 0.0))
;; FIXME: I didn't change the following three things, since they look
;; suspicious (the first and the last start with a "_" but they're not
;; pointers?)
(define cpveql
  (get-ffi-obj "_cpveql" chipmunk (_fun _cpVect _cpVect -> _bool)))
(define cpvadd
  (function-ptr (get-ffi-obj "_cpvadd" chipmunk _pointer)
                (_fun _cpVect _cpVect -> _cpVect)))
(define cpvlengthsq
  (get-ffi-obj "_cpvlengthsq" chipmunk (_fun _cpVect -> _cpFloat)))

; ***********************************************
; * End of vector operation definitions.
; ***********************************************

; -----------------------------------------------

; ***********************************************
; * Start of various operation definitions.
; ***********************************************

(defchipmunk cpMomentForCircle
  (_fun _cpFloat _cpFloat _cpFloat _cpVect -> _cpFloat))

; ***********************************************
; * Start of various operation definitions.
; ***********************************************

(provide (all-defined-out))
