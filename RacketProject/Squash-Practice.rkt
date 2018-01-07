;; The first three lines of this file were inserted by DrRacket. They record metadata
;; about the language level of this file in a form that our tools can easily process.
#reader(lib "htdp-intermediate-lambda-reader.ss" "lang")((modname Squash-Practice) (read-case-sensitive #t) (teachpacks ()) (htdp-settings #(#t constructor repeating-decimal #f #t none #f () #f)))
;; SquashPractice

;; A squash player practicing without an opponent

;; The simulation displays the positions and motions of a squash ball and the
;; player's racket moving within a rectangular court

;; The simulation is first in ready-to-serve state, with ball and racket at
;; initial positions.
;; When space bar is pressed, it goes into rally state, with ball and racket
;; moving according to thier respective velocity.
;; If space bar is pressed in rally state, simulation pauses for 3 seconds.

;; When in rally state, the velocity of racket and ball changes accordingly on
;; different key events or on collision with the court walls.

;; When the simulation is in rally state, the racket becomes selectable and
;; draggable and a blue circle appears to show the position of mouse.

;; When the simulation is in rally state, pressing 'b' key creates a new ball
;; with position components (330,384) and velocity components (3,-9).

;; If a ball collides with the back wall, it disappears from the simulation.
;; If its disappearance leaves no more balls within the simulation, the rally
;; state ends as though the space bar had been pressed.



;; start with (simulation n)
;; where n is the speed of the simulation in seconds per tick

;; for example
;; (simulation 1/10)
;; (simulation 1)

(require rackunit)
(require "extras.rkt")

(require 2htdp/universe)
(require 2htdp/image)



(provide
 simulation
 initial-world
 world-ready-to-serve?
 world-after-tick
 world-after-key-event
 world-after-mouse-event
 racket-after-mouse-event
 racket-selected?
 world-balls
 world-racket
 ball-x
 ball-y
 racket-x
 racket-y
 ball-vx
 ball-vy
 racket-vx
 racket-vy)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; MAIN FUNCTION:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; simulation : PosReal -> World
;; GIVEN: the speed of the simulation in seconds per tick
;; EFFECT: runs the simulation
;; RETURNS: the final state of the world

(define (simulation s)
  (big-bang(initial-world s)
           (on-tick world-after-tick s)
           (on-key world-after-key-event)
           (on-mouse world-after-mouse-event)
           (on-draw world-to-scene)))

;; initial-world : PosReal -> World
;; GIVEN: the speed of simulation, in seconds per tick
;; RETURNS: the ready-to-serve state of the world

;; EXAMPLES:
;; (initial-world 1/10) => (make-world BALL-IN-READY-TO-SERVE
;;                                     RACKET-IN-READY-TO-SERVE-STATE
;;                                     "ready-to-serve" 0.5 6)


;; DESIGN STRATEGY: Use constructor template for World on w
(define (initial-world s)
  (make-world
   (list (make-ball BALL-X-COORD BALL-Y-COORD BALL-INITIAL-VEL-X
                    BALL-INITIAL-VEL-Y))
   (make-racket RACKET-X-COORD RACKET-Y-COORD RACKET-INITIAL-VEL-X
                RACKET-INITIAL-VEL-Y false 0 0)
   READY-TO-SERVE-STATE s (/ PAUSE-TIME s)))

;; TESTS:
(begin-for-test
  (check-equal?
   (initial-world 1/10) (make-world BALLS-IN-READY-TO-SERVE-STATE
                                    RACKET-IN-READY-TO-SERVE-STATE
                                    "ready-to-serve" 1/10 30)))



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CONSTANTS:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; dimensions of court:
(define COURT-WIDTH 425)
(define COURT-HEIGHT 649)

;; court with white background color:
(define COURT-WHITE (frame (rectangle COURT-WIDTH COURT-HEIGHT
                                      "solid" "white")))

;; court with yellow background color:
(define COURT-YELLOW (frame (rectangle COURT-WIDTH COURT-HEIGHT
                                       "solid" "yellow")))

;; dimensions of ball and racket
(define BALL-RADIUS 3)
(define RACKET-WIDTH 47)
(define RACKET-HEIGHT 7)

;; Ball and Racket:
(define BALL (circle BALL-RADIUS "solid" "black"))
(define RACKET (rectangle RACKET-WIDTH RACKET-HEIGHT "solid" "green"))

;; initial x and y co-ordinates of Ball
(define BALL-X-COORD 330)
(define BALL-Y-COORD 384)

;; initial x and y co-ordinates of Racket
(define RACKET-X-COORD 330)
(define RACKET-Y-COORD 384)

;; initial velocity of Ball
(define BALL-INITIAL-VEL-X 0)
(define BALL-INITIAL-VEL-Y 0)

;; initial velocity of Racket
(define RACKET-INITIAL-VEL-X 0)
(define RACKET-INITIAL-VEL-Y 0)

;; time in number of seconds for which the simulation will remain paused
(define PAUSE-TIME 3)

;; blue circle which indicates the location of the mouse
(define BLUE-CIRCLE (circle 4 "solid" "blue"))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; DATA-DEFINITIONS:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; REPRESENTATION:
;; A World is represented as a struct,
;; (make-world balls racket state speed pause-counter)
;; with the following fields:
;; balls           : BallList   represents a list of balls in the world
;; racket          : Racket     represents a racket in the world
;; state           : State      represents the state of the simulation, it can
;;                              be either in ready-to-serve state, in rally
;;                              state or in paused state
;; speed           : PosReal    represents the speed of the simulation
;; pause-counter   : Integer    represents the time in ticks for which the
;;                              simulation will remain in paused state

;; IMPLEMENTATION:
(define-struct world (balls racket state speed pause-counter))

;; CONSTRUCTOR TEMPLATE:
;; (make-world BallList Racket State PosReal Integer)

;; OBSERVER TEMPALTE:
;; world-fn : World -> ??
#;
(define (world-fn w)
  (...
   (bs-fn (world-balls w))
   (world-racket w)
   (world-state w)
   (world-speed w)
   (world-pause-counter w)))


;; REPRESENTATION:
;; A Ball is represented as a struct (make-ball x y vx vy)
;; with the following fields:
;; x, y : Integer      represents the position of the ball in the scene
;; vx   : Integer      represents the velocity of ball in x direction,
;;                     tells how many pixels the ball moves on each tick in
;;                     the x direction
;; vy   : Integer      represents the velocity of ball in y direction, tells
;;                     how many pixels the ball moves on each tick in the y
;;                     direction

;; IMPLEMENTATION:
(define-struct ball (x y vx vy))

;; CONSTRUCTOR TEMPLATE:
;; (make-ball Integer Integer Integer Integer)

;; OBSERVER TEMPALTE:
;; ball-fn : Ball -> ??
(define (ball-fn b)
  (...
   (ball-x b)
   (ball-y b)
   (ball-vx b)
   (ball-vy b)))


;; A BallList is represented as a list of Balls

;; CONSTRUCTOR TEMPLATE AND IMPLEMENTATION:
;; empty               -- the empty sequence

;; (cons b bs)
;; WHERE:
;;   b is a Ball       -- the first Ball in the sequence
;;   bs is a BallList  -- the rest of the Balls in the sequence

;; OBSERVER TEMPALTE:
;; bs-fn : BallList -> ??
#;
(define (bs-fn lst)
  (cond
    [(empty? lst)...]
    [else (... (first lst)
               (bs-fn (rest lst)))]))



;; REPRESENTATION:
;; A Racket is represented as a struct (make-racket x y vx vy selected? mx my)
;; with the following fields:
;; x, y      : Integer      represents the position of the racket in the scene
;; vx        : Integer      represents the velocity of racket in x direction,
;;                          tells how many pixels the racket moves on each tick
;;                          in the x direction
;; vy        : Integer      represents the velocity of racket in y direction,
;;                          tells how many pixels the racket moves on each tick
;;                          in the y direction
;; selected? : Boolean      true if the racket is selected
;; mx, my    : Integer      if racket is selected, the position of x and y
;;                          coordinates of mouse, otherwise 0.

;; IMPLEMENTATION:
(define-struct racket (x y vx vy selected? mx my))

;; CONSTRUCTOR TEMPLATE:
;; (make-racket Integer Integer Integer Integer Boolean Integer Integer)

;; OBSERVER TEMPALTE:
;; racket-fn : Racket -> ??
#;
(define (racket-fn r)
  (...
   (racket-x r)
   (racket-y r)
   (racket-vx r)
   (racket-vy r)
   (racket-selected? r)
   (racket-mx r)
   (racket-my r)))


;; REPRESENTATION:
;; A State is represented by one the following
;; -- "ready-to-serve"
;; -- "rally"
;; -- "paused"

;; INTERPRETATION: the simulation can be either in ready-to-serve state,
;;                 rally state or in paused state

;; EXAMPLES:
(define READY-TO-SERVE-STATE "ready-to-serve")
(define RALLY-STATE "rally")
(define PAUSED-STATE "paused")

;; OBSERVER TEMPALTE:
;; state-fn : State -> ??
#;
(define (state-fn s)
  (cond
    [(string=? s "ready-to-serve") ...]
    [(string=? s "rally") ...]
    [(string=? s "paused") ...]))


;; A KeyEvent is represented by one the following
;; -- " "
;; -- "left"
;; -- "right"
;; -- "up"
;; -- "down"
;; -- "b"

;; INTERPRETATION: the key event can be one of, pressing a space bar, left key,
;;                 right key, up key, down key or b key.

;; EXAMPLES:
(define SPACE " ")
(define LEFT "left")
(define RIGHT "right")
(define UP "up")
(define DOWN "down")
(define b "b")

;; OBSERVER TEMPALTE:
;; key-event-fn : KeyEvent -> ??
#;
(define (key-event-fn s)
  (cond
    [(string=? s " ") ...]
    [(string=? s "left") ...]
    [(string=? s "right") ...]
    [(string=? s "up") ...]
    [(string=? s "down") ...]
    [(string=? s "b") ...]))


;; A MouseEvent is represented by one the following
;; -- "button-up"
;; -- "button-down"
;; -- "drag"

;; INTERPRETATION: the mouse event can be one of, pressing a button down,
;;                 releasing the button or dragging the mouse

;; EXAMPLES:
(define BUTTON-UP "button-up")
(define BUTTON-DOWN "button-down")
(define DRAG "drag")

;; OBSERVER TEMPALTE:
#;
(define (mouse-event-fn s)
  (cond
    [(string=? s "button-up") ...]
    [(string=? s "button-down") ...]
    [(string=? s "drag") ...]))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; EXAMPLES FOR TESTING:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Examples of ball for testing:
(define BALLS-IN-READY-TO-SERVE-STATE (list (make-ball 330 384 0 0)))
(define BALLS-IN-RALLY-STATE (list (make-ball 234 235 3 5)
                                   (make-ball 95 28 0 0)))
(define BALLS-IN-PAUSED-STATE (list (make-ball 195 280 0 0)
                                    (make-ball 95 28 0 0)
                                    (make-ball 150 180 0 0)))

;; Examples of unselected racket for testing:
(define RACKET-IN-READY-TO-SERVE-STATE (make-racket 330 384 0 0 false 0 0))
(define RACKET-IN-RALLY-STATE (make-racket 126 192 4 7 false 0 0))
(define RACKET-IN-PAUSED-STATE (make-racket 148 292 0 0 false 0 0))

;; Examples of selected racket for testing:
(define SELECTED-RACKET-IN-RALLY-STATE (make-racket 126 192 4 7 true 128 194))
(define SELECTED-RACKET-IN-PAUSED-STATE (make-racket 148 292 0 0 true 150 295))

;; Examples of world for testing
(define WORLD-IN-READY-TO-SERVE-STATE (make-world BALLS-IN-READY-TO-SERVE-STATE
                                                  RACKET-IN-READY-TO-SERVE-STATE
                                                  "ready-to-serve" 0.5 6))

(define WORLD-IN-RALLY-STATE (make-world BALLS-IN-RALLY-STATE
                                         RACKET-IN-RALLY-STATE "rally" 0.5 6))

(define WORLD-IN-PAUSED-STATE (make-world BALLS-IN-PAUSED-STATE
                                          RACKET-IN-PAUSED-STATE
                                          "paused" 0.5 4))

(define WORLD-IN-RACKET-SELECTED (make-world BALLS-IN-RALLY-STATE
                                             SELECTED-RACKET-IN-RALLY-STATE
                                             "rally" 0.5 4))


;; Examples of world image for testing:
(define IMAGE-OF-WORLD-IN-READY-TO-SERVE (place-image
                                          BALL 330 384 (place-image
                                                        RACKET 330 384
                                                        COURT-WHITE)))

(define IMAGE-OF-WORLD-IN-RALLY (place-image
                                 BALL 234 235
                                 (place-image BALL 95 28
                                              (place-image
                                               RACKET 126 192 COURT-WHITE))))

(define IMAGE-OF-WORLD-IN-PAUSED
  (place-image BALL 195 280
               (place-image BALL 95 28
                            (place-image BALL 150 180
                                         (place-image RACKET 148 292
                                                      COURT-YELLOW)))))

(define IMAGE-OF-WORLD-IN-RACKET-SELECTED
  (place-image BLUE-CIRCLE 128 194
               (place-image BALL 234 235
                            (place-image BALL 95 28
                                         (place-image RACKET 126 192
                                                      COURT-WHITE)))))



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; FUNCTION-DEFINITIONS:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; world-to-scene : World -> Scene
;; GIVEN: a world
;; RETURNS: a scene that portrays the given world

;; EXAMPLE:
;; (world-to-scene IMAGE-OF-WORLD-IN-READY-TO-SERVE)
;; should return a ball and a racket, both placed at (330,334)
;; in a court with white background.

;; DESIGN-STRATEGY: Place racket and ball in the court
(define (world-to-scene w)
  (cond
    [(world-paused? w)
     (scene-with-balls (world-balls w) (scene-with-racket (world-racket w)
                                                          COURT-YELLOW))]
    [(racket-selected? (world-racket w))
     (scene-with-blue-circle (world-racket w)
                             (scene-with-balls
                              (world-balls w) (scene-with-racket
                                               (world-racket w) COURT-WHITE)))]
    [else (scene-with-balls (world-balls w) (scene-with-racket
                                             (world-racket w) COURT-WHITE))]))

;; TESTS:
(begin-for-test
  (check-equal?
   (world-to-scene WORLD-IN-READY-TO-SERVE-STATE)
   IMAGE-OF-WORLD-IN-READY-TO-SERVE
   "if world in ready-to-serve state, ball and racket have velocity 0
     and placed at (330,384)")
  
  (check-equal?
   (world-to-scene WORLD-IN-RALLY-STATE) IMAGE-OF-WORLD-IN-RALLY
   "if world in rally state, ball and racket have some velocity")
  
  (check-equal?
   (world-to-scene WORLD-IN-PAUSED-STATE) IMAGE-OF-WORLD-IN-PAUSED
   "if world in paused state, ball and racket do not move")

  (check-equal?
   (world-to-scene WORLD-IN-RACKET-SELECTED) IMAGE-OF-WORLD-IN-RACKET-SELECTED
   "if racket is selected, blue circle appears."))
  

;; scene-with-balls : BallList Scene -> Scene
;; GIVEN: a list of balls and a scene
;; RETURNS: a scene just like the given scene except that it has given
;;          list of balls in it.

;; EXAMPLE:
;; (scene-with-balls BALLS-IN-READY-TO-SERVE-STATE COURT-WHITE)
;; will return a court with white background and a ball placed at (330,384).

;; DESIGN-STRATEGY: Place ball in the given scene
;(define (scene-with-balls bl s)
;  (cond
;    [(empty? bl) s]
;    [else (place-image BALL (ball-x (first bl)) (ball-y (first bl))
;                       (scene-with-balls (rest bl) s))]))

;; DESIGN-STRATEGY: Use HOF foldr on bl
(define (scene-with-balls bl s)
  (foldr
   ;; Scene Scene -> Scene
   ;; RETURNS: returns a scene which has both the given scenes in it
   (lambda (s1 s2) (place-image BALL (ball-x s1) (ball-y s1) s2)) s bl))

;; TESTS:
(begin-for-test
  (check-equal?
   (scene-with-balls BALLS-IN-RALLY-STATE COURT-WHITE)
   (place-image BALL 234 235 (place-image BALL 95 28 COURT-WHITE))
   "two balls placed at (234,235) and (95,28) in court with white background")
  (check-equal?
   (scene-with-balls BALLS-IN-PAUSED-STATE COURT-YELLOW)
   (place-image BALL 195 280
                (place-image BALL 95 28
                             (place-image BALL 150 180 COURT-YELLOW)))
   "three balls placed at (195,280), (95,28), (150,180) in court with
    yellow background"))



;; scene-with-racket : Racket Scene -> Scene
;; GIVEN: a racket and a scene
;; RETURNS: a scene just like the given scene except that it has given
;;          racket in it.

;; EXAMPLE:
;; (scene-with-racket RACKET-IN-READY-TO-SERVE-STATE COURT-WHITE)
;; will return a court with white background and a racket placed at (330,384).

;; DESIGN-STRATEGY: Place racket in the given scene
(define (scene-with-racket r s)
  (place-image RACKET (racket-x r) (racket-y r) s))

;; TESTS:
(begin-for-test
  (check-equal?
   (scene-with-racket RACKET-IN-RALLY-STATE COURT-WHITE)
   (place-image RACKET 126 192 COURT-WHITE)
   "racket placed at (126,192) in court with white background")
  (check-equal?
   (scene-with-racket RACKET-IN-PAUSED-STATE COURT-YELLOW)
   (place-image RACKET 148 292 COURT-YELLOW)
   "racket placed at (148,292) in court with yellow background"))



;; scene-with-blue-circle : Racket Scene -> Scene
;; GIVEN: a racket and a scene
;; RETURNS: a scene just like the given scene except that it has a blue circle
;;          placed at the position of mouse given by the racket

;; EXAMPLE:
;; (scene-with-blue-circle RACKET-IN-READY-TO-SERVE-STATE COURT-WHITE)
;; will return a court with white background and a blue circle placed at
;; the position of mouse.

;; DESIGN-STRATEGY: Place blue circle in the given scene
(define (scene-with-blue-circle r s)
  (place-image BLUE-CIRCLE (racket-mx r) (racket-my r) s))

;; TESTS:
(begin-for-test
  (check-equal?
   (scene-with-blue-circle SELECTED-RACKET-IN-RALLY-STATE COURT-WHITE)
   (place-image BLUE-CIRCLE 128 194 COURT-WHITE)
   "blue circle placed at (128,194) in court with white background"))



;; world-ready-to-serve? : World -> Boolean
;; GIVEN: a world
;; RETURNS: true if and only if the world is in its ready-to-serve state

;; EXAMPLES:
;; (world-ready-to-serve? WORLD-IN-READY-TO-SERVE-STATE) => true
;; (world-ready-to-serve? WORLD-IN-RALLY-STATE) => false

;; DESIGN-STRATEGY: Use observer template for World
(define (world-ready-to-serve? w)
  (string=? (world-state w) READY-TO-SERVE-STATE))

;; TESTS:
(begin-for-test
  (check-equal?
   (world-ready-to-serve? WORLD-IN-READY-TO-SERVE-STATE) true
   "world is in ready-to-serve state, so returns true")
  (check-equal?
   (world-ready-to-serve? WORLD-IN-RALLY-STATE) false
   "world is in rally state, so returns false"))



;; world-paused? : World -> Boolean
;; GIVEN: a world
;; RETURNS: true if and only if the world is in its paused state

;; EXAMPLES:
;; (world-paused? WORLD-IN-READY-TO-SERVE-STATE) => false
;; (world-paused? WORLD-IN-PAUSED-STATE) => true

;; DESIGN-STRATEGY: Use observer template for World
(define (world-paused? w)
  (string=? (world-state w) PAUSED-STATE))

;; TESTS:
(begin-for-test
  (check-equal?
   (world-paused? WORLD-IN-PAUSED-STATE) true
   "world is in paused state, so returns true")
  (check-equal?
   (world-paused? WORLD-IN-RALLY-STATE) false
   "world is in rally state, so returns false"))



;; world-rally? : World -> Boolean
;; GIVEN: a world
;; RETURNS: true if and only if the world is in its rally state

;; EXAMPLES:
;; (world-rally? WORLD-IN-READY-TO-SERVE-STATE) => false
;; (world-rally? WORLD-IN-RALLY-STATE) => true

;; DESIGN-STRATEGY: Use observer template for World
(define (world-rally? w)
  (string=? (world-state w) RALLY-STATE))

;; TESTS:
(begin-for-test
  (check-equal?
   (world-rally? WORLD-IN-PAUSED-STATE) false
   "world is in paused state, so returns false")
  (check-equal?
   (world-rally? WORLD-IN-RALLY-STATE) true
   "world is in rally state, so returns true"))



;; world-after-tick : World -> World
;; GIVEN: any world that is possible for the simulation
;; RETURNS: the world that should follow the given world after the tick

;; EXAMPLES:
;; (world-after-tick (make-world BALLS-IN-PAUSED-STATE RACKET-IN-PAUSED-STATE
;;                                  "paused" 0.5 4)) =>
;; (make-world BALLS-IN-PAUSED-STATE RACKET-IN-PAUSED-STATE "paused" 0.5 3)

;; (world-after-tick (make-world (list (make-ball 39 645 -5 8) empty)
;;                                  (make-racket 228 344 4 6 false 0 0)
;;                                  "rally" 0.5 6)) =>
;; (make-world empty (make-racket 228 344 0 0 false 0 0) "paused" 0.5 6)


;; DESIGN-STRATEGY: Cases on state of the world and different conditions
(define (world-after-tick w)
  (cond
    [(world-paused? w) (world-in-pause-state w)]
    
    [(or (racket-collide-with-top-wall? (world-racket w))
         (and (= (length (world-balls w)) 1)
              (ball-collide-with-back-wall?
               (first (world-balls w)) (world-racket w))))
     (world-after-rally w)]
    
    [else (make-world (balls-after-tick (world-balls w) (world-racket w))
                      (racket-after-tick (world-balls w) (world-racket w))
                      (world-state w) (world-speed w)
                      (world-pause-counter w))]))

;; TESTS:
(begin-for-test
  (check-equal?
   (world-after-tick (make-world BALLS-IN-PAUSED-STATE RACKET-IN-PAUSED-STATE
                                 "paused" 0.5 4))
   (make-world BALLS-IN-PAUSED-STATE RACKET-IN-PAUSED-STATE "paused" 0.5 3)
   "world is in paused state, so counter decreses by 1")
  
  (check-equal?
   (world-after-tick (make-world BALLS-IN-PAUSED-STATE RACKET-IN-PAUSED-STATE
                                 "paused" 0.5 0))
   (make-world BALLS-IN-READY-TO-SERVE-STATE RACKET-IN-READY-TO-SERVE-STATE
               "ready-to-serve" 0.5 6)
   "if counter is 0 in paused state, next state will be ready-to-serve state")
  
  (check-equal?
   (world-after-tick (make-world (list (make-ball 245 345 -4 -3))
                                 (make-racket 345 234 2 -4 false 0 0)
                                 "rally" 0.5 6))
   (make-world (list (make-ball 241 342 -4 -3))
               (make-racket 347 230 2 -4 false 0 0) "rally" 0.5 6)
   "if world in rally state, x and y coordinates of ball and racket change
    according to thier respective velocities")

  (check-equal?
   (world-after-tick (make-world (list (make-ball 245 345 -4 -3))
                                 (make-racket 345 2 2 -4 false 0 0)
                                 "rally" 0.5 6))
   (make-world (list (make-ball 245 345 0 0))
               (make-racket 345 0 0 0 false 0 0) "paused" 0.5 6)
   "if racket collide with top wall, world goes in pause state"))



;; world-in-pause-state : World -> World
;; GIVEN: a world in paused state
;; RETURNS: the world that should follow the given world after the tick

;; EXAMPLES:
;; (world-in-pause-state (make-world BALLS-IN-PAUSED-STATE
;;                                   RACKET-IN-PAUSED-STATE "paused" 0.5 4)) =>
;; (make-world BALLS-IN-PAUSED-STATE RACKET-IN-PAUSED-STATE "paused" 0.5 3)

;; (world-in-pause-state (make-world BALLS-IN-PAUSED-STATE
;;                                   RACKET-IN-PAUSED-STATE "paused" 0.5 0)) =>
;; WORLD-IN-READY-TO-SERVE-STATE


;; DESIGN-STRATEGY: Use constructor template for World
(define (world-in-pause-state w)
  (if (> (world-pause-counter w) 0)
      (make-world (world-balls w) (world-racket w) (world-state w)
                  (world-speed w) (- (world-pause-counter w) 1))
      (initial-world (world-speed w))))

;; TESTS:
(begin-for-test
  (check-equal?
   (world-in-pause-state (make-world BALLS-IN-PAUSED-STATE
                                     RACKET-IN-PAUSED-STATE "paused" 0.5 4))
   (make-world BALLS-IN-PAUSED-STATE RACKET-IN-PAUSED-STATE "paused" 0.5 3)
   "world in paused state and couter greater than 0, so counter decreses by 1")

  (check-equal?
   (world-in-pause-state (make-world BALLS-IN-PAUSED-STATE
                                     RACKET-IN-PAUSED-STATE "paused" 0.5 0))
   WORLD-IN-READY-TO-SERVE-STATE)
  "if counter is 0 in paused state, next state will be ready-to-serve state")



;; balls-after-tick : BallList Racket -> BallList
;; GIVEN: a list of balls and a racket
;; RETURNS: the list of balls that should follow the given list after the tick

;; EXAMPLES:
;; (balls-after-tick (list (make-ball 2 4 -6 8) (make-ball 420 4 10 8))
;;                      (make-racket 228 344 4 6 false 0 0)) =>
;; (list (make-ball 4 12 6 8) (make-ball 420 12 -10 8))

;; (balls-after-tick (list (make-ball 2 4 6 -6) (make-ball 128 645 -6 8))
;;                      (make-racket 228 344 4 6 false 0 0)) =>
;; (list (make-ball 8 2 6 6))


;; DESIGN-STRATEGY: Use observer template for BallList
;(define (balls-after-tick bl r)
;  (cond
;    [(empty? bl) bl]
;    [(would-ball-racket-collide? (first bl) r)
;     (cons (make-ball (+ (ball-x (first bl)) (ball-vx (first bl)))
;                      (+ (ball-y (first bl)) (ball-vy (first bl)))
;                      (ball-vx (first bl))
;                      (- (racket-vy r) (ball-vy (first bl))))
;           (balls-after-tick (rest bl) r))]
;
;    [(and (ball-collide-with-left-wall? (first bl) r)
;          (ball-collide-with-top-wall? (first bl) r))
;     (cons (make-ball (- 0 (+ (ball-x (first bl)) (ball-vx (first bl))))
;                      (- 0 (+ (ball-y (first bl)) (ball-vy (first bl))))
;                      (- 0 (ball-vx (first bl))) (- 0 (ball-vy (first bl))))
;           (balls-after-tick (rest bl) r))]
;
;    [(and (ball-collide-with-right-wall? (first bl) r)
;          (ball-collide-with-top-wall? (first bl) r))
;     (cons (make-ball (- 425 (- (+ (ball-x (first bl))
;                                   (ball-vx (first bl))) 425))
;                      (- 0 (+ (ball-y (first bl)) (ball-vy (first bl))))
;                      (- 0 (ball-vx (first bl))) (- 0 (ball-vy (first bl))))
;           (balls-after-tick (rest bl) r))]
;    
;    [(ball-collide-with-left-wall? (first bl) r)
;     (cons (make-ball (- 0 (+ (ball-x (first bl)) (ball-vx (first bl))))
;                      (+ (ball-y (first bl)) (ball-vy (first bl)))
;                      (- 0 (ball-vx (first bl))) (ball-vy (first bl)))
;           (balls-after-tick (rest bl) r))]
;
;    [(ball-collide-with-right-wall? (first bl) r)
;     (cons (make-ball (- 425 (- (+ (ball-x (first bl))
;                                   (ball-vx (first bl))) 425))
;                      (+ (ball-y (first bl)) (ball-vy (first bl)))
;                      (- 0 (ball-vx (first bl))) (ball-vy (first bl)))
;           (balls-after-tick (rest bl) r))]
;    
;    [(ball-collide-with-top-wall? (first bl) r)
;     (cons (make-ball (+ (ball-x (first bl)) (ball-vx (first bl)))
;                      (- 0 (+ (ball-y (first bl)) (ball-vy (first bl))))
;                      (ball-vx (first bl)) (- 0 (ball-vy (first bl))))
;           (balls-after-tick (rest bl) r))]
;
;    [(ball-collide-with-back-wall? (first bl) r) (remove (first bl) bl)]
;
;    [else (cons (make-ball (+ (ball-x (first bl)) (ball-vx (first bl)))
;                           (+ (ball-y (first bl)) (ball-vy (first bl)))
;                           (ball-vx (first bl)) (ball-vy (first bl)))
;                (balls-after-tick (rest bl) r))]))

;; DESIGN STRATEGY: Use HOF map on bl
(define (balls-after-tick bl r)
  (local (;; check-ball-condition : Ball -> Ball
          ;; RETURNS: a ball that should follow the given ball after the tick
          (define (check-ball-condition b) (ball-after-tick b r)))
    (map check-ball-condition (remove-collided-balls bl r))))

;; TESTS:
(begin-for-test
  (check-equal?
   (balls-after-tick (list (make-ball 2 4 -6 8) (make-ball 420 4 10 8))
                     (make-racket 228 344 4 6 false 0 0))
   (list (make-ball 4 12 6 8) (make-ball 420 12 -10 8))
   "If ball collide with left wall, its x-velocity negates and x-coordinates
    change accordingly")
  
  (check-equal?
   (balls-after-tick (list (make-ball 420 4 10 8) (make-ball 128 210 -6 8))
                     (make-racket 228 344 4 6 false 0 0))
   (list (make-ball 420 12 -10 8) (make-ball 122 218 -6 8))
   "If ball collide with right wall, its x-velocity negates and x-coordinates
    change accordingly")
  
  (check-equal?
   (balls-after-tick (list (make-ball 2 4 6 -6) (make-ball 128 645 -6 8))
                     (make-racket 228 344 4 6 false 0 0))
   (list (make-ball 8 2 6 6))
   "If ball collide with top wall, its y-velocity negates and y-coordinates
    change accordingly and one which collides with back wall is removed")
  
  (check-equal?
   (balls-after-tick (list (make-ball 128 210 -6 8) (make-ball 120 110 -4 6))
                     (make-racket 228 344 4 -6 false 0 0))
   (list (make-ball 122 218 -6 8) (make-ball 116 116 -4 6))
   "no collision, ball x and y coordinates change according to velocity")
  
  (check-equal?
   (balls-after-tick (list (make-ball 318 165 -3 9))
                     (make-racket 317 172 3 -3 false 0 0))
   (list (make-ball 315 174 -3 -12))
   "racket and ball collide, ball x and y coordinates change according
    to velocity")

  (check-equal?
   (balls-after-tick (list (make-ball 2 4 -4 -6))
                     (make-racket 228 344 4 6 false 0 0))
   (list (make-ball 2 2 4 6))
   "ball collides with left and top wall, its x and y velocity shloud negate")

  (check-equal?
   (balls-after-tick (list (make-ball 420 4 10 -6))
                     (make-racket 228 344 4 6 false 0 0))
   (list (make-ball 420 2 -10 6))
   "ball collides with right and top wall, x and y velocity should negate"))


;; remove-collided-balls : BallList Racket -> BallList
;; GIVEN: a list of balls and a racket
;; RETURNS: a list of balls just like the given list except that it does not
;;          contain the balls which has collided with back wall

;; EXAMPLES:
;; (remove-collided-balls (list (make-ball 39 645 -5 8) (make-ball 39 64 -2 8))
;;                          (make-racket 228 344 4 6 false 0 0)) =>
;; (list (make-ball 39 64 -2 8))

;; DESIGN STRATEGY: Use HOF filter on bl
(define (remove-collided-balls bl r)
  (local (;; check-ball-back-wall-collision: Ball -> Boolean
          ;; RETURNS: true if and only if the given ball has not collided with
          ;;          the back wall
          (define (check-ball-back-wall-collision b)
            (not (ball-collide-with-back-wall? b r))))
    (filter check-ball-back-wall-collision bl)))

;; TESTS:
(begin-for-test
  (check-equal?
   (remove-collided-balls (list (make-ball 39 645 -5 8) (make-ball 39 64 -2 8))
                          (make-racket 228 344 4 6 false 0 0))
   (list (make-ball 39 64 -2 8))
   "the ball which has collided with back wall should be removed"))



;; ball-after-tick: Ball Racket -> Ball
;; GIVEN: a ball and a racket
;; RETURNS: the ball that should follow the given ball after the tick

;; EXAMPLES:
;; (ball-after-tick (make-ball 2 4 -6 8)
;;                        (make-racket 228 344 4 6 false 0 0)) =>
;; (make-ball 4 12 6 8)

;; (ball-after-tick (make-ball 2 4 6 -6)
;;                        (make-racket 228 344 4 6 false 0 0)) =>
;; (make-ball 8 2 6 6)

;; DESIGN STRATEGY: Cases on different collision conditions
(define (ball-after-tick b r)
  (cond
    [(would-ball-racket-collide? b r) (ball-after-racket-collision b r)]

    [(and (ball-collide-with-left-wall? b r)
          (ball-collide-with-top-wall? b r))
     (ball-after-top-left-wall-collision b)]

    [(and (ball-collide-with-right-wall? b r)
          (ball-collide-with-top-wall? b r))
     (ball-after-top-right-wall-collision b)]
    
    [(ball-collide-with-left-wall? b r) (ball-after-left-wall-collision b)]

    [(ball-collide-with-right-wall? b r) (ball-after-right-wall-collision b)]
    
    [(ball-collide-with-top-wall? b r) (ball-after-top-wall-collision b)]

    [else (make-ball (+ (ball-x b) (ball-vx b))
                     (+ (ball-y b) (ball-vy b))
                     (ball-vx b)
                     (ball-vy b))]))

;; TESTS:
(begin-for-test
  (check-equal?
   (ball-after-tick (make-ball 2 4 -6 8)
                          (make-racket 228 344 4 6 false 0 0))
   (make-ball 4 12 6 8)
   "If ball collide with left wall, its x-velocity negates and x-coordinates
    change accordingly")
  
  (check-equal?
   (ball-after-tick (make-ball 420 4 10 8)
                          (make-racket 228 344 4 6 false 0 0))
   (make-ball 420 12 -10 8)
   "If ball collide with right wall, its x-velocity negates and x-coordinates
    change accordingly")
  
  (check-equal?
   (ball-after-tick (make-ball 2 4 6 -6)
                          (make-racket 228 344 4 6 false 0 0))
   (make-ball 8 2 6 6)
   "If ball collide with top wall, its y-velocity negates and y-coordinates
    change accordingly and one which collides with back wall is removed")
  
  (check-equal?
   (ball-after-tick (make-ball 128 210 -6 8)
                          (make-racket 228 344 4 -6 false 0 0))
   (make-ball 122 218 -6 8)
   "no collision, ball x and y coordinates change according to velocity")
  
  (check-equal?
   (ball-after-tick (make-ball 318 165 -3 9)
                          (make-racket 317 172 3 -3 false 0 0))
   (make-ball 315 174 -3 -12)
   "racket and ball collide, ball x and y coordinates change according
    to velocity")

  (check-equal?
   (ball-after-tick (make-ball 2 4 -4 -6)
                          (make-racket 228 344 4 6 false 0 0))
   (make-ball 2 2 4 6)
   "ball collides with left and top wall, its x and y velocity shloud negate")

  (check-equal?
   (ball-after-tick (make-ball 420 4 10 -6)
                          (make-racket 228 344 4 6 false 0 0))
   (make-ball 420 2 -10 6)
   "ball collides with right and top wall, x and y velocity should negate"))



;; ball-after-racket-collision : Ball Racket -> Ball
;; GIVEN: a ball and a racket
;; WHERE: the ball will collide with the racket in the next tick
;; RETURNS: a ball that should follow the given ball after it collides
;;          with the given racket

;; EXAMPLES:
;; (ball-after-racket-collision (make-ball 318 165 -3 9)) =>
;;                              (make-ball 315 174 -3 -12)

;; DESIGN STRATEGY: Use constructor template for Ball on b
(define (ball-after-racket-collision b r)
  (make-ball (+ (ball-x b) (ball-vx b))
             (+ (ball-y b) (ball-vy b))
             (ball-vx b)
             (- (racket-vy r) (ball-vy b))))

;; TESTS:
(begin-for-test
  (check-equal?
   (ball-after-racket-collision (make-ball 318 165 -3 9)
                                (make-racket 317 172 3 -3 false 0 0))
   (make-ball 315 174 -3 -12)
   "racket and ball collide, ball x and y coordinates change according
    to velocity"))


;; ball-after-top-left-wall-collision : Ball -> Ball
;; GIVEN: a ball
;; WHERE: the ball will collide with the top and left wall simultaneously in
;;        the next tick
;; RETURNS: a ball that should follow the given ball after it collides
;;          with the top and left wall simultaneously

;; EXAMPLES:
;; (ball-after-top-left-wall-collision (make-ball 2 4 -4 -6)) =>
;;                                     (make-ball 2 2 4 6)

;; DESIGN STRATEGY: Use constructor template for Ball on b
(define (ball-after-top-left-wall-collision b)
  (make-ball (- 0 (+ (ball-x b) (ball-vx b)))
             (- 0 (+ (ball-y b) (ball-vy b)))
             (- 0 (ball-vx b))
             (- 0 (ball-vy b))))

;; TESTS:
(begin-for-test
  (check-equal?
   (ball-after-top-left-wall-collision (make-ball 2 4 -4 -6))
   (make-ball 2 2 4 6)
   "ball collides with left and top wall, its x and y velocity shloud negate"))


;; ball-after-top-right-wall-collision : Ball -> Ball
;; GIVEN: a ball
;; WHERE: the ball will collide with the top and right wall simultaneously in
;;        the next tick
;; RETURNS: a ball that should follow the given ball after it collides
;;          with the top and right wall simultaneously

;; EXAMPLES:
;; (ball-after-top-right-wall-collision (make-ball 420 4 10 -6)) =>
;;                                      (make-ball 420 2 -10 6)

;; DESIGN STRATEGY: Use constructor template for Ball on b
(define (ball-after-top-right-wall-collision b)
  (make-ball (- 425 (- (+ (ball-x b) (ball-vx b)) 425))
             (- 0 (+ (ball-y b) (ball-vy b)))
             (- 0 (ball-vx b))
             (- 0 (ball-vy b))))

;; TESTS:
(begin-for-test
  (check-equal?
   (ball-after-top-right-wall-collision (make-ball 420 4 10 -6))
   (make-ball 420 2 -10 6)
   "ball collides with right and top wall, xa nd y velocity should negate"))


;; ball-after-left-wall-collision : Ball -> Ball
;; GIVEN: a ball
;; WHERE: the ball will collide with the left wall in the next tick
;; RETURNS: a ball that should follow the given ball after it collides
;;          with the left wall

;; EXAMPLES:
;; (ball-after-left-wall-collision (make-ball 2 4 -6 8)) => (make-ball 4 12 6 8)

;; DESIGN STRATEGY: Use constructor template for Ball on b
(define (ball-after-left-wall-collision b)
  (make-ball (- 0 (+ (ball-x b) (ball-vx b)))
             (+ (ball-y b) (ball-vy b))
             (- 0 (ball-vx b))
             (ball-vy b)))

;; TESTS:
(begin-for-test
  (check-equal?
   (ball-after-left-wall-collision (make-ball 2 4 -6 8))
   (make-ball 4 12 6 8)
   "If ball collide with left wall, its x-velocity negates and x-coordinates
    change accordingly"))


;; ball-after-right-wall-collision : Ball -> Ball
;; GIVEN: a ball
;; WHERE: the ball will collide with the right wall in the next tick
;; RETURNS: a ball that should follow the given ball after it collides
;;          with the right wall

;; EXAMPLES: 
;; (ball-after-right-wall-collision (make-ball 420 4 10 8)) =>
;;                                  (make-ball 420 12 -10 8)

;; DESIGN STRATEGY: Use constructor template for Ball on b
(define (ball-after-right-wall-collision b)
  (make-ball (- 425 (- (+ (ball-x b) (ball-vx b)) 425))
             (+ (ball-y b) (ball-vy b))
             (- 0 (ball-vx b))
             (ball-vy b)))

;; TESTS:
(begin-for-test
  (check-equal?
   (ball-after-right-wall-collision (make-ball 420 4 10 8))
   (make-ball 420 12 -10 8)
   "If ball collide with right wall, its x-velocity negates and x-coordinates
    change accordingly"))


;; ball-after-top-wall-collision : Ball -> Ball
;; GIVEN: a ball
;; WHERE: the ball will collide with the top wall in the next tick
;; RETURNS: a ball that should follow the given ball after it collides
;;          with the top wall

;; EXAMPLES:
;; (ball-after-top-wall-collision (make-ball 2 4 6 -6)) => (make-ball 8 2 6 6)

;; DESIGN STRATEGY: Use constructor template for Ball on b
(define (ball-after-top-wall-collision b)
  (make-ball (+ (ball-x b) (ball-vx b))
             (- 0 (+ (ball-y b) (ball-vy b)))
             (ball-vx b)
             (- 0 (ball-vy b))))

;; TESTS:
(begin-for-test
  (check-equal?
   (ball-after-top-wall-collision (make-ball 2 4 6 -6))
   (make-ball 8 2 6 6)
   "If ball collide with top wall, its y-velocity negates and y-coordinates
    change accordingly and one which collides with back wall is removed"))


;; racket-after-tick : BallList Racket -> Racket
;; GIVEN: a list of balls and any racket that is possible for the simulation
;; RETURNS: the racket that should follow the given racket after the tick

;; EXAMPLES:
;; (racket-after-tick (list (make-ball 420 4 10 8))
;;                    (make-racket 30 40 -10 6 false 0 0)) =>
;;                    (make-racket 47/2 46 10 6 false 0 0)

;; (racket-after-tick (list (make-ball 420 4 10 8))
;;                    (make-racket 415 40 6 8 false 0 0)) =>
;;                    (make-racket (- 425 47/2) 46 10 6 false 0 0)

;; (racket-after-tick (list (make-ball 420 4 10 8))
;;                    (make-racket 310 640 10 10 false 0 0)) =>
;;                    (make-racket 320 649 10 0 false 0 0)

;; (racket-after-tick (list (make-ball 420 4 10 8))
;;                    (make-racket 210 4 10 6 false 0 0)) =>
;;                    (make-racket 220 10 10 6 false 0 0)


;; DESIGN-STRATEGY: Cases on different conditions of collisions
(define (racket-after-tick bl r)
  (cond
    [(racket-collide-with-left-wall? r) (racket-after-left-wall-collision r)]
    
    [(racket-collide-with-right-wall? r) (racket-after-right-wall-collision r)]
    
    [(racket-collide-with-back-wall? r) (racket-after-back-wall-collision r)]
    
    [(would-racket-ball-collide? bl r) (racket-after-ball-collision r)]

    [(racket-selected? r) (racket-after-selected r)]
        
    [else (make-racket (+ (racket-x r) (racket-vx r))
                       (+ (racket-y r) (racket-vy r)) (racket-vx r)
                       (racket-vy r) (racket-selected? r)
                       (racket-mx r) (racket-my r))]))


;; TESTS:
(begin-for-test
  (check-equal?
   (racket-after-tick (list (make-ball 420 4 10 8))
                      (make-racket 30 40 -10 6 false 0 0))
   (make-racket 24 46 -10 6 false 0 0)
   "If racket collide with left wall it should stick with the left wall
    and continue moving in y direction")
  
  (check-equal?
   (racket-after-tick (list (make-ball 420 4 10 8))
                      (make-racket 415 40 10 8 false 0 0))
   (make-racket 402 48 10 8 false 0 0)
   "If racket collide with right wall it should stick with the right wall
    and continue moving in y direction")
  
  (check-equal?
   (racket-after-tick (list (make-ball 420 4 10 8))
                      (make-racket 310 640 10 10 false 0 0))
   (make-racket 320 649 10 0 false 0 0)
   "If racket collide with back wall it should stick with the back wall
    and continue moving in x direction")
  
  (check-equal?
   (racket-after-tick (list (make-ball 420 4 10 8))
                      (make-racket 210 4 10 6 false 0 0))
   (make-racket 220 10 10 6 false 0 0)
   "no collision, racket's x and y position change according to its velocty")
  
  (check-equal?
   (racket-after-tick (list (make-ball 420 4 10 8) (make-ball 318 165 -3 9))
                      (make-racket 317 172 3 -3 false 0 0))
   (make-racket 320 169 3 0 false 0 0)
   "racket collides with ball, and its y-velocity is negative so it
    should become 0")
  
  (check-equal?
   (racket-after-tick (list (make-ball 420 4 10 8) (make-ball 318 165 -3 9))
                      (make-racket 317 172 3 1 false 0 0))
   (make-racket 320 173 3 1 false 0 0)
   "racket collides with ball, and its y-velocity is not negative so it
    should remain same")

  (check-equal?
   (racket-after-tick (list (make-ball 420 4 10 8))
                      (make-racket 57 49 4 6 true 65 60))
   (make-racket 57 49 4 6 true 65 60)
   "racket is selected, so no change in position"))


;; racket-after-left-wall-collision : Racket -> Racket
;; GIVEN: a racket
;; WHERE: the racket will collide with the left wall in the next tick
;; RETURNS: a racket that should follow the given racket after it collides
;;          with left wall

;; EXAMPLES:
;; (racket-after-left-wall-collision (make-racket 30 40 -10 6 false 0 0)) =>
;;                                    (make-racket 24 46 -10 6 false 0 0)

;; DESIGN STRATEGY: Use constructor template for Racket on r
(define (racket-after-left-wall-collision r)
  (make-racket (round (/ RACKET-WIDTH 2)) (+ (racket-y r) (racket-vy r))
               (racket-vx r) (racket-vy r) (racket-selected? r)
               (racket-mx r) (racket-my r)))

;; TEST:
(begin-for-test
  (check-equal?
   (racket-after-left-wall-collision (make-racket 30 40 -10 6 false 0 0))
   (make-racket 24 46 -10 6 false 0 0)
   "If racket collide with left wall it should stick with the left wall
    and continue moving in y direction"))


;; racket-after-right-wall-collision : Racket -> Racket
;; GIVEN: a racket
;; WHERE: the racket will collide with the right wall in the next tick
;; RETURNS: a racket that should follow the given racket after it collides
;;          with right wall

;; EXAMPLES:
;; (racket-after-right-wall-collision (make-racket 415 40 10 8 false 0 0)) =>
;;                                    (make-racket 402 48 10 8 false 0 0)

;; DESIGN STRATEGY: Use constructor template for Racket on r
(define (racket-after-right-wall-collision r)
  (make-racket (round (- COURT-WIDTH (/ RACKET-WIDTH 2)))
               (+ (racket-y r) (racket-vy r)) (racket-vx r) (racket-vy r)
               (racket-selected? r) (racket-mx r) (racket-my r)))

;; TEST:
(begin-for-test
  (check-equal?
   (racket-after-right-wall-collision (make-racket 415 40 10 8 false 0 0))
   (make-racket 402 48 10 8 false 0 0)
   "If racket collide with right wall it should stick with the right wall
    and continue moving in y direction"))


;; racket-after-back-wall-collision : Racket -> Racket
;; GIVEN: a racket
;; WHERE: the racket will collide with the back wall in the next tick
;; RETURNS: a racket that should follow the given racket after it collides
;;          with back wall

;; EXAMPLES:
;; (racket-after-back-wall-collision (make-racket 310 640 10 10 false 0 0)) =>
;;                                   (make-racket 320 649 10 0 false 0 0)

;; DESIGN STRATEGY: Use constructor template for Racket on r
(define (racket-after-back-wall-collision r)
  (make-racket (+ (racket-x r) (racket-vx r)) COURT-HEIGHT (racket-vx r) 0
               (racket-selected? r) (racket-mx r) (racket-my r)))

;; TEST:
(begin-for-test
  (check-equal?
   (racket-after-back-wall-collision (make-racket 310 640 10 10 false 0 0))
   (make-racket 320 649 10 0 false 0 0)
   "If racket collide with back wall it should stick with the back wall
    and continue moving in x direction"))



;; racket-after-ball-collision : Racket -> Racket
;; GIVEN: a racket
;; WHERE: the racket will collide with a ball in the next tick
;; RETURNS: a racket that should follow the given racket after it collides
;;          with a ball

;; EXAMPLES:
;; (racket-after-ball-collision (make-racket 317 172 3 -3 false 0 0)) =>
;;                              (make-racket 320 169 3 0 false 0 0)

;; DESIGN STRATEGY: Use constructor template for Racket on r
(define (racket-after-ball-collision r)
  (make-racket (+ (racket-x r) (racket-vx r))
               (+ (racket-y r) (racket-vy r))
               (racket-vx r) (if (< (racket-vy r) 0) 0 (racket-vy r))
               (racket-selected? r) (racket-mx r) (racket-my r)))

;; TEST:
(begin-for-test
  (check-equal?
   (racket-after-ball-collision (make-racket 317 172 3 -3 false 0 0))
   (make-racket 320 169 3 0 false 0 0)
   "racket collides with ball, and its y-velocity is negative so it
    should become 0"))


;; racket-after-selected : Racket -> Racket
;; GIVEN: a racket
;; WHERE: the racket has been selected in this tick
;; RETURNS: a racket that should follow the given racket after it is selected

;; EXAMPLES:
;; (racket-after-selected (make-racket 57 49 4 6 true 65 60)) =>
;;                        (make-racket 57 49 4 6 true 65 60)

;; DESIGN STRATEGY: Use constructor template for Racket on r
(define (racket-after-selected r)
  (make-racket (racket-x r) (racket-y r) (racket-vx r) (racket-vy r)
               (racket-selected? r) (racket-mx r) (racket-my r)))

;; TEST:
(begin-for-test
  (check-equal?
   (racket-after-selected (make-racket 57 49 4 6 true 65 60))
   (make-racket 57 49 4 6 true 65 60)
   "racket is selected, so no change in position"))



;; would-racket-ball-collide? : BallList Racket -> Boolean
;; GIVEN: a list of balls and a racket
;; RETURNS: true if and only if any one of the balls will collide with
;;          the racket

;; EXAMPLES:
;; (would-racket-ball-collide? (list (make-ball 420 4 10 8)
;;                                     (make-ball 318 165 -3 9))
;;                               (make-racket 320 173 3 1 false 0 0)) => true

;; (would-racket-ball-collide? empty
;; (make-racket 320 173 3 1 false 0 0)) => false

;; DESIGN STRATEGY: Use observer template for BallList
;(define (would-racket-ball-collide? bl r)
;  (cond
;    [(empty? bl) false]
;    [(would-ball-racket-collide? (first bl) r) true]
;    [else (would-racket-ball-collide? (rest bl) r)]))

;; DESIGN STRATEGY: Use HOF ormap on bl
(define (would-racket-ball-collide? bl r)
  (local (;; Ball -> Boolean
          ;; RETURNS: true if and only if the given ball will collide with the
          ;;          given racket in the next tick
          (define (check-racket-ball-collision b)
            (would-ball-racket-collide? b r)))
    (ormap check-racket-ball-collision bl)))

;; TESTS:
(begin-for-test
  (check-equal?
   (would-racket-ball-collide? (list (make-ball 420 4 10 8)
                                     (make-ball 318 165 -3 9))
                               (make-racket 320 173 3 1 false 0 0))
   true "racket collide with ball, so return true")
  
  (check-equal?
   (would-racket-ball-collide? empty (make-racket 320 173 3 1 false 0 0))
   false "ball list is empty, so return false"))




;; world-after-key-event : World KeyEvent -> World
;; GIVEN: any world and a key event
;; RETURNS: the world that should follow the given world after the key event

;; EXAMPLES:
;; (world-after-key-event WORLD-IN-READY-TO-SERVE-STATE " ") =>
;; (make-world (make-ball 330 384 3 -9) (make-racket 330 384 0 0 false 0 0)
;;              "rally" 0.5 6)

;; (world-after-key-event (make-world (make-ball 410 410 4 5)
;;                                    (make-racket 330 210 4 -6 false 0 0)
;;                                    "rally" 0.5 6) "left") =>
;; (make-world (make-ball 410 410 4 5) (make-racket 330 210 3 -6 false 0 0)
;;             "rally" 0.5 6)


;; DESIGN-STRATEGY: Cases on different key events
(define (world-after-key-event w ke)
  (cond
    [(key=? ke " ") (world-after-space-bar w)]
    [(key=? ke "left") (world-after-left-key w)]
    [(key=? ke "right") (world-after-right-key w)]
    [(key=? ke "up") (world-after-up-key w)]
    [(key=? ke "down") (world-after-down-key w)]
    [(key=? ke "b") (world-after-b-key w)]
    [else w]))


;; TESTS:
(begin-for-test
  (check-equal?
   (world-after-key-event WORLD-IN-READY-TO-SERVE-STATE " ")
   (make-world (list (make-ball 330 384 3 -9))
               (make-racket 330 384 0 0 false 0 0) "rally" 0.5 6)
   "if world in ready-to-serve state, pressing space changes its state
    to rally state")
  
  (check-equal?
   (world-after-key-event (make-world (list (make-ball 410 410 4 5))
                                      (make-racket 330 210 4 -6 false 0 0)
                                      "rally" 0.5 6) "left")
   (make-world (list (make-ball 410 410 4 5))
               (make-racket 330 210 3 -6 false 0 0) "rally" 0.5 6)
   "pressing left key decreses racket's x-velocity by 1")
  
  (check-equal?
   (world-after-key-event (make-world (list (make-ball 410 410 4 5))
                                      (make-racket 330 210 4 -6 false 0 0)
                                      "rally" 0.5 6) "right")
   (make-world (list (make-ball 410 410 4 5))
               (make-racket 330 210 5 -6 false 0 0) "rally" 0.5 6)
   "pressing right key increases racket's x-velocity by 1")
  
  (check-equal?
   (world-after-key-event (make-world (list (make-ball 410 410 4 5))
                                      (make-racket 330 210 4 -6 false 0 0)
                                      "rally" 0.5 6) "up")
   (make-world (list (make-ball 410 410 4 5))
               (make-racket 330 210 4 -7 false 0 0) "rally" 0.5 6)
   "pressing up key decreses racket's y-velocity by 1")
  
  (check-equal?
   (world-after-key-event (make-world (list (make-ball 410 410 4 5))
                                      (make-racket 330 210 4 -6 false 0 0)
                                      "rally" 0.5 6) "down")
   (make-world (list (make-ball 410 410 4 5))
               (make-racket 330 210 4 -5 false 0 0) "rally" 0.5 6)
   "pressing down key increases racket's y-velocity by 1")

  (check-equal?
   (world-after-key-event (make-world (list (make-ball 410 410 4 5))
                                      (make-racket 330 210 4 -6 false 0 0)
                                      "rally" 0.5 6) "b")
   (make-world (list (make-ball 330 384 3 -9) (make-ball 410 410 4 5))
               (make-racket 330 210 4 -6 false 0 0) "rally" 0.5 6)
   "pressing b key creates new ball")
  
  (check-equal?
   (world-after-key-event (make-world (list (make-ball 410 410 4 5))
                                      (make-racket 330 210 4 -6 false 0 0)
                                      "rally" 0.5 6) "f")
   (make-world (list (make-ball 410 410 4 5))
               (make-racket 330 210 4 -6 false 0 0) "rally" 0.5 6)
   "pressing any other key does not have any change"))




;; world-after-space-bar : World -> World
;; GIVEN: a world
;; RETURNS: the world that should follow the given world after space bar
;;          is pressed

;; EXAMPLES:
;; (world-after-space-bar world-in-ready-to-serve) => WORLD-IN-RALLY-STATE

;; (world-after-space-bar (make-world (make-ball 234 256 3 5)
;;                                    (make-racket 134 467 3 6 false 0 0)
;;                                    "rally" 0.5 6)) =>
;; (make-world (make-ball 234 256 0 0) (make-racket 134 467 0 0 false 0 0)
;;             "paused" 0.5 6)

;; DESIGN-STRATEGY: Combine simpler functions
(define (world-after-space-bar w)
  (cond
    [(world-ready-to-serve? w) (world-after-ready-to-serve w)]
    [(world-rally? w) (world-after-rally w)]
    [else w]))

;; TESTS:
(begin-for-test
  (check-equal?
   (world-after-space-bar WORLD-IN-READY-TO-SERVE-STATE)
   (make-world (list (make-ball 330 384 3 -9))
               (make-racket 330 384 0 0 false 0 0) "rally" 0.5 6)
   "if world in ready-to-serve, pressing space bar will change its state
    to rally")
  
  (check-equal?
   (world-after-space-bar (make-world (list (make-ball 234 256 3 5))
                                      (make-racket 134 467 3 6 false 0 0)
                                      "rally" 0.5 6))
   (make-world (list (make-ball 234 256 0 0))
               (make-racket 134 467 0 0 false 0 0) "paused" 0.5 6)
   "if world in rally, pressing space bar will change its state to paused")
  
  (check-equal?
   (world-after-space-bar WORLD-IN-PAUSED-STATE) WORLD-IN-PAUSED-STATE
   "if world in paused, pressing space bar will have no change in the world"))



;; world-after-ready-to-serve : World -> World
;; GIVEN: a world in ready-to-serve state
;; RETURNS: the world that should follow the given world after space bar
;;          is pressed

;; EXAMPLES:
;; (world-after-ready-to-serve world-in-ready-to-serve) => WORLD-IN-RALLY-STATE

;; DESIGN-STRATEGY: Use constructor template for World
(define (world-after-ready-to-serve w)
  (make-world (ball-after-ready-to-serve (world-balls w))
              (world-racket w) RALLY-STATE (world-speed w)
              (world-pause-counter w)))

;; TESTS:
(begin-for-test
  (check-equal?
   (world-after-ready-to-serve WORLD-IN-READY-TO-SERVE-STATE)
   (make-world (list (make-ball 330 384 3 -9))
               (make-racket 330 384 0 0 false 0 0) "rally" 0.5 6)
   "if world in ready-to-serve, pressing space bar will change its state
    to rally"))


;; world-after-rally : World -> World
;; GIVEN: a world in rally state
;; RETURNS: the world that should follow the given world after space bar
;;          is pressed

;; EXAMPLES:
;; (world-after-rally (make-world (make-ball 234 256 3 5)
;;                                (make-racket 134 467 3 6 false 0 0)
;;                                "rally" 0.5 6)) =>
;;                    (make-world (make-ball 234 256 0 0)
;;                                (make-racket 134 467 0 0 false 0 0)
;;                                "paused" 0.5 6)

;; DESIGN-STRATEGY: Use constructor template for World
(define (world-after-rally w)
  (make-world (balls-after-rally (world-balls w) (world-racket w))
              (racket-after-rally (world-racket w)) PAUSED-STATE
              (world-speed w) (world-pause-counter w)))

;; TESTS:
(begin-for-test
  (check-equal?
   (world-after-rally (make-world (list (make-ball 234 256 3 5))
                                  (make-racket 134 467 3 6 false 0 0)
                                  "rally" 0.5 6))
   (make-world (list (make-ball 234 256 0 0))
               (make-racket 134 467 0 0 false 0 0) "paused" 0.5 6)
   "if world in rally, pressing space bar will change its state to paused"))



;; ball-after-ready-to-serve : BallList -> BallList
;; GIVEN: a list of balls in ready-to-serve state
;; WHERE: the list contains only one ball
;; RETURNS: the list of balls that should follow the given list of balls
;;          after space bar is pressed

;; EXAMPLES:
;; (ball-after-ready-to-serve (list (make-ball 330 384 0 0))) =>
;; (list (make-ball 330 384 3 -9))

;; DESIGN-STRATEGY: Use constructor template for BallList
(define (ball-after-ready-to-serve bl)
  (list (make-ball (ball-x (first bl)) (ball-y (first bl)) 3 -9)))

;; TESTS:
(begin-for-test
  (check-equal?
   (ball-after-ready-to-serve (list (make-ball 330 384 0 0)))
   (list (make-ball 330 384 3 -9))
   "ball with velocity (-3 9)"))



;; balls-after-rally : BallList Racket -> BallList
;; GIVEN: a list of balls and a racket
;; WHERE: the balls and the racket are in rally state
;; RETURNS: the list of balls that should follow the given list of balls after
;;          space bar is pressed

;; EXAMPLES:
;; (balls-after-rally (list (make-ball 234 280 3 6) (make-ball 35 65 2 6))) =>
;; (list (make-ball 234 280 0 0) (make-ball 35 65 0 0))

;; DESIGN-STRATEGY: Use observer template for BallList
;(define (balls-after-rally bl r)
;  (cond
;    [(empty? bl) bl]
;    [(and (= (length bl) 1) (ball-collide-with-back-wall? (first bl) r))
;     (remove (first bl) bl)]
;    [else (cons (make-ball (ball-x (first bl)) (ball-y (first bl)) 0 0)
;                (balls-after-rally (rest bl) r))]))


;; DESIGN-STRATEGY: Use HOF map on bl
(define (balls-after-rally bl r)
  (cond
    [(and (= (length bl) 1) (ball-collide-with-back-wall? (first bl) r)) empty]
    [else (local (;; paused-ball : BallList -> BallList
                  ;; RETURNS: a list of balls just like the given list of balls
                  ;;          except that the velocity of balls become 0
                  (define (paused-ball b)
                    (make-ball (ball-x b) (ball-y b) 0 0)))
            (map paused-ball bl))]))
  

;; TESTS:
(begin-for-test
  (check-equal?
   (balls-after-rally (list (make-ball 234 645 3 6))
                      (make-racket 167 256 4 9 false 0 0))
   empty "if ball collide with back wall it is removed from list")
  (check-equal?
   (balls-after-rally (list (make-ball 234 280 3 6) (make-ball 35 65 2 6))
                      (make-racket 47 39 2 4 false 0 0))
   (list (make-ball 234 280 0 0) (make-ball 35 65 0 0))
   "if ball in rally state and space bar pressed ball's velocity becomes 0"))



;; racket-after-rally : Racket -> Racket
;; GIVEN: a racket in rally-state
;; RETURNS: the racket that should follow the given racket after space bar
;;          is pressed

;; EXAMPLES:
;; (racket-after-rally (make-racket 178 4 5 -6 false 0 0)) =>
;;                     (make-racket 178 0 0 0 false 0 0)
;; (racket-after-rally (make-racket 178 234 5 -6 false 0 0)) =>
;;                     (make-racket 178 234 0 0 false 0 0)

;; DESIGN-STRATEGY: Use constructor template for Racket on r
(define (racket-after-rally r)
  (if (racket-collide-with-top-wall? r)
      (make-racket (racket-x r) 0 0 0 false 0 0)
      (make-racket (racket-x r) (racket-y r) 0 0 false 0 0)))

;; TESTS:
(begin-for-test
  (check-equal?
   (racket-after-rally (make-racket 178 4 5 -6 false 0 0))
   (make-racket 178 0 0 0 false 0 0)
   "if racket collide with top wall world goes in pause state")
  
  (check-equal?
   (racket-after-rally (make-racket 178 234 5 -6 false 0 0))
   (make-racket 178 234 0 0 false 0 0)
   "if racket in rally state and space bar pressed racket go in paused state"))



;; world-after-left-key : World -> World
;; GIVEN: a world
;; RETURNS: the world that should follow the given world after left key
;;          is pressed

;; EXAMPLES:
;; (world-after-left-key WORLD-IN-PAUSED-STATE) => WORLD-IN-PAUSED-STATE

;; (world-after-left-key (make-world (list (make-ball 410 410 4 5))
;;                                     (make-racket 330 210 4 -6 false 0 0)
;;                                     "rally" 0.5 6)) =>
;; (make-world (list (make-ball 410 410 4 5))
;;               (make-racket 330 210 3 -6 false 0 0) "rally" 0.5 6)

;; (world-after-left-key WORLD-IN-READY-TO-SERVE-STATE) =>
;; WORLD-IN-READY-TO-SERVE-STATE


;; DESIGN-STRATEGY: Use constructor template for world
(define (world-after-left-key w)
  (cond
    [(world-rally? w)
     (make-world (world-balls w) (change-racket-x-velocity (world-racket w) -1)
                 (world-state w) (world-speed w) (world-pause-counter w))]
    [else w]))

;; TESTS:
(begin-for-test
  (check-equal?
   (world-after-left-key WORLD-IN-PAUSED-STATE) WORLD-IN-PAUSED-STATE
   "if world in paused state it will remain in its previous state")
  
  (check-equal?
   (world-after-left-key (make-world (list (make-ball 410 410 4 5))
                                     (make-racket 330 210 4 -6 false 0 0)
                                     "rally" 0.5 6))
   (make-world (list (make-ball 410 410 4 5))
               (make-racket 330 210 3 -6 false 0 0) "rally" 0.5 6)
   "if world in rally state racket's x-velocity decreses by 1")
  
  (check-equal?
   (world-after-left-key WORLD-IN-READY-TO-SERVE-STATE)
   WORLD-IN-READY-TO-SERVE-STATE
   "if world in ready-to-serve state it will remain in its previous state"))



;; world-after-right-key : World -> World
;; GIVEN: a world
;; RETURNS: the world that should follow the given world after right key
;;          is pressed

;; EXAMPLES:
;; (world-after-right-key WORLD-IN-PAUSED-STATE) => WORLD-IN-PAUSED-STATE

;; (world-after-right-key (make-world (list (make-ball 410 410 4 5))
;;                                      (make-racket 330 210 4 -6 false 0 0)
;;                                      "rally" 0.5 6)) =>
;; (make-world (list (make-ball 410 410 4 5))
;;               (make-racket 330 210 5 -6 false 0 0) "rally" 0.5 6)

;; (world-after-right-key WORLD-IN-READY-TO-SERVE-STATE)
;;   WORLD-IN-READY-TO-SERVE-STATE


;; DESIGN-STRATEGY: Use constructor template for World on w
(define (world-after-right-key w)
  (cond
    [(world-rally? w)
     (make-world (world-balls w) (change-racket-x-velocity (world-racket w) 1)
                 (world-state w) (world-speed w) (world-pause-counter w))]
    [else w]))

;; TESTS:
(begin-for-test
  (check-equal?
   (world-after-right-key WORLD-IN-PAUSED-STATE) WORLD-IN-PAUSED-STATE
   "if world in paused state it will remain in its previous state")
  
  (check-equal?
   (world-after-right-key (make-world (list (make-ball 410 410 4 5))
                                      (make-racket 330 210 4 -6 false 0 0)
                                      "rally" 0.5 6))
   (make-world (list (make-ball 410 410 4 5))
               (make-racket 330 210 5 -6 false 0 0) "rally" 0.5 6)
   "if world in rally state racket's x-velocity increases by 1")
  
  (check-equal?
   (world-after-right-key WORLD-IN-READY-TO-SERVE-STATE)
   WORLD-IN-READY-TO-SERVE-STATE
   "if world in ready-to-serve state it will remain in its previous state"))



;; world-after-up-key : World -> World
;; GIVEN: a world
;; RETURNS: the world that should follow the given world after up key
;;          is pressed

;; EXAMPLES:
;; (world-after-up-key WORLD-IN-PAUSED-STATE) WORLD-IN-PAUSED-STATE

;; (world-after-up-key (make-world (list (make-ball 410 410 4 5))
;;                                   (make-racket 330 210 4 -6 false 0 0)
;;                                   "rally" 0.5 6)) =>
;; (make-world (list (make-ball 410 410 4 5))
;;               (make-racket 330 210 4 -7 false 0 0) "rally" 0.5 6)

;; (world-after-up-key WORLD-IN-READY-TO-SERVE-STATE)
;;   WORLD-IN-READY-TO-SERVE-STATE

;; DESIGN-STRATEGY: Use constructor template for World on w
(define (world-after-up-key w)
  (cond
    [(world-rally? w)
     (make-world (world-balls w) (change-racket-y-velocity (world-racket w) -1)
                 (world-state w) (world-speed w) (world-pause-counter w))]
    [else w]))

;; TESTS:
(begin-for-test
  (check-equal?
   (world-after-up-key WORLD-IN-PAUSED-STATE) WORLD-IN-PAUSED-STATE
   "if world in paused state it will remain in its previous state")
  
  (check-equal?
   (world-after-up-key (make-world (list (make-ball 410 410 4 5))
                                   (make-racket 330 210 4 -6 false 0 0)
                                   "rally" 0.5 6))
   (make-world (list (make-ball 410 410 4 5))
               (make-racket 330 210 4 -7 false 0 0) "rally" 0.5 6)
   "if world in rally state racket's y-velocity decreases by 1")
  
  (check-equal?
   (world-after-up-key WORLD-IN-READY-TO-SERVE-STATE)
   WORLD-IN-READY-TO-SERVE-STATE
   "if world in ready-to-serve state it will remain in its previous state"))




;; world-after-down-key : World -> World
;; GIVEN: a world
;; RETURNS: the world that should follow the given world after down key
;;          is pressed

;; EXAMPLES:
;; (world-after-down-key WORLD-IN-PAUSED-STATE) WORLD-IN-PAUSED-STATE

;; (world-after-down-key (make-world (list (make-ball 410 410 4 5))
;;                                     (make-racket 330 210 4 -6 false 0 0)
;;                                     "rally" 0.5 6)) =>
;; (make-world (list (make-ball 410 410 4 5))
;;               (make-racket 330 210 4 -5 false 0 0) "rally" 0.5 6)

;; (world-after-down-key WORLD-IN-READY-TO-SERVE-STATE)
;;   WORLD-IN-READY-TO-SERVE-STATE

;; DESIGN-STRATEGY: Use constructor template for World on w
(define (world-after-down-key w)
  (cond
    [(world-rally? w)
     (make-world (world-balls w) (change-racket-y-velocity (world-racket w) 1)
                 (world-state w) (world-speed w) (world-pause-counter w))]
    [else w]))

;; TESTS:
(begin-for-test
  (check-equal?
   (world-after-down-key WORLD-IN-PAUSED-STATE) WORLD-IN-PAUSED-STATE
   "if world in paused state it will remain in its previous state")
  
  (check-equal?
   (world-after-down-key (make-world (list (make-ball 410 410 4 5))
                                     (make-racket 330 210 4 -6 false 0 0)
                                     "rally" 0.5 6))
   (make-world (list (make-ball 410 410 4 5))
               (make-racket 330 210 4 -5 false 0 0) "rally" 0.5 6)
   "if world in rally state racket's y-velocity increases by 1")
  
  (check-equal?
   (world-after-down-key WORLD-IN-READY-TO-SERVE-STATE)
   WORLD-IN-READY-TO-SERVE-STATE
   "if world in ready-to-serve state it will remain in its previous state"))



;; world-after-b-key : World -> World
;; GIVEN: a world
;; RETURNS: the world that should follow the given world after 'b' key
;;          is pressed

;; EXAMPLES:
;; (world-after-b-key (make-world (list (make-ball 410 410 4 5))
;;                                     (make-racket 330 210 4 -6 false 0 0)
;;                                     "rally" 0.5 6)) =>
;; (make-world (list (make-ball 410 410 4 5) (make-ball 330 338 3 -9))
;;                                     (make-racket 330 210 4 -6 false 0 0)
;;                                     "rally" 0.5 6)

;; (world-after-down-key WORLD-IN-READY-TO-SERVE-STATE)
;;   WORLD-IN-READY-TO-SERVE-STATE

;; DESIGN-STRATEGY: Use constructor template for World on w
(define (world-after-b-key w)
  (cond
    [(world-rally? w)
     (make-world (ball-after-b-key (world-balls w)) (world-racket w)
                 (world-state w) (world-speed w) (world-pause-counter w))]
    [else w]))

;; TESTS:
(begin-for-test
  (check-equal?
   (world-after-b-key (make-world (list (make-ball 410 410 4 5))
                                  (make-racket 330 210 4 -6 false 0 0)
                                  "rally" 0.5 6))
   (make-world (list (make-ball 330 384 3 -9) (make-ball 410 410 4 5))
               (make-racket 330 210 4 -6 false 0 0)
               "rally" 0.5 6)
   "after 'b' key, a new ball is created")
  
  (check-equal?
   (world-after-b-key WORLD-IN-READY-TO-SERVE-STATE)
   WORLD-IN-READY-TO-SERVE-STATE
   "if world in ready-to-serve state it will remain in its previous state"))



;; ball-after-b-key : BallList -> BallList
;; GIVEN: a list of balls
;; WHERE: the balls are in rally state
;; RETURNS: a list of balls just like the given except that a ball is added
;;          in it

;; EXAMPLES:
;; (ball-after-b-key (list (make-ball 410 410 4 5))) =>
;; (list (make-ball 410 410 4 5) (make-ball 330 338 3 -9))

;; DESIGN-STRATEGY: Use constructor template for BallList on bl
(define (ball-after-b-key bs)
  (cons (make-ball BALL-X-COORD BALL-Y-COORD 3 -9) bs))

;; TESTS:
(begin-for-test
  (check-equal?
   (ball-after-b-key (list (make-ball 410 410 4 5)))
   (list (make-ball 330 384 3 -9) (make-ball 410 410 4 5))
   "after 'b' key, a new ball is created"))



;; world-after-mouse-event : World Integer Integer MouseEvent -> World
;; GIVEN: a world, the x and y coordinates of a mouse and a mouse event
;; RETURNS: the world that should follow the given world after the given
;;          mouse event

;; EXAMPLES:
;; (world-after-mouse-event WORLD-IN-READY-TO-SERVE-STATE 65 60 "button-down")
;; => WORLD-IN-READY-TO-SERVE-STATE

;; DESIGN-STRATEGY: Use constructor template for World on w
(define (world-after-mouse-event w mx my me)
  (if (world-rally? w)
      (make-world (world-balls w)
                  (racket-after-mouse-event (world-racket w) mx my me)
                  (world-state w) (world-speed w) (world-pause-counter w)) w))

;; TESTS:
(begin-for-test
  (check-equal?
   (world-after-mouse-event WORLD-IN-READY-TO-SERVE-STATE 65 60 "button-down")
   WORLD-IN-READY-TO-SERVE-STATE
   "world is not in rally state")

  (check-equal?
   (world-after-mouse-event (make-world (list (make-ball 410 410 4 5))
                                        (make-racket 57 49 4 6 true 65 60)
                                        "rally" 0.5 4) 65 60 "button-up")
   (make-world (list (make-ball 410 410 4 5))
               (make-racket 57 49 4 6 false 0 0) "rally" 0.5 4)
   "up-mouse-event, so racket should be unselected"))



;; racket-after-mouse-event : Racket Integer Integer MouseEvent -> Racket
;; GIVEN: a racket, the x and y coordinates of a mouse and a mouse event
;; WHERE: the racket is in the rally state
;; RETURNS: the racket as it should be after the given mouse event

;; EXAMPLES:
;; (racket-after-mouse-event (make-racket 57 49 4 6 false 0 0) 65 60
;;                            "button-down") =>
;;                            (make-racket 57 49 4 6 true 65 60)

;; (racket-after-mouse-event (make-racket 57 49 4 6 true 65 60) 65 60
;;                            "button-up") =>
;;                            (make-racket 57 49 4 6 false 0 0)

;; DESIGN-STRATEGY: Cases on mouse events
(define (racket-after-mouse-event r mx my me)
  (cond
    [(mouse=? me BUTTON-DOWN) (racket-after-button-down r mx my)]
    [(mouse=? me BUTTON-UP) (racket-after-button-up r mx my)]
    [(mouse=? me DRAG) (racket-after-drag r mx my)]
    [else r]))

;; TESTS:
(begin-for-test
  (check-equal?
   (racket-after-mouse-event (make-racket 57 49 4 6 false 0 0)
                             65 60 "button-down")
   (make-racket 57 49 4 6 true 65 60)
   "racket should be selected")
  
  (check-equal?
   (racket-after-mouse-event (make-racket 57 49 4 6 true 65 60)
                             65 60 "button-up")
   (make-racket 57 49 4 6 false 0 0)
   "racket should be unselected")
  
  (check-equal?
   (racket-after-mouse-event (make-racket 156 345 7 8 true 176 355)
                             180 350 "drag")
   (make-racket 160 340 7 8 true 180 350)
   "racket should be draggable")

  (check-equal?
   (racket-after-mouse-event (make-racket 156 345 7 8 true 176 355)
                             180 350 "move")
   (make-racket 156 345 7 8 true 176 355)
   "not valid mouse event"))



;; racket-after-button-down : Racket Integer Integer -> Racket
;; GIVEN: a racket, the x and y coordinates of a mouse
;; WHERE: the racket is in the rally state
;; RETURNS: the racket as it should be after the button-down mouse event

;; EXAMPLES:
;; (racket-after-button-down (make-racket 57 49 4 6 false 0 0) 65 60) =>
;;                           (make-racket 57 49 4 6 true 5 7)

;; (racket-after-button-down (make-racket 57 49 4 6 false 0 0) 87 80) =>
;;                           (make-racket 57 49 4 6 false 0 0)

;; DESIGN-STRATEGY: Use constructor template for Racket
(define (racket-after-button-down r mx my)
  (if (point-inside-racket? r mx my)
      (make-racket (racket-x r) (racket-y r) (racket-vx r) (racket-vy r)
                   true mx my)
      (make-racket (racket-x r) (racket-y r) (racket-vx r) (racket-vy r)
                   false 0 0)))

;; TESTS:
(begin-for-test
  (check-equal?
   (racket-after-button-down (make-racket 57 49 4 6 false 0 0) 65 60)
   (make-racket 57 49 4 6 true 65 60)
   "racket should be selected")
  (check-equal?
   (racket-after-button-down (make-racket 57 49 4 6 false 0 0) 87 80)
   (make-racket 57 49 4 6 false 0 0)
   "point not inside, so not selected"))


;; racket-after-button-up : Racket Integer Integer -> Racket
;; GIVEN: a racket, the x and y coordinates of a mouse
;; WHERE: the racket is in the rally state
;; RETURNS: the racket as it should be after the button-up mouse event

;; EXAMPLES:
;; (racket-after-button-up (make-racket 57 49 4 6 true 65 60) 60 58) =>
;;                         (make-racket 57 49 4 6 false 0 0)
;; (racket-after-button-up (make-racket 57 49 4 6 false 0 0) 87 80) =>
;;                         (make-racket 57 49 4 6 false 0 0)

;; DESIGN-STRATEGY: Use constructor template for Racket on r
(define (racket-after-button-up r mx my)
  (make-racket (racket-x r) (racket-y r) (racket-vx r) (racket-vy r) false 0 0))

;; TESTS:
(begin-for-test
  (check-equal?
   (racket-after-button-up (make-racket 57 49 4 6 true 65 60) 65 60)
   (make-racket 57 49 4 6 false 0 0)
   "racket becomes unselected")
  (check-equal?
   (racket-after-button-up (make-racket 57 49 4 6 false 0 0) 87 80)
   (make-racket 57 49 4 6 false 0 0)
   "racket is not selected, so no change"))


;; racket-after-drag : Racket Integer Integer -> Racket
;; GIVEN: a racket, the x and y coordinates of a mouse
;; WHERE: the racket is in the rally state
;; RETURNS: the racket as it should be after the drag mouse event

;; EXAMPLES:
;; (racket-after-drag (make-racket 57 49 4 6 true 65 60) 65 60) =>
;;                    (make-racket 65 60 4 6 true 65 60)
;; (racket-after-drag (make-racket 57 49 4 6 false 0 0) 87 80) =>
;;                    (make-racket 57 49 4 6 false 0 0)

;; DESIGN-STRATEGY: Use constructor template for Racket on r
(define (racket-after-drag r mx my)
  (if (racket-selected? r)
      (make-racket (+ (racket-x r) (- mx (racket-mx r)))
                   (+ (racket-y r) (- my (racket-my r)))
                   (racket-vx r) (racket-vy r) true mx my) r))

;; TESTS:
(begin-for-test
  (check-equal?
   (racket-after-drag (make-racket 57 83 4 6 false 0 0) 65 60)
   (make-racket 57 83 4 6 false 0 0)
   "racket is not selected, cannot be dragged")
  
  (check-equal?
   (racket-after-drag (make-racket 156 345 7 8 true 176 355) 180 350)
   (make-racket 160 340 7 8 true 180 350)
   "racket is not selected, cannot be dragged"))


;; point-inside-racket? : Racket Integer Integer -> Boolean
;; GIVEN: a racket, x and y position of mouse
;; RETURNS: true iff the position of mouse is no more than 25 pixels
;;          away from th racket's position

;; EXAMPLES:
;; (point-inside-racket? (make-racket 156 345 7 8 false 0 0) 176 355) => true
;; (point-inside-racket? (make-racket 156 345 7 8 false 0 0) 200 455) => false

;; DESIGN-STRATEGY: Transcribe formula
(define (point-inside-racket? r mx my)
  (>= (sqr 25) (+ (sqr (- mx (racket-x r))) (sqr (- my (racket-y r))))))

;; TESTS:
(begin-for-test
  (check-equal?
   (point-inside-racket? (make-racket 156 345 7 8 false 0 0) 176 355) true
   "point is less than 25 pixels away, should return true")
  (check-equal?
   (point-inside-racket? (make-racket 156 345 7 8 false 0 0 ) 200 455) false
   "point is more than 25 pixels away, should return false"))



;; change-racket-x-velocity : Racket Integer -> Racket
;; GIVEN: a racket and an integer n
;; WHERE: the racket is in the rally state
;; RETURNS: same racket as the given racket except that its velocity in
;;          x direction increased or decreased by n.

;; EXAMPLES:
;; (change-racket-x-velocity (make-racket 330 384 5 7 false 0 0) 1) =>
;;                           (make-racket 330 384 6 7 false 0 0)
;; (change-racket-x-velocity (make-racket 330 384 -4 6 false 0 0) -1) =>
;;                           (make-racket 330 384 -5 6 false 0 0)

;; DESIGN-STRATEGY: Use constructor template for Racket on r
(define (change-racket-x-velocity r n)
  (make-racket (racket-x r) (racket-y r) (+ (racket-vx r) n) (racket-vy r)
               (racket-selected? r) (racket-mx r) (racket-my r)))

;; TESTS:
(begin-for-test
  (check-equal?
   (change-racket-x-velocity (make-racket 330 384 5 7 false 0 0) 1)
   (make-racket 330 384 6 7 false 0 0)
   "velocity increased by 1")
  (check-equal?
   (change-racket-x-velocity (make-racket 330 384 -4 6 false 0 0) -1)
   (make-racket 330 384 -5 6 false 0 0)
   "velocity decreased by 1"))


;; change-racket-y-velocity : Racket Integer -> Racket
;; GIVEN: a racket and a integer n
;; WHERE: the racket is in the rally state
;; RETURNS: same racket as the given racket except that its velocity in
;;          y direction increased or decreased by n.

;; EXAMPLES:
;; (change-racket-y-velocity (make-racket 330 384 5 7 false 0 0) 1) =>
;;                           (make-racket 330 384 5 7 false 0 0)

;; (change-racket-y-velocity (make-racket 330 384 -4 6 false 0 0) -1) =>
;;                           (make-racket 330 384 -4 5 false 0 0)

;; DESIGN-STRATEGY: Use constructor template for Racket on r
(define (change-racket-y-velocity r n)
  (make-racket (racket-x r) (racket-y r) (racket-vx r) (+ (racket-vy r) n)
               (racket-selected? r) (racket-mx r) (racket-my r)))

;; TESTS:
(begin-for-test
  (check-equal?
   (change-racket-y-velocity (make-racket 330 384 5 7 false 0 0) 1)
   (make-racket 330 384 5 8 false 0 0)
   "increase velocity by 1")
  (check-equal?
   (change-racket-y-velocity (make-racket 330 384 -4 6 false 0 0) -1)
   (make-racket 330 384 -4 5 false 0 0)
   "deacrease velocity by 1"))



;; would-ball-racket-collide? : Ball Racket -> Boolean
;; GIVEN: a racket and a ball in rally state
;; RETURNS: true if and only if path of the ball during the tick intersects
;;          the 47-pixel line segment that represents the racket's position
;;          at the end of the tick

;; EXAMPLES:
;;(would-ball-racket-collide? (make-ball 318 165 -3 9)
;;                            (make-racket 317 172 3 -3 false 0 0)) => true

;; (would-ball-racket-collide? (make-ball 140 140 -3 10)
;;                             (make-racket 172 143 -3 -3 false 0 0)) => false

;; DESIGN-STRATEGY: Combine simpler functions
(define (would-ball-racket-collide? b r)
  (and
   (not (and (= (ball-y b) (racket-y r))
             (<= (- (racket-x r) 47/2) (ball-x b) (+ (racket-x r) 47/2))))
   (or (= 0 (ball-vy b)) (> (ball-vy b) 0))
   (ball-racket-intersect? (ball-x b) (ball-y b)
                           (ball-x (new-ball b))
                           (ball-y (new-ball b))
                           (- (+ (racket-x r) (racket-vx r)) (/ 47 2))
                           (+ (racket-y r) (racket-vy r))
                           (+ (+ (racket-x r) (racket-vx r)) (/ 47 2))
                           (+ (racket-y r) (racket-vy r)))))

;; TESTS:
(begin-for-test
  (check-equal?
   (would-ball-racket-collide? (make-ball 318 165 -3 9)
                               (make-racket 317 172 3 -3 false 0 0))
   true "ball and racket should collide")

  (check-equal?
   (would-ball-racket-collide? (make-ball 192 137 3 5)
                               (make-racket 189 143 3 -3 false 0 0))
   true "ball and racket should collide")

  (check-equal?
   (would-ball-racket-collide? (make-ball 140 140 -3 10)
                               (make-racket 172 143 -3 -3 false 0 0))
   false "ball and racket should not collide")

  (check-equal?
   (would-ball-racket-collide? (make-ball 149 90 -3 9)
                               (make-racket 152 86 -3 -5 false 0 0))
   false "ball and racket should not collide"))



;; new-ball : Ball -> Ball
;; GIVEN: a ball
;; RETURNS: a ball that should follow the given ball the next tick

;; EXAMPLES:
;; (new-ball (make-ball 3 45 -5 9)) => (make-ball 2 54 5 9)
;; (new-ball (make-ball 420 420 10 10)) => (make-ball 420 430 -10 10)

;; DESIGN STRATEGY: Cases on different collision conditions
(define (new-ball b)
  (cond
    [(< (+ (ball-x b) (ball-vx b)) 0) (ball-after-left-wall-collision b)]

    [(> (+ (ball-x b) (ball-vx b)) COURT-WIDTH)
     (ball-after-right-wall-collision b)]
    
    [(< (+ (ball-y b) (ball-vy b)) 0) (ball-after-top-wall-collision b)]

    [else (make-ball (+ (ball-x b) (ball-vx b)) (+ (ball-y b) (ball-vy b))
                     (ball-vx b) (ball-vy b))]))

;; TESTS:
(begin-for-test
  (check-equal?
   (new-ball (make-ball 3 45 -5 9)) (make-ball 2 54 5 9)
   "if ball collide with left wall its new x-pos is inside court")

  (check-equal?
   (new-ball (make-ball 420 420 10 10)) (make-ball 420 430 -10 10)
   "if ball collide with right wall its new x-pos is inside court")

  (check-equal?
   (new-ball (make-ball 20 5 10 -10)) (make-ball 30 5 10 10)
   "if ball collide with top wall its new y-pos is inside court")

  (check-equal?
   (new-ball (make-ball 200 50 10 -10)) (make-ball 210 40 10 -10)
   "if no collision, velocity gets added"))



;; ball-racket-intersect? : Integer Integer Integer Integer
;;                          Integer Integer Integer Integer -> Boolean
;; GIVEN: x and y coordinates of current and tentative position ball,
;;        and x and y coordinates of extreme ends of tentative position
;;        of racket.
;; WHERE: tentative position is  obtained by adding the components of
;;        ball/racket previous velocity to the corresponding components of
;;        ball/racket previous position
;; RETURNS: true if and only if the line segment joining ball's path
;;          and racket intersect

;; EXAMPLES:
;; (ball-racket-intersect? 318 165 315 174 (- 320 47/2) 169 (+ 320 47/2) 169)
;;  => true
;; (ball-racket-intersect? 192 137 195 142 (- 192 47/2) 140 (+ 192 47/2) 140)
;;  => true
;; (ball-racket-intersect? 140 140 137 150 (- 169 47/2) 140 (+ 169 47/2) 140)
;;  => false

;; DESIGN-STRATEGY: Transcribe formula
(define (ball-racket-intersect? bx1 by1 bx2 by2 rx1 ry1 rx2 ry2)
  (and (not (= 0 (find-det bx1 by1 bx2 by2 rx1 ry1 rx2 ry2)))
       (<= rx1 (find-x bx1 by1 bx2 by2 rx1 ry1 rx2 ry2) rx2)
       (= ry1 (find-y bx1 by1 bx2 by2 rx1 ry1 rx2 ry2))
       (<= by1 ry1 by2)))

;; TESTS:
(begin-for-test
  (check-equal?
   (ball-racket-intersect? 318 165 315 174 (- 320 47/2) 169 (+ 320 47/2) 169)
   true "ball and racket should intersect")

  (check-equal?
   (ball-racket-intersect? 192 137 195 142 (- 192 47/2) 140 (+ 192 47/2) 140)
   true "ball and racket should intersect")

  (check-equal?
   (ball-racket-intersect? 140 140 137 150 (- 169 47/2) 140 (+ 169 47/2) 140)
   false "ball and racket should intersect")

  (check-equal?
   (ball-racket-intersect? 149 90 147 99 (- 149 47/2) 81 (+ 149 47/2) 81) false
   "ball and racket should intersect"))



;; find-a-or-b : Integer -> Integer
;; GIVEN: x/y coordinates of line joining current and tentative position of
;;        ball or extereme coordinates of tentative position of racket
;; RETURNS: the difference between the coordinates

;; EXAMPLES:
;; (find-a-or-b 150 157) => -7
;; (find-a-or-b 160 157) => 3

;; DESIGN STRATEGY: Transcribe formula
(define (find-a-or-b a b)
  (- a b))

;; TESTS:
(begin-for-test
  (check-equal?
   (find-a-or-b 150 157) -7)
  (check-equal?
   (find-a-or-b 160 157) 3))


;; find-c : Integer Integer Integer Integer Integer -> Integer
;; GIVEN: x and y coordinates of line joining current and tentative position of
;;        ball or extereme coordinates of tentative position of racket
;; RETURNS: the constant value 'C' of the line of form Ax + By = C made by
;;          joining the current and tentative position of ball or the line
;;          which represents a racket

;; EXAMPLES:
;; (find-c 149 90 147 99) => 1521
;; (find-c (- 169 47/2) 140 (+ 169 47/2) 140) => 0

;; DESIGN STRATEGY: Transcribe formula
(define (find-c x1 x2 y1 y2)
  (+ (* (find-a-or-b y2 y1) x1) (* (find-a-or-b x1 x2) y1)))

;; TESTS:
(begin-for-test
  (check-equal?
   (find-c 149 90 147 99) 1521)
  (check-equal?
   (find-c (- 169 47/2) 140 (+ 169 47/2) 140) -6580))


;; find-det : PosReal PosReal PosReal PosReal
;;            PosReal PosReal PosReal PosReal -> PosReal
;; GIVEN: x and y coordinates of current and tentative position ball, and
;;        x and y coordinates of extreme ends of tentative position of racket.
;; RETURNS: the 'determine' of line segments formed by joining given points

;; EXAMPLES:
;; (find-det 318 165 315 174 (- 320 47/2) 169 (+ 320 47/2) 169) => -423
;; (find-det 140 140 137 150 (- 169 47/2) 140 (+ 169 47/2) 140) => -470

;; DESIGN STRATEGY: Transcribe formula
(define (find-det bx1 by1 bx2 by2 rx1 ry1 rx2 ry2)
  (- (* (find-a-or-b by2 by1) (find-a-or-b rx1 rx2))
     (* (find-a-or-b ry2 ry1) (find-a-or-b bx1 bx2))))

;; TESTS:
(begin-for-test
  (check-equal?
   (find-det 318 165 315 174 (- 320 47/2) 169 (+ 320 47/2) 169) -423
   "lines intersect, so determine should not be 0")
  (check-equal?
   (find-det 140 140 137 150 (- 169 47/2) 140 (+ 169 47/2) 140) -470
   "lines do not intersect"))


;; find-x : PosReal PosReal PosReal PosReal
;;          PosReal PosReal PosReal PosReal -> PosReal
;; GIVEN: x and y coordinates of current and tentative position ball, and
;;        x and y coordinates of extreme ends of tentative position of racket
;; RETURNS: x-coordinate of point of intersection of given line segments

;; EXAMPLES:
;; find-x 318 165 315 174 (- 320 47/2) 169 (+ 320 47/2) 169) => 950/3
;; find-x  140 140 137 150 (- 169 47/2) 140 (+ 169 47/2) 140 => 140

;; DESIGN STRATEGY: Transcribe formula
(define (find-x bx1 by1 bx2 by2 rx1 ry1 rx2 ry2)
  (/ (- (* (find-a-or-b rx1 rx2) (find-c bx1 bx2 by1 by2))
        (* (find-a-or-b bx1 bx2) (find-c rx1 rx2 ry1 ry2)))
     (find-det bx1 by1 bx2 by2 rx1 ry1 rx2 ry2)))

;; TESTS:
(begin-for-test
  (check-equal?
   (find-x 318 165 315 174 (- 320 47/2) 169 (+ 320 47/2) 169) 950/3)
  (check-equal?
   (find-x  140 140 137 150 (- 169 47/2) 140 (+ 169 47/2) 140) 140))


;; find-y : PosReal PosReal PosReal PosReal
;;          PosReal PosReal PosReal PosReal -> PosReal
;; GIVEN: x and y coordinates of current and tentative position ball, and
;;        x and y coordinates of extreme ends of tentative position of racket
;; RETURNS: y-coordinate of point of intersection of given line segments

;; EXAMPLES:
;; find-y 318 165 315 174 (- 320 47/2) 169 (+ 320 47/2) 169 => 169
;; find-y  140 140 137 150 (- 169 47/2) 140 (+ 169 47/2) 140 => 140

;; DESIGN STRATEGY: Transcribe formula
(define (find-y bx1 by1 bx2 by2 rx1 ry1 rx2 ry2)
  (/ (- (* (find-a-or-b by2 by1) (find-c rx1 rx2 ry1 ry2))
        (* (find-a-or-b ry2 ry1) (find-c bx1 bx2 by1 by2)))
     (find-det bx1 by1 bx2 by2 rx1 ry1 rx2 ry2)))

;; TESTS:
(begin-for-test
  (check-equal?
   (find-y 318 165 315 174 (- 320 47/2) 169 (+ 320 47/2) 169) 169)
  (check-equal?
   (find-y  140 140 137 150 (- 169 47/2) 140 (+ 169 47/2) 140) 140))
   

;; ball-collide-with-left-wall? : Ball Racket -> Boolean
;; GIVEN: a ball and a racket
;; RETURNS: true if and only is the ball does not collide with the racket and
;;          the ball collides with the left wall

;; EXAMPLES:
;; (ball-collide-with-left-wall? (make-ball 318 165 -3 9)
;;                               (make-racket 317 172 3 -3 false 0 0)) => false

;; (ball-collide-with-left-wall? (make-ball 2 4 -4 8)
;;                               (make-racket 228 344 4 6 false 0 0)) => true

;; (ball-collide-with-left-wall? (make-ball 4 8 -8 -9)
;;                               (make-racket 228 344 4 6 false 0 0)) => true

;; DESIGN-STRATEGY: Use observer template for Ball
(define (ball-collide-with-left-wall? b r)
  (if (would-ball-racket-collide? b r) false (< (+ (ball-x b) (ball-vx b)) 0)))

;; TESTS:
(begin-for-test
  (check-equal?
   (ball-collide-with-left-wall? (make-ball 318 165 -3 9)
                                 (make-racket 317 172 3 -3 false 0 0))
   false "ball does not collide")
  
  (check-equal?
   (ball-collide-with-left-wall? (make-ball 2 4 -4 8)
                                 (make-racket 228 344 4 6 false 0 0))
   true "ball collides")
  
  (check-equal?
   (ball-collide-with-left-wall? (make-ball 4 8 -8 -9)
                                 (make-racket 228 344 4 6 false 0 0))
   true "ball collides"))


;; ball-collide-with-right-wall? : Ball Racket -> Boolean
;; GIVEN: a ball and a racket
;; RETURNS: true if and only is the ball does not collide with the racket and
;;          the ball collides with the right wall

;; EXAMPLES:
;; (ball-collide-with-right-wall? (make-ball 420 340 10 6)
;;                                (make-racket 228 344 4 6 false 0 0)) => true
;; (ball-collide-with-right-wall? (make-ball 318 165 -3 9)
;;                                (make-racket 317 172 3 -3 false 0 0)) =>
;;  false

;; DESIGN-STRATEGY: Use observer template for Ball on b
(define (ball-collide-with-right-wall? b r)
  (if (would-ball-racket-collide? b r) false (> (+ (ball-x b) (ball-vx b))
                                                COURT-WIDTH)))

;; TESTS:
(begin-for-test
  (check-equal?
   (ball-collide-with-right-wall? (make-ball 420 340 10 6)
                                  (make-racket 228 344 4 6 false 0 0))
   true "ball collides")
  
  (check-equal?
   (ball-collide-with-right-wall? (make-ball 318 165 -3 9)
                                  (make-racket 317 172 3 -3 false 0 0))
   false "ball does not collide"))


;; ball-collide-with-top-wall? : Ball Racket -> Boolean
;; GIVEN: a ball and racket
;; RETURNS: true if and only is the ball does not collide with the racket and
;;          the ball collides with the top wall

;; EXAMPLES:
;; (ball-collide-with-top-wall? (make-ball 35 3 -5 -8)
;;                              (make-racket 228 344 4 6 false 0 0)) => true
;; (ball-collide-with-top-wall? (make-ball 318 165 -3 9)
;;                              (make-racket 317 172 3 -3 false 0 0)) => false

;; DESIGN-STRATEGY: Use observer template for Ball on b
(define (ball-collide-with-top-wall? b r)
  (if (would-ball-racket-collide? b r) false (< (+ (ball-y b) (ball-vy b)) 0)))

;; TESTS:
(begin-for-test
  (check-equal?
   (ball-collide-with-top-wall? (make-ball 35 3 -5 -8)
                                (make-racket 228 344 4 6 false 0 0))
   true "ball collides")
  
  (check-equal?
   (ball-collide-with-top-wall? (make-ball 318 165 -3 9)
                                (make-racket 317 172 3 -3 false 0 0))
   false "ball does not collide"))



;; ball-collide-with-back-wall? : Ball Racket -> Boolean
;; GIVEN: a ball and a racket
;; RETURNS: true if and only is the ball does not collide with the racket and
;;          the ball collides with the back wall

;; EXAMPLES:
;; (ball-collide-with-back-wall? (make-ball 39 645 -5 8)
;;                               (make-racket 228 344 4 6 false 0 0)) => true
;; (ball-collide-with-back-wall? (make-ball 318 165 -3 9)
;;                               (make-racket 317 172 3 -3 false 0 0)) => false

;; DESIGN-STRATEGY: Use observer template for Ball on b
(define (ball-collide-with-back-wall? b r)
  (if (would-ball-racket-collide? b r) false (> (+ (ball-y b) (ball-vy b))
                                                COURT-HEIGHT)))

;; TESTS:
(begin-for-test
  (check-equal?
   (ball-collide-with-back-wall? (make-ball 39 645 -5 8)
                                 (make-racket 228 344 4 6 false 0 0))
   true "ball collides")
  
  (check-equal?
   (ball-collide-with-back-wall? (make-ball 318 165 -3 9)
                                 (make-racket 317 172 3 -3 false 0 0))
   false "ball does not collide"))



;; racket-collide-with-left-wall? : Racket -> Boolean
;; GIVEN: a racket
;; RETURNS: true if and only is the racket collides with the left wall

;; EXAMPLES:
;; (racket-collide-with-left-wall? (make-racket 30 40 -10 6 false 0 0)) => true
;; (racket-collide-with-left-wall? (make-racket 70 40 6 8 false 0 0)) => false

;; DESIGN-STRATEGY: Use observer template for Racket on r
(define (racket-collide-with-left-wall? r)
  (< (+ (racket-x r) (racket-vx r)) (/ RACKET-WIDTH 2)))

;; TESTS:
(begin-for-test
  (check-equal?
   (racket-collide-with-left-wall? (make-racket 30 40 -10 6 false 0 0)) true
   "racket collides")
  (check-equal?
   (racket-collide-with-left-wall? (make-racket 70 40 6 8 false 0 0)) false
   "racket does not collide"))



;; racket-collide-with-right-wall? : Racket -> Boolean
;; GIVEN: a racket
;; RETURNS: true if and only is the racket collides with the right wall

;; EXAMPLES:
;; (racket-collide-with-right-wall? (make-racket 310 40 10 6 false 0 0)) =>
;;  false
;; (racket-collide-with-right-wall? (make-racket 405 40 6 8 false 0 0)) => true

;; DESIGN-STRATEGY: Use observer template for Racket on r
(define (racket-collide-with-right-wall? r)
  (> (+ (racket-x r) (racket-vx r)) (- COURT-WIDTH (/ RACKET-WIDTH 2))))

;; TESTS:
(begin-for-test
  (check-equal?
   (racket-collide-with-right-wall? (make-racket 310 40 10 6 false 0 0)) false
   "racket does not collides")
  (check-equal?
   (racket-collide-with-right-wall? (make-racket 405 40 6 8 false 0 0)) true
   "racket collides"))



;; racket-collide-with-top-wall? : Racket -> Boolean
;; GIVEN: a racket
;; RETURNS: true if and only is the racket collides with the top wall

;; EXAMPLES:
;; (racket-collide-with-top-wall? (make-racket 410 4 10 -6 false 0 0)) => true
;; (racket-collide-with-top-wall? (make-racket 405 40 6 8 false 0 0)) => false

;; DESIGN-STRATEGY: Use observer template for Racket on r
(define (racket-collide-with-top-wall? r)
  (<= (+ (racket-y r) (racket-vy r)) 0))

;; TESTS:
(begin-for-test
  (check-equal?
   (racket-collide-with-top-wall? (make-racket 410 4 10 -6 false 0 0)) true
   "racket collides")
  (check-equal?
   (racket-collide-with-top-wall? (make-racket 405 40 6 8 false 0 0)) false
   "racket does not collide"))


;; racket-collide-with-back-wall? : Racket -> Boolean
;; GIVEN: a racket
;; RETURNS: true if and only is the racket collides with the back wall

;; EXAMPLES:
;; (racket-collide-with-back-wall? (make-racket 410 640 10 10 false 0 0)) =>
;;  true
;; (racket-collide-with-back-wall? (make-racket 405 40 6 8 false 0 0)) => false

;; DESIGN-STRATEGY: Use observer template for Racket on r
(define (racket-collide-with-back-wall? r)
  (>= (+ (racket-y r) (racket-vy r)) 649))

;; TESTS:
(begin-for-test
  (check-equal?
   (racket-collide-with-back-wall? (make-racket 410 640 10 10 false 0 0)) true
   "racket collides")
  (check-equal?
   (racket-collide-with-back-wall? (make-racket 405 40 6 8 false 0 0)) false
   "racket does not collide"))


;; world-balls : World -> BallList
;; GIVEN: a world
;; RETURNS: a list of the balls that are present in the world (but does not
;; include any balls that have disappeared by colliding with the back wall)

;; EXAMPLES:
;; (world-balls (make-world (list (make-ball 156 245 6 8) (make-ball 320 40 3 4)
;;                                (make-ball 56 45 6 8))
;;                          (make-racket 78 567 5 2 false 0 0) "rally" 0.5 6))
;; (list (make-ball 156 245 6 8) (make-ball 320 40 3 4)
;;                                   (make-ball 56 45 6 8))


;; TESTS:
(begin-for-test
  (check-equal?
   (world-balls (make-world (list (make-ball 156 245 6 8)
                                  (make-ball 320 40 3 4) (make-ball 56 45 6 8))
                            (make-racket 78 567 5 2 false 0 0) "rally" 0.5 6))
   (list (make-ball 156 245 6 8) (make-ball 320 40 3 4)
         (make-ball 56 45 6 8))))



;; world-racket : World -> Racket
;; GIVEN: a world
;; RETURNS: the racket that is present in the world

;; EXAMPLES:
;; (world-racket (make-world (make-ball 156 245 6 8)
;;                           (make-racket 78 567 5 2 false 0 0) "rally" 0.5 6))
;;               (make-racket 78 567 5 2 false 0 0)

;; TESTS:
(begin-for-test
  (check-equal?
   (world-racket (make-world (make-ball 156 245 6 8)
                             (make-racket 78 567 5 2 false 0 0) "rally" 0.5 6))
   (make-racket 78 567 5 2 false 0 0)))


;; ball-x : Ball -> Integer
;; GIVEN: a ball
;; RETURNS: the x coordinate of the ball's position, in graphics coordinates

;; EXAMPLES:
;; (ball-x (make-ball 156 245 6 8)) => 156

;; TESTS:
(begin-for-test
  (check-equal?
   (ball-x (make-ball 156 245 6 8)) 156))


;; ball-y : Ball -> Integer
;; GIVEN: a ball
;; RETURNS: the y coordinate of the ball's position, in graphics coordinates

;; EXAMPLES:
;; (ball-y (make-ball 156 245 6 8)) => 245

;; TESTS:
(begin-for-test
  (check-equal?
   (ball-y (make-ball 156 245 6 8)) 245))


;; racket-x : Racket -> Integer
;; GIVEN: a racket
;; RETURNS: the x coordinate of the racket's position, in graphics coordinates

;; EXAMPLES:
;; (racket-x (make-racket 78 567 5 2 false 0 0)) => 78

;; TESTS:
(begin-for-test
  (check-equal?
   (racket-x (make-racket 78 567 5 2 false 0 0)) 78))


;; racket-y : Racket -> Integer
;; GIVEN: a racket
;; RETURNS: the y coordinate of the racket's position, in graphics coordinates

;; EXAMPLES:
;; (racket-y (make-racket 78 567 5 2 false 0 0)) => 567

;; TESTS:
(begin-for-test
  (check-equal?
   (racket-y (make-racket 78 567 5 2 false 0 0)) 567))


;; ball-vx : Ball -> Integer
;; GIVEN: a ball
;; RETURNS: the vx component of the ball's velocity, in pixels per tick

;; EXAMPLES:
;; (ball-vx (make-ball 156 245 6 8)) => 6

;; TESTS:
(begin-for-test
  (check-equal?
   (ball-vx (make-ball 156 245 6 8)) 6))



;; ball-vy : Ball -> Integer
;; GIVEN: a ball
;; RETURNS: the vy component of the ball's velocity, in pixels per tick

;; EXAMPLES:
;; (ball-vy (make-ball 156 245 6 8)) => 8

;; TESTS:
(begin-for-test
  (check-equal?
   (ball-vy (make-ball 156 245 6 8)) 8))


;; racket-vx : Rcaket -> Integer
;; GIVEN: a ball
;; RETURNS: the vx component of the racket's velocity, in pixels per tick

;; EXAMPLES:
;; (racket-vx (make-racket 78 567 5 2 false 0 0)) => 5

;; TESTS:
(begin-for-test
  (check-equal?
   (racket-vx (make-racket 78 567 5 2 false 0 0)) 5))



;; racket-vy : Rcaket -> Integer
;; GIVEN: a ball
;; RETURNS: the vy component of the racket's velocity, in pixels per tick

;; EXAMPLES:
;; (racket-vy (make-racket 78 567 5 2 false 0 0)) => 2

;; TESTS:
(begin-for-test
  (check-equal?
   (racket-vy (make-racket 78 567 5 2 false 0 0)) 2))


;; racket-selected? : Racket -> Boolean
;; GIVEN: a racket
;; RETURNS: true iff the racket is selected

;; EXAMPLES:
;; (racket-selected? (make-racket 78 567 5 2 false 0 0)) => false
;; (racket-selected? (make-racket 78 567 5 2 true 0 0)) => true

;; TESTS:
(begin-for-test
  (check-equal?
   (racket-selected? (make-racket 78 567 5 2 false 0 0)) false)
  (check-equal?
   (racket-selected? (make-racket 78 567 5 2 true 0 0)) true))
