# cython: boundscheck=False
#cython: cython.wraparound=False
import numpy as np

def run(unsigned char[:, :, :] image):
    cdef unsigned char[:,:] chroma_channel = np.zeros((image.shape[0], image.shape[1]), dtype=np.uint8)
    cdef unsigned char[:] pixel
    cdef unsigned char max_rgb, min_rgb, pixel_value
    cdef int row_idx, column_idx, channel_value
    for row_idx in range(image.shape[0]):
        for column_idx in range(image.shape[1]):
            max_rgb = 0
            min_rgb = 255
            pixel = image[row_idx, column_idx]

            for channel_value in range(3):
                pixel_value = pixel[channel_value]
                if pixel_value > max_rgb:
                    max_rgb =  pixel_value
                if pixel_value  < min_rgb:
                    min_rgb = pixel_value 
            
            chroma_channel[row_idx, column_idx] = max_rgb - min_rgb
    

    return np.asarray(chroma_channel)