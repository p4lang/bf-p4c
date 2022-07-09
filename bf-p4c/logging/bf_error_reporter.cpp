#include <fstream>
#include "bf_error_reporter.h"
#include "bf-p4c-options.h"
#include "event_logger.h"



static bool has_output_already_been_silenced = false;
void  reset_has_output_already_been_silenced() {  //  should this do more?
            has_output_already_been_silenced = false;
}
bool    get_has_output_already_been_silenced() {
     return has_output_already_been_silenced;
}

using namespace std;

void redirect_all_standard_outputs_to_dev_null() {
    // no good ctors for this acc. to <https://m.cplusplus.com/reference/fstream/filebuf/open/> :-(
    static filebuf devNull;
    devNull.open("/dev/null", ios::out | ios::app);

    cerr.rdbuf(&devNull);
    clog.rdbuf(&devNull);
    cout.rdbuf(&devNull);

    has_output_already_been_silenced = true;
}



void check_the_error_count_and_act_accordingly(const BfErrorReporter& BFER) {
    const auto EC { BFER.getErrorCount() };
    if (Log::Detail::verbosity > 0) {
        // just  "if (Log::verbose)" wasn`t good enough: too much spew;
        //   "if ((*Log::verbose) > 1)" was even _worse_
        cerr << "Error count: " << EC << " [cerr]\n";
        cout << "Error count: " << EC << " [cout]\n";
    }
    if (EC >
        BackendOptions().inclusive_max_errors_before_enforcing_silence_other_than_the_summary) {
        cerr << "INFO: suppressing all non-summary non-file output from this point on." << endl;
        redirect_all_standard_outputs_to_dev_null();
    }
}  //  end of “check_the_error_count_and_act_accordingly”



void BfErrorReporter::emit_message(const ErrorMessage &msg) {
    check_the_error_count_and_act_accordingly(*this);

    if (msg.type == ErrorMessage::MessageType::Error) {
        EventLogger::get().error(msg);
    } else if (msg.type == ErrorMessage::MessageType::Warning) {
        EventLogger::get().warning(msg);
    }
    ErrorReporter::emit_message(msg);

    check_the_error_count_and_act_accordingly(*this);
}



void BfErrorReporter::emit_message(const ParserErrorMessage &msg) {
    check_the_error_count_and_act_accordingly(*this);

    EventLogger::get().parserError(msg);
    ErrorReporter::emit_message(msg);

    check_the_error_count_and_act_accordingly(*this);
}
