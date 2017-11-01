#include "bf-p4c/phv/cluster_phv_bind.h"
#include "bf-p4c/device.h"
#include "bf-p4c/phv/phv_fields.h"
#include "lib/log.h"
#include "lib/stringref.h"
#include "lib/error.h"

//***********************************************************************************
//
// PHV_Bind::apply_visitor()
//
//***********************************************************************************


const IR::Node *
PHV_Bind::apply_visitor(const IR::Node *node, const char *name) {
    //
    LOG1("..........PHV_Bind::apply_visitor()..........");
    if (name)
        LOG1(name);

    collect_containers_with_fields();

    if (fields_overflow_i.size()) {
        ::error("New fields:");
        for (auto f : fields_overflow_i)
            ::error("%1%", f->name);
        BUG("New, unallocated fields introduced after PHV allocation!"); }

    sanity_check_field_duplicate_containers("PHV_Bind::apply_visitor()..");

    bind_fields_to_containers();

    // phv_fields.h vector<alloc_slice> alloc;
    // sorted MSB (field) first
    // sort fields' alloc
    // later passes assume that phv alloc info is sorted in field bit order, msb first
    for (auto &f : phv_i) {
        std::sort(f.alloc_i.begin(), f.alloc_i.end(),
            [](PHV::Field::alloc_slice l, PHV::Field::alloc_slice r) {
                return l.field_bit > r.field_bit; }); }

    LOG3(*this);
    return node;
}

void PHV_Bind::collect_containers_with_fields() {
    //
    // collect all allocated containers from phv_mau_map, t_phv_map
    // accumulate containers_i, allocated_fields_i
    //
    containers_i.clear();
    allocated_fields_i.clear();
    ordered_set<PHV::Field *> allocated_fields;
    //
    for (auto &it : phv_mau_i.phv_mau_map()) {
        for (auto &g : it.second) {
            for (auto &c : g->phv_containers()) {
                if (c->fields_in_container().size()) {
                    containers_i.push_front(c);
                    for (auto &entry : c->fields_in_container()) {
                        allocated_fields.insert(entry.first);
                    }
                }
            }
        }
    }
    for (auto &coll : phv_mau_i.t_phv_map()) {
        for (auto &c_s : coll.second) {
            for (auto &c : c_s.second) {
                if (c->fields_in_container().size()) {
                    containers_i.push_front(c);
                    for (auto &entry : c->fields_in_container()) {
                        allocated_fields.insert(entry.first);
                    }
                }
            }
        }
    }
    sanity_check_field_slices(allocated_fields, "PHV_Bind::collect_containers_with_fields()...");
    //
    allocated_fields_i.assign(allocated_fields.begin(), allocated_fields.end());
    allocated_fields_i.sort(
        [](const PHV::Field *l, const PHV::Field *r) {
            // sort by cluster id_num to prevent non-determinism
            return l->id < r->id;
        });
}

void
PHV_Bind::bind_fields_to_containers() {
    //
    // binding fields to containers
    // clear previous field alloc information if any
    //
    phv_i.clear_container_to_fields();
    for (auto &f : allocated_fields_i) {
        f->alloc_i.clear();
        // ccgf members
        if (f->ccgf_fields().size()) {
            for (auto &m : f->ccgf_fields()) {
                m->alloc_i.clear();
            }
        }
    }
    for (const PHV_Container *c : containers_i) {
        for (auto& cc_s : Values(c->fields_in_container())) {
            for (auto* cc : cc_s) {
                PHV::Field *f = cc->field();
                if (!uses_i.is_referenced(f)) {
                    // referenced @ phv_analysis but ElimUnused / unreferenced now @ phv_bind
                    continue;
                }
                int field_bit = cc->field_bit_lo();
                int container_bit = cc->lo();
                // ensure overlay preserves field overlay width, does not extend to substratum width
                BUG_CHECK(f->size >= cc->width(), "Field size is less than CC width, check Overlay "
                    "field = %1%, size=%2%, width=%3%",
                    cstring::to_cstring(f), f->size, cc->width());
                int width_in_container = cc->width();
                PHV::Container asm_container = Device::phvSpec().idToContainer(c->container_id());
                //
                // ignore allocation for owners of
                // non-header stack ccgs
                // simple header ccgs
                //
                f->alloc_i.emplace_back(
                   f,
                   asm_container,
                   field_bit,
                   container_bit,
                   width_in_container);
                phv_i.add_container_to_field_entry(asm_container, f);
                //
                // contiguous container group allocation
                // in case bypassing MAU PHV allocation PHV_container::taint() recursion
                //
                // int container_width = c->width();
                // container_contiguous_alloc(f1,
                //                            container_width,
                //                            asm_container,
                //                            width_in_container);
            } } }
}


//***********************************************************************************
//
// sanity checks
//
//***********************************************************************************


void
PHV_Bind::sanity_check_field_duplicate_containers(
    const std::string& msg) {
    //
    const std::string msg_1 = msg+"PHV_Bind::sanity_check_field_duplicate_containers";
    //
    for (auto &f : allocated_fields_i) {
        ordered_set<int> hi_s;
        for (auto &as : f->alloc_i) {
            if (hi_s.count(as.field_bit)) {
                LOG1(std::endl
                    << "*****cluster_phv_bind.cpp:sanity_FAIL***** "
                    << msg_1
                    << std::endl
                    << ".....PHV_Bind Field Container duplication..... "
                    << std::endl
                    << f
                    << "\t"
                    << as);
            } else {
                hi_s.insert(as.field_bit);
            }
        }
    }
}

void
PHV_Bind::sanity_check_field_slices(
    ordered_set<PHV::Field *>& allocated_fields,
    const std::string& msg) {
    //
    const std::string msg_1 = msg + "PHV_Bind::sanity_check_field_slices";
    //
    // sliced fields, check all slices allocated
    // remove incompletely allocated fields from allocated_fields
    //
    ordered_set<PHV::Field *> incomplete_slices;
    for (auto &f : allocated_fields) {
        int allocated_width = 0;
        for (auto &c : f->phv_containers()) {
            for (auto &cc : c->fields_in_container()[f]) {
                allocated_width += cc->width();
            }
        }
        if (allocated_width < f->size) {
            LOG1(std::endl
                << "*****cluster_phv_bind.cpp:sanity_FAIL***** "
                << msg_1
                << std::endl
                << ".....PHV_Bind Field Slices allocation incomplete..... "
                << "allocation_width = "
                << allocated_width
                << ", field_size = "
                << f->size
                << std::endl
                << f
                << std::endl);
            incomplete_slices.insert(f);
        }
    }
    // remove incomplete ones from allocated fields so that they can be overflow allocated
    LOG3(".....cluster_phv_bind.cpp:sanity_INFO..... "
        << ".....PHV_Bind Incompletely Allocated Fields..... = "
        << incomplete_slices.size()
        << std::endl
        << incomplete_slices);
    allocated_fields -= incomplete_slices;
    //
    // sort allocated_fields on field id before printing
    // LOG3(".....cluster_phv_bind.cpp:sanity_INFO..... "
        // << ".....PHV_Bind Updated Completely Allocated Fields..... = "
        // << allocated_fields.size()
        // << std::endl
        // << allocated_fields);
}

//***********************************************************************************
//
// output stream <<
//
//***********************************************************************************
//
//

std::ostream &operator<<(std::ostream &out, PHV_Bind &phv_bind) {
    out << std::endl
        << "Begin ++++++++++++++++++++ PHV Bind Containers to Fields ++++++++++++++++++++"
        << std::endl
        << std::endl;
    for (auto &f : phv_bind.allocated_fields()) {
        out << f
            << std::endl;
    }
    if (phv_bind.fields_overflow().size()) {
        out << std::endl
            << "Begin .......... Overflow Fields ("
            << phv_bind.fields_overflow().size()
            << ") ........................"
            << std::endl
            << std::endl;
        for (auto &f : phv_bind.fields_overflow()) {
            out << f;
            for (auto &as : f->alloc_i) {
                out << std::endl
                    << '\t'
                    << as;
            }
            out << std::endl;
        }
        out << std::endl
            << "End .......... Overflow Fields ("
            << phv_bind.fields_overflow().size()
            << ") ........................"
            << std::endl
            << std::endl;
    }
    out << std::endl
        << "End ++++++++++++++++++++ PHV Bind Containers to Fields ++++++++++++++++++++"
        << std::endl
        << std::endl;
    return out;
}
