#include "table_replay_friendly_constraints.h"

namespace PHV {
namespace v2 {
const IR::Node *TableReplayFriendlyPhvConstraints::preorder(IR::Expression *expr) {
    const IR::MAU::Table *table = findContext<IR::MAU::Table>();
    if (!table) return expr;
    const IR::MAU::Action *action = findContext<IR::MAU::Action>();
    if (!action) return expr;
    LOG5("parent table is " + table->name);
    if (mau_backtracker.get_table_summary()->get_table_replay_failed_table() !=
        mau_backtracker.get_table_summary()->getTableIName(table)) {
        return expr;
    }
    auto *f = phv.field(expr);
    if (!f) {
        return expr;
    }
    if (add_pa_container_size.find(f->name) != add_pa_container_size.end()) {
        return expr;
    }
    if (trivial_allocation_info.find(f->name) == trivial_allocation_info.end()) {
        return expr;
    }
    // for now it works for fieldslice that only occupies only one container.
    if (trivial_allocation_info.find(f->name)->second.size() > 1) {
        return expr;
    }
    // TODO(changhao): 16-bit pa_container_size could be helpful. For now, the reason I skip 16-bit
    // is because it is also possible that 16-bit pa_container_size eliminates some allocation
    // flexibility, since 16-bit pa_container_size prevents a fieldslice from being allocated to
    // 8-bit containers. I will need to see more failed test cases to decide if 16-bit
    // pa_container_size is useful. For now, I just target 8-bit pa_container_size for minimal
    // impact.
    if (trivial_allocation_info.at(f->name).at(0).container_size == 32 ||
        trivial_allocation_info.at(f->name).at(0).container_size == 16) {
        return expr;
    }
    // add pa_container_size pragma for this field
    std::vector<PHV::Size> size_vec;
    auto alloc_info = trivial_allocation_info.at(f->name);
    for (int index = 0; index < f->size;) {
        BUG_CHECK(alloc_info.find(index) != alloc_info.end(), "index not found");
        size_vec.push_back(PHV::Size(alloc_info[index].container_size));
        if (alloc_info[index].length != (int)alloc_info[index].container_size) {
            break;
        } else {
            // have a BUG_CHECK to see alloc_info[index] exist, so cannot put this in the third part
            // of for loop.
            index += alloc_info[index].length;
        }
    }
    LOG5(f->name << " added to pa_container_size because of table: " + table->name);
    LOG5("pa_container_size " << size_vec.front());
    add_pa_container_size[f->name] = size_vec;
    return expr;
}

void CollectPHVAllocationResult::end_apply(const IR::Node *) {
    allocation_info.clear();
    for (auto &field : phv) {
        for (auto &alloc : field.get_alloc()) {
            LOG5(alloc.field() << " " << alloc.field_slice() << " is in " << alloc.container());
            AllocInfo info = {(int)alloc.field_slice().size(), alloc.container().size()};
            allocation_info[field.name][alloc.field_slice().lo] = info;
        }
    }

    ordered_set<cstring> to_remove;
    // perfectly_aligned means that except for the last AllocSlice, every AllocSlice of a fieldslice
    // can occupy a container entirely.
    for (auto it : allocation_info) {
        auto field_name = it.first;
        bool perfectly_aligned = true;
        auto field = phv.field(field_name);
        LOG5("Checking field: " << field);
        BUG_CHECK(field, "field not found");
        for (int index = 0; index < field->size; index += it.second[index].length) {
            // if allocated in clot, then we cannot find this field
            if (it.second.find(index) == it.second.end()) {
                perfectly_aligned = false;
                break;
            }
            auto &alloc_info = it.second[index];
            // if AllocSlice does not occupy a container entirely
            if (alloc_info.length != (int)alloc_info.container_size) {
                // it is perfectly aligned if it is the last AllocSlice.
                if (index + alloc_info.length == field->size) {
                    perfectly_aligned = true;
                } else {
                    perfectly_aligned = false;
                }
                break;
            }
        }
        if (!perfectly_aligned) to_remove.insert(field_name);
    }
    for (auto field_name : to_remove) {
        allocation_info.erase(field_name);
    }
}

}  // namespace v2
}  // namespace PHV
