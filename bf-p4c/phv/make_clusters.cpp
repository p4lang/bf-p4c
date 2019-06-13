#include "bf-p4c/phv/make_clusters.h"
#include <boost/range/adaptors.hpp>
#include "bf-p4c/bf-p4c-options.h"
#include "bf-p4c/phv/phv_fields.h"
#include "lib/algorithm.h"
#include "lib/log.h"
#include "lib/stringref.h"

Visitor::profile_t Clustering::ClearClusteringStructs::init_apply(const IR::Node* root) {
    auto rv = Inspector::init_apply(root);
    self.aligned_clusters_i.clear();
    self.rotational_clusters_i.clear();
    self.super_clusters_i.clear();
    self.fields_to_slices_i.clear();
    self.slices_used_in_slice_lists_i.clear();
    self.complex_validity_bits_i.clear();
    return rv;
}

bool Clustering::FindComplexValidityBits::preorder(const IR::MAU::Instruction* inst) {
    bool has_non_val = false;
    const PHV::Field* dst_validity_bit = nullptr;
    const PHV::Field* src_validity_bit = nullptr;
    for (auto* op : inst->operands) {
        auto* f = phv_i.field(op);
        if (op == inst->operands[0] && f && f->pov) {
            dst_validity_bit = f;
        } else if (!op->is<IR::Literal>()) {
            has_non_val = true;
            auto* d = phv_i.field(op);
            if (d && d->pov) src_validity_bit = d;
        }
    }

    if (dst_validity_bit && has_non_val) {
        LOG5("Found destination complex validity bit: " << dst_validity_bit);
        self.complex_validity_bits_i.insert(dst_validity_bit);
        if (src_validity_bit != nullptr) {
            self.complex_validity_bits_i.insert(src_validity_bit);
            self.complex_validity_bits_i.makeUnion(dst_validity_bit, src_validity_bit);
        }
        LOG5("Found source complex validity bit: " << src_validity_bit);
    }

    return false;
}

void Clustering::FindComplexValidityBits::end_apply() {
    if (!LOGGING(2)) return;
    LOG2("Printing complex validity bits union find structure");
    LOG2(self.complex_validity_bits_i);
}

std::vector<PHV::FieldSlice> Clustering::slices(const PHV::Field* field, le_bitrange range) const {
    BUG_CHECK(fields_to_slices_i.find(field) != fields_to_slices_i.end(),
              "Clustering::slices: field not found: %1%", cstring::to_cstring(field));

    std::vector<PHV::FieldSlice> rv;
    for (auto& slice : fields_to_slices_i.at(field))
        if (slice.range().overlaps(range))
            rv.push_back(slice);
    return rv;
}

bool Clustering::MakeSlices::updateSlices(const PHV::Field* field, le_bitrange range) {
    BUG_CHECK(self.fields_to_slices_i.find(field) != self.fields_to_slices_i.end(),
              "Field not in fields_to_slices_i: %1%", cstring::to_cstring(field));
    bool changed = false;
    auto& slices = self.fields_to_slices_i.at(field);
    // Find the slice that contains the low bit of this new range, and split it
    // if necessary.  Repeat for the high bit.
    for (auto idx : { range.lo, range.hi + 1 }) {
        for (auto slice_it = slices.begin(); slice_it != slices.end(); ++slice_it) {
            // If a slice already exists at the an idx of this range, no additional
            // slicing is necessary.
            if (slice_it->range().lo == idx) {
                break; }

            // Otherwise, if the lo idx is in another slice, split that slice.
            if (slice_it->range().contains(idx)) {
                changed = true;
                auto range_lo = slice_it->range().resizedToBits(idx - slice_it->range().lo);
                auto range_hi =
                    slice_it->range().resizedToBits(slice_it->range().size() - range_lo.size())
                                     .shiftedByBits(idx - slice_it->range().lo);
                LOG5("Clustering::MakeSlices: breaking " << *slice_it << " into " << range_lo <<
                     " / " << range_hi);
                slice_it = slices.erase(slice_it);
                slice_it = slices.emplace(slice_it, PHV::FieldSlice(field, range_lo));
                slice_it++;
                slice_it = slices.emplace(slice_it, PHV::FieldSlice(field, range_hi));
                break; } } }
    return changed;
}

Visitor::profile_t Clustering::MakeSlices::init_apply(const IR::Node *root) {
    auto rv = Inspector::init_apply(root);
    equivalences_i.clear();
    // Wrap each field in a slice.
    for (auto& f : phv_i)
        self.fields_to_slices_i[&f].push_back(PHV::FieldSlice(&f, StartLen(0, f.size)));
    return rv;
}

bool Clustering::MakeSlices::preorder(const IR::MAU::Table* tbl) {
    CollectGatewayFields collect_fields(phv_i);
    tbl->apply(collect_fields);

    auto& info_set = collect_fields.info;

    for (auto& field_info : info_set) {
        // We need to make sure that slices that are XORed with each other for gateway comparisons
        // should be sliced in the same way. The end_apply() method takes the equivalently sliced
        // sets in `equivalences_i` and propagates fine-grained slicing through those fields until
        // we reach a fixed point. Therefore, implementing equivalent slicing for gateway comparison
        // slices is equivalent to adding those equivalent slices to the `equivalences_i` object.
        auto &slice1 = field_info.first;
        auto &info = field_info.second;
        for (auto &slice2 : info.xor_with) {
            ordered_set<PHV::FieldSlice> equivalence;
            equivalence.insert(slice1);
            equivalence.insert(slice2);
            LOG5("\tAdding equivalence for gateway slices: " << slice1 << " and " << slice2);
            equivalences_i.emplace_back(equivalence);
        }
    }
    return true;
}

bool Clustering::MakeSlices::preorder(const IR::Expression *e) {
    le_bitrange range;
    PHV::Field* field = phv_i.field(e, &range);

    if (!field)
        return true;

    updateSlices(field, range);
    return true;
}

void Clustering::MakeSlices::postorder(const IR::MAU::Instruction *inst) {
    LOG5("Clustering::MakeSlices: visiting instruction " << inst);
    // Find relative combined slice positions.
    ordered_set<PHV::FieldSlice> equivalence;
    for (auto* op : inst->operands) {
        le_bitrange range;
        PHV::Field* f = phv_i.field(op, &range);
        if (!f) continue;
        equivalence.insert(PHV::FieldSlice(f, range)); }
    equivalences_i.emplace_back(equivalence);
}

void Clustering::MakeSlices::end_apply() {
    // Propagate fine-grained slicing until reaching a fixpoint.
    bool changed;
    do {
        changed = false;
        for (auto& equivalence : equivalences_i) {
            for (auto& s1 : equivalence) {
                for (auto& s2 : equivalence) {
                    for (auto& tiny_slice : self.slices(s2.field(), s2.range())) {
                        // Shift from s2's coordinate system to s1's.
                        // Eg. for f1[3:0] = f2[7:4], shift the slice from [7:4] to [3:0].
                        // and for f1[7:4] = f2[3:0], vice versa.
                        auto new_slice =
                            tiny_slice.range().shiftedByBits(s1.range().lo - s2.range().lo);
                        LOG5("    ...and splitting " << s1.field() << " at " << new_slice);
                        changed |= updateSlices(s1.field(), new_slice); } } } }
    } while (changed);

    if (LOGGING(5)) {
        LOG5("Created fine-grained slices:");
        for (auto& kv : self.fields_to_slices_i) {
            std::stringstream ss;
            for (auto& slice : kv.second)
                ss << "[" << slice.range().lo << ".." << slice.range().hi << "] ";
            LOG5("    " << kv.first << ": " << ss.str()); } }
}

Visitor::profile_t Clustering::MakeAlignedClusters::init_apply(const IR::Node *root) {
    auto rv = Inspector::init_apply(root);
    union_find_i.clear();
    // Initialize union_find_i with pointers to all field slices.
    for (auto& by_field : self.fields_to_slices_i) {
        for (auto& slice : by_field.second) {
            LOG5("Creating AlignedCluster singleton containing field slice " << slice);
            union_find_i.insert(slice); } }
    return rv;
}

// After InstructionSelection, only primitive operations should remain in
// actions. (Except SALU operands, which may be wrapped in unary operations,
// but we don't care about those here.)
bool Clustering::MakeAlignedClusters::preorder(const IR::MAU::Instruction* inst) {
    LOG5("Clustering::MakeAlignedClusters: visiting instruction " << inst);
    if (findContext<IR::MAU::SaluAction>()) {
        LOG5("    ...skipping SALU instruction " << inst);
        return false; }

    if (inst->operands.size() == 0) {
        return false; }

    // `set` doesn't induce alignment constraints, because the `deposit_field`
    // ALU instruction can rotate its source.  This is not true for casting
    // instructions to a larger size, however, which require the PHV sources to
    // be aligned.
    if (inst->name == "set") {
        le_bitrange src_range;
        le_bitrange dst_range;
        auto* src = phv_i.field(inst->operands[1]);
        auto* dst = phv_i.field(inst->operands[0]);

        // If the entirety of the source is assigned to a piece of the
        // destination, and the destination is larger than the source, then
        // another set instruction exists to assign 0 to the rest of the
        // destination.  In this case, the deposit_field instruction will
        // require the source and destination to be aligned.
        bool needs_alignment = src && dst && src->size == dst_range.size() &&
                                             dst->size != dst_range.size();
        if (!needs_alignment) {
            LOG5("    ...skipping 'set', because it doesn't induce alignment constraints");
            return false; } }

    // Union all operands.  Because the union operation is reflexive and
    // transitive, start with the first operand (`dst`) and union it with all
    // operands.
    std::vector<PHV::FieldSlice> dst_slices;
    for (auto* operand : inst->operands) {
        le_bitrange range;
        PHV::Field* f = phv_i.field(operand, &range);
        LOG5("UNION over instruction " << inst);
        if (!f) continue;
        if (!dst_slices.size()) {
            dst_slices = self.slices(f, range);
            BUG_CHECK(dst_slices.size(),
                      "No slices for field %1% in range %2%",
                      cstring::to_cstring(f), cstring::to_cstring(range)); }
        auto these_slices = self.slices(f, range);

        // Some instructions naturally take operands of different sizes, eg.
        // shift, where the shift amount is usually smaller than the value
        // being shifted.  In that case, the lowest slices will be aligned,
        // which combines with the `no_split` constraint on non-move
        // instructions to ensure that the entirety of these fields are aligned
        // at the lowest bits.
        auto dst_slices_it = dst_slices.begin();
        auto these_slices_it = these_slices.begin();
        while (dst_slices_it != dst_slices.end() && these_slices_it != these_slices.end()) {
            LOG5("Adding aligned operands: " << *dst_slices_it << ", " << *these_slices_it);
            union_find_i.makeUnion(*dst_slices_it, *these_slices_it);
            ++dst_slices_it;
            ++these_slices_it; } }

    return false;
}

bool Clustering::MakeAlignedClusters::preorder(const IR::MAU::Table *tbl) {
    CollectGatewayFields collect_fields(phv_i);
    tbl->apply(collect_fields);
    auto& info_set = collect_fields.info;

    // Union all operands.  Because the union operation is reflexive and
    // transitive, start with the first operand and union it with all
    // operands.
    for (auto& field_info : info_set) {
        auto& field = field_info.first;
        auto& info = field_info.second;
        for (auto xor_with : info.xor_with) {
            // instead of using const_cast, get a mutable pointer from phvInfo.
            auto* field_a = phv_i.field(field.field()->id);
            auto* field_b = phv_i.field(xor_with.field()->id);
            auto slices_a = self.slices(field_a, StartLen(0, field_a->size));
            auto slices_b = self.slices(field_b, StartLen(0, field_b->size));
            auto a_it = slices_a.begin();
            auto b_it = slices_b.begin();
            while (a_it != slices_a.end() && b_it != slices_b.end()) {
                union_find_i.makeUnion(*a_it, *b_it);
                ++a_it;
                ++b_it; } } }
    return true;
}

void Clustering::MakeAlignedClusters::end_apply() {
    // Create AlignedClusters from sets.
    for (auto* cluster_set : union_find_i) {
        // Create AlignedClusters, distinguishing between PHV/TPHV requirements.
        // XXX(cole): Need to account for all kinds of PHV for JBay.
        bool tphv_candidate =
            std::all_of(cluster_set->begin(), cluster_set->end(),
                        [&](const PHV::FieldSlice& slice) {
                            return slice.is_tphv_candidate(uses_i); });
        PHV::Kind kind = tphv_candidate ? PHV::Kind::tagalong : PHV::Kind::normal;
        self.aligned_clusters_i.emplace_back(new PHV::AlignedCluster(kind, *cluster_set)); }
}

Visitor::profile_t Clustering::MakeRotationalClusters::init_apply(const IR::Node *root) {
    auto rv = Inspector::init_apply(root);
    union_find_i.clear();
    slices_to_clusters_i.clear();
    // Initialize union_find_i with pointers to the aligned clusters formed in
    // MakeAlignedClusters.  Ditto for slices_to_clusters_i.
    for (auto* cluster : self.aligned_clusters_i) {
        union_find_i.insert(cluster);
        LOG5("MakeRotationalClusters: Adding singleton aligned cluster " << cluster);
        for (auto& slice : *cluster)
            slices_to_clusters_i[slice] = cluster; }
    return rv;
}

bool Clustering::MakeRotationalClusters::preorder(const IR::MAU::Instruction *inst) {
    if (inst->name != "set")
        return false;

    LOG5("MakeRotationalClusters: Visiting " << inst);
    BUG_CHECK(inst->operands.size() == 2, "Primitive instruction %1% expected to have 2 operands, "
              "but it has %2%", cstring::to_cstring(inst), inst->operands.size());

    // The destination must be a PHV-backed field.
    le_bitrange dst_range;
    PHV::Field* dst_f = phv_i.field(inst->operands[0], &dst_range);
    BUG_CHECK(dst_f, "No PHV field for dst of instruction %1%", cstring::to_cstring(inst));

    // The source may be a non-PHV backed value, however.
    le_bitrange src_range;
    PHV::Field* src_f = phv_i.field(inst->operands[1], &src_range);
    if (!src_f)
        return false;
    LOG5("Adding set operands from instruction " << inst);

    auto dst_slices = self.slices(dst_f, dst_range);
    auto src_slices = self.slices(src_f, src_range);
    auto dst_slices_it = dst_slices.begin();
    auto src_slices_it = src_slices.begin();
    while (dst_slices_it != dst_slices.end() && src_slices_it != src_slices.end()) {
        auto dst = *dst_slices_it;
        auto src = *src_slices_it;
        BUG_CHECK(dst.size() == src.size(),
                  "set operands of different sizes: %1%, %2%\ninstruction: %3%",
                  cstring::to_cstring(dst), cstring::to_cstring(src),
                  cstring::to_cstring(inst));
        BUG_CHECK(slices_to_clusters_i.find(dst) != slices_to_clusters_i.end(),
                  "set dst operand is not present in any aligned cluster: %1%",
                  cstring::to_cstring(dst));
        BUG_CHECK(slices_to_clusters_i.find(src) != slices_to_clusters_i.end(),
                  "set src operand is not present in any aligned cluster: %1%",
                  cstring::to_cstring(src));
        LOG5("Adding rotationally-equivalent operands: " << *dst_slices_it << ", "
             << *src_slices_it);
        union_find_i.makeUnion(slices_to_clusters_i.at(dst), slices_to_clusters_i.at(src));
        ++dst_slices_it;
        ++src_slices_it; }

    return false;
}

void Clustering::MakeRotationalClusters::end_apply() {
    for (auto* cluster_set : union_find_i)
        self.rotational_clusters_i.emplace_back(new PHV::RotationalCluster(*cluster_set));
}

Visitor::profile_t Clustering::MakeSuperClusters::init_apply(const IR::Node* root) {
    auto rv = Inspector::init_apply(root);
    headers_i.clear();
    slice_lists_i.clear();
    return rv;
}

void Clustering::MakeSuperClusters::visitHeaderRef(const IR::HeaderRef* hr) {
    LOG5("Visiting HeaderRef " << hr);
    const PhvInfo::StructInfo& struct_info = phv_i.struct_info(hr);

    // Only analyze headers, not metadata structs.
    if (struct_info.metadata || struct_info.size == 0) {
        LOG5("Ignoring metadata or zero struct info: " << hr);
        return;
    }

    if (headers_i.find(struct_info.first_field_id) != headers_i.end())
        return;
    headers_i.insert(struct_info.first_field_id);

    // Build slice lists.  All slices of the same field go in the same slice
    // list.  Additionally, non-byte aligned fields are grouped together in the
    // smallest byte-aligned chunk.  Use reverse order, because types list
    // fields in network order, not little Endian order.
    PHV::SuperCluster::SliceList *accumulator = new PHV::SuperCluster::SliceList();
    int accumulator_bits = 0;

    // This tracks whether the slice list so far is a TPHV candidate, with
    // boost::none indicating that the slice list hasn't been started yet.
    // TODO(yumin): optional<bool> is not good.
    boost::optional<bool> prev_is_tphv = boost::none;
    const PHV::Field* lastDigest = nullptr;
    bool lastNoPack = false;
    bool lastWideArith = false;
    bool lastDeparserZero = false;
    bool break_at_next_byte_boundary = false;
    bool lastUnreferenced = false;

    auto StartNewSliceList = [&](void) {
        slice_lists_i.insert(accumulator);
        accumulator_bits = 0;
        prev_is_tphv = boost::none;
        accumulator = new PHV::SuperCluster::SliceList();
        lastNoPack = false;
        lastDigest = nullptr;
        lastWideArith = false;
        lastDeparserZero = false;
        break_at_next_byte_boundary = false;
        lastUnreferenced = false;
    };

    LOG5("Starting new slice list:");
    for (int fid : boost::adaptors::reverse(struct_info.field_ids())) {
        PHV::Field* field = phv_i.field(fid);

        BUG_CHECK(field != nullptr, "No PHV info for field in header reference %1%",
                  cstring::to_cstring(hr));
        BUG_CHECK(self.fields_to_slices_i.find(field) != self.fields_to_slices_i.end(),
                  "Found field in header but not PHV: %1%",
                  cstring::to_cstring(field));

        // XXX(cole): HACK to deal with intrinsic metadata padding.  Some
        // intrinsic metadata is not deparsed and also marked as no-pack.  To
        // avoid prepending its padding to the next slice list, we don't
        // include unreferenced fields as the first fields in slice lists.  The
        // longer-term solution is to replace slice lists with
        // finer-granularity constraints.

        // XXX(hanw):
        // When allocating for a header that has
        // header {
        //    bit<4> _field_0;   // unreferenced;
        //    bit<4> _padding;
        //    bit<8> _field_1;   // referenced; }
        // The check above would skip the first field, because it is
        // unreferenced. We should also skip the second padding.
        if (accumulator_bits % int(PHV::Size::b8) == 0 &&
                lastUnreferenced && field->padding) {
            LOG5("    ...skipping padding after unreferenced field: " << field);
            continue;
        }

        // If the slice list contains a no_pack field, then all the other slices in the list (if
        // any) must be padding or unreferenced (unreferenced fields effectively act as a
        // padding field).
        if (lastNoPack && !field->padding && self.uses_i.is_referenced(field)) {
            StartNewSliceList();
            LOG5("Starting new slice list (to isolate a no_pack field): ");
        } else if (lastWideArith && !field->padding) {
            StartNewSliceList();
            LOG5("Starting new slice list (to isolate a field used in wide arithmetic): ");
        } else if (lastDigest && !field->is_digest() && !field->padding &&
                !self.uses_i.is_referenced(field)) {
            StartNewSliceList();
            LOG5("Starting new slice list (to separate a digest and non-digest field): ");
        }

        // If the slice list containers a deparser_zero field and the current field is not a
        // deparser zero optimization candidate, then start a new slice list.
        if (lastDeparserZero && !field->is_deparser_zero_candidate()) {
            StartNewSliceList();
            LOG5("Starting new slice list (to isolate deparser zero field): "); }

        // Privatizable fields are the PHV copies of fields duplicated in TPHVs. So, slice creation
        // has to start a new slice whenever it encounters a privatizable field. By construction,
        // privatizable fields only being at a byte-aligned offset within a header, so this is a
        // safe place to slice clusters.
        bool is_tphv = field->is_tphv_candidate(self.uses_i) || field->privatizable();

        // Break off, if field is extracted in Phase 0, i.e. if field is
        // bridged and also extracted in INGRESS.
        // XXX(cole): This should work for bridged metadata extracted in Phase
        // 0, but needs more thought for extracted header fields.  See
        // BRIG-301.
        break_at_next_byte_boundary |= self.uses_i.is_extracted(field) && field->bridged;

        if (accumulator_bits && (field->no_pack())) {
            // Break off the existing slice list if this field has a no_pack
            // Break at bottom as well
            StartNewSliceList();
            LOG5("Starting new slice list (for no_pack field):");
        } else if (accumulator_bits && (field->used_in_wide_arith())) {
            // Break off the existing slice list if this field is used in wide arithmetic
            // Break at bottom as well
            StartNewSliceList();
            LOG5("Starting new slice list (for field used in wide arithmetic):");
        } else if (accumulator_bits && !lastDeparserZero && field->is_deparser_zero_candidate()) {
            // Break off the existing slice list if this field is a deparser zero optimization
            // candidate.
            StartNewSliceList();
            LOG5("Starting new slice list (for deparser zero field):");
        } else if (accumulator_bits && field->is_digest()) {
            // Break off the existing slice list if this field is a digest
            if (lastDigest == nullptr || accumulator_bits % int(PHV::Size::b8) == 0)
                StartNewSliceList();
            lastDigest = field;
            LOG5("Starting new slice list (for digest field):");
        } else if (accumulator_bits % int(PHV::Size::b8) == 0 &&
                lastDigest != nullptr && !field->is_digest() && !field->padding) {
            // break off the existing slice list if a metadata field is used in digest,
            // AND the field is aliased as a source to a bridged metadata header AND
            // the next field in the bridged metadata header is not used in the digest.
            // This happens in switch-16 with mirroring digest.
            // DO NOT break off if the field is a header field, otherwise, it may break
            // the packing requirement of header field, see basic_ipv4.p4 when emitting
            // ipv4.ihl as a digest field, it must be packed with ipv4.version, even if
            // the ipv4.version if not emitted.
            StartNewSliceList();
            LOG5("Starting new slice list (to isolate non digest field from digest field):");
        } else if (accumulator_bits % int(PHV::Size::b8) == 0 && break_at_next_byte_boundary) {
            StartNewSliceList();
            LOG5("Starting new slice list (at phase 0 field boundary):");

/* XXX(cole): This heuristic proactively breaks a slice list at a PHV/TPHV
 * boundary to encourage TPHV-eligible fields to be packed in TPHV containers.
 * However, that precludes packing TPHV fields with adjacent PHV fields in PHV
 * containers, which is sometimes necessary when MAU operations require small
 * header fields to be placed in larger containers.
 *
 * Remove it for now, because it causes problems with fabric + INT.

        } else if (accumulator_bits % int(PHV::Size::b8) == 0 && prev_is_tphv &&
                   *prev_is_tphv != is_tphv) {
            // Break off, if previous one is phv/tphv but this one is not the same.
            StartNewSliceList();
            LOG5("Starting new slice list (at " << (is_tphv ? "PHV-->TPHV" : "TPHV-->PHV") <<
                 " boundary):");

 */

/* XXX(cole): This heuristic proactively breaks big headers into 32b chunks,
 * which cuts down on the combinatorial space of slicing headers.

        } else if (accumulator_bits % int(PHV::Size::b8) == 0
                   && accumulator_bits + field->size > int(PHV::Size::b32)) {
            // Break off, if this field is a large field.
            StartNewSliceList();
            LOG5("Starting new slice list (after " << accumulator_bits << "b because the next field"
                    " is large):");
*/

        } else if (accumulator_bits % int(PHV::Size::b8) == 0
                   && !self.uses_i.is_referenced(field) && !field->isGhostField()) {
            LOG5("    ...breaking slice list before unreferenced field: " << field);
            // Break off, on unreferenced/referenced boundary.
            // Break at bottom as well.
            StartNewSliceList();
            LOG5("Starting new slice list (after " << accumulator_bits << "b because the next field"
                    " is unreferenced):"); }

        // XXX(Deep): From BRIG-899
        // The hardware writes ghost metadata to a single 32-bit phv container in a very
        // constrained form. The fields are written to certain bits in a fixed way:
        //   pipe to [1:0]
        //   qid to [12:2]
        //   qlength to [30:13]
        //   pingpong to [31:31]
        // So, phv allocation must match the header. If a particular field is unused (pipe is rarely
        // used), the hardware will still write those bits, so it may not be possible to reuse it
        // for something else (need to add an explicit write in the mau pipe). The fields may not
        // also be relocated within the container.
        if (accumulator_bits == 0 && !self.uses_i.is_referenced(field) && !field->isGhostField()) {
            LOG5("    ...skipping unreferenced field at the beginning of a slice list: " << field);
            lastUnreferenced = true;
            continue; }

        int field_slice_list_size = 0;
        for (auto& slice : self.fields_to_slices_i.at(field)) {
            LOG5("    ...adding " << slice);
            accumulator->push_back(slice);
            field_slice_list_size += slice.size();
            self.slices_used_in_slice_lists_i.insert(slice); }
        accumulator_bits += field->size;
        lastNoPack = field->no_pack() || (lastNoPack && !self.uses_i.is_referenced(field)) ||
            (lastNoPack && field->padding);
        lastWideArith = field->used_in_wide_arith();
        lastDeparserZero = field->is_deparser_zero_candidate();
        lastUnreferenced = !self.uses_i.is_referenced(field);
        lastDigest = (field->is_digest() || (lastDigest && !self.uses_i.is_referenced(field)) ||
                (lastDigest && field->padding)) ? field : nullptr;

        // We use AND because all slices in a slice list must be TPHV
        // candidates for the slice list to be a TPHV candidate.  Note that a
        // mix of PHV/TPHV candidates may be in the same slice list if the
        // boundary is not byte-aligned.
        prev_is_tphv = prev_is_tphv.get_value_or(true) && is_tphv;

        BUG_CHECK(field_slice_list_size == field->size,
                  "Fine grained slicing of field %1% (size %2%) produced slices adding up to %3%b",
                  cstring::to_cstring(field), field->size, field_slice_list_size);

        // Break off the slice list holding this field if it has a no_pack
        // constraint, or if the list has reached a byte multiple of at least
        // 32b.
        bool is_multiple = accumulator_bits % int(PHV::Size::b8) == 0 && accumulator_bits >= 32;
        if (is_multiple || (accumulator_bits % int(PHV::Size::b8) == 0
                && !self.uses_i.is_referenced(field))) {
            StartNewSliceList();
            LOG5("Starting new slice list:"); } }

    if (accumulator->size())
        slice_lists_i.insert(accumulator);
}

bool Clustering::MakeSuperClusters::preorder(const IR::ConcreteHeaderRef* hr) {
    visitHeaderRef(hr);
    return false;
}

bool Clustering::MakeSuperClusters::preorder(const IR::HeaderStackItemRef* hr) {
    visitHeaderRef(hr);
    return false;
}

// Create slice list from digest field list, this will allow compiler inserted
// padding field to be allocated to the same container as the field that is
// being padded.
void Clustering::MakeSuperClusters::visitDigestFieldList(
        const IR::BFN::DigestFieldList *fl, int skip) {
    PHV::SuperCluster::SliceList *accumulator = new PHV::SuperCluster::SliceList();
    int accumulator_bits = 0;
    bool lastSkipped = 0;

    if (fl->sources.size() == 0)
        return;
    LOG5("  creating slice list from field list: " << fl);

    auto StartNewSliceList = [&](void) {
        accumulator_bits = 0;
        accumulator = new PHV::SuperCluster::SliceList();
        lastSkipped = false;
    };

    for (auto f = fl->sources.rbegin(); f != fl->sources.rend() - skip; f++) {
        const PHV::Field* field = phv_i.field((*f)->field);

        if (lastSkipped && field->padding) {
            LOG5("    ...skipping padding after duplicated field: " << field);
            continue;
        }
        if (accumulator_bits % int(PHV::Size::b8) == 0) {
            slice_lists_i.insert(accumulator);
            StartNewSliceList();
            LOG5("Starting new slice list (for digest)");
        }
        for (auto &slice : self.fields_to_slices_i.at(field)) {
            if (!self.slices_used_in_slice_lists_i.count(slice)) {
                LOG5("    ...adding " << slice);
                self.slices_used_in_slice_lists_i.insert(slice);
                accumulator->push_back(slice);
                accumulator_bits += slice.size();
            } else {
                LOG5("    ...skipping duplicated field: " << field);
                StartNewSliceList();
                lastSkipped = true;
            }
        }
    }

    if (accumulator->size()) {
        slice_lists_i.insert(accumulator);
    }
}

bool Clustering::MakeSuperClusters::preorder(const IR::BFN::Digest* digest) {
    if (digest->name != "learning" && digest->name != "mirror"
            && digest->name != "resubmit" && digest->name != "pktgen")
        return false;

    if (digest->name == "learning" || digest->name == "pktgen") {
        for (auto fieldList : digest->fieldLists)
            visitDigestFieldList(fieldList, 0);
    }

    if (digest->name == "resubmit") {
        for (auto fieldList : digest->fieldLists) {
            visitDigestFieldList(fieldList, 1);
        }
    }

    // skip the first element in digest sources which is the session id
    if (digest->name == "mirror") {
        for (auto fieldList : digest->fieldLists) {
            visitDigestFieldList(fieldList, 1);
        }
    }

    return false;
}

void Clustering::MakeSuperClusters::pack_pov_bits() {
    ordered_set<PHV::Field*> pov_bits;

    for (auto& f : phv_i) {
        // Don't bother adding unreferenced fields.
        if (!self.uses_i.is_referenced(&f)) continue;

        // Skip everything but POV valid bits.
        if (!f.pov) continue;

        // Skip valid bits for header stacks, which are allocated with
        // $stkvalid.
        if (f.size > 1) continue;

        // Skip valid bits involved in complex instructions, because they have
        // complicated packing constraints.
        if (self.complex_validity_bits_i.contains(&f)) {
            LOG5("Ignoring field " << f.name << " because it is a complex validity bit.");
            continue;
        }

        pov_bits.insert(&f);
    }

    // XXX(Deep): Might need to reintroduce this later, if we need to pack POV bits better.
    // pack_complex_pov_bits();

    auto* ingress_list = new PHV::SuperCluster::SliceList();
    auto* egress_list = new PHV::SuperCluster::SliceList();
    int ingress_list_bits = 0;
    int egress_list_bits = 0;

    ordered_set<PHV::Field*> allocated_pov_bits;

    ordered_map<PHV::Field*, ordered_set<PHV::Field*>> extractedTogetherBits;
    const auto& unionFind = phv_i.getSameSetConstantExtraction();
    for (auto* f : pov_bits) {
        if (!phv_i.hasParserConstantExtract(f)) continue;
        const auto* fSet = unionFind.setOf(f);
        for (auto* f1 : pov_bits) {
            if (f == f1) continue;
            if (!phv_i.hasParserConstantExtract(f1)) continue;
            if (fSet->find(f1) == fSet->end()) continue;
            extractedTogetherBits[f].insert(f1);
        }
    }

    if (LOGGING(3)) {
        LOG3("Printing extracted together bits");
        for (auto kv : extractedTogetherBits) {
            LOG3("\t" << kv.first->name);
            std::stringstream ss;
            for (auto* f : kv.second)
                ss << f->name << " ";
            LOG3("\t  " << ss.str());
        }
    }

    ordered_set<PHV::Field*> allocated_extracted_together_bits;
    for (auto* f : pov_bits) {
        if (allocated_extracted_together_bits.count(f)) continue;
        LOG5("Creating POV BIT LIST with " << f);
        // NB: Use references to mutate the appropriate list/counter.
        auto& current_list = f->gress == INGRESS ? ingress_list : egress_list;
        int& current_list_bits = f->gress == INGRESS ? ingress_list_bits : egress_list_bits;

        std::vector<PHV::FieldSlice> toBeAddedFields;
        toBeAddedFields.push_back(PHV::FieldSlice(f));

        if (extractedTogetherBits.count(f)) {
            allocated_extracted_together_bits.insert(f);
            for (auto* g : extractedTogetherBits[f]) {
                if (allocated_extracted_together_bits.count(g)) continue;
                toBeAddedFields.push_back(PHV::FieldSlice(g));
                allocated_extracted_together_bits.insert(g);
            }
        }

        // Check if any no-pack constraints have been inferred on the candidate field f, the fields
        // the candidate field must be packed with, and any other field already in the slice list.
        bool any_pack_conflicts = false;
        for (auto& slice1 : *current_list) {
            for (auto& slice2 : toBeAddedFields) {
                if (slice1 == slice2) continue;
                if (conflicts_i.hasPackConflict(slice1.field(), slice2.field()))
                    any_pack_conflicts = true; } }
        if (any_pack_conflicts) {
            LOG5("    Ignoring POV bit " << f->name << " because of a pack conflict");
            continue; }
        if (f->no_pack()) {
            ::error("POV Bit %1% is marked as no-pack", f->name);
            continue; }

        for (auto& slice : toBeAddedFields) {
            current_list->push_back(slice);
            current_list_bits += f->size;
            if (current_list_bits >= 32) {
                LOG5("Creating new POV slice list: " << current_list);
                slice_lists_i.insert(current_list);
                for (auto sl = current_list->begin(); sl != current_list->end(); sl++)
                    allocated_pov_bits.insert(phv_i.field((*sl).field()->id));
                current_list = new PHV::SuperCluster::SliceList();
                current_list_bits = 0;
            }
        }
    }

    if (ingress_list->size() != 0) {
        LOG4("Creating new POV slice list: " << ingress_list);
        slice_lists_i.insert(ingress_list);
        for (auto sl = ingress_list->begin(); sl != ingress_list->end(); sl++)
            allocated_pov_bits.insert(phv_i.field((*sl).field()->id));
    }
    if (egress_list->size() != 0) {
        LOG4("Creating new POV slice list: " << egress_list);
        slice_lists_i.insert(egress_list);
        for (auto sl = egress_list->begin(); sl != egress_list->end(); sl++)
            allocated_pov_bits.insert(phv_i.field((*sl).field()->id));
    }
}

void Clustering::MakeSuperClusters::end_apply() {
    // XXX(cole): This is a temporary hack to try to encourage slices of
    // metadata fields with alignment constraints to be placed together.
    for (auto& kv : self.fields_to_slices_i) {
        if (!self.uses_i.is_referenced(kv.first)) continue;
        bool is_metadata = kv.first->metadata || kv.first->pov;
        int minByteSize = ROUNDUP(kv.first->size, 8);
        bool is_exact_containers = kv.first->hasMaxContainerBytesConstraint() &&
            (kv.first->getMaxContainerBytes() == minByteSize);
        // The kv.second.size() comparison is added to avoid creating slice lists containing one
        // slice.
        bool has_constraints = kv.first->alignment
                               || (kv.first->no_split() && kv.second.size() > 1)
                               || (kv.first->no_pack() && kv.second.size() > 1)
                               || kv.first->is_checksummed() || kv.first->is_marshaled()
                               // We must create slice lists for all metadata fields that are
                               // involved in wide arithmetic to ensure that the slices of those
                               // fields can bbe placed adjacently.
                               || kv.first->used_in_wide_arith() || is_exact_containers;

        // XXX(hanw): if any slice of a field is already assigned to a slice
        // list, do not create additional slice list from the field.  This is
        // to avoid creating separate slice list for padding and padded in
        // digest field lists.
        bool used = false;
        for (auto& slice : kv.second) {
            if (self.slices_used_in_slice_lists_i.count(slice)) {
                used = true;
                break; } }
        if (used) {
            LOG5("Skip creating slice list for field " << kv.first);
            continue;
        }

        // XXX(cole): Bridged metadata is treated as a header, except in the
        // egress pipeline, where it's treated as metadata.  We need to take
        // care here not to add those fields to slice lists here, because they
        // will already have been added when traversing headers.

        if (is_metadata && has_constraints && !kv.first->bridged) {
            LOG5("Creating slice list for field " << kv.first);
            auto* list = new PHV::SuperCluster::SliceList();
            for (auto& slice : kv.second)
                list->push_back(slice);
            slice_lists_i.insert(list); } }

    pack_pov_bits();

    UnionFind<const PHV::RotationalCluster*> cluster_union_find;
    ordered_map<PHV::FieldSlice, PHV::RotationalCluster*> slices_to_clusters;

    for (auto* rotational_cluster : self.rotational_clusters_i) {
        // Insert cluster into UnionFind.
        cluster_union_find.insert(rotational_cluster);

        // Map fields to clusters for quick lookup later.
        for (auto* aligned_cluster : rotational_cluster->clusters())
            for (auto& slice : *aligned_cluster)
                slices_to_clusters[slice] = rotational_cluster; }

    // Find sets of rotational clusters that have fields that need to be placed in
    // the same container.
    for (auto* slice_list : slice_lists_i) {
        if (slice_list->size() <= 1)
            continue;

        // Union the clusters of all fields in the list.  Because union is
        // reflexive and commutative, union all clusters with the first cluster.
        BUG_CHECK(slices_to_clusters.find(slice_list->front()) != slices_to_clusters.end(),
                  "Created slice list with field slice not in any cluster: %1%",
                  cstring::to_cstring(slice_list->front()));
        PHV::RotationalCluster* first_cluster = slices_to_clusters.at(slice_list->front());
        for (auto& slice : *slice_list) {
            BUG_CHECK(slices_to_clusters.find(slice) != slices_to_clusters.end(),
                      "Created slice list with field slice not in any cluster: %1%",
                      cstring::to_cstring(slice));
            cluster_union_find.makeUnion(first_cluster, slices_to_clusters.at(slice)); } }

    // Build SuperClusters.
    for (auto* cluster_set : cluster_union_find) {
        // Collect slice lists that induced this grouping.
        // XXX(cole): Caching would be much more efficient.
        ordered_set<PHV::SuperCluster::SliceList*> these_lists;
        ordered_set<PHV::FieldSlice> slices_in_these_lists;
        for (auto* rotational_cluster : *cluster_set)
            for (auto* aligned_cluster : rotational_cluster->clusters() )
                for (const PHV::FieldSlice& slice : *aligned_cluster)
                    for (auto* slist : slice_lists_i)
                        if (std::find(slist->begin(), slist->end(), slice) != slist->end())
                            these_lists.insert(slist);

        // Put each exact_containers slice in a rotational cluster but not in a
        // field list into a singelton field list.
        for (auto* slice_list : these_lists)
            for (auto& slice_in_list : *slice_list)
                slices_in_these_lists.insert(slice_in_list);
        for (auto* rotational_cluster : *cluster_set)
            for (auto* aligned_cluster : rotational_cluster->clusters())
                for (auto& slice : *aligned_cluster)
                    if (slice.field()->exact_containers()
                        && slices_in_these_lists.find(slice) == slices_in_these_lists.end()) {
                        auto* new_list = new PHV::SuperCluster::SliceList();
                        new_list->push_back(slice);
                        these_lists.insert(new_list);
                        slices_in_these_lists.insert(slice); }

        // side-effect: cluster_set and these_lists might changes.
        addPaddingForMarshaledFields(*cluster_set, these_lists);
        self.super_clusters_i.emplace_back(new PHV::SuperCluster(*cluster_set, these_lists));
    }


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

void Clustering::MakeSuperClusters::addPaddingForMarshaledFields(
        ordered_set<const PHV::RotationalCluster*>& cluster_set,
        ordered_set<PHV::SuperCluster::SliceList*>& these_lists) {
    // Add paddings for marshaled fields slice list, to the size of the largest
    // slice list, up to the largest container size.
    int max_slice_list_size = 8;
    for (const auto* slice_list : these_lists) {
        int sum_bits = 0;
        for (const auto& fs : *slice_list) {
            sum_bits += fs.size(); }
        max_slice_list_size = std::max(max_slice_list_size, sum_bits);
    }
    // Round up to the closest 8-bit.
    max_slice_list_size = ROUNDUP(max_slice_list_size, 8) * 8;

    for (auto* slice_list : these_lists) {
        if (std::any_of(slice_list->begin(), slice_list->end(),
                        [] (const PHV::FieldSlice& fs) {
                            return fs.field()->is_marshaled(); })) {
            int sum_bits = 0;
            for (const auto& fs : *slice_list) {
                sum_bits += fs.size(); }
            BUG_CHECK(max_slice_list_size >= sum_bits, "wrong max slice list size.");

            bool has_bridged = std::any_of(slice_list->begin(), slice_list->end(),
                                           [] (const PHV::FieldSlice& fs) {
                                               return fs.field()->bridged; });
            // If a slice has bridged field, then it's padding is handled by bridged metadata
            // packing now. Adding extract padding here will make parse_bridged state wrong
            // because we do not adjust bridged metadata state.
            // TODO(yumin): in a long term, we need a way to deal with those marshaled fields,
            // bridged/mirrored/resubmited uniformly.
            if (has_bridged) {
                continue; }
            // If this field does not need padding, skip it.
            if (max_slice_list_size == sum_bits) {
                continue; }

            auto* padding = phv_i.create_dummy_padding(max_slice_list_size - sum_bits,
                                                       slice_list->front().gress());
            padding->set_exact_containers(true);
            auto padding_fs = PHV::FieldSlice(padding);
            slice_list->push_back(padding_fs);
            auto* aligned_cluster_padding =
                new PHV::AlignedCluster(PHV::Kind::normal,
                                        std::vector<PHV::FieldSlice>{padding_fs});
            auto* rot_cluster_padding = new PHV::RotationalCluster({aligned_cluster_padding});
            self.aligned_clusters_i.push_back(aligned_cluster_padding);
            self.rotational_clusters_i.push_back(rot_cluster_padding);
            cluster_set.insert(rot_cluster_padding);
            LOG4("Added " << padding_fs << " for " <<  slice_list);
        }
    }
}

Visitor::profile_t Clustering::ValidateDeparserZeroClusters::init_apply(const IR::Node* root) {
    // Flag an error if the supercluster has a mix of deparsed zero fields and non deparsed zero
    // fields.
    for (auto* sc : self.cluster_groups()) {
        bool has_deparser_zero_fields = sc->any_of_fieldslices(
                [&] (const PHV::FieldSlice& fs) { return fs.field()->is_deparser_zero_candidate();
                });
        bool has_non_deparser_zero_fields = sc->any_of_fieldslices(
                [&] (const PHV::FieldSlice& fs) { return !fs.field()->is_deparser_zero_candidate();
                });
        if (has_deparser_zero_fields == has_non_deparser_zero_fields) {
            LOG1(sc);
            ::error("contains a mixture of deparser zero and non deparser zero fields");
        }
    }
    return Inspector::init_apply(root);
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
