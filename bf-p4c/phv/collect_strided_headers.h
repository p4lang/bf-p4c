#ifndef BF_P4C_PHV_COLLECT_STRIDED_HEADERS_H_
#define BF_P4C_PHV_COLLECT_STRIDED_HEADERS_H_

/// Collects header stacks that require strided allocation (in a parser loop).
struct CollectStridedHeaders : public Inspector {
    PhvInfo& phv;

    std::map<cstring, std::vector<ordered_set<const PHV::Field*>>> stride_groups;

    explicit CollectStridedHeaders(PhvInfo& p) : phv(p) { }

    bool preorder(const IR::HeaderStack* hs) {
        auto state = findContext<IR::BFN::ParserState>();

        if (state && state->stride) {
            LOG4(state->name << " needs strided allocation (stride size = " << hs->size << ")");

            for (auto f : hs->type->fields) {
                ordered_set<const PHV::Field*> stride_group;

                for (int i = 0; i < hs->size; i++) {
                    cstring name = hs->name + "[" + cstring::to_cstring(i) + "]." + f->name;
                    auto field = phv.field(name);
                    stride_group.push_back(field);
                }

                stride_groups[hs->name].push_back(stride_group);
            }
        }

        return false;
    }

    const ordered_set<const PHV::Field*>*
    get_strided_group(const PHV::Field* f) const {
        for (auto& kv : stride_groups) {
            for (auto& group : kv.second) {
                if (group.count(f))
                    return &group;
            }
        }

        return nullptr;
    }
};

#endif  /* BF_P4C_PHV_COLLECT_STRIDED_HEADERS_H_ */
