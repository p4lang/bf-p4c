import bfrt_grpc.client as grpccli

class TableEntryBuilder:
    '''
    Builder of a table entry

    This is a helper class which offers a simple interface to construct and
    register a table entry.
    '''

    def __init__(self, table, action):
        '''
        Ctor

        Parameters:
        -----------
        table: Table
            the table instance
        action: string
            name of the entry action
        '''
        self._table = table
        self._keys = []
        self._data = []
        self._action = action
    
    def appendByteKey(self, keyname, value):
        '''
        Append byte key

        Parameters:
        -----------
        keyname: string
            name of the key (P4 field)
        value: int
            the byte value
        '''
        self._keys.append(grpccli.KeyTuple(keyname, grpccli.to_bytes(value, 1)))
    
    def appendHalfWordKey(self, keyname, value):
        '''
        Append a half-word key (2 bytes)

        Parameters:
        -----------
        keyname: string
            name of the key (P4 field)
        value: int
            the key value
        '''
        self._keys.append(grpccli.KeyTuple(keyname, grpccli.to_bytes(value, 2)))

    def appendWordKey(self, keyname, value):
        '''
        Append a word key (4 bytes)

        Parameters:
        -----------
        keyname: string
            name of the key (P4 field)
        value: int
            the key value
        '''
        self._keys.append(grpccli.KeyTuple(keyname, grpccli.to_bytes(value, 4)))

    def appendByteData(self, argname, value):
        '''
        Append byte data
        
        Parameters:
        -----------
        argname: string
            name of the action parameter
        value: int
            the appended data value
        '''
        self._data.append(grpccli.DataTuple(argname, grpccli.to_bytes(value, 1)))
    
    def appendHalfWordData(self, argname, value):
        '''
        Append half-word data (2 B)
        
        Parameters:
        -----------
        argname: string
            name of the action parameter
        value: int
            the appended data value
        '''
        self._data.append(grpccli.DataTuple(argname, grpccli.to_bytes(value, 2)))
    
    def appendWordData(self, argname, value):
        '''
        Append word data (4 B)
        
        Parameters:
        -----------
        argname: string
            name of the action parameter
        value: int
            the appended data value
        '''
        self._data.append(grpccli.DataTuple(argname, grpccli.to_bytes(value, 4)))
    
    def commitEntry(self):
        '''
        Insert built table entry into the table
        '''
        self._table._addEntry(self._action, self._keys, self._data)
        self._keys = []
        self._data = []


