#!/usr/bin/env python

import mapBehavior
import action
import unboard
import logging


def xy_movements_clamper(number):
    """Function to clamp number between -1.0 and 1.0. Use with arguments in moveToward.

    Args:
        number (float): number to clamp

    Returns:
        float: number clamped between -1.0 and 1.0.
    """    
    return max(min(number, 1.0), -1.0)

## 	\brief Closed loop for walking ball when ball is seen in bot camera
def behaviorAction():
    # State led
    action.leds.SetRightEyeLeds(action.session, "blue")

    # Adjust head
    action.movements.jointName = "HeadYaw"
    action.movements.Angle = 0.0
    action.movements.MaxSpeed = 0.1
    action.movements.HeadMove(action.session)

    action.movements.jointName = "HeadPitch"
    action.movements.Angle = 29.0
    action.movements.MaxSpeed = 0.1
    action.movements.HeadMove(action.session)

    # If ball is seen
    if(unboard.seeBallBot == True): 
        
        ballX = unboard.ballXBot
        ballY = unboard.ballYBot

        # Walk ball in closed loop. 
        # Here we set the walk parametes according with ball position return in unboard.
        if(ballX < 0.4 and ballX > 0):
            action.movements.Y = xy_movements_clamper(float(2 * (0.5 - ballX)))
        elif(ballX > 0.6):
            action.movements.Y = xy_movements_clamper(float(2 * (0.5 - ballX)))
        else:
            action.movements.Y = float(0.0)

        if(ballY < 0.60 and ballY != -1):
            action.movements.X = xy_movements_clamper(float(1.8 * (0.6 - ballY)))
            if(action.movements.X < 0.2):
                action.movements.X = float(0.2)
        else:
            action.movements.X = float(0.0)

        print(action.movements.X, action.movements.Y, "movements")
        action.movements.Walk(action.session)

    # If ball is lost
    else:
        action.movements.StopWalk(action.session)

## 	\brief  Transitions to walkBall_bot if ball is seen in bot camera.
#           Transitions to walkBall_top if ball is seen in top camera.
    
def behaviorTransition():

    if(unboard.ballYBot > 0.6 and unboard.ballXBot > 0.55 and unboard.ballXBot < 0.75):
        logging.info("kickBehavior")
        return mapBehavior.kicking
    elif(unboard.seeBallBot):
        return mapBehavior.walkBall_bot
    elif(unboard.seeBallTop):
        return mapBehavior.walkBall_top
    
    logging.info("walkball_bot")
    return mapBehavior.walkBall_bot
    
