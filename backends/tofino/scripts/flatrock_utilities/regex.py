# regex.py
# A script to generate regex to filter flatrock model log.
import os
import sys
import yaml
from yaml import Loader, Dumper

def load_bfa(bfa_file, schema_file):
    bfa_objs = []
    schema_objs = []
    with open(bfa_file, "rb") as bfa_obj_file:
        bfa_objs = yaml.load(bfa_obj_file, Loader=yaml.SafeLoader)
    with open(schema_file, "rb") as schema_obj_file:
        schema_objs = yaml.load(schema_obj_file, Loader=yaml.SafeLoader)
    return bfa_objs, schema_objs

class Table:
    properties = {}
    schema = {}
    def __init__(self, properties, schema):
        self.properties = properties
        self.schema = schema

    def regex_for_common_properties():
        pass

class ExactMatch(Table):
    def __init__(self, properties, schema):
        super(ExactMatch, self).__init__(properties, schema)

class HashAction(Table):
    def __init__(self, properties, schema):
        super(HashAction, self).__init__(properties, schema)

    def regex(self, stage, gress):
        output = []
        ppu = "I::Ppu" if (gress == "ingress") else "E::Ppu"
        for item in self.schema:
            if type(item) is dict:
                continue
            elif type(item) is str:
                output.append("producing.*{}-{}.*{}".format(ppu, stage, item))
            else:
                raise ValueError("Unhandled schema type: ", type(item))
        return output

def main():
    regex = []
    bfa_objs, schema_objs = load_bfa(sys.argv[1], os.path.dirname(os.path.abspath(__file__)) + "/regex.schema")
    for section_name, section in bfa_objs.items():
        section_type = section_name.split(" ")
        if section_type[0] != "stage":
            continue
        stage = section_type[1]
        gress = section_type[2]
        if section is None:
            continue
        for table, properties in section.items():
            table_type = table.split(" ")[0]
            if table_type == "hash_action":
                schema = schema_objs[table_type]
                hash_action = HashAction(properties, schema)
                regex.extend(hash_action.regex(stage, gress))
            elif table_type == "exact_match":
                exact_match = ExactMatch(properties, schema)
            else:
                raise ValueError("Unhandled table type ", table_type)

    print("grep '" + "\|".join(regex) + "'")

if __name__ == "__main__":
    main()
