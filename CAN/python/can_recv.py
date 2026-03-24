#!/usr/bin/python3​
import time
import can

## Setup CAN channel​
interface = 'socketcan'
channel = 'can0'
#channel = 'can1'​
#channel = 'ucan0'​
#channel = 'ucan1'​

bus = can.Bus(channel=channel, interface=interface)

while True:
    try:
        message = bus.recv()
        if message:
            print(message)
    except can.CanError:
        print("Message NOT sent")
    except KeyboardInterrupt:
        break