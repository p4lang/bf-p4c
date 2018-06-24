# vim: ft=python
set print object
set unwindonsignal on
set unwind-on-terminating-exception on

define d
    call ::dump($arg0)
end


python
def template_split(s):
    parts = []
    bracket_level = 0
    current = []
    for c in (s):
        if c == "," and bracket_level == 1:
            parts.append("".join(current))
            current = []
        else:
            if c == '>':
                bracket_level -= 1
            if bracket_level > 0:
                current.append(c)
            if c == '<':
                bracket_level += 1
    parts.append("".join(current))
    return parts

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
            if (rv.__len__() % 120 == 119): rv += ':'
            elif (rv.__len__() % 30 == 29): rv += ' '
            elif (rv.__len__() % 6 == 5): rv += '_'
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
            v = self.val['bigi']
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
            rv += "("
            while count > 1:
                count -= 1
                cmd += 1
                rv += str(cmd.dereference())
                if count > 1:
                    rv += ", "
            rv += ")"
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
class ordered_map_Printer:
    "Print an ordered_map<>"
    def __init__(self, val):
        self.val = val
        self.args = template_split(val.type.tag)
        self.eltype = gdb.lookup_type('std::pair<' + self.args[0] + ' const,' + self.args[1] + '>')
    def to_string(self):
        return "ordered_map<..>"
    class _iter:
        def __init__(self, eltype, it, e):
            self.eltype = eltype
            self.it = it
            self.e = e
        def __iter__(self):
            return self
        def __next__(self):
            if self.it == self.e:
                raise StopIteration
            el = (self.it + 1).cast(self.eltype.pointer()).dereference()
            self.it = self.it.dereference()['_M_next']
            return ("[" + str(el['first']) + "]", el['second']);
        def next(self): return self.__next__()
    def children(self):
        return self._iter(self.eltype, self.val['data']['_M_impl']['_M_node']['_M_next'],
                          self.val['data']['_M_impl']['_M_node'].address)
class InputXbar_Group_Printer:
    "Print an InputXbar::Group"
    def __init__(self, val):
        self.val = val
    def to_string(self):
        if self.val['type'] == 0:
            rv = 'exact'
        elif self.val['type'] == 1:
            rv = 'ternary'
        elif self.val['type'] == 2:
            rv = 'byte'
        else:
            rv = '<bad type 0x%x>' % int(self.val['type'])
        rv += ' group ' + str(self.val['index'])
        return rv
class ActionBus_Source_Printer:
    "Print an ActionBus::Source"
    def __init__(self, val):
        self.val = val
    def to_string(self):
        try:
            if self.val['type'] == 0:
                rv = "None"
            elif self.val['type'] == 1:
                rv = "Field"
                rv += " %s" % str(self.val['field'])
            elif self.val['type'] == 2:
                rv = "HashDist"
            elif self.val['type'] == 3:
                rv = "RandomGen"
            elif self.val['type'] == 4:
                rv = "TableOutput"
            elif self.val['type'] == 5:
                rv = "TableColor"
            elif self.val['type'] == 6:
                rv = "NameRef"
            elif self.val['type'] == 7:
                rv = "ColorRef"
            else:
                rv = '<bad type 0x%x>' % int(self.val['type'])
        except Exception as e:
                    rv += "{crash: "+str(e)+"}"
        return rv
    class _iter:
        def __init__(self, val, type):
            self.val = val
            self.type = type
            self.done = type < 1 or type > 6
        def __iter__(self):
            return self
        def __next__(self):
            if self.done:
                raise StopIteration
            self.done = True
            if type == 1:
                return ("field", self.val['field'])
            elif type == 2:
                return ("hd", self.val['hd'])
            elif type == 4 or type == 5:
                return ("table", self.val['table'])
            elif type == 6 or type == 7:
                return ("name_ref", self.val['name_ref'])
            else:
                raise StopIteration
        def next(self): return self.__next__()
    def children(self):
        return self._iter(self.val, int(self.val['type']))


def find_pp(val):
    if val.type.tag == 'bitvec':
        return bitvecPrinter(val)
    if val.type.tag == 'value_t':
        return value_t_Printer(val)
    if val.type.tag == 'value_t_VECTOR':
        return value_t_VECTOR_Printer(val)
    if val.type.tag == 'pair_t_VECTOR':
        return pair_t_VECTOR_Printer(val)
    if str(val.type.tag).startswith('ordered_map<'):
        return ordered_map_Printer(val)
    if val.type.tag == 'InputXbar::Group':
        return InputXbar_Group_Printer(val)
    if val.type.tag == 'ActionBus::Source':
        return ActionBus_Source_Printer(val)
    return None

#gdb.pretty_printers = [ gdb.pretty_printers[0] ]  # uncomment if reloading
gdb.pretty_printers.append(find_pp)
end
