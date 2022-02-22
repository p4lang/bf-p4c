/* parser template specializations for flatrock -- #included directly in top-level parser.cpp */

template <> void Parser::RateLimit::write_config(::Flatrock::regs_pipe &regs, gress_t gress) {
    error(lineno, "%s:%d: Flatrock parser write_config not implemented yet!", __FILE__, __LINE__);
}

template<> void Parser::write_config(Target::Flatrock::parser_regs &, json::map &, bool) {
    error(lineno, "%s:%d: Flatrock parser write_config not implemented yet!", __FILE__, __LINE__);
}

template<> void Parser::gen_configuration_cache(Target::Flatrock::parser_regs&, json::vector&) {
    error(lineno, "%s:%d: Flatrock parser gen_config not implemented yet!", __FILE__, __LINE__);
}
