#!/usr/bin/ruby2.1
require 'pp'
require 'unimidi'
require 'i2c'
require 'i2c/driver/i2c-dev'
require_relative 'midi'
require_relative 'mpr121'
require_relative 'bmp085'
require_relative 'fingering'

class OpenPipe
  attr_accessor :fingers, :previous_fingers, :control, :previous_control, :note,
    :previous_note, :noteoff, :pressure, :expression_off
  
  def initialize(path)
    @bmp085           = BMP085.new(path,0)
    @mpr121           = MPR121.new(path)
    @previous_note    = 0xFF
    @previous_fingers = 0xFF
    @previous_control = 0xFF
    @corrective       = nil
    @pressure         = 0x00
    @expression_off   = nil 
    @midi             = UniMIDI::Output.use(:first)
    @midi.puts(0xB0, MIDI::PC_SOSTENUTO_PEDAL, 1) if @mpr121.connect?
  end
  
  def run
    # TODO: Traed
    if @bmp085.connect?
      read_pressure
      # Bless
      if self.expression_off && self.pressure < 0
        @midi.puts(MIDI::CC,MIDI::CC_EXPRESSION, 0)
        self.expression_off = false
      elsif self.pressure > 0
        @midi.puts(MIDI::CC,MIDI::CC_EXPRESSION, self.pressure)
        self.expression_off = true
      end
    end
    
    # TODO: Thread
    if @mpr121.connect?
      read_fingers
      # Pipe 
      if (self.fingers != self.previous_fingers) ||
          (self.control != self.previous_control)
      
        self.previous_fingers = self.fingers
        if (self.control & 1)
          self.note = self.fingers_to_note(fingers)
          self.noteoff = true
          if (self.note != self.previous_note)
            @midi.puts(MIDI::NOTE_OFF,self.previous_note,0)
            @midi.puts(MIDI::NOTE_ON,self.note, 127)
            self.previous_note = self.note
          end
        else
          @midi.puts(MIDI::NOTE_OFF, self.note) if noteoff
        end
      end
    end 
  end

  def pressure_calibration
    values = []
    cycle = 50
    cycle.times do
      values << @bmp085.read_pressure
    end
    @corrective = (values.inject(&:+) / cycle) + 25
  end
  
  def read_pressure()
    buffer = []
    pressure_calibration() unless @corrective
    if @corrective
      pressure = @bmp085.read_pressure
      self.pressure = (pressure - @corrective) / 19
      self.pressure = 127 if self.pressure > 127
    end
  end
  
  def read_fingers()
    sensors = @mpr121.touched()
    self.fingers = (((sensors[0] & (1 << 0)) >> 0) |
      ((sensors[0] & (1 << 1)) >> 0) |
      ((sensors[0] & (1 << 2)) >> 0) |
      ((sensors[0] & (1 << 4)) >> 1) |
      ((sensors[0] & (1 << 7)) >> 3) |
      ((sensors[0] & (1 << 6)) >> 1) |
      ((sensors[1] & (1 << 2)) << 4) |
      ((sensors[1] & (1 << 1)) << 6))
    self.control = ((sensors[0] & (1 << 5)) >> 5)
  end
  
  def fingers_to_note(position)
    note = 0
    fingering_table = fingering_tables()
    base = fingering_tables()[0]
    row = 0
    index = 2
    while(fingering_table[index] !=  0xFFFFFFFF) do
      row = fingering_table[index]
      if ( row & 0x80000000) && ( row & 0x80000000) != 0
        # TODO
        row = (row & ~0x80000000)
        if ((position & (row & 0xFFFF)) == (row >> 16))
          # Jump over following fingering positions (if they exist)
          while((fingering_table[index] & 0x80000000) &&
            (fingering_table[index] & 0x80000000) != 0)
            index += 1
          end
          note = (fingering_table[index] >> 24) & 0xFF
          
          return base + note
        end
      end
      index += 1
    end
    return 0xFF
  end

  def fingering_tables
    # TODO: move in the fingering_table difinition file
    gaita_galega = [
	71,72,48,
	0x80FFFEFF, 0x00000000,
	0x80FEFEFF, 0x01000000,
	0x80FDFEFF, 0x02000000,
	0x80FCFEFF, 0x03000000,
	0x80FAFEFF, 0x04000000,
	0x80F8FEFE, 0x80FBFEFF, 0x05000000,
	0x80F0FEF8, 0x80F6FEFE, 0x06000000,
	0x80E8FEFB, 0x80EFFEFF, 0x07000000,
	0x80E0FEF8, 0x80EEFEFF, 0x08000000,
	0x80D0FEF0, 0x09000000,
	0x80C0FEF0, 0x0A000000,
	0x80A0FEF0, 0x0B000000,
	0x8080FEF0, 0x807FFEFF, 0x80BFFEFF, 0x0C000000,
	0x8000FEF0, 0x807EFEFF, 0x80B0FEF1, 0x0D000000,
	0x807DFEFF, 0x0E000000,
	0x807CFEFF, 0x0F000000,
	0x807AFEFF, 0x10000000,
	0x8078FEFE, 0x807BFEFF, 0x11000000,
	0x8070FEF8, 0x12000000,
	0x8068FEFB, 0x806FFEFF, 0x13000000,
	0x8060FEF8, 0x806EFEFF, 0x14000000,
	0x8050FEF0, 0x15000000,
	0x8040FEF0, 0x16000000,
	0x8020FEF0, 0x17000000,
	0x803FFEFF, 0x18000000,
	0x803EFEFF, 0x19000000,
	0xFFFFFFFF
    ]

    gaita_asturiana = [
	71,72,48,
	0x80FFFEFF, 0x00000000,
	0x80FEFEFF, 0x01000000,
	0x80FDFEFF, 0x02000000,
	0x80FCFEFF, 0x03000000,
	0x80F8FEFF, 0x04000000,
	0x80FAFEFF, 0x05000000,
	0x80F6FEFF, 0x06000000,
	0x80F7FEFF, 0x07000000,
	0x80EEFEFF, 0x80EAFEFF, 0x80E6FEFF, 0x08000000,
	0x80C6FEFF, 0x09000000,
	0x80CEFEFF, 0x80CFFEFF, 0x0A000000,
	0x808EFEFF, 0x0B000000,
	0x804EFEFF, 0x80BFFEFF, 0x807FFEFF, 0x0C000000,
	0x807EFEFF, 0x80BEFEFF, 0x0D000000,
	0x8036FEFF, 0x0E000000,
	0x807CFEFF, 0x80BCFEFF, 0x0F000000,
	0x8078FEFF, 0x10000000,
	0x807AFEFF, 0x11000000,
	0x8076FEFF, 0x12000000,
	0xFFFFFFFF
    ]
    great_highland_bagpipe = [
	67,69,57,
	0x80FFFEFF, 0x00000000,
	0x80FEFEFF, 0x02000000,
	0x80FCFEFF, 0x04000000,
	0x80F9FEFF, 0x80F8FEFC, 0x05000000,
	0x80F1FEFF, 0x80F0FEFC, 0x07000000,
	0x80EEFEFF, 0x80E0FEF0, 0x09000000,
	0x80CEFEFF, 0x80C0FEF0, 0x0A000000,
	0x808EFEFF, 0x8080FEF0, 0x0C000000,
	0x800EFEFF, 0x8000FEF0, 0x0E000000,
	0xFFFFFFFF
    ] 
    uilleann_pipe = [
	62,62,0,
	0x80FFFEFF, 0x00000000,
	0x80FCFEFF, 0x02000000,
	0x80FBFEFF, 0x04000000,
	0x80F3FEFF, 0x05000000,
	0x80EFFEFF, 0x07000000,
	0x80CFFEFF, 0x09000000,
	0x80BBFEFF, 0x0A000000,
	0x80BFFEFF, 0x0B000000,
	0x807FFEFF, 0x0C000000,
	0xFFFFFFFF    
    ]
    irish_flute = [
       50,50,0,
        0x807EFFFE, 0x00000000,
        0x807CFFFE, 0x02000000,
        0x8078FFFE, 0x04000000,
        0x8070FFFE, 0x05000000,
        0x8060FFFE, 0x07000000,
        0x8040FFFE, 0x09000000,
        0x8030FFFE, 0x0A000000,
        0x8080FFFE, 0x0B000000,
        0x80BEFFFE, 0x0C000000,
        0x80FCFFFE, 0x0E000000,
        0x80F8FFFE, 0x10000000,
        0x80F0FFFE, 0x11000000,
        0x80E0FFFE, 0x13000000,
        0x80C0FFFE, 0x15000000,
        0xFFFFFFFF
    ]

    normal_bagpipe = [
        58,58,0,
        0x80FFFFFF, 0x00000000,
        0x80FEFFFF, 0x02000000,
        0x80FCFFFF, 0x04000000,
        0x80F9FFFF, 0x06000000,
        0x80F1FFFF, 0x07000000,
        0x80EEFFFF, 0x09000000,
        0x80CEFFFF, 0x0B000000,
        0x808EFFFF, 0x0C000000,
        0x801EFFFF, 0x0E000000,
        0xFFFFFFFF
    ]

    # gaita_galega
    # gaita_asturiana
    # great_highland_bagpipe
    # irish_flute
    # normal_bagpipe
    return irish_flute 
  end
end

openpipe = OpenPipe.new('/dev/i2c-1')
loop do
  openpipe.run
end
