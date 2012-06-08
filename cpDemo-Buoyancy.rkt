#lang racket

(require htdp/image)
(require 2htdp/universe)
(require "chipmunk-ffi.rkt")

(define *space (cpSpaceNew))
(cpSpaceSetIterations *space 30.0)
(cpSpaceSetGravity *space (cpv 0.0 -100.0))
(cpSpaceSetDamping *space 0.5)
(cpSpaceSetSleepTimeThreshold *space 0.5)
(cpSpaceSetCollisionSlop *space 0.5)

(define *staticBody (cpSpaceGetStaticBody *space))