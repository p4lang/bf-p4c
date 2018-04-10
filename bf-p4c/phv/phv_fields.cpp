#include "bf-p4c/phv/phv_fields.h"

#include <boost/optional.hpp>
#include <boost/range/adaptor/reversed.hpp>
#include "bf-p4c/common/header_stack.h"
#include "bf-p4c/device.h"
#include "bf-p4c/phv/phv_parde_mau_use.h"
#include "ir/ir.h"
#include "lib/log.h"
#include "lib/stringref.h"

//
//***********************************************************************************
//
// PhvInfo member functions
//
//***********************************************************************************
//

void PhvInfo::clear() {
    all_fields.clear();
    by_id.clear();
    all_structs.clear();
    simple_headers.clear();
    alloc_done_ = false;
    pov_alloc_done = false;
}

void PhvInfo::add(
        cstring name, gress_t gress, int size, int offset, bool meta, bool pov,
        bool bridged, bool pad) {
    // Set the egress version of bridged fields to metadata
    if (gress == EGRESS && bridged)
        meta = true;
    LOG3("PhvInfo adding " << (pad ? "padding" : (meta ? "metadata" : "header")) << " field " <<
         name << " size " << size);
    assert(all_fields.count(name) == 0);
    auto *info = &all_fields[name];
    info->name = name;
    info->id = by_id.size();
    info->gress = gress;
    info->size = size;
    info->offset = offset;
    info->metadata = meta;
    info->pov = pov;
    info->bridged = bridged;
    info->alwaysPackable = pad;
    by_id.push_back(info);
}

void PhvInfo::add_hdr(cstring name, const IR::Type_StructLike *type, gress_t gress, bool meta) {
    if (!type) {
        LOG3("PhvInfo no type for " << name);
        return; }
    LOG3("PhvInfo adding " << (meta ? "metadata" : "header") << " " << name);
    BUG_CHECK(all_structs.count(name) == 0, "phv_fields.cpp:add_hdr(): all_structs inconsistent");
    int start = by_id.size();
    int offset = 0;
    auto annot = type->getAnnotations();
    bool bridged = false;
    if (auto s = annot->getSingle("layout")) {
        LOG3("Candidate bridged metadata header (found layout annotation): " << name);
        bridged = true; }
    for (auto f : type->fields)
        offset += f->type->width_bits();
    for (auto f : type->fields) {
        int size = f->type->width_bits();
        // "Hidden" annotation indicates padding introduced with bridged metadata fields
        bool isPad = f->getAnnotations()->getSingle("hidden") != nullptr;
        add(name + '.' + f->name, gress, size, offset -= size, meta, false, bridged, isPad); }
    int end = by_id.size();
    all_structs.emplace(name, StructInfo(meta, gress, start, end - start));
}

void PhvInfo::addTempVar(const IR::TempVar *tv, gress_t gress) {
    BUG_CHECK(tv->type->is<IR::Type::Bits>() || tv->type->is<IR::Type::Boolean>(),
              "Can't create temp of type %s", tv->type);
    if (all_fields.count(tv->name) == 0)
        add(tv->name, gress, tv->type->width_bits(), 0, true, tv->POV);
}

const PhvInfo::StructInfo PhvInfo::struct_info(cstring name_) const {
    StringRef name = name_;
    if (all_structs.find(name) != all_structs.end())
        return all_structs.at(name);
    if (auto *p = name.findstr("::")) {
        name = name.after(p+2); }
    if (all_structs.find(name) != all_structs.end())
        return all_structs.at(name);
    BUG("No PhvInfo::header for header named '%s'", name_);
}

//
//***********************************************************************************
//
// PhvInfo::field functions to extract field
// retrieve field from IR expression, IR member
//
//***********************************************************************************
//

const PHV::Field *PhvInfo::field(const IR::Expression *e, le_bitrange *bits) const {
    if (!e) return nullptr;
    BUG_CHECK(!e->is<IR::BFN::ContainerRef>(),
        "Looking for PHV::Fields but found an IR::BFN::ContainerRef: %1%", e);
    if (auto *fr = e->to<IR::Member>())
        return field(fr, bits);
    if (auto *cast = e->to<IR::Cast>())
        return field(cast->expr, bits);
    if (auto *sl = e->to<IR::Slice>()) {
        auto *rv = field(sl->e0, bits);
        if (rv && bits) {
            bits->lo += sl->getL();
            int width = sl->getH() - sl->getL() + 1;
            if (bits->hi >= bits->lo + width - 1)
                bits->hi = bits->lo + width - 1;
            if (bits->hi < bits->lo) {
                warning("slice %d..%d invalid for field %s of size %d", sl->getL(), sl->getH(),
                        sl->e0, bits->hi);
                return 0; } }
        return rv; }
    if (auto *tv = e->to<IR::TempVar>()) {
        if (auto *rv = getref(all_fields, tv->name)) {
            if (bits) {
                bits->lo = 0;
                bits->hi = rv->size - 1; }
            return rv;
        } else {
            BUG("TempVar %s not in PhvInfo", tv->name); } }
    return 0;
}

const PHV::Field *PhvInfo::field(const IR::Member *fr, le_bitrange *bits) const {
    if (bits) {
        bits->lo = 0;
        bits->hi = fr->type->width_bits() - 1; }

    // No need to look up enums, which are really constants.  This sidesteps
    // the warning message for "can't find field" as well.
    if (fr->type->is<IR::Type_Enum>())
        return nullptr;

    return field(fr->toString());
}

const PHV::Field *PhvInfo::field(const cstring& name_) const {
    StringRef name = name_;
    if (auto *p = name.find('[')) {
        if (name.after(p).find(':'))
            name = name.before(p); }
    if (auto *rv = getref(all_fields, name))
        return rv;
    if (auto *p = name.findstr("::")) {
        name = name.after(p+2);
        if (auto *rv = getref(all_fields, name))
            return rv; }

    // XXX(seth): The warning spew from POV bits prior to allocatePOV() being
    // called is just too great. We need to improve how that's handled, but for
    // now, silence those warnings.
    if (!name.toString().endsWith(".$valid"))
        warning("can't find field '%s'", name);

    return nullptr;
}

//
//***********************************************************************************
//
// PhvInfo::allocatePOV
// simple header pov & header stack pov ccgfs
//
//***********************************************************************************
//

void PhvInfo::allocatePOV(const BFN::HeaderStackInfo& stacks) {
    LOG3("BEGIN PhvInfo::allocatePOV");
    if (pov_alloc_done) BUG("trying to reallocate POV");
    pov_alloc_done = true;

    int size[2] = { 0, 0 };
    int stacks_num = 0;
    for (auto &stack : stacks) {
        LOG3("    ...preanalyzing header stack " << stack.name);
        StructInfo info = struct_info(stack.name);
        BUG_CHECK(!info.metadata, "metadata stack?");
        size[info.gress] += stack.size + stack.maxpush + stack.maxpop;
        stacks_num++; }

    for (auto &hdr : simple_headers) {
        LOG3("    ...preanalyzing simple header " << hdr.first);
        auto hdr_info = hdr.second;
        ++size[hdr_info.gress]; }

    for (auto &field : *this)
        if (field.pov && field.metadata)
            size[field.gress] += field.size;

    for (auto gress : { INGRESS, EGRESS }) {
        if (size[gress] == 0) continue;
        for (auto &field : *this) {
            if (field.pov && field.metadata && field.gress == gress) {
                size[gress] -= field.size;
                field.offset = size[gress]; } }

        // Create fields for (non-header stack) validity bits.
        for (auto hdr : simple_headers)
            if (hdr.second.gress == gress)
                add(hdr.first + ".$valid", gress, 1, --size[gress], false, true);

        // Create header stack POVs, including header stack validity bits.
        for (auto &stack : stacks) {
            StructInfo info = struct_info(stack.name);
            if (info.gress == gress) {
                add(stack.name + ".$stkvalid", gress, stack.size + stack.maxpush + stack.maxpop,
                    size[gress], true, true);
                size[gress] -= stack.size + stack.maxpush + stack.maxpop;
                PHV::Field *pov_stk = &all_fields[stack.name + ".$stkvalid"];
                pov_stk->set_no_split(true);
                LOG3("Creating HEADER STACK " << pov_stk); } }

        BUG_CHECK(size[gress] == 0, "%1% more bits of POV expected but not created in %2%",
                  size[gress], cstring::to_cstring(gress)); }
}

//
//***********************************************************************************
//
// PhvInfo::container_to_fields related functions
//
//***********************************************************************************
//
void PhvInfo::add_container_to_field_entry(const PHV::Container c,
                                           const PHV::Field *f) {
    if (f == nullptr) return;
    container_to_fields[c].insert(f);
}

const ordered_set<const PHV::Field *>&
PhvInfo::fields_in_container(const PHV::Container c) const {
    static const ordered_set<const PHV::Field *> empty_list;
    if (container_to_fields.count(c))
        return container_to_fields.at(c);
    return empty_list;
}

bitvec PhvInfo::bits_allocated(
        const PHV::Container c, const ordered_set<const PHV::Field*>& writes) const {
    bitvec ret_bitvec;
    auto& fields = fields_in_container(c);
    if (fields.size() == 0)
        return ret_bitvec;
    // Gather all the slices of written fields allocated to container c
    ordered_set<const PHV::Field::alloc_slice*> write_slices_in_container;
    for (auto* field : writes) {
        field->foreach_alloc([&](const PHV::Field::alloc_slice &alloc) {
            if (alloc.container != c) return;
            write_slices_in_container.insert(&alloc);
        }); }
    for (auto* field : fields) {
        if (field->alwaysPackable) continue;
        field->foreach_alloc([&](const PHV::Field::alloc_slice &alloc) {
            if (alloc.container != c) return;
            le_bitrange bits = alloc.container_bits();
            // Discard the slices that are mutually exclusive with any of the written slices
            bool mutually_exclusive = std::any_of(
                write_slices_in_container.begin(), write_slices_in_container.end(),
                [&](const PHV::Field::alloc_slice* slice) {
                    return field_mutex(slice->field->id, alloc.field->id); });
            if (!mutually_exclusive)
                ret_bitvec.setrange(bits.lo, bits.size());
        }); }
    return ret_bitvec;
}

boost::optional<cstring> PhvInfo::get_alias_name(const IR::Expression* expr) const {
    if (auto mem = expr->to<IR::BFN::AliasMember>()) {
        cstring aliasSourceName = mem->getAliasSource();
        BUG_CHECK(aliasSourceName != cstring(), "No alias source name for AliasMember %1%",
                mem);
        const PHV::Field* aliasSourceField = field(aliasSourceName);
        BUG_CHECK(aliasSourceField, "Field %s not found", aliasSourceName);
        return aliasSourceName;
    } else if (auto sl = expr->to<IR::Slice>()) {
        auto expr = sl->e0;
        if (auto mem = expr->to<IR::BFN::AliasMember>()) {
            cstring aliasSourceName = mem->getAliasSource();
            BUG_CHECK(aliasSourceName != cstring(), "No alias source name for AliasMember %1%",
                    mem);
            const PHV::Field* aliasSourceField = field(aliasSourceName);
            BUG_CHECK(aliasSourceField, "Field %s not found", aliasSourceName);
            return aliasSourceName;
        }
    }
    return boost::none;
}

//
//***********************************************************************************
//
// PHV::Field le_bitrange interface related member functions
//
//***********************************************************************************
//

// figure out how many disinct container bytes contain info from a le_bitrange of a particular field
//
int PHV::Field::container_bytes(le_bitrange bits) const {
    if (bits.hi < 0) bits.hi = size - 1;
    if (alloc_i.empty())
        return bits.hi/8U + bits.lo/8U + 1;
    int rv = 0, w;
    for (int bit = bits.lo; bit <= bits.hi; bit += w) {
        auto &sl = for_bit(bit);
        w = sl.width - (bit - sl.field_bit);
        if (bit + w > bits.hi)
            w = bits.hi - bit + 1;
        int cbit = bit + sl.container_bit - sl.field_bit;
        rv += (cbit+w-1)/8U - cbit/8U + 1; }
    return rv;
}

//
//***********************************************************************************
//
// PHV::Field Cluster Phv_Bind / alloc_i interface related member functions
//
//***********************************************************************************
//

safe_vector<PHV::Field::alloc_slice> *
PhvInfo::alloc(const IR::Member *member) {
    PHV::Field *info = field(member);
    BUG_CHECK(nullptr != info, "; Cannot find PHV allocation for %s", member->toString());
    return &info->alloc_i;
}

void PHV::Field::foreach_byte(
        le_bitrange range,
        std::function<void(const PHV::Field::Slice&)> fn) const {
    le_bitrange window = StartLen(range.lo, 8);
    while (window.overlaps(range)) {
        // Create a Slice of the window intersected with the range.
        PHV::Field::Slice slice(this, *toClosedRange(window.intersectWith(range)));

        // Apply @fn.
        fn(slice);

        // Advance the window.
        window = window.shiftedByBits(8); }
}

const PHV::Field::alloc_slice &PHV::Field::for_bit(int bit) const {
    for (auto &sl : alloc_i)
        if (bit >= sl.field_bit && bit < sl.field_bit + sl.width)
            return sl;
    ERROR("No allocation for bit " << bit << " in " << name);
    static alloc_slice invalid(nullptr, PHV::Container(), 0, 0, 0);
    return invalid;
}

// TODO(cole): Should really reimplement this to call foreach_alloc and then
// iterate byte-by-byte through each alloc.
void PHV::Field::foreach_byte(
        le_bitrange range,
        std::function<void(const alloc_slice &)> fn) const {
    // Iterate in reverse order, because alloc_i slices are ordered from field
    // MSB to LSB, but foreach_byte iterates from LSB to MSB.
    for (auto slice : boost::adaptors::reverse(alloc_i)) {
        // Break after we've processed the last element.
        if (range.hi < slice.field_bits().lo)
            break;

        // Otherwise, skip allocations that don't overlap with the target
        // range.
        if (!range.overlaps(slice.field_bits()))
            continue;

        // XXX(cole): HACK: clients of foreach_byte assume that @fn is invoked
        // exactly once for each byte of the field, which is violated if the
        // field is allocated in more than one place.  There was a time when
        // fields could be allocated to both PHV and TPHV (but this may not be
        // true any longer).  Hence, skip TPHV allocations.
        if (slice.container.is(PHV::Kind::tagalong))
            continue;

        // The requested range may only cover part of slice, so we create a new
        // slice that intersects with the range.
        auto intersectedSlice = slice;
        if (slice.field_bit < range.lo) {
            int difference = range.lo - slice.field_bit;
            intersectedSlice.container_bit += difference;
            intersectedSlice.field_bit += difference;
            intersectedSlice.width -= difference; }
        if (range.hi < slice.field_hi())
            intersectedSlice.width -= slice.field_hi() - range.hi;

        // Apply @fn to each byte of the restricted allocation, taking care to
        // split the allocation along container byte boundaries.
        le_bitrange containerRange = intersectedSlice.container_bits();
        le_bitrange byte = StartLen(containerRange.loByte() * 8, 8);
        BUG_CHECK(byte.overlaps(containerRange),
                  "Bad alloc?\nByte: %1%\nContainer range: %2%\nField: %3%",
                  cstring::to_cstring(byte), cstring::to_cstring(containerRange),
                  cstring::to_cstring(this));
        while (byte.overlaps(containerRange)) {
            auto window = toClosedRange(byte.intersectWith(containerRange));
            BUG_CHECK(window, "Bad alloc slice");

            // Create an alloc_slice for this window.
            int offset = window->lo - containerRange.lo;
            alloc_slice tmp(this,
                            intersectedSlice.container,
                            intersectedSlice.field_bit + offset,
                            window->lo,
                            window->size());

            // Invoke the function.
            fn(tmp);

            // Increment the window.
            byte = byte.shiftedByBits(8); } }
}

void PHV::Field::foreach_alloc(
        le_bitrange range,
        std::function<void(const alloc_slice &)> fn) const {
    int lo = range.lo;
    int hi = range.hi;
    alloc_slice tmp(this, PHV::Container(), lo, lo, hi-lo+1);

    // Find first slice that includes @lo, and process it.
    auto it = alloc_i.rbegin();
    while (it != alloc_i.rend() && it->field_hi() < lo) ++it;
    if (it != alloc_i.rend() && it->field_bit != lo) {
        BUG_CHECK(it->field_bit < lo,
            "Field %1% has an allocated PHV slice %2% that appears out of order; expected its LSB "
            "(%3%) to be less than %4%.", cstring::to_cstring(it->field),
            cstring::to_cstring(*it), it->field_bit, lo);
        tmp = *it;
        tmp.container_bit += abs(it->field_bit - lo);
        if (tmp.container_bit < 0) {
            LOG1("********** phv_fields.cpp:sanity_FAIL **********"
                << ".....container_bit negative in alloc_slice....."
                << " field_bit = " << it->field_bit
                << " container_bit = " << it->container_bit
                << " width = " << it->width
                << " lo = " << lo
                << " tmp.container_bit = " << tmp.container_bit
                << std::endl
                << " field = " << this
                << " container = " << it->container);
            BUG("phv_fields.cpp:foreach_alloc(): container_bit negative in alloc_slice");
        }
        tmp.field_bit = lo;
        if (it->field_hi() > hi)
            tmp.width = hi - lo + 1;
        else
            tmp.width -= abs(it->field_bit - lo);
        fn(tmp);
        ++it; }

    // Process remaining slices until reaching the first slice that does not
    // include any bits less than @hi.
    while (it != alloc_i.rend() && it->field_bit <= hi) {
        if (it->field_hi() > hi) {
            tmp = *it;
            tmp.width = hi - it->field_bit + 1;
            fn(tmp);
        } else {
            fn(*it); }
        ++it; }
}

//
// constraints, phv_widths
//
bool
PHV::Field::constrained(bool packing_constraint) const {
    bool pack_c = mau_phv_no_pack_i || no_pack_i;
    if (packing_constraint) {
        return pack_c;
    }
    return  pack_c || deparsed_bottom_bits_i;
}

bool
PHV::Field::is_ccgf() const {
    if (ccgf_i == this || header_stack_pov_ccgf_i || simple_header_pov_ccgf_i) {
        BUG_CHECK(ccgf_fields_i.size(), "ccgf fields empty");
        return true;
    }
    return false;
}

bool PHV::Field::is_tphv_candidate(const PhvUse& uses) const {
    // Privatized fields are the TPHV copies of header fields. Therefore, privatized fields are
    // always TPHV candidates.
    if (privatized_i) return true;
    return !uses.is_used_mau(this) && !pov && !metadata && !deparsed_to_tm_i;
}

boost::optional<int>
PHV::Field::phv_alignment(bool get_ccgf_alignment) const {
    // the parameter get_ccgf_alignment distinguishes between requesting alignment
    // of the CCGF as a whole vs the alignment of a ccgf member field
    if (alignment) {
        if (get_ccgf_alignment && ccgf_fields_i.size()) {
            // return alignment of last field of ccgf as [m1,m2,m3] placed m3.m2.m1 in phv[0..w]
            return ccgf_fields_i.back()->phv_alignment();
        }
        return alignment->littleEndian;
    }
    return boost::none;
}

boost::optional<int> PHV::Field::phv_alignment_network() const {
    if (alignment)
        return alignment->network;
    return boost::none;
}

int
PHV::Field::ccgf_width() const {
    int ccgf_width_l = 0;
    for (auto &f : ccgf_fields_i) {
        if (f->is_ccgf() && !f->header_stack_pov_ccgf()) {
            // ccgf owner appears as member, phv_use_width = aggregate size of members
            ccgf_width_l += f->size;
        } else {
            ccgf_width_l += f->size;
        }
    }
    return ccgf_width_l;
}

void PHV::Field::updateAlignment(const FieldAlignment& newAlignment) {
    LOG3("Inferred alignment " << newAlignment << " for field " << name);

    // If there's no existing alignment for this field, just take this one.
    if (!alignment) {
        alignment = newAlignment;
        return;
    }

    // If there is an existing alignment, it must agree with this new one.
    // Otherwise the program is inconsistent and we can't compile it.
    // XXX(seth): We actually could, in theory, handle such a situation by
    // creating two different versions of the field with different alignments
    // and copying between them as needed in the MAU. Not cheap, though.
    ERROR_CHECK(*alignment == newAlignment,
                "Inferred incompatible alignments for field %1%: %2% != %3%",
                name, cstring::to_cstring(newAlignment),
                cstring::to_cstring(*alignment));
}

void PHV::Field::updateValidContainerRange(nw_bitrange newValidRange) {
    LOG3("Inferred valid container range " << newValidRange <<
         " for field " << name);

    const auto intersection = validContainerRange_i.intersectWith(newValidRange);
    if (intersection.empty() || intersection.size() < size) {
        ::error("Inferred valid container ranges %1% and %2% for field %3% "
                "which cannot both be satisfied for a field of size %4%b",
                cstring::to_cstring(validContainerRange_i),
                cstring::to_cstring(newValidRange), name, size);
        return;
    }

    validContainerRange_i = *toClosedRange(intersection);
}


//***********************************************************************************
//
// CollectPhvInfo implementation.
//
//***********************************************************************************

/**
 * Populates a PhvInfo object with Fields for each PHV-backed object in the
 * program (header instances, TempVars, etc.).
 *
 * Some Field metadata can't be collected in a single pass; that information is
 * collected by other CollectPhvInfo passes.
 *
 * XXX(seth): There's some other stuff mixed in here for historical reasons, but
 * we should think about whether it belongs in separate passes.
 */
struct CollectPhvFields : public Inspector, public TofinoWriteContext {
    explicit CollectPhvFields(PhvInfo& phv) : phv(phv) { }

 private:
    Visitor::profile_t init_apply(const IR::Node* root) override {
        auto rv = Inspector::init_apply(root);
        phv.clear();
        return rv;
    }

    bool preorder(const IR::Header* h) override {
        auto gress = VisitingThread(this);
        int start = phv.by_id.size();
        phv.add_hdr(h->name, h->type, gress, false);
        int end = phv.by_id.size();
        phv.simple_headers.emplace(h->name,
                                   PhvInfo::StructInfo(false, gress, start, end - start));
        return false;
    }

    bool preorder(const IR::HeaderStack* h) override {
        if (!h->type) return false;
        auto gress = VisitingThread(this);
        char buffer[16];
        int start = phv.by_id.size();
        for (int i = 0; i < h->size; i++) {
            snprintf(buffer, sizeof(buffer), "[%d]", i);
            phv.add_hdr(h->name + buffer, h->type, gress, false); }
        int end = phv.by_id.size();
        phv.all_structs.emplace(h->name, PhvInfo::StructInfo(false, gress, start, end - start));
        return false;
    }

    bool preorder(const IR::Metadata* h) override {
        auto gress = VisitingThread(this);
        phv.add_hdr(h->name, h->type, gress, true);
        return false;
    }

    bool preorder(const IR::TempVar* tv) override {
        auto gress = VisitingThread(this);
        phv.addTempVar(tv, gress);

        // XXX(seth): `^bridged_metadata_indicator` is a special case, because
        // it looks like bridged metadata in the IR, but it *must* be placed in
        // a single 8-bit container so that the egress parser works correctly.
        if (tv->name.endsWith("^bridged_metadata_indicator")) {
            PHV::Field* f = phv.field(tv);
            BUG_CHECK(f, "No PhvInfo entry for a field we just added?");
            f->set_exact_containers(true);
            f->set_no_pack(true);
            f->set_no_split(true);
        }
        // A field that ends with PHV::Field::PRIVATIZE_SUFFIX is the TPHV copy of a header field,
        // produced during the Privatization pass. This field must be marked appropriately as
        // privatized.
        if (tv->name.endsWith(PHV::Field::PRIVATIZE_SUFFIX)) {
            PHV::Field* f = phv.field(tv);
            BUG_CHECK(f, "No PhvInfo entry for a field we just added?");
            f->set_privatized(true);
        }

        return false;
    }

    void postorder(const IR::BFN::DeparserParameter* param) override {
        // extract deparser constraints from Deparser & Digest IR nodes ref: bf-p4c/ir/parde.def
        // set deparser constaints on field
        PHV::Field* f = phv.field(param->source->field);
        BUG_CHECK(f != nullptr, "Field not created in PhvInfo");

        // Deparser parameters all need to be placed right-justified in their
        // containers *for now*.
        // XXX(seth): We can relax this restriction once we add support for the
        // shifters that the deparser hardware makes available.
        f->updateAlignment(FieldAlignment(le_bitrange(StartLen(0, f->size))));
        f->set_deparsed_bottom_bits(true);
        f->set_deparsed_to_tm(true);
        f->set_no_split(true);

        BUG_CHECK(f->size < 32, "The architecture requires that field %1% not be split "
                  "across PHV containers, but the field is larger than the largest PHV container.",
                  cstring::to_cstring(f));

        // If this field can be packed with other fields, we're done.
        if (param->canPack) return;

        // The field assigned to this parameter cannot be packed with other
        // fields; this is generally because Tofino's hidden container
        // validity bit matters for this parameter, and if we packed it with
        // other fields, writes to those other fields would change the
        // hidden container validity bit and break the program.
        f->set_no_pack(true);
        f->set_read_container_valid_bit(true);
        LOG1(".....Deparser No-Pack Constraint '" << param->name
              << "' on field..... " << f);
    }

    void postorder(const IR::BFN::Digest* entry) override {
        // TODO:
        // IR futures: distinguish each digest as an enumeration: learning, mirror, resubmit
        // as they have differing constraints -- bottom-bits, bridge-metadata mirror packing
        // learning, mirror field list in bottom bits of container, e.g.,
        // 301:ingress::$learning<3:0..2>
        // 590:egress::$mirror<3:0..2> specifies 1 of 8 field lists
        // currently, IR::BFN::Digest node has a string field to distinguish them by name
        if (entry->name != "learning" && entry->name != "mirror"
            && entry->name != "resubmit")
            return;

        PHV::Field* f = phv.field(entry->selector->field);
        BUG_CHECK(f != nullptr, "Field not created in PhvInfo");
        f->set_deparsed_bottom_bits(true);
        f->set_no_split(true);
        // TODO:
        // This constraint can be removed by setting digest field to an invalid value
        // in the parser, instead of using the validity bit of container, which implies
        // the no_pack here.
        f->set_no_pack(true);
        f->set_read_container_valid_bit(true);
        LOG1(".....Deparser Constraint " << entry->name << " 'digest' on field..... " << f);

        if (entry->name == "resubmit") {
            LOG1("\t resubmit field (" << f << ") is set to be "
                 << "no_pack, no_split and deparsed_bottom_bits");
            return; }

        if (entry->name == "learning") {
            // Add byte-aligned constraint to metadata field in learning field_list
            // TODO(yumin): This constraint can be relaxed to be no_pack in a same byte.
            for (auto* fieldList : entry->fieldLists) {
                for (auto* fieldListEntry : fieldList->sources) {
                    auto* fieldInfo = phv.field(fieldListEntry->field);
                    if (fieldInfo->metadata) {
                        fieldInfo->updateAlignment(
                                FieldAlignment(le_bitrange(StartLen(0, fieldInfo->size))));
                        LOG1(fieldInfo << " is marked to be byte_aligned "
                             "because it's in a field_list and digested."); } } }

            // Logging...
            for (auto* fieldList : entry->fieldLists) {
                LOG1("\t.....learning field list..... ");
                for (auto* fieldListEntry : fieldList->sources) {
                    auto* fieldInfo = phv.field(fieldListEntry->field);
                    if (fieldInfo)
                        LOG1("\t\t" << fieldInfo);
                    else
                        LOG1("\t\t" <<"-f?"); } }
            return; }

        // For mirror digests, associate the mirror field with its field list,
        // which is used during constraint checks for bridge-metadata phv
        // allocation.
        LOG1(".....mirror fields in field list " << f->id << ":" << f->name);
        int fieldListIndex = 0;
        for (auto* fieldList : entry->fieldLists) {
            LOG1("\t.....field list....." << fieldList);

            // The first two entries in the field list are both special and may
            // not be split between containers. The first indicates the mirror
            // session ID to the hardware. The second is used by the egress
            // parser to determine which field list a mirrored packet comes
            // from, and we need to be careful to ensure that it maintains the
            // expected layout exactly.
            if (!fieldList->sources.empty()) {
                auto* fieldInfo = phv.field(fieldList->sources[0]->field);
                if (fieldInfo) fieldInfo->set_no_split(true);
            }
            if (fieldList->sources.size() > 1) {
                auto* fieldInfo = phv.field(fieldList->sources[1]->field);
                if (fieldInfo) fieldInfo->set_no_split(true);
            }

            /* HACK: Mirroring in P4_14 is currently handled through the Mirror
             * extern, which in turn is implemented in the backend by
             * synthesizing a parser that assumes mirrored fields are allocated
             * to the bottom bits of the smallest PHV containers large enough to
             * hold them.
             * 
             * This hack forces PHV allocation to match that assumption.
             * However, adding no_pack and no_split means we will fail to
             * allocate any mirrored fields larger than 32b.
             * 
             * The long-term solution is to change P4_14-->P4_16 conversion to
             * translate mirroring to TNA.
             */
            for (auto* mirroredField : fieldList->sources) {
                PHV::Field* mirror = phv.field(mirroredField->field);
                if (mirror) {
                    mirror->mirror_field_list = {f, fieldListIndex};
                    mirror->set_deparsed_to_tm(true);
                    mirror->set_no_pack(true);
                    mirror->set_no_split(true);
                    LOG1("\t\t" << mirror);
                } else {
                    LOG1("\t\t" << "-f?"); }
                fieldListIndex++; } }
    }

    void postorder(const IR::BFN::LoweredParser*) override {
        BUG("Running CollectPhvInfo after the parser IR has been lowered; "
            "this will produce invalid results.");
    }

    PhvInfo& phv;
};

/// Allocate POV bits for each header instance, metadata instance, or header
/// stack that we visited in CollectPhvFields.
struct AllocatePOVBits : public Inspector {
    explicit AllocatePOVBits(PhvInfo& phv) : phv(phv) { }

 private:
    profile_t init_apply(const IR::Node* root) override {
        LOG3("BEGIN AllocatePOVBits");
        return Inspector::init_apply(root);
    }

    bool preorder(const IR::BFN::Pipe* pipe) override {
        BUG_CHECK(pipe->headerStackInfo != nullptr,
                  "Running AllocatePOVBits without running "
                  "CollectHeaderStackInfo first?");
        phv.allocatePOV(*pipe->headerStackInfo);
        return false;
    }

    PhvInfo& phv;
};

/// Examine how fields are used in the parser and deparser to compute their
/// alignment requirements.
struct ComputeFieldAlignments : public Inspector {
    explicit ComputeFieldAlignments(PhvInfo& phv) : phv(phv) { }

 private:
    bool preorder(const IR::BFN::Extract* extract) override {
        // Only extracts from the input buffer introduce alignment constraints.
        auto* bufferSource = extract->source->to<IR::BFN::BufferlikeRVal>();
        if (!bufferSource) return false;

        auto* fieldInfo = phv.field(extract->dest->field);
        if (!fieldInfo) {
            ::warning("No allocation for field %1%", extract->dest);
            return false;
        }

        // The alignment required for a parsed field is determined by the
        // position from which it's read from the wire.
        const auto extractedBits = bufferSource->range();
        const auto alignment = FieldAlignment(extractedBits);
        fieldInfo->updateAlignment(alignment);

        // If a parsed field starts at a container bit index larger than the bit
        // index at which it's located in the input buffer, we won't be able to
        // extract it, because we'd have to read past the beginning of the input
        // buffer. For example (all indices are in network order):
        //
        //   Container: [ 0  1  2  3  4  5  6  7  8  9  10 11 12 13 14 15 ]
        //                                      [       field      ]
        //   Input buffer:                      [ 0  1  2  3  4  5 ]
        //
        // This field begins at position 0 in the input buffer, but because the
        // parser has to write to the entire container, to place the field at
        // position 8 in the container would require that bits [0, 7] of the
        // container came from a negative position in the input buffer.
        //
        // To avoid this, we generate a constraint that prevents PHV allocation
        // from placing the field in a problematic position in the container.
        //
        // In simple terms, what we want to avoid is placing the field too far
        // to the right in the container. For fields which come from the mapped
        // input buffer region (which has a fixed coordinate system that cannot
        // be shifted) or from the end of the headers in the input packet (where
        // we'll end up treating some of the packet payload as header if we
        // introduce an extra shift), a symmetric issue exists where we need to
        // avoid placing the field too far to the *left* in the container. Both
        // of these limitations need to be converted into constraints for PHV
        // allocation.
        // XXX(seth): Unfortunately we can't capture the "too far to the left"
        // case with our current representation of valid container ranges.
        const nw_bitrange validContainerRange = FromTo(0, extractedBits.hi);
        fieldInfo->updateValidContainerRange(validContainerRange);

        // XXX(seth): This is a hack: if this field was bridged from ingress, we
        // apply the same alignment constraint to the ingress version of the
        // field. This ensures that the two allocations are compatible until
        // we're ready to handle bridged metadata more intelligently. (Note that
        // we don't even need to do this before CreateThreadLocalInstances has
        // run, since before that there is just one version of the field; that's
        // why we check for "egress::" below.)
        auto* state = findContext<IR::BFN::ParserState>();
        if (state->name.endsWith("^bridge_metadata_extract") &&
                fieldInfo->name.startsWith("egress::")) {
            cstring ingressFieldName = cstring("ingress::")
                                     + fieldInfo->name.substr(strlen("egress::"));
            auto* ingressFieldInfo = phv.field(ingressFieldName);
            BUG_CHECK(ingressFieldInfo != nullptr,
                      "No ingress version of egress bridged metadata field?");
            ingressFieldInfo->updateAlignment(alignment);
            ingressFieldInfo->updateValidContainerRange(validContainerRange);
        }

        return false;
    }

    bool preorder(const IR::BFN::Deparser* deparser) override {
        unsigned currentBit = 0;

        for (auto* emitPrimitive : deparser->emits) {
            // XXX(seth): Right now we treat EmitChecksum as not inducing any
            // particular alignment, but we will need to revisit that.
            auto* emit = emitPrimitive->to<IR::BFN::Emit>();
            if (!emit) continue;

            auto* fieldInfo = phv.field(emit->source->field);
            if (!fieldInfo) {
                ::warning("No allocation for field %1%", emit->source);
                currentBit = 0;
                continue;
            }

            // XXX(seth): We don't need to infer any constraints from the
            // deparser for bridged metadata fields; they get their alignment
            // from the hack in `preorder(Extract)`. (We just duplicate the
            // egress alignment constraints, which are inferred from the
            // parser, for the ingress versions of the fields.) For now, we just
            // skip to the next byte-aligned position.
            if (fieldInfo->bridged) {
                currentBit += fieldInfo->size;
                if (currentBit % 8 != 0)
                    currentBit += 8 - currentBit % 8;
                continue;
            }

            // For other deparsed fields, the alignment requirement is induced
            // by the position at which the field will be written on the wire.
            // We can behave as if every field will be deparsed (i.e., all POV
            // bits are set) because any sequential group of deparsed fields
            // with the same POV bits must be byte-aligned in a valid Tofino P4
            // program. (If not, you'd end up with garbage bits on the wire.)
            nw_bitrange emittedBits(currentBit, currentBit + fieldInfo->size - 1);
            fieldInfo->updateAlignment(FieldAlignment(emittedBits));
            currentBit += fieldInfo->size;
        }

        return false;
    }

    PhvInfo& phv;
};


/// Set the `deparsed` constraint for fields that are emitted in the deparser.
class MarkDeparsedFields : public Inspector {
    PhvInfo& phv_i;

    bool preorder(const IR::BFN::Emit* emit) {
        auto* src_field = phv_i.field(emit->source->field);
        BUG_CHECK(src_field, "Deparser Emit with a non-PHV source: %1%",
                  cstring::to_cstring(emit));
        // XXX(cole): These two constraints will be subsumed by deparser schema.
        src_field->set_deparsed(true);
        src_field->set_exact_containers(true);

        if (!src_field->privatized()) return false;

        // The original PHV copy of privatized fields must be explicitly identified as privatizable
        // and its exact containers property must be set to true.
        boost::optional<cstring> newString = src_field->getPHVPrivateFieldName();
        if (!newString)
            BUG("Did not find PHV version of privatized field %1%", src_field->name);
        auto* phv_field = phv_i.field(*newString);
        BUG_CHECK(phv_field, "PHV version of privatized field %1% not found", src_field->name);
        phv_field->set_exact_containers(true);
        phv_field->set_privatizable(true);

        return false;
    }

 public:
    explicit MarkDeparsedFields(PhvInfo& phv) : phv_i(phv) { }
};

Visitor::profile_t AddAliasAllocation::init_apply(const IR::Node* root) {
    profile_t rv = Inspector::init_apply(root);
    for (auto kv : phv.getAliasMap()) {
        PHV::Field* aliasSource = phv.field(kv.first);
        PHV::Field* aliasDest = phv.field(kv.second);
        BUG_CHECK(aliasSource, "Alias source %1% not found");
        BUG_CHECK(aliasDest, "Alias destination %1% not found");
        aliasDest->foreach_alloc([&](const PHV::Field::alloc_slice& alloc) {
            aliasSource->alloc_i.emplace_back(
                aliasSource,
                alloc.container,
                alloc.field_bit,
                alloc.container_bit,
                alloc.width);
            phv.add_container_to_field_entry(alloc.container, aliasSource);
        });
    }

    // Later passes assume that PHV allocation is sorted in field bit order
    // MSB first
    for (auto& f : phv) {
        std::sort(f.alloc_i.begin(), f.alloc_i.end(),
                [](PHV::Field::alloc_slice l, PHV::Field::alloc_slice r) {
                return l.field_bit > r.field_bit; }); }
    return rv;
}

bool CollectNameAnnotations::preorder(const IR::MAU::Table* t) {
    if (t->match_table) {
        forAllMatching<IR::KeyElement>(t->match_table,
            [&](const IR::KeyElement* e) {
                // XXX(cole): This method is applied to mid-end IR but needs to
                // look up the back-end version of field names.  The following
                // code basically reapplies the name mangling that the back end
                // does.  There must be a better way.

                for (auto gress : { INGRESS, EGRESS }) {
                    auto prefix = gress == INGRESS ? "ingress::" : "egress::";
                    StringRef name = e->expression->toString();
                    if (auto* p1 = name.findlast('.')) {
                        StringRef n1 = name.before(p1);
                        if (auto* p2 = n1.findlast('.')) {
                            name = name.after(p2 + 1); } }
                    auto* field = phv.field(prefix + name);
                    if (!field) return true;
                    if (auto ann = e->getAnnotation(IR::Annotation::nameAnnotation)) {
                        field->setExternalName(prefix + IR::Annotation::getName(ann));
                        LOG1(ann << ": setting external name of field " << field->name
                             << " to " << field->externalName()); } }
                    return true;
            }); }
    return true;
}

/** The timestamp and version fields are located in a special part of the input
 * buffer, and PHV allocation needs to take care when allocating these fields:
 * Their start/end bits can't be placed too deep within a PHV container,
 * because that would cause the extractor to read off the end of the buffer.
 *  
 * That is, both timestamp and version have both a validContainerStart range
 * (like extracted fields) but also a dual validContainerEnd range.
 *  
 * However, rather than implement that for just two fields, this pass instead
 * sets the exact_containers requirement for these fields, sidestepping the
 * problem.
 */
class MarkTimestampAndVersion : public Inspector {
    PhvInfo& phv_i;

    void end_apply() {
        for (auto& f : phv_i) {
            cstring name = f.name;
            bool isTstamp = name.endsWith("ig_intr_md_from_prsr.global_tstamp");
            bool isVersion = name.endsWith("ig_intr_md_from_prsr.global_ver");
            if (isTstamp || isVersion) {
                LOG2("Setting exact_containers for " << f.name);
                f.set_exact_containers(true); } }
    }

 public:
    explicit MarkTimestampAndVersion(PhvInfo& phv) : phv_i(phv) { }
};

CollectPhvInfo::CollectPhvInfo(PhvInfo& phv) {
    addPasses({
        new CollectPhvFields(phv),
        new AllocatePOVBits(phv),
        new ComputeFieldAlignments(phv),
        new MarkDeparsedFields(phv),
        new MarkTimestampAndVersion(phv)
    });
}
//
//
//***********************************************************************************
//
// output stream <<
//
//***********************************************************************************
//

std::ostream &PHV::operator<<(std::ostream &out, const PHV::Field::alloc_slice &sl) {
    out << '[' << (sl.field_bit+sl.width-1) << ':' << sl.field_bit << "]->[" << sl.container << ']';
    if (sl.container_bit || size_t(sl.width) != sl.container.size()) {
        out << '(' << sl.container_bit;
        if (sl.width != 1)
            out << ".." << (sl.container_bit + sl.width - 1);
        out << ')'; }
    return out;
}

std::ostream &PHV::operator<<(std::ostream &out,
                         const std::vector<PHV::Field::alloc_slice> &sl_vec) {
    for (auto &sl : sl_vec) {
        out << sl << ';';
    }
    return out;
}

std::ostream &operator<<(std::ostream &out,
                         const safe_vector<PHV::Field::alloc_slice> &sl_vec) {
    for (auto &sl : sl_vec) {
        out << sl << ';';
    }
    return out;
}

std::ostream &PHV::operator<<(std::ostream &out, const PHV::Field &field) {
    out << field.id << ':' << field.name << '<' << field.size << '>';
    if (field.alignment)
        out << " ^" << field.alignment->littleEndian;
    else
        out << " ^x";
    if (field.validContainerRange_i != ZeroToMax())
        out << " ^" << field.validContainerRange_i;
    else
        out << " ^x";
    if (field.bridged) out << " bridge";
    if (field.metadata) out << " meta";
    if (field.mirror_field_list.member_field)
        out << " mirror%{"
            << field.mirror_field_list.member_field->id
            << ":" << field.mirror_field_list.member_field->name
            << "#" << field.mirror_field_list.field_list
            << "}%";
    if (field.pov) out << " pov";
    if (field.deparsed()) out << " deparsed";
    if (field.mau_phv_no_pack()) out << " mau_phv_no_pack";
    if (field.no_pack()) out << " no_pack";
    if (field.alwaysPackable) out << " always_packable";
    if (field.no_split()) out << " no_split";
    if (field.deparsed_bottom_bits()) out << " deparsed_bottom_bits";
    if (field.deparsed_to_tm()) out << " deparsed_to_tm";
    if (field.exact_containers()) out << " exact_containers";
    if (field.privatized()) out << " TPHV-priv";
    if (field.privatizable()) out << " PHV-priv";
    if (field.header_stack_pov_ccgf()) out << " header_stack_pov_ccgf";
    if (field.simple_header_pov_ccgf()) out << " simple_header_pov_ccgf";
    if (field.ccgf()) out << " ccgf=" << field.ccgf()->id << ':' << field.ccgf()->name;
    if (field.ccgf_fields().size()) {
        // aggregate widths of members in "container contiguous group fields"
        out << std::endl << '[';
        for (auto &f : field.ccgf_fields()) {
            out << '\t';
            if (f->is_ccgf() && !f->header_stack_pov_ccgf()) {
                // ccgf owner appears as member, phv_use_width = aggregate size of members
                out << f->id << ':' << f->name << '<' << f->size << ">*";
            } else {
                if (f->id == field.id) {
                    // originally f was ccgf owner but after container assignment
                    // ownership got terminated although f remains ccgf member of itself
                    out << f->id << ':' << f->name << '<' << f->size << ">#";
                } else {
                    out << f;
                }
            }
            out << std::endl;
        }
        out << ']';
    }
    return out;
}

std::ostream &PHV::operator<<(std::ostream &out, const PHV::Field *fld) {
    if (fld) return out << *fld;
    return out << "(nullptr)";
}

// ordered_set Field*
std::ostream &operator<<(std::ostream &out, const ordered_set<PHV::Field *>& field_set) {
    for (auto &f : field_set) {
        out << f << std::endl;
    }
    return out;
}

// ordered_set const Field*
std::ostream &operator<<(std::ostream &out, const ordered_set<const PHV::Field *>& field_set) {
    for (auto &f : field_set) {
        out << f << std::endl;
    }
    return out;
}

std::ostream &operator<<(std::ostream &out, const PhvInfo &phv) {
    out << "++++++++++ All Fields name[size]{range} (" << phv.num_fields() << ") ++++++++++"
        << std::endl
        << std::endl;
    //
    for (auto field : phv) {
         out << &field << std::endl;
    }
    return out;
}

std::ostream &operator<<(std::ostream &out, const PHV::Field_Ops &op) {
    switch (op) {
        case PHV::Field_Ops::NONE: out << "None"; break;
        case PHV::Field_Ops::R: out << 'R'; break;
        case PHV::Field_Ops::W: out << 'W'; break;
        case PHV::Field_Ops::RW: out << "RW"; break;
        default: out << "<Field_Ops " << int(op) << ">"; }
    return out;
}

namespace std {

ostream &operator<<(ostream &out, const list<::PHV::Field *>& field_list) {
    for (auto &f : field_list) {
        out << f << std::endl;
    }
    return out;
}

ostream &operator<<(ostream &out, const set<const ::PHV::Field *>& field_list) {
    for (auto &f : field_list) {
        out << f << std::endl;
    }
    return out;
}

}  // namespace std

// for calling from the debugger
void dump(const PhvInfo *phv) { std::cout << *phv; }
void dump(const PHV::Field *f) { std::cout << *f; }

const IR::Node* PhvInfo::DumpPhvFields::apply_visitor(const IR::Node *n, const char *) {
    LOG1("");
    LOG1("--- PHV FIELDS -------------------------------------------");
    LOG1("");
    LOG1("P: used in parser/deparser");
    LOG1("M: used in MAU");
    LOG1("R: referenced anywhere");
    LOG1("D: is deparsed");
    for (auto f : phv) {
        LOG1("(" <<
              (uses.is_used_parde(&f) ? "P" : " ") <<
              (uses.is_used_mau(&f) ? "M" : " ") <<
              (uses.is_referenced(&f) ? "R" : " ") <<
              (uses.is_deparsed(&f) ? "D" : " ") << ") " << /*f.externalName()*/
              f); }
    LOG1("");

    LOG1("--- PHV FIELDS WIDTH HISTOGRAM----------------------------");
    LOG1("\nINGRESS:");
    generate_field_histogram(INGRESS);
    LOG1("\nEGRESS:");
    generate_field_histogram(EGRESS);
    LOG1("\n");
    return n;
}

void PhvInfo::DumpPhvFields::generate_field_histogram(gress_t gress) const {
    if (!LOGGING(1)) return;
    std::map<int, size_t> size_distribution;
    size_t total_bits = 0;
    size_t total_fields = 0;
    for (auto field : phv) {
        if (field.gress == gress) {
            // Only report histogram for fields that aren't dead code eliminated
            if (uses.is_referenced(&field) || uses.is_deparsed(&field) || uses.is_used_mau(&field)
                    || uses.is_used_parde(&field)) {
                size_distribution[field.size] += 1;
                total_bits += field.size;
                total_fields++; } } }
    // Print histogram
    LOG1("Fields to be allocated: " << total_fields);
    LOG1("Bits to be allocated: " << total_bits);
    for (auto entry : size_distribution) {
        std::stringstream row;
        row << entry.first << "\t";
        for (size_t i = 0; i < entry.second; i++)
            row << "x";
        row << " (" << entry.second << ")";
        LOG1(row.str()); }
}
