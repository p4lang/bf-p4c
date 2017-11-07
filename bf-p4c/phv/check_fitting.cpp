#include "check_fitting.h"

const IR::Node* CheckFitting::apply_visitor(const IR::Node *n, const char *) {
    ordered_set<PHV::Field *> unallocated = collect_unallocated_fields(phv, uses, clot);
    int unallocated_bits = 0;
    int ingress_phv_bits = 0;
    int egress_phv_bits = 0;
    int ingress_t_phv_bits = 0;
    int egress_t_phv_bits = 0;
    if (unallocated.size()) {
        std::stringstream msg;
        msg << "PHV allocation was not successful" << std::endl;
        msg << "Unallocated fields (=" << unallocated.size() << "):" << std::endl;
        for (auto f : unallocated) {
            bool f_phv = uses.is_used_mau(f);
            cstring s = f_phv ? "phv" : "tphv";
            msg << "    " << (LOGGING(3) ? (cstring::to_cstring(f)+" --"+s) : f->name) << std::endl;
                                        // cstring::to_cstring invokes PHV::Field::operator<<
            unallocated_bits += f->size;
            if (f->gress == INGRESS) {
                if (f_phv)
                    ingress_phv_bits += f->size;
                else
                    ingress_t_phv_bits += f->size;
            } else {
                if (f_phv)
                    egress_phv_bits += f->size;
                else
                    egress_t_phv_bits += f->size; }}
        if (LOGGING(3)) {
            msg << std::endl
                << "..........Unallocated bits = " << unallocated_bits << std::endl;
            msg << "..........ingress phv bits = " << ingress_phv_bits << std::endl;
            msg << "..........egress phv bits = " << egress_phv_bits << std::endl;
            msg << "..........ingress t_phv bits = " << ingress_t_phv_bits << std::endl;
            msg << "..........egress t_phv bits = " << egress_t_phv_bits << std::endl; }
        if (ignorePHVOverflow) {
            ::warning("%1%", msg.str());
        } else {
            phv.print_phv_group_occupancy();
            ::error("%1%", msg.str()); }}

    return n;
}
