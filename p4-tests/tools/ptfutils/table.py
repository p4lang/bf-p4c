from .table_entry_builder import TableEntryBuilder

class Table:
    '''
    Representation of one BFRT/P4 table
    '''

    def __init__(self, name, device, table):
        '''
        Ctor

        Parameters:
        -----------
        name: string
            String identifier/name of the table
        device: grpccli.Target
            Device target the table belongs to
        table: BFRT table
            Raw table object
        '''
        self._name = name
        self._device = device
        self._table = table
    
    def getName(self):
        '''
        Get name of the table
        '''
        return self._name
    
    def createEntryBuilder(self, action):
        '''
        Create entry builder for this table

        Parameters:
        -----------
        action: string
            Name of the entry action
        '''
        return TableEntryBuilder(self, action)
    
    def cleanEntries(self):
        '''
        Clean table entries and reset the default action
        '''
        
        # -- remove table entries
        keys = []
        for (_, k) in self._table.entry_get(self._device):
            if k is not None:
                keys.append(k)
        self._table.entry_del(self._device, keys)

        # -- Reset default action. Ignore errors as not all
        #    tables supports this operation.
        try:
            self._table.default_entry_reset(self._device)
        except:
            pass
    
    def _addEntry(self, action, keys, data):
        raw_keys = self._table.make_key(keys)
        raw_data = self._table.make_data(data, action)
        self._table.entry_add(self._device, [raw_keys], [raw_data])