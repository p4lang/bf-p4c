#include "bf-p4c/device.h"
#include "bf-p4c/midend/check_unsupported.h"
#include "frontends/p4/methodInstance.h"

namespace BFN {

bool CheckUnsupported::preorder(const IR::PathExpression* path_expression) {
    static const IR::Path SAMPLE3(IR::ID("sample3"), false);
    static const IR::Path SAMPLE4(IR::ID("sample4"), false);

    if (*path_expression->path == SAMPLE3 || *path_expression->path == SAMPLE4) {
        ::error(
            ErrorType::ERR_UNSUPPORTED,
            "Primitive %1% is not supported by the backend",
            path_expression->path);
        return false;
    }
    return true;
}

bool hasAtcamPragma(const IR::P4Table* const table_ptr) {
    for (const auto* annotation : table_ptr->annotations->annotations) {
        if ( annotation->name.name        .startsWith("atcam") ||
             annotation->name.originalName.startsWith("atcam")
           ) return true;
    }
    return false;
}

void CheckUnsupported::postorder(const IR::P4Table* const table_ptr) {
    if (const auto* const key_ptr = table_ptr->getKey()) {
        int LPM_count = 0, ternary_key_count = 0;
        size_t total_TCAM_key_bits = 0u;

        for (const auto* const key_element_ptr : key_ptr->keyElements) {
            if (    "lpm" == key_element_ptr->matchType->path->name) { ++LPM_count; }
            if ("ternary" == key_element_ptr->matchType->path->name) {
                ++ternary_key_count;
                const size_t size = table_ptr->getSizeProperty()->asUint64(),
                             this_TCAM_key_bits = key_element_ptr->expression->type->width_bits();

                total_TCAM_key_bits += this_TCAM_key_bits;

                LOG9("found ternary key " << '"' << key_element_ptr->expression->toString() <<
                     '"' << " of width " << this_TCAM_key_bits <<
                     " bits and table size = " << size);
            }
        }

        if (LPM_count > 1) {
            error(ErrorType::ERR_UNSUPPORTED, "%1%table %2% Cannot match on multiple fields using"
                  " the LPM match type.", table_ptr->srcInfo, table_ptr->name.originalName);
        }

        if (ternary_key_count > 0) {
            // P4_14 expresses ATCAM tables as TCAM tables with an ATCAM-specific pragma,
            //   so we need to be extra-careful not to error out erroneously on those,
            //   at least for so long as we are still supporting P4_14 inputs to this compiler.
            const bool has_ATCAM_pragma = hasAtcamPragma(table_ptr);
            if (has_ATCAM_pragma) return;  //  no further checks

            const size_t table_size = table_ptr->getSizeProperty()->asUint64();
            LOG5("found " << ternary_key_count << " ternary key(s) in a table with {total TCAM key"
                 " bits = " << total_TCAM_key_bits << "} and {table size = " << table_size << "}");

            const auto& MAU_spec = Device::mauSpec();

            const size_t inclusive_max_size_in_bits = MAU_spec.tcam_rows()    *
                                                      MAU_spec.tcam_columns() *
                                                      MAU_spec.tcam_width()   *
                                                      MAU_spec.tcam_depth()   *
                                                      Device::numStages();

            LOG9("TCAM inclusive_max_size_in_bits = " << inclusive_max_size_in_bits);

            const size_t table_size_times_total_TCAM_key_bits = table_size * total_TCAM_key_bits;

            if (table_size_times_total_TCAM_key_bits > inclusive_max_size_in_bits) {
                const size_t max_table_size = inclusive_max_size_in_bits / total_TCAM_key_bits;
                std::stringstream buf;
                buf << "The table '" << table_ptr->name.originalName << "' exceeds the "
                       "maximum size.  It has " << ternary_key_count << " ternary key"
                       << ((1==ternary_key_count)?"":"s") << " of total size " <<
                       total_TCAM_key_bits << " bits and a table size of " << table_size <<
                       " entries.  The resulting product (" << table_size_times_total_TCAM_key_bits
                       << ") exceeds the maximum supported size (" << inclusive_max_size_in_bits
                       << ") for tables with ternary keys on the current target.  "
                       "Largest usable table size: " << max_table_size << " entries.";

                /* // safe code
                   // ---------
                std::string local_string = buf.str();
                std::string* heap_string = new std::string(local_string);
                const char* const to_error_with = heap_string->c_str();
                ::error(to_error_with);
                */
                ::error(/* slightly risky */buf.str().c_str()/* slightly risky */);
            }
        }
    }
}

}  // namespace BFN
