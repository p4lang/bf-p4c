"""
csr: Code dealing with compiler-facing JSON files and raw Semifore CSV files

TODO: explain how to generate Semifore CSV files properly
"""

import csv
import os.path
import hashlib
import copy
import string

from operator import mul
from types import StringTypes

import chip

########################################################################
## Utility functions

def array_str(array_idx):
    """
    Given a list of integers, return a string containing those integers in []
    for generating a C++ index expression
    """
    if array_idx is None: return ""
    return reduce(lambda x,y: x+"[%i]"%y,array_idx,"")

def product(seq):
    """
    Given a list of integers, return their product

    @param   seq     A list of integers
    @return          The product of the integers in the list
    """
    return reduce(mul, seq, 1 )

def nd_array_loop(count, data, func, context=None, current_dim=0):
    """
    Given an N-dimensional list of objects, drill down to the inner-most lists
    and call func() on them. Essentially a variable-depth nested for loop. The
    reason func is called on the inner-most dimension and not each object itself
    is to allow some state to be kept across iterations of the inner-most loop
    (for example, like an address offset counter).

    @param   count  A list of integers recording the number of elements
                    in each dimension of the data. Should be N elements
                    long.
    @param   data   The N-dimensional list of data
    @param   func   A function that takes two arguments, which is called on
                    every list of the inner-most dimension. Its arguments are,
                    in order:
                        - The inner-most list to be processed
                        - The 'context' of this function call: a list of
                          integers recording at which index in each dimension
                          the provided list is from. The last element in this
                          list is uninitialized and intended to hold the
                          iteration count of the inner-most loop.

                          This list is SHARED ACROSS ALL INVOCATIONS of func(),
                          so while it's safe to modify it should be copied if
                          intended to be stored beyond the current scope.
    """
    if context == None:
        context = [0]*len(count)
    if current_dim < len(count)-1:
        for idx in range(0, count[current_dim]):
            context[current_dim] = idx
            nd_array_loop(count, None if data is None else data[idx], func, context, current_dim+1)
    else:
        func(data, context)

def count_array_loop(count, func, context=None, current_dim=0):
    """
    Given a vector of dimensions, call func for each possible legal index
    Essentially a variable-depth nested for loop.

    @param   count  A list of integers recording the number of elements
                    in each dimension of the data. Should be N elements
                    long.
    @param   func   A function that takes one argument, which is called on
                    on every legal set of indexes of the given dimensions
                    Its argument is the 'context' of this function call: a list of
                    integers recording at which index in each dimension.

                      This list is SHARED ACROSS ALL INVOCATIONS of func(),
                      so while it's safe to modify it should be copied if
                      intended to be stored beyond the current scope.
    """
    if context == None:
        context = [0]*len(count)
    if current_dim < len(count):
        for idx in range(0, count[current_dim]):
            context[current_dim] = idx
            count_array_loop(count, func, context, current_dim+1)
    else:
        func(context)

########################################################################
## Structures

class CsrException (Exception):
    """
    An exception that occured while crunching malformed data according to the
    given chip schema. An exception handler in walle.py will catch these
    exceptions and then attempt to print a "traceback" recording where in the
    chip schema the exception occured.

    This traceback is maintained by keeping a local variable called 'path' in
    any scope where a CsrException may be raised. 'path' is a list of
    traversal_history objects.
    """
    pass

class traversal_history (object):
    """
    A class which records part of Walle's traversal through input JSON data. A
    single traversal_history corresponds to the traversal of one JSON file.

    Attributes:
    @attr template_name
        The value at the top level "_name" key of the file currently being
        processed
    @attr path
        An ordered list of keys and list indices visited in the current
        traversal of this file.
        If we drill down into a dictionary at key "a", push "a" onto the list.
        If we access elements of a list, push a tuple recording the index at
        each dimension of the list and then the list name. Eg,
            [(4,),"a"] to represent a[4]
            [(1,2,3),"b"] to represent b[1][2][3]
    """
    def __init__(self, template_name):
        self.template_name = template_name
        self.path = []

class binary_cache(object):
    """
    A class used to store flat chip_obj lists, each corresponding to one JSON
    file. The "_name" at the top of each JSON is used to index into the cache.
    Requesting a JSON file from here will crunch it into binary if it hasn't
    been already.
    """
    def __init__(self, schema):
        self.schema = schema
        self.templates = {}
        self.binary_templates = {}

    def get_type(self, key):
        """
        Get the addressmap name that the binary data at the given key
        corresponds to, of the form "section_name.addressmap_name".
        """
        return self.templates[key]["_type"]

    def get_data (self, key, path=None):
        """
        Return a list of objects inheriting from chip.chip_obj, representing
        the write operations that must be done in the hardware to program a
        hardware object of the given JSON file's "_type"

        These lists are a deep copy of the one stored internally, so it is safe
        to modify them
        """
        if path==None:
            path = []

        if key not in self.binary_templates:
            obj_section, obj_type = self.templates[key]["_type"].split(".")
            obj_schema = self.schema[obj_section][obj_type]
            # TODO: There used to be a first deepcopy here, before the one in the
            #       return statement. 99% sure it was unnecessary, but if things
            #       seem broken revisit this
            path.append(traversal_history(key))
            self.binary_templates[key] = obj_schema.generate_binary(self.templates[key], self, path)
            path.pop()

        binary_data_copy = []
        for chip_obj in self.binary_templates[key]:
            binary_data_copy.append(chip_obj.deepcopy())
        return binary_data_copy

class csr_object (object):
    """
    Base class for objects in a Semifore register hierarchy

    A Semifore object array is still represented as one csr_object instance,
    albeit with a "count" attribute expressing how many hardware objects this
    Semifore node actually corresponds to.

    Since all objects in Semifore have names and can be arrays, all csr_objects
    have name and count attributes. Since arrays can be multidimensional,
    count is _always_ a tuple of array sizes, even if that tuple has only one
    element. Single elements will have a count of (1,).
    """

    def __init__(self, name, count):
        self.name = name
        self.count = count

    def replicate (self, templatized_self):
        if self.count != (1,):
            last_dim_obj = templatized_self
            for dim in reversed(self.count):
                last_dim_obj = [copy.deepcopy(last_dim_obj) for _ in range(0,dim)]
            return last_dim_obj
        else:
            return templatized_self

    def is_field(self):
        return False
    def is_singleton(self):
        return False
    def singleton_obj(self):
        return self

class csr_composite_object (csr_object):
    """
    Base class for composite (non-leaf) CSR objects.  All such objects have one
    or more children
    """
    def __init__(self, name, count):
        csr_object.__init__(self, name, count)
    def children(self):
        raise CsrException("Unimplemented abstract method for " + type(self))

    def gen_method_declarator(self, outfile, args, rtype, classname, name, argdecls, suffix):
        outfile.write("%s " % rtype)
        if args.gen_decl == 'defn': outfile.write("%s::" % classname)
        outfile.write("%s(" % name)
        first = True
        for a in argdecls:
            if not first:
                outfile.write(", ")
            if type(a) is tuple:
                outfile.write(a[0])
                if args.gen_decl != 'defn':
                    outfile.write(" = " + a[1])
            else:
                outfile.write(a)
            first = False
        outfile.write(")")
        if suffix != '':
            outfile.write(" %s" % suffix)
        if args.gen_decl == 'decl':
            outfile.write(";\n")
            return True
        outfile.write(" {\n")
        return False

    def gen_emit_method(self, outfile, args, schema, classname, name, nameargs, indent):
        outfile.write(indent)
        argdecls = ["std::ostream &out"]
        for idx, argtype in enumerate(nameargs):
            argdecls.append("%sna%d" % (argtype, idx))
        if args.gen_decl == 'defn':
            argdecls.append("indent_t indent")
        else:
            argdecls.append("indent_t indent = 1")
        if self.gen_method_declarator(outfile, args, "void", classname,
                                      "emit_json", argdecls, "const"):
            return
        indent += "  "
        if args.enable_disable and not self.top_level():
            outfile.write("%sif (disabled_) {\n" % indent)
            outfile.write('%s  out << "0";\n' % indent)
            outfile.write("%s  return; }\n" % indent)
        outfile.write("%sout << '{' << std::endl;\n" % indent)
        first = True
        if self.top_level():
            if len(nameargs) > 0:
                tmplen = len(name) + len(nameargs)*10 + 32
                outfile.write("%schar tmp[%d];\n" % (indent, tmplen))
                outfile.write('%ssnprintf(tmp, sizeof(tmp), "%s"' % (indent, name))
                for i in range(0, len(nameargs)):
                    outfile.write(", na%d" % i)
                outfile.write(");\n")
                outfile.write('%sout << indent << "\\"_name\\": \\"" << tmp << "\\"";\n' % indent)
            else:
                outfile.write('%sout << indent << "\\"_name\\": \\"%s\\"";\n' % (indent, name))
            outfile.write('%sout << ", \\n";\n' % indent)
            outfile.write('%sout << indent << "\\"_reg_version\\": \\"%s\\"";\n' %
                          (indent, schema["_reg_version"]))
            outfile.write('%sout << ", \\n";\n' % indent)
            outfile.write('%sout << indent << "\\"_schema_hash\\": \\"%s\\"";\n' %
                          (indent, schema["_schema_hash"]))
            outfile.write('%sout << ", \\n";\n' % indent)
            outfile.write('%sout << indent << "\\"_section\\": \\"%s\\"";\n' %
                          (indent, self.parent))
            outfile.write('%sout << ", \\n";\n' % indent)
            outfile.write('%sout << indent << "\\"_type\\": \\"%s.%s\\"";\n' %
                          (indent, self.parent, self.name))
            outfile.write('%sout << ", \\n";\n' % indent)
            outfile.write('%sout << indent << "\\"_walle_version\\": \\"%s\\"";\n' %
                          (indent, schema["_walle_version"]))
            first = False
        for a in sorted(self.children(), key=lambda a: a.name):
            if not first:
                outfile.write('%sout << ", \\n";\n' % indent)
            outfile.write('%sout << indent << "\\"%s\\": ";\n' % (indent, a.name))
            if a.disabled() and not args.expand_disabled_vector:
                outfile.write('%sout << "0";\n' % indent)
                continue
            field_name = a.name
            if field_name in args.cpp_reserved:
                field_name += '_'
            if a.count != (1,):
                for idx_num, idx in enumerate(a.count):
                    if args.enable_disable and args.checked_array and not a.disabled():
                        outfile.write("%sif (%s" % (indent, field_name))
                        for i in range(0, idx_num):
                            outfile.write("[i%d]" % i)
                        outfile.write(".disabled()) {\n")
                        outfile.write('%s  out << "0";\n' % indent)
                        outfile.write("%s} else {\n" % indent)
                        indent += '  '
                    outfile.write('%sout << "[\\n" << ++indent;\n' % indent)
                    outfile.write('%sfor (int i%d = 0; i%d < %d; i%d++) { \n' %
                                  (indent, idx_num, idx_num, idx, idx_num))
                    outfile.write('%s  if (i%d) out << ", \\n" << indent;\n' % (indent, idx_num))
                    indent += '  '
            single = a.singleton_obj()
            if single != a:
                outfile.write('%sout << "{\\n" << indent+1 << "\\"%s\\": " << %s' %
                              (indent, a.name, field_name))
                if a.count != (1,):
                    for i in range(0, len(a.count)):
                        outfile.write("[i%d]" % i)
                outfile.write(" << '\\n';\n")
                outfile.write("%sout << indent << '}';\n" % indent)
            elif a.is_field() or a.top_level():
                outfile.write("%sout << %s" % (indent, field_name))
                if a.count != (1,):
                    for i in range(0, len(a.count)):
                        outfile.write("[i%d]" % i)
                outfile.write(";\n")
            elif a.disabled():
                outfile.write('%sout << 0;\n' % indent)
            else:
                outfile.write("%s%s" % (indent, field_name))
                if a.count != (1,):
                    for i in range(0, len(a.count)):
                        outfile.write("[i%d]" % i)
                outfile.write(".emit_json(out, indent+1);\n")
            if a.count != (1,):
                for i in range(0, len(a.count)):
                    indent = indent[2:]
                    outfile.write("%s}\n" % indent)
                    outfile.write("%sout << '\\n' << --indent << ']';\n" % indent)
                    if args.enable_disable and args.checked_array and not a.disabled():
                        indent = indent[2:]
                        outfile.write("%s}\n" %indent)
            first = False
        outfile.write("%sout << '\\n' << indent-1 << \"}\";\n" % indent)
        indent = indent[2:]
        outfile.write("%s}\n" % indent)

    def gen_emit_binary_method(self, outfile, args, classname, indent):
        def child_name(child):
            name = child.name
            if name in args.cpp_reserved:
                name += '_'
            return name
        def field_name(child):
            name = child_name(child)
            if child.count != (1,):
                for i in range(0, len(child.count)):
                    name += "[j%d]" % i
            return name
        outfile.write(indent)
        if self.gen_method_declarator(outfile, args, "void", classname, "emit_binary",
                ["std::ostream &out", "uint64_t a"], "const"):
            return
        indent += "  "
        if args.enable_disable:
            outfile.write("%sif (disabled_) return;\n" % indent)
        root_parent = self.parent
        while type(root_parent) is not str:
            root_parent = root_parent.parent
        addr_decl = "auto "
        for a in self.children():
            addr_var = "a"
            if a.disabled(): continue
            if root_parent=="memories":
                indirect = True
                width_unit = 128
                address_unit = 16
                type_tag = 'D'
            elif a.name in args.write_dma:
                indirect = True
                width_unit = 32
                address_unit = 1
                type_tag = 'B'
            else:
                indirect = False
                width_unit = 32
                address_unit = 1
                type_tag = 'R'
            if args.enable_disable:
                outfile.write("%sif (!%s.disabled()) {\n" % (indent, child_name(a)))
                indent += '  '
            if indirect and type(a) is reg:
                outfile.write("%sout << binout::tag('%s') << binout::byte8" % (indent, type_tag) +
                              "(a + 0x%x) << binout::byte4(%d) << binout::byte4(%d);\n" %
                              (a.offset//address_unit, width_unit,
                               product(a.count) * a.width // width_unit))
            if a.count != (1,):
                if args.enable_disable:
                    outfile.write("%sauto addr = a;\n" % indent)
                else:
                    outfile.write("%s%saddr = a;\n" % (indent, addr_decl))
                    addr_decl = "";
                addr_var = "addr"
                for idx_num, idx in enumerate(a.count):
                    outfile.write('%sfor (int j%d = 0; j%d < %d; j%d++) { \n' %
                                  (indent, idx_num, idx_num, idx, idx_num))
                    indent += '  '
            single = a.singleton_obj()
            if not indirect and single != a:
                # FIXME -- should check each element being written singly to see if its
                #  disabled and not write it if so?  The generate_binary code does not
                #  do that, so we don't emit C++ code to do it either.
                #  Would it cause problems for register arrays that are actually wideregs
                #  under the hood?  See 3.2.1.1 in the Tofino Switch Architecture doc.
                #outfile.write("%sif (!%s.disabled()) {\n" % (indent, field_name(a)))
                #indent += '  '
                if single.msb >= 64:
                    for w in (range(single.msb//32, -1, -1) 
                              if args.reverse_write else
                              range(0, single.msb//32 + 1)):
                        outfile.write("%sout << binout::tag('R') << binout::byte4" % indent +
                                      "(%s + 0x%x) << binout::byte4(%s.value.getrange(%d, 32));\n" %
                                      (addr_var, a.offset//address_unit + 4, field_name(a), w*32))
                else:
                    if not args.reverse_write:
                        outfile.write("%sout << binout::tag('R') << binout::byte4" % indent +
                                      "(%s + 0x%x) << binout::byte4(%s);\n" %
                                      (addr_var, a.offset//address_unit, field_name(a)))
                    if single.msb >= 32:
                        outfile.write("%sout << binout::tag('R') << binout::byte4" % indent +
                                      "(%s + 0x%x) << binout::byte4(%s >> 32);\n" %
                                      (addr_var, a.offset//address_unit + 4, field_name(a)))
                    if args.reverse_write:
                        outfile.write("%sout << binout::tag('R') << binout::byte4" % indent +
                                      "(%s + 0x%x) << binout::byte4(%s);\n" %
                                      (addr_var, a.offset//address_unit, field_name(a)))
                #indent = indent[2:]
                #outfile.write("%s}\n" % indent)
            else:
                outfile.write(indent)
                if a.top_level():
                    outfile.write("if (%s)" % field_name(a))
                outfile.write(field_name(a))
                outfile.write("->" if a.top_level() else ".")
                outfile.write("emit_binary(out, %s + 0x%x);\n" %
                              (addr_var, a.offset//address_unit))
            if a.count != (1,):
                outfile.write("%saddr += 0x%x;\n" % (indent, a.address_stride()//address_unit))
                for i in range(0, len(a.count)):
                    indent = indent[2:]
                    outfile.write("%s}\n" % indent)
            if args.enable_disable:
                indent = indent[2:]
                outfile.write("%s}\n" % indent)
        indent = indent[2:]
        outfile.write("%s}\n" % indent)

    def gen_fieldname_method(self, outfile, args, classname, indent):
        outfile.write(indent)
        if self.gen_method_declarator(outfile, args, "void", classname, "emit_fieldname",
                ["std::ostream &out", "const char *addr", "const void *end"], "const"):
            return
        indent += "  "
        if not self.is_singleton():
            outfile.write("%sif ((void *)addr == this && end == this+1) return;\n" % indent)
        first = True
        for a in sorted(self.children(), key=lambda a: a.name, reverse=True):
            if a.disabled(): continue
            field_name = a.name
            if field_name in args.cpp_reserved:
                field_name += '_'
            outfile.write(indent)
            if first: first = False
            else: outfile.write("} else ")
            outfile.write("if (addr >= (char *)&%s) {\n" % field_name)
            indent += "  "
            outfile.write('%sout << ".%s";\n' % (indent, a.name))
            if a.count != (1,):
                for i, idx in enumerate(a.count):
                    outfile.write("%sint i%d = (addr - (char *)&%s" % (indent, i, field_name))
                    for j in range(0, i):
                        outfile.write("[i%d]" % j)
                    outfile.write("[0])/sizeof(%s" % field_name)
                    for j in range(0, i+1):
                        outfile.write("[0]")
                    outfile.write(");\n")
                    if idx > 1:
                        outfile.write("%sif (i%d < 0 || (i%d == 0 && 1 + &%s" %
                                      (indent, i, i, field_name))
                        for j in range(0, i):
                            outfile.write("[i%d]" % j)
                        outfile.write(" == end)) return;\n")
                    outfile.write("%sout << '[' << i%d << ']';\n" % (indent, i))
            single = a.singleton_obj()
            if not single.is_field() and not single.top_level():
                outfile.write("%s%s" % (indent, field_name))
                if a.count != (1,):
                    for i in range(0, len(a.count)):
                        outfile.write("[i%d]" % i)
                outfile.write(".emit_fieldname(out, addr, end);\n")
            indent = indent[2:]
        if not first:
            outfile.write("%s}\n" % indent)
        indent = indent[2:]
        outfile.write("%s}\n" % indent)

    def gen_unpack_method(self, outfile, args, classname, indent):
        outfile.write(indent)
        if self.gen_method_declarator(outfile, args, "int", classname, "unpack_json",
                ["json::obj *obj"], ""):
            return
        indent += "  "
        outfile.write("%sint rv = 0;\n" % indent)
        outfile.write("%sjson::map *m = dynamic_cast<json::map *>(obj);\n" % indent)
        outfile.write("%sif (!m) return -1;\n" % indent)
        for a in sorted(self.children(), key=lambda a: a.name):
            if a.disabled(): continue
            index_num = 0
            if a.count != (1,):
                for index_num, idx in enumerate(a.count):
                    outfile.write("%sif (json::vector *v%s = dynamic_cast<json::vector *>(" %
                                  (indent, index_num))
                    indent += "  "
                    if index_num > 0:
                        outfile.write("(*v%d)[i%d].get()" % (index_num-1, index_num-1))
                    else: outfile.write('(*m)["%s"].get()' % a.name)
                    outfile.write("))\n")
                    outfile.write("%sfor (int i%d = 0; i%d < %d; i%d++)\n" %
                                  (indent, index_num, index_num, idx, index_num))
                    indent += "  "
                index_num = len(a.count)
            single = a.singleton_obj()
            field_name = a.name
            if field_name in args.cpp_reserved:
                field_name += '_'
            if single != a:
                outfile.write("%sif (json::map *s = dynamic_cast<json::map *>(" % indent)
                indent += "  "
                if index_num > 0:
                    outfile.write("(*v%d)[i%d].get()" % (index_num-1, index_num-1))
                else: outfile.write('(*m)["%s"].get()' % a.name)
                outfile.write("))\n")
                outfile.write("%sif (json::number *n = dynamic_cast<json::number *>" % indent)
                indent += "  "
                outfile.write('((*s)["%s"].get()))\n' % a.name)
                outfile.write("%s%s" % (indent, field_name))
                if a.count != (1,):
                    for i in range(0, len(a.count)):
                        outfile.write("[i%d]" % i)
                outfile.write(" = n->val;\n")
                indent = indent[2:]
                outfile.write("%selse rv = -1;\n" % indent)
                indent = indent[2:]
                outfile.write("%selse rv = -1;\n" % indent)
            elif not a.is_field() and not a.top_level():
                outfile.write("%srv |= %s" % (indent, field_name))
                if a.count != (1,):
                    for i in range(0, len(a.count)):
                        outfile.write("[i%d]" % i)
                outfile.write(".unpack_json(")
                if index_num > 0:
                    outfile.write("(*v%d)[i%d].get()" % (index_num-1, index_num-1))
                else: outfile.write('(*m)["%s"].get()' % a.name)
                outfile.write(");\n")
            else:
                jtype = "json::number"
                access = "n->val"
                if a.top_level():
                    jtype = "json::string"
                    access = "*n"
                outfile.write("%sif (%s *n = dynamic_cast<%s *>(" % (indent, jtype, jtype))
                indent += "  "
                if index_num > 0:
                    outfile.write("(*v%d)[i%d].get()" % (index_num-1, index_num-1))
                else: outfile.write('(*m)["%s"].get()' % a.name)
                outfile.write(")) {\n")
                outfile.write("%s%s" % (indent, field_name))
                if a.count != (1,):
                    for i in range(0, len(a.count)):
                        outfile.write("[i%d]" % i)
                outfile.write(" = %s;\n" % access)
                if a.top_level():
                    outfile.write("%s} else if (json::number *n = dynamic_cast<json::number *>(" %
                                  indent[2:])
                    if index_num > 0:
                        outfile.write("(*v%d)[i%d].get()" % (index_num-1, index_num-1))
                    else: outfile.write('(*m)["%s"].get()' % a.name)
                    outfile.write(")) {\n")
                    outfile.write("%sif (n->val) rv = -1;\n" % indent)
                indent = indent[2:]
                outfile.write("%s} else rv = -1;\n" % indent)
            for i in range(0, index_num):
                indent = indent[4:]
                outfile.write("%selse rv = -1;\n" % indent)
        outfile.write("%sreturn rv;\n" % indent)
        indent = indent[2:]
        outfile.write("%s}\n" % indent)

    def gen_dump_unread_method(self, outfile, args, classname, indent):
        outfile.write(indent)
        if self.gen_method_declarator(outfile, args, "void", classname, "dump_unread",
                ["std::ostream &out", "prefix *pfx"], "const"):
            return
        indent += "  "
        need_lpfx = True
        for a in sorted(self.children(), key=lambda a: a.name):
            if a.disabled(): continue
            field_name = a.name
            if field_name in args.cpp_reserved:
                field_name += '_'
            if not a.singleton_obj().is_field() and not a.top_level():
                if need_lpfx:
                    outfile.write("%sprefix lpfx(pfx, 0);\n" % indent)
                    need_lpfx = False
                outfile.write('%slpfx.str = "%s' % (indent, a.name))
                if a.count != (1,):
                    for idx in a.count:
                        outfile.write("[%d]" % idx)
                outfile.write('";\n')
                outfile.write("%s%s" % (indent, field_name))
                if a.count != (1,):
                    for idx in a.count:
                        outfile.write("[0]")
                outfile.write(".dump_unread(out, &lpfx);\n")
            else:
                outfile.write("%sif (!%s" % (indent, field_name))
                if a.count != (1,):
                    for idx in a.count:
                        outfile.write("[0]")
                outfile.write('.read) out << pfx << ".%s' % a.name)
                if a.count != (1,):
                    for idx in a.count:
                        outfile.write("[%d]" % idx)
                outfile.write('" << std::endl;\n')
        indent = indent[2:]
        outfile.write("%s}\n" % indent)

    def gen_modified_method(self, outfile, args, classname, indent):
        outfile.write(indent)
        if self.gen_method_declarator(outfile, args, "bool", classname, "modified", [], "const"):
            return
        indent += "  "
        for a in sorted(self.children(), key=lambda a: a.name):
            if a.disabled(): continue
            field_name = a.name
            if field_name in args.cpp_reserved:
                field_name += '_'
            if not args.checked_array:
                if a.count != (1,):
                    for index_num, idx in enumerate(a.count):
                        outfile.write("%sfor (int i%d = 0; i%d < %d; i%d++)\n" %
                                      (indent, index_num, index_num, idx, index_num))
                        indent += "  "
                outfile.write("%sif (%s" % (indent, field_name))
                if a.count != (1,):
                    for i in range(0, len(a.count)):
                        outfile.write("[i%d]" % i)
                outfile.write(".modified()) return true;\n")
                if a.count != (1,):
                    indent = indent[2*len(a.count):]
            else:
                outfile.write("%sif (%s.modified()) return true;\n" % (indent, field_name))
        outfile.write("%sreturn false;\n" % indent)
        indent = indent[2:]
        outfile.write("%s}\n" % indent)

    def gen_set_modified_method(self, outfile, args, classname, indent):
        outfile.write(indent)
        if self.gen_method_declarator(outfile, args, "void", classname, "set_modified",
                                      [("bool v", "true")], ""):
            return
        indent += "  "
        for a in sorted(self.children(), key=lambda a: a.name):
            if a.disabled(): continue
            field_name = a.name
            if field_name in args.cpp_reserved:
                field_name += '_'
            if not args.checked_array:
                if a.count != (1,):
                    for index_num, idx in enumerate(a.count):
                        outfile.write("%sfor (int i%d = 0; i%d < %d; i%d++)\n" %
                                      (indent, index_num, index_num, idx, index_num))
                        indent += "  "
                outfile.write("%s%s" % (indent, field_name))
                if a.count != (1,):
                    for i in range(0, len(a.count)):
                        outfile.write("[i%d]" % i)
                outfile.write(".set_modified(v);\n")
                if a.count != (1,):
                    indent = indent[2*len(a.count):]
            else:
                outfile.write("%s%s.set_modified(v);\n" % (indent, field_name))
        indent = indent[2:]
        outfile.write("%s}\n" % indent)

    def gen_disable_method(self, outfile, args, classname, indent):
        outfile.write(indent)
        if self.gen_method_declarator(outfile, args, "bool", classname, "disable", [], ""):
            return
        indent += "  "
        outfile.write("%sbool rv = true;\n" % indent)
        outfile.write("%sif (modified()) {\n" % indent)
        outfile.write('%s  std::clog << "ERROR: Disabling modified record ";\n' % indent)
        outfile.write("%s  print_regname(std::clog, this, this+1);\n" % indent)
        outfile.write("%s  std::clog << std::endl; \n" % indent)
        outfile.write("%s  return false; }\n" % indent)
        for a in sorted(self.children(), key=lambda a: a.name):
            if a.disabled(): continue
            field_name = a.name
            if field_name in args.cpp_reserved:
                field_name += '_'
            if not args.checked_array:
                if a.count != (1,):
                    for index_num, idx in enumerate(a.count):
                        outfile.write("%sfor (int i%d = 0; i%d < %d; i%d++)\n" %
                                      (indent, index_num, index_num, idx, index_num))
                        indent += "  "
                outfile.write("%sif (%s" % (indent, field_name))
                if a.count != (1,):
                    for i in range(0, len(a.count)):
                        outfile.write("[i%d]" % i)
                outfile.write(".disable()) rv = true;\n")
                if a.count != (1,):
                    indent = indent[2*len(a.count):]
            else:
                outfile.write("%sif (%s.disable()) rv = true;\n" % (indent, field_name))
        outfile.write("%sif (rv) disabled_ = true;\n" % indent)
        outfile.write("%sreturn rv;\n" % indent)
        indent = indent[2:]
        outfile.write("%s}\n" % indent)

    def gen_disable_if_reset_value_method(self, outfile, args, classname, indent):
        outfile.write(indent)
        if self.gen_method_declarator(outfile, args, "bool", classname,
                                      "disable_if_reset_value", [], ""):
            return
        indent += "  "
        outfile.write("%sbool rv = true;\n" % indent)
        for a in sorted(self.children(), key=lambda a: a.name):
            if a.disabled(): continue
            field_name = a.name
            if field_name in args.cpp_reserved:
                field_name += '_'
            if not args.checked_array:
                if a.count != (1,):
                    for index_num, idx in enumerate(a.count):
                        outfile.write("%sfor (int i%d = 0; i%d < %d; i%d++)\n" %
                                      (indent, index_num, index_num, idx, index_num))
                        indent += "  "
                outfile.write("%sif (!%s" % (indent, field_name))
                if a.count != (1,):
                    for i in range(0, len(a.count)):
                        outfile.write("[i%d]" % i)
                outfile.write(".disable_if_reset_value()) rv = false;\n")
                if a.count != (1,):
                    indent = indent[2*len(a.count):]
            else:
                outfile.write("%sif (!%s.disable_if_reset_value()) rv = false;\n" %
                              (indent, field_name))
        outfile.write("%sif (rv) disabled_ = true;\n" % indent)
        outfile.write("%sreturn rv;\n" % indent)
        indent = indent[2:]
        outfile.write("%s}\n" % indent)

    def gen_disable_if_unmodified_method(self, outfile, args, classname, indent):
        outfile.write(indent)
        if self.gen_method_declarator(outfile, args, "bool", classname,
                                      "disable_if_unmodified", [], ""):
            return
        indent += "  "
        outfile.write("%sbool rv = true;\n" % indent)
        for a in sorted(self.children(), key=lambda a: a.name):
            if a.disabled(): continue
            field_name = a.name
            if field_name in args.cpp_reserved:
                field_name += '_'
            if not args.checked_array:
                if a.count != (1,):
                    for index_num, idx in enumerate(a.count):
                        outfile.write("%sfor (int i%d = 0; i%d < %d; i%d++)\n" %
                                      (indent, index_num, index_num, idx, index_num))
                        indent += "  "
                outfile.write("%sif (!%s" % (indent, field_name))
                if a.count != (1,):
                    for i in range(0, len(a.count)):
                        outfile.write("[i%d]" % i)
                outfile.write(".disable_if_unmodified()) rv = false;\n")
                if a.count != (1,):
                    indent = indent[2*len(a.count):]
            else:
                outfile.write("%sif (!%s.disable_if_unmodified()) rv = false;\n" %
                              (indent, field_name))
        outfile.write("%sif (rv) disabled_ = true;\n" % indent)
        outfile.write("%sreturn rv;\n" % indent)
        indent = indent[2:]
        outfile.write("%s}\n" % indent)

    def gen_disable_if_zero_method(self, outfile, args, classname, indent):
        outfile.write(indent)
        if self.gen_method_declarator(outfile, args, "bool", classname, "disable_if_zero", [], ""):
            return
        indent += "  "
        outfile.write("%sbool rv = true;\n" % indent)
        for a in sorted(self.children(), key=lambda a: a.name):
            if a.disabled(): continue
            field_name = a.name
            if field_name in args.cpp_reserved:
                field_name += '_'
            if not args.checked_array:
                if a.count != (1,):
                    for index_num, idx in enumerate(a.count):
                        outfile.write("%sfor (int i%d = 0; i%d < %d; i%d++)\n" %
                                      (indent, index_num, index_num, idx, index_num))
                        indent += "  "
                outfile.write("%sif (!%s" % (indent, field_name))
                if a.count != (1,):
                    for i in range(0, len(a.count)):
                        outfile.write("[i%d]" % i)
                outfile.write(".disable_if_zero()) rv = false;\n")
                if a.count != (1,):
                    indent = indent[2*len(a.count):]
            else:
                outfile.write("%sif (!%s.disable_if_zero()) rv = false;\n" % (indent, field_name))
        outfile.write("%sif (rv && modified()) {\n" % indent)
        outfile.write('%s  std::clog << "Disabling modified zero record ";\n' % indent)
        outfile.write("%s  print_regname(std::clog, this, this+1);\n" % indent)
        outfile.write("%s  std::clog << std::endl;\n" % indent)
        outfile.write("%s  rv = false; }\n" % indent)
        outfile.write("%sif (rv) disabled_ = true;\n" % indent)
        outfile.write("%sreturn rv;\n" % indent)
        indent = indent[2:]
        outfile.write("%s}\n" % indent)

    def gen_enable_method(self, outfile, args, classname, indent):
        outfile.write(indent)
        if self.gen_method_declarator(outfile, args, "void", classname, "enable", [], ""):
            return
        indent += "  "
        for a in sorted(self.children(), key=lambda a: a.name):
            if a.disabled(): continue
            field_name = a.name
            if field_name in args.cpp_reserved:
                field_name += '_'
            if not args.checked_array:
                if a.count != (1,):
                    for index_num, idx in enumerate(a.count):
                        outfile.write("%sfor (int i%d = 0; i%d < %d; i%d++)\n" %
                                      (indent, index_num, index_num, idx, index_num))
                        indent += "  "
                outfile.write("%s%s" % (indent, field_name))
                if a.count != (1,):
                    for i in range(0, len(a.count)):
                        outfile.write("[i%d]" % i)
                outfile.write(".enable();\n")
                if a.count != (1,):
                    indent = indent[2*len(a.count):]
            else:
                outfile.write("%s%s.enable();\n" % (indent, field_name))
        outfile.write("%sdisabled_ = false;\n" % indent)
        indent = indent[2:]
        outfile.write("%s}\n" % indent)

    def need_ctor(self):
        for el in self.children():
            s = el.singleton_obj()
            if s.is_field() and s.default and s.default != 0:
                if type(s.default) is tuple:
                    for v in s.default:
                        if v != 0:
                            return True
                else:
                    return True
        return False

    def gen_ctor(self, outfile, args, namestr, indent):
        outfile.write("%s%s() : " % (indent, namestr))
        first = True
        if args.enable_disable:
            outfile.write("disabled_(false)")
            first = False
        for el in sorted(self.children(), key=lambda a: a.name):
            if el.disabled(): continue
            s = el.singleton_obj()
            if s.is_field() and s.default and s.default != 0:
                if type(s.default) is tuple:
                    ok = True
                    for v in s.default:
                        if v != 0:
                            ok = False
                            break
                    if ok: continue
                if first:
                    first = False
                else:
                    outfile.write(", ")
                outfile.write(el.name)
                if el.name in args.cpp_reserved:
                    outfile.write('_')
                if type(s.default) is tuple and len(s.default) > 1:
                    outfile.write("({ ")
                    for v in s.default:
                        outfile.write(str(v)+", ")
                    outfile.write("})")
                else:
                    outfile.write('(%d)' % s.default)
        outfile.write(' {}\n')

    def canon_name(self, name):
        namestr = ''
        nameargs = []
        format = False
        islong = False
        for ch in name:
            if format:
                if ch in string.digits:
                    continue
                elif ch == 'l':
                    islong = True
                    continue
                elif ch == 'd' or ch == 'i' or ch == 'u' or ch == 'x':
                    nameargs.append('long ' if islong else 'int ')
                elif ch == 'e' or ch == 'f' or ch == 'g':
                    nameargs.append('double ' if islong else 'float ')
                elif ch == 's':
                    nameargs.append('const char *')
                else:
                    raise CsrException("unknown conversion '%%%s' in name\n" % ch)
                format = False
            elif ch in string.letters or ch in string.digits or ch == '_':
                namestr += ch
            elif ch == '.':
                namestr += '_'
            elif ch == '%':
                format = True
                islong = False
            else:
                raise CsrException("invalid character '%s' in name\n" % ch)
        return namestr, nameargs

    def gen_type(self, outfile, args, schema, parent, name, indent):
        namestr, nameargs = self.canon_name(name)
        classname = parent
        if classname != '':
            classname += '::'
        classname += namestr
        if args.gen_decl != 'defn':
            indent += "  "
            outfile.write("struct %s {\n" % namestr)
            if args.enable_disable:
                outfile.write("%sbool disabled_;\n" % indent)
                outfile.write("%sbool disabled() const { return disabled_; }\n" % indent)
            if args.enable_disable or self.need_ctor():
                self.gen_ctor(outfile, args, namestr, indent)
            if self.top_level():
                outfile.write('%sstatic constexpr const char *_reg_version = "%s";\n' %
                              (indent, schema['_reg_version']))
                outfile.write('%sstatic constexpr const char *_schema_hash = "%s";\n' %
                              (indent, schema['_schema_hash']))
        for el in sorted(self.children(), key=lambda a: a.name):
            if el.disabled(): continue
            typ = el.singleton_obj()
            notclass = typ.is_field() or typ.top_level()
            isglobal = el.name in args.global_types
            if args.gen_decl != 'defn':
                outfile.write(indent)
                if args.checked_array and notclass and el.count != (1,):
                    for idx in el.count:
                        outfile.write("checked_array<%d, " % idx)
            if not isglobal:
                typ.gen_type(outfile, args, schema, classname, "_" + el.name, indent)
            if args.gen_decl != 'defn':
                field_name = el.name
                if field_name in args.cpp_reserved:
                    field_name += '_'
                if args.checked_array and el.count != (1,):
                    if not notclass:
                        if not isglobal:
                            outfile.write(";\n%s" % indent)
                        for idx in el.count:
                            outfile.write("checked_array<%d, " % idx)
                        outfile.write('::' if isglobal else '_')
                        outfile.write(el.name)
                    if el.count != (1,):
                        for idx in el.count:
                            outfile.write(">")
                    outfile.write(" %s;\n" % field_name)
                else:
                    outfile.write(" %s" % field_name)
                    if el.count != (1,):
                        for idx in el.count:
                            outfile.write("[%d]" % idx)
                    outfile.write(";\n")
        if args.delete_copy and args.gen_decl != 'defn':
            if not args.enable_disable and not self.need_ctor():
                outfile.write("%s%s() = default;\n" % (indent, namestr))
            outfile.write("%s%s(const %s &) = delete;\n" % (indent, namestr, namestr))
            outfile.write("%s%s(%s &&) = delete;\n" % (indent, namestr, namestr))
        if args.emit_json:
            self.gen_emit_method(outfile, args, schema, classname, name, nameargs, indent)
        if args.emit_binary:
            self.gen_emit_binary_method(outfile, args, classname, indent)
        if args.emit_fieldname:
            self.gen_fieldname_method(outfile, args, classname, indent)
        if args.unpack_json:
            self.gen_unpack_method(outfile, args, classname, indent)
        if args.dump_unread:
            self.gen_dump_unread_method(outfile, args, classname, indent)
        if args.enable_disable:
            self.gen_modified_method(outfile, args, classname, indent)
            self.gen_set_modified_method(outfile, args, classname, indent)
            self.gen_disable_method(outfile, args, classname, indent)
            self.gen_disable_if_reset_value_method(outfile, args, classname, indent)
            self.gen_disable_if_unmodified_method(outfile, args, classname, indent)
            self.gen_disable_if_zero_method(outfile, args, classname, indent)
            self.gen_enable_method(outfile, args, classname, indent)
        if args.gen_decl != 'defn':
            indent = indent[2:]
            outfile.write("%s}" % indent)

    def gen_global_types(self, outfile, args, schema):
        for a in sorted(self.children(), key=lambda a: a.name):
            if a.disabled(): continue
            if not a.is_field() and not a.top_level():
                a.gen_global_types(outfile, args, schema)
                if a.name in args.global_types:
                    if a.name in args.global_types_generated:
                        if args.global_types_generated[a.name] != a:
                            raise CsrException("Inconsistent definition of type "+a.name)
                    else:
                        args.global_types_generated[a.name] = a
                        a.gen_type(outfile, args, schema, "", a.name, "")
                        outfile.write(";\n")

class address_map(csr_composite_object):
    """
    A Semifore addressmap. Contains registers and instances of other
    addressmaps.

    In practice, the count of an address_map is always (1,) and it is the
    instances of the addressmap that are actually arrays.

    @attr templatization_behavior
        Controls how this address map gets used during template generation:
            - If None, it is expanded as a dictionary wherever it appears in the
              register hierarchy
            - If "top_level", it is split off into its own JSON file and
              replaced wherever it appears in the register hierarchy with a
              string reference to that JSON file
            - If "disabled", it is replaced wherever it appears in the register
              hierarchy with a 0 (indicating "don't write"). No JSON file for
              the address map is generated
    @attr objs
        An ordered list of objects contained in the addressmap - either regs,
        groups, or address_map_instances

    @attr parent
        A string indicating which parent of the chip hierarchy the addressmap
        falls under ("memories" or "regs)
    """
    def __init__(self, name, count, parent):
        csr_composite_object.__init__(self, name, count)

        self.templatization_behavior = None
        self.objs = []
        self.parent = parent

    def min_width(self, round_to_power_of_2=True):
        """
        Some addressmap arrays have an explicit "stride" specifying how much
        address space each element takes up. When they don't, we calculate the
        stride by summing up the widths of all contained objects and rounding
        to the next highest power of 2.

        Whether an addressmap has a stride or not is up to the programmer of
        the original Semifore CSR and, as far as Walle is conserned, arbitrary.
        """
        width = 0
        for obj in self.objs:
            obj_end = obj.offset * 8
            if type(obj) is reg:
                obj_end += obj.width * product(obj.count)
            elif type(obj) is address_map_instance or type(obj) is group:
                try:
                    multiplier = product(obj.count) * obj.stride
                except:
                    multiplier = 1
                obj_end += obj.min_width() * multiplier
            else:
                raise CsrException("Unrecognized object in address map ('"+type(obj)+"')")
            if obj_end > width:
                width = obj_end

        width /= 8

        if round_to_power_of_2:
            # Round stride up to the next largest power of 2
            round_width = 1
            while round_width < width:
                round_width *= 2
            return round_width
        else:
            return width

    def generate_binary(self, data, cache, path):
        if data == 0:
            # No-op
            return {}
        elif isinstance(data, StringTypes):
            # Refernce to template

            type_name = self.parent + "." + self.name

            if data not in cache.templates:
                raise CsrException("Could not find template with name '"+data+"'")

            if cache.get_type(data) != type_name:
                raise CsrException("Expected type of instantiated object '"+data+"' to be '"+type_name+"', found '"+cache.get_type(data)+"'")

            return cache.get_data(data, path)
        elif type(data) is dict:
            # Actual data
            reg_values = []
            for obj in self.objs:
                if obj.name not in data:
                    raise CsrException("Could not find key '"+obj.name+"'")
                if data[obj.name] != 0 and not isinstance(data[obj.name], StringTypes):
                    if obj.count == (1,):
                        if type(data[obj.name]) is not dict:
                            raise CsrException("Expected dictionary at key '"+obj.name+"'")
                    else:
                        # TODO: check all dimensions are the right size, maybe if a 'strict errors' flag is used
                        if type(data[obj.name]) is not list or len(data[obj.name]) != obj.count[0]:
                            array_size = "x".join(map(str,obj.count))
                            raise CsrException("Expected "+array_size+" element array of dictionaries at key '"+obj.name+"'")

                if type(obj) is reg:
                    if obj.count == (1,):
                        chip_obj = obj.generate_binary(data[obj.name], cache, path)
                        reset_value = obj.get_reset_value()

                        if chip_obj is not None and reset_value is not None:
                            # Check if a non-zero value to put into the binary file is the same as the reset (initial) value.
                            # (We will continue to write zero values, for caution's sake.
                            #  Would block writes work if leave out subsection?)
                            # If the non-zero value is the reset value, do not output it in the binary file.
                            # We are having too many problems where the driver is clearing things (like interrupt enables)
                            # before the binary file is loaded, and then the binary file re-enables them.
                            # See DRV-1389
                            if reset_value == chip_obj.orig_value:
                                # print "Skipping setting %s, because it has the same value (%s) as its reset value of %s." % (obj.name, str(chip_obj), hex(reset_value))
                                continue

                        if chip_obj != None:
                            reg_values.append(chip_obj)
                    elif data[obj.name] != 0:
                        # TODO: we should be able to DMA anything into the chip,
                        #       so this count > 4 heuristic should work well
                        #
                        #       but right now the model doesn't implement chip-
                        #       side register addresses, so we have to force
                        #       direct register writes for the regs part of
                        #       the schema and DMA for the mem part. lame.
                        #       use this count heuristic once the model is fixed.
                        #
                        # if product(obj.count) > 4:
                        root_parent = obj.parent
                        while type(root_parent) is not str:
                            root_parent = root_parent.parent
                        # DRV-655, Force the mapram_config register programming
                        # on the DMA block write path to avoid a race during
                        # chip init where the map ram is being written and the
                        # ECC mode is also being configured.  Since the map ram
                        # is written with block writes, forcing this register
                        # configuration on the same path removes the race.

                        registers_to_write_with_dma = [ "mapram_config",
                            "imem_dark_subword16", "imem_dark_subword32", "imem_dark_subword8",
                            "imem_mocha_subword16", "imem_mocha_subword32", "imem_mocha_subword8",
                            "imem_subword16", "imem_subword32", "imem_subword8",
                            "galois_field_matrix"]
                        if product(obj.count) > 4 and (root_parent=="memories" or obj.name in registers_to_write_with_dma):
                            mem = chip.dma_block(obj.offset, obj.width, src_key=obj.name, is_reg=root_parent=="regs")
                            def mem_loop(sub_data, context):
                                path[-1].path.append(context)
                                for idx in range(0, obj.count[-1]):
                                    context[-1] = idx
                                    obj.generate_binary(sub_data[idx], cache, path, mem)
                                path[-1].path.pop()
                            nd_array_loop(obj.count, data[obj.name], mem_loop)
                            reg_values.append(mem)
                        else:
                            offset = [0]
                            width = obj.width/8 #TODO: warn if not power of (8 or 32 or w/e)?
                            def reg_loop(sub_data, context):
                                path[-1].path.append(context)
                                for idx in range(0, obj.count[-1]):
                                    context[-1] = idx
                                    chip_obj = obj.generate_binary(sub_data[idx], cache, path)
                                    if chip_obj != None:
                                        chip_obj.add_offset(offset[0])
                                        reg_values.append(chip_obj)
                                    offset[0] += width
                                path[-1].path.pop()
                            nd_array_loop(obj.count, data[obj.name], reg_loop)

                elif type(obj) is address_map_instance or type(obj) is group:
                    if obj.count == (1,):
                        sub_chip_objs = obj.generate_binary(data[obj.name], cache, path)
                        for sub_chip_obj in sub_chip_objs:
                            sub_chip_obj.add_offset(obj.offset)
                            reg_values.append(sub_chip_obj)
                    elif data[obj.name] != 0:
                        offset = [0]
                        def addr_map_loop(sub_data, context):
                            path[-1].path.append(context)
                            for idx in range(0, obj.count[-1]):
                                context[-1] = idx
                                sub_chip_objs = obj.generate_binary(sub_data[idx], cache, path)
                                for sub_chip_obj in sub_chip_objs:
                                    sub_chip_obj.add_offset(obj.offset+offset[0])
                                    reg_values.append(sub_chip_obj)
                                offset[0] += obj.stride
                            path[-1].path.pop()
                        nd_array_loop(obj.count, data[obj.name], addr_map_loop)
                else:
                    raise CsrException("Unrecognized object in address map ('"+type(obj)+"')")

            return reg_values
        else:
            raise CsrException(
                "Expected dictionary at addressmap node '%s' but found value of type %s" % (
                self.name, type(data).__name__
            ))

    def generate_template(self, inject_size):
        self_dict = {}
        if self.templatization_behavior == "disabled":
            return None
        if self.templatization_behavior == "top_level":
            self_dict["_type"] = self.parent + "." + self.name
            self_dict["_name"] = "template("+self_dict["_type"]+")"
        for obj in self.objs:
            self_dict[obj.name] = obj.generate_template(inject_size)
        return self.replicate(self_dict)

    def children(self):
        return self.objs
    def disabled(self):
        return self.templatization_behavior == "disabled"
    def top_level(self):
        return self.templatization_behavior == "top_level"

    def generate_cpp(self, outfile, args, schema):
        try:
            name = args.name
        except AttributeError:
            name = self.name
        self.gen_type(outfile, args, schema, '', name, '')

    def print_as_text(self, indent):
        if self.templatization_behavior != "disabled":
            print "%saddress_map %s%s:" % (indent, self.name, str(self.count))
            for ch in self.objs:
                ch.print_as_text(indent+"  ")

class address_map_instance(csr_composite_object):
    """
    TODO: docstring
    @attr offset
        offset from the start of the containing address_map (instance)
    @attr map
        address_map object that is an instance of
    @attr stride
        If @count is not (1,), this is the offset from each instance in the array to
        the next.  If @count is (1,) this should be null
    """
    def __init__(self, name, count, offset, addrmap, stride):
        csr_composite_object.__init__(self, name, count)

        self.offset = offset
        self.map = addrmap
        self.stride = stride

    def min_width(self):
        return self.map.min_width()

    def generate_binary(self, data, cache, path):
        path[-1].path.append(self.name)
        binary = self.map.generate_binary(data, cache, path)
        path[-1].path.pop()
        return binary

    def generate_template(self, inject_size):
        if self.map.templatization_behavior == "top_level":
            return self.replicate(self.map.name+"_object")
        elif self.map.templatization_behavior == "disabled":
            return self.replicate(0)
        else:
            return self.replicate(self.map.generate_template(inject_size))

    def children(self):
        return self.map.objs
    def disabled(self):
        return self.map.templatization_behavior == "disabled"
    def top_level(self):
        return self.map.templatization_behavior == "top_level"
    def address_stride(self):
        return self.stride

    def gen_type(self, outfile, args, schema, parent, name, indent):
        if self.map.templatization_behavior == "disabled":
            raise CsrException("disabled address_map hit in gen_type")
        elif self.map.templatization_behavior == "top_level":
            if args.gen_decl != 'defn':
                tname = self.map.object_name
                if tname is None:
                    tname = self.map.parent + '.' + self.map.name
                outfile.write("register_reference<struct %s>" % self.canon_name(tname)[0])
        else:
            self.map.gen_type(outfile, args, schema, parent, name, indent)

    def print_as_text(self, indent):
        print "%saddress_map_instance %s%s: offset=0x%x%s" % (
            indent, self.name, str(self.count), self.offset,
            " stride=0x%x" % self.stride if self.stride else "")
        if self.map.templatization_behavior == "top_level":
            print "%s  address_map %s%s: (top level %s)" % (
                indent, self.name, str(self.count), self.map.name)
        else:
            self.map.print_as_text(indent+"  ")


class group(address_map):
    """
    TODO: docstring
    @attr stride
        If @count is not (1,) this the offset from each element to the next
        If @count is (1,) this should be null
    @attr offset
        offset from the start of the containing addres_map
    """
    def __init__(self, name, count, offset, parent, stride):
        address_map.__init__(self, name, count, parent)
        self.stride = stride
        self.offset = offset

    def generate_binary(self, data, cache, path):
        path[-1].path.append(self.name)
        binary = address_map.generate_binary(self, data, cache, path)
        path[-1].path.pop()
        return binary

    def min_width(self):
        """
        A group array's stride, unlike addressmap instance arrays, is not
        rounded up to a power of two if it has to be calculated.
        """
        if self.stride != None:
            return self.stride
        else:
            return address_map.min_width(self, round_to_power_of_2=False)

    def address_stride(self):
        return self.stride

    def print_as_text(self, indent):
        print "%sgroup %s%s: offset=0x%x%s" % (
            indent, self.name, str(self.count), self.offset,
            " stride=0x%x" % self.stride if self.stride else "")
        for ch in self.objs:
            ch.print_as_text(indent+"  ")


class reg(csr_composite_object):
    """
    TODO: docstring
    @attr parent
        Containing address_map object
    @attr offset
        Offset from the start of the containing address_map_instance
    @attr width
        width in bits
    @attr fields
        vector of fields in the register
    """
    def __init__(self, name, count, offset, width, parent):
        csr_composite_object.__init__(self, name, count)

        self.parent = parent
        self.offset = offset
        self.width = width
        self.fields = []

    def __str__(self):
        f = "("
        for x in self.fields:
            f += "%s, " % str(x.name)
        f += ")"
        return "%s has fields %s" % (self.name, f)

    def get_reset_value(self):
        rv = 0
        for f in self.fields:
            rv |= (f.default[0] << f.lsb)
        return rv

    def generate_binary(self, data, cache, path, mem=None):
        if data == 0:
            # No-op
            return None
        elif isinstance(data, StringTypes):
            # Refernce to template

            path[-1].path.append(self.name)

            type_name = self.parent + "." + self.name

            if data not in cache.templates:
                raise CsrException("Could not find template with name '"+data+"'")

            if cache.get_type(data) != type_name:
                raise CsrException("Expected type of instantiated object '"+data+"' to be '"+type_name+"', found '"+cache.get_type(data)+"'")

            cached_data = cache.get_data(data, path)
            path[-1].path.pop()

            if mem:
                mem.add_word(cached_data)
            else:
                return cached_data
        elif type(data) is dict:
            path[-1].path.append(self.name)

            reg_value = [0]
            # TODO:  put field names in path histories
            for field in self.fields:

                if field.name not in data:
                    raise CsrException("Could not find key '"+field.name+"'")

                width = field.msb-field.lsb+1
                if field.count == (1,):
                    value = data[field.name]
                    if type(value) is not int and type(value) is not long:
                        raise CsrException(
                            "Expected integer value for field '%s.%s' but found value of type %s" % (
                            self.name, field.name, type(value).__name__
                        ))
                    elif value < 0:
                        raise CsrException(
                            "Value for field '%s.%s' is negative (%i)" % (
                            self.name, field.name, value
                        ))
                    elif value <= pow(2, width):
                        reg_value[0] |= value << field.lsb
                    else:
                        raise CsrException(
                            "Width of field '%s.%s' (%i bits) not large enough to hold value (%i)" % (
                            self.name, field.name, width, value
                        ))
                else:
                    offset = [0]
                    def field_loop(sub_data, context):
                        path[-1].path.append(context)
                        for idx in range(0, field.count[-1]):
                            context[-1] = idx
                            value = sub_data[idx]
                            if type(value) is not int and type(value) is not long:
                                raise CsrException(
                                    "Expected integer value for field '%s.%s%s' but found value of type %s" % (
                                    self.name, field.name, array_str(context), type(value).__name__
                                ))
                            elif value < 0:
                                raise CsrException(
                                    "Value for field '%s.%s%s' is negative (%i)" % (
                                    self.name, field.name, array_str(context), value
                                ))
                            elif value <= pow(2, width):
                                reg_value[0] |= value << field.lsb + offset[0]
                                offset[0] += width
                            else:
                                raise CsrException(
                                    "Width of field '%s.%s%s' (%i bits) not large enough to hold value (%i)" % (
                                    self.name, field.name, array_str(context), width, value
                                ))
                        path[-1].path.pop()

                    # TODO: check all dimension sizes
                    if type(data[field.name]) is not list or len(data[field.name]) != field.count[0]:
                        array_size = "x".join(map(str,field.count))
                        raise CsrException("Expected "+array_size+" element array of integers at key '"+field.name+"'")

                    nd_array_loop(field.count, data[field.name], field_loop)

            path[-1].path.pop()

            if mem:
                mem.add_word(reg_value[0])
            elif self.width <= 32:
                return chip.direct_reg(self.offset, reg_value[0], src_key=self.name)
            else:
                return chip.indirect_reg(self.offset, reg_value[0], self.width, src_key=self.name)
        else:
            raise CsrException(
                "Expected dictionary at register node '%s' but found value of type %s" % (
                self.name, type(data).__name__
            ))


    def generate_template(self, inject_size):
        self_dict = {}
        for field in self.fields:
            self_dict[field.name] = field.generate_template(inject_size)
        return self.replicate(self_dict)

    def children(self):
        return self.fields
    def is_singleton(self):
        return len(self.fields) == 1 and self.fields[0].count == (1,)
    def singleton_obj(self):
        if self.is_singleton() and self.fields[0].name == self.name:
            return self.fields[0]
        return self
    def address_stride(self):
        return self.width // 8
        
    def disabled(self):
        return False
    def top_level(self):
        return False

    def gen_emit_binary_method(self, outfile, args, classname, indent):
        outfile.write(indent)
        if self.gen_method_declarator(outfile, args, "void", classname, "emit_binary",
                ["std::ostream &out", "uint64_t a"], "const"):
            return
        indent += "  "
        if self.count != (1,):
            pass
        class context:
            shift = 0
            words = []
        context.words = [None] * (self.width // 32)
        indirect = ((self.parent.parent=="memories") or (self.name in args.write_dma))
        if not indirect:
            outfile.write("%sif (!disabled_) {\n" % indent);
            indent += "  "
        for a in self.fields:
            field_name = a.name
            if field_name in args.cpp_reserved:
                field_name += '_'
            context.shift = a.lsb;
            def emit_field_slice(field, word, shift):
                if context.words[word] is None:
                    context.words[word] = ''
                else:
                    context.words[word] += " + "
                if shift != 0:
                    context.words[word] += "("
                context.words[word] += field
                if shift > 0:
                    context.words[word] += " << %d)" % shift
                elif shift < 0:
                    context.words[word] += " >> %d)" % -shift
            def emit_ubits_field(index_list):
                word = context.shift // 32
                shift = context.shift % 32
                name = field_name + array_str(index_list)
                emit_field_slice(name, word, shift)
                if shift + a.msb - a.lsb >= 32:
                    emit_field_slice(name, word+1, shift - 32)
                if shift + a.msb - a.lsb >= 64:
                    emit_field_slice(name, word+2, shift - 64)
                context.shift = context.shift + a.msb - a.lsb + 1
            def emit_widereg_field(index_list):
                word = context.shift // 32
                shift = context.shift % 32
                name = field_name + array_str(index_list) + ".value.getrange("
                emit_field_slice(name + "0, %d)" % (32 - shift), word, shift)
                shift = 32 - shift
                while shift < a.msb - a.lsb + 1:
                    word += 1
                    emit_field_slice(name + "%d, 32)" % shift, word, 0)
                    shift += 32
            if a.count != (1,):
                if a.msb - a.lsb + 1 > 64:
                    count_array_loop(a.count, emit_widereg_field)
                else:
                    count_array_loop(a.count, emit_ubits_field)
            else:
                if a.msb - a.lsb + 1 > 64:
                    emit_widereg_field(None)
                else:
                    emit_ubits_field(None)
        pairs = enumerate(context.words)
        if not indirect and args.reverse_write:
            # DANGER -- certain registers must be written in reverse order (higher
            # address then lower), so we reverse the order of register writes here.
            # block writes must be in order (lowest to highest) as they are a block
            pairs = reversed(list(pairs))
        for idx, val in pairs:
            if val is None:
                val = '0'
            outfile.write("%sout << " % indent);
            if not indirect:
                outfile.write("binout::tag('R') << binout::byte4(a + %d)\n" % (idx*4))
                outfile.write("%s    << " % indent)
            outfile.write("binout::byte4(%s);\n" % val)
        if not indirect:
            indent = indent[2:]
            outfile.write("%s}\n" % indent)
        indent = indent[2:]
        outfile.write("%s}\n" % indent)

    def print_as_text(self, indent):
        print "%sreg %s%s: offset=0x%x width=%d" % (
            indent, self.name, str(self.count), self.offset, self.width)
        for ch in self.fields:
            ch.print_as_text(indent+"  ")


class field(csr_object):
    """
    TODO: docstring
    @attr default
        default (reset-init) value
    @attr parent
        containing register object
    @attr msb, lsb
        Range of bits in containing register for this field.  If @count is not (1,), this
        is just the first element; the second will be at lsb = msb+1 etc
    """
    def __init__(self, name, count, msb, lsb, default, parent):
        csr_object.__init__(self, name, count)

        self.default = default
        self.parent = parent
        self.msb = msb
        self.lsb = lsb

    def generate_template(self, inject_size):
        if inject_size:
            return self.replicate(self.msb-self.lsb+1)
        else:
            if self.count == (1,):
                return self.default[0]
            else:
                return self.default

    def is_field(self):
        return True
    def disabled(self):
        return False
    def top_level(self):
        return False
    def gen_type(self, outfile, args, schema, parent, name, indent):
        size = self.msb-self.lsb+1
        if args.gen_decl != 'defn':
            if size > 64:
                outfile.write("widereg<%d>" % size)
            else:
                outfile.write("ubits<%d>" % size)

    def __str__(self):
        return "name = %s  count = %s  msb = %s  lsb = %s  default = %s  parent = %s" % (str(self.name), str(self.count), str(self.msb), str(self.lsb), str(self.default), str(self.parent))

    def print_as_text(self, indent):
        print "%sfield %s%s: [%d:%d]%s" % (
            indent, self.name, str(self.count), self.msb, self.lsb, 
            " default=" + str(self.default) if self.default else "")


########################################################################
## Utility functions

def parse_resets(reset_str):
    """
    Turn a reset value from a Semifore CSV string into a tuple of ints

    Semifore CSV formats most reset values as hex integers of the from 0x___
    Arrays of fields, however, result in comma-separated lists:
    [0x__, 0x__, ...]

    If the array is 1D this function will still output the size as a 1-element
    tuple, just for consistency of iterability.
    """
    reset_strs = reset_str.replace("[","").replace("]","").split(",")
    resets = map(lambda x: int(x,0), reset_strs)
    return tuple(resets)

def parse_array_size(size_str):
    """
    Turn an array size from a Semifore CSV string into a tuple of ints

    Semifore CSV formats the size of an array as an int in square brackets.
    Multidimensional arrays are just a lot of these concatenated together:
    [i]
    [i][j][k]
    ...

    If the array is 1D this function will still output the size as a 1-element
    tuple, just for consistency of iterability.
    """
    size_strs = size_str.replace("]","").split("[")[1:]
    sizes = map(int, size_strs)
    if len(sizes) > 0:
        return tuple(sizes)
    else:
        return (1,)

def parse_csrcompiler_csv (filename, section_name):
    """
    Given a Semifore CSV file, parse it into a bunch of csr_object instances.
    Since the chip hierarchy is contained across multiple CSV files, each one
    has a unique "section name".

    @param  filename        The filename of the CSV file to parse
    @param  section_name    A string meaningfully describing the contents of
                            the CSV (eg, "memories" and "regs")
    @return A list of all addressmaps parsed out of the file.
    """

    csv_field_types = {
        "configuration",
        "userdefined configuration",
        "constant",
        "counter",
        "status",
        "hierarchicalInterrupt",
        "interrupt"
    }

    csv_addressmap_types = {
        "addressmap",
        "userdefined addressmap",
    }

    csv_register_types = {
        "register",
        "wide register",
        "userdefined register",
        "userdefined wide register",
    }

    csv_group_types = {
        "group",
        "userdefined group",
    }

    addr_maps = {}
    active_addr_map = None
    active_group = []
    active_reg = None
    active_reg_default = 0

    with open(filename, "rb") as csv_file:
        csv_reader = csv.DictReader(csv_file)
        row_num = 0
        for row in csv_reader:
            array_size = parse_array_size(row["Array"])

            if len(active_group) > 0:
                active_container = active_group[-1]
            else:
                active_container = active_addr_map

            if row["Type"] in csv_addressmap_types:
                addr_maps[row["Identifier"]] = address_map(
                    row["Identifier"],
                    array_size,
                    section_name
                )
                active_addr_map = addr_maps[row["Identifier"]]
            elif row["Type"] in csv_register_types:
                reg_width = int(row["Register Size"].replace(" bits",""),0)
                active_container.objs.append(reg(row["Identifier"], array_size, int(row["Offset"],0), reg_width, active_addr_map))
                active_reg = active_container.objs[-1]
                if row["Reset Value"] == "":
                    active_reg_default = 0
                else:
                    active_reg_default = int(row["Reset Value"],0)
            elif row["Type"] in csv_field_types:
                if len(array_size) > 1:
                    raise CsrException("Multi-dimensional field arrays not currently supported (in CSV file '"+filename+"' line "+str(row_num)+")")
                range_tokens = row["Position"].replace("[","").replace("]","").split(":")
                msb = int(range_tokens[0])
                if len(range_tokens) == 1:
                    lsb = msb
                else:
                    lsb = int(range_tokens[1])
                if row["Reset Value"] == "":
                    default = []
                    elem_width = msb-lsb+1
                    elem_mask = 2**elem_width - 1
                    for elem_idx in range(array_size[0]):
                        default_offset = lsb + elem_width*elem_idx
                        default_val = (active_reg_default >> default_offset) & elem_mask
                        default.append(default_val)
                    default = tuple(default)
                else:
                    default = parse_resets(row["Reset Value"])
                    if array_size != (1,):
                        if len(default) == 1:
                            default = default*array_size[0]
                        elif len(default) != array_size[0]:
                            raise CsrException("Field reset value list is not the same length as the field array itself (in CSV file '"+filename+"' line "+str(row_num)+")")

                active_reg.fields.append(field(row["Identifier"], array_size, msb, lsb, default, active_reg))
            elif row["Type"] == "addressmap instance":
                try:
                    stride = int(row["Stride"].replace(" bytes",""),0)
                except:
                    stride = addr_maps[row["Type Name"]].min_width()

                active_container.objs.append(
                    address_map_instance(
                        row["Identifier"],
                        array_size,
                        int(row["Offset"],0),
                        addr_maps[row["Type Name"]],
                        None if array_size == (1,) else stride
                    )
                )
            elif row["Type"] in csv_group_types:
                try:
                    stride = int(row["Stride"].replace(" bytes",""),0)
                except:
                    stride = None

                active_container.objs.append(
                    group (
                        row["Identifier"],
                        array_size,
                        int(row["Offset"],0),
                        section_name,
                        None if array_size == (1,) else stride
                    )
                )
                active_group.append(active_container.objs[-1])
            elif row["Type"] == "endgroup":
                popped_group = active_group.pop()
                if popped_group.stride == None:
                    popped_group.stride = popped_group.min_width()
            elif row["Type"] == "userdefined memory":
                # ignore for now?
                pass
            elif row["Type"] == "reserved":
                # ignore for now?
                pass
            else:
                raise CsrException("Unrecognized type '"+row["Type"]+"' in CSV file '"+filename+"' line "+str(row_num))

            row_num += 1

    return addr_maps


def build_schema (dir, walle_version):
    """
    Build a chip schema based on the top-level CSV files from Semifore

    The schema is a dictionary of dictionaries. The top-level keys are the
    "sections" of the chip's interface and metadata:
        - memories: Memories and large register arrays. Things like the parser
                    TCAM are found here. Taken from the <chip>_mem Semifore
                    hierarchy, in byte-granularity chip addresses
        - regs:     Registers, like statistics counters and MAU crossbars.
                    Taken from the <chip> Semifore hierarchy, in 32-bit PCIe
                    addresses
        - _schema_hash:  An MD5 hash of the CSV file contents used to generate
                    the rest of the schema

    The non-metadata entries contain a dictionary of all of that hierarchy's
    addressmaps, mapping from addressmap name to addrses_map objects.

    @param  dir     A string pointing to the directory containing (a copy of) the
                    bfnregs repo subdir "modules/<chip>_reg" generated by Semifore
                    using csr_config.css
    @return A new schema object
    """
    new_schema = {}
    schema_hash = 0
    hasher = hashlib.md5()

    version_file = os.path.join(dir, "..", "..", "VERSION")
    csv_files = os.path.join(dir, "module", "csv")
    if not os.path.isfile(version_file) or not os.path.isdir(csv_files):
        raise Exception("Directory '"+os.path.abspath(dir)+"' could not be opened, "+
                        "does not exist, or does not appear to be a valid bfnregs "+
                        "chip module.")

    for filename in os.listdir(csv_files):
        if filename.endswith(".csv"):
            key = os.path.splitext(filename)[0]
            if key == "pipe_top_level":
                key = "memories"
            elif key == "tofino":
                key = "regs"
            elif key.endswith("_mem"):
                key = "memories"
            elif key.endswith("_reg"):
                key = "regs"
            filename = os.path.join(csv_files, filename)

            new_schema[key] = parse_csrcompiler_csv(filename, key)

            with open(filename, "rb") as csv_file:
                hasher.update(csv_file.read())

    with open(version_file, "r") as version_file_handle:
        reg_version = version_file_handle.read()
        hasher.update(reg_version)

    new_schema["_reg_version"] = reg_version
    new_schema["_walle_version"] = walle_version
    new_schema["_schema_hash"] = hasher.hexdigest()

    return new_schema

# Unit tests
if __name__ == "__main__":
    y = reg("bar", (1,), 0, 32, None)
    y.fields.append(field("y1", (1,),  7,  0, y))
    y.fields.append(field("y2", (1,), 15,  8, y))
    y.fields.append(field("y3", (1,), 23, 16, y))
    y.fields.append(field("y4", (1,), 31, 24, y))
    data={
        "y1" : 0x30,
        "y2" : 0x32,
        "y3" : 0x34,
        "y4" : 0x36,
    }
    z = y.generate_binary(data, None, [traversal_history("root")])
    if z.value != "0246":
        print "ERROR: Expected 32-bit object to have string value '6420'"
        print "    32 bit value was " + z.value

    y = reg("baz", (1,), 0, 40, None)
    y.fields.append(field("y1", (1,),  7,  0, y))
    y.fields.append(field("y2", (1,), 15,  8, y))
    y.fields.append(field("y3", (1,), 23, 16, y))
    y.fields.append(field("y4", (1,), 31, 24, y))
    y.fields.append(field("y5", (1,), 39, 32, y))
    data={
        "y1" : 0x30,
        "y2" : 0x32,
        "y3" : 0x34,
        "y4" : 0x36,
        "y5" : 0x38,
    }
    z = y.generate_binary(data, None, [traversal_history("root")])
    if z.value != "02468":
        print "Expected 40-bit field to have string value '86420'"
        print "    40 bit value was " + z.value
