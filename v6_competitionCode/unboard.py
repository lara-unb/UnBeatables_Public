########################
#      Perception      #
########################
is_simulation = True
if is_simulation:
    height = 480.0
    width = 640.0
else:
    height = 240.0
    width = 320.0

seeBallTop = False
seeBallBot = False

ballXBot = -1.0
ballYBot = -1.0

ballXTop = -1.0
ballYTop = -1.0

ballSide = "Left" # Or "Right"


########################
#      Communication   #
########################

# Set this variable for each player
playerNumber = 0 # Order in gameController
teamNumber = 0   # Order in gameController

gameState = 0
penalty = 0