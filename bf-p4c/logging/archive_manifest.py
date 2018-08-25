#!/usr/bin/env python

"""
archive_manifest.py: Defines the JSON schema for the compiler archive manifest.

Schema versions:
1.0.0 - initial schema
1.1.0 - add pipe_name to contexts node
1.2.0 - add command line arguments
"""

import jsl
import json
import inspect

major_version = 1
minor_version = 2
patch_version = 0

def get_schema_version():
    return "%s.%s.%s" % (str(major_version), str(minor_version), str(patch_version))

#### ENTRY FORMATS ####
class BFNCompilerArchive(jsl.Document):
    title = "BFNCompilerArchive"
    description = "Manifest file for a compiler archive"
    schema_version = jsl.StringField(required=True, description="Manifest schema version")
    target = jsl.StringField(required=True, description="Target device",
                             enum=['tofino', 'tofino2', 'tofino3'])
    architecture = jsl.StringField(required=True,description="P4_16 architecture (PISA for P4_14)",
                                   enum=['tna', 't2na', 'psa', 'PISA', 'v1model'])
    build_date = jsl.StringField(required=True,
                                 description="Timestamp of when the archive was built.")
    compiler_version = jsl.StringField(required=True,
                                       description="Compiler version used in compilation.")
    compiler_flags = jsl.StringField(required=False, description="Compiler cmmand line flags")
    programs = jsl.ArrayField(required=True, description="Array of compiled programs",
                              items=jsl.DocumentField("CompiledProgram", as_ref=True))

class CompiledProgram(jsl.Document):
    title = "CompiledProgram"
    description="Compiled program properties"
    program_name = jsl.StringField(required=True, description="Name of the compiled program.")
    p4_version = jsl.StringField(required=True, description="P4 version of program",
                                 enum=['p4-14', 'p4-16'])
    run_id = jsl.StringField(required=True, description="Unique ID for this compile run.")
    p4runtime_file = jsl.StringField(required=False, description="Path to the p4runtime file")
    contexts = jsl.ArrayField(required=True, description="Array of per pipe context.json files",
                              min_items=1,
                              items = jsl.DictField(required=True,
            properties = {
                "pipe": jsl.IntField(required=True, description="Logical id of the control flow"),
                "pipe_name" : jsl.StringField(required=True,
                                              description="Control flow name from P4 program"),
                "path": jsl.StringField(required=True, description="Path to the context.json file")
            })
    )
    # not needed for visualization, but needed if we go with a zip file
    binaries =  jsl.ArrayField(required=False,
                               description="Array of per pipe binary files (tofino.bin)",
                               items = jsl.DictField(required=False,
            properties = {
                "pipe": jsl.IntField(required=True, description="Logical id of the control flow"),
                "path": jsl.StringField(required=True, description="Path to the binary file")
            })
    )
    graphs =  jsl.ArrayField(required=True, description="List of graph files",
                             items = jsl.DictField(required=False,
            properties = {
                "graph_type": jsl.StringField(required=True,
                                             description="Type of graph",
                                             enum = ['parser', 'control']),
                # Right now we support only .dot files, in the future we may want other formats
                "graph_format": jsl.StringField(required=True,
                                                description="The format for the file."),
                "path": jsl.StringField(required=True,
                                        description="Path to the graph file")
            })
    )
    logs =  jsl.ArrayField(required=True, description="List of log files",
                           items = jsl.DictField(required=False,
            properties = {
                "log_type": jsl.StringField(required=True, description="Type of log",
                                           enum = ['parser', 'phv', 'mau', 'power']),
                "path": jsl.StringField(required=True, description="Path to the log file")
            })
    )
