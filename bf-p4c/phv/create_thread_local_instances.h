#ifndef BF_P4C_PHV_CREATE_THREAD_LOCAL_INSTANCES_H_
#define BF_P4C_PHV_CREATE_THREAD_LOCAL_INSTANCES_H_

#include "ir/ir.h"

/**
 * This Visitor creates a thread-local instance of every metadata instance,
 * header instance, parser state, and TempVar. The name of the new instance
 * follows the pattern `gress-name::instance-name`.
 *
 * The set of metadata variables in BFN::Pipe::metadata is also updated.
 */
struct CreateThreadLocalInstances : public PassManager {
    CreateThreadLocalInstances();
};

#endif /* BF_P4C_PHV_CREATE_THREAD_LOCAL_INSTANCES_H_ */
