#include "bf-p4c/phv/phv_fields.h"

#include <boost/optional.hpp>
#include <boost/range/adaptor/reversed.hpp>
#include <boost/range/irange.hpp>
#include <regex>
#include <string>
#include "bf-p4c/common/header_stack.h"
#include "bf-p4c/device.h"
#include "bf-p4c/ir/thread_visitor.h"
#include "bf-p4c/phv/phv_parde_mau_use.h"
#include "frontends/p4/toP4/toP4.h"
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
    aliasMap.clear();
    dummyPaddingNames.clear();
    externalNameMap.clear();
    metadata_overlay.clear();
    bridged_extracted_together.clear();
    alloc_done_ = false;
    pov_alloc_done = false;
    zeroContainers[0].clear();
    zeroContainers[1].clear();
    reverseMetadataDeps.clear();
    metadataDeps.clear();
    deparser_no_pack.clear();
    field_mutex.clear();
    constantExtractedInSameState.clear();
    sameStateConstantExtraction.clear();
}

void PhvInfo::add(
        cstring name, gress_t gress, int size, int offset, bool meta, bool pov,
        bool bridged, bool pad) {
    // Set the egress version of bridged fields to metadata
    if (gress == EGRESS && bridged)
        meta = true;
    if (all_fields.count(name)) {
        LOG3("Already added field; skipping: " << name);
        return; }
    LOG3("PhvInfo adding " << (pad ? "padding" : (meta ? "metadata" : "header")) << " field " <<
         name << " size " << size << " offset " << offset);
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

void PhvInfo::add_struct(
        cstring name,
        const IR::Type_StructLike *type,
        gress_t gress,
        bool meta,
        bool bridged,
        int offset) {
    BUG_CHECK(type, "No type for %1%", name);
    LOG3("PhvInfo adding " << (meta ? " metadata" : "header") << " for struct " << name);
    for (auto f : type->fields) {
        int size = f->type->width_bits();
        cstring f_name = name + '.' + f->name;
        if (f->type->is<IR::Type_StructLike>()) {
            auto* struct_type = f->type->to<IR::Type_StructLike>();
            add_struct(f_name, struct_type, gress, meta, bridged, offset);
        }
        if (size == 0)
            ::error("%1% Field %2% of size %3% not supported on %4%", f->srcInfo, f_name, size,
                    Device::name());
        bool isPad = f->getAnnotations()->getSingle("hidden") != nullptr;
        add(f_name, gress, size, offset -= size, meta, false, bridged, isPad);
    }
}

void PhvInfo::add_hdr(cstring name, const IR::Type_StructLike *type, gress_t gress, bool meta) {
    if (!type) {
        LOG3("PhvInfo no type for " << name);
        return; }
    if (all_structs.count(name)) {
        LOG3("Already added header; skipping: " << name);
        return; }
    LOG3("PhvInfo adding " << (meta ? "metadata" : "header") << " " << name);
    int start = by_id.size();
    int offset = 0;
    auto annot = type->getAnnotations();
    bool bridged = false;
    if (annot->getSingle("layout")) {
        LOG3("Candidate bridged metadata header (found layout annotation): " << name);
        bridged = true; }
    for (auto f : type->fields)
        offset += f->type->width_bits();
    for (auto f : type->fields) {
        int size = f->type->width_bits();
        cstring f_name = name + '.' + f->name;
        if (f->type->is<IR::Type_StructLike>()) {
            auto* struct_type = f->type->to<IR::Type_StructLike>();
            // Add fields inside nested structs.
            add_struct(f_name, struct_type, gress, meta, bridged, offset);
        }
        if (size == 0)
            ::error("%1% Field %2% of size %3% not supported on %4%", f->srcInfo, f_name, size,
                    Device::name());
        // "Hidden" annotation indicates padding introduced with bridged metadata fields
        bool isPad = f->getAnnotations()->getSingle("hidden") != nullptr;
        add(f_name, gress, size, offset -= size, meta, false, bridged, isPad); }
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
    if (auto *cast = e->to<IR::BFN::ReinterpretCast>())
        return field(cast->expr, bits);
    // HACK. midend changes zero extend cast into 0 ++ expr. When the
    // expression is used in a 'add' operation, the compiler does not perform
    // any transformation to eliminate the '++' operator.
    if (auto *concat = e->to<IR::Concat>()) {
        if (auto k = concat->left->to<IR::Constant>())
            if (k->value == 0)
                return field(concat->right, bits); }
    if (auto *sl = e->to<IR::Slice>()) {
        auto *rv = field(sl->e0, bits);
        if (rv && bits) {
            le_bitrange sliceRange = FromTo(sl->getL(), sl->getH());
            if (!bits->contains(sliceRange)) {
                warning("slice %d..%d invalid for field %s of size %d", sl->getL(), sl->getH(),
                        sl->e0, bits->size());
                return nullptr; }
            auto intersection = bits->intersectWith(sliceRange);
            *bits = le_bitrange(StartLen(intersection.lo, intersection.size())); }
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
    if (externalNameMap.count(name_)) {
        LOG4("  Looking up PHV field from external name map entry: " << name_);
        return externalNameMap.at(name_);
    }
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

    // PHV field names are fully qualified, but we sometimes look up a partial
    // name when it's unique.  Eg. using "ingress::bar.f" to find
    // "ingress::foo.bar.f" when there are no other "bar.f" suffixes.  This is
    // not common; it comes up mostly with aliases, which often use local
    // names.
    name = name_;
    StringRef prefixRef;
    StringRef suffixRef = name;
    if (auto* p = name.findstr("::")) {
        prefixRef = name.before(p);
        suffixRef = name.after(p + 2); }
    cstring prefix = prefixRef.toString();
    cstring suffix = suffixRef.toString();

    LOG4("Looking for PHV field " << name_);
    LOG4("    ...with prefix " << prefix);
    LOG4("    ...with suffix " << suffix);
    std::set<std::pair<cstring, const PHV::Field*>> matches;
    for (auto& kv : all_fields) {
        cstring name = kv.first;
        if (name.endsWith(suffix))
            LOG4("    ...found suffix: " << kv.first);
        if (name.startsWith(prefix) && name.endsWith(suffix))
            matches.insert(std::make_pair(kv.first, &kv.second)); }
    if (matches.size() > 1) {
        std::stringstream msg;
        for (auto& kv : matches)
            msg << " " << kv.first;
        LOG4("Name '" << name_ << "' could refer to:" << msg.str());
    } else if (matches.size() == 1) {
        return matches.begin()->second;
    }

    // XXX(seth): The warning spew from POV bits prior to allocatePOV() being
    // called is just too great. We need to improve how that's handled, but for
    // now, silence those warnings.
    if (!name.toString().endsWith(".$valid")) {
        LOG4("   ...can't find field " << name); }

    return nullptr;
}

void PhvInfo::allocatePOV(const BFN::HeaderStackInfo& stacks) {
    LOG3("BEGIN PhvInfo::allocatePOV");
    if (pov_alloc_done) BUG("trying to reallocate POV");
    pov_alloc_done = true;

    int size[2] = { 0, 0 };
    int stacks_num = 0;
    for (auto &stack : stacks) {
        StructInfo info = struct_info(stack.name);
        LOG3("    ...preanalyzing header stack " << stack.name << " (" << info.gress << ")");
        BUG_CHECK(!info.metadata, "metadata stack?");
        size[info.gress] += stack.size + stack.maxpush + stack.maxpop;  // size for $stkvalid
        size[info.gress] += stack.size;                                 // size for $valid
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
                // Create $stkvalid.
                add(stack.name + ".$stkvalid", gress, stack.size + stack.maxpush + stack.maxpop,
                    size[gress], true, true);
                PHV::Field *pov_stk = &all_fields[stack.name + ".$stkvalid"];
                pov_stk->set_no_split(true);
                LOG3("Creating HEADER STACK " << pov_stk);
                size[gress] -= stack.size + stack.maxpush + stack.maxpop;
                // Create $valid.
                for (int i : boost::irange(0, stack.size))
                    add(stack.name + "[" + std::to_string(i) + "].$valid",
                        gress, 1, --size[gress], false, true); } }

        BUG_CHECK(size[gress] == 0, "Error creating %1% POV fields.  %2% bits not created.",
                  cstring::to_cstring(gress), size[gress]); }
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

const std::vector<PHV::Field::alloc_slice>
PhvInfo::get_slices_in_container(const PHV::Container c) const {
    std::vector<PHV::Field::alloc_slice> rv;
    for (auto* field : fields_in_container(c)) {
        field->foreach_alloc([&](const PHV::Field::alloc_slice &alloc) {
            if (alloc.container != c) return;
            rv.push_back(alloc);
        });
    }
    return rv;
}

bitvec PhvInfo::bits_allocated(const PHV::Container c) const {
    bitvec ret_bitvec;
    for (auto* field : fields_in_container(c)) {
        if (field->alwaysPackable) continue;
        field->foreach_alloc([&](const PHV::Field::alloc_slice &alloc) {
            if (alloc.container != c) return;
            le_bitrange bits = alloc.container_bits();
            ret_bitvec.setrange(bits.lo, bits.size());
        }); }
    return ret_bitvec;
}

bitvec PhvInfo::bits_allocated(
        const PHV::Container c, const ordered_set<const PHV::Field*>& writes) const {
    bitvec ret_bitvec;
    auto& fields = fields_in_container(c);
    if (fields.size() == 0) return ret_bitvec;
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
                    return field_mutex(slice->field->id, alloc.field->id);
            });
            bool meta_overlay = std::any_of(
                write_slices_in_container.begin(), write_slices_in_container.end(),
                [&](const PHV::Field::alloc_slice* slice) {
                    return metadata_overlay(slice->field->id, alloc.field->id);
            });
            if (!mutually_exclusive && !meta_overlay)
                ret_bitvec.setrange(bits.lo, bits.size());
        }); }
    return ret_bitvec;
}

boost::optional<cstring> PhvInfo::get_alias_name(const IR::Expression* expr) const {
    if (auto* alias = expr->to<IR::BFN::AliasMember>()) {
        const PHV::Field* aliasSourceField = field(alias->source);
        BUG_CHECK(aliasSourceField, "Alias source field %s not found", alias->source);
        return aliasSourceField->name;
    } else if (auto* alias = expr->to<IR::BFN::AliasSlice>()) {
        const PHV::Field* aliasSourceField = field(alias->source);
        BUG_CHECK(aliasSourceField, "Alias source field %s not found", alias->source);
        return aliasSourceField->name;
    } else if (auto sl = expr->to<IR::Slice>()) {
        get_alias_name(sl->e0);
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
int PHV::Field::container_bytes(boost::optional<le_bitrange> optBits) const {
    BUG_CHECK(!alloc_i.empty(), "Trying to get PHV container bytes for unallocated field %1%",
              this);
    le_bitrange bits = optBits.get_value_or(StartLen(0, size));
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

void PHV::Field::foreach_byte(
        le_bitrange range,
        std::function<void(const PHV::FieldSlice&)> fn) const {
    le_bitrange window = StartLen(range.lo, 8);
    while (window.overlaps(range)) {
        // Create a Slice of the window intersected with the range.
        PHV::FieldSlice slice(this, *toClosedRange(window.intersectWith(range)));

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
bool PHV::Field::is_tphv_candidate(const PhvUse& uses) const {
    PHV::FieldSlice slice(this, StartLen(0, size));
    return slice.is_tphv_candidate(uses);
}

bool PHV::FieldSlice::is_tphv_candidate(const PhvUse& uses) const {
    // Privatized fields are the TPHV copies of header fields. Therefore, privatized fields are
    // always TPHV candidates.
    if (field_i->privatized()) return true;
    if (field_i->alwaysPackable) return false;  // __pad_ fields are not considered as tphv.
    // TODO(zma) derive these rather than hard-coding the name
    std::string f_name(field_i->name.c_str());
    if (f_name.find("compiler_generated_meta") != std::string::npos &&
        f_name.find("residual_checksum_") != std::string::npos) {
        return true;
    }
    // XXX(zma) somehow phv allocation can't derive this one
    if (f_name.find("$constant") != std::string::npos)
        return true;
    return !uses.is_used_mau(field_i, range_i) && !field_i->pov && !field_i->deparsed_to_tm() &&
        !field_i->is_digest() && (!field_i->metadata || uses.is_used_parde(field_i));
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

void PHV::Field::setStartBits(PHV::Size size, bitvec startPositions) {
    startBitsByContainerSize_i[size] = startPositions;
}

bitvec PHV::Field::getStartBits(PHV::Size size) const {
    if (!startBitsByContainerSize_i.count(size))
        return bitvec(0, int(size));
    return startBitsByContainerSize_i.at(size);
}

PHV::FieldSlice::FieldSlice(
        const Field* field,
        le_bitrange range) : field_i(field), range_i(range) {
    BUG_CHECK(0 <= range.lo, "Trying to create field slice with negative start");
    BUG_CHECK(range.size() <= field->size,
            "Trying to create field slice larger than field");

    // Calculate relative alignment for this field slice.
    if (field->alignment) {
        le_bitrange field_range = StartLen(field->alignment->littleEndian, field->size);
        le_bitrange slice_range = field_range.shiftedByBits(range_i.lo)
            .resizedToBits(range_i.size());
        alignment_i = FieldAlignment(slice_range);
        if (field->name == "ingress::mtel_least_int.start_index" ||
                field->name == "ingress::mtel_least_int.next_index")
            LOG4("Adjusting alignment of field " << field->name << " to " << *alignment_i <<
                    " for slice " << range);
    }

    // The valid starting bits (by container size C) for a slice s[Y:X]
    // equal the valid bits for the field shifted by X mod C.  For example,
    // if a 12b field f can start at bits 0 and 8 in a 16b container, then
    // f[11:8] can start at bits 0 and 8.
    for (auto size : Device::phvSpec().containerSizes())
        for (auto idx : field->getStartBits(size))
            startBitsByContainerSize_i[size].setbit((idx + range.lo) % int(size));

    // Calculate valid container range for this slice by shrinking
    // the valid range of the field by the size of the "tail"
    // (i.e. the least significant bits) not in this slice.
    if (field_i->validContainerRange_i == ZeroToMax()) {
        validContainerRange_i = ZeroToMax();
    } else {
        int new_size = field_i->validContainerRange_i.size() - range.lo;
        validContainerRange_i = field_i->validContainerRange_i.resizedToBits(new_size); }
}

void PHV::FieldSlice::setStartBits(PHV::Size size, bitvec startPositions) {
    startBitsByContainerSize_i[size] = startPositions;
}

bitvec PHV::FieldSlice::getStartBits(PHV::Size size) const {
    if (!startBitsByContainerSize_i.count(size))
        return bitvec(0, int(size));
    return startBitsByContainerSize_i.at(size);
}

void PHV::Field::updateValidContainerRange(nw_bitrange newValidRange) {
    LOG3("Inferred valid container range " << newValidRange <<
         " for field " << name);

    const auto intersection = validContainerRange_i.intersectWith(newValidRange);
    if (intersection.empty()) {
        ::error("Inferred valid container ranges %1% and %2% for field %3% "
                "which cannot both be satisfied for a field of size %4%b",
                cstring::to_cstring(validContainerRange_i),
                cstring::to_cstring(newValidRange), name, size);
        return;
    }

    validContainerRange_i = *toClosedRange(intersection);
}

bool PHV::Field::no_split() const {
    for (const auto& range : no_split_ranges_i) {
        if (range.size() == size) {
            return true; } }
    return false;
}

void PHV::Field::set_no_split(bool b) {
    if (b) {
        set_no_split_at(le_bitrange(StartLen(0, size)));
    } else {
        no_split_ranges_i.clear();
    }
}

bool PHV::Field::no_split_at(int pos) const {
    // Note: A constaint that requires splitting a field at a specific bit
    // position means that we are allowed to split at the lsb position.
    // For example:
    //    x[63:0] = y[63:0] + 1
    //    x and y must be split into slices as [63:32] and [31:0].
    //    When creating slices, slicing at bit position 32 should be allowed.
    return std::any_of(
            no_split_ranges_i.begin(), no_split_ranges_i.end(), [&] (const le_bitrange& r) {
                return r.contains(pos) && r.lo != pos; });
}

void PHV::Field::set_no_split_at(le_bitrange range) {
    no_split_ranges_i.push_back(range);
}

//***********************************************************************************
//
// CollectPhvInfo implementation.
//
//***********************************************************************************

class ClearPhvInfo : public Inspector {
    PhvInfo& phv;
    bool preorder(const IR::BFN::Pipe*) override {
        phv.clear();
        return false;
    }

 public:
    explicit ClearPhvInfo(PhvInfo& phv) : phv(phv) { }
};

/** Populates a PhvInfo object with Fields for each PHV-backed object in the
 * program (header instances, TempVars, etc.), with the exception of POV
 * fields, which are created by the AllocatePOVBits pass.
 *
 * Note that this pass also collects field information for alias sources by
 * explicitly visiting the `source` children of AliasMembers and AliasSlices.
 * In this mode (i.e. when @gress is supplied to the constructor), the internal
 * data structures are NOT cleared in init_apply.
 */
class CollectPhvFields : public Inspector {
    PhvInfo& phv;

    // WARNING(cole): CollectPhvFields is usually invoked on an entire IR, not
    // a subtree, which means that we can get the gress from
    // VisitingThread(this).  However, AliasMember and AliasSlice nodes have
    // untraversed pointers to the alias sources, which we need to get PHV info
    // for, as the allocation of their associated alias destinations will be
    // copies to the sources in AddAliasAllocation.
    //
    // In order to avoid code duplication, CollectPhvFields can be supplied
    // with a thread.  If present, (a) use this instead of
    // VisitingThread(this), and (b) don't clear the phv object in init_apply.
    //
    // This seems needlessly complex, but I can't think of a better way.

    /// Provided at construction when the visitor is intended to be invoked on
    /// a subtree, rather than the entire IR.  If not present, the gress is
    /// acquired from VisitingThread(this), which looks up the gress from the
    /// enclosing IR::BFN::Pipe.  This never changes after construction.
    boost::optional<gress_t> gress;

    /// Tracks the header/metadata instances that have been added, to avoid
    /// duplication.
    ordered_set<cstring> seen;

    /// @returns the input gress (at construction) if provided, or
    /// VisitingThread(this) if not.
    gress_t getGress() const {
        auto rv = gress ? *gress : VisitingThread(this);
        // FIXME: for now treat GHOST thread as INGRESS for phv allocation
        return rv == GHOST ? INGRESS : rv;
    }

    Visitor::profile_t init_apply(const IR::Node* root) override {
        auto rv = Inspector::init_apply(root);

        // Only clear if this is a new pass, i.e. gress == boost::none.
        if (!gress) {
            seen.clear();
            LOG3("Begin CollectPhvFields");
        } else {
            LOG3("Begin CollectPhvFields (recursive)"); }

        return rv;
    }

    /// Collect field information for alias sources.
    bool preorder(const IR::BFN::AliasMember* alias) override {
        alias->source->apply(CollectPhvFields(phv, getGress()));
        return true;
    }

    /// Collect field information for alias sources.
    bool preorder(const IR::BFN::AliasSlice* alias) override {
        alias->source->apply(CollectPhvFields(phv, getGress()));
        return true;
    }

    bool preorder(const IR::Header* h) override {
        // Skip headers that have already been visited.
        if (seen.find(h->name) != seen.end()) return false;
        seen.insert(h->name);

        int start = phv.by_id.size();
        phv.add_hdr(h->name.name, h->type, getGress(), false);
        int end = phv.by_id.size();

        // Ensure that the header hasn't been seen before
        auto it = std::find_if(phv.simple_headers.begin(),
                      phv.simple_headers.end(),
                      [&h](const std::pair<cstring, PhvInfo::StructInfo>& hdr)
                      { return hdr.first == h->name.name; });
        BUG_CHECK(it == phv.simple_headers.end(),
            "Header %1% already seen!", h->name.name);

        // Add the header to the simple_headers vector, as they
        // are seen in the program order
        phv.simple_headers.emplace_back(
            h->name.name,
            PhvInfo::StructInfo(false, getGress(), start, end - start));

        return false;
    }

    bool preorder(const IR::HeaderStack* h) override {
        // Skip headers that have already been visited.
        if (seen.find(h->name) != seen.end()) return false;
        seen.insert(h->name);

        if (!h->type) return false;
        char buffer[16];
        int start = phv.by_id.size();
        for (int i = 0; i < h->size; i++) {
            snprintf(buffer, sizeof(buffer), "[%d]", i);
            phv.add_hdr(h->name.name + buffer, h->type, getGress(), false); }
        int end = phv.by_id.size();
        LOG3("Adding header stack " << h->name);
        phv.all_structs.emplace(
            h->name.name,
            PhvInfo::StructInfo(false, getGress(), start, end - start));
        return false;
    }

    bool preorder(const IR::Metadata* h) override {
        // Skip headers that have already been visited.
        if (seen.find(h->name) != seen.end()) return false;
        seen.insert(h->name);

        phv.add_hdr(h->name.name, h->type, getGress(), true);
        return false;
    }

    bool preorder(const IR::TempVar* tv) override {
        phv.addTempVar(tv, getGress());

        // bridged_metadata_indicator must be placed in 8-bit container
        if (tv->name.endsWith("^bridged_metadata_indicator")) {
            PHV::Field* f = phv.field(tv);
            BUG_CHECK(f, "No PhvInfo entry for a field we just added?");
            f->set_exact_containers(true);
            f->set_no_pack(true);
            f->set_no_split(true);
        }
        // A field that ends with PHV::Field::TPHV_PRIVATIZE_SUFFIX is the TPHV copy of a header
        // field, produced during the Privatization pass. This field must be marked appropriately as
        // privatized.
        if (tv->name.endsWith(PHV::Field::TPHV_PRIVATIZE_SUFFIX)) {
            PHV::Field* f = phv.field(tv);
            BUG_CHECK(f, "No PhvInfo entry for a field we just added?");
            f->set_privatized(true);
        }

        return false;
    }

    void postorder(const IR::BFN::LoweredParser*) override {
        BUG("Running CollectPhvInfo after the parser IR has been lowered; "
            "this will produce invalid results.");
    }

    void end_apply() override {
        for (auto& f : phv) {
            std::string f_name(f.name.c_str());
            if (f_name.find("compiler_generated_meta") != std::string::npos
             && f_name.find("residual_checksum_") != std::string::npos) {
                f.set_exact_containers(true);
                f.set_no_pack(true);
                f.set_no_split(true);
            }
            if (f_name == "ingress::ig_intr_md_for_dprsr.digest_type")
                f.set_no_pack(true);
        }
    }

 public:
    explicit CollectPhvFields(PhvInfo& phv, boost::optional<gress_t> gress = boost::none)
    : phv(phv), gress(gress) { }
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
        auto* bufferSource = extract->source->to<IR::BFN::InputBufferRVal>();
        if (!bufferSource) return false;

        auto lval = extract->dest->to<IR::BFN::FieldLVal>();
        if (!lval) return false;

        auto* fieldInfo = phv.field(lval->field);
        if (!fieldInfo) {
            ::warning("No allocation for field %1%", extract->dest);
            return false;
        }

        // The alignment required for a parsed field is determined by the
        // position from which it's read from the wire.
        const auto extractedBits = bufferSource->range();
        const auto alignment = FieldAlignment(extractedBits);
        LOG3("A. Updating alignment of " << fieldInfo->name << " to " << alignment);
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
            LOG3("B. Updating alignment of " << ingressFieldInfo->name << " to " << alignment);
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
            auto* emit = emitPrimitive->to<IR::BFN::EmitField>();
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
            LOG3("C. Updating alignment of " << fieldInfo->name << " to " << emittedBits);
            fieldInfo->updateAlignment(FieldAlignment(emittedBits));
            currentBit += fieldInfo->size;
        }

        return false;
    }

    PhvInfo& phv;
};


/** Mark certain intrinsic metadata fields as invalidate_from_arch so that
 * we don't initialize them in the parser (see ComputeInitZeroContainers pass
 * in lower_parser.cpp)
 *
 * "Metadata is always considered to be valid. This is further explained in
 * Section 2.2.1. Metadata instances are initialized to 0 by default."
 *
 * For Tofino applications, we deviated from the spec for a few user-accessible
 * intrinsic metadata fields that are read at the deparser, because a valid
 * value of 0 has undesired behavior at the deparser (see field list below).
 *
 * Note that Glass does not expose the mirror field list type as a user-facing
 * field, but that may also apply here. (The learning digest type may also
 * apply here too.)
 *
 * All other metadata fields (intrinsic and user) should have their container
 * valid bit set coming out of the parser.
 *
 * P4_16 changed the semantic to be such that uninitialized metadata has an
 * undefined value.
 */

class AddIntrinsicConstraints : public Inspector {
    PhvInfo& phv;

    std::vector<std::pair<cstring, cstring>> invalidate_fields_from_arch() {
        static std::vector<std::pair<cstring, cstring>> rv =
           {{ "ig_intr_md_for_tm", "mcast_grp_a" },
            { "ig_intr_md_for_tm", "mcast_grp_b" },
            { "eg_intr_md", "egress_port" },
            { "ig_intr_md_for_tm", "ucast_egress_port" },
            { "ig_intr_md_for_dprsr", "resubmit_type" },
            { "ig_intr_md_for_dprsr", "digest_type" },
            { "g_intr_md_for_dprsr", "mirror_type"}
           };

        return rv;
    }

    profile_t init_apply(const IR::Node* root) override {
        for (auto& f : phv) {
            if (f.pov) continue;

            for (auto& intr : {"ingress::ig_intr_md", "egress::eg_intr_md"}) {
                std::string f_name(f.name.c_str());
                if (f_name.find(intr) != std::string::npos) {
                    f.set_intrinsic(true);
                    LOG1("\tMarking field " << f.name << " as intrinsic");
                }
            }

            if (Device::currentDevice() == Device::TOFINO) {
                for (auto& kv : invalidate_fields_from_arch()) {
                    std::string f_name(f.name.c_str());
                    if (f_name.find(kv.first) != std::string::npos
                        && f_name.find(kv.second) != std::string::npos) {
                        f.set_no_pack(true);
                        f.set_invalidate_from_arch(true);
                        LOG1("\tMarking field " << f.name << " as invalidate from arch");
                    }
                }
            }
        }
        return Inspector::init_apply(root);
    }

 public:
    explicit AddIntrinsicConstraints(PhvInfo& phv) : phv(phv) { }
};


/** Sets constraint properties in PHV::Field objects based on constraints
 * induced by the parser/deparser.
 */
class CollectPardeConstraints : public Inspector {
    PhvInfo& phv;

    // If two adjacent fields in deparser are predicated by different POV bits,
    // we cannot pack them in the same container (deparser can only deparse whole
    // container, not byte in container).
    bool preorder(const IR::BFN::Deparser* deparser) override {
        const PHV::Field* prev_field = nullptr;
        const PHV::Field* prev_pov_bit = nullptr;

        for (auto prim : deparser->emits) {
            if (auto ef = prim->to<IR::BFN::EmitField>()) {
                auto curr_field = phv.field(ef->source->field);
                auto curr_pov_bit = phv.field(ef->povBit->field);

                if (prev_pov_bit && (prev_pov_bit != curr_pov_bit)) {
                    phv.addDeparserNoPack(prev_field, curr_field);
                    LOG1("\tMarking " << prev_field->name << " and "
                                      << curr_field->name << " as deparser_no_pack");
                }

                prev_field = curr_field;
                prev_pov_bit = curr_pov_bit;
            }
        }

        return true;
    }

    void postorder(const IR::BFN::EmitChecksum* checksum) override {
        for (const auto* flval : checksum->sources) {
            PHV::Field* f = phv.field(flval->field);
            BUG_CHECK(f != nullptr, "Field not created in PhvInfo");
            f->set_is_checksummed(true);
            LOG1("Checksummed field: " << f);
        }
    }

    void postorder(const IR::BFN::EmitField* emit) override {
        auto* src_field = phv.field(emit->source->field);
        BUG_CHECK(src_field, "Deparser Emit with a non-PHV source: %1%",
                  cstring::to_cstring(emit));
        // XXX(cole): These two constraints will be subsumed by deparser schema.
        src_field->set_deparsed(true);
        src_field->set_exact_containers(true);

        if (!src_field->privatized()) return;

        // The original PHV copy of privatized fields must be explicitly identified as privatizable
        // and its exact containers property must be set to true.
        boost::optional<cstring> newString = src_field->getPHVPrivateFieldName();
        if (!newString)
            BUG("Did not find PHV version of privatized field %1%", src_field->name);
        auto* phv_field = phv.field(*newString);
        BUG_CHECK(phv_field, "PHV version of privatized field %1% not found", src_field->name);
        phv_field->set_exact_containers(true);
        phv_field->set_privatizable(true);
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
        LOG3("D. Updating alignment of " << f->name << " to " <<
                FieldAlignment(le_bitrange(StartLen(0, f->size))));
        f->updateAlignment(FieldAlignment(le_bitrange(StartLen(0, f->size))));
        f->set_deparsed_bottom_bits(true);
        f->set_deparsed_to_tm(true);
        f->set_no_split(true);

        BUG_CHECK(f->size <= 32, "The architecture requires that field %1% not be split "
                  "across PHV containers, but the field is larger than the largest PHV container.",
                  cstring::to_cstring(f));
    }

    void postorder(const IR::BFN::Digest* digest) override {
        // TODO:
        // IR futures: distinguish each digest as an enumeration: learning, mirror, resubmit
        // as they have differing constraints -- bottom-bits, bridge-metadata mirror packing
        // learning, mirror field list in bottom bits of container, e.g.,
        // 301:ingress::$learning<3:0..2>
        // 590:egress::$mirror<3:0..2> specifies 1 of 8 field lists
        // currently, IR::BFN::Digest node has a string field to distinguish them by name
        if (digest->name != "learning" && digest->name != "mirror"
            && digest->name != "resubmit")
            return;

        PHV::Field* f = phv.field(digest->selector->field);
        BUG_CHECK(f != nullptr, "Field not created in PhvInfo");
        f->set_deparsed_bottom_bits(true);
        f->set_no_split(true);
        f->set_no_pack(true);
        f->set_is_digest(true);

        for (auto fieldList : digest->fieldLists) {
            for (auto flval : fieldList->sources) {
                if (auto f = phv.field(flval->field))
                    f->set_is_digest(true);
            }
        }

        if (digest->name == "resubmit") {
            LOG3("\t resubmit metadata field (" << f << ") is set to be "
                 << "exact container and is_marshaled.");
            for (auto fieldList : digest->fieldLists) {
                LOG3("\t.....resubmit metadata field list....." << fieldList);
                for (auto resubmit_field_expr : fieldList->sources) {
                    PHV::Field* resubmit_field = phv.field(resubmit_field_expr->field);
                    if (resubmit_field) {
                        if (resubmit_field->metadata) {
                            resubmit_field->set_exact_containers(true);
                            resubmit_field->set_is_marshaled(true);
                            LOG3("\t\t" << resubmit_field);
                        }
                    } else {
                        BUG("\t\t resubmit field does not exist: %1%",
                            resubmit_field_expr->field);
                    }
                }
            }
            return;
        }

        if (digest->name == "learning") {
            // Add byte-aligned constraint to metadata field in learning field_list
            // TODO(yumin): This constraint can be relaxed to be no_pack in a same byte.
            for (auto fieldList : digest->fieldLists) {
                for (auto fieldListEntry : fieldList->sources) {
                    auto fieldInfo = phv.field(fieldListEntry->field);
                    if (fieldInfo->metadata) {
                        LOG3("E. Updating alignment of metadata field " << fieldInfo->name << " to "
                                << FieldAlignment(le_bitrange(StartLen(0, fieldInfo->size))));
                        fieldInfo->updateAlignment(
                                FieldAlignment(le_bitrange(StartLen(0, fieldInfo->size))));
                        LOG3(fieldInfo << " is marked to be byte_aligned "
                             "because it's in a field_list and digested.");
                    }
                }
            }

            if (LOGGING(3)) {
                for (auto fieldList : digest->fieldLists) {
                    LOG3("\t.....learning field list..... ");
                    for (auto fieldListEntry : fieldList->sources) {
                        auto fieldInfo = phv.field(fieldListEntry->field);
                        if (fieldInfo)
                            LOG3("\t\t" << fieldInfo);
                        else
                            LOG3("\t\t" <<"-f?");
                    }
                }
            }
            return;
        }

        // For mirror digests, associate the mirror field with its field list,
        // which is used during constraint checks for bridge-metadata phv
        // allocation.
        LOG3(".....mirror fields in field list " << f->id << ":" << f->name);
        int fieldListIndex = 0;
        for (auto fieldList : digest->fieldLists) {
            LOG3("\t.....mirror metadata field list....." << fieldList);

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

            // mirror_field_list fields are marked as is_marshaled, so that
            // the phv allocation will make sure that the allocation field can be
            // serialized without leaving any padding within the field.
            // XXX(yumin): One special case is that, on both gresses,
            // compiler_generated_meta.mirror_id must go to [H] and
            // compiler_generated_meta.mirror_source must go to [B].
            // This constraint is handled in the phv allocation.
            for (auto mirroredField : fieldList->sources) {
                PHV::Field* mirror = phv.field(mirroredField->field);
                if (mirror) {
                    if (mirror->metadata) {
                        mirror->mirror_field_list = {f, fieldListIndex};
                        mirror->set_exact_containers(true);
                        mirror->set_is_marshaled(true);
                        LOG3("\t\t" << mirror);
                    }
                } else {
                    BUG("\t\t mirror field does not exist: %1%", mirroredField->field);
                }
                fieldListIndex++;
            }
        }
    }

 public:
    explicit CollectPardeConstraints(PhvInfo& phv) : phv(phv) { }
};

void AddAliasAllocation::addAllocation(
        PHV::Field* aliasSource,
        const PHV::Field* aliasDest,
        le_bitrange range) {
    BUG_CHECK(aliasSource->size == range.size(), "Alias source (%1%b) and destination (%2%b) of "
              "different sizes", aliasSource->size, range.size());

    // Avoid adding allocation for the same field more than once.
    if (seen.count(aliasSource))
        return;
    seen.insert(aliasSource);

    // Add allocation.
    aliasDest->foreach_alloc(range, [&](const PHV::Field::alloc_slice& alloc) {
        PHV::Field::alloc_slice new_slice(
            aliasSource,
            alloc.container,
            alloc.field_bit - range.lo,
            alloc.container_bit,
            alloc.width);
        LOG5("Adding allocation slice for aliased field: " << aliasSource << " " << new_slice);
        aliasSource->add_alloc(new_slice);
        phv.add_container_to_field_entry(alloc.container, aliasSource);
    });
}

bool AddAliasAllocation::preorder(const IR::BFN::AliasMember* alias) {
    // Recursively add any aliases in the source.
    alias->source->apply(AddAliasAllocation(phv));

    // Then add this alias.
    PHV::Field* aliasSource = phv.field(alias->source);
    const PHV::Field* aliasDest = phv.field(alias);
    addAllocation(aliasSource, aliasDest, StartLen(0, aliasSource->size));
    return true;
}

bool AddAliasAllocation::preorder(const IR::BFN::AliasSlice* alias) {
    // Recursively add any aliases in the source.
    alias->source->apply(AddAliasAllocation(phv));

    // Then add this alias.
    PHV::Field* aliasSource = phv.field(alias->source);
    const PHV::Field* aliasDest = phv.field(alias);
    addAllocation(aliasSource, aliasDest, FromTo(alias->getL(), alias->getH()));
    return true;
}

void AddAliasAllocation::end_apply() {
    // Later passes assume that PHV allocation is sorted in field bit order
    // MSB first
    for (auto& f : phv)
        f.sort_alloc();
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
            bool isTstamp = name.endsWith("global_tstamp") && f.is_intrinsic();
            bool isVersion = name.endsWith("global_ver") && f.is_intrinsic();
            if (isTstamp || isVersion) {
                LOG2("Setting exact_containers for " << f.name);
                f.set_exact_containers(true); } }
    }

 public:
    explicit MarkTimestampAndVersion(PhvInfo& phv) : phv_i(phv) { }
};

// Map field to the parser states in which they are extracted
struct MapFieldToParserStates : public ParserInspector {
    PhvInfo& phv;

    explicit MapFieldToParserStates(PhvInfo& phv) : phv(phv) { }

    bool preorder(const IR::BFN::Extract* extract) override {
        auto lval = extract->dest->to<IR::BFN::FieldLVal>();
        if (!lval) return true;

        if (auto* f = phv.field(lval->field)) {
            auto state = findContext<IR::BFN::ParserState>();
            phv.field_to_parser_states[f->name].insert(state->name);
        }

        return true;
    }
};

Visitor::profile_t CollectBridgedExtractedTogetherFields::init_apply(const IR::Node* root) {
    auto& matrix = phv_i.getBridgedExtractedTogether();
    matrix.clear();

    for (auto kv : extractedTogether) {
        const auto* f1 = phv_i.field(kv.first);
        // Fields may be eliminated by dead code elimination. So, no need for these bug checks.
        if (!f1) continue;
        for (auto fName : kv.second) {
            const auto* f2 = phv_i.field(fName);
            if (!f2) continue;
            // Ignore extracted together for padding fields.
            if (f1->alwaysPackable || f2->alwaysPackable) continue;
            matrix(f1->id, f2->id) = true;
        }
    }

    return Inspector::init_apply(root);
}

CollectPhvInfo::CollectPhvInfo(PhvInfo& phv) {
    addPasses({
        new ClearPhvInfo(phv),
        new CollectPhvFields(phv),
        new AllocatePOVBits(phv),
        new MapFieldToParserStates(phv),
        new CollectPardeConstraints(phv),
        new ComputeFieldAlignments(phv),
        new AddIntrinsicConstraints(phv),
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
    if (field.is_intrinsic()) out << " intrinsic";
    if (field.mirror_field_list.member_field)
        out << " mirror%{"
            << field.mirror_field_list.member_field->id
            << ":" << field.mirror_field_list.member_field->name
            << "#" << field.mirror_field_list.field_list
            << "}%";
    if (field.pov) out << " pov";
    if (field.is_deparser_zero_candidate())
        out << " deparsed-zero";
    else if (field.deparsed())
        out << " deparsed";
    if (field.mau_phv_no_pack()) out << " mau_phv_no_pack";
    if (field.no_pack()) out << " no_pack";
    if (field.alwaysPackable) out << " always_packable";
    if (field.no_split()) {
        out << " no_split";
    } else if (field.no_split_ranges().size() > 0) {
        for (const auto& range : field.no_split_ranges()) {
            out << " no_split_at" << range; } }
    if (field.deparsed_bottom_bits()) out << " deparsed_bottom_bits";
    if (field.deparsed_to_tm()) out << " deparsed_to_tm";
    if (field.exact_containers()) out << " exact_containers";
    if (field.used_in_wide_arith()) out << " wide_arith";
    if (field.privatized()) out << " TPHV-priv";
    if (field.privatizable()) out << " PHV-priv";
    if (Device::currentDevice() == Device::JBAY) {
        if (field.is_mocha_candidate()) out << " mocha";
        if (field.is_dark_candidate()) out << " dark";
    }
    if (field.is_checksummed()) out << " checksummed";
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

std::ostream &operator<<(std::ostream &out, const PHV::FieldAccessType &op) {
    switch (op) {
        case PHV::FieldAccessType::NONE: out << "None"; break;
        case PHV::FieldAccessType::R: out << 'R'; break;
        case PHV::FieldAccessType::W: out << 'W'; break;
        case PHV::FieldAccessType::RW: out << "RW"; break;
        default: out << "<FieldAccessType " << int(op) << ">"; }
    return out;
}

namespace PHV {

std::ostream &operator<<(std::ostream &out, const PHV::FieldSlice& fs) {
    if (fs.field() == nullptr) {
        out << "-field-slice-of-null-field-ptr-";
        return out; }

    auto& field = *fs.field();
    out << field.name << "<" << field.size << ">";
    if (fs.alignment())
        out << " ^" << fs.alignment()->littleEndian;
    if (fs.validContainerRange() != ZeroToMax())
        out << " ^" << fs.validContainerRange();
    if (field.bridged) out << " bridge";
    if (field.metadata) out << " meta";
    if (field.is_intrinsic()) out << " intrinsic";
    if (field.mirror_field_list.member_field)
        out << " mirror%{"
            << field.mirror_field_list.member_field->id
            << ":" << field.mirror_field_list.member_field->name
            << "#" << field.mirror_field_list.field_list
            << "}%";
    if (field.pov) out << " pov";
    if (field.is_deparser_zero_candidate())
        out << " deparsed-zero";
    else if (field.deparsed())
        out << " deparsed";
    if (field.no_pack()) out << " no_pack";
    if (field.no_split()) out << " no_split";
    if (field.deparsed_bottom_bits()) out << " deparsed_bottom_bits";
    if (field.deparsed_to_tm()) out << " deparsed_to_tm";
    if (field.exact_containers()) out << " exact_containers";
    if (field.used_in_wide_arith()) out << " wide_arith";
    if (field.privatized()) out << " TPHV-priv";
    if (field.privatizable()) out << " PHV-priv";
    out << " [" << fs.range().lo << ":" << fs.range().hi << "]";
    return out;
}

std::ostream &operator<<(std::ostream &out, const PHV::FieldSlice* fs) {
    if (fs)
        out << *fs;
    else
        out << "-null-field-slice ";
    return out;
}

}   // namespace PHV

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
              f << " (" << f.gress << ")") ; }
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
