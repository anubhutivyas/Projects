SquashPractice is the simulation of a squash player practicing without an opponent, in functional reactive programming Racket. The simulation is a universe program that displays the positions and motions of multiple squash balls and the player's racket moving within a 2D rectangular court.

HOW TO RUN:

Call the function simulation with the speed by entering (simulation 1/10), where 1/10 depicts the speed of the ball. It is the number of pixels the ball moves in one second.

DETAILS:

The simulation is first in ready-to-serve state, with ball and racket at initial positions. When space bar is pressed, it goes into rally state, with ball and racket moving according to thier respective velocity. If space bar is pressed in rally state, simulation pauses for 3 seconds.

When in rally state, the velocity of racket and ball changes accordingly on different key events or on collision with the court walls.

When the simulation is in rally state, the racket becomes selectable and draggable and a blue circle appears to show the position of mouse.

When the simulation is in rally state, pressing 'b' key creates a new ball with position components (330,384) and velocity components (3,-9).

If a ball collides with the back wall, it disappears from the simulation. If its disappearance leaves no more balls within the simulation, the rally state ends as though the space bar had been pressed.