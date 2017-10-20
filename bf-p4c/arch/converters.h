#ifndef BF_P4C_ARCH_CONVERTERS_H_
#define BF_P4C_ARCH_CONVERTERS_H_

#include <cmath>
#include "ir/ir.h"
#include "bf-p4c/arch/program_structure.h"
#include "frontends/p4/cloner.h"
#include "frontends/p4/coreLibrary.h"
#include "lib/safe_vector.h"

namespace BFN {

///////////////////////////////////////////////////////////////////////////////////////////////

class ControlConverter : public Transform {
 protected:
    ProgramStructure* structure;
    P4::ClonePathExpressions cloner;

 public:
    explicit ControlConverter(ProgramStructure* structure)
    : structure(structure) { CHECK_NULL(structure); }
    const IR::Node* postorder(IR::Member* node) override;
    const IR::Node* postorder(IR::Declaration_Instance* node) override;
    const IR::Node* postorder(IR::MethodCallExpression* node) override;
    const IR::Node* postorder(IR::MethodCallStatement* node) override;

    const IR::P4Control* convert(const IR::Node* node) {
        auto conv = node->apply(*this);
        auto result = conv->to<IR::P4Control>();
        BUG_CHECK(result != nullptr, "Conversion of %1% did not produce a control", node);
        return result;
    }
};

class IngressControlConverter : public ControlConverter {
 public:
    explicit IngressControlConverter(ProgramStructure* structure)
    : ControlConverter(structure) { CHECK_NULL(structure); }
    const IR::Node* preorder(IR::P4Control* node) override;
};

class EgressControlConverter : public ControlConverter {
 public:
    explicit EgressControlConverter(ProgramStructure* structure)
    : ControlConverter(structure) { CHECK_NULL(structure); }
    const IR::Node* preorder(IR::P4Control* node) override;
};

class IngressDeparserConverter : public ControlConverter {
 public:
    explicit IngressDeparserConverter(ProgramStructure* structure)
    : ControlConverter(structure) { CHECK_NULL(structure); }
    const IR::Node* preorder(IR::P4Control* node) override;
};

class EgressDeparserConverter : public ControlConverter {
 public:
    explicit EgressDeparserConverter(ProgramStructure* structure)
    : ControlConverter(structure) { CHECK_NULL(structure); }
    const IR::Node* preorder(IR::P4Control* node) override;
};

///////////////////////////////////////////////////////////////////////////////////////////////

class ParserConverter : public Transform {
 protected:
    ProgramStructure* structure;
    P4::ClonePathExpressions cloner;

 public:
    explicit ParserConverter(ProgramStructure* structure)
    : structure(structure) { CHECK_NULL(structure); }
    const IR::Node* postorder(IR::AssignmentStatement* node) override;
    const IR::Node* postorder(IR::Member* node) override;
    const IR::P4Parser* convert(const IR::Node* node) {
        auto conv = node->apply(*this);
        auto result = conv->to<IR::P4Parser>();
        BUG_CHECK(result != nullptr, "Conversion of %1% did not produce a parser", node);
        return result;
    }
};

class IngressParserConverter : public ParserConverter {
 public:
    explicit IngressParserConverter(ProgramStructure* structure)
    : ParserConverter(structure) { CHECK_NULL(structure); }
    const IR::Node* postorder(IR::P4Parser* node) override;
};

class EgressParserConverter : public ParserConverter {
 public:
    explicit EgressParserConverter(ProgramStructure* structure)
    : ParserConverter(structure) { CHECK_NULL(structure); }
    const IR::Node* postorder(IR::AssignmentStatement* node) override;
    const IR::Node* postorder(IR::P4Parser* node) override;
};

///////////////////////////////////////////////////////////////////////////////////////////////

class ExternConverter : public Transform {
 protected:
    ProgramStructure* structure;

 public:
    explicit ExternConverter(ProgramStructure* structure)
    : structure(structure) { CHECK_NULL(structure); }
    const IR::Node* postorder(IR::Member* node) override;
    const IR::Declaration_Instance* convertExternInstance(const IR::Node* node) {
        auto conv = node->apply(*this);
        auto result = conv->to<IR::Declaration_Instance>();
        BUG_CHECK(result != nullptr,
                  "Conversion of %1% did not produce an extern instance", node);
        return result;
    }
    const IR::MethodCallExpression* convertExternCall(const IR::Node* node) {
        auto conv = node->apply(*this);
        auto result = conv->to<IR::MethodCallExpression>();
        BUG_CHECK(result != nullptr,
                  "Conversion of %1% did not produce an extern method call", node);
        return result;
    }

    const IR::Statement* convertExternFunction(const IR::Node* node) {
        auto conv = node->apply(*this);
        auto result = conv->to<IR::Statement>();
        BUG_CHECK(result != nullptr,
                  "Conversion of %1% did not produce an extern method call", node);
        return result;
    }
};

class HashConverter : public ExternConverter {
 public:
    explicit HashConverter(ProgramStructure* structure)
    : ExternConverter(structure) { CHECK_NULL(structure); }
    const IR::Node* postorder(IR::MethodCallStatement* node) override;
};

class RandomConverter : public ExternConverter {
 public:
    explicit RandomConverter(ProgramStructure* structure)
    : ExternConverter(structure) { CHECK_NULL(structure); }
    const IR::Node* postorder(IR::MethodCallStatement* node) override;
};

class CounterConverter : public ExternConverter {
 public:
    explicit CounterConverter(ProgramStructure* structure)
    : ExternConverter(structure) { CHECK_NULL(structure); }
    const IR::Node* postorder(IR::Declaration_Instance* node) override;
    const IR::Node* postorder(IR::ConstructorCallExpression* node) override;
};

class DirectCounterConverter : public ExternConverter {
 public:
    explicit DirectCounterConverter(ProgramStructure* structure)
            : ExternConverter(structure) { CHECK_NULL(structure); }
    const IR::Node* postorder(IR::Declaration_Instance* node) override;
};

class MeterConverter : public ExternConverter {
 public:
    explicit MeterConverter(ProgramStructure* structure)
    : ExternConverter(structure) { CHECK_NULL(structure); }
    const IR::Node* postorder(IR::Declaration_Instance* node) override;
    const IR::Node* postorder(IR::ConstructorCallExpression* node) override;
    const IR::Node* postorder(IR::MethodCallExpression* node) override;
};

class DirectMeterConverter : public ExternConverter {
 public:
    explicit DirectMeterConverter(ProgramStructure* structure)
    : ExternConverter(structure) { CHECK_NULL(structure); }
    const IR::Node* postorder(IR::Declaration_Instance* node) override;
    const IR::Node* postorder(IR::MethodCallStatement* node) override;
};

///////////////////////////////////////////////////////////////////////////////////////////////

class ExpressionConverter : public Transform {
 protected:
    ProgramStructure* structure;

 public:
    explicit ExpressionConverter(ProgramStructure* structure)
    : structure(structure) { CHECK_NULL(structure); }
    const IR::Expression* convert(const IR::Node* node) {
        auto result = node->apply(*this);
        return result->to<IR::Expression>();
    }
    const IR::Member* convertMember(const IR::Node* node) {
        auto result = node->apply(*this);
        return result->to<IR::Member>();
    }
};

class TypeNameExpressionConverter : public ExpressionConverter {
    // mapping enum name from v1model to tofino
    ordered_map<cstring, cstring> enumsToTranslate = {
            {"HashAlgorithm", "HashAlgorithm_t"}, {"CounterType", "CounterType_t"},
            {"MeterType", "MeterType_t"},
            {"CloneType", nullptr},  // tofino has no mapping for CloneType
    };
    ordered_map<cstring, cstring> fieldsToTranslate = {
            {"crc16", "CRC16"}, {"csum16", "CSUM16"}, {"packets", "PACKETS"},
            {"bytes", "BYTES"}, {"packets_and_bytes", "PACKETS_AND_BYTES"},
            {"crc32", "CRC32"}, {"identity", "IDENTITY"}, {"random", "RANDOM"}};
 public:
    explicit TypeNameExpressionConverter(ProgramStructure* structure)
    : ExpressionConverter(structure) { CHECK_NULL(structure); }
    const IR::Node* postorder(IR::TypeNameExpression* node) override;
    const IR::Node* postorder(IR::Member* node) override;
};

class MemberExpressionConverter : public ExpressionConverter {
 public:
    explicit MemberExpressionConverter(ProgramStructure* structure)
    : ExpressionConverter(structure) { CHECK_NULL(structure); }
    const IR::Node* postorder(IR::Member* node) override;
};

class PathExpressionConverter : public ExpressionConverter {
 public:
    explicit PathExpressionConverter(ProgramStructure* structure)
    : ExpressionConverter(structure) { CHECK_NULL(structure); }
    const IR::Node* postorder(IR::Member* node) override;
};

///////////////////////////////////////////////////////////////////////////////////////////////

class StatementConverter : public Transform {
 protected:
    ProgramStructure* structure;

 public:
    explicit StatementConverter(ProgramStructure* structure)
    : structure(structure) { CHECK_NULL(structure); }
    const IR::Statement* convert(const IR::Node* node) {
        auto result = node->apply(*this);
        return result->to<IR::Statement>();
    }
};

class ParserPriorityConverter : public StatementConverter {
 public:
    explicit ParserPriorityConverter(ProgramStructure* structure)
    : StatementConverter(structure) { CHECK_NULL(structure); }
    const IR::Node* postorder(IR::AssignmentStatement* node) override;
};

class ParserCounterConverter : public StatementConverter {
 public:
    explicit ParserCounterConverter(ProgramStructure *structure)
    : StatementConverter(structure) { CHECK_NULL(structure); }

    const IR::Node* postorder(IR::AssignmentStatement *node) override;
};

class ParserCounterSelectionConverter : public StatementConverter {
 public:
    explicit ParserCounterSelectionConverter(ProgramStructure* structure)
    : StatementConverter(structure) { CHECK_NULL(structure); }

    const IR::Node* postorder(IR::Member* node) override;
};

}  // namespace BFN

#endif /* BF_P4C_ARCH_CONVERTERS_H_ */
