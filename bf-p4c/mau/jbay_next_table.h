#ifndef EXTENSIONS_BF_P4C_MAU_JBAY_NEXT_TABLE_H_
#define EXTENSIONS_BF_P4C_MAU_JBAY_NEXT_TABLE_H_

#include "mau_visitor.h"
#include "lib/dyn_vector.h"
#include "bf-p4c/mau/memories.h"
#include "bf-p4c/mau/table_layout.h"

/* This pass determines next table propagation in tofino2. It minimizes the use of long branches
 * whenever possible by "pushing down" next table propagation to tables in the table sequence and
 * using global_exec/local_exec instead. This pass must be run after modifications to IR graph are
 * done, otherwise its data will be invalidated.
 */
class NextTable : public PassManager {
 public:
    // Map from tables->condition (tseq names)->sets of tables that need to occur next
    using next_map_t = std::map<UniqueId, std::unordered_map<cstring, std::set<UniqueId>>>;
    next_map_t props;
    // Map from table to tag # to set of tables
    std::map<UniqueId, std::unordered_map<int, std::set<UniqueId>>> lbs;
    size_t get_num_lbs() { return max_tag; }  // For metrics
    NextTable();

 private:
    // Represents a long branch targeting a single destination (unique on destination)
    class LBUse {
        bool extended;  // Whether this use has been extended
     public:
        size_t fst, lst;  // First and last stages this tag is used on
        const IR::MAU::Table* dest;  // The destination related with this use
        explicit LBUse(const IR::MAU::Table* d)  // Dummy constructor for lookup by destination
                : extended(false), fst(0), lst(0), dest(d) {}
        LBUse(const IR::MAU::Table* d, size_t f, size_t l)  // Construct a LBUse for a dest
                : extended(false), fst(f), lst(l), dest(d) {}
        bool operator<(const LBUse& r) const { return dest < r.dest; }  // Always unique on dest!
        bool operator&(const LBUse& a) const;  // Returns true if tags do have unmergeable overlap
        void extend(const IR::MAU::Table*);  // Extends this LB to a new source table
        // Returns true if on the same gress, false o.w.
        inline bool same_gress(const LBUse& r) const { return dest->thread() == r.dest->thread(); }
        // Returns true if this LB is targetable for DT, false o.w.
        inline bool can_dt() const { return !extended; }
        inline gress_t thread() const { return dest->thread(); }
        friend std::ostream& operator<<(std::ostream& out, const LBUse& u) {
            out << "dest: " << u.dest->name << ", rng: " << u.fst << "->" << u.lst
                << ", extended? " << u.extended;
            return out;
        }
    };

    // Represents a single wire with multiple LBUses in it
    class Tag {
        std::vector<LBUse> uses;  // Live ranges of this tag
     public:
        // Attempts to add a tag. Returns true if successful, false otherwise
        bool add_use(const LBUse&);
        std::vector<LBUse>::iterator begin() { return uses.begin(); }
        std::vector<LBUse>::iterator end() { return uses.end(); }
        size_t size() const { return uses.size(); }
    };

    // Gets the unique id for a table, depending on whether the table is placed or not
    static inline UniqueId get_uid(const IR::MAU::Table* t) {
        return t->is_placed() ? t->unique_id() : t->pp_unique_id();
    }

    /*===================================Data gathered by Prop===================================*/
    std::map<int, Memories>                      mems;      // Map from stage to tables
    std::map<int, int>                           stage_id;  // Map from stage to next open LID
    std::set<LBUse>                              lbus;      // Long branches that are needed
    std::map<UniqueId, std::set<UniqueId>>       dest_src;  // Map from dest. to set of srcs
    std::map<UniqueId, const IR::MAU::TableSeq*> dest_ts;   // Map from dest. to containing seq
    std::set<UniqueId>                           al_runs;   // Set of tables that always run
    int                                          max_stage;

    // Computes a minimal scheme for how to propagate next tables and records long branches for
    // allocation. Also gathers information for dumb table allocation/addition.
    class Prop : public MauInspector {
        NextTable& self;

        // Holds information for propagating a single table sequence
        struct NTInfo;
        // Adds a table and corresponding table sequence to props map
        void add_table_seq(const IR::MAU::Table*, std::pair<cstring, const IR::MAU::TableSeq*>);
        void local_prop(const NTInfo& nti);  // Calculates and adds local (same stage) propagation
        void cross_prop(const NTInfo& nti);  // Calculates cross stage propagation
        bool preorder(const IR::MAU::Table*) override;
        bool preorder(const IR::BFN::Pipe*) override;  // Early abort

        profile_t init_apply(const IR::Node* root) override;
        void end_apply() override;

     public:
        explicit Prop(NextTable& ntp) : self(ntp) {}
    };

    /*==================================Data gathered by LBAlloc==================================*/
    bool                                         rebuild = true;  // Whether we need dumb tables
    dyn_vector<Tag>                              stage_tags;  // Track usage of tags x stages so far
    size_t                                       max_tag;  // Largest tag allocated (number of lbs)
    // Allocates long branches into tags
    class LBAlloc : public MauInspector {
        NextTable& self;
        profile_t init_apply(const IR::Node* root) override;  // Allocates long branches to tags
        bool preorder(const IR::BFN::Pipe*) override;  // Early abort
        int alloc_lb(const LBUse&);  // Finds a tag in self.stage_tags to fit the LBUse

     public:
        explicit LBAlloc(NextTable& ntp) : self(ntp) {}
    };

    // Attempts to reduce the number of tags in use to the max supported by the device
    class TagReduce : public MauTransform {
        NextTable& self;

        template <class T> class sym_matrix;  // Symmetric matrix for merging
        struct merge_t;  // Represents an "in-progress" merge of two tags
        sym_matrix<merge_t> find_merges() const;  // Finds all possible merges given current tags
        merge_t merge(Tag l, Tag r) const;  // Merges two tags, creating list of dummy tables
        bool merge_tags();  // Merge tags by adding DTs to fit. Returns false if failed
        std::map<int, std::vector<IR::MAU::Table*>> stage_dts;  // Map from stage # to DTs
        void alloc_dt_mems();  // Allocates memories for DTs in stage_dts

        // Map from table sequences to dumb tables to add to sequence
        std::map<const IR::MAU::TableSeq*, std::vector<IR::MAU::Table*>> dumb_tbls;

        profile_t init_apply(const IR::Node* root) override;
        // Early abort if push-down is sufficient. Adds DTs and allocates them memories
        IR::Node* preorder(IR::BFN::Pipe*) override;
        IR::Node* preorder(IR::MAU::Table*) override;  // Set always run tags
        IR::Node* preorder(IR::MAU::TableSeq*) override;  // Add specified tables to table sequences

        // FIXME: Pretty printing is all wrong right now
        // Capture information for pretty printing long branches (tag # -> src stage # -> src,dest)
        std::map<int, std::map<int, std::pair<const IR::MAU::Table*, const IR::MAU::Table*>>> lb_pp;
        // Log that captures pretty printing info
        std::stringstream log;
        // Print long branches prettily
        void pretty_print();

     public:
        explicit TagReduce(NextTable& ntp) : self(ntp) {}
    };
};

#endif /* EXTENSIONS_BF_P4C_MAU_JBAY_NEXT_TABLE_H_ */
