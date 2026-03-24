import RPi.GPIO as GPIO
import time

output_pins = { 'JETSON_ORIN': 18 }
output_pin = output_pins.get(GPIO.model, None)
if output_pin is None:
    raise Exception('PWM not supported on this board')

def main():
    # Pin Setup:​
    # Board pin-numbering scheme​
    GPIO.setmode(GPIO.BOARD)
    # set pin as an output pin with optional initial state of HIGH​
    GPIO.setup(output_pin, GPIO.OUT, initial=GPIO.HIGH)
    p = GPIO.PWM(output_pin, 50)
    val = 100
    p.start(val)

    print("PWM running. Press CTRL+C to exit.")
    try:
        while True:
            time.sleep(3)
            val = 100
            p.ChangeDutyCycle(val)
            print(val)

            time.sleep(3)
            val = 20
            p.ChangeDutyCycle(val)
            print(val)

            time.sleep(3)
            val = 0
            p.ChangeDutyCycle(val)
            print(val)

    finally:
        p.stop()
        GPIO.cleanup()

if __name__ == '__main__':
    main()