#ifndef EXTENSIONS_BF_P4C_PARDE_LOWERED_COMPUTE_MULTI_WRITE_CONTAINERS_H_
#define EXTENSIONS_BF_P4C_PARDE_LOWERED_COMPUTE_MULTI_WRITE_CONTAINERS_H_

#include "bf-p4c/parde/allocate_parser_checksum.h"
#include "bf-p4c/parde/parde_visitor.h"
#include "bf-p4c/parde/clot/clot_info.h"

namespace Parde::Lowered {

/// Collect all containers that are written more than once by the parser.
class ComputeMultiWriteContainers : public ParserModifier {
    const PhvInfo& phv;
    const CollectLoweredParserInfo& parser_info;

 public:
    ComputeMultiWriteContainers(const PhvInfo& ph,
                                const CollectLoweredParserInfo& pi)
        : phv(ph), parser_info(pi) { }

 private:
    bool preorder(IR::BFN::LoweredParserMatch* match) override;

    bool preorder(IR::BFN::LoweredParser*) override;

    bool has_non_mutex_writes(const IR::BFN::LoweredParser* parser,
            const std::set<const IR::BFN::LoweredParserMatch*>& matches);

    void detect_multi_writes(const IR::BFN::LoweredParser* parser,
            const std::map<PHV::Container, std::set<const IR::BFN::LoweredParserMatch*>>& writes,
            std::set<PHV::Container>& write_containers, const char* which);

    void postorder(IR::BFN::LoweredParser* parser) override;

    std::map<PHV::Container,
             std::set<const IR::BFN::LoweredParserMatch*>> bitwise_or, clear_on_write;
    std::set<PHV::Container> bitwise_or_containers, clear_on_write_containers;
};

}  // namespace Parde::Lowered

#endif /* EXTENSIONS_BF_P4C_PARDE_LOWERED_COMPUTE_MULTI_WRITE_CONTAINERS_H_ */
