import cv2
import collections

params_2_alfrednator = collections.OrderedDict() 
params_2_alfrednator["Hmin"] = "number"
params_2_alfrednator["Smin"] = "number"
params_2_alfrednator["Vmin"] = "number"
params_2_alfrednator["Hmax"] = "number"
params_2_alfrednator["Smax"] = "number"
params_2_alfrednator["Vmax"] = "number"

debug_image_array = []

Hmin = 0
Smin = 0
Vmin = 0

Hmax = 255
Smax = 255
Vmax = 255


def main(image_array):

    del debug_image_array[:]  #clear debug_imaage_array

    image = image_array[0]
    debug_image_array.append(image)

    hsvImage = cv2.cvtColor(image, cv2.COLOR_BGR2HSV)

    debug_image_array.append(hsvImage[:,:,0]) # H channel
    debug_image_array.append(hsvImage[:,:,1]) # S channel
    debug_image_array.append(hsvImage[:,:,2]) # V channel

    # HSV Mask
    mask = cv2.inRange(hsvImage, (Hmin, Smin, Vmin), (Hmax, Smax, Vmax))
    debug_image_array.append(mask)

    


