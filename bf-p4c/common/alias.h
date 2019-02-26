#ifndef EXTENSIONS_BF_P4C_COMMON_ALIAS_H_
#define EXTENSIONS_BF_P4C_COMMON_ALIAS_H_

#include "ir/ir.h"
#include "bf-p4c/bf-p4c-options.h"
#include "bf-p4c/phv/phv_fields.h"
#include "bf-p4c/phv/pragma/pa_alias.h"

/** This class generates a fieldExpressions map that stores a representative IR::Expression object
  * corresponding to each field in the program.
  */
class FindExpressionsForFields : public Inspector {
 private:
    /// PhvInfo object.
    const PhvInfo& phv;
    /// Map of IR::Expression objects corresponding to the field names.
    ordered_map<cstring, const IR::Member*>& fieldNameToExpressionsMap;

    profile_t init_apply(const IR::Node* root) override;
    bool preorder(const IR::HeaderOrMetadata* h) override;

 public:
    FindExpressionsForFields(const PhvInfo& p, ordered_map<cstring, const IR::Member*>& f)
        : phv(p), fieldNameToExpressionsMap(f) { }
};

/** This class replaces all uses of alias source fields with the corresponding alias destination
  * fields. It uses the fieldExpressions map populated by the FindExpressionsForFields pass to
  * generate new expressions.
  */
class ReplaceAllAliases : public Transform {
 private:
    /// PhvInfo object.
    const PhvInfo& phv;
    /// Aliasing information from the @pa_alias pragma.
    const PragmaAlias& pragmaAlias;
    /// Map of IR::Expression objects corresponding to the alias destination fields.
    const ordered_map<cstring, const IR::Member*>&    fieldExpressions;

    profile_t init_apply(const IR::Node* root) override;
    IR::Node* preorder(IR::Expression* expr) override;

 public:
    ReplaceAllAliases(
            const PhvInfo& p,
            const PragmaAlias& pragmaAlias,
            const ordered_map<cstring, const IR::Member*>& f)
        : phv(p), pragmaAlias(pragmaAlias), fieldExpressions(f) { }
};

/** This class implements a pass manager that handles aliasing relationships specified by pa_alias
  * fields. The general idea is that all the uses of one of the fields specified by the pragma
  * (alias source) are replaced by the uses of the other field in the pragma (alias destination). In
  * cases where one of the fields is a header and the other is metadata, the metadata is always the
  * alias source and the header field is always the alias destination. When both fields are
  * metadata, PragmaAlias pass chooses one of them as the alias source. Aliasing is not allowed when
  * both fields belong to packet headers.
  */
class Alias : public PassManager {
 private:
     ordered_map<cstring, const IR::Member*> fieldExpressions;
     PragmaAlias pragmaAlias;

 public:
    explicit Alias(PhvInfo& phv, const BFN_Options &options)
        : pragmaAlias(phv, options.disabled_pragmas) {
        addPasses({
            &pragmaAlias,
            new FindExpressionsForFields(phv, fieldExpressions),
            new ReplaceAllAliases(phv, pragmaAlias, fieldExpressions)
        });
    }
};

/// Replace AliasMember and AliasSlice nodes with their alias sources.
class ReinstateAliasSources : public Transform {
    PhvInfo&    phv;

    IR::Node* preorder(IR::BFN::AliasMember* alias) override {
        const PHV::Field* aliasSource = phv.field(alias->source);
        const PHV::Field* aliasDestination = phv.field(alias);
        BUG_CHECK(aliasSource, "Field %1% not found", alias->source);
        BUG_CHECK(aliasDestination, "Field %1% not found", alias);
        phv.addAliasMapEntry(aliasSource, aliasDestination);
        return alias->source->apply(ReinstateAliasSources(phv))->clone();
    }

    IR::Node* preorder(IR::BFN::AliasSlice* alias) override {
        const PHV::Field* aliasSource = phv.field(alias->source);
        const PHV::Field* aliasDestination = phv.field(alias);
        BUG_CHECK(aliasSource, "Field %1% not found", alias->source);
        BUG_CHECK(aliasDestination, "Field %1% not found", alias);
        phv.addAliasMapEntry(aliasSource, aliasDestination);
        return alias->source->apply(ReinstateAliasSources(phv))->clone();
    }

 public:
    explicit ReinstateAliasSources(PhvInfo& p) : phv(p) { }
};

#endif  /* EXTENSIONS_BF_P4C_COMMON_ALIAS_H_ */
