#include <queue>

#include "bf-p4c/device.h"
#include "bf-p4c/parde/parde_visitor.h"
#include "bf-p4c/phv/phv_parde_mau_use.h"
#include "bf-p4c/phv/phv_fields.h"
#include "clot_info.h"

class CollectClotInfo : public Inspector {
    const PhvInfo& phv;
    ClotInfo& clot;

 public:
    explicit CollectClotInfo(const PhvInfo& phv, ClotInfo& clot) : phv(phv), clot(clot) {}

 private:
    Visitor::profile_t init_apply(const IR::Node* root) override {
        auto rv = Inspector::init_apply(root);
        clot.clear();
        return rv;
    }

    bool preorder(const IR::BFN::Extract* extract) override {
        auto* state = findContext<IR::BFN::ParserState>();
        if (auto f = phv.field(extract->dest->field))
            clot.all_fields[state].push_back(f);
        return false;
    }
};

class NaiveClotAlloc : public Visitor {
    static const int MAX_BYTES_PER_CLOT = 64;  // TODO(zma) move to parde_spec
    static const int TOTAL_CLOTS_AVAIL = 16;

    ClotInfo& clot;
    const PhvInfo &phv;
    const PhvUse &uses;

 public:
    explicit NaiveClotAlloc(ClotInfo& clot, const PhvInfo& phv, const PhvUse& uses) :
        clot(clot), phv(phv), uses(uses) {}

    struct ClotAlloc {
        ClotAlloc(const IR::BFN::ParserState* state, unsigned unused_bytes) :
            state(state), unused_bytes(unused_bytes) {}

        const IR::BFN::ParserState* state;
        unsigned unused_bytes = 0;
        bool operator<(const ClotAlloc& rhs) const {
            return unused_bytes < rhs.unused_bytes;
        }
    };

    bool is_clot_candidate(const PHV::Field* field) {
        return !uses.is_used_mau(field) && uses.is_used_parde(field);
    }

    std::priority_queue<ClotAlloc*> compute_requirement() {
       std::priority_queue<ClotAlloc*> q;

       for (auto& hdrs : clot.all_fields) {
           unsigned state_unused_bytes = 0;

           for (auto f : hdrs.second)
               if (is_clot_candidate(f))
                   state_unused_bytes += f->size;

           LOG3("state " << hdrs.first->name << " has " << state_unused_bytes << " fields");

           auto r = new ClotAlloc(hdrs.first, state_unused_bytes);
           q.push(r);
       }

       return q;
    }

    void allocate(ClotAlloc* ca) {
        // locate the fields that are not used in mau in headers,
        // greedily allocate clots to cover those

        std::vector<const PHV::Field*> all_fields;
        std::vector<int> no_use_mau_indices;

        int index = 0;
        auto& fields = clot.all_fields[ca->state];
        for (auto f : fields) {
            if (is_clot_candidate(f))
                no_use_mau_indices.push_back(index);
            all_fields.push_back(f);
            index++;
        }

        Clot* cl = nullptr;
        int curr_idx = 0;
        int prev_idx = -1;

        for (unsigned i = 0; i < no_use_mau_indices.size(); i++) {
            if (clot.clots.size() == TOTAL_CLOTS_AVAIL)
                break;

            curr_idx = no_use_mau_indices[i];
            auto curr_field = all_fields[curr_idx];

            if ((cl == nullptr) ||
                (curr_idx - prev_idx != 1) ||
                (cl && cl->length() + curr_field->size > MAX_BYTES_PER_CLOT)) {
                cl = new Clot();
                clot.add(cl, ca->state);
            }

            cl->all_fields.push_back(curr_field);

            // XXX(zma) above assumes no fields are > 64 bytes
            // we can obviously improve this by packing multiple
            // no_use_mau_fields in one clot, and with phv fields
            // in between. keep this naive for the time being.

            // TODO 3 byte gap constraint?

            prev_idx = curr_idx;
        }
    }

    const IR::Node *apply_visitor(const IR::Node *n, const char *) override {
        // sort all parser states in decreasing order of num of bytes
        // that do not participate in the mau pipe

        std::priority_queue<ClotAlloc*> q = compute_requirement();

        while (!q.empty() && clot.clots.size() <= TOTAL_CLOTS_AVAIL) {
            auto t = q.top();
            allocate(t);
            q.pop();
        }

        return n;
    }
};

AllocateClot::AllocateClot(ClotInfo &clot, const PhvInfo &phv, PhvUse &uses) {
    addPasses({
        &uses,
        new CollectClotInfo(phv, clot),
        new NaiveClotAlloc(clot, phv, uses),
        });
}

