#!/usr/env/bin python3

from kafka import KafkaConsumer
import cv2 as cv
import numpy as np
from imutils.video import FPS
import os, time
from hdfs.client import Client


client = Client("http://192.168.100.108:50070")

def put_to_hdfs(client, local_path, hdfs_path):
    client.upload(hdfs_path, local_path, cleanup=True)

def get_from_hdfs(client, hdfs_path, local_path):
    client.download(hdfs_path, local_path, overwrite=False)



def face_detecting(frame, face_cascade, font):
    faces = face_cascade.detectMultiScale(
        frame,
        scaleFactor=1.15,
        minNeighbors=5,
        minSize=(5, 5)
    )
    if len(faces) != 0:
        print("警告：有人闯入！！！（[%s]个）" % len(faces))
    for x, y, w, h in faces:
        cv.rectangle(frame, (x - 10, y - 10), (x + w + 10, y + h + 10), (225, 0, 0), 2)
        cv.putText(frame, "WARNING: PEOPLE HERE!!", (x, y + h), font, 0.5, (255, 0, 0), 1)


def show_video(brokers, topic):
    face_cascade = cv.CascadeClassifier(r'venv\Lib\site-packages\cv2\data\haarcascade_frontalface_default.xml')
    font = cv.FONT_HERSHEY_SIMPLEX

    file_name = os.path.join('outputs', 'output-' + str(time.time()) + '.avi')
    fourcc = cv.VideoWriter_fourcc(*'XVID')
    out = cv.VideoWriter(file_name, fourcc, 32, (640, 480), isColor=False)

    consumer = KafkaConsumer(topic, bootstrap_servers=brokers)
    fps = FPS().start()
    print("Receiving Video...")

    for msg in consumer:
        frame = np.frombuffer(msg.value, np.uint8)
        frame = frame.reshape(480, 640, 1)    # 格式化

        face_detecting(frame, face_cascade, font)

        out.write(frame)
        cv.imshow('Faces', frame)
        # print(os.path.getsize(file_name))

        if os.path.getsize(file_name) >= 1048576:
            out.release()
            put_to_hdfs(client, file_name, '/tmp/')
            file_name = os.path.join('outputs', 'output-' + str(time.time()) + '.avi')
            out = cv.VideoWriter(file_name, fourcc, 20.0, (640, 480), isColor=False)
        if cv.waitKey(1) == ord('q'):
            break

        fps.update()

    fps.stop()
    out.release()
    cv.destroyAllWindows()


if __name__ == '__main__':


    show_video(brokers='node2:6667,node3:6667,node5:6667', topic='myvideo')

