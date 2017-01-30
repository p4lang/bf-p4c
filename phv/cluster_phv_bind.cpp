#include "cluster_phv_bind.h"
#include "lib/log.h"
#include "lib/stringref.h"
#include "base/logging.h"

//***********************************************************************************
//
// PHV_Bind::apply_visitor()
//
//***********************************************************************************


const IR::Node *
PHV_Bind::apply_visitor(const IR::Node *node, const char *name) {
    //
    LOG1("..........PHV_Bind::apply_visitor()..........");
    if (name) {
        LOG1(name);
    }
    //
    // collect all allocated containers from phv_mau_map, t_phv_map
    //
    containers_i.clear();
    for (auto &it : phv_mau_i.phv_mau_map()) {
        for (auto &g : it.second) {
            for (auto &c : g->phv_containers()) {
                if (c->fields_in_container().size()) {
                    containers_i.push_front(c);
                }
            }
        }
    }
    for (auto &coll : phv_mau_i.t_phv_map()) {
        for (auto &c_s : coll.second) {
            for (auto &c : c_s.second) {
                if (c->fields_in_container().size()) {
                    containers_i.push_front(c);
                }
            }
        }
    }
    //
    // accumulate fields to be bound
    // create equivalent asm containers
    //
    ordered_map<const PHV_Container*, PHV::Container *> phv_to_asm_map;
    for (auto &c : containers_i) {
        for (auto &cc : const_cast<PHV_Container *>(c)->fields_in_container()) {
            fields_i.insert(cc->field());
        }
        phv_to_asm_map[c] =
            new PHV::Container(const_cast<PHV_Container *>(c)->asm_string().c_str());
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
        // ccgf members
        if (f1->ccgf_fields.size()) {
            for (auto &pov_f : f1->ccgf_fields) {
                pov_f->alloc.clear();
            }
        }
    }
    for (auto &c : containers_i) {
        for (auto &cc : const_cast<PHV_Container *>(c)->fields_in_container()) {
            PhvInfo::Field *f1 = const_cast<PhvInfo::Field *>(cc->field());
            int field_bit = cc->field_bit_lo();
            int container_bit = cc->lo();
            int width_in_container = cc->width();
            PHV::Container *asm_container = phv_to_asm_map[c];
            //
            // ignore allocation for owners of
            // non-header stack ccgs
            // simple header ccgs
            //
            f1->alloc.emplace_back(
               *asm_container,
               field_bit,
               container_bit,
               width_in_container);

            // contiguous container group allocation
            // in case bypassing MAU PHV allocation PHV_container::taint() recursion
            //
            // container_contiguous_alloc(f1, c, asm_container, width_in_container);
        }
    }
    //
    // phv_fields.h vector<alloc_slice> alloc;  // sorted MSB (field) first
    // for all fields sort
    //
    for (auto &f : fields_i) {
        PhvInfo::Field *f1 = const_cast<PhvInfo::Field *>(f);
        if (f1->alloc.size() > 1) {
            std::sort(f1->alloc.begin(), f1->alloc.end(),
                [](PhvInfo::Field::alloc_slice l, PhvInfo::Field::alloc_slice r) {
                    return l.field_bit > r.field_bit;
            });
        }
    }
    //
    // Trivially allocating overflow fields
    //
    // trivial_allocate(fields_overflow);
    //
    LOG3(*this);
    //
    return node;
}


void
PHV_Bind::container_contiguous_alloc(
    PhvInfo::Field* f1,
    const PHV_Container *c,
    PHV::Container *asm_container,
    int width_in_container) {
    //
    // container contiguous allocation
    // header fields allocation permits no holes in container
    // header stack povs allocation permits leading / trailing holes beside ccgf
    //
    if (f1->ccgf_fields.size()) {
        if (f1->ccgf == f1) {
            // contiguous container group allocation
            // cases bypassing MAU PHV allocation PHV_container::taint() recursion
            // consider MSB order
            int processed_members = 0;
            // container_bit start
            int start = static_cast<int>(
                        const_cast<PHV_Container *>(c)->width());
            for (auto &member : f1->ccgf_fields) {
                int member_bit_lo = member->phv_use_lo;
                int use_width = member->size - member->phv_use_rem;
                start -= use_width;
                if (start < 0) {
                    // member straddles containers
                    // remainder bits processed
                    // in subsequent container allocated to owner
                    use_width += start;
                    start = 0;
                    member_bit_lo = member->size - use_width - member->phv_use_rem;
                    member->phv_use_rem += use_width;  // [width 20]
                                                       // 12..19 [8b],
                                                       // 4..11 [8b],
                                                       // 0..3 [4b]
                } else {
                    processed_members++;
                    member->phv_use_rem = 0;
                }
                // -- reentrant PHV_Bind, preserve entry state of member
                // member->ccgf = 0;
                member->alloc.emplace_back(
                    *asm_container,
                    member_bit_lo,
                    start,
                    use_width);
                if (start <= 0) {
                    break;
                }
            }
            // -- reentrant PHV_Bind, preserve entry state of f1
            // f1->ccgf_fields.erase(
                // f1->ccgf_fields.begin(),
                // f1->ccgf_fields.begin() + processed_members);
            // if (f1->ccgf_fields.size()) {
                // f1->ccgf = f1;
            // }
        } else {
            //
            // header stack pov members
            // constituent members of header stack povs must fit header stk pov
            // this condition should be guaranteed by phv_fields.cpp allocatePOV()
            //
            int container_bit = width_in_container + 1;
            for (auto &pov_f : f1->ccgf_fields) {
                int field_bit = pov_f->phv_use_lo;
                int pov_width = pov_f->size;
                container_bit -= pov_width;
                if (f1->phv_use_rem < 0) {
                    // simple header ccgs
                    container_bit -= 2;
                    f1->phv_use_rem = 0;
                    f1->phv_use_hi = f1->size - 1;
                }
                //
                // check constituent members do fit hdr stk pov
                //
                if (container_bit < 0) {
                    WARNING("*****PHV_Bind: header stack overrun *****"
                        << " hdr stk pov: "
                        << f1
                        << " pov member: "
                        << pov_f
                        << " container_bit: "
                        << container_bit);
                }
                pov_f->alloc.emplace_back(
                    *asm_container,
                    field_bit,
                    container_bit,
                    pov_width);
            }
        }
    }
}  // container_contiguous_alloc


void
PHV_Bind::trivial_allocate(std::set<const PhvInfo::Field *>& fields) {
    //
    // trivially allocating overflow fields
    //
    LOG3("********** Overflow Allocation **********");
    std::map<PHV_Container::PHV_Word, int> overflow_reg {
        {PHV_Container::PHV_Word::b32, 64},
        {PHV_Container::PHV_Word::b16, 224},
        {PHV_Container::PHV_Word::b8,  128},
    };
    PHV_Container::PHV_Word container_width = PHV_Container::PHV_Word::b8;
    std::string container_prefix = "B";
    for (auto &f : fields) {
        if (!uses_i->use[0][f->gress][f->id]) {
            continue;
        }
        PhvInfo::Field *f1 = const_cast<PhvInfo::Field *>(f);
        int field_bit = 0;
        int container_bit = 0;
        if (f->size >= 16) {
            container_width = PHV_Container::PHV_Word::b32;
            container_prefix = "W";
        } else if (f->size >= 8) {
            container_width = PHV_Container::PHV_Word::b16;
            container_prefix = "H";
        }
        for (field_bit = 0; field_bit < f->size; field_bit++) {
            std::stringstream ss;
            ss << overflow_reg[container_width];
            overflow_reg[container_width]++;
            std::string reg_string = container_prefix + ss.str();
            const char *reg_name = reg_string.c_str();
            PHV::Container *asm_container = new PHV::Container(reg_name);
            f1->alloc.emplace_back(
                *asm_container, field_bit, container_bit, static_cast<int> (container_width));
            LOG3("....." << f << '[' << field_bit << "].." << reg_name);
            field_bit += static_cast<int> (container_width)-1;
        }
    }
}


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
    std::set<const PhvInfo::Field *> s1;                                // All Fields
    for (auto &field : phv_i) {
        //
        // discard fields that are not used
        //
        if (uses_i->use[1][field.gress][field.id]
           || uses_i->use[0][field.gress][field.id]) {
            //
            s1.insert(&field);
        }
    }
    // s3 = All - PHV_Bind fields
    set_difference(
        s1.begin(),
        s1.end(),
        fields_i.begin(),
        fields_i.end(),
        std::inserter(s3, s3.end()));
    //
    if (s3.size()) {
        LOG1(std::endl
            << "*****cluster_phv_bind.cpp:sanity_FAIL*****"
            << msg
            << ".....phv bind fields != all....."
            << std::endl
            << s3);
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
        << "++++++++++ PHV Bind Containers to Fields ++++++++++"
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
