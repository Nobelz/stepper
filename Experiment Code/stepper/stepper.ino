#include <Stepper.h>

//define global variables
const int stepsPerRevolution = 96;
int len = 1000;
int rate = 20;
byte gain = 1;
byte val = 0;
byte spd = 240;
byte trigmode = 0;
volatile uint8_t trigflag = 0;
//instantiate stepper class on digital pins 8-11
Stepper stepper(stepsPerRevolution, 8, 9, 10, 11);

void setup() {
  //turn on digital pins 7 and 12 to enable the h-bridge chip
  digitalWrite(7, true);
  digitalWrite(12, true);

  // set digital pin 4 to output for stepper timing information
  pinMode(4, OUTPUT);

  //set speed to default
  stepper.setSpeed(spd);

  //start serial communication
  Serial.begin(9600);
}

void loop() {
  //listen for new serial commands
  if (Serial.available() > 0) {
    //store incoming bytes in command
    char command = Serial.read();
    if (command == 'r') {                  //step right
      while (Serial.available() == 0) {};  //wait for next byte which says how many steps
      val = Serial.read();                 //store value of next byte when available
      Serial.print(command);               //print command and number of steps as feedback
      Serial.println(val);
      stepper.step(val);          //step right by requested number of steps
    } else if (command == 'l') {  //same as above but for left step
      while (Serial.available() == 0) {};
      val = Serial.read();
      Serial.print(command);
      Serial.println(val);
      stepper.step(-val);
    } else if (command == 'R') {  //step right one full revolution
      Serial.println(command);    //print for feedback
      stepper.step(stepsPerRevolution);
    } else if (command == 'L') {  //same as above but for left
      Serial.println(command);
      stepper.step(-stepsPerRevolution);
    } else if (command == 'S') {           //set speed
      while (Serial.available() == 0) {};  //wait for byte
      spd = Serial.read();                 //store speed value when available
      Serial.print(command);               //print feedback
      Serial.println(spd);
      stepper.setSpeed(spd);               //set speed of stepper object
    } else if (command == 'G') {           //set gain
      while (Serial.available() == 0) {};  //wait for byte
      gain = Serial.read();                //store gain value when available
      Serial.print(command);               //print feedback
      Serial.println(gain);
      digitalWrite(13, true);
    } else if (command == 'P') {           //set update rate in Hz for sequence mode
      while (Serial.available() == 0) {};  //wait for value in next byte
      rate = (int)Serial.read();           //store value
      Serial.print(command);               //print feedback
    } else if (command == 'C') {           //begin sequence mode
      while (Serial.available() < 2) {};   //wait for two bytes to be available
      len = Serial.read();                 //get length of commanded sequence in bytes
      beginSequence(len, rate, gain);      //execute sequence mode with desired rate
    } else if (command == 'T') {           //set trigger behavior for sequence playback mode
      while (Serial.available() == 0) {};  //wait for byte
      trigmode = Serial.read();            //store trigger behavior setting.
      // available modes: 0 = play sequence immediately, 1 = step one element of sequence every time pin 2 goes high, 2 = play whole sequence after pin 2 goes high.
      Serial.print(command);              //print feedback
    } else if (command == 'V') {          // begin voltage mode
      beginVoltage(gain);                 // begin voltage mode with desired duration
    } 
    else if (command == 'A') {          // begin arena mode: listen to arena output and move accordingly
      while (Serial.available() < 2) {};  //wait for two bytes to be available
      // len = Serial.read();                // get length of commanded sequence in bytes
      beginArena(len, gain);              // execute sequence mode with desired gain according to arena feedback
    }
  }
}

//sequence playback function
void beginSequence(int len, int rate, byte gain) {
  stepper.setSpeed(255);  //temporarily set speed to maximum
  byte buff[len];         //define a byte buffer for the incomming sequence
  //pull bytes from the serial buffer into the command buffer as they become available
  int ctr = 0;
  while (ctr < len) {
    while (Serial.available() == 0) {};
    buff[ctr] = Serial.read();
    ctr++;
  }

  //attach interrupt to digital pin 2 if trigger mode 1 or 2 is enabled
  if (trigmode > 0) {
    attachInterrupt(digitalPinToInterrupt(2), flagup, RISING);
  }

  trigflag = 0;                //flag for trigger up condition in modes 1 and 2
  byte mode = trigmode;        //copy trigger mode
  unsigned long prevtime = 0;  //last value of timer
  long per = 1000 / rate;      //number of milliseconds between steps
  byte curbyte;                //current command byte [4 commands per byte]

  //start iterating through command bytes
  for (int i = 0; i < len; i++) {
    curbyte = buff[i];  // assign next byte in buffer to curbyte
    //go through bits in current byte 2 at a time
    for (int j = 0; j < 7; j = j + 2) {
      if (mode > 0) {             //if we're in trigger modes 1 or 2 we need to wait between commands
        while (trigflag == 0) {}  //trigflag will change from 0 to 1 when the interrupt is called
        if (mode == 1) {          //if we're in mode 1, set the trigger flag back to zero so we'll wait for another pulse between commands
          trigflag = 0;
        } else {  //if we're in mode 2, we only cared about the first trigger pulse and will use internal clock for subsequent steps, so we can change to mode 0 for the rest of this sequence
          mode = 0;
        }
      } else {  //if we're in mode 0 wait til its time for the next step and then go
        while (millis() < prevtime + per) {
          if (millis() > (prevtime + per / 2)) {
            // Write digital pin down halfway through iteration
            digitalWrite(4, LOW);
          }
        }                     //wait til current time is greater than last pulse + interpulse period
        prevtime = millis();  //assign last pulse time to now
      }

      // Write digital pin up
      digitalWrite(4, HIGH);

      if ((bitRead(curbyte, j) == 0) & (bitRead(curbyte, j + 1) == 1)) {  //step right by 1 step if our command bits are 01 (1 in decimal)
        stepper.step(1 * gain);
      } else if ((bitRead(curbyte, j) == 1) & (bitRead(curbyte, j + 1) == 0)) {  //step left by 1 step if our command bits are 10 (2 in decimal)
        stepper.step(-1 * gain);
      }
      //other command bits [00 (0 in decimal) and 11 (3 in decimal)] do nothing
    }
  }
  //all done with sequence
  stepper.setSpeed(spd);  //set speed back to defined speed
  if (trigmode > 0) {     //if we were using a triggered sequence mode detach the interrupt from digital pin 2
    detachInterrupt(digitalPinToInterrupt(2));
  }
}

void beginVoltage(byte gain) {
  stepper.setSpeed(255);  //temporarily set speed to maximum
  unsigned long prevtime = millis();
  unsigned int val = 0;
  int8_t curState = 0;
  int8_t lastState = 0;

  while (true) {
    val = analogRead(A1);
    if (val < 341) {
      curState = -1;
    } else if (val < 682) {
      curState = 0;
    } else {
      curState = 1;
    }

    if (lastState == 0 && curState < 0) {
      stepper.step(-1 * gain);
      digitalWrite(4, HIGH);
    } else if (lastState == 0 && curState > 0) {
      stepper.step(1 * gain);
      digitalWrite(4, HIGH);
    } else if (lastState != 0 && curState == 0) {
      digitalWrite(4, LOW);
    }

    lastState = curState;
  }

  stepper.setSpeed(spd);  //set speed back to defined speed
}

//sequence playback function
void beginArena(int len, byte gain) {
  stepper.setSpeed(255);  // Temporarily set speed to maximum
  byte buff[len];         // Define a byte buffer for the incomming sequence
  // Pull bytes from the serial buffer into the command buffer as they become available
  int ctr = 0;
  while (ctr < len) {
    while (Serial.available() == 0) {};
    buff[ctr] = Serial.read();
    ctr++;
  }

  digitalWrite(4, LOW); // Set output to be low to begin

  trigflag = 0;                // Flag for trigger up condition
  unsigned long prevtime = 0;  // Last value of timer
  long per = 1000 / rate;      // Number of milliseconds between steps
  byte curbyte;                // Current command byte [4 commands per byte]
  byte out = LOW;              // Stores the previous output so we can alternate for output logging

  unsigned int lastState = analogRead(A1);
  unsigned int currentState = analogRead(A1);  

  // Start iterating through command bytes
  for (int i = 0; i < len; i++) {
    curbyte = buff[i];  // Assign next byte in buffer to curbyte
    // Go through bits in current byte 2 at a time
    for (int j = 0; j < 7; j = j + 2) {
      while (abs(lastState - currentState) < 600) { // Wait until rising/falling edge is detected
        lastState = currentState;
        currentState = analogRead(A1);
      } 

      // Change digital pin output
      digitalWrite(4, 1 - out);
      out = 1 - out;

      if ((bitRead(curbyte, j) == 0) & (bitRead(curbyte, j + 1) == 1)) {  // Step right by 1 step if our command bits are 01 (1 in decimal)
        stepper.step(1 * gain);
      } else if ((bitRead(curbyte, j) == 1) & (bitRead(curbyte, j + 1) == 0)) {  // Step left by 1 step if our command bits are 10 (2 in decimal)
        stepper.step(-1 * gain);
      }
      // Other command bits [00 (0 in decimal) and 11 (3 in decimal)] do nothing

      lastState = currentState;
    }
  }

  // All done with sequence
  stepper.setSpeed(spd);  // Set speed back to defined speed
}

//interrupt service routine for triggered recordings -- when attached, this is called whenever D2 goes high
void flagup() {
  trigflag = 1;
}
