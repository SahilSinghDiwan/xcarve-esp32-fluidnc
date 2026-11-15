from picamera import PiCamera
from time import sleep

camera=PiCamera()
camera.rotation=180

#camera.start_preview()
count=0
while(True):
	sleep(5*60)
	camera.capture('/home/pi/time_lapse_camera/captured_images/cap%s.jpg' % count)
	count+=1
#camera.stop_previ	ew
