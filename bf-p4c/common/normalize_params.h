#ifndef _COMMON_NORMALIZE_PARAMS_H_
#define _COMMON_NORMALIZE_PARAMS_H_

#include "frontends/common/resolveReferences/referenceMap.h"
#include "frontends/p4/typeMap.h"
#include "ir/ir.h"

/** At the P4 level, the TNA architecture provides an interface for users to
 * define custom parsers/controls/deparsers that are parameterized on
 * architecture-supplied inputs and outputs.  For example, a user might supply
 * the following ingress parser and ingress MAU control:
 *
 *  parser ingress_parser(
 *      packet_in pkt,
 *      out my_hdr_t parser_hdr,
 *      out my_meta_t ig_md,
 *      out ingress_intrinsic_metadata_t ig_intr_md);
 *
 *  control ingress_control(
 *      inout my_hdr_t mau_hdr,
 *      inout my_meta_t ig_md,
 *      in ingress_intrinsic_metadata_t ig_intr_md,
 *      in ingress_intrinsic_metadata_from_parser_t ig_intr_md_from_prsr,
 *      inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
 *      inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm);
 *
 * However, the `parser_hdr` value produced by the parser is actually the same
 * value passed as `mau_hdr` as input to the control.
 *
 *
 * This pass replaces the user-supplied parameter names (eg. `parser_hdr` and
 * `mau_hdr`) with the corresponding parameter names defined in the
 * architecture (`hdr`, in this case).
 *
 * These names are only changed internally; the original names are still
 * exposed to the control plane via the @name annotations attached in the
 * midend.  The one exception is the snapshot mechanism, which will need to
 * refer to the architecture-supplied parameter names when referencing PHV
 * fields.
 *
 * If the user defines the same parameter names as the architecture, then this
 * pass has no effect.  However, if the user defines other instances with the
 * same names as any of the architecture params, this pass raises an error, as
 * those names are reserved.
 */
// XXX(cole): Rather than producing an error, it would be better to rewrite the
// conflicting user-supplied instance names.
class NormalizeParams : public Modifier {
    // const P4::ReferenceMap*         refMap;
    // const P4::TypeMap*              typeMap;
    // const IR::ToplevelBlock*   toplevel;

    /// Maps (original) parameter node pointers for each block to the names
    /// that should replace them.
    using Renaming = ordered_map<const IR::Parameter*, cstring>;
    ordered_map<const IR::Node*, Renaming> renaming;

    Modifier::profile_t init_apply(const IR::Node* root) override;
    bool preorder(IR::P4Parser* parser) override;
    bool preorder(IR::P4Control* control) override;

 public:
    NormalizeParams() {}
};

#endif  /* _COMMON_NORMALIZE_PARAMS_H_ */
