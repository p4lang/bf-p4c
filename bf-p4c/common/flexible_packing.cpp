#include <cstring>
#include <algorithm>
#include <sstream>

#include "bf-p4c/common/flexible_packing.h"
#include "bf-p4c/common/ir_utils.h"
#include "bf-p4c/common/utils.h"
#include "bf-p4c/lib/pad_alignment.h"
#include "bf-p4c/phv/cluster_phv_operations.h"
#include "bf-p4c/phv/phv_fields.h"
#include "bf-p4c/phv/pragma/pa_atomic.h"
#include "bf-p4c/phv/pragma/pa_container_size.h"
#include "bf-p4c/phv/pragma/pa_solitary.h"
#include "bf-p4c/phv/pragma/pa_no_pack.h"
#include "bf-p4c/common/table_printer.h"

// included by PackFlexibleHeaders
#include "bf-p4c/common/alias.h"
#include "bf-p4c/common/check_for_unimplemented_features.h"
#include "bf-p4c/common/header_stack.h"
#include "bf-p4c/common/multiple_apply.h"
#include "bf-p4c/mau/empty_controls.h"
#include "bf-p4c/mau/instruction_selection.h"
#include "bf-p4c/mau/push_pop.h"
#include "bf-p4c/mau/selector_update.h"
#include "bf-p4c/mau/stateful_alu.h"
#include "bf-p4c/parde/add_metadata_pov.h"
#include "bf-p4c/parde/stack_push_shims.h"
#include "bf-p4c/phv/create_thread_local_instances.h"
#include "bf-p4c/phv/pragma/pa_no_overlay.h"
#include "bf-p4c/parde/reset_invalidated_checksum_headers.h"

// helper function
bool findFlexibleAnnotation(const IR::Type_StructLike* header) {
    for (auto f : header->fields) {
        auto anno = f->getAnnotation("flexible");
        if (anno != nullptr)
            return true; }
    return false;
}

// XXX(Deep): BRIG-333
// We can do better with these IR::BFN::DeparserParameters in terms of packing. This IR type is only
// used to represent intrinsic metadata in ingress and egress at the moment. As noted in the
// comments in line 698 in phv_fields.cpp, the constraints on bottom_bit for some of these TM
// metadata is not necessary. We can theoretically place certain TM metadata field, such as
// bypass_egress to any bit in a byte. The implication for bridge metadata packing is that
// bypass_egress could be packed with any field anywhere. There are a few other TM metadata with the
// same property: ct_disable, ct_mcast, qid, icos, meter_color, deflect_on_drop, copy_to_cpu_cos.
// BRIG-333 is tracking this issue.
bool GatherDeparserParameters::preorder(const IR::BFN::DeparserParameter* p) {
    BUG_CHECK(p->source, "Parameter %1% missing source", p->name);
    const PHV::Field* f = phv.field(p->source->field);
    BUG_CHECK(f, "Field %1% not found while gathering deparser parameters", p->source->field);
    LOG5("    Deparser parameter identified: " << f);
    params.insert(f);
    return true;
}

// TODO: Remove reliance on phase0 parser state name by visiting Phase0 node in
// IR::BFN::Parser and use phase0->fields to gather Phase0 fields. The fields
// must be converted from an IR::StructField to a PHV::Field.
// TODO: Another chance for optimization is by allowing flexible packing of
// fields. Right now, the fields are packed to Phase0 bit width (Tofino = 64 and
// JBAY = 128) with padding inserted. This does not allow flexibility while
// packing fields into containers. The packing is specified in tna.cpp &
// arch/phase0.cpp - canPackDataIntoPhase0() method. The packing code can be
// removed and we can work with only the fields in Phase0. Packing width can be
// determined by Device::pardeSpec().bitPhase0Width()
bool GatherPhase0Fields::preorder(const IR::BFN::ParserState* p) {
    // Not a phase 0 parser state
    if (p->name != PHASE0_PARSER_STATE_NAME)
        return true;
    // For phase 0 parser state, detect the fields written to.
    for (auto s : p->statements) {
        auto* e = s->to<IR::BFN::Extract>();
        if (!e) continue;
        auto* dest = e->dest->to<IR::BFN::FieldLVal>();
        if (!dest) continue;
        const auto* f = phv.field(dest->field);
        if (!f) continue;
        LOG3("CONSTRAINT must be packed alone A " << f);
        noPackFields.insert(f); }
    return true;
}

// TODO: if a field is used in both bridging and mirror/resubmit/digest, we do
// not pack these fields with other fields. The compiler should be able to do
// better.
bool GatherPhase0Fields::preorder(const IR::BFN::DigestFieldList* d) {
    for (auto source : d->sources) {
        const auto* field = phv.field(source->field);
        if (!field) continue;
        LOG3("CONSTRAINT must be packed alone B " << field);
        noPackFields.insert(field);
    }
    return false;
}

std::string LogRepackedHeaders::strip_prefix(cstring str, std::string pre) {
    std::string s = str + "";
    // Find the first occurence of the prefix
    size_t first = s.find(pre, 0);

    // If it's not at 0, then we haven't found a prefix
    if (first != 0)
        return s;

    // Otherwise, we have a match and can trim it
    return s.substr(pre.length(), std::string::npos);
}

// Collect repacked headers
bool LogRepackedHeaders::preorder(const IR::HeaderOrMetadata* h) {
    // Check if we have visited this header's ingress/egress version before
    cstring hname = h->name;
    std::string h_in = strip_prefix(hname, "ingress::");
    std::string h_out = strip_prefix(hname, "egress::");
    if (hdrs.find(h_in) != hdrs.end() || hdrs.find(h_out) != hdrs.end())
        return false;
    // Otherwise, add the shorter one (the one with the prefix stripped) to our set
    std::string h_strip;
    if (h_in.length() > h_out.length())
        h_strip = h_out;
    else
        h_strip = h_in;
    hdrs.emplace(h_strip);

    // Check if this header may have been repacked by looking for flexible fields
    bool isRepacked = false;
    for (auto f : *h->type->fields.getEnumerator()) {
        if (f->getAnnotation("flexible")) {
            isRepacked = true;
            break;
        }
    }

    // Add it to our vector if it is repacked
    if (isRepacked) {
        std::pair<const IR::HeaderOrMetadata*, std::string> pr(h, h_strip);
        repacked.push_back(pr);
    }

    // Prune this branch because headers won't have headers as children
    return false;
}

// Pretty print all of the headers
void LogRepackedHeaders::end_apply() {
    // Check if we should be logging anything
    if (LOGGING(1))
        // Iterate through the headers and print all of their fields
        for (auto h : repacked)
            LOG1(pretty_print(h.first, h.second));
}

// TODO: Currently outputting backend name for each field. Should be changed to user facing name.
std::string LogRepackedHeaders::getFieldName(std::string hdr, const IR::StructField* f) const {
    auto nm = hdr + "." + f->name;
    auto* fi = phv.field(nm);
    auto name = fi ? fi->name : nm;
    std::string s = name + "";
    return s;
}

std::string LogRepackedHeaders::pretty_print(const IR::HeaderOrMetadata* h, std::string hdr) const {
    // Number of bytes we have used
    unsigned byte_ctr = 0;
    // Number of bits in the current byte we have used
    unsigned bits_ctr = 0;

    std::stringstream out;
    out << "Repacked header " << hdr << ":" << std::endl;

    // Create our table printer
    TablePrinter* tp = new TablePrinter(out, {"Byte #", "Bits", "Field name"},
                                       TablePrinter::Align::CENTER);
    tp->addSep();

    // Run through the fields. We divide each field into 3 sections: (1) the portion that goes into
    // the current byte; (2) the portion that goes into byte(s) in the middle; and (3) the portion
    // that goes into the last byte. As we process each field, we may want to change how previous
    // portions were allocated. For example, if we realize (2) will be a range and (1) was a full
    // byte, then (1) should get merged into (2). Thus, we will capture the printing (to
    // TablePrinter) of each portion as a copy-capture lambda. This allows us to do "lazy
    // evaluation" and effectively modify what is printed after in earlier portions.
    for (auto f : h->type->fields) {
        // PORTION(1): This section will always exist, but it may end up getting included into
        // portion 2
        std::function<void(void)> write_beg = [=]() { return; };
        // PORTION(2): This section may be a range (of full bytes), a single full byte or be empty.
        std::function<void(void)> write_mid = [=]() { return; };
        // PORTION(3): This section is necessary when the field doesn't end up completely filling
        // the last byte of the mid.
        std::function<void(void)> write_end = [=]() { return; };

        // Get the field name. If it's a pad, change to *PAD*
        std::string name = getFieldName(hdr, f);
        if (name.find("__pad_", 0) != std::string::npos)
            name = "*PAD*";

        // Need to calculate how many bytes and what bits this field takes up
        unsigned width = f->type->width_bits();
        // Remaining bits in the current byte
        unsigned rem_bits = 8 - bits_ctr;
        // True if this field overflows the current byte
        bool ofByte = width > rem_bits;

        // PORTION (1): First, we add to the current byte.
        // Last bit is the next open bit
        unsigned last_bit = ofByte ? 8 : bits_ctr + width;
        // If this first byte is full, we'll need to print a separator.
        bool first_full = last_bit == 8;
        // If this byte is completely occupied by this field, it may need to be a range
        bool first_occu = first_full && bits_ctr == 0;
        write_beg = [=]() {
                        tp->addRow({std::to_string(byte_ctr),
                                   "[" + std::to_string(bits_ctr) + " : "
                                   + std::to_string(last_bit - 1) + "]",
                                   name});
                        if (first_full) tp->addSep();
                    };

        // Update bits/byte counter and width after finishing 1st byte
        bits_ctr = last_bit % 8;
        byte_ctr = first_full ? byte_ctr + 1 : byte_ctr;
        width = width - rem_bits;

        // PORTION (2)/(3): Only need to handle this portion if we did overflow
        if (ofByte) {
            // See what byte/bit we'll fill up to. The last bit is the next open bit
            unsigned end_byte = byte_ctr + width/8;
            last_bit = width % 8;

            // PORTION(2): Now, we want to handle any bytes that are completely filled by this
            // field. We want to put multiple bytes that are occupied by the same field into a range
            // instead of explicitly printing out each one
            if (end_byte - byte_ctr >= 1) {
                // If we're in this conditional, we know that we have at least 1 full byte, but
                // that's not enough to print a range, so:
                if (end_byte - byte_ctr >= 2 || first_occu) {
                    // Now, we have at least 2 bytes that are full, so we can print a range.
                    unsigned beg_byte = byte_ctr;
                    // If the first was completely occupied by this field, include it in the range
                    // and don't do anything in write_beg
                    if (first_occu) {
                        beg_byte--;
                        write_beg = [=]() { return; };
                    }
                    // Add the range row
                    write_mid = [=]() {
                                    tp->addRow({std::to_string(beg_byte) + " -- "
                                               + std::to_string(end_byte-1),
                                               "[" + std::to_string(0) + " : "
                                               + std::to_string(7) + "]",
                                               name});
                                    tp->addSep();
                                    return;
                                };
                } else {
                    // Here we know our mid portion is going to be just the single full byte we have
                    write_mid = [=]() {
                                    tp->addRow({std::to_string(byte_ctr),
                                               "[" + std::to_string(0) + " : "
                                               + std::to_string(7) + "]",
                                               name});
                                    tp->addSep();
                                    return;
                                };
                }
            }

            // PORTION(3): We now need to handle the partial byte that might be leftover
            if (last_bit != 0) {
                write_end = [=]() {
                                tp->addRow({std::to_string(end_byte),
                                           "[" + std::to_string(0) + " : "
                                           + std::to_string((last_bit-1)) + "]",
                                           name});
                                return;
                            };
            }

            // Now, we update our counters
            byte_ctr = end_byte;
            bits_ctr = last_bit;
        }
        // Finally, write everything to the table printer
        write_beg();
        write_mid();
        write_end();
    }

    // Print the table to the stream out and return it
    tp->print();
    out << std::endl;
    return out.str();
}

FlexiblePacking::FlexiblePacking(
        PhvInfo& p,
        const PhvUse& u,
        DependencyGraph& dg,
        const BFN_Options &o,
        PackWithConstraintSolver& sol) :
          options(o),
          pa_no_pack(p),
          packConflicts(p, dg, tMutex, table_alloc, aMutex, pa_no_pack),
          actionConstraints(p, u, packConflicts, tableActionsMap, dg),
          packWithConstraintSolver(sol) {
              addPasses({
                      new FindDependencyGraph(p, dg, &options),
                      new PHV_Field_Operations(p),
                      new PragmaContainerSize(p),
                      new PragmaAtomic(p),
                      new PragmaSolitary(p),
                      &pa_no_pack,
                      &tMutex,
                      &aMutex,
                      &packConflicts,
                      &tableActionsMap,
                      &actionConstraints,
                      new GatherDeparserParameters(p, deparserParams),
                      new GatherPhase0Fields(p, noPackFields),
                      new GatherAlignmentConstraints(p, actionConstraints),
                      &packWithConstraintSolver,
              });
}

// Return a Json representation of flexible headers to be saved in .bfa/context.json
std::string LogRepackedHeaders::asm_output() const {
    if (repacked.empty())
        return std::string("");

    std::ostringstream out;
    bool first_header = true;
    out << "flexible_headers: [\n";  // list of headers
    for (auto h : repacked) {
        if (!first_header) {
            out << ",\n";
        } else {
            out << "\n"; first_header = false;
        }

        out << "  { name: \"" << h.second << "\",\n"
            << "    fields: [\n";  // list of fields

        bool first_field = true;
        for (auto f : h.first->type->fields) {
            auto name = f->name.name;   // getFieldName(h.second, f);
            // for now all the fields are full fields not slices
            unsigned width = f->type->width_bits();
            unsigned start_bit = 0;  // so all fields start at 0.

            if (!first_field) {
                out << ",\n";
            } else {
                out << "\n"; first_field = false;
            }

            out << "      { name: \"" << name << "\", slice: { "
                << "start_bit: " << start_bit << ", bit_width: " << width
                // << ", slice_name:" << "the name of the slice"
                << " } }";
        }
        out << "    ]\n";    // list of fields
        out << "  }";     // header
    }
    out << "]\n";  // list of headers
    return out.str();
}

/**
 * candidates: if non-empty, indicate the set of header types to pack.
 *             if empty, all eligible header types are packed.
 */
PackFlexibleHeaders::PackFlexibleHeaders(const BFN_Options& options,
        ordered_set<cstring>& candidates, RepackedHeaderTypes& map) :
    uses(phv),
    defuse(phv),
    solver(context),
    constraint_solver(phv, context, solver, debug_info),
    packWithConstraintSolver(phv, constraint_solver, candidates, map) {
    flexiblePacking = new FlexiblePacking(phv, uses, deps, options,
            packWithConstraintSolver);
    flexiblePacking->addDebugHook(options.getDebugHook(), true);
    PragmaNoOverlay *noOverlay = new PragmaNoOverlay(phv);
    PragmaAlias *pragmaAlias = new PragmaAlias(phv, *noOverlay);
    addPasses({
        new CreateThreadLocalInstances,
        new BFN::CollectHardwareConstrainedFields,
        new CheckForUnimplementedFeatures(),
        new RemoveEmptyControls,
        // new MultipleApply(options, boost::none, false, false),
        new AddSelectorSalu,
        new FixupStatefulAlu,
        new CollectHeaderStackInfo,  // Needed by CollectPhvInfo.
        new CollectPhvInfo(phv),
        &defuse,
        Device::hasMetadataPOV() ? new AddMetadataPOV(phv) : nullptr,
        new CollectPhvInfo(phv),
        &defuse,
        new CollectHeaderStackInfo,  // Needs to be rerun after CreateThreadLocalInstances, but
                                     // cannot be run after InstructionSelection.
        new RemovePushInitialization,
        new StackPushShims,
        new CollectPhvInfo(phv),    // Needs to be rerun after CreateThreadLocalInstances.
        new HeaderPushPop,
        new InstructionSelection(options, phv),
        new FindDependencyGraph(phv, deps, &options, "program_graph", "Pack Flexible Headers"),
        new CollectPhvInfo(phv),
        pragmaAlias,
        new AutoAlias(phv, *pragmaAlias, *noOverlay),
        new Alias(phv, *pragmaAlias),
        new CollectPhvInfo(phv),
        // Run after InstructionSelection, before deadcode elimination.
        flexiblePacking
    });

    if (options.excludeBackendPasses) {
        try {
            removePasses(options.passesToExcludeBackend);
        } catch (const std::runtime_error& e) {
            // Ignore this error since this is only a subset of the backend passes
            LOG3(e.what());
        }
    }
}

void PackFlexibleHeaders::end_apply() {
    if (LOGGING(2)) {
        for (auto hdr : debug_info) {
            LOG1("(header " << hdr.first);
            for (auto constr = hdr.second.begin();
                    constr != hdr.second.end(); ++constr) {
                LOG1("  (constraint " << (*constr).first);
                for (auto iter = (*constr).second.begin();
                        iter != (*constr).second.end(); ++iter) {
                    LOG1("    " << *iter
                            << ((std::next(iter) != (*constr).second.end()) ? "" : ")")
                            << ((std::next(constr) != hdr.second.end()) ? "" : ")"));
                } }
        } }
}
