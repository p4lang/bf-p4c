/*!
 * @file checksum_correction.p4
 * @brief checksum correcion
 */
#if __TARGET_TOFINO__ == 2
#include <t2na.p4>
#else
#include <tna.p4>
#endif
#include "headers.p4"
#include "debt_reg.p4"


/*************************************************************/
control egress_capture(
  in egress_intrinsic_metadata_t eg_intr_md,
  in egress_metadata_t meta,
  inout header_t hdr,
  inout bit<8> rich_register) 
{
   
    bit<8> capture_port;
    bit<16> padded_length = 0;
    capture_index_t capture_group = 0;

    bit<16> seq_no;
    Register<bit<16>, bit<2>>(size=1, initial_value=0) sequence_no;
    RegisterAction<bit<16>, bit<2>, bit<16>>(sequence_no)
    update_seq_no = {
        void apply(inout bit<16> register_data, out bit<16> result)
        {
            result = register_data;
            if (register_data == 16w0x7ff)
                register_data = 0;
            else
                register_data = register_data + 1;
        }
    };

    action pad_out_length(capture_index_t index)
    {
        padded_length = eg_intr_md.pkt_length>>2;
        capture_group = index;
    }

    action lookup_group(capture_index_t index)
    {
        padded_length = 0;
        capture_group = index;
    }

    action no_pad()
    {
        padded_length = 0;
    }
    // if egress port = capture port type, 
    // then padded_length is the shifted length, else 0 
    table captureLookupTbl {
        key = {
            eg_intr_md.egress_port : exact;
        }
        actions = {
            pad_out_length;
            lookup_group;
            no_pad;
        }
        default_action = no_pad;
        size = 32;
    }

    action insert_seq_no( bit<16> calculated_ov)
    {
        hdr.capture.seq_no[15:0] = calculated_ov;
        hdr.capture.seq_no[31:16] = calculated_ov;
        hdr.capture.timestamp = meta.ing_port_mirror.mac_timestamp;
    }

    table insertOverheadTbl {
    key = {
        seq_no : exact;
    }
    actions = {
        insert_seq_no;
    }
      size = 2048;
    }
   
    /******************************************************************/
    apply
    {
        captureLookupTbl.apply();
        update_register.apply(eg_intr_md, hdr,
            padded_length, capture_group, rich_register);
        if (meta.pkt_type == PKT_TYPE_CAPTURE)
        {
            seq_no = update_seq_no.execute(capture_group);
            insertOverheadTbl.apply();
        }
    }
}

