#include "bf-p4c/phv/pragma/phv_pragmas.h"

/// @returns true if for the associated @pragmaName, the @gress is either ingress or egress.
bool PHV::Pragmas::gressValid(cstring gress) {
    return gress == "ingress" || gress == "egress";
}

/**
 * Check if valid combination of pipe and gress arguments is passed.
 * @param[in]     expr List of expressions
 * @param[in,out] expr_index Index of the first argument that is not pipe or gress
 * @param[in,out] min_required_arguments Minimal number of arguments without the pipe argument
 * @param[out]    pipe_arg Pointer to the pipe argument
 * @param[out]    gress_arg Pointer to the gress argument
 * @return Returns true if valid combination of pipe and gress arguments is found,
 *         false otherwise.
 */
bool PHV::Pragmas::determinePipeGressArgs(const IR::Vector<IR::Expression>& exprs,
        unsigned& expr_index, unsigned& required_args,
        const IR::StringLiteral*& pipe_arg, const IR::StringLiteral*& gress_arg) {
    // At least one argument is present, ensured by grammar
    auto arg0 = exprs.at(expr_index++)->to<IR::StringLiteral>();

    // Determine whether the name of a pipe is present
    if (gressValid(arg0->value)) {
        // The first argument is gress so there is no pipe
        gress_arg = arg0;
    } else if (BFNContext::get().isPipeName(arg0->value)) {
        // The first argument is pipe, the second must be gress
        pipe_arg = arg0;
        required_args++;
        if (exprs.size() > 1) {
            // Ensure there is another argument
            gress_arg = exprs.at(expr_index++)->to<IR::StringLiteral>();
            if (!gressValid(gress_arg->value)) {
                ::warning(ErrorType::WARN_UNKNOWN,
                    "%1%: Found invalid gress argument. Ignoring pragma.", gress_arg);
                return false;
            }
        }
    } else {
        // The first argument is not gress neither pipe
        ::warning(ErrorType::WARN_UNKNOWN,
            "%1%: Found invalid gress or pipe argument. Ignoring pragma.", arg0);
        return false;
    }
    return true;
}

/**
 * Check if all arguments of the pragma are string literals.
 * @param[in]     expr List of expressions
 * @return Returns true if all arguments of the pragma are string literals,
 *         false otherwise.
 */
bool PHV::Pragmas::checkStringLiteralArgs(const IR::Vector<IR::Expression>& exprs) {
    for (auto& expr : exprs) {
        if (!expr->is<IR::StringLiteral>()) {
            ::warning(ErrorType::WARN_INVALID,
                "%1%: Found a non-string literal argument. Ignoring pragma.", expr);
            return false;
        }
    }
    return true;
}

/**
 * Check if the number of arguments is suitable for the specified pragma.
 * @param[in] annotation Annotation IR
 * @param[in] required_args Number of required arguments
 * @param[in] min_required_args Minimal number of required arguments
 * @param[in] exact_number_of_args Number of required arguments is exact or minimal
 * @param[in] pragma_name Pragma name
 * @param[in] pragma_args_wo_pipe Arguments of the pragma excluding pipe argument
 * @return Returns true if suitable number of arguments is passed, false otherwise.
 */
bool PHV::Pragmas::checkNumberArgs(const IR::Annotation* annotation,
        unsigned required_args, const unsigned min_required_args, bool exact_number_of_args,
        cstring pragma_name, cstring pragma_args_wo_pipe) {
    auto& exprs = annotation->expr;
    if ((exact_number_of_args && exprs.size() != required_args) || exprs.size() < required_args) {
        ::warning(ErrorType::WARN_INVALID, "%1%: Invalid number of arguments. "
                  "With `pipe' and `gress' arguments, pragma @%2% requires %3% "
                  "%4%arguments (`pipe', %5%%6%). "
                  "Without `pipe' argument, pragma @%2% requires %7% "
                  "%4%arguments (%5%%6%). "
                  "Found %8% arguments. Ignoring pragma.",
                  /* %1% */ annotation,
                  /* %2% */ pragma_name,
                  /* %3% */ min_required_args + 1,
                  /* %4% */ exact_number_of_args ? "" : "or more ",
                  /* %5% */ pragma_args_wo_pipe,
                  /* %6% */ exact_number_of_args ? "" : ", ...",
                  /* %7% */ min_required_args,
                  /* %8% */ exprs.size());
        return false;
    }
    return true;
}

/**
 * Check whether the pragma should be applied in the specified pipe.
 * @param[in] pipe Pipe IR argument
 * @param[in] pipe_arg Pipe argument delivered in the pragma
 * @param[in] pragma Pragma
 * @return Returns true if the pragma should be applied in the specified pipe,
 *         false otherwise.
 */
bool PHV::Pragmas::checkPipeApplication(const IR::Annotation *annotation,
        const IR::BFN::Pipe* pipe, const IR::StringLiteral *pipe_arg) {
    if (pipe_arg && pipe->name && pipe_arg->value != pipe->name) {
        LOG4("Skipping pragma " << cstring::to_cstring(annotation)
            << " at the pipe `" << pipe->name.toString() << "'.");
        return false;
    }
    return true;
}

/**
 * Report no matching PHV field.
 * @param[in] pipe Pipe IR. If null, pipe name is not shown.
 * @param[in] expr Expression IR with source info.
 * @param[in] field_name If @expr is null, use this argument as the field name.
 */
void PHV::Pragmas::reportNoMatchingPHV(const IR::BFN::Pipe* pipe,
        const IR::Expression* expr, cstring field_name) {
    if (expr) {
        if (pipe && pipe->name) {
            // If the pipe is named
            ::warning(ErrorType::WARN_INVALID,
                "%1%: No matching PHV field in the pipe `%2%'. Ignoring pragma.",
                expr, pipe->name);
        } else {
            ::warning(ErrorType::WARN_INVALID,
                "%1%: No matching PHV field. Ignoring pragma.",
                expr);
        }
    } else {
        // No source info available
        if (pipe && pipe->name) {
            // If the pipe is named
            ::warning(ErrorType::WARN_INVALID,
                "No matching PHV field `%1' in the pipe `%2%'. Ignoring pragma.",
                field_name, pipe->name);
        } else {
            ::warning(ErrorType::WARN_INVALID,
                "No matching PHV field `%1%'. Ignoring pragma.",
                field_name);
        }
    }
}