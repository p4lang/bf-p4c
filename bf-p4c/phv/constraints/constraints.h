#ifndef BF_P4C_PHV_CONSTRAINTS_CONSTRAINTS_H_
#define BF_P4C_PHV_CONSTRAINTS_CONSTRAINTS_H_

// This is the file in which we will document all PHV constraints.
// XXX(Deep): Integrate all constraints into this class format.

namespace Constraints {

// Class that captures whether a constraint is present on a field or not.
// It also registers the reason for the constraint being added to the field.
// reason = 0 necessarily implies the absence of the constraint.
class BooleanConstraint {
 protected:
    unsigned reason = 0;

 public:
    virtual bool hasConstraint() const = 0;
    virtual void addConstraint(uint32_t reason) = 0;
};

// This class represents the solitary constraint, which implies that the field cannot be packed with
// any other field in the same container. Note that solitary constraint does not preclude fields
// sharing the same container through overlay.
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
        PRAGMA_CONTAINER_SIZE = (1 << 5)    // solitary constraint due to pa_container_size
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
}  // namespace Constraints

#endif  /* BF_P4C_PHV_CONSTRAINTS_CONSTRAINTS_H_ */
