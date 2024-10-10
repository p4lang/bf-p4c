/**
 *  Detects multiple pipelines in a program
 */
#ifndef EXTENSIONS_BF_P4C_MIDEND_DETECT_MULTIPLE_PIPELINES_H_
#define EXTENSIONS_BF_P4C_MIDEND_DETECT_MULTIPLE_PIPELINES_H_

#include "ir/ir.h"

namespace BFN {

// This is the visitor class for detecting multiple pipelines
class DetectMultiplePipelines : public Inspector {
    unsigned nPipelines = 0;
    // Checks the "main"
    bool preorder(const IR::Declaration_Instance*) override;
 public:
    // Constructor that adds all of the passes
    DetectMultiplePipelines()
         {}
    // Returns true if multiple pipelines were found
    bool hasMultiplePipelines()
         { return (nPipelines > 1); }
};

}  // namespace BFN

#endif  // EXTENSIONS_BF_P4C_MIDEND_DETECT_MULTIPLE_PIPELINES_H_
