#ifndef BF_P4C_PHV_ALLOC_SETTING_H_
#define BF_P4C_PHV_ALLOC_SETTING_H_

namespace PHV {

// AllocSetting holds various alloc settings.
struct AllocSetting {
    /// trivial allocation mode that
    /// (1) do minimal packing, i.e., pack fieldslices only when unavoidable.
    /// (2) assume that there were infinite number of containers.
    /// (3) no metadata or dark initialization, as if no_code_change mode is enabled.
    bool trivial_alloc = false;
    bool no_code_change = false;              // true if disable metadata and dark init.
    bool physical_liverange_overlay = false;  // true if allow physical liverange overlay.
    bool limit_tmp_creation = false;          // true if intermediate tmp value are limited.
    bool single_gress_parser_group = false;   // true if PragmaParserGroupMonogress enabled.
};

}  // namespace PHV

#endif /* BF_P4C_PHV_ALLOC_SETTING_H_ */
