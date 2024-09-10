#include "action_data_bus.h"
#include "backends/tofino/mau/resource.h"
#include "backends/tofino/mau/tofino/action_data_bus.h"
#if HAVE_FLATROCK
#include "backends/tofino/mau/flatrock/action_data_bus.h"
#endif

void ActionDataBus::clear() {
    allocated_attached.clear();
    reduction_or_mapping.clear();
}

/** The update procedure for all previously allocated tables in a stage.  This fills in the
 *  bitvecs correctly in order to be tested against in the allocation of the current table.
 */
void ActionDataBus::update(cstring name, const Use &alloc) {
    for (auto &rs : alloc.action_data_locs) {
         update(name, rs);
    }

    for (auto &rs : alloc.clobber_locs) {
        update(name, rs);
    }
}

void ActionDataBus::update_action_data(cstring name, const TableResourceAlloc *alloc,
                                       const IR::MAU::Table *tbl) {
    const IR::MAU::ActionData *ad = nullptr;
    for (auto back_at : tbl->attached) {
        auto at = back_at->attached;
        ad = at->to<IR::MAU::ActionData>();
        if (ad != nullptr)
            break;
    }
    if (ad) {
        if (allocated_attached.count(ad) > 0)
            return;
    }

    if (alloc->action_data_xbar) {
        update(name, *alloc->action_data_xbar);
        if (ad)
            allocated_attached.emplace(ad, *alloc->action_data_xbar);
    }
}

void ActionDataBus::update_meter(cstring name, const TableResourceAlloc *alloc,
                                 const IR::MAU::Table *tbl) {
    const IR::MAU::AttachedMemory *am = nullptr;
    const IR::MAU::StatefulAlu *salu = nullptr;
    for (auto back_at : tbl->attached) {
        auto at = back_at->attached;
        auto mtr = at->to<IR::MAU::Meter>();
        salu = at->to<IR::MAU::StatefulAlu>();
        if ((mtr && mtr->alu_output()) || salu) {
            am = at;
            break;
        }
    }

    if (am) {
        if (allocated_attached.count(am) > 0)
            return;
    } else {
        return;
    }

    if (salu && salu->reduction_or_group && reduction_or_mapping.count(salu->reduction_or_group))
        return;

    // Only update if the meter/stateful alu use is not previously accounted for
    if (alloc->meter_xbar) {
        update(name + "$" + am->name, *alloc->meter_xbar);
        if (salu && salu->reduction_or_group) {
            reduction_or_mapping.emplace(salu->reduction_or_group, *alloc->meter_xbar); }
        allocated_attached.emplace(am, *alloc->meter_xbar); }
}

void ActionDataBus::update(cstring name, const TableResourceAlloc *alloc,
                           const IR::MAU::Table *tbl) {
    update_action_data(name, alloc, tbl);
    update_meter(name, alloc, tbl);
}

void ActionDataBus::update(const IR::MAU::Table *tbl) {
    update(tbl->name, tbl->resources, tbl);
}

ActionDataBus *ActionDataBus::create() {
#if HAVE_FLATROCK
    // FIXME -- add Device::newIXBar() method?
    if (Device::currentDevice() == Device::FLATROCK)
        return new Flatrock::ActionDataBus();
#endif
    return new Tofino::ActionDataBus;
}

std::ostream &operator<<(std::ostream &out, const ActionDataBus::Use &u) {
    out << "["
        << "action_data_locs size: " << u.action_data_locs.size()
        << " clobber_locs size: " << u.clobber_locs.size()
        << "]";
    return out;
}

std::ostream &operator<<(std::ostream &out, const ActionDataBus &adb) {
    out << "["
        << "allocated_attached size: " << adb.allocated_attached.size()
        << " reduction_or_mapping: " << adb.reduction_or_mapping.size()
        << "]";
    return out;
}

int ActionDataBus::getAdbSize() {
    return Tofino::ActionDataBus::ADB_BYTES;
}
