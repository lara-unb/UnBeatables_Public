## \details Class that encapsulates a new source from opencv. Used with webcams or video files.
#  \brief  Class that encapsulates a new source from opencv.
class CapSource(object):
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