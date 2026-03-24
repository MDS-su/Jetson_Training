#!/usr/bin/python3​
import time
import can

## Setup CAN channel​
interface = 'socketcan'
channel = 'can1'

def helpformat():
    print("--HELP------------------------------------------------------")
    print(" - <can_id>: 3 INT Type chars \n 3 INT Type -> HEX Type input")
    print(" * Examples:\n 142 / 555 / 111 / 123\n -> 08E / 22B / 06F / 07B\n")
    print(" - {data}: 0-8 INT Type chars(0-255) \n INT Type -> HEX Type input")
    print(" * Examples:\n 5,5 / 1,255,64,22 / 128,45,61,250,165,2,8,99\n -> 0505 /
    01FF4016 / 802D3DFAA5020863")
    print("-------------------------------------------------------------")​


def list_data(s):
    s_list=list()
    s_list=s.split(',')
    return s_list

def confirm_data(i, v):
    if len(i) == 3:
        if len(v) <= 8:
            len_v = len(v)
            return len_v
        else:
            print("Wrong {data} format!\n")
            helpformat()
            return -1
    else:
        print("Wrong <can_id> format!\n")
        helpformat()
        return -1

def can_send(i, v, l):
    bus = can.Bus(channel=channel, interface=interface)
    adata=[0x00]*8
    
    if(v != 0):
        n = 0
        for n in range(v):
            adata[n] = int(l[n])

    msg = can.Message(arbitration_id=int(i), data=adata, is_extended_id=False)​
    bus.send(msg)
    time.sleep(1)
    helpformat()

while True:
    try:
        canid = input("\n<can_id>: ")
        value = input("{data}: ")
        lvalue=list_data(value)
        vdata=confirm_data(canid, lvalue)
        if vdata != -1:
            print("-data num: " + str(vdata))
            can_send(canid, vdata, lvalue)
    except can.CanError:
        print("Message NOT sent")
    except ValueError:
        helpformat()
    except KeyboardInterrupt:
        break