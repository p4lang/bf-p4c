/* parser template specializations for flatrock -- #included directly in top-level parser.cpp */

template <> void Parser::RateLimit::write_config(::Flatrock::regs_pipe &regs, gress_t gress) {
    BUG("TBD");
}

template<> void Parser::write_config(Target::Flatrock::parser_regs &, json::map &, bool) {
    BUG("TBD");
}

template<> void Parser::gen_configuration_cache(Target::Flatrock::parser_regs&, json::vector&) {
    BUG("TBD");
}
