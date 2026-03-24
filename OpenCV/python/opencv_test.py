import cv2

# 연결 2가지 중 다른 1쪽은 주석처리
# 카메라 연결 - 1 : 0번카메라
cap = cv2.VideoCapture(0)

# 카메라 연결 - 2 : GStreamer 파이프라인
# pipeline = 'gst-launch-1.0 -v v4l2src device=/dev/video0 ! video/x-raw, width=640, height=480, format=YUY2, framerate=20/1 ! videoconvert ! video/x-raw, format=BGR ! Appsink'
# cap = cv2.VideoCapture(pipeline, cv2.CAP_GSTREAMER)

# 해상도 확인
print('width : %d, height : %d' % (cap.get(3), cap.get(4)))
# 해상도 변경
cap.set(cv2.CAP_PROP_FRAME_WIDTH, 640)
cap.set(cv2.CAP_PROP_FRAME_HEIGHT, 480)

while(True):
    ret, frame = cap.read()    # Read 결과와 frame

    if(ret) :
        # gray = cv2.cvtColor(frame,  cv2.COLOR_BGR2GRAY)    # 입력 받은 화면 Gray로 변환
        cv2.imshow('frame_color', frame)    # 컬러 화면 출력
        # cv2.imshow('frame_gray', gray)     # Gray 화면 출력
        if cv2.waitKey(1) == ord('q'):
            break

cap.release()
cv2.destroyAllWindows()