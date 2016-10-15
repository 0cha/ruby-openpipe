require 'pp'
require 'i2c'
require 'i2c/driver/i2c-dev'

class MPR121
  I2CADDR         = 0x5A
  TOUCHSTATUS_L   = 0x00
  TOUCHSTATUS_H   = 0x01
  FILTDATA_0L     = 0x04
  FILTDATA_0H     = 0x05
  BASELINE_0      = 0x1E
  MHDR            = 0x2B
  NHDR            = 0x2C
  NCLR            = 0x2D
  FDLR            = 0x2E
  MHDF            = 0x2F
  NHDF            = 0x30
  NCLF            = 0x31
  FDLF            = 0x32
  NHDT            = 0x33
  NCLT            = 0x34
  FDLT            = 0x35
  TOUCHTH_0       = 0x41
  RELEASETH_0     = 0x42
  DEBOUNCE        = 0x5B
  CONFIG1         = 0x5C
  CONFIG2         = 0x5D
  CHARGECURR_0    = 0x5F
  CHARGETIME_1    = 0x6C
  ECR             = 0x5E
  AUTOCONFIG0     = 0x7B
  AUTOCONFIG1     = 0x7C
  UPLIMIT         = 0x7D
  LOWLIMIT        = 0x7E
  TARGETLIMIT     = 0x7F
  GPIODIR         = 0x76
  GPIOEN          = 0x77
  GPIOSET         = 0x78
  GPIOCLR         = 0x79
  GPIOTOGGLE      = 0x7A
  SOFTRESET       = 0x80

  MAX_I2C_RETRIES = 5


  
  def initialize(path)
    @device = I2CDevice.new(address: I2CADDR, drive: I2CDevice::Driver::I2CDev.new(path))
    @address = I2CADDR
    device_check()
    reset() if connect?
  end

  def connect?
    return @connect
  end

  def device_check
    begin
      read(@addres)
      puts 'MPR121 is connected...'
      @connect = true
    rescue I2CDevice::I2CIOError
      puts 'MPR121 is disconnected'
      @connect = false
    end
  end

  def reset
    set_thresholds(1, 1)
    # Configure baseline filtering control registers.
    write(MHDR, 0x01)
    write(NHDR, 0x01)
    write(NCLR, 0x00)
    write(FDLR, 0x00)
    write(MHDF, 0x01)
    write(NHDF, 0x01)
    write(NCLF, 0xFF)
    write(FDLF, 0x02)

    write(CONFIG2, 0x00)
    write(ECR, 0x0c)
    
    # All done, everything succeeded!
    write(AUTOCONFIG0, 0x08)
    write(UPLIMIT,     0xc9)
    write(LOWLIMIT,    0x83)
    write(TARGETLIMIT, 0x85)
  end

  def set_thresholds(touch, release)
    if  (touch >= 0 && touch <= 255) &&
      (release >= 0 && release <= 255) 

      12.times do |i|
        write(TOUCHTH_0   + 2 * i, touch)
        write(RELEASETH_0 + 2 * i, release)
      end
    end
  end

  def filtered_data(pin)
    if pin >= 0 && pin < 12
      return read(FILTDATA_0L + pin * 2, 2)
    end
  end

  def baseline_data(pin)
    bl = read(BASELINE_0 + pin)
    return bl << 2
  end
 
  def touched
    data = read(TOUCHSTATUS_L, 2)
    return data
  end

  def write(register,param)
    @device.i2cset(register, param, 1)
  end

  def read(register,byte=1)
    data = @device.i2cget(register,byte).bytes
    result = byte == 1 ? data.first : data
    return result
  end
end
