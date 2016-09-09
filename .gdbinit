set print object
set unwindonsignal on
set unwind-on-terminating-exception on

define d
    call ::dump($arg0)
end


python
class bitvecPrinter(object):
    "Print a bitvec"
    def __init__(self, val):
	self.val = val
    def to_string(self):
	data = self.val['data']
	rv = ""
	size = self.val['size']
	ptr = self.val['ptr']
	unitsize = ptr.type.target().sizeof * 8
	while size > 1:
	    data = ptr.dereference()
	    i = 0
	    while i < unitsize:
		if (rv.__len__() % 120 == 119): rv += ':'
		elif (rv.__len__() % 30 == 29): rv += ' '
		elif (rv.__len__() % 6 == 5): rv += '_'
		if (data & 1) == 0:
		    rv += "0"
		else:
		    rv += "1"
		data >>= 1
		i += 1
	    ptr += 1
	    size -= 1
	    data = ptr.dereference()
	while rv == "" or data > 0:
	    if (rv.__len__() % 6 == 5): rv += ' '
	    if (data & 1) == 0:
		rv += "0"
	    else:
		rv += "1"
	    data >>= 1
	return rv
class value_t_Printer(object):
    "Print a value_t"
    def __init__(self, val):
        self.val = val
    def to_string(self):
        typ = self.val['type']
        if typ == 0:  # tINT
            return str(self.val['i'])
        elif typ == 1:  # tBIGINT
            v = self.val['bi']
            data = v['data']
            size = v['size']
            val = 0
            while size > 0:
                val <<= 64
                val += data.dereference()
                size -= 1
                data += 1
            return str(val)
        elif typ == 2:  # tRANGE
            return str(self.val['lo']) + '..' + str(self.val['hi'])
        elif typ == 3:  # tSTR
            return self.val['s']
        elif typ == 4:  # tMATCH
            return self.val['m']
        elif typ == 5:  # tVEC
            return "vector of %d elements" % self.val['vec']['size']
        elif typ == 6:  # tMAP
            return "map of %d elements" % self.val['map']['size']
        elif typ == 7:  # tCMD
            cmd = self.val['vec']['data']
            count = self.val['vec']['size']
            rv = str(cmd.dereference())
            while count > 1:
                count -= 1
                cmd += 1
                rv += " " + str(cmd.dereference())
            return rv;
        else:
            return "<value_t type " + hex(typ) + ">"
    class _vec_iter:
        def __init__(self, data, size):
            self.data = data
            self.size = size
            self.counter = -1
        def __iter__(self):
            return self
        def __next__(self):
            self.counter += 1
            if self.counter >= self.size:
                raise StopIteration
            item = self.data.dereference()
            self.data += 1
            return ("[%d]" % self.counter, item)
        def next(self): return self.__next__()
    class _map_iter:
        def __init__(self, data, size):
            self.data = data
            self.size = size
        def __iter__(self):
            return self
        def __next__(self):
            self.size -= 1
            if self.size < 0:
                raise StopIteration
            item = self.data.dereference()
            self.data += 1
            return ("[" + str(item['key']) + "]", item['value'])
        def next(self): return self.__next__()

    class _not_iter:
        def __init__(self):
            pass
        def __iter__(self):
            return self
        def __next__(self):
            raise StopIteration
        def next(self): return self.__next__()
    def children(self):
        typ = self.val['type']
        if typ == 5:
            vec = self.val['vec']
            return self._vec_iter(vec['data'], vec['size'])
        elif typ == 6:
            map = self.val['map']
            return self._map_iter(map['data'], map['size'])
        else:
            return self._not_iter()
class value_t_VECTOR_Printer(object):
    "Print a VECTOR(value_t)"
    def __init__(self, val):
        self.val = val
    def to_string(self):
        return "vector of %d elements" % self.val['size']
    class _iter:
        def __init__(self, data, size):
            self.data = data
            self.size = size
            self.counter = -1
        def __iter__(self):
            return self
        def __next__(self):
            self.counter += 1
            if self.counter >= self.size:
                raise StopIteration
            item = self.data.dereference()
            self.data += 1
            return ("[%d]" % self.counter, item)
        def next(self): return self.__next__()
    def children(self):
        return self._iter(self.val['data'], self.val['size'])
class pair_t_VECTOR_Printer(object):
    "Print a VECTOR(pair_t)"
    def __init__(self, val):
        self.val = val
    def to_string(self):
        return "map of %d elements" % self.val['size']
    class _iter:
        def __init__(self, data, size):
            self.data = data
            self.size = size
        def __iter__(self):
            return self
        def __next__(self):
            self.size -= 1
            if self.size < 0:
                raise StopIteration
            item = self.data.dereference()
            self.data += 1
            return ("[" + str(item['key']) + "]", item['value'])
        def next(self): return self.__next__()
    def children(self):
        return self._iter(self.val['data'], self.val['size'])
def find_pp(val):
    if val.type.tag == 'bitvec':
	return bitvecPrinter(val)
    if val.type.tag == 'value_t':
	return value_t_Printer(val)
    if val.type.tag == 'value_t_VECTOR':
	return value_t_VECTOR_Printer(val)
    if val.type.tag == 'pair_t_VECTOR':
	return pair_t_VECTOR_Printer(val)
    return None
gdb.pretty_printers.append(find_pp)
end
