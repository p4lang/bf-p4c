#include <array>
#include <vector>

#include "bf-p4c/device.h"
#include "bf-p4c/parde/parde_visitor.h"
#include "bf-p4c/phv/phv_parde_mau_use.h"
#include "bf-p4c/phv/phv_fields.h"
#include "clot_info.h"

void ClotInfo::dbprint(std::ostream &out) const {
    for (auto c : clots_) {
        out << "clot " << c->tag << " : " << std::endl;
        out << "  all_fields: " << std::endl;
        for (auto f : c->all_fields)
            out << "    " << f->name << std::endl;
        out << "  phv_fields: " << std::endl;
        for (auto f : c->phv_fields)
            out << "    " << f->name << std::endl;
        out << std::endl;
    }
}

static unsigned num_bytes(unsigned bits) {
    return (bits + 7) / 8;
}

class CollectClotInfo : public Inspector {
    const PhvInfo& phv;
    ClotInfo& clotInfo;

 public:
    explicit CollectClotInfo(const PhvInfo& phv, ClotInfo& clotInfo) :
        phv(phv), clotInfo(clotInfo) {}

 private:
    Visitor::profile_t init_apply(const IR::Node* root) override {
        auto rv = Inspector::init_apply(root);
        clotInfo.clear();
        return rv;
    }

    bool preorder(const IR::BFN::Extract* extract) override {
        auto* state = findContext<IR::BFN::ParserState>();
        if (extract->source->is<IR::BFN::PacketRVal>()) {
            if (auto f = phv.field(extract->dest->field))
                clotInfo.all_fields_[state].push_back(f);
        }
        return false;
    }
};

class NaiveClotAlloc : public Visitor {
    static const int MAX_CLOTS_PER_STATE = 2;  // TODO(zma) move to pardeSpec
    static const int MAX_BYTES_PER_CLOT = 64;
    static const int TOTAL_CLOTS_AVAIL = 16;
    static const int INTER_CLOTS_BYTE_GAP = 3;

    ClotInfo& clotInfo;

 public:
    explicit NaiveClotAlloc(ClotInfo& clotInfo) : clotInfo(clotInfo) {}

    struct ClotAlloc {
        ClotAlloc(const IR::BFN::ParserState* state, unsigned unused, unsigned total) :
            state(state), unused_bytes(unused), total_bytes(total) {}

        const IR::BFN::ParserState* state;
        unsigned unused_bytes = 0;
        unsigned total_bytes = 0;
        bool operator<(const ClotAlloc& rhs) const {
            if (unused_bytes < rhs.unused_bytes) return true;
            if (unused_bytes > rhs.unused_bytes) return false;
            if (total_bytes < rhs.total_bytes) return true;
            if (total_bytes > rhs.total_bytes) return false;
            return state->id < rhs.state->id;
        }
    };

    std::array<std::vector<ClotAlloc>, 2> compute_requirement() {
       std::array<std::vector<ClotAlloc>, 2> req;

       for (auto& hdrs : clotInfo.all_fields_) {
           auto* state = hdrs.first;

           unsigned state_unused_bytes = 0;
           unsigned state_total_bytes = 0;

           for (auto f : hdrs.second) {
               if (clotInfo.is_clot_candidate(f))
                   state_unused_bytes += num_bytes(f->size);
               state_total_bytes += num_bytes(f->size);
           }

           LOG3("state " << state->name << " has " << state_unused_bytes << " unused bytes");

           ClotAlloc ca(state, state_unused_bytes, state_total_bytes);
           req[state->gress].push_back(ca);
       }

       // XXX(zma) replace this with optimizition based on parse graph anlysis
       // std::sort(req[0].begin(), req[0].end());
       // std::sort(req[1].begin(), req[1].end());

       std::reverse(req[0].begin(), req[0].end());
       std::reverse(req[1].begin(), req[1].end());

       return req;
    }

    bool allocate(const ClotAlloc& ca, unsigned gap_needed) {
        if (ca.unused_bytes == 0)
            return false;

        // TODO(zma) state larger than 64 bytes
        if (ca.total_bytes > MAX_BYTES_PER_CLOT)
            return false;

        // extract whole header in clot
        Clot* clot = nullptr;
        unsigned offset = 0;

        for (auto f : clotInfo.all_fields_[ca.state]) {
            if (gap_needed > offset + 1)
                continue;

            if (clot == nullptr) {
                clot = new Clot();
                clot->start = offset;
                clotInfo.add(clot, ca.state);
            }

            if (!clotInfo.is_clot_candidate(f))
                clot->phv_fields.push_back(f);

            clot->all_fields.push_back(f);

            offset += f->size;
        }

        return true;
    }

    void allocate(const std::vector<ClotAlloc>& req) {
        bool has_prev = false;

        for (unsigned i = 0; i < req.size(); ++i) {
            if (clotInfo.clots().size() == TOTAL_CLOTS_AVAIL)
                break;

            has_prev = allocate(req[i], has_prev ? INTER_CLOTS_BYTE_GAP * 8 : 0);
        }
    }

    const IR::Node *apply_visitor(const IR::Node *n, const char *) override {
        std::array<std::vector<ClotAlloc>, 2> req = compute_requirement();

        allocate(req[0]);  // ingress
        allocate(req[1]);  // egress

        LOG3("=== CLOT allocation ===");
        LOG3(clotInfo);

        return n;
    }
};

AllocateClot::AllocateClot(ClotInfo &clotInfo, const PhvInfo &phv, PhvUse &uses) {
    addPasses({
        &uses,
        new CollectClotInfo(phv, clotInfo),
        new NaiveClotAlloc(clotInfo),
    });
}

