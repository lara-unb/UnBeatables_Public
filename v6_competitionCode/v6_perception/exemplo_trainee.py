import cv2
import collections

# Coloque aqui os parametros que vc deseja inserir

params_2_alfrednator = collections.OrderedDict() 
params_2_alfrednator["Hmin"] = "number"
params_2_alfrednator["Smin"] = "number"
params_2_alfrednator["Vmin"] = "number"
params_2_alfrednator["Hmax"] = "number"
params_2_alfrednator["Smax"] = "number"
params_2_alfrednator["Vmax"] = "number"
params_2_alfrednator["kernel_size1"] = "number"
params_2_alfrednator["kernel_size2"] = "number"
params_2_alfrednator["param1"] = "number"
params_2_alfrednator["param2"] = "number"
params_2_alfrednator["min_radius"] = "number"
params_2_alfrednator["min_dist"] = "number"


debug_image_array = []

Hmin = 90
Smin = 100
Vmin = 100

Hmax = 100
Smax = 255
Vmax = 255

kernel_size1 = 3
kernel_size2 = 3
param1 = 15
param2 = 30
min_radius = 10
min_dist = 20


def main(image_array):

    del debug_image_array[:]  #clear debug_imaage_array

    image = image_array[0]

    # Insere uma imagem no array de imagens de debug
    debug_image_array.append(image)

    # Aplica transformacao e mascara HSV
    hsvImage = cv2.cvtColor(image, cv2.COLOR_BGR2HSV)
    mask = cv2.inRange(hsvImage, (Hmin, Smin, Vmin), (Hmax, Smax, Vmax))

    # Coloca a mascara no array de imagens de debug
    debug_image_array.append(mask)

    # Filtra imagem
    filtered_mask = cv2.erode(mask, (kernel_size1,kernel_size1), iterations=2) 
    filtered_mask = cv2.dilate(filtered_mask, (kernel_size2,kernel_size2), iterations=9)
    debug_image_array.append(filtered_mask)

   # Encontra os circulos
    circles = cv2.HoughCircles(filtered_mask,
                               cv2.HOUGH_GRADIENT, 
                               dp=1,
                               minDist=min_dist,
                               param1=param1,
                               param2=param2,
                               minRadius=int(min_radius))

    image_copy = image.copy()
    if circles is not None:

        for circle in circles[0,:]:
            centerx = circle[0]
            centery = circle[1]
            radius = circle[2]

            cv2.circle(image_copy, (centerx,centery), radius, (0, 255, 0), 2) 

    debug_image_array.append(image_copy)