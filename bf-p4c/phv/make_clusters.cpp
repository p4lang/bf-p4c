#include "bf-p4c/phv/make_clusters.h"
#include <boost/range/adaptors.hpp>
#include <sstream>
#include "bf-p4c/bf-p4c-options.h"
#include "bf-p4c/common/utils.h"
#include "bf-p4c/ir/bitrange.h"
#include "bf-p4c/phv/phv_fields.h"
#include "bf-p4c/phv/utils/utils.h"
#include "lib/algorithm.h"
#include "lib/log.h"
#include "lib/ordered_set.h"
#include "lib/stringref.h"

Visitor::profile_t Clustering::ClearClusteringStructs::init_apply(const IR::Node* root) {
    auto rv = Inspector::init_apply(root);
    self.aligned_clusters_i.clear();
    self.rotational_clusters_i.clear();
    self.super_clusters_i.clear();
    self.fields_to_slices_i.clear();
    self.complex_validity_bits_i.clear();
    self.inconsistent_extract_no_packs_i.clear();
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
        if (slice.range().overlaps(range)) rv.push_back(slice);
    return rv;
}

bool Clustering::MakeSlices::updateSlices(const PHV::Field* field, le_bitrange range) {
    BUG_CHECK(self.fields_to_slices_i.find(field) != self.fields_to_slices_i.end(),
              "Field not in fields_to_slices_i: %1%", cstring::to_cstring(field));
    bool changed = false;
    auto& slices = self.fields_to_slices_i.at(field);
    // Find the slice that contains the low bit of this new range, and split it
    // if necessary.  Repeat for the high bit.
    for (auto idx : {range.lo, range.hi + 1}) {
        for (auto slice_it = slices.begin(); slice_it != slices.end(); ++slice_it) {
            // If a slice already exists at the an idx of this range, no additional
            // slicing is necessary.
            if (slice_it->range().lo == idx) {
                break;
            }

            // Otherwise, if the lo idx is in another slice, split that slice.
            if (slice_it->range().contains(idx)) {
                changed = true;
                auto range_lo = slice_it->range().resizedToBits(idx - slice_it->range().lo);
                auto range_hi = slice_it->range()
                                    .resizedToBits(slice_it->range().size() - range_lo.size())
                                    .shiftedByBits(idx - slice_it->range().lo);
                LOG5("Clustering::MakeSlices: breaking " << *slice_it << " into " << range_lo
                                                         << " / " << range_hi);
                slice_it = slices.erase(slice_it);
                slice_it = slices.emplace(slice_it, PHV::FieldSlice(field, range_lo));
                slice_it++;
                slice_it = slices.emplace(slice_it, PHV::FieldSlice(field, range_hi));
                break;
            }
        }
    }
    return changed;
}

Visitor::profile_t Clustering::MakeSlices::init_apply(const IR::Node* root) {
    auto rv = Inspector::init_apply(root);
    equivalences_i.clear();
    // Wrap each field in a slice.
    for (auto& f : phv_i) {
        if (pa_sizes_i.has_no_pack_slice(&f)) {
            auto no_pack_slices = pa_sizes_i.get_no_pack_slices(&f);
            for (auto& slice : no_pack_slices) {
                self.fields_to_slices_i[&f].push_back(slice);
                LOG5("Clustering::MakeSlices: breaking " << f.name << " into " << slice.range()
                                                         << " due to pa_container_size");
            }
        } else {
            self.fields_to_slices_i[&f].push_back(PHV::FieldSlice(&f, StartLen(0, f.size)));
        }
    }
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
        auto& slice1 = field_info.first;
        auto& info = field_info.second;
        for (auto& slice2 : info.xor_with) {
            ordered_set<PHV::FieldSlice> equivalence;
            equivalence.insert(slice1);
            equivalence.insert(slice2);
            LOG5("\tAdding equivalence for gateway slices: " << slice1 << " and " << slice2);
            equivalences_i.emplace_back(equivalence);
        }
    }
    return true;
}

bool Clustering::MakeSlices::preorder(const IR::Expression* e) {
    le_bitrange range;
    PHV::Field* field = phv_i.field(e, &range);

    if (!field) return true;

    updateSlices(field, range);
    return true;
}

void Clustering::MakeSlices::postorder(const IR::MAU::Instruction* inst) {
    LOG5("Clustering::MakeSlices: visiting instruction " << inst);
    // Find relative combined slice positions.
    ordered_set<PHV::FieldSlice> equivalence;
    for (auto* op : inst->operands) {
        le_bitrange range;
        PHV::Field* f = phv_i.field(op, &range);
        if (!f) continue;
        equivalence.insert(PHV::FieldSlice(f, range));
    }
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
                        changed |= updateSlices(s1.field(), new_slice);
                    }
                }
            }
        }
    } while (changed);

    if (LOGGING(5)) {
        LOG5("Created fine-grained slices:");
        for (auto& kv : self.fields_to_slices_i) {
            std::stringstream ss;
            for (auto& slice : kv.second)
                ss << "[" << slice.range().lo << ".." << slice.range().hi << "] ";
            LOG5("    " << kv.first << ": " << ss.str());
        }
    }
}

Visitor::profile_t Clustering::MakeAlignedClusters::init_apply(const IR::Node* root) {
    auto rv = Inspector::init_apply(root);
    union_find_i.clear();
    // Initialize union_find_i with pointers to all field slices.
    for (auto& by_field : self.fields_to_slices_i) {
        for (auto& slice : by_field.second) {
            LOG5("Creating AlignedCluster singleton containing field slice " << slice);
            union_find_i.insert(slice);
        }
    }
    return rv;
}

// After InstructionSelection, only primitive operations should remain in
// actions. (Except SALU operands, which may be wrapped in unary operations,
// but we don't care about those here.)
bool Clustering::MakeAlignedClusters::preorder(const IR::MAU::Instruction* inst) {
    LOG5("Clustering::MakeAlignedClusters: visiting instruction " << inst);
    if (findContext<IR::MAU::SaluAction>()) {
        LOG5("    ...skipping SALU instruction " << inst);
        return false;
    }

    if (inst->operands.size() == 0) {
        return false;
    }

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
        bool needs_alignment =
            src && dst && src->size == dst_range.size() && dst->size != dst_range.size();
        if (!needs_alignment) {
            LOG5("    ...skipping 'set', because it doesn't induce alignment constraints");
            return false;
        }
    }

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
            BUG_CHECK(dst_slices.size(), "No slices for field %1% in range %2%",
                      cstring::to_cstring(f), cstring::to_cstring(range));
        }
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
            ++these_slices_it;
        }
    }

    return false;
}

bool Clustering::MakeAlignedClusters::preorder(const IR::MAU::Table* tbl) {
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
                ++b_it;
            }
        }
    }
    return true;
}

void Clustering::MakeAlignedClusters::end_apply() {
    // Create AlignedClusters from sets.
    for (auto* cluster_set : union_find_i) {
        // Create AlignedClusters, distinguishing between PHV/TPHV requirements.
        // XXX(cole): Need to account for all kinds of PHV for JBay.
        bool tphv_candidate = std::all_of(
            cluster_set->begin(), cluster_set->end(),
            [&](const PHV::FieldSlice& slice) { return slice.is_tphv_candidate(uses_i); });
        PHV::Kind kind = tphv_candidate ? PHV::Kind::tagalong : PHV::Kind::normal;
        self.aligned_clusters_i.emplace_back(new PHV::AlignedCluster(kind, *cluster_set));
    }
}

Visitor::profile_t Clustering::MakeRotationalClusters::init_apply(const IR::Node* root) {
    auto rv = Inspector::init_apply(root);
    union_find_i.clear();
    slices_to_clusters_i.clear();
    // Initialize union_find_i with pointers to the aligned clusters formed in
    // MakeAlignedClusters.  Ditto for slices_to_clusters_i.
    for (auto* cluster : self.aligned_clusters_i) {
        union_find_i.insert(cluster);
        LOG5("MakeRotationalClusters: Adding singleton aligned cluster " << cluster);
        for (auto& slice : *cluster) slices_to_clusters_i[slice] = cluster;
    }
    return rv;
}

bool Clustering::MakeRotationalClusters::preorder(const IR::MAU::Instruction* inst) {
    if (inst->name != "set") return false;

    LOG5("MakeRotationalClusters: Visiting " << inst);
    BUG_CHECK(inst->operands.size() == 2,
              "Primitive instruction %1% expected to have 2 operands, "
              "but it has %2%",
              cstring::to_cstring(inst), inst->operands.size());

    // The destination must be a PHV-backed field.
    le_bitrange dst_range;
    PHV::Field* dst_f = phv_i.field(inst->operands[0], &dst_range);
    BUG_CHECK(dst_f, "No PHV field for dst of instruction %1%", cstring::to_cstring(inst));

    // The source may be a non-PHV backed value, however.
    le_bitrange src_range;
    PHV::Field* src_f = phv_i.field(inst->operands[1], &src_range);
    if (!src_f) return false;
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
                  cstring::to_cstring(dst), cstring::to_cstring(src), cstring::to_cstring(inst));
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
        ++src_slices_it;
    }

    return false;
}

void Clustering::MakeRotationalClusters::end_apply() {
    for (auto* cluster_set : union_find_i)
        self.rotational_clusters_i.emplace_back(new PHV::RotationalCluster(*cluster_set));
}

bool Clustering::CollectInconsistentFlexibleFieldExtract::preorder(
    const IR::BFN::ParserState* state) {
    ExtractVec extracts;
    for (const auto* primitive : state->statements) {
        const auto* extract = primitive->to<IR::BFN::Extract>();
        if (!extract) {
            continue;
        }
        auto* buf = extract->source->to<IR::BFN::PacketRVal>();
        if (!buf) {
            continue;
        }
        le_bitrange f_bits;
        auto* field = phv_i.field(extract->dest->field, &f_bits);
        extracts.insert({buf->range, field});
    }
    if (extracts.size() > 0) {
        LOG3("extract of state " << state->name);
        for (const auto& e : extracts) {
            LOG3(e.first << ": " << e.second->name);
        }
        extracts_i.push_back(extracts);
    }
    return true;
}

void Clustering::CollectInconsistentFlexibleFieldExtract::save_header_layout(
    const IR::HeaderRef* hr) {
    const PhvInfo::StructInfo& struct_info = phv_i.struct_info(hr);
    if (struct_info.metadata || struct_info.size == 0) {
        return;
    }

    if (headers_i.count(struct_info.first_field_id)) return;

    std::vector<const PHV::Field*> fields;
    for (int fid : struct_info.field_ids()) {
        const PHV::Field* field = phv_i.field(fid);
        BUG_CHECK(field != nullptr, "No PHV info for field in header reference %1%",
                  cstring::to_cstring(hr));
        fields.push_back(field);
    }

    headers_i[struct_info.first_field_id] = fields;
    return;
}

bool Clustering::CollectInconsistentFlexibleFieldExtract::preorder(
    const IR::ConcreteHeaderRef* hr) {
    save_header_layout(hr);
    return true;
}

bool Clustering::CollectInconsistentFlexibleFieldExtract::preorder(
    const IR::HeaderStackItemRef* hr) {
    save_header_layout(hr);
    return true;
}

void Clustering::CollectInconsistentFlexibleFieldExtract::end_apply() {
    ordered_map<const PHV::Field*, ordered_map<const PHV::Field*, int>> relative_distances;
    for (const auto& h : headers_i) {
        const auto& fields = h.second;
        for (int i = 0; i < int(fields.size()); i++) {
            int offset = fields[i]->size;
            for (int j = i + 1; j < int(fields.size()); j++) {
                relative_distances[fields[i]][fields[j]] = offset;
                relative_distances[fields[j]][fields[i]] = -offset;
                offset += fields[j]->size;
                if (offset > 32) {
                    break;
                }
            }
        }
    }
    if (LOGGING(3)) {
        LOG3("print relative order in header");
        for (const auto& kv : relative_distances) {
            for (const auto& dis : kv.second) {
                LOG3(kv.first->name << " is " << dis.second << " bits before " << dis.first->name);
            }
        }
    }
    for (const auto& state : extracts_i) {
        for (auto i = state.begin(); i != state.end(); i++) {
            const nw_bitrange i_range = i->first;
            const PHV::Field* i_field = i->second;
            for (auto j = std::next(i); j != state.end(); j++) {
                const nw_bitrange j_range = j->first;
                const PHV::Field* j_field = j->second;
                int extract_dist = j_range.lo - i_range.lo;
                if (extract_dist >= 32) {
                    break;
                }
                if (relative_distances.count(i_field) &&
                    relative_distances.at(i_field).count(j_field)) {
                    if (relative_distances.at(i_field).at(j_field) != extract_dist) {
                        self.inconsistent_extract_no_packs_i[i_field].insert(j_field);
                        self.inconsistent_extract_no_packs_i[j_field].insert(i_field);
                        LOG1("InconsistentFlexibleFieldExtract no_pack because "
                             << i_field->name << " and " << j_field->name
                             << " are extracted with distance of " << extract_dist
                             << " bits but they are "
                             << relative_distances.at(i_field).count(j_field)
                             << " bits away in the header");
                    }
                }
            }
        }
    }
}

// add valid bridged_extracted_together_i field slices to a slice list.
void Clustering::CollectPlaceTogetherConstraints::pack_bridged_extracted_together() {
    for (auto* sl : bridged_extracted_together_i) {
        LOG3("Adding a bridged extracted slice lists " << sl);
        place_together_i[Reason::BridgedTogether].push_back(sl);
    }
}

void Clustering::CollectPlaceTogetherConstraints::pack_constrained_metadata() {
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
        bool has_constraints =
            kv.first->alignment || (kv.first->no_split() && kv.second.size() > 1) ||
            (kv.first->is_solitary() && kv.second.size() > 1) || kv.first->is_checksummed() ||
            kv.first->is_marshaled()
            // We must create slice lists for all metadata fields that are
            // involved in wide arithmetic to ensure that the slices of those
            // fields can bbe placed adjacently.
            || kv.first->used_in_wide_arith() || is_exact_containers ||
            kv.first->written_in_force_immediate_table() || actions_i.hasSpecialityReads(kv.first);

        // XXX(cole): Bridged metadata is treated as a header, except in the
        // egress pipeline, where it's treated as metadata.  We need to take
        // care here not to add those fields to slice lists here, because they
        // will already have been added when traversing headers.
        if (is_metadata && has_constraints && !kv.first->bridged) {
            LOG5("Creating slice list for field " << kv.first);
            auto* list = new std::list<PHV::FieldSlice>();
            for (auto& slice : kv.second) list->push_back(slice);
            place_together_i[Reason::ConstrainedMeta].push_back(list);
        }
    }
}

// add pov lists to slice_lists_i.
void Clustering::CollectPlaceTogetherConstraints::pack_pov_bits() {
    ordered_set<PHV::FieldSlice> used;
    for (const auto& sl : slice_lists_i) {
        for (const auto& fs : *sl) {
            used.insert(fs);
        }
    }
    ordered_set<PHV::Field*> pov_bits;
    for (auto& f : phv_i) {
        // Don't bother adding unreferenced fields.
        if (!self.uses_i.is_referenced(&f)) continue;

        // Skip everything but POV valid bits.
        if (!f.pov) continue;

        // Skip valid bits for header stacks, which are allocated with
        // $stkvalid.
        if (f.size > 1) continue;

        // pov bits may be packed already, e.g. if used in digest field list.
        if (used.count(PHV::FieldSlice(&f))) continue;

        // Skip valid bits involved in complex instructions, because they have
        // complicated packing constraints.
        if (self.complex_validity_bits_i.contains(&f)) {
            LOG5("Ignoring field " << f.name << " because it is a complex validity bit.");
            continue;
        }

        pov_bits.insert(&f);
    }

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
            for (auto* f : kv.second) ss << f->name << " ";
            LOG3("\t  " << ss.str());
        }
    }

    auto* ingress_list = new PHV::SuperCluster::SliceList();
    auto* egress_list = new PHV::SuperCluster::SliceList();
    int ingress_list_bits = 0;
    int egress_list_bits = 0;
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

        if (f->is_solitary()) {
            continue;
        }

        // Check if any no-pack constraints have been inferred on the candidate field f, the fields
        // the candidate field must be packed with, and any other field already in the slice list.
        bool any_pack_conflicts = false;
        for (auto& slice1 : *current_list) {
            for (auto& slice2 : toBeAddedFields) {
                if (slice1 == slice2) continue;
                if (conflicts_i.hasPackConflict(slice1.field(), slice2.field()))
                    any_pack_conflicts = true;
            }
        }
        if (any_pack_conflicts) {
            LOG5("    Ignoring POV bit " << f->name << " because of a pack conflict");
            continue;
        }

        for (auto& slice : toBeAddedFields) {
            current_list->push_back(slice);
            current_list_bits += f->size;
            if (current_list_bits >= 32) {
                LOG5("Creating new POV slice list: " << current_list);
                slice_lists_i.insert(current_list);
                current_list = new PHV::SuperCluster::SliceList();
                current_list_bits = 0;
            }
        }
    }

    for (auto* sl : {ingress_list, egress_list}) {
        if (sl->size() != 0) {
            LOG4("Creating new POV slice list: " << sl);
            slice_lists_i.insert(sl);
        }
    }
}

// Preorder on egress parser states and pack adjacent fields together if they
// are are_bridged_extracted_together.
// The reason we do this is:
// 1. phv.are_bridged_extracted_together() allows two fields to be packed into
//    one container, even if they are extracted.
// 2. however, are_bridged_extracted_together does not take the relative position
//    of two fields into account. So a field may be allocated to the wrong bits
//    that makes parser extraction impossible.
// So we pack them into a slice list to force this constraint.
// See P4C-2754 for more details.
bool Clustering::CollectPlaceTogetherConstraints::preorder(const IR::BFN::ParserState* state) {
    if (state->gress == INGRESS) {
        return false;
    }

    // sort fields by extract source.
    std::map<nw_bitrange, const PHV::Field*> sorted;
    for (const auto* prim : state->statements) {
        if (const auto* extract = prim->to<IR::BFN::Extract>()) {
            auto* bufferSource = extract->source->to<IR::BFN::InputBufferRVal>();
            if (!bufferSource) continue;

            auto lval = extract->dest->to<IR::BFN::FieldLVal>();
            if (!lval) continue;

            const auto* field = phv_i.field(lval->field);
            if (!field) {
                continue;
            }
            sorted.insert({bufferSource->range, field});
        }
    }

    boost::optional<std::pair<nw_bitrange, const PHV::Field*>> last = boost::none;
    PHV::SuperCluster::SliceList* accumulator = new PHV::SuperCluster::SliceList();
    auto start_new_slicelist = [&]() {
        if (accumulator->size() > 1) {
            const int sz = PHV::SuperCluster::slice_list_total_bits(*accumulator);
            const bool has_ec = PHV::SuperCluster::slice_list_has_exact_containers(*accumulator);
            if (sz % 8 != 0 && has_ec) {
                // XXX(yumin): alternatively, we can add some dummy_padding fields.
                // but conservatively, we do not do it here.
                LOG3(
                    "CANNOT build bridged extracted together "
                    "slice list because of exact container: "
                    << *accumulator);
            } else {
                bridged_extracted_together_i.insert(accumulator);
            }
        }
        last = boost::none;
        accumulator = new PHV::SuperCluster::SliceList();
    };

    for (const auto& kv : boost::adaptors::reverse(sorted)) {
        const nw_bitrange range = kv.first;
        const auto* field = kv.second;
        if (last && phv_i.are_bridged_extracted_together((*last).second, field) &&
            (*last).first.lo == range.hi + 1) {
            LOG3("bridged extracted together: " << (*last).second << " , " << field);
        } else {
            start_new_slicelist();
        }
        BUG_CHECK(self.fields_to_slices_i.count(field), "Field not in fields_to_slices_i: %1%",
                  cstring::to_cstring(field));
        for (const auto& fs : self.fields_to_slices_i.at(field)) {
            accumulator->push_back(fs);
        }
        last = std::make_pair(range, field);
    }
    return true;
}

void Clustering::CollectPlaceTogetherConstraints::visit_header_ref(const IR::HeaderRef* hr) {
    LOG5("Visiting HeaderRef " << hr);
    const PhvInfo::StructInfo& struct_info = phv_i.struct_info(hr);

    // Only analyze headers, not metadata structs.
    if (struct_info.metadata || struct_info.size == 0) {
        LOG5("Ignoring metadata or zero struct info: " << hr);
        return;
    }

    if (headers_i.find(struct_info.first_field_id) != headers_i.end()) return;
    headers_i.insert(struct_info.first_field_id);

    auto* fields_in_header = new std::list<PHV::FieldSlice>();
    for (int fid : boost::adaptors::reverse(struct_info.field_ids())) {
        PHV::Field* field = phv_i.field(fid);
        BUG_CHECK(field != nullptr, "No PHV info for field in header reference %1%",
                  cstring::to_cstring(hr));
        BUG_CHECK(self.fields_to_slices_i.find(field) != self.fields_to_slices_i.end(),
                  "Found field in header but not PHV: %1%", cstring::to_cstring(field));
        for (auto& slice : self.fields_to_slices_i.at(field)) {
            fields_in_header->push_back(slice);
        }
    }
    place_together_i[Reason::Header].push_back(fields_in_header);
    return;
}

bool Clustering::CollectPlaceTogetherConstraints::preorder(const IR::ConcreteHeaderRef* hr) {
    visit_header_ref(hr);
    return false;
}

bool Clustering::CollectPlaceTogetherConstraints::preorder(const IR::HeaderStackItemRef* hr) {
    visit_header_ref(hr);
    return false;
}

// Create slice list from digest field list, this will allow compiler inserted
// padding field to be allocated to the same container as the field that is
// being padded.
void Clustering::CollectPlaceTogetherConstraints::visit_digest_fieldlist(
    const IR::BFN::DigestFieldList* fl, int skip, Reason reason) {
    if (fl->sources.size() == 0) return;
    LOG5("  creating slice list from field list: " << fl);

    auto* fieldslice_list = new std::list<PHV::FieldSlice>();
    for (auto f = fl->sources.rbegin(); f != fl->sources.rend() - skip; f++) {
        const PHV::Field* field = phv_i.field((*f)->field);
        for (const auto& slice : self.fields_to_slices_i.at(field)) {
            fieldslice_list->push_back(slice);
        }
    }
    place_together_i[reason].push_back(fieldslice_list);
    return;
}

bool Clustering::CollectPlaceTogetherConstraints::preorder(const IR::BFN::Digest* digest) {
    if (digest->name == "learning") {
        for (auto fieldList : digest->fieldLists) {
            visit_digest_fieldlist(fieldList, 0, Reason::Learning);
        }
    } else if (digest->name == "pktgen") {
        for (auto fieldList : digest->fieldLists) {
            visit_digest_fieldlist(fieldList, 0, Reason::Pktgen);
        }
    } else if (digest->name == "resubmit") {
        for (auto fieldList : digest->fieldLists) {
            visit_digest_fieldlist(fieldList, 1, Reason::Resubmit);
        }
    } else if (digest->name == "mirror") {
        // skip the first element in digest sources which is the session id
        for (auto fieldList : digest->fieldLists) {
            visit_digest_fieldlist(fieldList, 1, Reason::Mirror);
        }
    }
    return false;
}

// SliceListAccumulator is a helper cluster that manages the current
// state of accumulated slice list.
struct SliceListAccumulator {
    std::set<PHV::FieldSlice>* slices_used;
    PHV::SuperCluster::SliceList* accumulator = new PHV::SuperCluster::SliceList();
    int accumulator_bits = 0;
    cstring log_prefix;

    explicit SliceListAccumulator(std::set<PHV::FieldSlice>* slices_used, cstring log_prefix)
        : slices_used(slices_used), log_prefix(log_prefix) {}

    // append a new fieldslice to the end.
    void append(const PHV::FieldSlice& fs) {
        accumulator_bits += fs.size();
        accumulator->push_back(fs);
    }

    // start_new returns the accumulated slice list and start over a new one.
    PHV::SuperCluster::SliceList* start_new() {
        PHV::SuperCluster::SliceList* rst = nullptr;
        if (accumulator->size() > 0) {
            rst = accumulator;
            LOG3("accumulator(" << log_prefix << ") make slicelist: " << accumulator);
            if (slices_used != nullptr) {
                for (const auto& fs : *accumulator) {
                    slices_used->insert(fs);
                }
            }
        }
        accumulator_bits = 0;
        accumulator = new PHV::SuperCluster::SliceList();
        return rst;
    }
};

// BreakSliceListCtx describes a context during list breaking.
struct BreakSliceListCtx {
    using Itr = PHV::SuperCluster::SliceList::const_iterator;
    int offset;
    Itr curr;
    boost::optional<Itr> prev;
    boost::optional<Itr> next;
    const SliceListAccumulator* accumulator;
};

// break_slicelist_by break slicelists by @p condition.
std::vector<PHV::SuperCluster::SliceList*> break_slicelist_by(
    const std::vector<PHV::SuperCluster::SliceList*>& candidates, cstring log_prefix,
    std::function<bool(const BreakSliceListCtx& ctx)> cond) {
    std::vector<PHV::SuperCluster::SliceList*> rst;
    for (const auto* sl : candidates) {
        SliceListAccumulator accumulator(nullptr, log_prefix);
        int offset = sl->begin()->field()->exact_containers()
                         ? 0
                         : (sl->begin()->alignment() ? (*sl->begin()->alignment()).align : 0);
        for (auto itr = sl->begin(); itr != sl->end(); itr++) {
            accumulator.append(*itr);
            offset += itr->size();
            auto ctx = BreakSliceListCtx();
            ctx.offset = offset;
            ctx.curr = itr;
            ctx.prev = (itr == sl->begin() ? boost::none : boost::make_optional(std::prev(itr)));
            ctx.next =
                (std::next(itr) == sl->end() ? boost::none : boost::make_optional(std::next(itr)));
            ctx.accumulator = &accumulator;
            if (cond(ctx)) {
                auto* last = accumulator.start_new();
                if (last != nullptr) {
                    rst.push_back(last);
                }
            }
        }
        auto* last = accumulator.start_new();
        if (last != nullptr) {
            rst.push_back(last);
        }
    }
    return rst;
}

// pre-break: [][solitary]
// post-break: [solitary][padding*][other]
bool break_cond_solitary(const BreakSliceListCtx& ctx) {
    if (ctx.next && ctx.next.get()->field() != ctx.curr->field()) {
        auto next = ctx.next.get();
        if (next->field()->is_solitary()) {
            return true;
        }
        // post-break without padding
        if (ctx.curr->field()->is_solitary() && !next->field()->padding) {
            return true;
        }
    }
    // post-break with padding
    if (ctx.prev && ctx.prev.get()->field() != ctx.curr->field()) {
        // if current field is the padding of the prev solitary field, break.
        if (ctx.prev.get()->field()->is_solitary() && ctx.curr->size() % 8 != 0 &&
            ctx.offset % 8 == 0) {
            return true;
        }
    }
    return false;
}

// break [fs1<3>^0][fs2<2>^0][fs3<1>^0] into 3 different slices because their
// aligment constraints are conflicting.
bool break_cond_alignment_conflict(const BreakSliceListCtx& ctx) {
    if (ctx.next) {
        auto next = ctx.next.get();
        const auto& next_alignment = next->alignment();
        if (next_alignment && int((*next_alignment).align) != ctx.offset % 8) {
            LOG5("break between " << *ctx.curr << " and " << *next << "because aligment "
                                  << ctx.offset % 8 << "!=" << int((*next_alignment).align));
            return true;
        }
    }
    return false;
}

// break if there current field and the next field have different
// deparsed_zero constraints.
bool break_cond_deparsed_zero(const BreakSliceListCtx& ctx) {
    if (ctx.next) {
        auto curr = ctx.curr;
        auto next = *ctx.next;
        return curr->field()->is_deparser_zero_candidate() !=
               next->field()->is_deparser_zero_candidate();
    }
    return false;
}

// break [digest][padding*][normal][digest][padding*] into
// [digest][padding*], [normal], [digest][padding*].
// digest fields are special, they should be split out from the original slice list,
// along with the padding fields after them.
bool break_cond_digest_field(const BreakSliceListCtx& ctx,
                             const ordered_set<PHV::FieldSlice>& digest_fields) {
    // if next or current field is digest field and it's byte-aligned, break.
    if (ctx.next && ctx.next.get()->field() != ctx.curr->field()) {
        auto next = ctx.next.get();
        if (ctx.offset % 8 == 0) {
            if (digest_fields.count(*next) || digest_fields.count(*ctx.curr)) {
                LOG5("break at " << *ctx.curr << " because it byte boundary of a digest field");
                return true;
            }
        }
    }

    // if prev field is digest field, and curr is padding or
    // the current field can be a padding to make the list byte-sized.
    if (ctx.prev && ctx.prev.get()->field() != ctx.curr->field()) {
        auto prev = ctx.prev.get();
        if (digest_fields.count(*prev) && ctx.curr->size() % 8 != 0 && ctx.offset % 8 == 0) {
            LOG5("break at " << *ctx.curr << " because reaches digest field padding end");
            return true;
        }
    }

    return false;
}

void Clustering::CollectPlaceTogetherConstraints::solve_place_together_constraints() {
    LOG1("solve place-together constraints");
    std::set<PHV::FieldSlice> slices_used;
    SliceListAccumulator accumulator(&slices_used, "priority-solving");

    /// all fields slices that has been assigned to a slice list.
    std::vector<PHV::SuperCluster::SliceList*> candidates;
    for (auto& kv : place_together_i) {
        auto& reason = kv.first;
        auto& slicelists = kv.second;
        LOG3("building slice list, priority: " << int(reason));
        for (auto* sl : slicelists) {
            LOG3("solve place-together for " << int(reason) << ": " << sl);
            // break list at duplicated fields.
            auto itr = sl->begin();
            while (itr != sl->end()) {
                auto& slice = *itr;
                if (slices_used.count(slice)) {
                    auto last = accumulator.start_new();
                    if (last != nullptr) candidates.push_back(last);
                    auto next = std::next(itr);
                    while (next != sl->end() && next->field()->padding) {
                        next = std::next(next);
                    }
                    itr = next;  // itr stops at first non-padding slice.
                } else {
                    accumulator.append(slice);
                    itr++;
                }
            }
            auto last = accumulator.start_new();
            if (last != nullptr) candidates.push_back(last);
        }
    }

    // split by digest and non-digest field.
    LOG1("break slice list of digest fields");
    ordered_set<PHV::FieldSlice> digest_fields;
    for (const auto& reason :
         {Reason::Resubmit, Reason::Mirror, Reason::Learning, Reason::Pktgen}) {
        if (!place_together_i.count(reason)) {
            continue;
        }
        auto& lists = place_together_i.at(reason);
        for (const auto& sl : lists) {
            for (const auto& fs : *sl) {
                digest_fields.insert(fs);
            }
        }
    }
    candidates = break_slicelist_by(candidates, "digest-fields",
                                    [&digest_fields](const BreakSliceListCtx& ctx) -> bool {
                                        return break_cond_digest_field(ctx, digest_fields);
                                    });

    /// break at constraints.
    // split by deparsed zero.
    LOG1("break slice list of different deparsed zero constraints");
    candidates = break_slicelist_by(candidates, "deparsed-zero", break_cond_deparsed_zero);

    // break at conflicting aligments.
    LOG1("break slice list of conflicting aligments");
    candidates = break_slicelist_by(candidates, "aligment", break_cond_alignment_conflict);

    // break by solitary.
    LOG1("break slice list of mixed solitary/non-solitary fields");
    candidates = break_slicelist_by(candidates, "solitary", break_cond_solitary);

    // save results.
    for (const auto& sl : candidates) {
        slice_lists_i.insert(sl);
    }
}

void Clustering::CollectPlaceTogetherConstraints::end_apply() {
    // constraint solving
    pack_constrained_metadata();
    pack_bridged_extracted_together();
    solve_place_together_constraints();

    // add some additional pack together constraint.
    pack_pov_bits();
}

Visitor::profile_t Clustering::MakeSuperClusters::init_apply(const IR::Node* root) {
    auto rv = Inspector::init_apply(root);
    return rv;
}

void Clustering::MakeSuperClusters::end_apply() {
    auto slice_lists = place_togethers_i.get_slice_lists();
    LOG1("MakeSuperClusters slicelist input: ");
    for (const auto* sl : slice_lists) {
        LOG1(sl);
    }
    UnionFind<const PHV::RotationalCluster*> cluster_union_find;
    ordered_map<PHV::FieldSlice, PHV::RotationalCluster*> slices_to_clusters;

    for (auto* rotational_cluster : self.rotational_clusters_i) {
        // Insert cluster into UnionFind.
        cluster_union_find.insert(rotational_cluster);

        // Map fields to clusters for quick lookup later.
        for (auto* aligned_cluster : rotational_cluster->clusters()) {
            for (auto& slice : *aligned_cluster) {
                slices_to_clusters[slice] = rotational_cluster;
            }
        }
    }

    // Find sets of rotational clusters that have fields that need to be placed in
    // the same container.
    for (auto* slice_list : slice_lists) {
        if (slice_list->size() <= 1) continue;
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
            cluster_union_find.makeUnion(first_cluster, slices_to_clusters.at(slice));
        }
    }

    // Build SuperClusters.
    for (auto* cluster_set : cluster_union_find) {
        // Collect slice lists that induced this grouping.
        // XXX(cole): Caching would be much more efficient.
        ordered_set<PHV::SuperCluster::SliceList*> these_lists;
        ordered_set<PHV::FieldSlice> slices_in_these_lists;
        for (auto* rotational_cluster : *cluster_set)
            for (auto* aligned_cluster : rotational_cluster->clusters())
                for (const PHV::FieldSlice& slice : *aligned_cluster)
                    for (auto* slist : slice_lists)
                        if (std::find(slist->begin(), slist->end(), slice) != slist->end())
                            these_lists.insert(slist);

        // Put each exact_containers slice in a rotational cluster but not in a
        // field list into a singelton field list.
        for (auto* slice_list : these_lists)
            for (auto& slice_in_list : *slice_list) slices_in_these_lists.insert(slice_in_list);
        for (auto* rotational_cluster : *cluster_set)
            for (auto* aligned_cluster : rotational_cluster->clusters())
                for (auto& slice : *aligned_cluster)
                    if (slice.field()->exact_containers() &&
                        slices_in_these_lists.find(slice) == slices_in_these_lists.end()) {
                        auto* new_list = new PHV::SuperCluster::SliceList();
                        new_list->push_back(slice);
                        these_lists.insert(new_list);
                        slices_in_these_lists.insert(slice);
                    }

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
            if (!g->okIn(PHV::Kind::tagalong)) LOG1(g);

        LOG1("TPHV CANDIDATES:");
        for (auto& g : self.super_clusters_i)
            if (g->okIn(PHV::Kind::tagalong)) LOG1(g);
    }
}

void Clustering::MakeSuperClusters::addPaddingForMarshaledFields(
    ordered_set<const PHV::RotationalCluster*>& cluster_set,
    ordered_set<PHV::SuperCluster::SliceList*>& these_lists) {
    // Add paddings for marshaled fields slice list, to the size of the largest
    // slice list, up to the largest container size.
    int max_slice_list_size = 8;
    for (const auto* slice_list : these_lists) {
        int sum_bits = PHV::SuperCluster::slice_list_total_bits(*slice_list);
        max_slice_list_size = std::max(max_slice_list_size, sum_bits);
    }
    // Round up to the closest 8-bit.
    max_slice_list_size = ROUNDUP(max_slice_list_size, 8) * 8;

    for (auto* slice_list : these_lists) {
        if (std::any_of(slice_list->begin(), slice_list->end(),
                        [](const PHV::FieldSlice& fs) { return fs.field()->is_marshaled(); })) {
            int sum_bits = 0;
            for (const auto& fs : *slice_list) {
                sum_bits += fs.size();
            }
            BUG_CHECK(max_slice_list_size >= sum_bits, "wrong max slice list size.");

            bool has_bridged =
                std::any_of(slice_list->begin(), slice_list->end(),
                            [](const PHV::FieldSlice& fs) { return fs.field()->bridged; });
            // If a slice has bridged field, then it's padding is handled by bridged metadata
            // packing now. Adding extract padding here will make parse_bridged state wrong
            // because we do not adjust bridged metadata state.
            // TODO(yumin): in a long term, we need a way to deal with those marshaled fields,
            // bridged/mirrored/resubmited uniformly.
            if (has_bridged) {
                continue;
            }
            // If this field does not need padding, skip it.
            if (max_slice_list_size == sum_bits) {
                continue;
            }

            auto padding_size = ROUNDUP(sum_bits, 8) * 8 - sum_bits;
            if (padding_size == 0) continue;
            auto* padding = phv_i.create_dummy_padding(padding_size, slice_list->front().gress());
            padding->set_exact_containers(true);
            auto padding_fs = PHV::FieldSlice(padding);
            slice_list->push_back(padding_fs);
            auto* aligned_cluster_padding = new PHV::AlignedCluster(
                PHV::Kind::normal, std::vector<PHV::FieldSlice>{padding_fs});
            auto* rot_cluster_padding = new PHV::RotationalCluster({aligned_cluster_padding});
            self.aligned_clusters_i.push_back(aligned_cluster_padding);
            self.rotational_clusters_i.push_back(rot_cluster_padding);
            cluster_set.insert(rot_cluster_padding);
            LOG4("Added " << padding_fs << " for " << slice_list);
        }
    }
}

void Clustering::ValidateClusters::validate_basics(const std::list<PHV::SuperCluster*> clusters) {
    ordered_set<PHV::FieldSlice> showed;
    for (auto* sc : clusters) {
        for (const auto* sl : sc->slice_lists()) {
            if (sl->empty()) {
                BUG("SuperCluster with empty slice list: %1%", sc);
            }
            for (const auto& fs : *sl) {
                if (showed.count(fs)) {
                    BUG("SuperCluster has duplicated FieldSlice: %1%, FieldSlice: %2%", sc, fs);
                } else {
                    showed.insert(fs);
                }
            }
        }
    }
}

void Clustering::ValidateClusters::validate_deparsed_zero_clusters(
    const std::list<PHV::SuperCluster*> clusters) {
    // Flag an error if the supercluster has a mix of deparsed zero fields and non deparsed zero
    // fields.
    for (auto* sc : clusters) {
        bool has_deparser_zero_fields = sc->any_of_fieldslices(
            [&](const PHV::FieldSlice& fs) { return fs.field()->is_deparser_zero_candidate(); });
        bool has_non_deparser_zero_fields = sc->any_of_fieldslices(
            [&](const PHV::FieldSlice& fs) { return !fs.field()->is_deparser_zero_candidate(); });
        if (has_deparser_zero_fields == has_non_deparser_zero_fields) {
            LOG1(sc);
            BUG("contains a mixture of deparser zero and non deparser zero fields");
        }
    }
}

void Clustering::ValidateClusters::validate_exact_container_lists(
    const std::list<PHV::SuperCluster*> clusters, const PhvUse& uses) {
    for (auto* sc : clusters) {
        for (const auto* sl : sc->slice_lists()) {
            bool has_padding = false;
            // bool is_singleton = sl->size() == 1;
            bool is_used = false;
            bool has_exact_containers = false;
            bool has_non_exact_containers = false;
            for (const auto& fs : *sl) {
                if (uses.is_referenced(fs.field())) {
                    is_used = true;
                }
                has_padding |= fs.field()->is_padding();
                has_exact_containers |= fs.field()->exact_containers();
                has_non_exact_containers |= !fs.field()->exact_containers();
            }
            // XXX(yumin): it may be fine to mix exact or non_exact containers fields,
            // e.g. checksum destination on egress can be an example of this.
            // However, We need to investigate further on how it will impact phv allocation.
            if (has_non_exact_containers && has_exact_containers) {
                LOG1("mixed with exact_containers and non_exact_containers slices: " << sl);
            }
            // XXX(yumin): it's okay for padding fields to be not byte-sized.
            if (has_exact_containers && is_used && !has_padding) {
                int sz = PHV::SuperCluster::slice_list_total_bits(*sl);
                if (sz % 8 != 0) {
                    std::stringstream ss;
                    ss << "invalid SuperCluster was formed: " << sc;
                    ss << "because this slice list is not byte-sized: " << sl << " has " << sz
                       << " bits.\n";
                    ss << "This is either a compiler internal bug or you can introduce padding "
                          "fields around them by @padding or @flexible";
                    fatal_error("%1%", ss.str());
                }
            }
        }
    }
}

void Clustering::ValidateClusters::validate_alignments(const std::list<PHV::SuperCluster*> clusters,
                                                       const PhvUse& uses) {
    for (auto* sc : clusters) {
        for (const auto* sl : sc->slice_lists()) {
            bool is_used = false;
            int offset = sl->begin()->field()->exact_containers()
                             ? 0
                             : (sl->begin()->alignment() ? (*sl->begin()->alignment()).align : 0);
            for (const auto& fs : *sl) {
                if (uses.is_referenced(fs.field())) {
                    is_used = true;
                }
                const auto& alignment = fs.alignment();
                if (is_used && alignment && int((*alignment).align) != offset % 8) {
                    std::stringstream ss;
                    ss << "invalid SuperCluster was formed: " << sc;
                    ss << "because there are invalid alignment constraints in " << sl << "\n";
                    ss << fs << " must be allocated to " << int((*alignment).align)
                       << "-th bit in a byte";
                    ss << ", but the slicelist requires it to start at " << offset % 8
                       << "-th bit in a byte";
                    ss << "This is either a compiler internal bug or you can introduce padding "
                          "fields around them by @padding or @flexible";
                    fatal_error("%1%", ss.str());
                }
                offset += fs.size();
            }
        }
    }
}

void Clustering::ValidateClusters::validate_extract_from_flexible(
    const std::list<PHV::SuperCluster*> clusters,
    std::function<bool(const PHV::Field* a, const PHV::Field* b)> no_pack) {
    for (auto* sc : clusters) {
        for (const auto* sl : sc->slice_lists()) {
            int offset = 0;
            for (auto itr = sl->begin(); itr != sl->end(); itr++) {
                offset += itr->size();  // offset of next bit
                if (offset % 8 == 0) {
                    continue;
                }
                int next_offset = offset;
                for (auto next = std::next(itr); next != sl->end();
                     next_offset += next->size(), next++) {
                    LOG1("check " << *next << " vs " << *itr);
                    if (next_offset / 8 > offset / 8) {
                        break;
                    }
                    if (no_pack(itr->field(), next->field())) {
                        BUG("Flexible packing bug found. Two fields in a same byte in header are "
                            "extracted from different bytes in the parser (likely by an assignment "
                            "from @flexible headers): %1% and %2%",
                            itr->field()->name, next->field()->name);
                    }
                }
            }
        }
    }
}

Visitor::profile_t Clustering::ValidateClusters::init_apply(const IR::Node* root) {
    validate_deparsed_zero_clusters(self.cluster_groups());
    validate_exact_container_lists(self.cluster_groups(), self.uses_i);
    validate_alignments(self.cluster_groups(), self.uses_i);
    validate_extract_from_flexible(
        self.cluster_groups(),
        [this](const PHV::Field* a, const PHV::Field* b) { return self.no_pack(a, b); });
    return Inspector::init_apply(root);
}

//////////////////////////////////////////////////////////

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
