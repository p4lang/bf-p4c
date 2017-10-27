#include "check_fitting.h"

const IR::Node* CheckFitting::apply_visitor(const IR::Node *n, const char *) {
    ordered_set<PHV::Field *> unallocated = collect_unallocated_fields(phv, uses);
    int unallocated_bits = 0;
    if (unallocated.size()) {
        std::stringstream msg;
        msg << "PHV allocation was not successful" << std::endl;
        msg <<  unallocated.size() << " unallocated fields:" << std::endl;
        for (auto f : unallocated) {
            msg << "    " << (LOGGING(3) ? cstring::to_cstring(f) : f->name) << std::endl;
            unallocated_bits += f->size;
        }
        if (LOGGING(3))
            msg << std::endl << "..........Unallocated bits = " << unallocated_bits << std::endl;
        if (ignorePHVOverflow) {
            ::warning("%1%", msg.str());
        } else {
            phv.print_phv_group_occupancy();
            ::error("%1%", msg.str()); }}

    return n;
}
