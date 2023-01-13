#include "compute_multi_write_containers.h"

namespace Parde::Lowered {

bool ComputeMultiWriteContainers::preorder(IR::BFN::LoweredParserMatch* match) {
    auto orig = getOriginal<IR::BFN::LoweredParserMatch>();

    for (auto e : match->extracts) {
        if (auto extract = e->to<IR::BFN::LoweredExtractPhv>()) {
            if (extract->write_mode == IR::BFN::ParserWriteMode::CLEAR_ON_WRITE) {
                clear_on_write[extract->dest->container].insert(orig);
            } else {
                // Two extraction in the same transition, container should be bitwise or
                if (bitwise_or.count(extract->dest->container) &&
                    bitwise_or[extract->dest->container].count(orig)) {
                    bitwise_or_containers.insert(extract->dest->container);
                }
                bitwise_or[extract->dest->container].insert(orig);
            }
        }
    }

    for (auto csum : match->checksums) {
        PHV::Container container;
        if (csum->csum_err) {
            container = csum->csum_err->container->container;
        } else if (csum->phv_dest) {
            container = csum->phv_dest->container;
        }
        if (container) {
            if (csum->write_mode == IR::BFN::ParserWriteMode::CLEAR_ON_WRITE) {
                clear_on_write[container].insert(orig);
            } else if (csum->write_mode == IR::BFN::ParserWriteMode::BITWISE_OR) {
                bitwise_or[container].insert(orig);
            }
        }
    }

    return true;
}

bool ComputeMultiWriteContainers::preorder(IR::BFN::LoweredParser*) {
    bitwise_or = clear_on_write = {};
    clear_on_write_containers = bitwise_or_containers = {};
    return true;
}

bool ComputeMultiWriteContainers::has_non_mutex_writes(
    const IR::BFN::LoweredParser* parser,
    const std::set<const IR::BFN::LoweredParserMatch*>& matches) {
    for (auto i : matches) {
        for (auto j : matches) {
            if (i == j) continue;

            bool mutex = parser_info.graph(parser).is_mutex(i, j);
            if (!mutex) return true;
        }
    }

    return false;
}

void ComputeMultiWriteContainers::detect_multi_writes(
    const IR::BFN::LoweredParser* parser,
    const std::map<PHV::Container, std::set<const IR::BFN::LoweredParserMatch*>>& writes,
    std::set<PHV::Container>& write_containers, const char* which) {
    for (auto w : writes) {
        if (has_non_mutex_writes(parser, w.second)) {
            write_containers.insert(w.first);
            LOG4("mark " << w.first << " as " << which);
        } else if (Device::currentDevice() != Device::TOFINO) {
            // In Jbay, even and odd pair of 8-bit containers share extractor in the parser.
            // So if both are used, we need to mark the extract as a multi write.
            if (w.first.is(PHV::Size::b8)) {
                PHV::Container other(w.first.type(), w.first.index() ^ 1);
                if (writes.count(other)) {
                    bool has_even_odd_pair = false;

                    for (auto x : writes.at(other)) {
                        for (auto y : w.second) {
                            if (x == y || !parser_info.graph(parser).is_mutex(x, y)) {
                                has_even_odd_pair = true;
                                break;
                            }
                        }
                    }

                    if (has_even_odd_pair) {
                        write_containers.insert(w.first);
                        write_containers.insert(other);
                        LOG4("mark " << w.first << " and " << other << " as " << which
                                     << " (even-and-odd pair)");
                    }
                }
            }
        }
    }
}

void ComputeMultiWriteContainers::postorder(IR::BFN::LoweredParser* parser) {
    auto orig = getOriginal<IR::BFN::LoweredParser>();

    detect_multi_writes(orig, bitwise_or, bitwise_or_containers, "bitwise-or");
    detect_multi_writes(orig, clear_on_write, clear_on_write_containers, "clear-on-write");

    for (const auto& f : phv) {
        if (f.gress != parser->gress) continue;

        if (f.name.endsWith("$stkvalid")) {
            auto ctxt = PHV::AllocContext::PARSER;
            f.foreach_alloc(ctxt, nullptr, [&](const PHV::AllocSlice& alloc) {
                bitwise_or_containers.insert(alloc.container());
            });
        }
    }

    // validate
    for (auto c : bitwise_or_containers) {
        if (clear_on_write_containers.count(c))
            BUG("Container cannot be both clear-on-write and bitwise-or: %1%", c);
    }

    for (auto c : bitwise_or_containers)
        parser->bitwiseOrContainers.push_back(new IR::BFN::ContainerRef(c));

    for (auto c : clear_on_write_containers)
        parser->clearOnWriteContainers.push_back(new IR::BFN::ContainerRef(c));
}

}  // namespace Parde::Lowered
