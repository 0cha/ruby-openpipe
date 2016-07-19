ruby-openpipe
===========
Is intended to [OpenPipe](http://openpipe.cc/) to work with Ruby nad Raspberry Pi

Using the combination of MIDI interface or MIDI program(ttymidi/aconnect....)

THe following libraries are rewrite in Ruby

- [Adafruit MPR121](https://github.com/openpipelabs/openpipe-breakout)
- [Adafruit BMP085](https://github.com/adafruit/Adafruit_Python_BMP)
- [openpipe-breakout](https://github.com/adafruit/Adafruit_Python_MPR121)

## Platforms
ruby-openpipe is developed on RASPBIAN(Jessi) is installed Raspberry Pi 2B/zero.

Please [enable i2c module](https://learn.sparkfun.com/tutorials/raspberry-pi-spi-and-i2c-tutorial#i2c-on-pi) is Raspberry Pi

## installation
```
$ sudo apt-get install ruby2.1 ruby2.1-dev make build-essential
$ sudo gem2.1 install bundle
$ git clone httsp://github.com/0cha/ruby-openpipe.git
$ cd ruby-openpipe
$ bundle install --path=vendor/bundle
```

## Usage
ruby-openpipe is the send OpenPipe signals to MIDI interface found in the first.


ruby-openpipe -> snd-virmidi -> [ttymidi](https://zuzebox.wordpress.com/2015/12/13/setting-up-rpi-midi-and-fluid-synth-softsynth/)

```
$ sudo apt-get install libasound2-dev
$ sudo modprobe snd-virmidi
$ ttymidi -s /dev/ttyAMA0 -b 38400 -v &
$ aconnect -iol
Client 0: 'System' [Type=Kernel]
    0 'Timer           '
    1 'Announce        '
Client 14: 'Midi Through' [type=kernel]
    0 'Midi Through Port-0'
Client 16: 'Virtual Raw MIDI 0-0' [type=kernel]
    0 'VirMIDI 0-0     '
Client 17: 'Virtual Raw MIDI 0-1' [type=kernel]
    0 'VirMIDI 0-1     '
Client 18: 'Virtual Raw MIDI 0-2' [type=kernel]
    0 'VirMIDI 0-2     '
Client 19: 'Virtual Raw MIDI 0-3' [type=kernel]
    0 'VirMIDI 0-3     '
Client 128: 'ttymidi' [type=User]
    0 'MIDI out        '
    1 'MIDI in         '
$ aconnect 14:0 128:1
$ cd ruby-openpipe
$ sudo bundle exec ruby2.1 ./openpipe.rb
```
