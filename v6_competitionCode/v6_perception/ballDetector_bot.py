import cv2
import time
import numpy as np
import logging
import time
import os

import unboard

# Time for robot ball center buffer
# If the ball is lost, robot will pretend the ball is in the last place seen for 4 seconds
buffer_time = 4.0
t0 = 0.0

params_2_alfrednator = {}
debug_image_array = []


def main(image_array):
    global t0
    del debug_image_array[:]  #clear debug_imaage_array

    botCamera = image_array[0]
    debug_image_array.append(botCamera)
    #####################
    #     Bot Camera    #
    #####################

    debug_image_array.append(cv2.cvtColor(botCamera, cv2.COLOR_BGR2GRAY))

    # Transform botCamera image in grayscale for the cascade search function
    gray = cv2.cvtColor(botCamera, cv2.COLOR_BGR2GRAY)

    debug_image_array.append(gray)

    #try to figure out code location from eviroment varaibles
    try:
        code_location = os.environ["NAO_CODE_LOCATION"]
    except KeyError as error:
        print(error)
        raise KeyError(
            "NAO_CODE_LOCATION enviroment variable not set. Please check documentation."
        )
    # Load the training data
    ball_cascade = cv2.CascadeClassifier(code_location +
                                         "v6_perception/cascade.xml")

    if (ball_cascade.empty()):
        raise IOError("ball_cascade empty. Maybe file not found?")
    # Detect ball in image
    ball = ball_cascade.detectMultiScale(gray, 1.3, 5)

    # Define ball center (normalized)
    # top left corner of rectangle (x,y)
    # width of rectangle (w)
    # height of rectangle (h)
    for (x, y, w, h) in ball:
        t0 = time.time()

        unboard.seeBallBot = True
        unboard.ballXBot = (x + w / 2) / unboard.width
        unboard.ballYBot = (y + h / 2) / unboard.height

        break  # Robot will only consider ball the first ball in ball vector (Need better solution)

    # If there is no ball, loses ball after buffer time
    if (len(ball) == 0):
        if (time.time() - t0 > buffer_time):
            unboard.seeBallBot = False
            if (unboard.ballXBot > 0.5 and unboard.ballXBot <= 1.0):
                unboard.ballSide = "Right"
            elif (unboard.ballXBot >= 0 and unboard.ballXBot <= 0.5):
                unboard.ballSide = "Left"
            unboard.ballXBot = -1
            unboard.ballYBot = -1
