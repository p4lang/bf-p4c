#ifndef _EXTENSIONS_BF_P4C_MAU_REMOVE_ACT_TABLES_H_
#define _EXTENSIONS_BF_P4C_MAU_REMOVE_ACT_TABLES_H_

#include "ir/ir.h"

using namespace P4;

/// Analyze tables to see whether they can be reduced to a set
/// of assignments which can be moved either in the parser or into
/// other actions similar to metadata initialization.
///
/// This is comes up in P4-16 when the programmer declares a set
/// of local variables in a control. The midend generates a table
/// with a single action that initializes these variables and thus
/// introduces a dependency that extends the number of stages.
class AnalyzeActionTables : public MAU::Inspector {
 public:
    AnalyzeActionTables() {}
    bool isCandidate(const IR::MAU::Table *t) const {
        return _candidates.
    }

 private:
    bool preorder(IR::P4Control* control) override;
    bool preorder(const IR::MAU::Table* t) override;
    bool preorder(IR::P4Action* action) override;

    std::set<cstring> _candidates;
};

/// Do the actual moves after the analysis has completed
class DoRemoveActionTables : public Transform {
    const AnalyzeActionTables *analysis;

 public:
    DoRemoveActionTables(const AnalyzeActionTables *a) : analysis(a) {}

 private:
    const IR::Node *postorder(const IR::MAU::Table* t) override;
};

class RemoveActionTables : public PassManager {
 public:
    RemoveActionTables() {
        auto analysis = new AnalyzeActionTables();
        addPasses({
            &analysis,
            new DoRemoveActionTables(analysis),
        });
    }
};


#endif  /* _EXTENSIONS_BF_P4C_MAU_REMOVE_ACT_TABLES_H_ */
