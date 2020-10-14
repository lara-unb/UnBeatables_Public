import qi
import vision_definitions
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