=begin
  * General binary methods library
  * Copyright (c) 2008 Cyril WACK
  * Code licensed under the BSD License:
      http://www.opensource.org/licenses/bsd-license.php
  * version: 0.1
=end

module BinaryMethods
  
  def str2bin(str)
    str.unpack('c*').collect { |x| sprintf('%02x', x) }.to_s.hex.to_s(2)
  end
  
  def bin2str(bin)
    bin.scan(/.{8}/).map { |x| x.to_i(2) }.pack('C*')
  end
  
  def padding_block(bin, length)
    while (bin.length < length)
      bin = '0' + bin
    end
    bin
  end
  
  def cut(bin, length)
    if bin.length > length:
      bin = bin[(bin.length - length), length]
    end
    bin
  end
  
  def bitmask(bits)
    ( 1 << bits ) - 1
  end
  
  def shift_left_width(value, register_width, bits)
    ( value << bits ) & bitmask(register_width)
  end
  
  def circular_shift_right(value, register_width, bits)
    remaining_bits = register_width - bits
    top = shift_left_width(value, register_width, remaining_bits)
    bottom = value >> bits
    top | bottom
  end
  
  def circular_shift_left(value, register_width, bits)
    remaining_bits = register_width - bits
    top = shift_left_width(value, register_width, bits)
    bottom = value >> remaining_bits
    top | bottom
  end
  
  
  VERSION = 0.1
  
end
