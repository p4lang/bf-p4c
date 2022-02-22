/* Flatrock overloads for instructions #included in instruction.cpp
 * WARNING -- this is included in an anonymous namespace, as VLIWInstruction is 
 * in that anonymous namespace */

void VLIWInstruction::write_regs(Target::Flatrock::mau_regs &regs,
        Table *tbl, Table::Actions::Action *act) {
    error(lineno, "%s:%d: Flatrock instruction not implemented yet!", __FILE__, __LINE__);
}
