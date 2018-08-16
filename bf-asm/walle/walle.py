#!/usr/bin/env python
"""
Walle - JSON-to-binary cruncher tool
See README.md for usage instructions

The code is organized into three main modules:
    - walle: Command-line interface and glue code
    - csr: Code dealing with compiler-facing JSON files and raw Semifore CSV
        files
    - chip: Code dealing with driver-facing binary config files

The main program flow is, on a first run of Walle:
    - The csr module is used to parse Semifore CSV files into the classes
      that inherit from csr_object, each of which being a Python representation
      of a Semifore object.
    - These objects are pickled into a file called "chip.schema" so the raw CSV
      does not have to be used again or distributed with the toolchain.

Thereafter, Walle operates on JSON files that mirror the structure of the
Semifore hierarchy and assign integer values to register fields from the
schema. The details of this format are specified in the README.md fileself.
    - To generate blank JSON, the csr module will recursively call the
      generate_template() methods of the csr_objects in the schema.
    - To crunch JSON into binary, the csr module will recursively call
      generate_binary() methods of the csr_objects in the schema, passing
      along the relevent tree of JSON data. These methods create a flat list of
      objects that represent driver write operations, all of which are classes
      from the chip module that inherit from chip_obj.
    - The flat list of chip objects is looped over, calling each one's bytes()
      method which returns the actual binary string to be passed to the driver.
      These bytes are concatenated onto the binary file being output.
      The address of this write may be manipulated, since Semifore addresses
      are auto-generated and may need to be operated on before they appear as
      the chip expects (for instance, chip memories are word-addressed while
      Semifore addresses are byte-addressed)

It's important to note that all addresses calculated within one JSON file are
relative, so to produce correct chip addresses the binary __must__ be
calculated starting at a top-level addressmap in the Semifore hierarchy. When
expanding a JSON config to contain data instead of references to other JSON
files, Walle will alter the addresses calculated for the _included_ JSON
to be relative to the addresses in the _including_ JSON.
"""
import argparse
import sys
import os
import subprocess

import pickle
import json
import yaml
import copy

import csr
import chip

__version__ = '0.4.13'

########################################################################
## Utility functions

class CsrUnpickler(pickle.Unpickler):
    """
    This module is a hacky fix for a bug that sometimes shows up when using a
    chip.schema file generated across different systems.

    Specifically:
    On system A, walle is a globally installed package via setup.py and can
    be accessed from the terminal with the command 'walle'
    On system B, walle is NOT globally installed and instead accessed locally
    by directly pointing to walle.py

    The chip.schema files generated on A and B will encode Python classes
    from two different module paths. A will have classes from "walle.csr" while
    B will have classes from "csr". If we move a schema from one system to
    another, the module lookup will fail.

    We fix this by looking for references to classes from the 'csr' module and
    directly retrieving them from the csr module that this top-level script has
    already imported.
    """
    def find_class(self, module, name):
        if module == "csr" or module[-4:] == ".csr":
            return getattr(csr,name)
        else:
            return pickle.Unpickler.find_class(self, module, name)

def annotate_names (obj, threshold, path=""):
    if type(obj) is list:
        if threshold > 0 and len(obj) > threshold:
            for idx, elem in enumerate(obj):
                if type(elem) is dict:
                    elem["_absolute_name"] = path+"_"+str(idx)
                annotate_names(elem, threshold, path)
        else:
            for elem in obj:
                annotate_names(elem, threshold, path)
    elif type(obj) is dict:
        for key, elem in obj.items():
            annotate_names(elem, threshold, (path+"_" if len(path)>0 else "")+key)

def print_schema_info (schema_file, schema):
    hierarchies = []
    sys.stdout.write("file: "+schema_file+"\n")
    for key in schema:
        if key[0] == "_":
            sys.stdout.write(key[1:]+": "+str(schema[key])+"\n")
        else:
            hierarchies.append(key)
    sys.stdout.write("hierarchies: "+", ".join(hierarchies)+"\n")

def parse_template_args(args, params):
    """
    Extend argparse.Namespace with additional arguments for cpp generation
    from templates.yaml that may not exist as command line arguments
    FIXME -- should be a way to do this with ArgParse?
    """
    def bool_arg(args, attr, val):
        if not type(val) is bool:
            raise Exception("Attribute "+attr+" requires bool argument, got "+str(val))
        setattr(args, attr, val)
    def str_arg(args, attr, val):
        if not type(val) is str:
            raise Exception("Attribute "+attr+" requires string argument, got "+str(val))
        setattr(args, attr, val)
    def add_list_arg(args, attr, val): getattr(args, attr).append(val)
    def add_set_arg(args, attr, val): getattr(args, attr).add(val)
    def set_decl(args, attr, val): args.gen_decl = 'decl'
    def set_defn(args, attr, val): args.gen_decl = 'defn'

    options = {
        'checked_array': (True, bool_arg),
        'decl': (None, set_decl),
        'delete_copy': (False, bool_arg),
        'defn': (None, set_defn),
        'dump_unread': (False, bool_arg),
        'emit_binary': (False, bool_arg),
        'emit_fieldname': (False, bool_arg),
        'emit_json': (False, bool_arg),
        'enable_disable': (False, bool_arg),
        'expand_disabled_vector': (False, bool_arg),
        'gen_decl': ('both', str_arg),
        'global_types': (set(), add_set_arg),
        'global': (None, lambda args, attr, val: add_set_arg(args, 'global_types', val)),
        'include': ([], add_list_arg),
        'name': (None, str_arg),
        'namespace': (False, str_arg),
        'reverse_write': (False, bool_arg),
        'unpack_json': (False, bool_arg),
        'widereg': (False, bool_arg),
        'write_dma': (set(), add_set_arg)
    }

    if not hasattr(args, 'cpp_reserved'):
        args.cpp_reserved = set([
            "asm", "auto", "break", "case", "catch", "char", "class", "const", "continue",
            "default", "delete", "do", "double", "else", "enum", "extern", "float", "for",
            "friend", "goto", "if", "inline", "int", "long", "new", "operator", "private",
            "protected", "public", "register", "return", "short", "signed", "sizeof",
            "static", "struct", "switch", "template", "this", "throw", "try", "typedef",
            "union", "unsigned", "virtual", "void", "volatile", "while" ])
    for opt in options:
        if options[opt][0] is not None:
            if hasattr(args, opt):
                setattr(args, opt, copy.copy(getattr(args, opt)))
            else:
                setattr(args, opt, copy.copy(options[opt][0]))
    for p in params:
        s = p.split('=', 1)
        if p in options:
            options[p][1](args, p, True)
        elif p[0] == '-' and p[1:] in options:
            options[p[1:]][1](args, p[1:], False)
        elif s[0] in options:
            options[s[0]][1](args, s[0], s[1])
        elif p[:2] == "-I":
            args.include.append(p[2:])
        else:
            sys.stderr.write("Unknown parameter %s\n" % str(p));

    if args.enable_disable:
        args.cpp_reserved = args.cpp_reserved.copy()
        args.cpp_reserved.update(["disable", "disabled", "disable_if_unmodified",
                                  "disable_if_zero", "enable", "modified", "set_modified"])

def read_template_file(template_file, args, schema):
    with open(template_file, "rb") as template_objects_file:
        templatization_cfg = yaml.load(template_objects_file)
        top_level_objs = templatization_cfg["generate"]
        disabled_objs = templatization_cfg["ignore"]
        if "global" in templatization_cfg:
            parse_template_args(args, templatization_cfg["global"])
    for section_name, section in schema.items():
        if section_name not in top_level_objs:
            if section_name[0] != "_":
                sys.stderr.write("no template cfg for "+section_name+", ignoring\n");
            continue;
        for obj in top_level_objs[section_name]:
            section[obj].templatization_behavior = "top_level"
            section[obj].object_name = None
            if top_level_objs[section_name][obj] is None: continue
            for fname, params in top_level_objs[section_name][obj].items():
                for p in params:
                    if p[:5] == 'name=':
                        section[obj].object_name = p[5:]
                        break
        for obj in disabled_objs[section_name]:
            if section[obj].templatization_behavior != None:
                raise Exception(obj+" cannot be both templatized and ignored")
            section[obj].templatization_behavior = "disabled"
    return top_level_objs

def generate_templates (args, schema):
    if args.o == None:
        args.o = "templates"
    if not os.path.exists(args.o):
        os.makedirs(args.o)

    top_level_objs = read_template_file(args.generate_templates, args, schema)
    for section_name, section in schema.items():
        if section_name not in top_level_objs:
            continue;
        for top_level_obj in top_level_objs[section_name]:
            template = section[top_level_obj].generate_template(False)
            sizes = section[top_level_obj].generate_template(True)

            if args.template_indices != None:
                annotate_names(template, args.template_indices)
                annotate_names(sizes, args.template_indices)

            # Copy in schema metadata
            schema_metadata = [key for key in schema.keys() if key[0]=="_"]
            for metadata in schema_metadata:
                template[metadata] = schema[metadata]
                sizes[metadata] = schema[metadata]
            template["_section"] = section_name
            sizes["_section"] = section_name

            cfg_name = section_name+"."+top_level_obj+".cfg.json"
            with open(os.path.join(args.o, cfg_name), "wb") as outfile:
                json.dump(template, outfile, indent=4, sort_keys=True)
            size_name = section_name+"."+top_level_obj+".size.json"
            with open(os.path.join(args.o, size_name), "wb") as outfile:
                json.dump(sizes, outfile, indent=4, sort_keys=True)

def generate_cpp_file(outfile, top_level, args, schema):
    outfile.write("/* Autogenerated from %s and %s -- DO NOT EDIT */\n" % (
                  args.schema, args.generate_cpp))
    for incl in args.include:
        outfile.write('#include "%s"\n' % incl)
    if args.emit_json or args.emit_fieldname or args.dump_unread:
        outfile.write('#include "indent.h"\n')
    if args.unpack_json:
        outfile.write('#include "json.h"\n')
    if args.checked_array:
        outfile.write('#include "checked_array.h"\n')
    if args.emit_binary:
        outfile.write('#include "binary_output.h"\n')
    outfile.write('#include "ubits.h"\n')
    outfile.write('#include "register_reference.h"\n')
    if args.widereg:
        outfile.write('#include "widereg.h"\n')
    outfile.write('\n')
    if len(args.global_types) > 0:
        args.global_types_generated = {}
        top_level.gen_global_types(outfile, args, schema)
    if args.namespace:
        outfile.write('namespace %s {\n\n' % args.namespace)
    top_level.generate_cpp(outfile, args, schema)
    outfile.write(";\n")
    if args.namespace:
        outfile.write('\n}  // end namespace %s\n\n' % args.namespace)

def extend_args(args, params):
    """
    parse additional template arguments into a copy of 'args'
    """
    args = copy.copy(args)
    parse_template_args(args, params)
    return args

def generate_cpp (args, schema):
    if args.o == None:
        args.o = "gen"
    if not os.path.exists(args.o):
        os.makedirs(args.o)

    top_level_objs = read_template_file(args.generate_cpp, args, schema)
    for section_name, section in schema.items():
        if section_name not in top_level_objs:
            continue;
        for top_level_obj,files in top_level_objs[section_name].items():
            if files is None: continue
            for generate_file,params in files.items():
                generate_cpp_file(open(os.path.join(args.o, generate_file), "w"),
                                  section[top_level_obj], extend_args(args, params), schema)

def print_schema_text(args, schema):
    def do_print(indent, obj):
        for key,val in obj.items():
            if type(val) is str:
                print "%s%s: %s" % (indent, key, val)
            elif type(val) is dict:
                print "%s%s:" % (indent, key)
                do_print(indent+"  ", val)
            elif val.templatization_behavior == "top_level":
                print "%s%s:" % (indent, key)
                val.print_as_text(indent+"  ")

    read_template_file(args.print_schema, args, schema)
    do_print("", schema)

def build_binary_cache (args, schema):
    cache = csr.binary_cache(schema)
    try:
        for config_filename in args.configs:
            with open(config_filename, "rb") as configfile:
                try:
                    template = json.load(configfile)
                except:
                    sys.stderr.write("ERROR: Input file '"+config_filename+"' could not be decoded as JSON.\n")
                    sys.exit(1)

                if (type(template) is not dict or
                    "_name" not in template or
                    "_type" not in template):
                    sys.stderr.write("ERROR: Input file '"+config_filename+"' does not appear to be valid Walle configuration JSON.\n")
                    sys.exit(1)

                if ("_schema_hash" not in template or
                    template["_schema_hash"] != schema["_schema_hash"]):
                    sys.stderr.write("ERROR: Input file '"+config_filename+"' does not match the current chip schema.\n")
                    if not args.ignore_schema_mismatch:
                        sys.exit(1)

                cache.templates[template["_name"]] = template
    except IOError as e:
        sys.stderr.write("ERROR: Could not open '%s' for reading: %s (errno %i).\n"%(config_filename,e[1],e[0]))
        sys.exit(e[0])

    return cache

def dump_binary (args, binary_cache, out_file):
    addr_func = {
        # Memories are ram-word addressed, not byte addressed
        "memories": lambda addr: addr >> 4,

        # TODO: use actual func once model+indirect writes are fixed
        "regs": lambda addr: addr
        # # Regs are give in 32-bit PCIe address space and need to be
        # # converted to 42-bit chip address space
        # "regs": lambda addr: ((addr&0x0FF80000)<<14)|(addr&0x0007FFFF)
    }

    for template in args.top:
        try:
            path = []
            data = binary_cache.get_data(template, path=path)
            data_type = binary_cache.get_type(template)
        except csr.CsrException as e:
            # TODO: decompose:
            sys.stderr.write("ERROR: "+str(e)+"\n")
            tb = []
            for frame in path:
                tb.append("{"+frame.template_name+"}")
                arr_subscript = None
                for node in frame.path:
                    if type(node) is str:
                        tb.append(node)
                        if arr_subscript != None:
                            tb[-1] += arr_subscript
                            arr_subscript = None
                    elif type(node) is list:
                        arr_subscript = csr.array_str(node)
                    else:
                        tb.append(str(node))
            sys.stderr.write("Traceback: "+".".join(tb)+"\n")
            sys.exit(1)

        template_section = data_type.split(".")[0]
        for chip_obj in data:
            chip_obj.addr = addr_func[template_section](chip_obj.addr)
            out_file.write(chip_obj.bytes())

    if args.append_sentinel:
        out_file.write(chip.direct_reg(0xFFFFFFFF, 0).bytes())

def walle_process(parser, args=None):
    if len(args.top) == 0:
        args.top = ["memories.top", "regs.top"]

    if args.generate_schema != None:
        schema = csr.build_schema(args.generate_schema, __version__)
        with open(args.schema, "wb") as outfile:
            pickle.dump(schema, outfile, protocol=2)
            print "Schema generated from:\n"
            cmd = 'echo | git -C %s log -1' % args.generate_schema
            output = subprocess.check_output(cmd, shell=True)
            print(output)
            outfile.write('\n\n' + output)

        if args.generate_templates != None:
            if not os.path.isfile(args.schema):
                sys.stderr.write("ERROR: Schema file '"+os.path.abspath(args.schema)+
                                 "' could not be opened or does not exist.\n")
                sys.exit(1)
            generate_templates(args, schema)
    else:

        if not os.path.isfile(args.schema):
            sys.stderr.write("ERROR: Schema file '"+os.path.abspath(args.schema)+
                             "' could not be opened or does not exist.\n")
            sys.exit(1)

        with open(args.schema, "rb") as infile:
            schema = CsrUnpickler(infile).load()

        if args.schema_info:
            print_schema_info(os.path.abspath(args.schema), schema)
        elif args.dump_schema:
            print yaml.dump(schema)
        elif args.print_schema:
            print_schema_text(args, schema)
        elif args.generate_templates != None:
            generate_templates(args, schema)
        elif args.generate_cpp != None:
            generate_cpp(args, schema)
        else:
            if len(args.configs)==0:
                parser.print_help()
            else:
                if args.o == None:
                    args.o = "a.out"
                cache = build_binary_cache(args, schema)
                with open(args.o,"wb") as binfile:
                    dump_binary(args, cache, binfile)

                sys.stdout.write("Binary '"+args.o+"' generated successfully.\n")

def main():
    """
    The main entry point for the script
    """

    parser = argparse.ArgumentParser()
    parser.add_argument(
        '-v', '--version',
        action='version', version='%(prog)s ' + __version__
    )
    parser.add_argument(
        "--schema", '-s',
        metavar='SCHEMA-FILE',
        help="The chip schema to use",
        type=str,
        default="chip.schema"
    )
    parser.add_argument(
        "--schema-info",
        action='store_true',
        help="Print metadata stored in the selected chip schema and exit"
    )
    parser.add_argument(
        "--target", "-t",
        help="The chip target",
        type=str,
        default="tofino"
    )
    parser.add_argument(
        "--dump-schema",
        action='store_true',
        help="Dump chip schema as yaml"
    )
    parser.add_argument(
        "--print-schema",
        metavar='TOP-LEVEL-OBJS-FILE',
        type=str,
        help="Dump chip schema as (readable?) text"
    )
    parser.add_argument(
        "--generate-schema",
        metavar='BFNREGS-TARGET-DIR',
        type=str,
        help="Generate a chip schema from the bfnregs target regs directory",
        default=None
    )
    parser.add_argument(
        "--ignore-schema-mismatch",
        action='store_true',
        help="Attempt to crunch input files, even if they do not match the current chip schema",
    )
    parser.add_argument(
        "--generate-templates",
        metavar='TOP-LEVEL-OBJS-FILE',
        type=str,
        help="Generate an 'all-0s' template for each addressmap listed in the given top-level objects file",
    )
    parser.add_argument(
        "--generate-cpp",
        metavar='TOP-LEVEL-OBJS-FILE',
        type=str,
        help="Generate C++ code for each addressmap listed in the given top-level objects file",
    )
    parser.add_argument(
        "--template-indices",
        metavar='THRESHOLD',
        help="Include human-readable index keys for register arrays greater than the specified threshold size",
        type=int,
        default=None
    )
    parser.add_argument(
        "--append-sentinel",
        action='store_true',
        help="Append a direct register write to address 0xFFFFFFFF to the end of the binary output",
    )
    parser.add_argument(
        '--top',
        metavar='IDENTIFIER',
        type=str,
        action='append',
        default=[],
        help='Identifier of a template to generate binary config data for'
    )
    parser.add_argument(
        '-o',
        metavar='FILE',
        type=str,
        default=None,
        help='Name of file to write binary config data into (or directory to write templates into)'
    )
    parser.add_argument(
        'configs',
        metavar='CONFIG-FILE',
        type=str, nargs='*',
        help='A JSON configuration file to process'
    )

    args = parser.parse_args()
    if getattr( sys, 'frozen', False ) :
        # running as a bundle: look for the schema in the bundled directory
        args.schema = os.path.join(sys._MEIPASS, 'lib', args.target, 'chip.schema')
    walle_process(parser, args)


########################################################################
## Frontend logic

if __name__ == "__main__":
    main()
