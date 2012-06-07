#lang scheme

; TODOTODO: Make ffi bindings lazy to reduce startup time.

(require ffi/unsafe
         ffi/unsafe/define)

(define chipmunk (ffi-lib "mychipmunk"))
(define-ffi-definer define-chipmunk chipmunk)

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
(define cpSpaceAlloc
  (get-ffi-obj "cpSpaceAlloc" chipmunk
               (_fun -> _cpSpace-pointer)))
; Definition for Space Initialization
(define cpSpaceInit
  (get-ffi-obj "cpSpaceInit" chipmunk
               (_fun _cpSpace-pointer -> _cpSpace-pointer)))
; Definition for New Space Construction
;  Equivalent to: cpSpaceAlloc + spSpaceInit
(define cpSpaceNew
  (get-ffi-obj "cpSpaceNew" chipmunk
               (_fun -> _cpSpace-pointer)))
; ***
; cpSpace destruction functions
; ***
; Definition for cpSpace Destruction
(define cpSpaceDestroy
  (get-ffi-obj "cpSpaceDestroy" chipmunk
               (_fun _cpSpace-pointer -> _void)))
; Definition for Freeing cpSpace
(define cpSpaceFree
  (get-ffi-obj "cpSpaceFree" chipmunk
               (_fun _cpSpace-pointer -> _void)))
; Definition for adding a cpShape to a cpSpace
(define cpSpaceAddShape
  (get-ffi-obj "cpSpaceAddShape" chipmunk
               (_fun _cpSpace-pointer
                     _cpShape-pointer
                     -> _cpShape-pointer)))
; Definition for adding a cpBody to a cpSpace
(define cpSpaceAddBody
  (get-ffi-obj "cpSpaceAddBody" chipmunk
               (_fun _cpSpace-pointer
                     _cpBody-pointer
                     -> _cpBody-pointer)))

; ********
; Getters and Setters Start
; ********
; Iterations Getter
(define cpSpaceGetIterations
  (function-ptr (get-ffi-obj "_cpSpaceGetIterations" chipmunk _pointer)
                (_fun _cpSpace-pointer -> _int)))
; Iterations Setter
(define cpSpaceSetIterations
  (function-ptr (get-ffi-obj "_cpSpaceSetIterations" chipmunk _pointer)
                (_fun _cpSpace-pointer _int -> _void)))
; Gravity Getter
(define cpSpaceGetGravity
  (function-ptr (get-ffi-obj "_cpSpaceGetGravity" chipmunk _pointer)
                (_fun _cpSpace-pointer -> _cpVect)))
; Gravity Setter
(define cpSpaceSetGravity
  (function-ptr (get-ffi-obj "_cpSpaceSetGravity" chipmunk _pointer)
                (_fun _cpSpace-pointer _cpVect -> _void)))
; Damping Getter
(define cpSpaceGetDamping
  (function-ptr (get-ffi-obj "_cpSpaceGetDamping" chipmunk _pointer)
                (_fun _cpSpace-pointer -> _cpFloat)))
; Damping Setter
(define cpSpaceSetDamping
  (function-ptr (get-ffi-obj "_cpSpaceSetDamping" chipmunk _pointer)
               (_fun _cpSpace-pointer _cpFloat -> _void)))
; Idle Speed Threshold Getter
(define cpSpaceGetIdleSpeedThreshold
  (function-ptr (get-ffi-obj "_cpSpaceGetIdleSpeedThreshold" chipmunk _pointer)
                (_fun _cpSpace-pointer -> _cpFloat)))
; Idle Speed Threshold Setter
(define cpSpaceSetIdleSpeedThreshold
  (function-ptr (get-ffi-obj "_cpSpaceSetIdleSpeedThreshold" chipmunk _pointer)
                (_fun _cpSpace-pointer _cpFloat -> _void)))
; Sleep Time Threshold Getter
(define cpSpaceGetSleepTimeThreshold
  (function-ptr (get-ffi-obj "_cpSpaceGetSleepTimeThreshold" chipmunk _pointer)
                (_fun _cpSpace-pointer -> _cpFloat)))
; Sleep Time Threshold Setter
(define cpSpaceSetSleepTimeThreshold
  (function-ptr (get-ffi-obj "_cpSpaceSetSleepTimeThreshold" chipmunk _pointer)
                (_fun _cpSpace-pointer _cpFloat -> _void)))
; Collision Slop Getter
(define cpSpaceGetCollisionSlop
  (function-ptr (get-ffi-obj "_cpSpaceGetCollisionSlop" chipmunk _pointer)
                (_fun _cpSpace-pointer -> _cpFloat)))
; Collision Slop Setter
(define cpSpaceSetCollisionSlop
  (function-ptr (get-ffi-obj "_cpSpaceSetCollisionSlop" chipmunk _pointer)
                (_fun _cpSpace-pointer _cpFloat -> _void)))
; Collision Bias Getter
(define cpSpaceGetCollisionBias
  (function-ptr (get-ffi-obj "_cpSpaceGetCollisionBias" chipmunk _pointer)
                (_fun _cpSpace-pointer -> _cpFloat)))
; Collision Bias Setter
(define cpSpaceSetCollisionBias
  (function-ptr (get-ffi-obj "_cpSpaceSetCollisionBias" chipmunk _pointer)
                (_fun _cpSpace-pointer _cpFloat -> _void)))
; Collision Persistence Getter
(define cpSpaceGetCollisionPersistence
  (function-ptr (get-ffi-obj "_cpSpaceGetCollisionPersistence" chipmunk _pointer)
                (_fun _cpSpace-pointer -> _cpTimeStamp)))
; Collisoin Persistence Setter
(define cpSpaceSetCollisionPersistence
  (function-ptr (get-ffi-obj "_cpSpaceSetCollisionPersistence" chipmunk _pointer)
                (_fun _cpSpace-pointer _cpTimeStamp -> _void)))
; Enable Contact Graph Getter
(define cpSpaceGetEnableContactGraph
  (function-ptr (get-ffi-obj "_cpSpaceGetEnableContactGraph" chipmunk _pointer)
                (_fun _cpSpace-pointer -> _cpBool)))
; Enable Contact Graph Setter
(define cpSpaceSetEnableContactGraph
  (function-ptr (get-ffi-obj "_cpSpaceSetEnableContactGraph" chipmunk _pointer)
                (_fun _cpSpace-pointer _cpBool -> _void)))
; User Data Getter
(define cpSpaceGetUserData
  (function-ptr (get-ffi-obj "_cpSpaceGetUserData" chipmunk _pointer)
                (_fun _cpSpace-pointer -> _cpDataPointer)))
; User Data Setter
(define cpSpaceSetUserData
  (function-ptr (get-ffi-obj "_cpSpaceSetUserData" chipmunk _pointer)
                (_fun _cpSpace-pointer _cpDataPointer -> _void)))
; Static Body Getter
(define cpSpaceGetStaticBody
  (function-ptr (get-ffi-obj "_cpSpaceGetStaticBody" chipmunk _pointer)
                (_fun _cpSpace-pointer -> _cpBody-pointer)))
; Current Time Step Getter
(define cpSpaceGetCurrentTimeStep
  (function-ptr (get-ffi-obj "_cpSpaceGetCurrentTimeStep" chipmunk _pointer)
                (_fun _cpSpace-pointer -> _cpFloat)))
; ********
; Getters and Setters End
; ********
; Collision Handlers Start
; ********
; Default Collision Handler
(define cpSpaceSetDefaultCollisionHandler
  (get-ffi-obj "cpSpaceSetDefaultCollisionHandler" chipmunk
               (_fun _cpSpace-pointer
                     _cpCollisionBeginFunc
                     _cpCollisionPreSolveFunc
                     _cpCollisionPostSolveFunc
                     _cpCollisionSeparateFunc
                     _pointer
                     -> _void)))
; ********
; Collision Handlers End
; ********
(define cpSpaceStep
  (get-ffi-obj "cpSpaceStep" chipmunk
               (_fun _cpSpace-pointer _cpFloat -> _void)))

; ***********************************************
; * End of Chipmunk Space definitions
; ***********************************************

; -----------------------------------------------

; ***********************************************
; * Start of Chipmunk Shape operation definitions.
; ***********************************************

(define cpSegmentShapeNew
  (get-ffi-obj "cpSegmentShapeNew" chipmunk
               (_fun _cpBody-pointer
                     _cpVect
                     _cpVect
                     _cpFloat
                     -> _cpShape-pointer)))
(define cpShapeFree
  (get-ffi-obj "cpShapeFree" chipmunk
               (_fun _cpShape-pointer -> _void)))
; ********
; Getters and Setters Start
; ********
(define cpShapeSetFriction
  (function-ptr (get-ffi-obj "_cpShapeSetFriction" chipmunk _pointer)
                (_fun _cpShape-pointer _cpFloat -> _void)))
; ********
; Getters and Setters End
; ********

; ***********************************************
; * End of Chipmunk Shape operation definitions.
; ***********************************************

; -----------------------------------------------

; ***********************************************
; * Start of Chipmunk Shape operation definitions.
; ***********************************************

(define cpBodyNew
  (get-ffi-obj "cpBodyNew" chipmunk
               (_fun _cpFloat _cpFloat -> _cpBody-pointer)))
(define cpBodyFree
  (get-ffi-obj "cpBodyFree" chipmunk
               (_fun _cpBody-pointer -> _void)))
(define cpCircleShapeNew
  (get-ffi-obj "cpCircleShapeNew" chipmunk
               (_fun _cpBody-pointer
                     _cpFloat
                     _cpVect
                     -> _cpShape-pointer)))
; ********
; Getters and Setters Start
; ********
(define cpBodyGetPos
  (function-ptr (get-ffi-obj "_cpBodyGetPos" chipmunk _pointer)
                (_fun _cpBody-pointer -> _cpVect)))
(define cpBodySetPos
  (get-ffi-obj "cpBodySetPos" chipmunk
               (_fun _cpBody-pointer _cpVect -> _void)))
(define cpBodyGetVel
  (function-ptr (get-ffi-obj "_cpBodyGetVel" chipmunk _pointer)
                (_fun _cpBody-pointer -> _cpVect)))
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
(define cpv
  (function-ptr (get-ffi-obj "_cpv" chipmunk _pointer)
                (_fun _cpFloat _cpFloat -> _cpVect)))
(define (cpvzero)
  (cpv 0.0 0.0))
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

(define cpMomentForCircle
  (get-ffi-obj "cpMomentForCircle" chipmunk
               (_fun _cpFloat _cpFloat _cpFloat _cpVect -> _cpFloat)))

; ***********************************************
; * Start of various operation definitions.
; ***********************************************

(provide (all-defined-out))
