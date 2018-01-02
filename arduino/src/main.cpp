#include <Arduino.h>

#define LEFT_PIN 5
#define RIGHT_PIN 4

#define LEFT_COMMAND 65
#define RIGHT_COMMAND 70
#define DOWN_COMMAND 0
#define UP_COMMAND 1
#define DEBOUNCE_DELAY 30

bool lastValueLeft, lastValueRight;
unsigned long lastTimeLeft, lastTimeRight;

void setup() {
    Serial.begin(115200);
    pinMode(LEFT_PIN, INPUT_PULLUP);
    pinMode(RIGHT_PIN, INPUT_PULLUP);
    lastValueLeft = true;
    lastTimeLeft = 0;
    lastValueRight = true;
    lastTimeRight = 0;
}

void readPaddle(uint8_t pin, bool &lastValue, unsigned long &lastTime, byte command) {
  bool newValue = digitalRead(pin);
  unsigned long now = millis();
  if (now - lastTime > DEBOUNCE_DELAY) {
    if (lastValue && !newValue) {
      Serial.write(command + DOWN_COMMAND);
      lastValue = newValue;
      lastTime = now;
    } else if (!lastValue && newValue) {
      Serial.write(command + UP_COMMAND);
      lastValue = newValue;
      lastTime = now;
    }
  }
}

void loop() {
    readPaddle(LEFT_PIN, lastValueLeft, lastTimeLeft, LEFT_COMMAND);
    readPaddle(RIGHT_PIN, lastValueRight, lastTimeRight, RIGHT_COMMAND);
}
