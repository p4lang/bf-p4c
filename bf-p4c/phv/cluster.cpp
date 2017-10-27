#include "bf-p4c/phv/cluster.h"
#include "bf-p4c/phv/cluster_phv_container.h"
#include "bf-p4c/phv/phv_fields.h"
#include "lib/log.h"
#include "lib/stringref.h"

void Cluster::MakeCCGFs::computeCCGFValidRange(PHV::Field *owner) {
    // Return immediately if this owner is not a CCGF owner.
    if (!owner->ccgf_i || !owner->ccgf_fields_i.size())
        return;

    int total_width = 0;
    for (PHV::Field *f : owner->ccgf_fields_i)
        total_width += f->size;

    // Compute the valid range for the CCGF as a whole such that, when
    // satisfied, it implies that all valid range constraints for members will
    // also be satisfied.
    auto valid_interval = nw_bitinterval(ZeroToMax());
    int width_so_far = 0;
    for (PHV::Field *f : owner->ccgf_fields_i) {
        // Sanity check
        width_so_far += f->size;
        auto range_so_far = nw_bitrange(StartLen(0, width_so_far));
        BUG_CHECK(f->validContainerRange_i.contains(range_so_far),
                  "Field %1% is a CCGF member but has a valid container range "
                  "that does not include fields preceding it in its CCGF.",
                  cstring::to_cstring(f));

        // If valid field isn't already ZeroToMax(), expand it to include the
        // remaining members.
        if (f->validContainerRange_i == nw_bitrange(ZeroToMax()))
            continue;
        int remaining_width = total_width - width_so_far;
        nw_bitrange extended_range = f->validContainerRange_i.resizedToBits(
            f->validContainerRange_i.size() + remaining_width);
        valid_interval = valid_interval.intersectWith(toHalfOpenRange(extended_range)); }

    BUG_CHECK(!valid_interval.empty(),
              "Fields within CCGF owned by %1% have mutually unsatisfiable alignment constraints.",
              cstring::to_cstring(this));

    owner->validCCGFRange_i = *toClosedRange(valid_interval);
}

bool Cluster::MakeCCGFs::preorder(const IR::HeaderRef *hr) {
    LOG4(".....Header Ref.....");
    //
    // parser extract, deparser emit
    // operand can be field or header
    // when header, set_field_range all fields in header
    // attempting container contiguous groups -- see Note #5 below
    //
    ordered_map<PHV::Field *, int> ccgf;
    PHV::Field *group_accumulator = 0;
    int accumulator_bits = 0;
    for (auto fid : phv_i.struct_info(hr).field_ids()) {
        auto field = phv_i.field(fid);
        if (!uses_i.is_referenced(field)) {
            //
            // disregard unreferenced fields before ccgf accumulation
            //
            continue;
        }
        set_field_range(field);
        LOG4(field);

        // accumulate sub-byte fields to group to a byte boundary
        // fields must be contiguous
        // aggregating beyond byte boundary can cause problems
        // e.g.,
        //   {extra$0.x1: W0(0..23), extra$0.more: B1}
        //      => 5 bytes  -- deparser problem
        //   {extra$0.x1: W0(8..31), extra$0.more: W0(0..7)}
        //      => 4 bytes -- ok
        //   {extra$0.x1.16-23: B2,extra$0.x1.8-15: B1,extra$0.x1.0-7: B0,extra$0.more: B49}
        //      => 4B
        if (!field->ccgf()) {
            bool byte_multiple = field->size % int(PHV::Size::b8) == 0;
            if (group_accumulator || !byte_multiple) {
                if (!group_accumulator) {
                    group_accumulator = field;
                    accumulator_bits = 0;
                }
                // check if current field requires alignment in network order
                // that accumulator_bits will not satisfy
                const int align_start =
                    field->phv_alignment_network().get_value_or(accumulator_bits);
                if (accumulator_bits) {
                    if (accumulator_bits % int(PHV::Size::b8) != align_start % int(PHV::Size::b8)) {
                        ccgf[group_accumulator] = accumulator_bits;
                        LOG4("+++++PHV_container_contiguous_group.....parde_alignment cutoff....."
                            << "accumulated_bits = " << accumulator_bits
                            << ", align_start (nw)" << align_start);
                        LOG4(group_accumulator);
                        // TODO:
                        // if the member cannot guarantee physical contiguity as required by parser
                        // error message to bail out
                        // metadata, especially bridge metadata need not satisfy contiguity
                        // the parser can always extract more than once
                        if (!group_accumulator->metadata)
                            ::error("Header field %1% is the first of a series of non-byte "
                                    "aligned fields, and the subsequent field %2% has an "
                                    "incompatible alignment requirement.",
                                    cstring::to_cstring(group_accumulator),
                                    cstring::to_cstring(field));
                        group_accumulator = field;  // begin new ccgf accumulation
                        accumulator_bits = 0;
                    }
                }
                field->set_ccgf(group_accumulator);
                group_accumulator->ccgf_fields().push_back(field);
                if (accumulator_bits == 0) {
                    // first member of ccgf can have a parde-alignment constraint
                    accumulator_bits += align_start;
                }
                accumulator_bits += field->size;
                if (accumulator_bits % int(PHV::Size::b8) == 0) {  // accumulate to byte boundary
                    ccgf[group_accumulator] = accumulator_bits;
                    LOG4("+++++PHV_container_contiguous_group....."
                        << accumulator_bits);
                    LOG4(group_accumulator);
                    group_accumulator = 0; } } } }
    if (group_accumulator) {
       ccgf[group_accumulator] = accumulator_bits;
       LOG4("+++++PHV_container_contiguous_group....."
           << accumulator_bits);
       LOG4(group_accumulator); }
    // discard container contiguous groups with:
    // - only one member
    // - widths that are larger than one byte but not byte-multiples
    // - widths that are larger than the contiguity limit/run-length that phv
    //   allocation supports
    // - parser has 4x8b, 4x16b, and 4x32b extractors, all can be written to PHV per parse state
    // - extensive metadata aggregation causes ccgf cluster bloat & pressure on phv allocation
    for (auto &entry : ccgf) {
        auto owner = entry.first;
        auto ccgf_width = entry.second;
        assert(ccgf_width > 0);
        //
        bool single_member = owner->ccgf_fields().size() == 1;
        bool byte_multiple = ccgf_width % int(PHV::Size::b8) == 0;
        auto contiguity_limit = owner->metadata?
                                CCGF_contiguity_limit::Metadata * int(PHV::Size::b8):
                                CCGF_contiguity_limit::Parser_Extract * int(PHV::Size::b8);
        //
        bool discard = false;
        if (single_member) {
            LOG2("*****cluster.cpp: ccgf fields not grouped *****"
                << "-----discarding PHV_container_contiguous_group....."
                << "single member");
            discard = true;
        }
        if (!byte_multiple) {
            LOG2("*****cluster.cpp: ccgf fields not grouped *****"
                << "-----discarding PHV_container_contiguous_group....."
                << "not byte_multiple");
            discard = true;
        }
        if (ccgf_width > contiguity_limit) {
            LOG2("*****cluster.cpp: ccgf fields not grouped *****"
                << "-----discarding PHV_container_contiguous_group....."
                << "ccgf_width=" << ccgf_width
                << " > contiguity_limit=" << contiguity_limit);
            discard = true;
        }
        if (discard) {
            for (auto &f : owner->ccgf_fields()) {
                f->set_ccgf(0);
            }
            owner->ccgf_fields().clear();
            BUG_CHECK(!owner->is_ccgf(), "Owner CCGF not cleared");
            //
            LOG2(owner);
            WARNING("*****cluster.cpp: ccgf fields not grouped *****"
                << "-----discarded PHV_container_contiguous_group.....\n"
                << owner);
        } else {
            // For surviving CCGFs, lift any valid range constraints on members
            // to the CCGF as a whole.
            computeCCGFValidRange(owner);

            if (LOGGING(2)) {
                LOG2("CCGF owner: " << owner);
                for (auto child : owner->ccgf_fields())
                    LOG2("     child: " << child); } } }
    return true;
}

void Cluster::MakeCCGFs::end_apply() {
    set_deparsed_flag();
}

bool Cluster::MakeClusters::preorder(const IR::Expression* e) {
    LOG4(".....Field....." << e->toString());
    if (auto f = phv_i.field(e)) {
        create_dst_map_entry(f);
        return false; }
    return true;
}

// After InstructionSelection, only primitive operations should remain in
// actions. (Except SALU operands, which may be wrapped in unary operations,
// but we don't care about those here.)
void Cluster::MakeClusters::postorder(const IR::Primitive* primitive) {
    LOG4(".....Primitive:Operation....." << primitive->name);
    if (primitive->operands.size() == 0)
        return;
    if (PHV::Field* dst_i = phv_i.field(primitive->operands[0])) {
        LOG4("...dst... = " << dst_i);
        auto gress = dst_i->gress;
        for (auto &operand : primitive->operands) {
            if (auto field = phv_i.field(operand)) {
                insert_cluster(dst_i, field);
                set_field_range(phv_i, *operand);
                LOG4("...operand... = " << field);
                BUG_CHECK(gress == field->gress,
                    "***** cluster.cpp: Operation ..... mixed gress !*****\n%d:%s,%s\n%d:%s,%s",
                    dst_i->id, dst_i->name, (dst_i->gress ? " E" : " I"),
                    field->id, field->name, (field->gress ? " E" : " I")); } }
        sanity_check_clusters("postorder.." + primitive->name + "..", dst_i); }
}

void Cluster::MakeClusters::end_apply() {
    // Add fields used in MAU not part of primitive operations
    for (auto &f : phv_i)
        if (uses_i.is_used_mau(&f))
            create_dst_map_entry(&f);

    sanity_check_field_range("end_apply..");

    for (auto &entry : self.dst_map_i) {
        auto lhs = entry.first;
        sanity_check_clusters("end_apply..", lhs); }

    // ccgf owner field must be in self.dst_map_i
    for (auto &f : phv_i) {
        if (self.dst_map_i.count(&f))  {
            if (f.ccgf()
                && !f.ccgf()->header_stack_pov_ccgf()  // not header stack pov
                && !f.ccgf_fields().size()
                && !self.dst_map_i.count(f.ccgf())) {  // current owner not in dst_map
                //
                create_dst_map_entry(f.ccgf());
                insert_cluster(f.ccgf(), &f); } } }

    LOG4(".....After ccgf owner in self.dst_map_i.....");
    LOG4(self.dst_map_i);

    for (auto &f : phv_i) {
        if (self.dst_map_i.count(&f))  {
            //
            // container contiguous group fields
            // cluster(a{a,b},x), cluster(b,y) => cluster(a{a,b},x,y)
            // a->ccgf_fields = {a,b,c}, a->ccgf=a, b->ccgf=a, c->ccgf=a
            // self.dst_map_i[a]=(a), self.dst_map_i[b]=(b)
            // (a) += (b); remove self.dst_map_i[b]
            // b appearing in self.dst_map_i[y] :-
            //     cluster(a{a,b},x), cluster(y,b) => cluster(a{a,b},x,y)
            //
            if (f.is_ccgf()) {
                for (auto &m : f.ccgf_fields())
                    if (self.dst_map_i.count(m))
                        insert_cluster(&f, m);

                // remove ccgf members duplicated as cluster members
                // ccgf owners responsible for member allocation
                // remove duplication as cluster members
                ordered_set<PHV::Field *> s1 = *(self.dst_map_i[&f]);
                for (auto &c_e : s1)
                    for (auto &m : c_e->ccgf_fields())
                        if (m != c_e && s1.count(m))
                            self.dst_map_i[&f]->erase(m); } } }
    LOG4(".....After remove ccgf member duplication.....");
    LOG4(self.dst_map_i);

    // form unique clusters
    // forall x not elem self.lhs_unique_i, self.dst_map_i[x] = 0
    // do not remove singleton clusters as x needs MAU PHV, e.g., set x, 3
    std::list<PHV::Field *> delete_list;
    for (auto &entry : self.dst_map_i) {
        auto lhs = entry.first;
        //
        // remove dst_map entry for fields absorbed in other clusters
        // remove singleton clusters (from headers) not used in mau
        //
        if (self.lhs_unique_i.count(lhs) == 0) {
            self.dst_map_i[lhs] = nullptr;
            delete_list.push_back(lhs);
        } else {
            // set_metadata lhs, ....
            // lhs should not be removed from self.dst_map_i as mau operation needed
            // parde (e.g., "extract", "emit") operands not used_mau should be removed from dst_map
            //
            bool need_mau = uses_i.is_used_mau(lhs);
            if (!need_mau && entry.second) {
                for (auto &f : *(entry.second)) {
                    if (uses_i.is_used_mau(f)) {
                        need_mau = true;
                        break;
                    } else {
                        if (f->is_ccgf()) {
                            for (auto &m : f->ccgf_fields()) {
                                if (uses_i.is_used_mau(m)) {
                                    need_mau = true;
                                    break; } } }
                        if (need_mau)
                            break; } } }

            if (!need_mau) {
                self.dst_map_i[lhs] = nullptr;
                delete_list.push_back(lhs); } } }

    for (auto &fp : delete_list)
        self.dst_map_i.erase(fp);

    LOG4(".....After form unique clusters.....");
    LOG4(".....self.lhs_unique_i.....");
    LOG4(&self.lhs_unique_i);
    LOG4(".....self.dst_map_i.....");
    LOG4(self.dst_map_i);

    deparser_ccgf_phv();
    // compute all fields that are not used through the MAU pipeline
    // potential candidates for T-PHV allocation
    compute_fields_no_use_mau();
    deparser_ccgf_t_phv();
    sort_fields_remove_non_determinism();

    sanity_check_clusters_unique("end_apply..");

    LOG1("--- ALL FIELD CLUSTERS --------------------------------------------------------");
    for (PHV::Field* unique_f : self.lhs_unique_i) {
        // XXX(cole): This seems like it should be true, but it's not.
        // BUG_CHECK(self.dst_map_i.count(unique_f),
        //     "Cluster UnionFind key field not in map: %1%", unique_f->name);
        if (!self.dst_map_i.count(unique_f)) {
            LOG2("UnionFind unique (key) field '" << unique_f->name << "' not in dst_map");
            continue; }
        for (auto f : *self.dst_map_i.at(unique_f))
            LOG1(f);
        LOG1("--------"); }
    LOG1("");

    LOG1("--- TPHV CANDIDATES -----------------------------------------------------------");
    for (auto f : self.fields_no_use_mau_i)
        LOG1(f);
    LOG1("-------------------------------------------------------------------------------");
    LOG1("");

    LOG1("--- POV FIELDS ----------------------------------------------------------------");
    for (auto f : self.pov_fields_i)
        LOG1(f);
    LOG1("-------------------------------------------------------------------------------");
    LOG1("");

    LOG1("--- POV FIELDS (not in cluster) -----------------------------------------------");
    for (auto f : self.pov_fields_not_in_cluster_i)
        LOG1(f);
    LOG1("-------------------------------------------------------------------------------");
    LOG1("");

    LOG3(phv_i);  // all Fields
    LOG3(self);   // all Clusters
}

//
// set deparsed flag on fields
//
void Cluster::MakeCCGFs::set_deparsed_flag() {
    for (auto &f : self.phv_i)
        // set field's deparsed if used in deparser
        if (uses_i.is_deparsed(&f) && !(f.metadata && !f.bridged) && !f.pov)
            f.set_deparsed(true);
    //
    // CCGF fields are either:
    // all fields from the same header, in which case they're all deparsed or not as a group,
    // or all metadata fields, in which case some may be deparsed (bridged) and some not.
    // hence we do not to set the deparsed bit on an entire CCGF if any field is deparsed
}

//
// deparser ccgf accumulation
//
void Cluster::MakeClusters::deparser_ccgf_phv() {
    //
    // scan through self.dst_map_i => phv related fields as t_phv fields will not be in clusters
    //
    ordered_map<gress_t, std::list<PHV::Field *>> ccgf;
    ordered_map<gress_t, int> ccgf_width;
    for (auto &entry : self.dst_map_i) {
        PHV::Field *f = entry.first;
        ordered_set<PHV::Field *> *s = entry.second;
        if (s->size() == 1
            && !f->metadata && !f->pov && !f->is_ccgf() && f->size < int(PHV::Size::b8)) {
            //
            ccgf[f->gress].push_back(f);
            ccgf_width[f->gress] += f->size; } }

    auto contiguity_limit = CCGF_contiguity_limit::Parser_Extract * int(PHV::Size::b8);
    for (auto &entry : ccgf) {
        std::list<PHV::Field *> member_list = entry.second;
        PHV::Field *owner = member_list.front();
        if (ccgf_width[entry.first] > contiguity_limit) {
            LOG2("*****cluster.cpp: ccgf fields not grouped *****"
                << "-----deparser_ccgf_phv....."
                << "ccgf_width=" << ccgf_width[entry.first]
                << " > contiguity_limit=" << contiguity_limit);
            LOG2(owner);
            continue; }

        if (member_list.size() > 1) {
            for (auto &f : member_list) {
                f->set_ccgf(owner);
                owner->ccgf_fields().push_back(f);
                self.dst_map_i.erase(f); }

            self.dst_map_i[owner] = new ordered_set<PHV::Field *>;  // new set
            self.dst_map_i[owner]->insert(owner);

            LOG3("..........deparser_ccgf_phv.........."); } }
}

void Cluster::MakeClusters::deparser_ccgf_t_phv() {
    //
    // scan through self.fields_no_use_mau_i => t_phv fields
    //
    ordered_map<gress_t, std::list<PHV::Field *>> ccgf;
    ordered_map<gress_t, int> ccgf_width;
    for (auto &f : self.fields_no_use_mau_i) {
        if (!f->metadata && !f->pov && !f->is_ccgf() && f->size < int(PHV::Size::b8)) {
            //
            ccgf[f->gress].push_back(f);
            ccgf_width[f->gress] += f->size; } }

    auto contiguity_limit = CCGF_contiguity_limit::Parser_Extract * int(PHV::Size::b8);
    for (auto &entry : ccgf) {
        std::list<PHV::Field *> member_list = entry.second;
        PHV::Field *owner = member_list.front();
        if (ccgf_width[entry.first] > contiguity_limit) {
            LOG2("*****cluster.cpp: ccgf fields not grouped *****"
                << "-----deparser_ccgf_t_phv....."
                << "ccgf_width=" << ccgf_width[entry.first]
                << " > contiguity_limit=" << contiguity_limit);
            LOG2(owner);
            continue; }

        if (member_list.size() > 1) {
            for (auto &f : member_list) {
                f->set_ccgf(owner);
                owner->ccgf_fields().push_back(f);
                self.fields_no_use_mau_i.remove(f); }

            self.fields_no_use_mau_i.push_back(owner);

            LOG3("..........deparser_ccgf_t_phv..........");
            LOG3(owner); } }
}

//
// compute fields that do not use mau pipeine, no MAU reads or writes
// these fields do not participate as operands in MAU instructions
// they can be placed in T_PHV, by-passing MAU
//
void Cluster::MakeClusters::compute_fields_no_use_mau() {
    //
    // clear all computed & exported lists
    //
    self.pov_fields_i.clear();
    self.pov_fields_not_in_cluster_i.clear();
    self.fields_no_use_mau_i.clear();

    ordered_set<PHV::Field *> all_fields;                          // all fields in phv_i
    ordered_set<PHV::Field *> cluster_fields;                      // cluster fields
    ordered_set<PHV::Field *> all_minus_cluster;                   // all - cluster fields
    ordered_set<PHV::Field *> pov_fields;                          // pov fields
    ordered_set<PHV::Field *> not_used_mau;                        // fields not used in MAU
                                                                   // all - cluster - pov_fields

    // preprocess fields before accumulation
    for (auto &field : phv_i) {
        if (field.simple_header_pov_ccgf() && !uses_i.is_referenced(&field)) {
            //
            // if singleton member, grouping of pov bits not required
            // else appoint new owner of group
            //
            std::vector<PHV::Field *> members;

            for (auto &m : field.ccgf_fields()) {
                if (uses_i.is_referenced(m))
                    members.push_back(m);
                m->set_ccgf(0); }

            if (members.size() > 1) {
                PHV::Field *owner = members.front();
                owner->set_simple_header_pov_ccgf(true);
                for (auto &m : members) {
                    m->set_ccgf(owner);
                    owner->ccgf_fields().push_back(m); } }

            field.set_simple_header_pov_ccgf(false);
            field.set_ccgf(0);
            field.ccgf_fields().clear(); } }

    // accumulation
    for (auto &field : phv_i) {
        // disregard unreferenced fields before all_fields accumulation
        if (!uses_i.is_referenced(&field))
            continue;

        all_fields.insert(&field);

        // avoid duplicate allocation for povs that are
        // members of owners that represent header_stack_pov_ccgf
        // members of owners that represent simple_header_pov_ccgf
        // these members are part of owner container
        // owners if not part of MAU cluster, should be added to pov_fields
        bool is_stack_or_simple_ccgf =
            field.ccgf() &&
            (field.ccgf()->header_stack_pov_ccgf() || field.ccgf()->simple_header_pov_ccgf());
        if (field.pov && !is_stack_or_simple_ccgf)
            pov_fields.insert(&field);

        // pov owners not part of MAU cluster, must be added to pov_fields
        if (field.pov && (&field == field.ccgf() && !self.dst_map_i.count(field.ccgf())))
            pov_fields.insert(&field);

        // compute width required for ccgf owner (responsible for its members)
        // need PHV container(s) space for ccgf_width
        if (field.is_ccgf())
            field.set_ccgf_phv_use_width();
    }

    self.pov_fields_i.assign(pov_fields.begin(), pov_fields.end());         // self.pov_fields_i
    LOG3(std::endl << "..........All fields (" << all_fields.size() << ")..........");

    // build cluster fields
    for (auto &entry : self.dst_map_i)
        if (entry.second) {
            cluster_fields.insert(entry.first);
            for (auto entry_2 : *(entry.second)) {
                cluster_fields.insert(entry_2);
                if (entry_2->ccgf_fields().size())
                    for (auto &member : entry_2->ccgf_fields())
                        cluster_fields.insert(member); } }

    LOG3("..........Cluster fields (" << cluster_fields.size() << ")..........");
    LOG3("..........POV fields (" << self.pov_fields_i.size() << ")..........");

    // all_minus_cluster = all_fields - cluster_fields
    all_minus_cluster = all_fields;
    all_minus_cluster -= cluster_fields;

    // not_used_mau = all_minus_cluster - pov_fields
    not_used_mau = all_minus_cluster;
    not_used_mau -= pov_fields;

    // pov_mau = pov intersect cluster fields
    ordered_set<PHV::Field *> pov_mau = pov_fields;
    pov_mau &= cluster_fields;

    LOG3("..........POV fields in Cluster (" << pov_mau.size() << ")..........");

    // pov fields not in cluster
    // pov_no_mau = set_diff pov, pov_mau
    ordered_set<PHV::Field *> pov_no_mau = pov_fields;
    pov_no_mau -= pov_mau;
    self.pov_fields_not_in_cluster_i.assign(pov_no_mau.begin(), pov_no_mau.end());

    LOG3("..........POV fields not in Cluster (" << pov_no_mau.size() << ")..........");
    LOG3("..........Fields avoiding MAU pipe (" << not_used_mau.size() << ")..........");

    sanity_check_fields_use(
        "compute_fields_no_use_mau..",
        all_fields,
        cluster_fields,
        all_minus_cluster,
        pov_fields,
        not_used_mau);

    /* From T_PHV candidates (fields not used in MAU):
     *  - remove non-bridged metadata
     *  - remove CCGF children---they will be allocated with their owner
     *
     * For remaining fields, set_field_range (entire field deparsed).
     */
    ordered_set<PHV::Field *> delete_set;
    for (auto f : not_used_mau) {
        // Metadata in T_PHV can be removed but bridged metadata must
        // be allocated.  CCGF children are also removed.
        // If a field is a candidate for TPHV but not deparsed then it is removed.
        // TODO:
        // If a field is a candidate for TPHV but only used in egress deparser
        // then it does not need T_PHV container. It is removed.
        bool is_ccgf_child = f->ccgf() && f->ccgf() != f;
        bool is_nonbridged_metadata = f->metadata && !f->bridged;
        bool is_not_deparsed = !f->deparsed();
        if (is_ccgf_child || is_nonbridged_metadata || is_not_deparsed) {
            delete_set.insert(f);
        } else {
            BUG_CHECK(!f->pov, "POV field not clustered");
            set_field_range(f); } }

    // s_diff = not_used_mau - delete_set
    ordered_set<PHV::Field *> s_diff = not_used_mau;
    s_diff -= delete_set;
    self.fields_no_use_mau_i.assign(s_diff.begin(), s_diff.end());  // self.fields_no_use_mau_i

    LOG3("..........T_PHV Fields ("
        << self.fields_no_use_mau_i.size()
        << ").........."
        << std::endl);
    for (auto f : self.fields_no_use_mau_i)
        LOG4(f);
}

void Cluster::MakeClusters::sort_fields_remove_non_determinism() {
    //
    // sort fields by id so that future passes using these lists
    // produce determined output on each run
    // useful for debugging purposes
    // occasionally see intermittent failures that are tough to track down
    // cause of non-determinism:
    // doing things that depend on where garbage collector puts stuff in memory (somewhat random)
    // generally by comparing pointers for order
    // happens whenever iterate over `set` or `map` that uses a pointer type as the key
    // best way to avoid is to use `ordered_set`/`ordered_map` types,
    // which track order of insertion & use that as iteration order.
    // sometimes, can't avoid, need additional support functions in ordered_set
    // e.g.,
    // set_intersection (&=), set_difference (-=),
    // insert ordered_set in (ordered_set of ordered_sets)
    //
    // sort exported list fields by id
    //
    self.pov_fields_i.sort(
        [](PHV::Field *l, PHV::Field *r) {
            // sort by cluster id_num to prevent non-determinism
            return l->id < r->id;
        });
    self.pov_fields_not_in_cluster_i.sort(
        [](PHV::Field *l, PHV::Field *r) {
            // sort by cluster id_num to prevent non-determinism
            return l->id < r->id;
        });
    self.fields_no_use_mau_i.sort(
        [](PHV::Field *l, PHV::Field *r) {
            // sort by cluster id_num to prevent non-determinism
            return l->id < r->id;
        });
}

//***********************************************************************************
//
// create dst map entry
// create a self.dst_map_i entry for field
// insert in self.lhs_unique_i
// insert_cluster
//
//***********************************************************************************
void Cluster::MakeClusters::create_dst_map_entry(PHV::Field *field) {
    assert(field);
    if (!self.dst_map_i[field]) {
        self.dst_map_i[field] = new ordered_set<PHV::Field *>;  // new set
        self.lhs_unique_i.insert(field);  // lhs_unique set insert field
        LOG5("lhs_unique..insert[" << std::endl << &self.lhs_unique_i << "lhs_unique..insert]");
        insert_cluster(field, field);
        set_field_range(field);
        LOG4("CREATE " << field << " for cluster");
    }
}

//***********************************************************************************
//
// set field range
// updates range of field slice used in computations / travel through MAU pipeline / phv
//
//***********************************************************************************

/* static */
void Cluster::set_field_range(PhvInfo &phv, const IR::Expression& expression) {
    bitrange bits;
    bits.lo = bits.hi = 0;
    if (auto field = phv.field(&expression, &bits)) {
        // set range based on expression bit-slice use
        field->set_phv_use_lo(std::min(field->phv_use_lo(), bits.lo));
        if (field->metadata || field->pov)
            field->set_phv_use_hi(std::max(field->phv_use_hi(), bits.hi));
        else
            set_field_range(field);
    }
}

/* static */
void Cluster::set_field_range(PHV::Field *field, int container_width) {
    if (field) {
        field->set_phv_use_lo(0);
        BUG_CHECK(field->size,
            "***** cluster.cpp: set_field_range ..... field size is 0 *****%d:%s",
            field->id, field->name);
        // set hi considering no-pack constraints
        field->set_phv_use_hi(field->phv_use_lo() + std::max(field->size, container_width) - 1);
    }
}

//***********************************************************************************
//
// insert field in cluster
//
// map[a]--> cluster(a,x) + insert b
// if b == a
//     [a]-->(a,x)
// if [b]--> ==  [a]-->
//     do nothing
// if [b]-->nullptr, b not member of ccgf[f], f element of [a]
//                            avoid duplicate b, f.b in cluster as f phv-allocates for its ccgf
//     (a,x) = (a,x) U b
//     [a],[b]-->(a,x,b)
// if [b]-->(b,d,x)
//     [a]-->(a,u,v)U(b,d,x), b,d,x not member of ccgf[f], f element of [a]
//                            avoid duplicates in cluster as f phv-allocates for its ccgf
//     [b(=rhs)] set members --> [a(=lhs)], rhs cluster subsumed by lhs'
//     [b],[d],[x],[a],[u],[v]-->(a,u,v,b,d,x)
//     lhs_unique set: -remove(b,d,x)
//     note: [b]-->(b,d,x) & op c d => [c]-->(c,b,d,x), lhs_unique set: +insert(c)-remove(b,d,x)
//     del (b,d,x) as no map[] key points to (b,d,x)
//
//***********************************************************************************

// barring CCGF, clustering = Union-Find
// Find: determine which subset contains a particular element
// Union: Join two subsets into a single subset
// if rhs is ccgf member, check if rhs ccgf owner in lhs cluster

void Cluster::MakeClusters::insert_cluster(PHV::Field *lhs, PHV::Field *rhs) {
    if (lhs && self.dst_map_i[lhs] && rhs) {
        if (rhs == lhs) {   // b == a
            self.dst_map_i[lhs]->insert(rhs);
        } else {
            if (self.dst_map_i[rhs] != self.dst_map_i[lhs]) {   // [b]-->nullptr
                //
                // ccgf owners will phv allocate for members
                // recursively (PHV_Container::taint())
                // avoid duplication
                // e.g.,  owner's cluster as (lhs{lhs->ccgf_fields=(field,...)}, field)
                //
                if (!self.dst_map_i[rhs]) {
                    // XXX(cole): If CCGF owner is in a different cluster, don't we
                    // need to union that cluster with this one?

                    if (!rhs->ccgf() || !is_ccgf_owner_in_cluster(lhs, rhs)) {
                        self.dst_map_i[lhs]->insert(rhs);
                        self.dst_map_i[rhs] = self.dst_map_i[lhs];
                    }
                } else {
                    // [b]-->(b,d,x)
                    // [a]-->(a,u,v)U(b,d,x)
                    for (auto field : *(self.dst_map_i[rhs]))
                        if (!field->ccgf() || !is_ccgf_owner_in_cluster(lhs, field))
                            self.dst_map_i[lhs]->insert(field);

                    // [b],[d],[x],[a],[u],[v]-->(a,u,v,b,d,x)
                    // lhs_unique set: -remove(b,d,x)
                    for (auto field : *(self.dst_map_i[rhs])) {
                        self.dst_map_i[field] = self.dst_map_i[lhs];
                        self.lhs_unique_i.erase(field); } } }

            LOG4("..... insert_cluster ....." << lhs);
            LOG4(self.dst_map_i[lhs]);
            LOG5("lhs_unique..erase[" << std::endl << &self.lhs_unique_i << "lhs_unique..erase]");
        }
    }
}


/// @return true if the CCGF owner of @rhs is in the same cluster as @lhs.
bool Cluster::MakeClusters::is_ccgf_owner_in_cluster(PHV::Field *lhs, PHV::Field *rhs) {
    //
    // return true if rhs' ccgf owner in cluster
    // i.e., rhs is not a member of f.ccgf_fields, f element of lhs cluster
    // check rhs.ccgf in self.dst_map_i[lhs]
    //
    return lhs && rhs && rhs->ccgf() &&
           self.dst_map_i[lhs] && self.dst_map_i[lhs]->count(rhs->ccgf());
}

//***********************************************************************************
//
// sanity checks
//
//***********************************************************************************

void Cluster::MakeClusters::sanity_check_field_range(const std::string& msg) {
    // for all fields in phv_i, check size >= range
    for (auto field : phv_i) {
        if (field.phv_use_width() > field.size) {
            if (field.is_ccgf()) {
                if (field.ccgf_width() != field.phv_use_width()) {
                    LOG1("*****cluster.cpp:sanity_WARN*****"
                        << msg << ".....ccgf field phv_use_width(" << field.phv_use_width()
                        << ") != ccgf_width(" << field.ccgf_width() << ")");
                    LOG1(&field);
                }
            } else {
                LOG1("*****cluster.cpp:sanity_FAIL*****"
                    << msg << ".....field phv_use_width(" << field.phv_use_width()
                    << ") > size(" << field.size << ")");
                LOG1(&field);
            }
        }
    }
}

void Cluster::MakeClusters::sanity_check_clusters(const std::string& msg, PHV::Field *lhs) {
    if (lhs && self.dst_map_i[lhs]) {
        // b --> (b,d,e); count b=1 in (b,d,e)
        if (!self.dst_map_i[lhs]->count(lhs)) {
            // sets contain at most one of any element, sanity check non-zero
            LOG1("*****cluster.cpp:sanity_FAIL*****"
                << msg << ".....cluster member does not exist in dst_map set");
            LOG1(lhs << "-->" << self.dst_map_i[lhs]);
        }
        // forall x elem (b,d,e), x-->(b,d,e)
        for (auto rhs : *(self.dst_map_i[lhs])) {
            if (self.dst_map_i[rhs] != self.dst_map_i[lhs]) {
                LOG1("*****cluster.cpp:sanity_FAIL*****"
                    << msg << ".....cluster member pointers inconsistent");
                LOG1(lhs);
                LOG1("xx vs xx");
                LOG1(rhs);
                LOG1("-------------------");
                LOG1(lhs);
                LOG1("=");
                LOG1(self.dst_map_i[lhs]);
                LOG1("-------------------");
                LOG1(rhs);
                LOG1("=");
                LOG1(self.dst_map_i[rhs]);
                LOG1("-------------------");
            }
        }
    }
}

void Cluster::MakeClusters::sanity_check_clusters_unique(const std::string& msg) {
    //
    // sanity check self.dst_map_i[] contains unique clusters only
    // forall clusters x,y
    //     x intersect y = 0
    //
    // avoid duplicate phv alloc for ccgf members as owner accounts for ccgf phv allocation
    // for m,f member of cluster x, m != f
    //    m not element of f.ccgf
    //    header stack povs: m not member of m.ccgf
    //    sub-byte header fields: m member of m.ccgf
    //
    for (auto entry : self.dst_map_i) {
        if (entry.first && entry.second) {
            ordered_set<PHV::Field *> s1 = *(entry.second);
            //
            // ccgf check
            // for x,y member of cluster, x!=y, z element of x.xxgf
            //     z != y
            //
            for (auto &f : s1) {
                for (auto &m : f->ccgf_fields()) {
                    if (m != f && s1.count(m)) {
                        LOG1("*****cluster.cpp:sanity_FAIL*****" << msg);
                        LOG1("ccgf member duplicated in cluster");
                        LOG1("member =");
                        LOG1(m);
                        LOG1("cluster =");
                        LOG1(&s1);
                    }
                }
            }
            //
            // unique clusters check
            //
            // ccgfs: s1.f.ccgf can intersect s2.f
            // s1 <-- s1 U f.ccgf, f element of s1
            // s2 <-- s2 U f.ccgf, f element of s2
            //
            ordered_set<PHV::Field *> sx;
            for (auto &f : s1) {
                for (auto &m : f->ccgf_fields()) {
                    PHV::Field *mx = m;
                    if (sx.count(mx)) {
                        LOG1("*****cluster.cpp:sanity_FAIL***** duplicate ccgf member ..." << msg);
                        LOG1(mx);
                    }
                    sx.insert(mx);
                }
            }
            for (auto &f : sx) {
                s1.insert(f);
            }
            //
            for (auto entry_2 : self.dst_map_i) {
                if (entry_2.first && entry_2.second && entry_2.first != entry.first) {
                    ordered_set<PHV::Field *> s2 = *(entry_2.second);
                    //
                    // s2 <-- s2 U f.ccgf, f element of s2
                    //
                    ordered_set<PHV::Field *> sx;
                    for (auto &f : s2) {
                        for (auto &m : f->ccgf_fields()) {
                            PHV::Field *mx = m;
                            if (sx.count(mx)) {
                                LOG1("*****cluster.cpp:sanity_FAIL***** duplicate ccgf member ....."
                                    << msg);
                                LOG1(mx);
                            }
                            sx.insert(mx);
                        }
                    }
                    for (auto &f : sx) {
                        s2.insert(f);
                    }
                    for (auto &f : s1) {
                        if (s2.count(f)) {
                            LOG1("*****cluster.cpp:sanity_FAIL***** cluster uniqueness.."
                                << msg);
                            LOG1(&s1);
                            LOG1("/\\");
                            LOG1(&s2);
                            LOG1('=');
                            LOG1("---> " << f << " <---");
                        }
                    }
                }
            }  // for
        }
    }
}  // sanity_check_clusters_unique

void Cluster::MakeClusters::sanity_check_fields_use(const std::string& msg,
    ordered_set<PHV::Field *>& all,
    ordered_set<PHV::Field *>& cluster,
    ordered_set<PHV::Field *>& all_minus_cluster,
    ordered_set<PHV::Field *>& pov,
    ordered_set<PHV::Field *>& no_mau) {
    //
    ordered_set<PHV::Field *> s_check;
    //
    // all = cluster + all_minus_cluster
    //
    ordered_set<PHV::Field *> s_all = cluster;
    s_all |= all_minus_cluster;
    // s_check = s_all - all
    s_check = s_all;
    s_check -= all;
    if (s_check.size()) {
        LOG1("*****cluster.cpp:sanity_FAIL*****fields_use.....");
        LOG1("..... cluster+all_minus_cluster != all .....");
        LOG1(msg << s_check);
    }
    //
    // cluster intersection all_minus_cluster = null
    //
    s_check = cluster;
    s_check &= all_minus_cluster;
    if (s_check.size()) {
        LOG1("*****cluster.cpp:sanity_FAIL*****fields_use.....");
        LOG1("..... cl intersect all_minus_cluster != 0 .....");
        LOG1(msg << s_check);
    }
    //
    // pov_mau = pov intersect with cluster
    //
    ordered_set<PHV::Field *> pov_mau = pov;
    pov_mau &= cluster;
    // all = cluster + pov + no_mau + pov_mau
    s_all = cluster;
    s_all |= pov;
    s_all |= no_mau;
    s_all |= pov_mau;
    // s_check = s_all - all
    s_check = s_all;
    s_check -= all;
    if (s_check.size()) {
        LOG1("*****cluster.cpp:sanity_FAIL*****fields_use .....");
        LOG1("..... fields_use all != cluster+pov+no_mau+pov_mau .....");
        LOG1(msg << s_check);
    }
}  // sanity_check_fields_use

//***********************************************************************************
//
// output stream <<
//
//***********************************************************************************
//
// cluster output
//

std::ostream &operator<<(std::ostream &out, ordered_set<PHV::Field *>* p_cluster_set) {
    if (p_cluster_set) {
        out << "cluster<#=" << p_cluster_set->size() << ">(" << std::endl;
        int n = 1;
        for (auto &field : *p_cluster_set) {
            out << "<#" << n++ << ">\t" << field << std::endl;
        }
        out << ')' << std::endl;
    } else {
        out << "cluster = ()" << std::endl;
    }
    return out;
}

std::ostream &operator<<(std::ostream &out, std::vector<PHV::Field *>& cluster_vec) {
    for (auto &field : cluster_vec) {
        out << field << std::endl;
    }
    return out;
}

std::ostream &operator<<(
    std::ostream &out,
    ordered_map<PHV::Field *, ordered_set<PHV::Field *>*>& dst_map) {
    // iterate through all elements in dst_map
    for (auto &entry : dst_map) {
        if (entry.second) {
            out << entry.first << " -->" << std::endl;
            out << entry.second;
        }
    }
    return out;
}

std::ostream &operator<<(std::ostream &out, Cluster &cluster) {
    out << "++++++++++ Clusters (" << cluster.dst_map().size() << ") ++++++++++"
        << std::endl
        << std::endl;
    // clusters
    out << cluster.dst_map();
    //
    // output pov fields
    out << std::endl;
    out << ".......... POV Fields (" << cluster.pov_fields().size() << ") ........."
        << std::endl
        << std::endl;
    out << cluster.pov_fields();
    out << std::endl;
    //
    // output fields_no_use_mau
    out << ".......... T_PHV Fields ("
        << cluster.fields_no_use_mau().size() << ") ........."
        << std::endl
        << std::endl;
    out << cluster.fields_no_use_mau();
    return out;
}

//***********************************************************************************
//
// Notes
//
//***********************************************************************************
//
// Note 1
// $mirror_id is a ‘special’ field.
// it is introduced by the parser shims for parsing mirror packets.
// for PHV allocation it should be treated like any other metadata field, as used in the IR.
// in particular expect `$mirror_id` to often be “unused” and thus not need to be allocated to a PHV
// it is extracted in the parser and used to switch parser states, but that it not actually a “use”
// of PHV allocation, the parser accesses it from the input buffer directly,
// so if no later use in MAU or deparser, the extract to PHV can be left as dead
//
// should have ingress::$mirror_id & egress::$mirror_id for phv allocation
// otherwise assembler complaint "No phv record $mirror_id"
//
// Note 2
// some fields e.g., egress_port (9 bits), egress_spec (9 bits)
// cannot share container with other fields, they expect cohabit bits = 0
// should NOT place ing_meta_data.drop bit cohabit with egress_port
// e.g., ing_metadata.egress_port: H1(0..8)
//       ing_metadata.drop: H1(15)
// ing_metadata.drop bit controlled by valid bit in egress_spec
//
// Note 3
// all digest selectors in Tofino are 3 bits, so rest of the phv is available for other uses
// mirror & resubmit both have shifts, so can use any 3 contiguous bits from any phv
// the deparser's learn_cfg has no shifter, value must be in bottom bits of container
// i.e., learning only looks at those bottom 3 bits
// allow packing after $learning in bottom bits
//
// Note 4
// ref: bf-p4c/ir/parde.def
// IR::BFN::Deparser has a field egress_port,
// which points to the egress port in the egress pipeline & egress spec in the ingress pipeline
// Each Deparser holds a vector of digests, one of which will be the learning digest if present
//
// Note 5 CCGF
// ccgfs are accumulated in network order
// so header [f1, f2, f3]
// f1's ccgf_fields contains in order f1, f2, f3
// first field of f->ccgf_fields() is the owner
// f->ccgf points to f, all members->ccgf point to f
// consider [f1<3>, f2<1>, f3<12>] where < w > = size, ccgf phv_use_lo .. phv_use_hi = 0 .. 15
// range denoted by f->phv_use_lo(), f->phv_use_hi() is the little Endian bit range,
// e.g., le_bitrange(FromTo(f->phv_use_lo(), f->phv_use_hi()))
// the allocation in a container H 0..15 would be
// 3333333333332111 container bits here are 0123456789.......
// low bit of f1 = 13, f2 = 12, f3 = 0, low bit of whole ccgf = 0
// high bit of f1 = 15, f2 = 12, f3 = 11, hi bit of whole ccgf = 15
//
