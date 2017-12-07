#include "bf-p4c/phv/make_clusters.h"
#include <boost/range/adaptors.hpp>
#include "bf-p4c/phv/phv_fields.h"
#include "lib/log.h"
#include "lib/stringref.h"

Visitor::profile_t Clustering::MakeAlignedClusters::init_apply(const IR::Node *root) {
    auto rv = Inspector::init_apply(root);
    // Initialize union_find_i with pointers to all fields in phv_i.
    for (auto& f : phv_i) {
        LOG5("Creating AlignedCluster singleton containing field " << f);
        union_find_i.insert(std::move(PHV::FieldSlice(&f))); }
    return rv;
}

// After InstructionSelection, only primitive operations should remain in
// actions. (Except SALU operands, which may be wrapped in unary operations,
// but we don't care about those here.)
bool Clustering::MakeAlignedClusters::preorder(const IR::Primitive* primitive) {
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
        union_find_i.makeUnion(PHV::FieldSlice(dst), PHV::FieldSlice(f)); }

    return false;
}

void Clustering::MakeAlignedClusters::end_apply() {
    // Create AlignedClusters from sets.
    for (auto* cluster_set : union_find_i) {
        // Create AlignedClusters, distinguishing between PHV/TPHV requirements.
        // XXX(cole): Need to account for all kinds of PHV for JBay.
        bool tphv_candidate =
            std::all_of(cluster_set->begin(), cluster_set->end(),
                        [&](const PHV::FieldSlice& slice) {
                            return !uses_i.is_used_mau(slice.field())
                                && slice.kind() != FieldKind::pov
                                && !slice.field()->deparsed_to_tm(); });
        PHV::Kind kind = tphv_candidate ? PHV::Kind::tagalong : PHV::Kind::normal;
        self.aligned_clusters_i.emplace_back(new PHV::AlignedCluster(kind, *cluster_set)); }
}

Visitor::profile_t Clustering::MakeRotationalClusters::init_apply(const IR::Node *root) {
    auto rv = Inspector::init_apply(root);
    // Initialize union_find_i with pointers to the aligned clusters formed in
    // MakeAlignedClusters.  Ditto for slices_to_clusters_i.
    for (auto* cluster : self.aligned_clusters_i) {
        union_find_i.insert(cluster);
        for (auto& slice : *cluster)
            slices_to_clusters_i[slice] = cluster; }
    return rv;
}

bool Clustering::MakeRotationalClusters::preorder(const IR::Primitive *prim) {
    if (prim->name != "set")
        return false;

    BUG_CHECK(prim->operands.size() == 2, "Primitive instruction %1% expected to have 2 operands, "
              "but it has %2%", cstring::to_cstring(prim), prim->operands.size());

    // The destination must be a PHV-backed field.
    PHV::Field* dst_f = phv_i.field(prim->operands[0]);
    BUG_CHECK(dst_f, "No PHV field for dst of instruction %1%", cstring::to_cstring(prim));
    auto dst = PHV::FieldSlice(dst_f);

    // The source may be a non-PHV backed value, however.
    PHV::Field* src_f = phv_i.field(prim->operands[1]);
    if (!src_f)
        return false;
    auto src = PHV::FieldSlice(src_f);

    LOG5("Adding set operands from instruction " << prim);
    BUG_CHECK(slices_to_clusters_i.find(dst) != slices_to_clusters_i.end(),
              "set dst operand is not present in any aligned cluster: %1%",
              cstring::to_cstring(dst));
    BUG_CHECK(slices_to_clusters_i.find(src) != slices_to_clusters_i.end(),
              "set src operand is not present in any aligned cluster: %1%",
              cstring::to_cstring(src));
    union_find_i.makeUnion(slices_to_clusters_i.at(dst), slices_to_clusters_i.at(src));
    return false;
}

void Clustering::MakeRotationalClusters::end_apply() {
    for (auto* cluster_set : union_find_i)
        self.rotational_clusters_i.emplace_back(new PHV::RotationalCluster(*cluster_set));
}

bool Clustering::MakeSuperClusters::preorder(const IR::HeaderRef *hr) {
    LOG5("Visiting HeaderRef " << hr);

    const PhvInfo::StructInfo& struct_info = phv_i.struct_info(hr);

    // Only analyze headers, not metadata structs.
    if (struct_info.metadata)
        return true;

    // Build slice lists.  Use reverse order, because types list fields in
    // network order, not little Endian order.
    PHV::SuperCluster::SliceList *accumulator = nullptr;
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
            accumulator = new PHV::SuperCluster::SliceList();
            accumulator_bits = 0; }

        accumulator->push_back(PHV::FieldSlice(field));
        accumulator_bits += field->size;

        // If we've accumulated fields that, in aggregate, reached byte
        // alignment, then add this slice list and clear the accumulator.
        if (accumulator_bits % int(PHV::Size::b8) == 0) {
            bool is_duplicate =
                std::any_of(slice_lists_i.begin(), slice_lists_i.end(),
                    [&](const PHV::SuperCluster::SliceList* sl) {
                        if (sl->size() != accumulator->size())
                            return false;
                        for (unsigned idx = 0U; idx < sl->size(); ++idx)
                            if (sl->at(idx) != accumulator->at(idx))
                                return false;
                        return true; });
            if (!is_duplicate) {
                // XXX(cole): This will need to be removed when we introduce constraint schema.
                BUG_CHECK(accumulator_bits <= 32,
                          "Trying to accumulate too many fields in CCGF %1%",
                          cstring::to_cstring(*accumulator));
                slice_lists_i.insert(accumulator);
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

void Clustering::MakeSuperClusters::end_apply() {
    UnionFind<PHV::RotationalCluster*> cluster_union_find;
    ordered_map<PHV::FieldSlice, PHV::RotationalCluster*> slices_to_clusters;

    for (auto* rotational_cluster : self.rotational_clusters_i) {
        // Insert cluster into UnionFind.
        cluster_union_find.insert(rotational_cluster);

        // Map fields to clusters for quick lookup later.
        for (auto* aligned_cluster : rotational_cluster->clusters())
            for (auto& slice : *aligned_cluster)
                slices_to_clusters[slice] = rotational_cluster; }


    // XXX(cole): Begin hack.  This is a hack to force POV bits to be grouped
    // into 8b chunks by placing them in slice lists, which is overly
    // restrictive.
    auto* ingress_list = new PHV::SuperCluster::SliceList();
    auto* egress_list = new PHV::SuperCluster::SliceList();
    for (auto& f : phv_i) {
        // Skip everything but POV valid bits.
        if (!f.pov || !f.name.endsWith("$valid"))
            continue;

        // If this validity bit is part of a header stack, skip it.
        if (f.header_stack_pov_ccgf() || f.ccgf())
            continue;

        PHV::SuperCluster::SliceList *current_list =
            f.gress == INGRESS ? ingress_list : egress_list;

        BUG_CHECK(f.size == 1, "Expected POV valid bit to have size 1 but is size %1%", f.size);
        current_list->push_back(PHV::FieldSlice(&f));

        // Make a new list after every 8 bits
        if (current_list->size() == 8) {
            slice_lists_i.insert(current_list);
            current_list = new PHV::SuperCluster::SliceList(); } }

    // If the number of headers is not a multiple of 8, then there will be some
    // leftover POV fields.
    if (ingress_list->size() > 0)
        slice_lists_i.insert(ingress_list);
    if (egress_list->size() > 0)
        slice_lists_i.insert(egress_list);

    // XXX(cole): end hack.


    // Find sets of rotational clusters that have fields that need to be placed in
    // the same container.
    for (auto* slice_list : slice_lists_i) {
        if (slice_list->size() <= 1)
            continue;

        // Union the clusters of all fields in the list.  Because union is
        // reflexive and commutative, union all clusters with the first cluster.
        BUG_CHECK(slices_to_clusters.find(slice_list->front()) != slices_to_clusters.end(),
                  "Created CCGF with field slice not in any cluster: %1%",
                  cstring::to_cstring(slice_list->front()));
        PHV::RotationalCluster* first_cluster = slices_to_clusters.at(slice_list->front());
        for (auto& slice : *slice_list) {
            BUG_CHECK(slices_to_clusters.find(slice) != slices_to_clusters.end(),
                      "Created CCGF with field slice not in any cluster: %1%",
                      cstring::to_cstring(slice));
            cluster_union_find.makeUnion(first_cluster, slices_to_clusters.at(slice)); } }

    // Build SuperClusters.
    for (auto* cluster_set : cluster_union_find) {
        // Collect slice lists that induced this grouping.
        // XXX(cole): Caching would be much more efficient.
        ordered_set<PHV::SuperCluster::SliceList*> these_lists;
        for (PHV::RotationalCluster* rotational_cluster : *cluster_set)
            for (auto* aligned_cluster : rotational_cluster->clusters() )
                for (const PHV::FieldSlice& slice : *aligned_cluster)
                    for (auto* slist : slice_lists_i)
                        if (std::find(slist->begin(), slist->end(), slice) != slist->end())
                            these_lists.insert(slist);
        self.super_clusters_i.emplace_back(new PHV::SuperCluster(*cluster_set, these_lists)); }

    if (LOGGING(1)) {
        LOG1("--- CLUSTERING RESULTS --------------------------------------------------------");
        LOG1("All fields are assigned to exactly one cluster.  Fields that are not read or");
        LOG1("written in any MAU instruction form singleton clusters.");
        LOG1("");

        LOG1("PHV CANDIDATES:");
        LOG1("");
        for (auto& g : self.super_clusters_i)
            if (!g->okIn(PHV::Kind::tagalong))
                LOG1(g);

        LOG1("TPHV CANDIDATES:");
        for (auto& g : self.super_clusters_i)
            if (g->okIn(PHV::Kind::tagalong))
                LOG1(g); }
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

