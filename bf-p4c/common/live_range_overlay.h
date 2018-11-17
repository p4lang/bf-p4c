#ifndef _LIVE_RANGE_OVERLAY_H_
#define _LIVE_RANGE_OVERLAY_H_

#include "ir/ir.h"
#include "lib/log.h"
#include "lib/symbitmatrix.h"
#include "bf-p4c/common/field_defuse.h"
#include "bf-p4c/mau/table_dependency_graph.h"
#include "bf-p4c/phv/pragma/phv_pragmas.h"

/** @brief Find fields that have mutually exclusive live ranges.
 *
 * For each field f, find all units u where f is definitely dead.  Field f is
 * dead at unit u if, for every read of f that happens (strictly) after u at
 * some unit ur, there exists a unit uw that writes f that happens (strictly)
 * between u and ur.
 *
 * Fields that are not definitely dead are possibly life.  Fields that are not
 * possibly live in the same units can be overlaid.
 *
 * Note that this pass can be run before and after table placement.  Before
 * table placement, the "happens before" relation is conservative:
 * `happens_before(t1, t2)` is only true when t1 *must* happen strictly before
 * *t2* because of dependencies between t1 and t2 (eg. t1 writes a field that
 * t2 reads).
 *
 * After table placement, `happens_before(t1, t2)` returns true if t1 is
 * assigned to an earlier stage than t2.
 */
class LiveRangeOverlay : public Inspector {
 private:
    PhvInfo                                 &phv;
    DependencyGraph                         &dg;
    FieldDefUse                             &defuse;
    const PragmaNoOverlay                   &noOverlay;
    SymBitMatrix                            &overlay;
    const ordered_set<const PHV::Field*>    &noInitFields;

    ordered_set<const IR::BFN::Unit *> all_ingress_units;
    ordered_set<const IR::BFN::Unit *> all_egress_units;
    ordered_set<const IR::BFN::Unit *> all_ghost_units;

    profile_t init_apply(const IR::Node* root) override {
        profile_t rv = Inspector::init_apply(root);
        all_ingress_units.clear();
        all_egress_units.clear();
        all_ghost_units.clear();
        return rv;
    }

    void postorder(const IR::MAU::Table *u) override {
        if (u->gress == INGRESS)
            all_ingress_units.insert(u);
        else if (u->gress == EGRESS)
            all_egress_units.insert(u);
        else if (u->gress == GHOST)
            all_ghost_units.insert(u);
        else
            BUG("Unexpected gress."); }
    void postorder(const IR::BFN::ParserState *u) override {
        if (u->gress == INGRESS)
            all_ingress_units.insert(u);
        else if (u->gress == EGRESS)
            all_egress_units.insert(u);
        else
            BUG("Unexpected gress."); }
    void postorder(const IR::BFN::Deparser *u) override {
        if (u->gress == INGRESS)
            all_ingress_units.insert(u);
        else if (u->gress == EGRESS)
            all_egress_units.insert(u);
        else
            BUG("Unexpected gress."); }
    void end_apply() override;

    /** True if @u1 must happen before @u2.
     *
     * The happens-before relation over units is as follows:
     *  - ingress happens before egress
     *  - parse states happen before tables
     *  - tables happen before deparsers
     *
     * For elements of the same kind:
     *  - parse states happen at the same time
     *  - if tables have not yet been assigned stages, then use the dependency
     *    graph happens-before relation
     *  - otherwise, t1 happens before t2 if it has been assigned to an earlier
     *    stage
     *  - deparsers happen at the same time.
     */
    bool happens_before(const IR::BFN::Unit *u1, const IR::BFN::Unit *u2) const;

    /** The `happens_before` method is conservative before table placement.  Hence,
     * `happens_before(x, y)` if and only if x definitely happens before y.
     * `may_happen_before(y, x)` iff `!happens_before(x, y)`.
     */
    bool may_happen_before(const IR::BFN::Unit *x, const IR::BFN::Unit *y) const;

    bool is_dead_at(const PHV::Field &f, const IR::BFN::Unit *u) const;

    /** Visual representation of the live ranges calculated for various metadata fields. Uses
      * logging-level 1.
      */
    void printLiveRanges(ordered_map<int, ordered_set<const IR::BFN::Unit *>>& lm);

 public:
    /** Build a LiveRangeOverlay Inspector.
     *
     * @input @phv
     * @input @dg
     * @input @defuse
     * @output @rv
     */
    explicit LiveRangeOverlay(
        PhvInfo &phv,
        DependencyGraph &dg,
        FieldDefUse &defuse,
        const PHV::Pragmas& pragmas)
    : phv(phv),
      dg(dg),
      defuse(defuse),
      noOverlay(pragmas.pa_no_overlay()),
      overlay(phv.field_mutex),
      noInitFields(pragmas.pa_no_init().getFields())
    { }
};

#endif /* _LIVE_RANGE_OVERLAY_H_ */
