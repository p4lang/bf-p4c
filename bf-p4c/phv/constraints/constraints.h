#ifndef BF_P4C_PHV_CONSTRAINTS_CONSTRAINTS_H_
#define BF_P4C_PHV_CONSTRAINTS_CONSTRAINTS_H_

#include <cstdint>

/// This is the file in which we will document all PHV constraints.
/// XXX(Deep): Integrate all constraints into this class format.

namespace Constraints {

/// Class that captures whether a constraint is present on a field or not.
/// It also registers the reason for the constraint being added to the field.
/// reason = 0 necessarily implies the absence of the constraint.
class BooleanConstraint {
 protected:
    unsigned reason = 0;

 public:
    virtual bool hasConstraint() const = 0;
    virtual void addConstraint(uint32_t reason) = 0;
};

/// This class represents the solitary constraint, which implies that the field cannot be packed
/// with any other field in the same container. Note that solitary constraint does not preclude
/// fields sharing the same container through overlay.
class SolitaryConstraint : BooleanConstraint {
 public:
     // Define reasons for constraints here as enum classes.
    enum SolitaryReason {
        NONE = 0,                           // represents absence of solitary constraint
        ALU = 1,                            // solitary constraint due to ALU operation
        CHECKSUM = (1 << 1),                // solitary constraint due to use in checksum
        ARCH = (1 << 2),                    // solitary constraint required by the hardware
        DIGEST = (1 << 3),                  // solitary constraint due to use in digest
        PRAGMA_SOLITARY = (1 << 4),         // solitary constraint due to pa_solitary pragma
        PRAGMA_CONTAINER_SIZE = (1 << 5),   // solitary constraint due to pa_container_size
        CONFLICT_ALIGNMENT = (1 << 6)       // solitary constraint due to conflicting alignment
                                            // in bridge packing
    };

    bool hasConstraint() const { return (reason != 0); }
    void addConstraint(uint32_t r) { reason |= r; }

    bool isALU() const { return reason & ALU; }
    bool isChecksum() const { return reason & CHECKSUM; }
    bool isArch() const { return reason & ARCH; }
    bool isDigest() const { return reason & DIGEST; }
    bool isPragmaSolitary() const { return reason & PRAGMA_SOLITARY; }
    bool isPragmaContainerSize() const { return reason & PRAGMA_CONTAINER_SIZE; }
};

/// This class represents the digest constraint, which implies that the field is used in a digest.
/// Additionally, it also stores the type of digest in which the field is used.
class DigestConstraint : BooleanConstraint {
 public:
    // Define type of digest in which the field is used.
    enum DigestType {
        NONE = 0,               // Field is not used in a digest
        MIRROR = 1,             // used in mirror digest
        LEARNING = (1 << 1),    // used in learning digest
        RESUBMIT = (1 << 2),    // used in resubmit
        PKTGEN = (1 << 3)       // used in pktgen
    };

    bool hasConstraint() const { return (reason != 0); }
    void addConstraint(uint32_t r) { reason |= r; }

    bool isMirror() const { return reason & MIRROR; }
    bool isLearning() const { return reason & LEARNING; }
    bool isResubmit() const { return reason & RESUBMIT; }
    bool isPktGen() const { return reason & PKTGEN; }
};

class IntegerConstraint {
 protected:
    unsigned reason = 0;
    unsigned value = 0;

 public:
    virtual ~IntegerConstraint() {}
    virtual bool hasConstraint() const = 0;
    virtual void addConstraint(unsigned r, unsigned v) = 0;
};

/// This class represents the alignment constraint, which implies that field must start at
/// a particular offset within a container.
class AlignmentConstraint : IntegerConstraint {
 protected:
    // used by bridged packing to insert extra padding to ease phv allocation
    // see IMPL_NOTE(0) in bridged_packing.h
    // DO NOT OUTPUT THIS CONSTRAINT TO USER LOG
    unsigned container_size = 0;

 public:
    // Define the cause of alignment constraint
    enum AlignmentReason {
        NONE = 0,
        BRIDGE = 1,
        PARSER = (1 << 1),
        DEPARSER = (1 << 2),
        TERNARY_MATCH = (1 << 3),
        DIGEST = (1 << 4),
        INTRINSIC = (1 << 5),
    };

    ~AlignmentConstraint() {}
    bool hasConstraint() const { return (reason != 0); }
    void addConstraint(unsigned source, unsigned v) { reason |= source; value = v; }

    void updateConstraint(unsigned source) { reason |= source; }
    void eraseConstraint() { reason = 0; }
    unsigned getAlignment() { return value; }
    unsigned getReason() { return reason; }

    void setContainerSize(unsigned size) { container_size = size; }
    unsigned getContainerSize() { return container_size; }

    bool isBridged() const { return reason & BRIDGE; }
    bool isParser() const { return reason & PARSER; }
    bool isDeparser() const { return reason & DEPARSER; }
    bool isTernaryMatch() const { return reason & TERNARY_MATCH; }
    bool isDigest() const { return reason & DIGEST; }
    bool isIntrinsic() const { return reason & INTRINSIC; }

    bool operator==(const AlignmentConstraint & a) const {
        return reason == a.reason && value == a.value; }
    bool operator<(AlignmentConstraint const & a) const {
        if (value < a.value) return true;
        else if (reason < a.reason) return true;
        return false;
    }
};

class GroupConstraint {
 protected:
    unsigned reason = 0;
    /* fields that share the same group constraint */
    ordered_set<const PHV::Field*> fields;

 public:
    virtual ~GroupConstraint() {}
    virtual bool hasConstraint() const = 0;
    virtual void addConstraint(uint32_t reason) = 0;
};

class CopackConstraint : GroupConstraint {
 public:
    ~CopackConstraint() {}
    bool hasConstraint() const { return (reason != 0); }
    void addConstraint(unsigned r) { reason |= r; }
};

}  // namespace Constraints

#endif  /* BF_P4C_PHV_CONSTRAINTS_CONSTRAINTS_H_ */
