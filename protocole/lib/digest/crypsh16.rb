=begin
  * A Ruby implementation of Crypsh (CRYPtographic haSH)
  * Copyright (c) 2008 Cyril WACK
  * Code licensed under the BSD License:
      http://www.opensource.org/licenses/bsd-license.php
  * version: 0.1
=end

module Digest
  class Crypsh16

    require File.dirname(__FILE__) + '/64sbox_6x4-1'
    require File.dirname(__FILE__) + '/binary_methods-0.1'

    include BinaryMethods
    
    
    def initialize(str = 'The quick brown fox jumps over the lazy dog')
      bin = str2bin(str)
      message = length_padding(bin)
      @hash = construction(message, '10' * (BLOCKSIZE / 2))
    end

    def digest
      @hash
    end

    def hexdigest
      @hash.to_i(2).to_s(16)
    end


    private

    def length_padding(message)
      message += '1'
      message += '0' until message.length % (BLOCKSIZE * BLOCK_OF_SBOX) == 0
      message
    end

    # Merkle Damgard construction
    def construction(message, iv)
      image = iv
      block = message.scan(/([01]{1,#{BLOCKSIZE}})/)
      block.length.times do |id|
        preimage = image
        pleintext = padding_block( cut((block[id].to_s.to_i(2) + id).to_s(2), BLOCKSIZE), BLOCKSIZE)
        image = compression(pleintext, preimage)
      end
      image
    end

    # Miyaguchi Preneel compression
    def compression(block, preimage)
      xor(e(block, g(preimage)), block, preimage)
    end

    def xor(bin_a, bin_b, bin_c='0')
      int_a = bin_a.to_i(2)
      int_b = bin_b.to_i(2)
      int_c = bin_c.to_i(2)
      padding_block( (int_a ^ int_b ^ int_c).to_s(2), bin_a.length )
    end

    def g(preimage)
      keycipher = circular_shift_left(preimage.to_i(2), BLOCKSIZE, 1).to_s(2)
      padding_block(keycipher, BLOCKSIZE)
    end

    def e(blocktext, keycipher)
      NB_FEISTELNETWORK.times do
        blocktext = circular_shift_left(blocktext.to_i(2), BLOCKSIZE, FEISTELNETWORK / 2).to_s(2)
        blocktext = padding_block(blocktext, BLOCKSIZE)
        blocktext = round(blocktext, keycipher)
      end
      padding_block(blocktext, BLOCKSIZE)
    end

    def round(blocktext, keycipher)
      sub_msg = blocktext.scan(/([01]{1,#{FEISTELNETWORK}})/)
      sub_key = keycipher.scan(/([01]{1,#{FEISTELNETWORK}})/)
      ciphertext = ''
      NB_FEISTELNETWORK.times { |i| ciphertext += feistel_cipher(i, sub_msg[i].to_s, sub_key[i].to_s) }
      ciphertext
    end

    def feistel_cipher(id, plaintext, keycipher)
      a = plaintext[0 * BLOCK_OF_SBOX, BLOCK_OF_SBOX]
      b = plaintext[1 * BLOCK_OF_SBOX, BLOCK_OF_SBOX]
      NB_SBOX_BY_FEISTELNETWORK.times do |i|
        a = tuple(i + (id * NB_SBOX_BY_FEISTELNETWORK), a, b + keycipher[i * KEY_OF_SBOX, KEY_OF_SBOX])
        a, b = b, a
      end
      a + b
    end

    def tuple(id, a, input)
      output = sbox(id, input)
      xor(a, output)
    end

    def sbox(id, input)
      # row take the first and the last(s) bit(s) of input
      row = (input[0, 1] + input[INPUT_BY_SBOX - 1, 1]).to_i(2)
      #row = input[0, ROW_BY_SBOX].to_i(2)
      # col take some bits from the second bit of input
      col = input[1, OUTPUT_BY_SBOX].to_i(2)
      #col = input[ROW_BY_SBOX, OUTPUT_BY_SBOX].to_i(2)
      SBOX[id][row][col].to_s(2)
    end


    #
    # length of main blocks
    # unit: bit
    # minimum: FEISTELNETWORK (because BLOCKSIZE need to be >= FEISTELNETWORK)
    # BLOCKSIZE
    #
    BLOCKSIZE = 16

    #
    # size of s-box block
    # unit: bit
    # default value: 4
    #
    BLOCK_OF_SBOX = 4

    #
    # size of Feistel network block
    # unit: bit
    # default value: 2 * BLOCK_OF_SBOX
    #
    FEISTELNETWORK = 2 * BLOCK_OF_SBOX

    #
    # size of all s-box key
    # unit: bit
    # default value: FEISTELNETWORK / 4
    #
    KEY_OF_SBOX = FEISTELNETWORK / 4

    #
    # nb of s-box by Feistel network
    # unit: bit
    #
    NB_SBOX_BY_FEISTELNETWORK = FEISTELNETWORK / KEY_OF_SBOX

    #
    # nb of Feistel network
    # unit: bit
    #
    NB_FEISTELNETWORK = BLOCKSIZE / FEISTELNETWORK

    #
    # nb of s-box
    # unit: bit
    #
    NB_SBOX = NB_SBOX_BY_FEISTELNETWORK * NB_FEISTELNETWORK

    OUTPUT_BY_SBOX = BLOCK_OF_SBOX
    INPUT_BY_SBOX = OUTPUT_BY_SBOX + KEY_OF_SBOX
    ROW_BY_SBOX = INPUT_BY_SBOX - OUTPUT_BY_SBOX
    COL_BY_SBOX = OUTPUT_BY_SBOX

    VERSION = 0.1

  end
end
