#https://en.wikipedia.org/wiki/HSL_and_HSV#Formal_derivation

import cv2
import numpy as np
import time
import chroma_calculator


params_2_alfrednator = {
}
debug_image_array = []

def chroma_channel_caculate(pixel):
    return max(pixel) - min(pixel)

def main(image_array):

    del debug_image_array[:]  #clear debug_imaage_array
    image = image_array[0]
    start_time = time.clock()
    chroma_channel = np.zeros((image.shape[0], image.shape[1]), dtype=np.uint8)

    debug_image_array.append(image)

    chroma_channel = chroma_calculator.run(image)
    end_time = time.clock()
    debug_image_array.append(chroma_channel)
    
    print(end_time - start_time)

if __name__ == "__main__":
    image = cv2.imread("/home/paulo/Pictures/photo1.jpg")
    main([image])

    cv2.namedWindow("test")
    cv2.namedWindow("image")
    cv2.imshow("test", debug_image_array[1])
    cv2.imshow("image", debug_image_array[0])
    cv2.waitKey(0)

    cv2.destroyAllWindows()
    


