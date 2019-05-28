#ifndef EXTENSIONS_BF_P4C_MAU_LONG_BRANCH_H_
#define EXTENSIONS_BF_P4C_MAU_LONG_BRANCH_H_

#include "mau_visitor.h"
#include "lib/dyn_vector.h"

/** Trivial greedy allocator for long branch tags.  Visits each Table, figures out if it
 * need one or more long branch tags, attempts to merge each with a previsouly allocated tag
 * (if it refers to the same tables), and then chooses the lowest unused tag the is still
 * free in the necessart stage(s) if not. */
class LongBranchAlloc : public MauModifier {
 public:
    struct Info {
        int                     tag = -1;
        int                     first_stage, last_stage;
        std::set<UniqueId>      tables;
        std::set<UniqueId>      optional;
        bitvec stage_use() const { return bitvec(first_stage, last_stage + 1 - first_stage); }
        Info(const IR::MAU::Table *tbl, const IR::MAU::TableSeq *nxt);
        bool can_merge(const Info &) const;
        void merge(const Info &);
    };
    friend std::ostream &operator<<(std::ostream &, const Info &);

 private:
    /* track usage of tags x stages so far.  In theory two uses could overlap by a single
     * stage (the last stage, where the tag is terminated, is the stage where another sets
     * it for a different use), but ONLY if the uses are in the samre thread.  For timing
     * reasons, we can't do this if one use is ingress and the other egress.  For now, we
     * don't even try */
    dyn_vector<bitvec>                  stage_use;
    /* track usage of stages x tags */
    dyn_vector<dyn_vector<Info *>>      use;

    void add_use(Info *);
    Info *find_merge(Info *);
    Info *alloc(Info *);

    bool preorder(IR::MAU::Table *) override;
    profile_t init_apply(const IR::Node *root) {
        stage_use.clear();
        use.clear();
        return MauModifier::init_apply(root); }
};

#endif /* EXTENSIONS_BF_P4C_MAU_LONG_BRANCH_H_ */
