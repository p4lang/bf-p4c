#ifndef EXTENSIONS_BF_P4C_PHV_TRANSFORMS_AUTO_ALIAS_H_
#define EXTENSIONS_BF_P4C_PHV_TRANSFORMS_AUTO_ALIAS_H_

#include "lib/bitvec.h"
#include "bf-p4c/phv/phv_fields.h"
#include "bf-p4c/phv/pragma/pa_alias.h"

class DetermineCandidateHeaders : public Inspector {
 private:
    const PhvInfo& phv;
    ordered_map<cstring, ordered_set<const IR::MAU::Action*>> headers;
    ordered_set<cstring> headersValidatedInParser;
    ordered_map<cstring, ordered_set<const IR::MAU::Action*>> headersValidatedInMAU;
    ordered_set<cstring> allHeaders;

    profile_t init_apply(const IR::Node* root) override;
    bool preorder(const IR::BFN::Extract* extract) override;
    bool preorder(const IR::MAU::Instruction* inst) override;
    void end_apply() override;

 public:
    explicit DetermineCandidateHeaders(const PhvInfo& p) : phv(p) { }

    const ordered_set<cstring> getCandidateHeaders() const {
        ordered_set<cstring> headerSet;
        for (auto& kv : headers) headerSet.insert(kv.first);
        return headerSet;
    }

    bool isCandidateHeader(cstring header) const { return headers.count(header); }

    const ordered_set<const IR::MAU::Action*>& getActionsForCandidateHeader(cstring header) const {
        static ordered_set<const IR::MAU::Action*> actions;
        if (!isCandidateHeader(header)) return actions;
        return headers.at(header);
    }
};

class DetermineCandidateFields : public Inspector {
 private:
    const PhvInfo& phv;
    const DetermineCandidateHeaders& headers;
    PragmaAlias& pragma;

    ordered_set<const PHV::Field*> initialCandidateSet;
    ordered_map<const PHV::Field*,
        ordered_map<const PHV::Field*, ordered_set<const IR::MAU::Action*>>> candidateSources;

    inline void dropFromCandidateSet(const PHV::Field* field);
    bool multipleSourcesFound(const PHV::Field* dest, const PHV::Field* src) const;

    profile_t init_apply(const IR::Node* root) override;
    bool preorder(const IR::MAU::Instruction* inst) override;
    void end_apply() override;

 public:
    explicit DetermineCandidateFields(
            const PhvInfo& p,
            const DetermineCandidateHeaders& h,
            PragmaAlias& pa)
        : phv(p), headers(h), pragma(pa) { }
};

class AutoAlias : public PassManager {
 private:
    DetermineCandidateHeaders   headers;
    DetermineCandidateFields    fields;

 public:
    explicit AutoAlias(const PhvInfo& phv, PragmaAlias& pa)
    : headers(phv), fields(phv, headers, pa) {
        addPasses({
            &headers,
            &fields
        });
    }
};

#endif  /* EXTENSIONS_BF_P4C_PHV_TRANSFORMS_AUTO_ALIAS_H_ */
