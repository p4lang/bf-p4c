#ifndef EXTENSIONS_BF_P4C_PARDE_REWRITE_PARSER_LOCALS_H_
#define EXTENSIONS_BF_P4C_PARDE_REWRITE_PARSER_LOCALS_H_
#include "collect_parser_usedef.h"
#include "bf-p4c/phv/phv_fields.h"
#include "bf-p4c/phv/phv_parde_mau_use.h"

class GetSelectFieldInfo : public Inspector {
    const PhvInfo& phv;
    /// Collect all select field in parser
    bool preorder(const IR::BFN::Select* select) override;
 public:
    /// A map of select fields to the states that use them
    ordered_map<const PHV::Field*, ordered_set<const IR::BFN::ParserState*>> select_field_to_state;
    explicit GetSelectFieldInfo(const PhvInfo& phv) : phv(phv) { }
    Visitor::profile_t init_apply(const IR::Node* root) override {
        select_field_to_state.clear();
        return Inspector::init_apply(root);
    }
};

class AddParserMatchDefs : public Modifier {
    const PhvInfo& phv;
    CollectParserInfo& parserInfo;
    const GetSelectFieldInfo& getSelectField;
    const PhvUse& uses;
    /// If this extract is the def of a temporary local variable used in select, then change
    /// the dest of this extract to type MatchLVal
    bool preorder(IR::BFN::Extract*) override;
 public:
    AddParserMatchDefs(const PhvInfo& phv, CollectParserInfo& parserInfo,
    const GetSelectFieldInfo& getSelectField, const PhvUse& uses) : phv(phv),
    parserInfo(parserInfo), getSelectField(getSelectField), uses(uses) { }
};

/// A parser can extract fields into temporary local variables and use it in select statements.
/// This pass looks for such extracts and changes the type of its destination to
/// IR::BFN::MatchLVal.
/// The main purpose of this is to avoid phv allocation of such local fields.

class RewriteParserMatchDefs : public PassManager {
 public:
    explicit RewriteParserMatchDefs(const PhvInfo& phv);
};

#endif /*EXTENSIONS_BF_P4C_PARDE_REWRITE_PARSER_LOCALS_H_*/
