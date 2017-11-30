#include "bf-p4c/phv/make_clusters.h"
#include <boost/range/adaptors.hpp>
#include "bf-p4c/phv/phv_fields.h"
#include "lib/log.h"
#include "lib/stringref.h"

bool Clustering::MakeSuperClusters::preorder(const IR::HeaderRef *hr) {
    LOG5("Visiting HeaderRef " << hr);

    const PhvInfo::StructInfo& struct_info = phv_i.struct_info(hr);

    // Only analyze headers, not metadata structs.
    if (struct_info.metadata)
        return true;

    // Build field lists.  Use reverse order, because types list fields in
    // network order, not little Endian order.
    PHV::SuperCluster::FieldList *accumulator = nullptr;
    int accumulator_bits = 0;
    for (int fid : boost::adaptors::reverse(struct_info.field_ids())) {
        PHV::Field* field = phv_i.field(fid);
        BUG_CHECK(field != nullptr, "No PHV info for field in header reference %1%",
                  cstring::to_cstring(hr));

        // Begin accumulating at the first non-byte aligned field.
        if (!accumulator && field->size % int(PHV::Size::b8) == 0)
            continue;

        // If this is the first non-byte aligned field in this list, initialize
        // the accumulator.
        if (!accumulator) {
            accumulator = new PHV::SuperCluster::FieldList();
            accumulator_bits = 0; }

        accumulator->push_back(field);
        accumulator_bits += field->size;

        // If we've accumulated fields that, in aggregate, reached byte
        // alignment, then add this field list and clear the accumulator.
        if (accumulator_bits % int(PHV::Size::b8) == 0) {
            bool is_duplicate =
                std::any_of(field_lists_i.begin(), field_lists_i.end(),
                    [&](const PHV::SuperCluster::FieldList* fl) {
                        if (fl->size() != accumulator->size())
                            return false;
                        for (unsigned idx = 0U; idx < fl->size(); ++idx)
                            if (fl->at(idx) != accumulator->at(idx))
                                return false;
                        return true; });
            if (!is_duplicate) {
                // XXX(cole): This will need to be removed when we introduce constraint schema.
                BUG_CHECK(accumulator_bits <= 32,
                          "Trying to accumulate too many fields in CCGF %1%",
                          cstring::to_cstring(*accumulator));
                field_lists_i.insert(accumulator);
                LOG5("    ...creating CCGF " << *accumulator);
            } else {
                LOG5("    ...skipping duplicate CCGF " << *accumulator);
            }
            accumulator = nullptr;
            accumulator_bits = 0; } }

    // Headers are required to be byte aligned, which should have been checked
    // earlier in the compilation process.
    BUG_CHECK(accumulator == nullptr, "Non-byte aligned header: %1%", cstring::to_cstring(hr));
    return true;
}

bool Clustering::MakeSuperClusters::preorder(const IR::Primitive *prim) {
    if (prim->name != "set")
        return false;

    BUG_CHECK(prim->operands.size() == 2, "Primitive instruction %1% expected to have 2 operands, "
              "but it has %2%", cstring::to_cstring(prim), prim->operands.size());

    // The destination must be a PHV-backed field.
    PHV::Field* dst = phv_i.field(prim->operands[0]);
    BUG_CHECK(dst, "No PHV field for dst of instruction %1%", cstring::to_cstring(prim));

    // The source may be a non-PHV backed value, however.
    PHV::Field* src = phv_i.field(prim->operands[1]);
    if (!src)
        return false;

    LOG5("Adding set operands from instruction " << prim);
    set_operands_i.insert(std::make_pair(dst, src));
    return false;
}

void Clustering::MakeSuperClusters::end_apply() {
    UnionFind<PHV::AlignedCluster*> cluster_union_find;
    ordered_map<PHV::Field*, PHV::AlignedCluster*> field_to_cluster;

    for (auto* cluster : self.clusters_i) {
        // Insert cluster into UnionFind.
        cluster_union_find.insert(cluster);

        // Map fields to clusters for quick lookup later.
        for (auto* f : cluster->fields())
            field_to_cluster[f] = cluster; }


    // XXX(cole): Begin hack.  This is a hack to force POV bits to be grouped
    // into 8b chunks by placing them in field lists, which is overly
    // restrictive.
    auto* ingress_list = new PHV::SuperCluster::FieldList();
    auto* egress_list = new PHV::SuperCluster::FieldList();
    for (auto& f : phv_i) {
        // Skip everything but POV valid bits.
        if (!f.pov || !f.name.endsWith("$valid"))
            continue;

        // If this validity bit is part of a header stack, skip it.
        if (f.header_stack_pov_ccgf() || f.ccgf())
            continue;

        PHV::SuperCluster::FieldList *current_list =
            f.gress == INGRESS ? ingress_list : egress_list;

        BUG_CHECK(f.size == 1, "Expected POV valid bit to have size 1 but is size %1%", f.size);
        current_list->push_back(&f);

        // Make a new list after every 8 bits
        if (current_list->size() == 8) {
            field_lists_i.insert(current_list);
            current_list = new PHV::SuperCluster::FieldList(); } }

    // If the number of headers is not a multiple of 8, then there will be some
    // leftover POV fields.
    if (ingress_list->size() > 0)
        field_lists_i.insert(ingress_list);
    if (egress_list->size() > 0)
        field_lists_i.insert(egress_list);

    // XXX(cole): end hack.


    // Find sets of aligned clusters that have fields that need to be placed in
    // the same container.
    for (auto* field_list : field_lists_i) {
        if (field_list->size() <= 1)
            continue;

        // Union the clusters of all fields in the list.  Because union is
        // reflexive and transitive, union all clusters with the first cluster.
        BUG_CHECK(field_to_cluster.find(field_list->front()) != field_to_cluster.end(),
                  "Created CCGF with field not in any cluster: %1%",
                  cstring::to_cstring(field_list->front()));
        PHV::AlignedCluster* first_cluster = field_to_cluster.at(field_list->front());
        for (auto* f : *field_list) {
            BUG_CHECK(field_to_cluster.find(f) != field_to_cluster.end(),
                      "Created CCGF with field not in any cluster: %1%",
                      cstring::to_cstring(field_list->front()));
            cluster_union_find.makeUnion(first_cluster, field_to_cluster.at(f)); } }

    // Operands of `set` instructions need to be in the same MAU group (i.e.
    // the same SuperCluster) but not the same AlignedCluster.
    for (auto& ops : set_operands_i)
        cluster_union_find.makeUnion(field_to_cluster.at(ops.first),
                                     field_to_cluster.at(ops.second));

    // Build ClusterGroups.
    for (auto* cluster_set : cluster_union_find) {
        // Collect field lists that induced this grouping.
        // XXX(cole): Caching would be much more efficient.
        ordered_set<PHV::SuperCluster::FieldList*> these_lists;
        for (PHV::AlignedCluster* cluster : *cluster_set)
            for (PHV::Field* field : *cluster )
                for (auto* flist : field_lists_i)
                    if (std::find(flist->begin(), flist->end(), field) != flist->end())
                        these_lists.insert(flist);
        self.cluster_groups_i.emplace_back(new PHV::SuperCluster(*cluster_set, these_lists)); }

    if (LOGGING(1)) {
        LOG1("--- CLUSTERING RESULTS --------------------------------------------------------");
        LOG1("All fields are assigned to exactly one cluster.  Fields that are not read or");
        LOG1("written in any MAU instruction form singleton clusters.");
        LOG1("");

        LOG1("PHV CANDIDATES:");
        LOG1("");
        for (auto& g : self.cluster_groups_i)
            if (!g->okIn(PHV::Kind::tagalong))
                LOG1(g);

        LOG1("TPHV CANDIDATES:");
        for (auto& g : self.cluster_groups_i)
            if (g->okIn(PHV::Kind::tagalong))
                LOG1(g); }
}

Visitor::profile_t Clustering::MakeClusters::init_apply(const IR::Node *root) {
    auto rv = Inspector::init_apply(root);
    // Initialize union_find_i with pointers to all fields in phv_i.
    for (auto& f : phv_i) {
        LOG5("Creating AlignedCluster singleton containing field " << f);
        union_find_i.insert(&f); }
    return rv;
}

// After InstructionSelection, only primitive operations should remain in
// actions. (Except SALU operands, which may be wrapped in unary operations,
// but we don't care about those here.)
bool Clustering::MakeClusters::preorder(const IR::Primitive* primitive) {
    if (LOGGING(5)) {
        std::stringstream ss;
        ss << "Visiting primitive operation: " << primitive->name;
        for (auto& op : primitive->operands)
            ss << " " << op;
        LOG5(ss.str()); }

    // `set` doesn't induce alignment constraints, because the `deposit_field`
    // ALU instruction can rotate its source.
    if (primitive->name == "set") {
        LOG5("    ...skipping 'set', because it doesn't induce alignment constraints");
        return false; }

    if (primitive->operands.size() == 0) {
        return false; }

    // Union all operands.  Because the union operation is reflexive and
    // transitive, start with the first operand (`dst`) and union it with all
    // operands.
    PHV::Field* dst = nullptr;
    for (auto* operand : primitive->operands) {
        PHV::Field* f = phv_i.field(operand);
        if (!f) continue;
        if (!dst) dst = f;
        union_find_i.makeUnion(dst, f); }

    return false;
}

void Clustering::MakeClusters::end_apply() {
    // Create AlignedClusters from sets.
    for (auto* cluster_set : union_find_i) {
        // Create AlignedClusters, distinguishing between PHV/TPHV requirements.
        // XXX(cole): Need to account for all kinds of PHV for JBay.
        bool tphv_candidate =
            std::all_of(cluster_set->begin(), cluster_set->end(),
                        [&](const PHV::Field* f) {
                            return !uses_i.is_used_mau(f) && !f->pov && !f->deparsed_to_tm(); });
        PHV::Kind kind = tphv_candidate ? PHV::Kind::tagalong : PHV::Kind::normal;
        self.clusters_i.emplace_back(new PHV::AlignedCluster(kind, *cluster_set)); }
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
