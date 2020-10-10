#!/usr/bin/env python


import vision_definitions
import numpy as np
import cv2
import time
import random
import os
import logging

import qi
import redBallDetector
import ballDetector_bot
import ballDetector_top
import hsvMask
import rgb_2_chroma
import exemplo_trainee

import unboard

session = qi.Session()

alfrednatorFunctions = [
    redBallDetector, hsvMask, rgb_2_chroma, exemplo_trainee
]

def alImage2npImage(image):

            imgWidth = image[0]
            imgHeight = image[1]
            imgChannels = image[2]
            npImg = np.reshape(image[6], (imgHeight, imgWidth, imgChannels))
            return npImg

def main(is_simulation):
    if(is_simulation):

        import vrep
        
        def initialize_vrep_cameras(top_camera_name, bottom_camera_name, clientID):
            #Top camera
            #Get the handle of the top vision sensor
            res1, top_camera_handle = vrep.simxGetObjectHandle(
                clientID, top_camera_name, vrep.simx_opmode_oneshot_wait)
            if (res1 != 0):
                raise RuntimeError("Could not get top camera handle. res = " +
                                str(res1))
            #Get the handle of the bottom vision sensor
            res1, bottom_camera_handle = vrep.simxGetObjectHandle(
                clientID, bottom_camera_name, vrep.simx_opmode_oneshot_wait)
            if (res1 != 0):
                raise RuntimeError("Could not get bottom camera handle. res = " +
                                str(res1))

            #Initialize top camera stream
            _, _, _ = vrep.simxGetVisionSensorImage(clientID, top_camera_handle, 0,
                                                    vrep.simx_opmode_streaming)

            #Initialize bottom camera stream
            _, _, _ = vrep.simxGetVisionSensorImage(clientID, bottom_camera_handle, 0,
                                                    vrep.simx_opmode_streaming)
            time.sleep(0.5)
            return top_camera_handle, bottom_camera_handle

        vrep.simxFinish(-1)
        clientID = vrep.simxStart('127.0.0.1', 19997, True, True, 5000, 5)
        if(clientID == -1):
            raise RuntimeError("Could not connect to vrep")
        # initialize a capture
        top_camera_name = "NAO_vision1"
        bottom_camera_name = "NAO_vision2"

        top_camera_handle, bottom_camera_handle = initialize_vrep_cameras(
            top_camera_name, bottom_camera_name, clientID)
        # Get ALImages of top camera and bottom camera
        while (True):

            top_res, top_resolution, top_image = vrep.simxGetVisionSensorImage(
                clientID, top_camera_handle, 0, vrep.simx_opmode_buffer)
            top_image = np.array(top_image, dtype=np.uint8)
            top_image.resize([top_resolution[1], top_resolution[0], 3])
            top_image = np.flip(top_image, axis=0)

            bottom_res, bottom_resolution, bottom_image = vrep.simxGetVisionSensorImage(
                clientID, bottom_camera_handle, 0, vrep.simx_opmode_buffer)
            bottom_image = np.array(bottom_image, dtype=np.uint8)
            bottom_image.resize([bottom_resolution[1], bottom_resolution[0], 3])
            bottom_image = np.flip(bottom_image, axis=0)

            if (unboard.seeBallBot):
                ballDetector_bot.main([bottom_image])
            elif (unboard.seeBallTop):
                ballDetector_top.main([top_image])
            else:
                ballDetector_bot.main([bottom_image])
                ballDetector_top.main([top_image])
    else:
        # Get the service ALVideoDevice.
        video_service = session.service("ALVideoDevice")

        # Register a Generic Video Module
        resolution = vision_definitions.kQVGA
        colorSpace = vision_definitions.kBGRColorSpace
        fps = 5

        topCamera = video_service.subscribeCamera(
            "python_top" + str(random.randint(1, 10)), 0, resolution, colorSpace,
            fps)
        botCamera = video_service.subscribeCamera(
            "python_bot" + str(random.randint(1, 10)), 1, resolution, colorSpace,
            fps)

        # Get ALImages of top camera and bottom camera
        while (True):

            topNAOImage = video_service.getImageRemote(topCamera)
            if (topNAOImage == None):
                logging.error("No topImage")

            botNAOImage = video_service.getImageRemote(botCamera)
            if (botNAOImage == None):
                logging.error("No botImage")


            topImage = alImage2npImage(topNAOImage)
            botImage = alImage2npImage(botNAOImage)

            if(unboard.seeBallBot):
                ballDetector_bot.main([botImage])
            elif(unboard.seeBallTop):
                ballDetector_top.main([topImage])
            else:
                ballDetector_bot.main([botImage])
                ballDetector_top.main([topImage])


        video_service.unsubscribe(topCamera)
        video_service.unsubscribe(botCamera)


        