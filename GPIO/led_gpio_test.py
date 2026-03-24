import RPi.GPIO as GPIO
import time

led_pin = 40

def main():
    # Pin Setup:​
    GPIO.setmode(GPIO.BOARD)  # BOARD pin-numbering scheme​
    GPIO.setup(led_pin, GPIO.OUT)  # LED pin set as output​
    GPIO.output(led_pin, GPIO.LOW)

    try:
        while True:
            GPIO.output(led_pin, GPIO.HIGH)
            print("HIGH")
            time.sleep(3)
            GPIO.output(led_pin, GPIO.LOW)
            print("LOW")
            time.sleep(3)
    finally:
        GPIO.cleanup()  # cleanup all GPIO

if __name__ == '__main__':
    main()