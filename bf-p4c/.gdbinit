# vi: ft=python
set print static-members off
set print object
set unwindonsignal on
set unwind-on-terminating-exception on
set python print-stack full

if $_isvoid($bpnum)
    break ErrorReporter::emit_message
    disable
    break Util::P4CExceptionBase::P4CExceptionBase<>
    break Util::P4CExceptionBase::traceCreation
    break BaseCompileContext::getDefaultErrorDiagnosticAction
end

define pn
    if $argc == 2
        call ::dbprint($arg0 $arg1)
    else
        call ::dbprint($arg0)
    end
end
document pn
        print a IR::Node pointer
end
define d
    if $argc == 2
        call ::dump($arg0 $arg1)
    else
        call ::dump($arg0)
    end
end
document d
        dump IR::Node tree or Visitor::Context
end
define dnt
    if $argc == 2
        call ::dump_notype($arg0 $arg1)
    else
        call ::dump_notype($arg0)
    end
end
document dnt
        dump IR::Node tree, skipping 'type' fields
end
define dsrc
    if $argc == 2
        call ::dump_src($arg0 $arg1)
    else
        call ::dump_src($arg0)
    end
end
document dsrc
        dump IR::Node tree, skipping 'type' fields, and printing source info
end

python
import sys

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

class ActionFormatUsePrinter(object):
    "Print an ActionFormat::Use"
    def __init__(self, val):
        self.val = val
    def to_string(self):
        rv = ""
        try:
            rv = "ActionFormat::Use"
        except Exception as e:
            rv += "{crash: "+str(e)+"}\n"
        return rv

class cstringPrinter(object):
    "Print a cstring"
    def __init__(self, val):
        self.val = val
    def to_string(self):
        if self.val['str']:
            return str(self.val['str'])
        else:
            return "nullptr"

class SourceInfoPrinter(object):
    "Print a Util::SourceInfo"
    def __init__(self, val):
        self.val = val
    def to_string(self):
        return (str(self.val['start']['lineNumber']) + ':' +
                str(self.val['start']['columnNumber']) + '-' +
                str(self.val['end']['lineNumber']) + ':' +
                str(self.val['end']['columnNumber']))

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

class MemoriesPrinter(object):
    "Print a Memories object"
    def __init__(self, val):
        self.val = val
    def to_string(self):
        rv = "\ntc  eb  tib ab  srams       mapram  gw 2p\n"
        tables = {}
        alloc_names = [ 'tcam_use', 'sram_print_search_bus', 'tind_bus',
            'action_data_bus', 'sram_use', 'mapram_use', 'gateway_use' ]
        ptrs = [ self.val[arr]['data'] for arr in alloc_names ]
        rows = [ self.val[arr]['nrows'] for arr in alloc_names ]
        cols = [ self.val[arr]['ncols'] for arr in alloc_names ]
        ptrs.append(self.val['twoport_bus']['data'])
        rows.append(self.val['twoport_bus']['size'])
        cols.append(1)

        for r in range(0, max(rows)):
            for t in range(0, len(ptrs)) :
                for c in range(0, cols[t]):
                    if r >= rows[t]:
                        rv += ' '
                    else:
                        tbl = ptrs[t].dereference()['str']
                        if tbl:
                            name = tbl.string()
                            if name not in tables:
                                tables[name] = chr(ord('A') + len(tables))
                            rv += tables[name]
                        else:
                            rv += '.'
                        ptrs[t] += 1
                rv += '  '
            rv += "\n"
        for tbl,k in tables.items():
            rv += "   " + k + " " + tbl + "\n"
        return rv

class IXBarPrinter(object):
    "Print an IXBar object"
    def __init__(self, val):
        self.val = val
    def to_string(self):
        rv = "\nexact ixbar groups                  ternary ixbar groups\n"
        fields = {}
        ptrs = [ self.val['exact_use']['data'],
                 self.val['ternary_use']['data'],
                 self.val['byte_group_use']['data'] ]
        cols = [ int(self.val['exact_use']['ncols']),
                 int(self.val['ternary_use']['ncols']), 1 ]
        indir = [ 0, 1, 2, 1 ]
        pfx = [ "", "   ", " ", " " ]
        for r in range(0, 8):
            for t in range(0, len(indir)):
                if r > 5 and t > 0:
                    break
                rv += pfx[t]
                for c in range(0, cols[indir[t]]):
                    field = ptrs[indir[t]].dereference()
                    if c == 8:
                        rv += ' '
                    if field['first']['str']:
                        name = field['first']['str'].string()
                        if name not in fields:
                            if (len(fields) > 26):
                                fields[name] = chr(ord('A') + len(fields) - 26)
                            else:
                                fields[name] = chr(ord('a') + len(fields))
                        rv += fields[name]
                        rv += hex(int(field['second'])//8)[2]
                    else:
                        rv += '..'
                    ptrs[indir[t]] += 1
            rv += "\n"
        for field,k in fields.items():
            rv += "   " + k + " " + field + "\n"

        rv += "hash select bits   G  hd  /- hash dist bits ---\n"
        tables = {}
        ptrs = [ self.val['hash_index_use']['data'],
                 self.val['hash_single_bit_use']['data'],
                 self.val['hash_group_print_use']['data'],
                 self.val['hash_dist_use']['data'],
                 self.val['hash_dist_bit_use']['data'] ]
        cols = [ int(self.val['hash_index_use']['ncols']),
                 int(self.val['hash_single_bit_use']['ncols']),
                 1, int(self.val['hash_dist_use']['ncols']),
                 int(self.val['hash_dist_bit_use']['ncols']) ]
        pfx = [ "", " ", "  ", "  ", " " ]
        for r in range(0, 16):
            for t in range(0, len(ptrs)):
                rv += pfx[t]
                if r > 8 and t == 2:
                    rv += ' '
                    continue
                for c in range(0, cols[t]):
                    tbl = ptrs[t].dereference()
                    if tbl['str']:
                        name = tbl['str'].string()
                        if name not in tables:
                            tables[name] = chr(ord('A') + len(tables))
                        rv += tables[name]
                    else:
                        rv += '.'
                    ptrs[t] += 1
            rv += "\n"
        for tbl,k in tables.items():
            rv += "   " + k + " " + tbl + "\n"
        return rv;

def vec_begin(vec):
    return vec['_M_impl']['_M_start']
def vec_end(vec):
    return vec['_M_impl']['_M_finish']
def vec_size(vec):
    return int(vec_end(vec) - vec_begin(vec))
def vec_at(vec, i):
    return (vec_begin(vec) + i).dereference()

class safe_vector_Printer:
    "Print a safe_vector<>"
    def __init__(self, val):
        self.val = val
    def to_string(self):
        return "" if vec_size(self.val) > 0 else "[]"
    class _iter:
        def __init__(self, val):
            self.val = val
            self.size = vec_size(val)
            self.idx = 0
        def __iter__(self):
            return self
        def __next__(self):
            if self.idx >= self.size:
                raise StopIteration
            idx = self.idx
            self.idx = idx + 1
            return ("[%d]" % idx, vec_at(self.val, idx));
        def next(self): return self.__next__()
    def children(self):
        return self._iter(self.val)

def bvec_size(vec):
    sz = int(vec_end(vec)['_M_p'] - vec_begin(vec)['_M_p'])
    sz = sz * vec_begin(vec)['_M_p'].type.target().sizeof * 8
    sz = sz + int(vec_end(vec)['_M_offset'] - vec_begin(vec)['_M_offset'])
    return sz

class safe_vector_bool_Printer:
    "Print a safe_vector<bool>"
    def __init__(self, val):
        self.val = val
    def to_string(self):
        return "" if bvec_size(self.val) > 0 else "[]"
    class _iter:
        def __init__(self, val):
            self.val = val
            self.end = vec_end(val)
            self.ptr = vec_begin(val)['_M_p']
            self.offset = vec_begin(val)['_M_offset']
            self.idx = 0
        def __iter__(self):
            return self
        def __next__(self):
            if self.ptr == self.end['_M_p'] and self.offset >= self.end['_M_offset']:
                raise StopIteration
            ptr = self.ptr
            offset = self.offset
            idx = self.idx
            self.offset = offset + 1
            self.idx = idx + 1
            if self.offset == self.ptr.type.target().sizeof * 8:
                self.offset = 0
                self.ptr = self.ptr + 1
            return ("[%d]" % idx, (self.ptr.dereference() >> self.offset) & 1);
        def next(self): return self.__next__()
    def children(self):
        return self._iter(self.val)

class MemoriesUsePrinter(object):
    "Print a Memories::Use object"
    def __init__(self, val):
        self.val = val
    def to_string(self):
        types = [ 'EXACT', 'ATCAM', 'TERNARY', 'GATEWAY', 'TIND', 'IDLETIME', 'COUNTER',
                  'METER', 'SELECTOR', 'STATEFUL', 'ACTIONDATA' ]
        t = int(self.val['type'])
        if t >= 0 and t < len(types):
            t = types[t]
        else:
            t = "<type " + str(t) + ">"
        rv = "MemUse " + t + "("
        rows = vec_size(self.val['row'])
        for i in range(0, rows):
            if i > 0:
                rv += "; "
            row = vec_at(self.val['row'], i)
            rv += str(row['row'])
            if row['bus'] >= 0:
                rv += "," + str(row['bus'])
            rv += ": "
            for j in range(0, vec_size(row['col'])):
                if j > 0:
                    rv += ','
                rv += str(vec_at(row['col'], j))
            for j in range(0, vec_size(row['mapcol'])):
                if j > 0:
                    rv += ','
                else:
                    rv += " +"
                rv += str(vec_at(row['mapcol'], j))
        rv += ')'
        return rv

class IXBarUsePrinter(object):
    "Print an IXBar::Use object"
    use_types = [ "Exact", "Gateway", "Selector", "Meter", "StatefulAlu", "HashDist" ]
    def __init__(self, val):
        self.val = val
    def use_array(self, arr, indent):
        rv = ""
        for i in range(0, vec_size(arr)):
            rv += "\n" + indent + "use[" + str(i) +"]: "
            byte = vec_at(arr, i)
            rv += byte['name']['str'].string()
            rv += "[" + str(byte['lo']) + "]("
            rv += str(byte['loc']['group']) + ','
            rv += str(byte['loc']['byte']) + ')'
            if int(byte['flags']) != 0:
                rv += " flags=" + hex(int(byte['flags']))
            if int(byte['search_bus']) >= 0:
                rv += " search_bus=" + str(int(byte['search_bus']))
            if int(byte['match_index']) >= 0:
                rv += " match_index=" + str(int(byte['match_index']))
        return rv;
    def to_string(self):
        rv = ""
        try:
            type_tag = int(self.val['type'])
            rv = "<type %d>" % type_tag
            if self.val['ternary']:
                rv = "Ternary"
                if type_tag != 0: rv += "<%d>" % type_tag
            elif self.val['atcam']:
                rv = "ATcam"
                if type_tag != 0: rv += "<%d>" % type_tag
            elif type_tag >= 0 and type_tag < len(self.use_types):
                rv = self.use_types[type_tag]
            rv += self.use_array(self.val['use'], '   ')
            for i in range(0, 8):
                hti = self.val['hash_table_inputs'][i]
                if hti != 0:
                    rv += "\n   hash_group[%d]: " % i
                    j = 0
                    while hti > 0:
                        if hti % 2 != 0:
                            rv += "%d " % j
                        j += 1
                        hti /= 2
            for i in range(0, vec_size(self.val['bit_use'])):
                rv += "\n   bit_use[" + str(i) +"]: "
                bits = vec_at(self.val['bit_use'], i)
                rv += str(bits['group']) + ':' + str(bits['bit']+40) + ': '
                rv += bits['field']['str'].string()
                rv += "(" + str(bits['lo'])
                if bits['width'] > 1:
                    rv += ".." + str(bits['lo'] + bits['width'] - 1)
                rv += ")"
            for i in range(0, vec_size(self.val['way_use'])):
                rv += "\n   way_use[" + str(i) +"]: "
                way = vec_at(self.val['way_use'], i)
                rv += "[%d:%d:%x]" % (int(way['group']), int(way['slice']), int(way['mask']))
            #for i in range(0, vec_size(self.val['select_use'])):
            #    rv += "\n   sel_use[" + str(i) +"]: "
            #    sel = vec_at(self.val['select_use'], i)
            #    rv += "%d:%x - %s" % (int(sel['group']), int(sel['bit_mask']), str(sel['alg']))
            mah = self.val['meter_alu_hash']
            if mah['allocated']:
                rv += "\n   meter_alu_hash: group=" + str(mah['group'])
            hdh = self.val['hash_dist_hash']
            if hdh['allocated']:
                rv += "\n   hash_dist_hash: unit=" + str(hdh['unit'])
                rv += " group=" + str(hdh['group'])
                rv += " slice=" + str(hdh['slice'])
                rv += " bit_mask=" + str(hdh['bit_mask'])
                rv += " algorithm=" + str(hdh['algorithm'])
            rv += "\n"
        except Exception as e:
            rv += "{crash: "+str(e)+"}\n"
        return rv;

class PHVBitPrinter(object):
    "Print a PHV::Bit object"
    def __init__(self, val):
        self.val = val
    def to_string(self):
        return self.val['first']['str'].string() + "[" + str(self.val['second']) + "]"


class PHVContainerPrinter(object):
    "Print a PHV::Container object"
    container_kinds = [ "T", "D", "M", "" ]
    container_sizes = { 8: "B", 16: "H", 32: "W" }
    def __init__(self, val):
        self.val = val
    def to_string(self):
        tk = int(self.val['type_']['kind_'])
        ts = int(self.val['type_']['size_'])
        if tk < 0 or tk >= len(self.container_kinds) or not ts in self.container_sizes:
            return "<invalid PHV::Container>"
        rv = self.container_kinds[tk] + self.container_sizes[ts] + str(self.val['index_'])
        return rv;

class SlicePrinter(object):
    "Print a Slice object"
    def __init__(self, val):
        self.val = val
    def to_string(self):
        field = self.val['field']
        if field == 0:
            name = PHVContainerPrinter(self.val['reg']).to_string()
        else:
            name = str(field['name']['str'])
        return name + '(' + str(self.val['lo']) + ".." + str(self.val['hi']) + ')'

class UniqueIdPrinter(object):
    "Print a UniqueId object"
    speciality = [ "", "$stcam", "$dleft" ]
    a_id_type = [ "", "tind", "idletime", "stats", "meter", "selector", "salu", "action_data" ]
    def __init__(self, val):
        self.val = val
    def to_string(self):
        rv = self.val['name']['str'].string()
        if self.val['speciality'] >= 0 and self.val['speciality'] < len(self.speciality):
            rv += self.speciality[self.val['speciality']]
        else:
            rv += "$spec<" + str(self.val['speciality']) + ">";
        if self.val['logical_table'] != -1:
            rv += "$lt" + str(self.val['logical_table'])
        if self.val['stage_table'] != -1:
            rv += "$st" + str(self.val['stage_table'])
        if self.val['is_gw'] != 0:
            rv += "$gw"
        a_id = self.val['a_id']
        if a_id['type'] != 0:
            if a_id['type'] > 0 and a_id['type'] < len(self.a_id_type):
                rv += "$" + self.a_id_type[a_id['type']]
            else:
                rv += "$a<" + str(a_id['type']) + ">"
            if a_id['name']['str']:
                rv += "." + a_id['name']['str'].string()
        return rv

def find_pp(val):
    if str(val.type.tag).startswith('ordered_map<'):
        return ordered_map_Printer(val)
    if str(val.type.tag).startswith('safe_vector<bool'):
        return safe_vector_bool_Printer(val)
    if str(val.type.tag).startswith('safe_vector<'):
        return safe_vector_Printer(val)
    if val.type.tag == 'ActionFormat::Use':
        return ActionFormatUsePrinter(val)
    if val.type.tag == 'bitvec':
        return bitvecPrinter(val)
    if val.type.tag == 'cstring':
        return cstringPrinter(val)
    if val.type.tag == 'IXBar':
        return IXBarPrinter(val)
    if val.type.tag == 'IXBar::Use':
        return IXBarUsePrinter(val)
    if val.type.tag == 'Memories':
        return MemoriesPrinter(val)
    if val.type.tag == 'Memories::Use':
        return MemoriesUsePrinter(val)
    if val.type.tag == 'Util::SourceInfo':
        return SourceInfoPrinter(val)
    if val.type.tag == 'PHV::Bit':
        return PHVBitPrinter(val)
    if val.type.tag == 'PHV::Container':
        return PHVContainerPrinter(val)
    if val.type.tag == 'Slice':
        return SlicePrinter(val)
    if val.type.tag == 'UniqueId':
        return UniqueIdPrinter(val)
    return None

try:
    while gdb.pretty_printers[-1].__name__ == "find_pp":
        gdb.pretty_printers = gdb.pretty_printers[:-1]
except:
    pass

gdb.pretty_printers.append(find_pp)
end
