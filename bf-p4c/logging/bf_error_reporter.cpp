#include "bf_error_reporter.h"
#include "event_logger.h"

void BfErrorReporter::emit_message(const ErrorMessage &msg) {
    if (msg.type == ErrorMessage::MessageType::Error) {
        EventLogger::get().error(msg);
    } else if (msg.type == ErrorMessage::MessageType::Warning) {
        EventLogger::get().warning(msg);
    }
    ErrorReporter::emit_message(msg);
}

void BfErrorReporter::emit_message(const ParserErrorMessage &msg) {
    EventLogger::get().parserError(msg);
    ErrorReporter::emit_message(msg);
}
