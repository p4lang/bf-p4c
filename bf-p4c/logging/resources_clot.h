#ifndef _EXTENSIONS_BF_P4C_LOGGING_RESOURCES_CLOT_H_
#define _EXTENSIONS_BF_P4C_LOGGING_RESOURCES_CLOT_H_

#include <map>
#include <vector>
#include "ir/ir.h"

#include "resources_schema.h"

using Logging::Resources_Schema_Logger;
class ClotInfo;  // Forward declaration

namespace BFN {

class ClotResourcesLogging : public ParserInspector {
 public:
    using ClotResourceUsage = Resources_Schema_Logger::ClotResourceUsage;
    using ClotUsage = Resources_Schema_Logger::ClotUsage;
    using ClotField = Resources_Schema_Logger::ClotField;

 protected:
    const ClotInfo &clotInfo;
    ClotResourceUsage *clotLogger = nullptr;
    std::vector<ClotResourceUsage*> clotUsages = std::vector<ClotResourceUsage*>(2);
    bool collected = false;
    std::map<unsigned, unsigned> clotTagToChecksumUnit;
    std::vector<std::map<unsigned, std::vector<ClotUsage*>>> usageData;

    bool usingClots() const;

    std::vector<ClotUsage*> &getUsageData(gress_t gress, unsigned tag);

    bool preorder(const IR::BFN::LoweredParserState* state);
    void end_apply() override;

    void collectClotUsages(const IR::BFN::LoweredParserMatch* match,
                       const IR::BFN::LoweredParserState* state,
                       gress_t gress);

    void collectExtractClotInfo(const IR::BFN::LoweredExtractClot* extract,
                                const IR::BFN::LoweredParserState *state,
                                gress_t gress);

    void logClotUsages();

    ClotUsage* logExtractClotInfo(bool hasChecksum, int length, int offset,
                                  unsigned tag, const Clot *clot);

 public:
    std::vector<ClotResourceUsage*> getLoggers();

    explicit ClotResourcesLogging(const ClotInfo& clotInfo);
};

}  // namespace BFN

#endif /* _EXTENSIONS_BF_P4C_LOGGING_RESOURCES_CLOT_H_ */
