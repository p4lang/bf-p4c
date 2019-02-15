#ifndef BF_P4C_MAU_INSTRUCTION_SELECTION_H_
#define BF_P4C_MAU_INSTRUCTION_SELECTION_H_

#include "bf-p4c/bf-p4c-options.h"
#include "bf-p4c/ir/tofino_write_context.h"
#include "bf-p4c/mau/mau_visitor.h"
#include "bf-p4c/phv/phv_fields.h"

/**
 * Until the Register.read and Register.write functions have a separate Instruction
 * Selection to convert these to RegisterActions, Brig does not support these read/write
 * calls.  Eventually someone has to write a pass to do this conversion.
 */
class UnimplementedRegisterMethodCalls : public MauInspector {
    bool preorder(const IR::Primitive *prim) override;

 public:
    UnimplementedRegisterMethodCalls() {}
};

/** The purpose of this pass is to determine the types, and per flow enables of actions.
 *  Eventually a second inspector will be required, after StatefulAttachmentSetup, in order
 *  to verify that the way that these synth2port tables are being used is correct.
 *
 *  FIXME: In order to fully remain sequential, for addressing being set up from potential
 *  fields, we cannot necessarily remove instructions.  Instead of using Primitive, a new
 *  IR node could be necessary.
 */
class Synth2PortSetup : public MauTransform {
    safe_vector<const IR::Primitive *> stateful;
    std::set<UniqueAttachedId> per_flow_enables;
    std::map<UniqueAttachedId, IR::MAU::MeterType> meter_types;

    safe_vector<IR::MAU::Instruction *> created_instrs;

    const IR::MAU::Action *preorder(IR::MAU::Action *) override;
    const IR::Node *postorder(IR::Primitive *) override;
    const IR::MAU::Action *postorder(IR::MAU::Action *) override;

    void clear_action() {
        stateful.clear();
        per_flow_enables.clear();
        meter_types.clear();
    }

 public:
    explicit Synth2PortSetup(const PhvInfo &) { }
};

/** The general purpose of instruction selection is to completely transform all P4 frontend code
 *  to parallel instructions that the compiler can completely understand.  These parallel
 *  instructions are encoded in IR::MAU::Instruction.
 *
 *  Currently the following classes exist to perform the conversion:
 *    - InstructionSelection: generic all-purpose class for handling the complete translation
 *      between frontend IR and backend.
 *    - StatefulAttachmentSetup: specifically to create or possibly link IR::MAU::HashDist units
 *      with their associated IR::MAU::BackendAttached tables, or setup other attachment modes
 *    - ConvertCastsToSlices: Conversion of all IR::Casts to IR::Slices as expressions.
 *      Specifically on assignment, will extend or possibly not extend the value that is being
 *      written
 *    - VerifyActions: Verifies that all generated instructions will be correctly understood
 *      and interpreted by the remainder of the compiler
 */
class DoInstructionSelection : public MauTransform, TofinoWriteContext {
    const BFN_Options &options;
    const PhvInfo &phv;
    IR::MAU::Action                     *af = nullptr;
    class SplitInstructions;

    profile_t init_apply(const IR::Node *root) override;
    const IR::GlobalRef *preorder(IR::GlobalRef *) override;
    const IR::MAU::Action *postorder(IR::MAU::Action *) override;
    const IR::MAU::Action *preorder(IR::MAU::Action *) override;
    const IR::MAU::SaluAction *preorder(IR::MAU::SaluAction *a) override { prune(); return a; }
    const IR::Expression *postorder(IR::Add *) override;
    const IR::Expression *postorder(IR::AddSat *) override;
    const IR::Expression *postorder(IR::Sub *) override;
    const IR::Expression *postorder(IR::SubSat *) override;
    const IR::Expression *postorder(IR::Neg *) override;
    const IR::Expression *postorder(IR::Shr *) override;
    const IR::Expression *postorder(IR::Shl *) override;
    const IR::Expression *postorder(IR::BAnd *) override;
    const IR::Expression *postorder(IR::BOr *) override;
    const IR::Expression *postorder(IR::BXor *) override;
    const IR::Expression *postorder(IR::Cmpl *) override;
    const IR::Expression *preorder(IR::BFN::SignExtend *) override;
    const IR::Expression *preorder(IR::Concat *) override;
    // const IR::Expression *postorder(IR::Cast *) override;
    const IR::Expression *postorder(IR::Mux *) override;
    const IR::Slice *postorder(IR::Slice *) override;
    const IR::Expression *postorder(IR::BoolLiteral *) override;
    const IR::Node *postorder(IR::Primitive *) override;
    const IR::MAU::Instruction *postorder(IR::MAU::Instruction *i) override { return i; }

    bool checkPHV(const IR::Expression *);
    bool checkSrc1(const IR::Expression *);
    bool checkConst(const IR::Expression *ex, long &value);
    bool equiv(const IR::Expression *a, const IR::Expression *b);
    IR::Member *genIntrinsicMetadata(gress_t gress, cstring header, cstring field);

 public:
    DoInstructionSelection(const BFN_Options &options, const PhvInfo &phv);
};

/** This pass was specifically created to deal with adding the HashDist object to different
 *  stateful objects.  On one particular case, execute_stateful_alu_from_hash was creating
 *  two separate instructions, a TempVar = hash function call, and an execute stateful call
 *  addressed by this TempVar.  This pass combines these instructions into one instruction,
 *  and correctly saves the HashDist IR into these attached tables
 */
class StatefulAttachmentSetup : public PassManager {
    const PhvInfo &phv;
    const IR::TempVar *saved_tempvar;
    const IR::MAU::HashDist *saved_hashdist;
    typedef std::pair<const IR::MAU::AttachedMemory *, const IR::MAU::Table *> HashDistKey;
    typedef std::pair<const IR::MAU::StatefulCall *, const IR::MAU::Table*> StatefulCallKey;
    ordered_set<cstring> remove_tempvars;
    ordered_set<const IR::Node *> remove_instr;
    ordered_map<cstring, const IR::MAU::HashDist *> stateful_alu_from_hash_dists;
    ordered_map<HashDistKey, const IR::MAU::HashDist *> update_hd;
    ordered_map<StatefulCallKey, const IR::Expression *> update_calls;
    typedef IR::MAU::StatefulUse use_t;
    ordered_map<const IR::MAU::Action *, ordered_map<const IR::MAU::AttachedMemory *, use_t>>
        action_use;
    typedef std::pair<const IR::MAU::Synth2Port *, const IR::MAU::Table *> IndexCheck;

    ordered_set<IndexCheck> addressed_by_hash;
    ordered_set<IndexCheck> addressed_by_index;

    profile_t init_apply(const IR::Node *root) override {
        remove_tempvars.clear();
        remove_instr.clear();
        stateful_alu_from_hash_dists.clear();
        update_hd.clear();
        return PassManager::init_apply(root); }
    class Scan : public MauInspector, TofinoWriteContext {
        StatefulAttachmentSetup &self;
        bool preorder(const IR::MAU::Action *) override;
        bool preorder(const IR::MAU::Instruction *) override;
        bool preorder(const IR::TempVar *) override;
        bool preorder(const IR::MAU::HashDist *) override;
        void postorder(const IR::MAU::Instruction *) override;
        void postorder(const IR::Primitive *) override;
        void postorder(const IR::MAU::Table *) override;
        void setup_index_operand(const IR::Expression *index_expr,
            const IR::MAU::Synth2Port *synth2port, const IR::MAU::Table *tbl,
            const IR::MAU::StatefulCall *call);
        void simpl_concat(std::vector<const IR::Expression*>& slices,
                          const IR::Concat* concat);

     public:
        explicit Scan(StatefulAttachmentSetup &self) : self(self) {}
    };
    class Update : public MauTransform {
        StatefulAttachmentSetup &self;
        const IR::MAU::StatefulCall *preorder(IR::MAU::StatefulCall *) override;
        const IR::MAU::BackendAttached *preorder(IR::MAU::BackendAttached *ba) override;
        const IR::MAU::Instruction *preorder(IR::MAU::Instruction *sp) override;
     public:
        explicit Update(StatefulAttachmentSetup &self) : self(self) {}
    };

    const IR::MAU::HashDist *find_hash_dist(const IR::Expression *expr, const IR::Primitive *prim);
    IR::MAU::HashDist *create_hash_dist(const IR::Expression *e, const IR::Primitive *prim);

 public:
    explicit StatefulAttachmentSetup(const PhvInfo &p) : phv(p) {
        addPasses({ new Scan(*this), new Update(*this) }); }
};

class NullifyAllStatefulCallPrim : public MauModifier {
    bool preorder(IR::MAU::StatefulCall *sc) override;

 public:
    NullifyAllStatefulCallPrim() { }
};

/** Local copy propagates any writes in set operations to later reads in other operations.
 *  Marks these fields as copy propagated.
 */
class BackendCopyPropagation : public MauTransform, TofinoWriteContext {
    const PhvInfo &phv;
    struct FieldImpact {
        le_bitrange dest_bits;
        const IR::Expression *read;
     public:
        FieldImpact(le_bitrange db, const IR::Expression *r) : dest_bits(db), read(r) { }
    };
    ordered_map<const PHV::Field *, safe_vector<FieldImpact>> copy_propagation_replacements;

    const IR::Node *preorder(IR::Node *n) override { visitOnce(); return n; }
    const IR::MAU::Instruction *preorder(IR::MAU::Instruction *i) override;
    const IR::MAU::StatefulCall *preorder(IR::MAU::StatefulCall *sc) override {
        prune(); return sc;
    }
    const IR::MAU::BackendAttached *preorder(IR::MAU::BackendAttached *ba) override {
        prune(); return ba;
    }
    const IR::MAU::Action *preorder(IR::MAU::Action *a) override;
    void update(const IR::MAU::Instruction *instr);
    const IR::Expression *propagate(const IR::MAU::Instruction *instr,
        const IR::Expression *e, bool &elem_copy_propagated);

 public:
    explicit BackendCopyPropagation(const PhvInfo &p) : phv(p) { visitDagOnce = false; }
};

/** Verifies that an action is entirely parallel, after BackendCopyPropagation occurs.
 *  Essentially, if a read in an action has previously been written, and this read has
 *  not been copy propagated, then this is a multi-stage action
 */
class VerifyParallelWritesAndReads : public MauInspector, TofinoWriteContext {
    const PhvInfo &phv;
    ordered_map<const PHV::Field *, safe_vector<le_bitrange>> writes;

    bool preorder(const IR::MAU::Action *) override;
    bool preorder(const IR::MAU::Instruction *) override;
    bool preorder(const IR::MAU::StatefulCall *) override { return false; }
    bool preorder(const IR::MAU::BackendAttached *) override { return false; }
    bool is_parallel(const IR::Expression *e, bool is_write);

 public:
    explicit VerifyParallelWritesAndReads(const PhvInfo &p) : phv(p) {}
};

/** Ensures that only the last write to a field is the only instruction kept in a parallel
 *  action, as if the action was sequential, then only the the last write matters.
 */
class EliminateAllButLastWrite : public PassManager {
    const PhvInfo &phv;

 public:
    using LastInstrMap = ordered_map<PHV::FieldSlice, const IR::MAU::Instruction *>;
    ordered_map<const IR::MAU::Action *, LastInstrMap> last_instr_per_action_map;

 private:
    class Scan : public MauInspector, TofinoWriteContext {
        EliminateAllButLastWrite &self;
        LastInstrMap last_instr_map;

        bool preorder(const IR::MAU::Action *) override;
        bool preorder(const IR::MAU::Instruction *) override;
        bool preorder(const IR::MAU::StatefulCall *) override { return false; }
        bool preorder(const IR::MAU::BackendAttached *) override { return false; }
        void postorder(const IR::MAU::Action *) override;

     public:
        explicit Scan(EliminateAllButLastWrite &self) : self(self) {}
    };

    class Update : public MauTransform, TofinoWriteContext {
        EliminateAllButLastWrite &self;
        const IR::MAU::Action *current_af = nullptr;
        const IR::MAU::Action *preorder(IR::MAU::Action *) override;
        const IR::MAU::Instruction *preorder(IR::MAU::Instruction *) override;
        const IR::MAU::StatefulCall *preorder(IR::MAU::StatefulCall *sc) override {
            prune(); return sc;
        }
        const IR::MAU::BackendAttached *preorder(IR::MAU::BackendAttached *ba) override {
            prune(); return ba;
        }

     public:
        explicit Update(EliminateAllButLastWrite &self) : self(self) { }
    };

 public:
    explicit EliminateAllButLastWrite(const PhvInfo &p) : phv(p) {
        addPasses({ new Scan(*this), new Update(*this) }); }
};

/** This pass will set up the IR to include any inputs to an LPF/WRED meter, as well
 *  as determine the pre-color for any meter.  The primitive information holds the
 *  field that is either the input/pre-color and in the update, the IR::MAU::Meter is
 *  updated.
 */
class MeterSetup : public PassManager {
    // Tracks the inputs per lpf
    ordered_map<const IR::MAU::Meter *, const IR::Expression *> update_lpfs;
    // Tracks the pre-color per meter
    ordered_map<const IR::MAU::Meter *, const IR::Expression *> update_pre_colors;
    // Marks an action for setting a meter type
    ordered_map<const IR::MAU::Action *, UniqueAttachedId> pre_color_types;
    ordered_map<const IR::MAU::Action *, UniqueAttachedId> standard_types;
    const PhvInfo &phv;

    class Scan : public MauInspector {
        MeterSetup &self;
        void find_input(const IR::Primitive *);
        void find_pre_color(const IR::Primitive *);
        const IR::Expression *convert_cast_to_slice(const IR::Expression *);
        bool preorder(const IR::MAU::Instruction *) override;
        bool preorder(const IR::Primitive *) override;
     public:
        explicit Scan(MeterSetup &self) : self(self) {}
    };

    class Update : public MauModifier {
        MeterSetup &self;
        void update_input(IR::MAU::Meter *);
        void update_pre_color(IR::MAU::Meter *);
        bool preorder(IR::MAU::Meter *) override;
        bool preorder(IR::MAU::Action *) override;
     public:
        explicit Update(MeterSetup &self) : self(self) {}
    };

 public:
    explicit MeterSetup(const PhvInfo &p) : phv(p) {
        addPasses({ new Scan(*this), new Update(*this) }); }
};

#if 0
class DLeftSetup : public MauModifier, TofinoWriteContext {
    void postorder(IR::MAU::Table *tbl) override;
    void postorder(IR::MAU::BackendAttached *ba) override;

 public:
    DLeftSetup() {}
};
#endif

class SetupAttachedAddressing : public PassManager {
    struct AttachedActionCoord {
        bool all_per_flow_enabled = true;
        bool all_same_meter_type = true;
        bool meter_type_set = false;
        IR::MAU::MeterType meter_type = IR::MAU::MeterType::UNUSED;
    };

    using AttachedInfo = std::map<UniqueAttachedId, AttachedActionCoord>;
    // coordinate the Attached Info across all inspectors
    ordered_map<const IR::MAU::Table *, AttachedInfo> all_attached_info;
    // Just to run the modifier on BackendAttached Objects
    ordered_map<const IR::MAU::BackendAttached *, AttachedActionCoord> attached_coord;

    class InitializeAttachedInfo : public MauInspector {
        SetupAttachedAddressing &self;
        bool preorder(const IR::MAU::BackendAttached *) override;
     public:
        explicit InitializeAttachedInfo(SetupAttachedAddressing &self) : self(self) { }
    };

    class ScanActions : public MauInspector {
        SetupAttachedAddressing &self;
        bool preorder(const IR::MAU::Action *) override;
     public:
        explicit ScanActions(SetupAttachedAddressing &self) : self(self) { }
    };

    class VerifyAttached : public MauInspector {
        SetupAttachedAddressing &self;
        bool preorder(const IR::MAU::BackendAttached *) override;
     public:
        explicit VerifyAttached(SetupAttachedAddressing &self) : self(self) { }
    };

    class UpdateAttached : public MauModifier {
        SetupAttachedAddressing &self;
        void simple_attached(IR::MAU::BackendAttached *);
        bool preorder(IR::MAU::BackendAttached *) override;
     public:
        explicit UpdateAttached(SetupAttachedAddressing &self) : self(self) { }
    };

 public:
    SetupAttachedAddressing() {
        addPasses({
            new InitializeAttachedInfo(*this),
            new ScanActions(*this),
            new VerifyAttached(*this),
            new UpdateAttached(*this)
        });
    }
};

class InstructionSelection : public PassManager {
 public:
    InstructionSelection(const BFN_Options&, PhvInfo &);
};

#endif /* BF_P4C_MAU_INSTRUCTION_SELECTION_H_ */
