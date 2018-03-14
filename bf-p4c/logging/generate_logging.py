#! /usr/bin/env python
#
# This script reads in a json schema document and generates a set of C++
# classes that allow logging to a json file that is compatible with the schema.
#

import argparse, os, sys
from string import maketrans
import json, jsonschema

def escape_cpp(to_translate, translate_to=u'_'):
    not_letters_or_digits = u'!"#%\'()*+,-./:;<=>?@[\]^_`{|}~'
    translate_table = dict((ord(char), translate_to) for char in not_letters_or_digits)
    return to_translate.translate(translate_table)

def ref2Type(reference):
    # print reference
    if reference.get('$ref', False):
        words = reference['$ref'].split('/')
        return words[-1]
    return "XXX"

class DataMember(object):
    def __init__(self, name, typeName = None, body = None, isOptional = False):
        self.name = name
        self.body = body
        self.typeName = typeName
        self.isOptional = isOptional
        self.description = None
        if body is not None and body.get('description', False):
            self.description = body['description']

    def cppType(self):
        raise "Must be implemented in derived class"
    def jsonType(self):
        raise "Must be implemented in derived class"
    def isBasicType(self):
        raise "Must be implemented in derived class"
    def isArrayType(self):
        raise "Must be implemented in derived class"
    def isObjectType(self):
        raise "Must be implemented in derived class"
    def defaultValue(self):
        raise "Must be implemented in derived class"
    def getDescription(self):
        if self.description is not None:
            return '/// ' + self.description

    def genTypeDecl(self, generator):
        # nothing by default
        return
    def memberName(self):
        return "_" + self.name
    def memberDecl(self):
        return self.cppType() + ' ' + self.memberName()
    def constructorParam(self):
        res = 'const ' + self.cppType() + ' ' + self.name
        if self.isOptional:
            res += ' = ' + self.defaultValue()
        return res
    def constructorInitializer(self):
        return self.memberName() + '('+ self.name + ')'
    def genAccessor(self, generator):
        generator.write(self.cppType() + ' get' + self.memberName() + '() const { ')
        generator.write('return ' + self.memberName() + '; }\n', None)
    def genSetter(self, generator, unique = True):
        return
    def serializeMember(self, varName = None):
        if varName is None:
            return self.memberName()
        return varName
    def genSerializer(self, generator, writeKey = True, isPtr = False):
        ref = ''
        if isPtr: ref = '*'
        if self.isOptional:
            generator.write('if (' + ref + self.memberName() + ' != ' +
                            self.defaultValue() + ') {\n')
            generator.incrIndent()
        if writeKey: generator.write('writer.Key("' + self.name + '");\n')
        generator.write('writer.' + self.jsonType() + '(' + ref + self.serializeMember() + ');\n')
        if self.isOptional:
            generator.decrIndent()
            generator.write('}\n')

class StringDataMember(DataMember):
    def cppType(self):
        return "std::string"
    def jsonType(self):
        return "String"
    def isBasicType(self):
        return True
    def isArrayType(self):
        return False
    def isObjectType(self):
        return False
    def defaultValue(self):
        return '""'
    def serializeMember(self, varName = None):
        return super(StringDataMember, self).serializeMember(varName) + '.c_str()'

class IntegerDataMember(DataMember):
    def cppType(self):
        return "int"
    def jsonType(self):
        return "Int"
    def isBasicType(self):
        return True
    def isArrayType(self):
        return False
    def isObjectType(self):
        return False
    def defaultValue(self):
        return 0

class NumberDataMember(DataMember):
    def cppType(self):
        return "double"
    def jsonType(self):
        return "Double"
    def isBasicType(self):
        return True
    def isArrayType(self):
        return False
    def isObjectType(self):
        return False
    def defaultValue(self):
        return 0.0

class EnumDataMember(DataMember):
    def __init__(self, name, typeName = None, body = None, isOptional = False):
        super(EnumDataMember, self).__init__(name, typeName, body, isOptional)
        self.enumMemberType = None
        self.enumMemberCount = 0
        self.defaultVal = 0
        for e in self.body['enum']:
            if not (isinstance(e, basestring) or isinstance(e, (int, long))):
                raise "Unknown enum type" + e
            if isinstance(e, basestring): self.enumMemberType = 'const char *'
            else:                         self.enumMemberType = 'long'
            self.enumMemberCount += 1

    def cppType(self):
        if self.typeName is None:
            return self.name + "_t"
        return self.typeName
    def jsonType(self):
        return "Uint"
    def isBasicType(self):
        return True
    def isArrayType(self):
        return False
    def isObjectType(self):
        return False
    def defaultValue(self):
        return self.defaultVal

    def serializeMember(self, varName = None):
        return  'int (' + super(EnumDataMember, self).serializeMember(varName) + ')'
    def genTypeDecl(self, generator):
        if self.body is None:
            raise 'Invalid body for enum', name
        decl = 'enum ' + self.cppType() + ' { '
        first = True
        for e in self.body['enum']:
            if isinstance(e, basestring): item = e.upper()
            else:                         item = u'I_' + str(e)

            if not first:
                decl += ', '
            else:
                self.defaultVal = escape_cpp(item)
                first = False
            decl += escape_cpp(item)
        decl += ' }'
        generator.write(decl + ';\n')

    def genSerializer(self, generator, writeKey = True, isPtr = False):
        if writeKey: generator.write('writer.Key("' + self.name + '");\n')
        mapName = self.name + '_toEnumVal'
        generator.write('static std::array<' + self.enumMemberType + ', ' +
                        str(self.enumMemberCount) + '> ' + mapName + ' {{ ')
        first = True
        for e in self.body['enum']:
            if isinstance(e, basestring):
                val = '"' + e + '"'
            else:
                val = e
            if not first: generator.write(', ', None)
            else: first = False
            generator.write(str(val), None)
        generator.write(' }};\n', None)
        ref = ''
        if isPtr: ref = '*'
        if self.enumMemberType == 'long':
            generator.write('writer.Uint64(' + mapName + '[' + ref + self.memberName() + ']);\n')
        else:
            generator.write('writer.String(' + mapName + '[' + ref + self.memberName() + ']);\n')


class UnionDataMember(DataMember):
    def __init__(self, name, typeName, body, isOptional):
        super(UnionDataMember, self).__init__(name, typeName, body, isOptional)
        self.dataMembers = []
        i = 0
        for p in self.body['oneOf']:
            memberName = "data" + str(i)
            self.dataMembers.append(getDataMember(memberName, p, name + '_type_t'))
            i += 1
    def cppType(self):
        return self.name + '_t'
    def jsonType(self):
        return 'Int'
    def isBasicType(self):
        return True
    def isArrayType(self):
        return False
    def isObjectType(self):
        return True
    def defaultValue(self):
        return self.dataMembers[0].defaultValue()
    def serializeMember(self, varName = None):
        return self.memberName() + "._data0"
    def genTypeDecl(self, generator):
        for p in self.dataMembers:
            if isinstance(p, EnumDataMember):
                p.genTypeDecl(generator)
        generator.write('class ' + self.cppType() + ' {\n')
        generator.incrIndent()
        for p in self.dataMembers:
            generator.write(p.cppType() + ' *' + p.memberName() + ';\n')
        generator.write('public:\n')
        for p in self.dataMembers:
            generator.write(self.cppType() + '(const ' + p.cppType() + ' e) {\n')
            generator.incrIndent()
            generator.write(p.memberName() + ' = new ' + p.cppType() + '(e);\n')
            for q in self.dataMembers:
                if q != p:
                    generator.write(q.memberName() + ' = nullptr;\n')
            generator.decrIndent()
            generator.write('}\n')
        self.genSerializerMethod(generator)
        generator.decrIndent()
        generator.write('};\n')

    def genSerializerMethod(self, generator):
        generator.write('/// serializer\n')
        generator.write('virtual void serialize(Writer &writer) const {\n')
        generator.incrIndent()
        generator.write('writer.Key("' + self.name + '");\n')
        # only one of the data members is not null
        for p in self.dataMembers:
            generator.write('if (' + p.memberName() + ' != nullptr) {\n')
            if isinstance(p, EnumDataMember):
                generator.incrIndent()
                p.genSerializer(generator, writeKey = False, isPtr = True)
                generator.decrIndent()
            else:
                generator.write('writer.' + p.jsonType() + '(*' + p.serializeMember() + ');\n',
                                generator.indentIncr)
            generator.write('}\n')
        generator.decrIndent()
        generator.write('}\n')

    def genSerializer(self, generator, writeKey = True, isPtr = False):
        ref = '.'
        if isPtr: ref = '->'
        generator.write(self.memberName() + ref + 'serialize(writer);\n')

class ArrayDataMember(DataMember):
    def __init__(self, name, typeName, body, isOptional):
        super(ArrayDataMember, self).__init__(name, typeName, body, isOptional)
        self.elemType = getDataMember(name.title(), body['items'])

    def cppType(self):
        ptr = ''
        if self.elemType.isObjectType(): ptr = ' *'
        return 'std::vector<' + self.elemType.cppType() + ptr + '>'
    def jsonType(self):
        return 'Array'
    def isBasicType(self):
        return False
    def isArrayType(self):
        return True
    def isObjectType(self):
        return False
    def defaultValue(self):
        return 'nullptr'

    def genAccessor(self, generator):
        generator.write(self.cppType() + '& get' + self.memberName() + '() { ')
        generator.write('return ' + self.memberName() + '; }\n', None)
    def genSerializer(self, generator, writeKey = True, isPtr = False):
        if writeKey: generator.write('writer.Key("' + self.name + '");\n')
        generator.write('writer.StartArray();\n')
        generator.write('for ( auto e : ' + self.memberName() + ')\n')
        if self.elemType.isObjectType():
            generator.write('e->serialize(writer);\n', generator.indentIncr)
        else:
            generator.write('writer.' + self.elemType.jsonType() + '(' +
                            self.elemType.serializeMember('e') + ');\n', generator.indentIncr)
        generator.write('writer.EndArray();\n')
    def genSetter(self, generator, unique = True):
        ptr = ' '
        if self.elemType.isObjectType(): ptr = ' *'
        methodName = 'append'
        if not unique: methodName += self.memberName()
        generator.write('void ' + methodName +'(' + self.elemType.cppType() + ptr + 'item) {\n')
        generator.write(self.memberName() + '.push_back(item);\n', generator.indentIncr)
        generator.write('}\n')

class ObjectDataMember(DataMember):
    def __init__(self, name, typeName, body, isOptional):
        super(ObjectDataMember, self).__init__(name, typeName, body, isOptional)
    def cppType(self):
        return self.name
    def jsonType(self):
        return 'Object'
    def isBasicType(self):
        return False
    def isArrayType(self):
        return False
    def isObjectType(self):
        return True
    def defaultValue(self):
        return 'nullptr'

def getDataMember(name, body, typeName = None, isOptional = False):
    # print name, '->', body
    if body.get('enum', False):
        return EnumDataMember(name, typeName, body, isOptional)
    if body.get('type', False):
        if body['type'] == 'integer':
            return IntegerDataMember(name, isOptional = isOptional)
        if body['type'] == 'string':
            return StringDataMember(name, isOptional = isOptional)
        if body['type'] == 'array':
            return ArrayDataMember(name, typeName, body, isOptional)
        if body['type'] == 'object':
            return ObjectDataMember(name, typeName, body, isOptional)
    if body.get('$ref', False):
        return ObjectDataMember(ref2Type(body), typeName, body, isOptional)
    if body.get('oneOf', False):
        return UnionDataMember(name, typeName, body, isOptional)

    raise "Unhandled:", name, body

class ClassGenerator:
    def __init__(self, generator, className, classBody, root = None):
        self.className = className
        self.classBody = classBody
        self.root = root
        self.generator = generator
        self.subClasses = []

        print ' '*generator.indent, 'class ', className
        # print classBody
        # order all classes such that we generate first the ones that do not have any subclasses
        if classBody.get('definitions', False):
            for d in classBody['definitions']:
                # print ' '*generator.indent, ' ----> ', d
                forwardClass = getDataMember(d, classBody['definitions'][d])
                if forwardClass.isObjectType():
                    self.subClasses.append(forwardClass)

        # class declarations inside properties
        if classBody.get('properties', False):
            for p in classBody['properties']:
                prop = classBody['properties'][p]
                isRequired = p in classBody['required']
                forwardClass = getDataMember(p, prop, isOptional = not isRequired)
                if forwardClass.isArrayType():
                    arrayElem = forwardClass.elemType
                    subClsNames = [ c.name for c in self.subClasses ]
                    # print 'found subclass ', arrayElem.name, 'in?', subClsNames, self.generator.classes
                    if arrayElem.isObjectType() and \
                       arrayElem.name not in subClsNames and \
                       arrayElem.name not in self.generator.classes:
                        # print 'appending', arrayElem.name
                        self.subClasses.insert(0, arrayElem)
                    if forwardClass.isObjectType():
                        self.subClasses.append(forwardClass)

        for c in self.subClasses:
            self.generator.classes.add(c.name)

        # retrieve the data members and list the required ones first
        self.dataMembers = []
        optionalMembers = []
        for p in classBody['properties']:
            isOptional = p not in classBody['required']
            m = getDataMember(p, classBody['properties'][p], isOptional = isOptional)
            if isOptional: optionalMembers.append(m)
            else:          self.dataMembers.append(m)
        self.dataMembers.extend(optionalMembers)
        # names = [ (m.name, m.isOptional) for m in self.dataMembers ]
        # print names

    def write(self, stmt, indent = 0):
        self.generator.write(stmt, indent)

    def generate(self, indent = False):
        if indent: self.generator.incrIndent()

        if self.classBody.get('description', False):
            self.write('/// ' + self.classBody['description'] + '\n')
            # ostream.write('/// ' + str(schema_json['definitions'][d]) + '\n')
        if self.classBody['type'] != "object":
            self.write('/// TODO: handle ' + self.className + ' ' + self.classBody['type'])
            return

        self.write('class ' + self.className)
        if self.root is not None:
            self.write(' : public ' + self.root, None)
        self.write(' {\n', None)
        self.write('public:\n')
        self.generator.incrIndent()

        # forward declare all classes in this scope so that they can be used
        self.write('/// forward declarations\n')
        for c in self.subClasses:
            self.write('class ' + c.cppType() + ';\n')

        # declare the types for object and enum properties
        self.write('/// type declarations\n')
        # generate subclasses
        for c in self.subClasses:
            cls = ClassGenerator(self.generator, c.name, c.body)
            cls.generate(indent=True)
        # types for other data members
        for d in self.dataMembers:
            d.genTypeDecl(self.generator)

        # declare the data members
        self.write('private:\n', indent = -2)
        for d in self.dataMembers:
            self.write(d.memberDecl() + ';\n') #  + d.getDescription() + '\n')

        self.write('public:\n', indent = -2)

        # constructor
        self.genConstructor()
        # destructor
        self.genDestructor()

        # accessors
        self.write('\n', None)
        self.write('/// accessors\n')
        for d in self.dataMembers:
            d.genAccessor(self.generator)

        # setters
        self.write('/// setters\n')
        for d in self.dataMembers:
            arrayMembers = [ m for m in self.dataMembers if m.isArrayType() ]
            d.genSetter(self.generator, unique = (len(arrayMembers) < 2))

        # serializer
        self.write('/// serializer\n')
        isOverride = ''
        if self.root is not None: isOverride = ' override'
        self.write('virtual void serialize(Writer &writer) const' + isOverride + ' {\n')
        self.generator.incrIndent()
        self.write('writer.StartObject();\n')
        for d in self.dataMembers:
            d.genSerializer(self.generator)
        self.write('writer.EndObject();\n')
        self.generator.decrIndent()
        self.write('}\n')

        self.generator.decrIndent()
        self.write('};\n\n')
        if indent: self.generator.decrIndent()

    def genConstructor(self):
        self.write('// Constructor\n')
        self.write(self.className + '(')
        argIndent = len(self.className) + 1;
        indent = self.generator.indent + argIndent
        first = True
        for d in self.dataMembers:
            if not d.isBasicType(): continue
            if not first: self.write(',\n' + ' '*indent, None)
            else:         first = False
            self.write(d.constructorParam(), None)
        self.write(')', None)


        self.generator.incrIndent()
        if self.root is not None:
            self.write(': Logger("' + self.className + '.json")', None)
        first = self.root is None
        for d in self.dataMembers:
            if not d.isBasicType(): continue
            if not first:
                self.write(',\n', None)
            else:
                self.write(': \n', None)
                first = False
            self.write(d.constructorInitializer())

        self.write(' { }\n', None)
        self.generator.decrIndent()

    def genDestructor(self):
        self.write('// Destructor\n')
        self.write('virtual ~' + self.className + '() {\n')
        self.generator.incrIndent()
        for d in self.dataMembers:
            if d.isBasicType(): continue
            if d.isObjectType():
                self.write('delete ' + d.memberName() + ';\n')
            if d.isArrayType() and d.elemType.isObjectType():
                self.write('for (auto e : ' + d.memberName() + ') ')
                self.write('delete e;\n', None)
        self.generator.decrIndent()
        self.write('}\n')


class Generator:
    def __init__(self, schema, file_name, output_dir):
        self.schema = schema
        self.ostream = open(os.path.join(output_dir, file_name + ".h"), "w")
        self.define = "_EXTENSIONS_" + file_name.upper() + "_H_"
        # classes that we have already generated code for
        self.classes = set()
        self.indent = 0
        self.indentIncr = 2

    def generate(self):
        """ main generation function for the root object """
        self.genPreamble()
        cls = ClassGenerator(self, file_name.title() + "_Logger", self.schema, root="Logger")
        cls.generate(self)
        self.genEpilog()



    def genPreamble(self):
        self.write('// Automatically generated file, please do not modify!\n')
        self.write('//\n')
        self.write('#ifndef ' + self.define + '\n')
        self.write('#define ' + self.define + '\n')
        self.write('\n')
        self.write('#include <array>\n')
        self.write('#include <memory>\n')
        self.write('#include <string>\n')
        self.write('#include <vector>\n')
        self.write('#include <lib/cstring.h>\n')
        self.write('#include <logging.h>\n')
        self.write('namespace Logging {\n')
        self.write('\n')

    def genEpilog(self):
        self.write('}  // end namespace Logging\n')
        self.write('#endif  /** ' + self.define + ' */\n')

    # output helper functions
    def write(self, stmt, indent = 0):
        if indent is not None:
            self.ostream.write(' ' * (self.indent + indent) + stmt)
        else:
            self.ostream.write(stmt)
    def incrIndent(self):
        self.indent += self.indentIncr
    def decrIndent(self):
        self.indent -= self.indentIncr



parser=argparse.ArgumentParser()

parser.add_argument ("-o", "--output", action="store", default=None,
                     help="generate code in the output directory")
parser.add_argument ("-g", "--debug", dest="debug", action="store_true", default=False,
                     help="debug")
parser.add_argument ("schemas", metavar="schemas", type=str, nargs='+',
                     default=None, help="schema(s) to generate code for")
opts = parser.parse_args()

if opts.schemas is None:
    print "Need a schema to generate code from"
    sys.exit(1)

if opts.output is None:
    opts.output = "./"

for schema in opts.schemas:
    schema_json = json.load(open(schema, 'r'))
    file_name, ext = os.path.splitext(os.path.basename(schema))
    gen = Generator(schema_json, file_name, opts.output)
    gen.generate()
