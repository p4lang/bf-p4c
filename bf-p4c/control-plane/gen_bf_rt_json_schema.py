#!/usr/bin/env python2

# This script generates a JSON schema for the BF-RT schema file. It can also
# validate teh BF-RT schema produced by the compiler (from the P4Info message)
# against the JSON schema.

import argparse
import jsl
import json
import jsonschema
import sys

class NamedObject(jsl.Document):
    id_ = jsl.IntField(name="id", required=True, description="ID of the key field")
    name = jsl.StringField(required=True, decription="Name")

class Annotation(jsl.Document):
    class Options(object):
        title = "Annotation"
        description = "Annotation on an object, propagated from P4 source"
    name = jsl.StringField(required=True)
    value = jsl.StringField(required=False)

Annotations = jsl.ArrayField(required=True, items=jsl.DocumentField(Annotation, as_ref=True))

MatchType = jsl.StringField(
    required=True,
    enum=["Exact", "Ternary", "LPM", "Range"],
    description = "Type of the match key field")

class PrimitiveTypeBase(jsl.Document):
    pass

PrimitiveIntTypes = [
    "int8", "int16", "int32", "int64",
    "uint8", "uint16", "uint32", "uint64",
]

class PrimitiveIntType(PrimitiveTypeBase):
    class Options(object):
        title = "PrimitiveIntType"
        description = "A fixed-width integer type"
    type_ = jsl.StringField(name="type", required=True, enum=PrimitiveIntTypes)
    default_value = jsl.IntField(required=False)

class PrimitiveBoolType(PrimitiveTypeBase):
    class Options(object):
        title = "PrimitiveBoolType"
        description = "Boolean type"
    type_ = jsl.StringField(name="type", required=True, enum=["bool"])
    default_value = jsl.BooleanField(required=False)

class PrimitiveBytesType(PrimitiveTypeBase):
    class Options(object):
        title = "PrimitiveBytesType"
        description = "A fixed-width bitvector type"
    type_ = jsl.StringField(name="type", required=True, enum=["bytes"])
    width = jsl.IntField(required=False)
    default_value = jsl.StringField(required=False)

PrimitiveType = jsl.OneOfField(
    name="type",
    required=True,
    fields=[jsl.DocumentField(PrimitiveIntType, as_ref=True),
            jsl.DocumentField(PrimitiveBoolType, as_ref=True),
            jsl.DocumentField(PrimitiveBytesType, as_ref=True)]
)

class BaseDataField(NamedObject):
    annotations = Annotations
    type_ = PrimitiveType
    repeated = jsl.BooleanField(required=True)

class KeyField(BaseDataField):
    class Options(object):
        title = "KeyField"
        description = "Table key specification"
    match_type = MatchType
    mandatory = jsl.BooleanField(required=True)
    repeated = jsl.BooleanField(required=True, enum=[False])

class CommonDataIface(jsl.Document):
    mandatory = jsl.BooleanField(required=True)
    read_only = jsl.BooleanField(required=True)

class SingletonData(CommonDataIface):
    class Options(object):
        title = "SingletonData"
        description = "A single action data field"
    singleton = jsl.DocumentField(
        required=True,
        document_cls=BaseDataField,
        as_ref=True)

class OneOfData(CommonDataIface):
    class Options(object):
        title = "OneOfData"
        description = "Union of possible action data fields"
    oneof = jsl.ArrayField(
        required=True,
        items=jsl.DocumentField(BaseDataField, as_ref=True))

# we could use a "singleton" field as well, but I believe that the increased
# uniformity is not required and would not make parsing easier in the drivers.
class ActionDataField(BaseDataField):
    class Options(object):
        title = "ActionDataField"
        description = "Action parameter specification"
    mandatory = jsl.BooleanField(required=True)
    repeated = jsl.BooleanField(required=True, enum=[False])

class ActionSpec(NamedObject):
    class Options(object):
        title = "ActionSpec"
        description = "List of action specifications; for each action we have a description of all action parameters"
    data = jsl.ArrayField(
        required=True, items=jsl.DocumentField(ActionDataField, as_ref=True))

class TableCommon(NamedObject):
    class Options(object):
        title = "Table"
        description = "Table object which can be controlled through BF-RT; can be either a P4 table or a fixed table"
    table_type = jsl.StringField(required=True)
    size = jsl.IntField(required=False)
    key = jsl.ArrayField(required=True,
                         items=jsl.DocumentField(KeyField, as_ref=True))
    # no support for recursive one-of because no use-case
    data = jsl.ArrayField(
        required=True,
        items=jsl.OneOfField(fields=[
            jsl.DocumentField(SingletonData, as_ref=True),
            jsl.DocumentField(OneOfData, as_ref=True)]),
        description="All 'common' action data fields for the table")
    attributes = jsl.ArrayField(required=True, items=jsl.StringField())
    supported_operations = jsl.ArrayField(required=True, items=jsl.StringField())

# TODO(antonin): is there a more elegant way to enfore the presence of
# action_spec based on the type of the table?

class TableWithActionSpec(TableCommon):
    class Options(object):
        title = "TableWithActionSpec"
        description = "Table object with action specs which can be controlled through BF-RT; must be a direct match-action table or an action table"
    table_type = jsl.StringField(
        required=True,
        enum=["MatchAction_Direct", "Action"])
    action_specs = jsl.ArrayField(
        required=True,
        items=jsl.DocumentField(ActionSpec, as_ref=True),
        description="P4 actions for the table")

class TableWithoutActionSpec(TableCommon):
    class Options(object):
        title = "TableWithoutActionSpec"
        description = "Table object without action specs which can be controlled through BF-RT"
    table_type = jsl.StringField(
        required=True,
        enum=["MatchAction_Indirect",
              "MatchAction_Indirect_Selector",
              "Selector",
              "Counter", "Meter", "Register",
              "PortMetadata"])

class LearnListFieldField(BaseDataField):
    class Options(object):
        title = "LearnListField"
        description = "Field entry in learn list"
    repeated = jsl.BooleanField(required=True, enum=[False])

class LearnList(NamedObject):
    class Options(object):
        title = "LearnList"
        description = "One learn list, corresponds to one digest emit call in program"
    fields = jsl.ArrayField(
        required=True,
        items=jsl.DocumentField(LearnListFieldField, as_ref=True))

class BfRtSchema(jsl.Document):
    # TODO(antonin): metadata information, e.g. program name
    tables = jsl.ArrayField(
        required=True,
        items=jsl.OneOfField(fields=[
            jsl.DocumentField(TableWithActionSpec, as_ref=True),
            jsl.DocumentField(TableWithoutActionSpec, as_ref=True)]),
        description="All table objects (fixed tables and P4 tables)")
    learn_filters = jsl.ArrayField(
        required=True,
        items=jsl.DocumentField(LearnList, as_ref=True),
        description="All learn lists from the P4 program")

def main():
    parser = argparse.ArgumentParser(
        description='BF-RT Json schema generator and validator')
    parser.add_argument('--dump-schema', action='store', required=False,
                        help='Dump the schema to this file')
    parser.add_argument('input_json', nargs='?',
                        help='Json file to validate')
    args = parser.parse_args()

    schema = BfRtSchema.get_schema()
    if args.dump_schema:
        with open(args.dump_schema, 'w') as schema_f:
	    json.dump(schema, schema_f, indent=4)
    if args.input_json:
        with open(args.input_json, 'r') as input_f:
            bf_rt_json = json.load(input_f)
            try:
                jsonschema.validate(bf_rt_json, schema)
            except jsonschema.ValidationError as e:
                print "Error when validating JSON"
                print e
                sys.exit(1)
    sys.exit(0)

if __name__ == '__main__':
    main()
