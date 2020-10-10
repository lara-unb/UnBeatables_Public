import mapBehavior
import action
import time

import unboard

def behaviorAction():
	unboard.seeBallTop  = False
	unboard.seeBallBot  = False
	action.motion.X = 0
	action.motion.Y = 0

	action.leds.SetRightEyeLeds(action.session, "cyan")
	# head yaw

	if(not unboard.seeBallTop and not unboard.seeBallBot):
		unboard.countAround += unboard.countAround
		# turn around 90 degrees

def behaviorTransition():
	if(unboard.countAround < 3):
		return mapBehavior.lookAround
	else:
		unboard.countAround = 0
		return mapBehavior.walkRandom