import mapBehavior
import action
import time

import unboard

def behaviorAction():
	action.leds.SetRightEyeLeds(action.session, "green")
	action.motion.X = 0.5
	action.motion.Y = 0

	action.motion.Walk(action.session)
	time.sleep(3.0)

	action.motion.StopWalk(action.session)

def behaviorTransition():
	return mapBehavior.lookAround