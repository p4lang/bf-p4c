#include "cluster_phv_bind.h"
#include "lib/log.h"
#include "lib/stringref.h"
#include "base/logging.h"

//***********************************************************************************
//
// PHV_Bind::PHV_Bind
//
//***********************************************************************************

PHV_Bind::PHV_Bind(PhvInfo &phv_f, PHV_MAU_Group_Assignments &phv_m)
    : phv_i(phv_f),
      phv_mau_group_assignments_i(phv_m),
      phv_mau_i(phv_m.phv_mau_map()),
      t_phv_i(phv_m.t_phv_map())  {
    //
    // collect all allocated containers in phv_mau_i, t_phv_i
    //
    for (auto it : phv_mau_i) {
        for (auto g : it.second) {
            for (auto c : g->phv_containers()) {
                if(c->fields_in_container().size()) {
                    containers_i.insert(c);
                }
            }
        }
    }
    for (auto coll : t_phv_i) {
        for (auto c_s : coll.second) {
            for (auto c : c_s.second) {
                if(c->fields_in_container().size()) {
                    containers_i.insert(c);
                }
            }
        }
    }
    //
    // accumulate fields to be bound
    // create equivalent asm containers
    //
    std::map<const PHV_Container*, PHV::Container *> phv_to_asm_map; 
    for (auto c : containers_i) {
        for (auto cc : const_cast<PHV_Container *>(c)->fields_in_container()) {
            fields_i.insert(cc->field());
        }
        phv_to_asm_map[c] = new PHV::Container(const_cast<PHV_Container *>(c)->asm_string().c_str()); 
    }
    //
    std::set<const PhvInfo::Field *> fields_overflow;  // all - PHV_Bind fields
    sanity_check_container_fields("PHV_Bind::PHV_Bind()..", fields_overflow);
    //
    // binding fields to containers
    // clear previous field alloc information if any
    //
    for (auto &f : fields_i) {
        PhvInfo::Field *f1 = const_cast<PhvInfo::Field *>(f);
        f1->alloc.clear();
    }
    for (auto c : containers_i) {
        for (auto cc : const_cast<PHV_Container *>(c)->fields_in_container()) {
            PhvInfo::Field *f1 = const_cast<PhvInfo::Field *>(cc->field());
            int field_bit = cc->field_bit_lo();
            int container_bit = cc->lo();
            int container_width = cc->width();
            PHV::Container *asm_container = phv_to_asm_map[c];
            f1->alloc.emplace_back(*asm_container, field_bit, container_bit, container_width);
        }
    }
    //
    LOG3(*this);
    //
}  // PHV_Bind


//***********************************************************************************
//
// sanity checks
//
//***********************************************************************************


void PHV_Bind::sanity_check_container_fields(
    const std::string& msg,
    std::set<const PhvInfo::Field *>& s3) {
    //
    const std::string msg_1 = msg+"PHV_Bind::sanity_check_container_fields";
    //
    // set difference phv_i fields, fields_i must be 0
    //
    std::set<const PhvInfo::Field *> s1;                                // all fields
    for (auto &field : phv_i) {
        s1.insert(&field);
    }
    // s3 = all - PHV_Bind fields
    set_difference(s1.begin(), s1.end(), fields_i.begin(), fields_i.end(), std::inserter(s3, s3.end()));
    if (s3.size()) {
        WARNING("*****cluster_phv_bind.cpp:sanity_FAIL*****+phv bind fields != all .."
            << msg << s3);
    }
    //
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
        << "++++++++++ PHV_Bind PHV Containers to Fields ++++++++++"
        << std::endl
        << std::endl;
    for (auto &f : phv_bind.fields()) {
        out << f;
        for (auto &as : f->alloc) {
            out << std::endl
                << '\t'
                << as;
        }
        out << std::endl;
    }
    out << std::endl;

    return out;
}
