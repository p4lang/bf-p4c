"""
TODO: document this file
"""
import struct
from copy import copy

class chip_object(object):
    """
    TODO: docstring
    """
    def __init__(self, addr, src_key):
        self.addr = addr
        self.src_key = src_key

    def add_offset (self, offset):
        self.addr += offset

class direct_reg(chip_object):
    """
    A single register write operation, of the format:

    4 bytes: "\0\0\0R"
    4 bytes: 32-bit PCIe address
    4 bytes: Data

    All fields little-endian
    """

    def __init__(self, addr, value, src_key=None):
        chip_object.__init__(self, addr, src_key)
        self.value=struct.pack("<I",value)

    def __str__(self):
        # TODO
        return hex(self.addr) + ": <TODO>"

    def deepcopy(self):
        return copy(self)

    def bytes(self):
        return "\0\0\0R" + struct.pack("<I",self.addr) + self.value

class indirect_reg(chip_object):
    """
    A single indirect register write operation, of the format:

    4 bytes: "\0\0\0I"
    8 bytes: 42-bit chip address
    4 bytes: Bit-length of word
    Following: Data

    All fields little-endian
    """
    def __init__(self, addr, value, width, src_key=None):
        chip_object.__init__(self, addr, src_key)
        self.width=width

        hexstr = hex(value).replace('0x','').replace('L','')
        if len(hexstr) % 2 != 0:
            hexstr = '0' + hexstr
        self.value=bytearray.fromhex(hexstr)
        self.value = self.value.rjust(self.width/8,chr(0))
        self.value.reverse()

    def __str__(self):
        # TODO
        return hex(self.addr) + ": <TODO>"

    def deepcopy(self):
        return copy(self)

    def bytes(self):
        # TODO: for now implement as a sequence of direct register writes
        #return "\0\0\0I" + struct.pack("<Q",self.addr) + struct.pack("<I",self.width) + self.value

        # Make sure to write pieces of the register starting from the
        # most-significant end, to ensure atomicity
        offset = (self.width/8) - 4
        byte_str = ""
        while offset >= 0:
            byte_str += "\0\0\0R" + struct.pack("<I",self.addr+offset) + self.value[offset:offset+4].ljust(4,chr(0))
            offset -= 4

        return byte_str

class dma_block(chip_object):
    """
    A single DMA block write operation, of the format:

    4 bytes: "\0\0\0D"
    8 bytes: 42-bit chip address
    4 bytes: Bit-length of word
    4 bytes: Number of words
    Following: Data, in 32-bit word chunks

    All fields little-endian
    """
    def __init__(self, addr, width, src_key=None):
        chip_object.__init__(self, addr, src_key)
        self.width=width
        self.values=[]

    def add_word(self, value):
        hexstr = hex(value).replace('0x','').replace('L','')

        if len(hexstr) % 2 != 0:
            hexstr = '0' + hexstr
        self.values.append(bytearray.fromhex(hexstr))
        self.values[-1] = self.values[-1].rjust(self.width/8,chr(0))
        self.values[-1].reverse()

    def __str__(self):
        # TODO
        return hex(self.addr) + ": <TODO>"
    
    def deepcopy(self):
        new = copy(self)
        new.values = new.values[:]
        return new

    def bytes(self):
        # TODO: generalize DMA writes larger than 128 bits
        if self.width == 256:
            self.width = 128
            new_values = []
            for value in self.values:
                new_values.append(value[0:16].rjust(128/8,chr(0)))
                new_values.append(value[16:32].rjust(128/8,chr(0)))
            self.values = new_values

        bytestr = "\0\0\0D" + struct.pack("<Q",self.addr) + struct.pack("<I",self.width) + struct.pack("<I",len(self.values))
        for value in self.values:
            bytestr += value
        return bytestr
