#include <avr/sleep.h>

#include "tmp102.h"
#include "TF.h"
#include "Battery.h"
#include "RX8025.h"

#include <Wire.h>
#include <Fat16.h>
#include <Fat16util.h> // use functions to print strings from flash memory

//**************************************

float convertedtemp; /* We then need to multiply our two bytes by a scaling factor, mentioned in the datasheet. */
int tmp102_val; /* an int is capable of storing two bytes, this is where we "chuck" the two bytes together. */

char name[] = "data.log";/* file name in TF card root dir */

unsigned int bat_read;//analog read battery voltage
float bat_voltage;//battery voltage
unsigned char charge_status;//battery charge status

unsigned char hour=0;
unsigned char minute=0;
unsigned char second=0;
unsigned char week=0;
unsigned char year=0;
unsigned char month=0;
unsigned char date=0;

// 'remote' temp sensor vars, where remote = off-board
// for two remote sensors 'a' and 'b'
/*int rta;
int remotedelay=1000;
float remotetempa;
int B=3975;
float resistancea;*/

int a;
int del=1000; // duration between temperature readings
float temperature;
int B=3975; 
float resistance;


unsigned char RX8025_time[7]=
{
  0x00,0x14,0x08,0x01,0x27,0x06,0x11 //second, minute, hour, week, date, month, year, BCD format
};


//======================================
void setup(void)
{
  Serial.begin(38400);
  RX8025_init();
  TF_card_init();
  tmp102_init();
  Battery_init();
  pinMode(8,OUTPUT);//LED pin set to OUTPUT
  pinMode(5,OUTPUT);//Bee power control pin
// uncomment below to set time on upload - time format set above in RX8025_time
// setRtcTime();
}
//======================================
void loop(void)
{
  digitalWrite(8,HIGH);//LED pin set to OUTPUT
  getTemp102();
  Battery_charge_status();
  Battery_voltage_read();  
  getRtcTime();
  write_data_to_TF();
  digitalWrite(8,LOW);

  //debug data
  print_RX8025_time();
  print_tmp102_data();
  print_Battery_data();
  Serial.println("--------------next--data---------------");
  Serial_Command();
  Serial.println();

//remote temp stuff
/*  rta=analogRead(0);
  resistancea=(float)(1023-rta)*10000/rta;
  remotetempa=1/(log(resistancea/10000)/B+1/298.15)-273.15;
  // delay(remotedelay);
  Serial.println(remotetempa);*/
  
  a=analogRead(0);
  resistance=(float)(1023-a)*10000/a; 
  temperature=1/(log(resistance/10000)/B+1/298.15)-273.15;
  delay(del);
  Serial.println(temperature);

  delay(2000);
}

//=================================
void print_tmp102_data(void)
{
  Serial.print("tep102_temperature = ");
  Serial.println(convertedtemp);
}

//==================================
void print_Battery_data(void)
{
  switch (charge_status) 
  {
  case 0x01:    
    {
      Serial.print("CH_sleeping");
      break;
    }
  case 0x02:    
    {
      Serial.print("CH_complete");
      break;
    }
  case 0x04:    
    {
      Serial.print("CH_charging");
      break;
    }
  case 0x08:    
    {
      Serial.print("CH_bat_not_exist");
      break;
    }
  }
  Serial.print(" battery voltage = ");
  Serial.println(bat_voltage);
}
//==============================================
void print_RX8025_time(void)
{
  Serial.print(year,DEC);
  Serial.print("/");
  Serial.print(month,DEC);
  Serial.print("/");
  Serial.print(date,DEC);
  switch(week)
  {
  case 0x00:
    {
      Serial.print("/Sunday  ");   
      break;
    }
  case 0x01:
    {
      Serial.print("/Monday  ");
      break;
    }
  case 0x02:
    {
      Serial.print("/Tuesday  ");
      break;
    }
  case 0x03:
    {
      Serial.print("/Wednesday  ");
      break;
    }
  case 0x04:
    {
      Serial.print("/Thursday  ");
      break;
    }
  case 0x05:
    {
      Serial.print("/Friday  ");
      break;
    }
  case 0x06:
    {
      Serial.print("/Saturday  ");
      break;
    }
  }
  Serial.print(hour,DEC);
  Serial.print(":");
  Serial.print(minute,DEC);
  Serial.print(":");
  Serial.println(second,DEC);
}

//======================================
void Serial_Command(void)
{
  if(Serial.available()==3)
  {
    if(Serial.read()=='c')
    {
      if(Serial.read()=='c')
      {
        if(Serial.read()=='c')
        {
          Serial.println("Got Serial data");
        }
      }
    }
  }
  else
  {
    Serial.flush();
  }
}






