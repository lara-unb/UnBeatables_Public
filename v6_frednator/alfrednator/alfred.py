# -*- coding: utf-8 -*-
import base64
import re
import sys
import os

from flask import Flask
from flask import render_template
from flask_socketio import SocketIO

import numpy as np
import cv2


import qi
import vision_definitions

# Adding competition code modules to library path
sys.path.append(os.path.join(sys.path[0],
                             '../../v6_competitionCode/v6_action'))
sys.path.append(
    os.path.join(sys.path[0], '../../v6_competitionCode/v6_behavior'))
sys.path.append(
    os.path.join(sys.path[0], '../../v6_competitionCode/v6_perception'))
sys.path.append(
    os.path.join(sys.path[0], '../../v6_competitionCode/v6_communication'))
sys.path.append(os.path.join(sys.path[0], '../../v6_competitionCode'))

# Importing competition code modules
import perception

PERCEPTION_FUNCTIONS = perception.alfrednatorFunctions  #array de funçoes do alfred
source_dict = {
}  #dict to be populated with various sources, {'path' : capture_obj}
image_dict = {}  #to be populated with various images

recording = None


## \details Class that encapsulates a new robot source. Used with NAO v6.
#  \brief  Class that encapsulates a new robot source.
class RobotSource(object):

    ## \details Function to start capturing both topImage and botImage from the robot. Should be called only once.
    #  \brief Function to start capturing both topImage and botImage from the robot.
    #  \param robot_ip String: robot address in the form of "xxx.xxx.xxx.xxx", such as "192.168.0.40".
    #  \param robot_port String: robot port in the form of "xxxxx", such as "9559".
    # \return Returns, in order, the qi session, the ALVideoDevice service, the top image client and the bottom image client.
    def __init__(self, robot_ip, robot_port):
        robot_ip = robot_ip.replace("robot-", "")
        self.robot_ip = robot_ip
        self.robot_port = robot_port
        self.isSubscribed = False

        self.session = qi.Session()
        self.session.connect("tcp://" + robot_ip + ":" + str(robot_port))

        # initialize a capture
        self.video_service = self.session.service("ALVideoDevice")
        self.resolution = vision_definitions.kVGA
        self.color_space = vision_definitions.kRGBColorSpace
        self.fps = 30

        if not "robot-" + self.robot_ip in source_dict:
            #new capture
            source_dict["robot-" + self.robot_ip] = self
            self.subscribe_cameras()
        #TODO: setar os paremetros de exposicao, balanco de branco, brightness etc

        self.top_image = self.get_new_top_image
        self.bottom_image = self.get_new_bottom_image

    #add new image source (camera)
    def subscribe_cameras(self):
        current_subscribers = self.video_service.getSubscribers()
        for subscriber in current_subscribers:
            if (subscriber.startswith(self.robot_ip + "_top_client") or
                    subscriber.startswith(self.robot_ip + "_bottom_client")):
                self.video_service.unsubscribe(subscriber)
        self.top_img_client = self.video_service.subscribeCamera(
            self.robot_ip + "_top_client", 0, self.resolution,
            self.color_space, self.fps)
        self.bottom_img_client = self.video_service.subscribeCamera(
            self.robot_ip + "_bottom_client", 1, self.resolution,
            self.color_space, self.fps)
        self.isSubscribed = True

    #remove a image source
    def unsubscribe_cameras(self):
        self.video_service.unsubscribe(self.top_img_client)
        self.video_service.unsubscribe(self.bottom_img_client)
        self.isSubscribed = False

    #get a new image from top camera
    def get_new_top_image(self):
        al_image = self.video_service.getImageRemote(self.top_img_client)
        self.top_image = al_image_2_cv_mat(al_image)
        return self.top_image

    #get a new image from bottom camera
    def get_new_bottom_image(self):
        al_image = self.video_service.getImageRemote(self.bottom_img_client)
        self.bottom_image = al_image_2_cv_mat(al_image)
        return self.bottom_image


## \details Class that encapsulates a new source from opencv. Used with webcams or video files.
#  \brief  Class that encapsulates a new source from opencv.
class Source_Cap(object):
    """Class that encapsulates a new source from opencv. Used with webcams or video files."""

    ## \brief Creates a Source_Cap object
    # \param path String: path of the capture. "0" or "/home/paulo/videos/test.mp4".
    def __init__(self, path):
        self.cap = cv2.VideoCapture(path)
        self.key = path
        self.type = self.__parse_type_from_path(path)
        self.frame = None

        if not self.key in source_dict:
            #new capture
            source_dict[path] = self
            self.open_cap()

    ## \brief Verify file extension
    # \param path String: path of the capture. "0" or "/home/paulo/videos/test.mp4".
    def __parse_type_from_path(self, path):
        try:
            int(path)
        except ValueError:
            if re.search(r".*\.((avi)|(mp4)|(mkv))$", path, re.IGNORECASE):
                return "file"
            return "not webcam"
        return "webcam"

    ## \brief Function to open a capture based on the type of path.
    def open_cap(self):

        if self.type == "webcam":
            self.cap.open(int(self.key))
        if self.type == "file":
            self.cap.open(self.key)

    ## \brief Method called to read a new frame from the cap.
    # \exception RuntimeError raised when the cap couldn't be open. Message = "cap closed".
    # \exception RuntimeError raised when the frame couldn't be read. Message = "cap read could not find a ret".
    # \return Returns the frame read.
    def update_image(self):
        if not self.cap.isOpened():
            raise RuntimeError("cap closed")

        ret, frame = self.cap.read()

        if not ret:
            if (self.type == "file"):
                #captura de arquivo chegou no fim
                self.cap.set(cv2.CAP_PROP_POS_AVI_RATIO, 0)
                ret, frame = self.cap.read()
            else:
                #maybe ValueError ?
                raise RuntimeError("cap read could not find a ret")
        self.frame = frame
        return frame


## \details Class that encapsulates a new image source. #It's not in use. Maybe will be deleted 
#  \brief  Class that encapsulates a new image source.
class SourceImage(object):
    def __init__(self, key):
        self.image = {}
        self.key = key
        self.active = False

    def toggle_active(self):
        self.active = not self.active

    def update_image(self, img):
        self.image = img
        self.active = True


app = Flask(__name__)
app.config['TEMPLATES_AUTO_RELOAD'] = True
# app.debug = True
SOCKETIO = SocketIO(app)


#event fired within the display loop
@SOCKETIO.on("request-cap-img")
##  \details Funtion to handle the "request-cap-img" event from socketio. Should be fired everytime the frontend needs a new image.
#   \brief Function to handle "request-cap-img" event from socketIO.
#   \param path String: String containning the path selected by the text input on the top of the page.
#   \param function_status Boolean/String:  Either false if there is no selected function or a string with the funtion name.
def handle_need_img(path, function_status, selected_index):
    try:
        img_byte_string, debug_image_size = generate_cap_image(
            path, function_status, selected_index)
    except RuntimeError as error:
        return "error " + error.message, path
    except ValueError as error:
        if(error.message=="too many values to unpack"):
            return "cap closed", path, 0
        else:
            raise error
    return img_byte_string, path, debug_image_size  #TODO: path may not be needed to be returned


#event fired within the display loop
@SOCKETIO.on("request-robot-img")
##  \details Funtion to handle the "request-robot-img" event from socketio. Should be fired everytime the frontend needs a new image.
#   \brief Function to handle "rrequest-robot-img" event from socketIO.
#   \param path String: String containning the path selected by the text input on the top of the page.
#   \param function_status Boolean/String:  Either false if there is no selected function or a string with the funtion name.
def handle_request_robot_img(path, function_status, selected_index):
    try:
        top_img_byte_string, bottom_img_byte_string, debug_image_size = generate_robot_images(
            path, function_status, selected_index)
    except RuntimeError as error:
        return "error " + error.message, path
    return top_img_byte_string, bottom_img_byte_string, path, debug_image_size


#event fired when the user requests a new cap source.
@SOCKETIO.on("start-video")
## \details Function to handle the request of a new source. It renders the templates for the tabs and frames for the source and returns them.
# \brief Function to handle the request of a new source.
# \param path String: String containning the path selected by the text input on the top of the page.
# \param source_number String: The number that should be this new source.
def handle_start_video(path, source_number):
    print("start-video")
    if not path in source_dict:
        Source_Cap(path)
    else:
        source_dict[path].open_cap()

    cap_tab = render_template("cap_frame_tab.html",
                              source_number=source_number,
                              path=path)
    cap_frame = render_template("cap_frame.html",
                                source_number=source_number,
                                path=path)
    return cap_tab, cap_frame


@SOCKETIO.on("start-robot-video")
## \details Function to handle the request of a new robot source. It renders the templates for the tabs and frames for the source and returns them.
# \brief Function to handle the request of a new robot source.
# \param robot_path String: String containning the path selected by the text input on the top of the page.
# \param source_number String: The number that should be this new source.
# \param port int: Port number that naoqi is running on. Defaults to 9559.
def handle_start_robot_video(robot_path, source_number, port=9559):
    source_path = robot_path
    if not source_path in source_dict:
        RobotSource(robot_path, port)
    else:
        if (not source_dict[source_path].isSubscribed):
            source_dict[source_path].subscribe_cameras()

    top_image_path = robot_path + "-top-image"

    #generate top image source and tab
    top_image_tab = render_template("robot_frame_tab.html",
                                    source_number=source_number,
                                    path=top_image_path)
    top_image_frame = render_template("robot_frame.html",
                                      source_number=source_number,
                                      path=top_image_path)

    bottom_image_path = robot_path + "-bottom-image"
    #generate bottom image source and tab
    bottom_image_tab = render_template("robot_frame_tab.html",
                                       source_number=int(source_number) + 1,
                                       path=bottom_image_path)
    bottom_image_frame = render_template("robot_frame.html",
                                         source_number=int(source_number) + 1,
                                         path=bottom_image_path)

    return top_image_tab, top_image_frame, bottom_image_tab, bottom_image_frame


@SOCKETIO.on("split-canvas")
## \details Function to handle the request of a multi-view new source. It renders the templates for the tabs and frames for the sources and returns them.
# \brief Function to handle the request of a multi-view source.
# \param source_number String: The number that should be this new source.
def handle_split_canvas(source_number):
    path = "split-canvas-" + source_number
    cap_tab = render_template("cap_frame_tab.html",
                              source_number=source_number,
                              path=path)
    cap_frame = render_template("cap_frame.html",
                                source_number=source_number,
                                path=path)
    return cap_tab, cap_frame


#Event fired when the user wants to close a source
@SOCKETIO.on("stop-capture")
## \details Function to handle the request of a source being stopped.
#  \brief Function to handle the request of a source being stopped.
#  \param captureKey String: path to the capture being stopped.
def handle_stop_capture(captureKey):
    #TODO: make it work for a robot
    if not captureKey in source_dict:
        raise RuntimeError(
            "trying to stop webcam without it being present in source dict")
    else:
        source_dict[captureKey].cap.release()
        return "success"


@SOCKETIO.on("stop-robot-capture")
## \details Function to handle the request of a source being stopped.
#  \brief Function to handle the request of a source being stopped.
#  \param captureKey String: path to the capture being stopped.
def handle_stop_robot_capture(captureKey):
    #TODO: make it work for a robot
    if not captureKey in source_dict:
        raise RuntimeError(
            "trying to stop robot without it being present in source dict, key = "
            + captureKey)
    else:
        source_dict[captureKey].unsubscribe_cameras()
        return "success"


#Event fired when a perception function is changed
@SOCKETIO.on("param-change")
def handle_param_changed(param_func, param_name, param_type, param_value):
    function_obj = getattr(perception, param_func)
    if (param_type == "number"):
        setattr(function_obj, param_name, float(param_value))
    elif (param_type == "bool"):
        setattr(function_obj, param_name, param_value == "True")
    print("changed {} parameter {} to {}".format(param_func, param_name,
                                                 param_value))
    return "success"


#Event fired when the user start recording
@SOCKETIO.on("start-record-video")
def handle_start_record_video(selected_source_path, recording_name):
    global recording
    if not re.match(r".+\.avi$", recording_name):
        return False, "Incorrect file format. Need to be .avi"
    else:
        #opencv video writer
        # Define the codec and create VideoWriter object
        #TODO: change resolution and fps on demand.
        fps = 15
        fourcc = cv2.VideoWriter_fourcc(*'XVID')
        recording = cv2.VideoWriter(recording_name, fourcc, fps, (640, 480))
        return True, "None"


#Event fired when there is a new frame to be recorded
@SOCKETIO.on("request-record-frame")
def handle_request_record_frame(selected_source_path):
    global recording
    if (not recording.isOpened()):
        return False
    if(selected_source_path.startswith("robot")):
        path_division = re.search(r"(robot-\d+\.\d+\.\d+\.\d+)\-(.+)", selected_source_path)
        robot_cap_ip = path_division.group(1)
        robot_camera = path_division.group(2)
        source = source_dict[robot_cap_ip]
        if(robot_camera == "top-image"):
            recording.write(source.top_image)
        else: 
            recording.write(source.bottom_image)
    else:
        source = source_dict[selected_source_path]
        recording.write(source.frame)
    return True


#Event fired when the user wants to stop capturing
@SOCKETIO.on("stop-record-video")
def handle_stop_record_video():
    global recording
    recording.release()


## \details Function to change an ALImage to a numpy Image to use within opencv. Used when handling images coming from the robot.
#  \brief Function to change an ALImage to a numpy Image.
#  \param al_image ALImage/Array: Array retrieved from the robot with qi getImageRemote/getImageLocal.
#  \return Returns a numpy Image to use with opencv.
def al_image_2_cv_mat(al_image):
    '''
        Convert from alImage to cvMat
        '''
    img_width = al_image[0]
    img_height = al_image[1]
    img_channels = al_image[2]
    np_img = np.reshape(al_image[6], (img_height, img_width, img_channels))
    np_img = np_img[..., ::-1]
    return np_img



## \details Function to encode a given image 
# #  \brief   Function called within a loop to get a cv2.cap image.
#  \param   image  Image Array: image source to be encoded. 
#  \param function_name Boolean/String:  Either false if there is no selected function or a string with the funtion name.
#  \param   selected_index int: user selected debug image index.
#  \return Returns the byte string that represents the cap image encoded in .jpg without the "data:image/jpeg;base64,". And image size for analysis.
def encode_image(image, function_name, selected_index):
    debug_image_size = 0  # if no selected function, it will stay 0
    if (function_name):
        getattr(perception, function_name).main([image])  # run main
        debug_image_size = len(
            getattr(perception, function_name).debug_image_array)
        image = getattr(perception, function_name).debug_image_array[int(
            selected_index)]  #get desired array index

    # encode the image in JPEG format
    (flag,
     top_encoded_image) = cv2.imencode(".jpg",
                                       image,
                                       params=[cv2.IMWRITE_JPEG_QUALITY, 30])

    # ensure the image was successfully encoded
    if not flag:
        raise RuntimeError("Immage not encoded correctly")

    #if everything went alright
    jpg_as_text = base64.b64encode(top_encoded_image)

    return jpg_as_text, debug_image_size


## \details Function called within a loop to get the robot images.
#  \param   ip String: robot ip, in the form of "192.168.0.40".
#  \param function_name Boolean/String:  Either false if there is no selected function or a string with the funtion name.
#  \param   selected_index int: user selected debug image index.
#  \return Returns the byte string that represents the cap image encoded in .jpg without the "data:image/jpeg;base64,".
def generate_robot_images(path, function_name, selected_index):
    key_name = path

    robot_src = source_dict[key_name]

    top_frame = robot_src.get_new_top_image()
    top_encoded, debug_image_size = encode_image(top_frame, function_name,
                                                 selected_index)

    bottom_frame = robot_src.get_new_bottom_image()
    bottom_encoded, debug_image_size = encode_image(bottom_frame,
                                                    function_name,
                                                    selected_index)

    return top_encoded, bottom_encoded, debug_image_size


## \details Function called within a loop to get a cv2.cap image. Used when dealing with video files and webcams.
#  \brief   Function called within a loop to get a cv2.cap image.
#  \param   path String: path used with the requeted cap. Should be in source_dict.
#  \param function_name Boolean/String:  Either false if there is no selected function or a string with the funtion name.
#  \param   selected_index int: user selected debug image index.
#  \return Returns the byte string that represents the cap image encoded in .jpg without the "data:image/jpeg;base64,".
def generate_cap_image(path, function_name, selected_index):

    key_name = path

    cap_src = source_dict[key_name]

    selected_debug_image_size = 0  # if no selected function, it will stay 0

    try:
        frame = cap_src.update_image()
    except RuntimeError as error:
        if error.message == "cap closed":
            return "cap closed"

    if function_name:
        getattr(perception, function_name).main([frame])  # run main
        selected_debug_image_size = len(
            getattr(perception, function_name).debug_image_array)
        frame = getattr(perception, function_name).debug_image_array[int(
            selected_index)]  #get desired array index

    # encode the frame in JPEG format
    (flag, encoded_image) = cv2.imencode(".jpg",
                                         frame,
                                         params=[cv2.IMWRITE_JPEG_QUALITY, 30])

    # ensure the frame was successfully encoded
    if not flag:
        raise RuntimeError("Image not encoded correctly")

    #if everything went alright

    jpg_as_text = base64.b64encode(encoded_image)

    return jpg_as_text, selected_debug_image_size


#127.0.0.1:5000
#Main route
@app.route("/", methods=["GET", "POST"])
## \details Funtion to handle the request to the home page.
#  \brief Funtion to handle the request to the home page.
def index():
    # return the rendered template
    return render_template(
        "index.html",  #todo rename file
        perception_functions=PERCEPTION_FUNCTIONS)


# check to see if this is the main thread of execution
if __name__ == '__main__':
    SOCKETIO.run(app, use_reloader=True, debug=True)
    # # start the flask app
    # app.run(host='127.0.0.1',
    #         port='8000',
    #         debug=True,
    #         threaded=True,
    #         use_reloader=False)
