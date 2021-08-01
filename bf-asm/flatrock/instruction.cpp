/* Flatrock overloads for instructions #included in instruction.cpp
 * WARNING -- this is included in an anonymous namespace, as VLIWInstruction is 
 * in that anonymous namespace */

void VLIWInstruction::write_regs(Target::Flatrock::mau_regs &regs,
        Table *tbl, Table::Actions::Action *act) {
    BUG("TBD");
}
