import functools

@functools.total_ordering
class Port:
    '''
    An identifier of a switch port. It consists of index of the device and index of
    the physical port.
    '''

    def __init__(self, port, device = None):
        if isinstance(port, int):
            if device is None:
                device = 0
            self._port = port
            self._device = device
        elif isinstance(port, Port):
            self._port = port._port
            self._device = port._device
        else:
            raise TypeError("Invalid type of the port object")
    
    @staticmethod
    def createPort(device, port):
        '''
        Create new Port object from device and port indexes
        '''
        return Port(port, device)

    def _is_valid_operand(self, other):
        return hasattr(other, "_port") and hasattr(other, "_device")
    
    def __hash__(self):
        return hash((self._port, self._device))
    
    def __eq__(self, other):
        if not self._is_valid_operand(other):
            return NotImplemented
        return (self._port == other._port and self._device == other._device)

    def __lt__(self, other):
        if not self._is_valid_operand(other):
            return NotImplemented
        return (self._device, self._port) < (other._device, other._port)
    
    def __str__(self):
        return "(device={}, port={})".format(self._device, self._port)
    
    def __repr__(self):
        return "Port({}, {})".format(self._device, self._port)

    def device(self):
        '''
        Get index of the device
        '''
        return self._device
    
    def port(self):
        '''
        Get index of the port
        '''
        return self._port
