#!/bin/env/bin python3


from kafka import KafkaProducer
import cv2 as cv
from imutils.video import VideoStream
import time, imutils

def publish_video(brokers, topic, camera):

    producer = KafkaProducer(bootstrap_servers=brokers)
    # cap = cv.VideoCapture(camera)
    vs = VideoStream(camera).start()
    time.sleep(2)
    print("Publishing Video...")

    while True:
        frame = vs.read()
        frame = cv.cvtColor(frame, cv.COLOR_BGR2GRAY)
        # frame = imutils.resize(frame, width=640, height=480)
        producer.send(topic, frame.tobytes())
        producer.flush()

    # vs.stop()

if __name__ == '__main__':

    publish_video(brokers='node2:6667,node3:6667,node5:6667', topic='myvideo', camera=0)

