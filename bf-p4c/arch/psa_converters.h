#ifndef BF_P4C_ARCH_PSA_CONVERTERS_H_
#define BF_P4C_ARCH_PSA_CONVERTERS_H_

#include <cmath>
#include "ir/ir.h"
#include "bf-p4c/arch/psa_program_structure.h"
#include "frontends/p4/cloner.h"
#include "frontends/p4/coreLibrary.h"
#include "lib/safe_vector.h"

namespace BFN {

namespace PSA {

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
};

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

class ExternConverter : public Transform {
 protected:
    ProgramStructure* structure;

 public:
    explicit ExternConverter(ProgramStructure* structure)
        : structure(structure) { CHECK_NULL(structure); }
    const IR::Node* convert(const IR::Node* node) {
        auto conv = node->apply(*this);
        return conv;
    }
};

class ParserConverter : public Transform {
 protected:
    ProgramStructure* structure;
    P4::ClonePathExpressions cloner;

 public:
    explicit ParserConverter(ProgramStructure* structure)
        : structure(structure) { CHECK_NULL(structure); }
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
    const IR::Node* postorder(IR::P4Parser* node) override;
};

class ControlConverter : public Transform {
 protected:
    ProgramStructure* structure;
    P4::ClonePathExpressions cloner;

 public:
    explicit ControlConverter(ProgramStructure* structure)
        : structure(structure) { CHECK_NULL(structure); }
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


class PathExpressionConverter : public ExpressionConverter {
 public:
    explicit PathExpressionConverter(ProgramStructure* structure)
        : ExpressionConverter(structure) { CHECK_NULL(structure); }
    const IR::Node* postorder(IR::Member* node) override;
};

}  // namespace PSA

}  // namespace BFN

#endif /* BF_P4C_ARCH_PSA_CONVERTERS_H_ */
