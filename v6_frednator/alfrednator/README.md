# ALFrednator
This is the source code for the ALFrednator, an application that can simulate and verify the robot's computer vision behavior, allowing it to vary its parameters and visualize the result.
 
Python, HTML, CSS and JavaScript knowledge are needed for better understanding.
 
### Structure (?)
 
- Path: `~/Unbeatables/v6_frednator/alfrednator`
- `~/templates`: HTML interface subdirectory.
- `~/static`: Web applications subdirectory.
- `alfred.py`: Main file.
 
## Dependencies
 
To run this code you must have installed these packages:
 
* [OpenCV]: A library of programming  computer vision functions.
 
   ```
   $ sudo pip install opencv-python
   ```
 
* Python NAOQI: The NAOqi Framework is the programming framework used to program NAO.
 
   Instructions in [http://doc.aldebaran.com/2-5/dev/python/install_guide.html]
 
* [Flask]: Web framework written in Python. Allows to create a local server. [Get Started][Flaskstarted].
 
   ```
   $ pip install -U Flask
   ```
 
* Flask_Socketio: A JavaScript library for web applications. Allows communication between web clients and servers. [Get Started][socketstarted].
 
   ```
   $ pip install Flask-SocketIO
   ```
 
* Construct: a Python library for the construction and deconstruction of data structures.
 
   ```
   $ pip install construct
   ```
 
* Eventlet
 
   ```
   $ pip install eventlet
   ```
 
* VREP: Simple python binding for V-REP robotics simulator, also known as  [CoppeliaSim]
 
   ```
   $ pip install vrep-python
   ```
 
 
 
## Execution
Since the addition of the bluezero CoppeliaSim communication , it's necessary to run the code below, to make sure that b0RemoteApi is able to find the correct boost libraries.
```
$ export LD_LIBRARY_PATH=$PWD/lib
```
 
 
Then, you can run:
```
$ python2 alfred.py
```
 
 
Then, open your browser and paste `127.0.0.1:5000/` or `localhost:5000/`  on your url bar.
 
### How to use
 
After getting on the website page, you should define the path of what you want to execute in ALFrednator. It can be:
- File path in your PC (mp4 video, for example).
- Webcam by giving your webcam capture code. It depends on your PC configuration.
- Robot IP, allowing visualization of Robot camera.
- Vrep Button. Currently it does not read from input. But it will work, with _NAO.ttt_ scene.
 
~~Also, you can select the desired FPS rate.~~ **This does not work**
 
 
After that, you will probably see your image source right below. Now, you can select the perception functions (at right of screen ) and vary its parameters in real time.
 
 
### Important functions
- `alfrednatorFunctions`: Array located at Perception main file. The functions included in it will appear in Alfred, such as redBallDetector or ballDetector.
 
- `params_2_alfrednator`: Array that informs which parameters can be changed within Alfred, such as the minimum and maximum parameters of R, G or B component in a RedBallDetector's color segmentation. It must be located in each main function file.
- `@socketio.on`: Socket.io method for triggering functions from events created by JavaScript. Depending on its purpose, can make the desired manipulations on Alfred's website.
 
  [Flaskstarted]: <https://flask.palletsprojects.com/en/1.1.x/quickstart/>
  [socketstarted]: <https://socket.io/get-started/chate>
  [CoppeliaSim]: <https://www.coppeliarobotics.com/>
  [Flask]: <https://flask.palletsprojects.com/en/1.1.x/>
  [OpenCV]: <https://opencv.org/>
 
 

