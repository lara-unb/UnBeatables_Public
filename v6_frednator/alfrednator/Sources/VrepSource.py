## \details Class that encapsulates a new vrep source. Used with NAO v6 Vrep simulation.
#  \brief  Class that encapsulates a new vrep source.
class VrepSource(object):

    ## \details Function to start capturing both topImage and botImage from the virtual robot. Should be called only once.
    #  \brief Function to start capturing both topImage and botImage from the robot.
    #  \param virtual_robot_ip String: virtual robot address in the form of "xxx.xxx.xxx.xxx", such as "192.168.0.40" or "localhost".
    #  \param virtual_robot_port String: robot port in the form of "xxxxx", such as "9559".
    # \return Returns, in order, the qi session, the ALVideoDevice service, the top image client and the bottom image client.
    def __init__(self, virtual_robot_ip, virtual_robot_port):
        virtual_robot_ip = virtual_robot_ip.replace("robot-", "")
        self.virtual_robot_ip = virtual_robot_ip
        self.virtual_robot_port = virtual_robot_port

        # initialize a capture
        self.top_camera_name = "NAO_vision1"
        self.bottom_camera_name = "NAO_vision2"

        if not "vrep-" + self.virtual_robot_ip + "-" + self.virtual_robot_port in source_dict:
            #new capture
            source_dict["vrep-" + self.virtual_robot_ip + "-" + self.virtual_robot_port] = self
            self.initialize_vrep_cameras()
        

        self.top_image = self.get_new_top_image
        self.bottom_image = self.get_new_bottom_image

    def initialize_vrep_cameras(self):
        #vrep setup
        vrep.simxFinish(-1)
        self.clientID = vrep.simxStart('127.0.0.1', 19997, True, True, 5000, 5)
        if(clientID == -1):
            raise RuntimeError("ClientID -1, could not connect to vrep")
        else:
             #Top camera
            #Get the handle of the top vision sensor
            res1, self.top_camera_handle = vrep.simxGetObjectHandle(
                self.clientID, self.top_camera_name, vrep.simx_opmode_oneshot_wait)
            if(res1 != 0):
                raise RuntimeError("Could not get top camera handle. res = " + str(res1))
            #Get the handle of the bottom vision sensor
            res1, self·bottom_camera_handle = vrep.simxGetObjectHandle(
                self.clientID, self.bottom_camera_name, vrep.simx_opmode_oneshot_wait)
            if(res1 != 0):
                raise RuntimeError("Could not get bottom camera handle. res = " + str(res1))
            
            #Initialize top camera stream
            res2, resolution, image = vrep.simxGetVisionSensorImage(
                self.clientID, self.top_camera_handle, 0, vrep.simx_opmode_streaming)
            
            #Initialize bottom camera stream
            res2, resolution, image = vrep.simxGetVisionSensorImage(
                self.clientID, self.bottom_camera_handle, 0, vrep.simx_opmode_streaming)

    #get a new image from top camera
    def get_new_top_image(self):
        #Get the image of the vision sensor
        top_res, top_resolution, top_image = vrep.simxGetVisionSensorImage(
            self.clientID, self.top_camera_handle, 0, vrep.simx_opmode_buffer)
        top_image = np.array(top_image,dtype=np.uint8)
        top_image.resize([top_resolution[1],top_resolution[0],3])
        top_image = np.flip(top_image, axis=0)
        return top_image

    #get a new image from bottom camera
    def get_new_bottom_image(self):
        bottom_res, bottom_resolution, bottom_image = vrep.simxGetVisionSensorImage(
            self.clientID, self.bottom_camera_handle, 0, vrep.simx_opmode_buffer)
        bottom_image = np.array(bottom_image,dtype=np.uint8)
        bottom_image.resize([bottom_resolution[1],bottom_resolution[0],3])
        bottom_image = np.flip(bottom_image, axis=0)
        return bottom_image