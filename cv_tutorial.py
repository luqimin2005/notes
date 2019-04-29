#!/usr/bin/env python3

import numpy as np
import cv2 as cv
import os, time
# 从摄像头读取视频


def show_camera(camera=0):

    cap = cv.VideoCapture(camera)

    if not cap.isOpened():
        print("Cannot open camera.")
        exit()
    while True:
        # Capture Frame-by-Frame
        ret, frame = cap.read()
        if not ret:
            print("Can't receive frame. Exiting...")
            break
        gray = cv.cvtColor(frame, cv.COLOR_BGR2GRAY)
        # cv.imshow('frame', gray)
        # print(frame)

        cv.imshow('frame', frame)
        if cv.waitKey(1) == ord('q'):
            break

    cap.release()
    cv.destroyAllWindows()


# 读取摄像头视频，并写入文件

def save_video(file_dir, camera=0):

    file_name = os.path.join(file_dir, 'output-'+str(time.time())+'.avi')

    cap = cv.VideoCapture(camera)
    fourcc = cv.VideoWriter_fourcc(*'XVID')
    # fourcc = cv.VideoWriter_fourcc(*'MPEG')
    out = cv.VideoWriter(file_name, fourcc, 20.0, (640, 480), isColor=False)

    while cap.isOpened():
        ret, frame = cap.read()
        if not ret:
            print("Can't receive frame. Exiting...")
            break
        # frame = cv.flip(frame, 0)
        frame = cv.cvtColor(frame, cv.COLOR_BGR2GRAY)
        # print(frame)
        out.write(frame)
        print(os.path.getsize(file_name))

        cv.imshow('frame', frame)
        if cv.waitKey(1) == ord('q'):
            break

        if os.path.getsize(file_name) >= 1048576:   # 1MB
            out.release()
            file_name = os.path.join(file_dir, 'output-'+str(time.time())+'.avi')
            out = cv.VideoWriter(file_name, fourcc, 20.0, (640, 480), isColor=False)

    cap.release()
    out.release()
    cv.destroyAllWindows()


# 读取视频文件
def show_video(file_name):
    cap = cv.VideoCapture(file_name)

    while cap.isOpened():
        ret, frame = cap.read()
        if not ret:
            print("Can't receive frame. Exiting...")
            break
        gray = cv.cvtColor(frame, cv.COLOR_BGR2GRAY)

        cv.imshow('frame', gray)
        if cv.waitKey(1) == ord('q'):
            break

    cap.release()
    cv.destroyAllWindows()

if __name__ == '__main__':

    show_camera()
    # save_video('outputs')
    # show_video('outputs\output.avi')
