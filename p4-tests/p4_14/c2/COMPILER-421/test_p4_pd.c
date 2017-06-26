/* Copyright (C) 2017 by TEST All Right Reserved */

void test_run()
{
  p4_pd_balancer_init();

  {
    struct
    {
      bf_dev_port_t dev_port;
      bf_port_speed_t speed;
      bf_fec_type_t fec;
      uint8_t port_type;
      bf_dev_port_t dev_linked_port;
      uint8_t forward_multicast;
      uint8_t is_nat;
    } port_cfg[] = {
      { .dev_port = 0, .speed = BF_SPEED_10G, .fec = BF_FEC_TYP_NONE, .port_type = 1, .dev_linked_port = 1, .forward_multicast = 1, .is_nat = 0 },
      { .dev_port = 1, .speed = BF_SPEED_10G, .fec = BF_FEC_TYP_NONE, .port_type = 2, .dev_linked_port = 0, .forward_multicast = 1, .is_nat = 0 },

      { .dev_port = 2, .speed = BF_SPEED_10G, .fec = BF_FEC_TYP_NONE, .port_type = 3 },
      { .dev_port = 3, .speed = BF_SPEED_10G, .fec = BF_FEC_TYP_NONE, .port_type = 3 },
      { .dev_port = 4, .speed = BF_SPEED_10G, .fec = BF_FEC_TYP_NONE, .port_type = 3 },
      { .dev_port = 5, .speed = BF_SPEED_10G, .fec = BF_FEC_TYP_NONE, .port_type = 3 },
      { .dev_port = 6, .speed = BF_SPEED_10G, .fec = BF_FEC_TYP_NONE, .port_type = 3 },
      { .dev_port = 7, .speed = BF_SPEED_10G, .fec = BF_FEC_TYP_NONE, .port_type = 3 },

      { .dev_port = 8, .speed = BF_SPEED_10G, .fec = BF_FEC_TYP_NONE, .port_type = 5 },
    };

    p4_pd_entry_hdl_t entry_hdl;
    p4_pd_sess_hdl_t sess_hdl;
    p4_pd_dev_target_t dev_tgt = { .device_id = BF_DEV_ID, .dev_pipe_id = BF_DEV_PIPE_ALL };

    if (p4_pd_client_init(&sess_hdl) == PIPE_SUCCESS)
    {
      int i;
      printf("Configuring.\n");
      p4_pd_balancer_calc_mpls_offset_set_default_action__nop(sess_hdl, dev_tgt, &entry_hdl);
      p4_pd_balancer_set_port_metadata_set_default_action__drop(sess_hdl, dev_tgt, &entry_hdl);
      p4_pd_balancer_bypass_mode_set_default_action__nop(sess_hdl, dev_tgt, &entry_hdl);
      p4_pd_balancer_forward_lacp_bfd_set_default_action__nop(sess_hdl, dev_tgt, &entry_hdl);
      p4_pd_balancer_forward_multicast_mpls_set_default_action__nop(sess_hdl, dev_tgt, &entry_hdl);
      p4_pd_balancer_forward_multicast_ipv4_set_default_action__nop(sess_hdl, dev_tgt, &entry_hdl);
      p4_pd_balancer_forward_multicast_ipv6_set_default_action__nop(sess_hdl, dev_tgt, &entry_hdl);
      p4_pd_balancer_aggregate_bypass_set_default_action__nop(sess_hdl, dev_tgt, &entry_hdl);
      p4_pd_balancer_get_flow_ports_set_default_action__nop(sess_hdl, dev_tgt, &entry_hdl);
      p4_pd_balancer_tbl_dpi_lan_ipv4_hash_set_default_action__nop(sess_hdl, dev_tgt, &entry_hdl);
      p4_pd_balancer_tbl_dpi_wan_ipv4_hash_set_default_action__nop(sess_hdl, dev_tgt, &entry_hdl);
      p4_pd_balancer_tbl_dpi_lan_ipv6_hash_set_default_action__nop(sess_hdl, dev_tgt, &entry_hdl);
      p4_pd_balancer_tbl_dpi_wan_ipv6_hash_set_default_action__nop(sess_hdl, dev_tgt, &entry_hdl);
      p4_pd_balancer_tbl_dpi_lan_imac_hash_set_default_action__nop(sess_hdl, dev_tgt, &entry_hdl);
      p4_pd_balancer_tbl_dpi_lan_omac_hash_set_default_action__nop(sess_hdl, dev_tgt, &entry_hdl);
      p4_pd_balancer_set_valid_hash_set_default_action__nop(sess_hdl, dev_tgt, &entry_hdl);
      p4_pd_balancer_update_byte_counters_set_default_action__nop(sess_hdl, dev_tgt, &entry_hdl);
      p4_pd_balancer_update_packet_counters_set_default_action__nop(sess_hdl, dev_tgt, &entry_hdl);
      p4_pd_balancer_tbl_flow_hash_lan_ipv4_set_default_action__nop(sess_hdl, dev_tgt, &entry_hdl);
      p4_pd_balancer_tbl_flow_hash_wan_ipv4_set_default_action__nop(sess_hdl, dev_tgt, &entry_hdl);
      p4_pd_balancer_tbl_flow_hash_parts_ipv4_set_default_action__nop(sess_hdl, dev_tgt, &entry_hdl);
      p4_pd_balancer_tbl_flow_hash_lan_ipv6_set_default_action__nop(sess_hdl, dev_tgt, &entry_hdl);
      p4_pd_balancer_tbl_flow_hash_wan_ipv6_set_default_action__nop(sess_hdl, dev_tgt, &entry_hdl);
      p4_pd_balancer_tbl_flow_hash_parts_ipv6_set_default_action__nop(sess_hdl, dev_tgt, &entry_hdl);
      p4_pd_balancer_tbl_flow_hash_lan_imac_set_default_action__nop(sess_hdl, dev_tgt, &entry_hdl);
      p4_pd_balancer_tbl_flow_hash_wan_imac_set_default_action__nop(sess_hdl, dev_tgt, &entry_hdl);
      p4_pd_balancer_tbl_flow_hash_parts_imac_set_default_action__nop(sess_hdl, dev_tgt, &entry_hdl);
      p4_pd_balancer_tbl_flow_hash_lan_omac_set_default_action__nop(sess_hdl, dev_tgt, &entry_hdl);
      p4_pd_balancer_tbl_flow_hash_wan_omac_set_default_action__nop(sess_hdl, dev_tgt, &entry_hdl);
      p4_pd_balancer_tbl_flow_hash_parts_omac_set_default_action__nop(sess_hdl, dev_tgt, &entry_hdl);
      p4_pd_balancer_set_flow_hash_set_default_action__nop(sess_hdl, dev_tgt, &entry_hdl);
      p4_pd_balancer_set_dpi_output_set_default_action__nop(sess_hdl, dev_tgt, &entry_hdl);
      p4_pd_balancer_forward_log_set_default_action__nop(sess_hdl, dev_tgt, &entry_hdl);
      p4_pd_balancer_drop_if_no_ebheader_set_default_action__nop(sess_hdl, dev_tgt, &entry_hdl);
      p4_pd_balancer_dpi_set_egress_port_set_default_action__nop(sess_hdl, dev_tgt, &entry_hdl);
      p4_pd_balancer_add_ebheader_set_default_action__nop(sess_hdl, dev_tgt, &entry_hdl);
      p4_pd_balancer_remove_ebheader_set_default_action__nop(sess_hdl, dev_tgt, &entry_hdl);

      for (i = 0; i < COUNT(port_cfg); ++ i)
      {
        {
          p4_pd_balancer_set_port_metadata_match_spec_t match_spec = { 0 };
          p4_pd_balancer_do_set_port_metadata_action_spec_t action_spec = { 0 };

          match_spec.ig_intr_md_ingress_port = port_cfg[i].dev_port;

          action_spec.action_port_type = port_cfg[i].port_type;
          action_spec.action_is_lan = port_cfg[i].port_type == 1 ? 1 : 0;
          action_spec.action_is_nat = 0;
          action_spec.action_linked_port = port_cfg[i].dev_linked_port;
          action_spec.action_is_lanwan = port_cfg[i].port_type == 1 || port_cfg[i].port_type == 2 ? 1 : 0;

          p4_pd_balancer_set_port_metadata_table_add_with_do_set_port_metadata(sess_hdl, dev_tgt, &match_spec, &action_spec, &entry_hdl);
        }
      }
      for (i = 0; i < COUNT(port_cfg); ++ i)
      {
        if (!port_cfg[i].forward_multicast)
        {
          continue;
        }
        {
          p4_pd_balancer_forward_multicast_mpls_match_spec_t match_spec = { 0 };

          match_spec.ig_intr_md_ingress_port = port_cfg[i].dev_port;
          match_spec.outer_ethernet_etherType = 0x8848;

          p4_pd_balancer_forward_multicast_mpls_table_add_with_mark_bypass_multi_mpls(sess_hdl, dev_tgt, &match_spec, &entry_hdl);
        }
        {
          p4_pd_balancer_forward_multicast_ipv4_match_spec_t match_spec = { 0 };

          match_spec.ig_intr_md_ingress_port = port_cfg[i].dev_port;
          match_spec.outer_ipv4_valid = 1;
          match_spec.outer_ipv4_dstAddr = 224 << 24;
          match_spec.outer_ipv4_dstAddr_prefix_length = 4;

          p4_pd_balancer_forward_multicast_ipv4_table_add_with_mark_bypass_multi4(sess_hdl, dev_tgt, &match_spec, &entry_hdl);
        }
        {
          p4_pd_balancer_forward_multicast_ipv6_match_spec_t match_spec = { 0 };

          match_spec.ig_intr_md_ingress_port = port_cfg[i].dev_port;
          match_spec.outer_ipv6_valid = 0;
          memset(match_spec.outer_ipv6_dstAddr, 0, sizeof(match_spec.outer_ipv6_dstAddr));
          match_spec.outer_ipv6_dstAddr[0] = 0xff;
          match_spec.outer_ipv6_dstAddr_prefix_length = 8;

          p4_pd_balancer_forward_multicast_ipv6_table_add_with_mark_bypass_multi6(sess_hdl, dev_tgt, &match_spec, &entry_hdl);
        }
      }
      //for (i = 0; i < COUNT(port_cfg); ++ i)
      {
        p4_pd_balancer_forward_lacp_bfd_match_spec_t match_spec = { 0 };

        match_spec.ebmeta_port_type = 1;
        match_spec.slow_proto_valid = 1;
        match_spec.slow_proto_subtype = 1;
        match_spec.udp_valid = 0;
        match_spec.udp_portDst = 0;

        p4_pd_balancer_forward_lacp_bfd_table_add_with_mark_bypass_lacp_bfd(sess_hdl, dev_tgt, &match_spec, &entry_hdl);

        match_spec.ebmeta_port_type = 2;
        match_spec.slow_proto_valid = 1;
        match_spec.slow_proto_subtype = 1;
        match_spec.udp_valid = 0;
        match_spec.udp_portDst = 0;

        p4_pd_balancer_forward_lacp_bfd_table_add_with_mark_bypass_lacp_bfd(sess_hdl, dev_tgt, &match_spec, &entry_hdl);

        match_spec.ebmeta_port_type = 1;
        match_spec.slow_proto_valid = 0;
        match_spec.slow_proto_subtype = 0;
        match_spec.udp_valid = 1;
        match_spec.udp_portDst = 3784;

        p4_pd_balancer_forward_lacp_bfd_table_add_with_mark_bypass_lacp_bfd(sess_hdl, dev_tgt, &match_spec, &entry_hdl);

        match_spec.ebmeta_port_type = 2;
        match_spec.slow_proto_valid = 0;
        match_spec.slow_proto_subtype = 0;
        match_spec.udp_valid = 1;
        match_spec.udp_portDst = 3784;

        p4_pd_balancer_forward_lacp_bfd_table_add_with_mark_bypass_lacp_bfd(sess_hdl, dev_tgt, &match_spec, &entry_hdl);

        match_spec.ebmeta_port_type = 1;
        match_spec.slow_proto_valid = 0;
        match_spec.slow_proto_subtype = 0;
        match_spec.udp_valid = 1;
        match_spec.udp_portDst = 3785;

        p4_pd_balancer_forward_lacp_bfd_table_add_with_mark_bypass_lacp_bfd(sess_hdl, dev_tgt, &match_spec, &entry_hdl);

        match_spec.ebmeta_port_type = 2;
        match_spec.slow_proto_valid = 0;
        match_spec.slow_proto_subtype = 0;
        match_spec.udp_valid = 1;
        match_spec.udp_portDst = 3785;

        p4_pd_balancer_forward_lacp_bfd_table_add_with_mark_bypass_lacp_bfd(sess_hdl, dev_tgt, &match_spec, &entry_hdl);
      }
      for (i = 0; i < COUNT(port_cfg); ++ i)
      {
        {
          p4_pd_balancer_tbl_dpi_lan_ipv4_hash_match_spec_t match_spec = { 0 };
          if (port_cfg[i].port_type == 1)
          {
            match_spec.ig_intr_md_ingress_port = port_cfg[i].dev_port;
            match_spec.outer_ipv4_valid = 1;

            if (port_cfg[i].is_nat)
            {
              p4_pd_balancer_tbl_dpi_lan_ipv4_hash_table_add_with_calc_dpi_lan_ipv4_nat_hash(sess_hdl, dev_tgt, &match_spec, &entry_hdl);
            }
            else
            {
              p4_pd_balancer_tbl_dpi_lan_ipv4_hash_table_add_with_calc_dpi_lan_ipv4_mag_hash(sess_hdl, dev_tgt, &match_spec, &entry_hdl);
            }
          }
        }
        {
          p4_pd_balancer_tbl_dpi_wan_ipv4_hash_match_spec_t match_spec = { 0 };
          if (port_cfg[i].port_type == 2)
          {
            match_spec.ig_intr_md_ingress_port = port_cfg[i].dev_port;
            match_spec.outer_ipv4_valid = 1;

            if (port_cfg[i].is_nat)
            {
              p4_pd_balancer_tbl_dpi_wan_ipv4_hash_table_add_with_calc_dpi_wan_ipv4_nat_hash(sess_hdl, dev_tgt, &match_spec, &entry_hdl);
            }
            else
            {
              p4_pd_balancer_tbl_dpi_wan_ipv4_hash_table_add_with_calc_dpi_wan_ipv4_mag_hash(sess_hdl, dev_tgt, &match_spec, &entry_hdl);
            }
          }
        }
        {
          p4_pd_balancer_tbl_dpi_lan_ipv6_hash_match_spec_t match_spec = { 0 };
          if (port_cfg[i].port_type == 1)
          {
            match_spec.ig_intr_md_ingress_port = port_cfg[i].dev_port;
            match_spec.outer_ipv6_valid = 1;

            if (port_cfg[i].is_nat)
            {
              p4_pd_balancer_tbl_dpi_lan_ipv6_hash_table_add_with_calc_dpi_lan_ipv6_nat_hash(sess_hdl, dev_tgt, &match_spec, &entry_hdl);
            }
            else
            {
              p4_pd_balancer_tbl_dpi_lan_ipv6_hash_table_add_with_calc_dpi_lan_ipv6_mag_hash(sess_hdl, dev_tgt, &match_spec, &entry_hdl);
            }
          }
        }
        {
          p4_pd_balancer_tbl_dpi_wan_ipv6_hash_match_spec_t match_spec = { 0 };
          if (port_cfg[i].port_type == 2)
          {
            match_spec.ig_intr_md_ingress_port = port_cfg[i].dev_port;
            match_spec.outer_ipv6_valid = 1;

            if (port_cfg[i].is_nat)
            {
              p4_pd_balancer_tbl_dpi_wan_ipv6_hash_table_add_with_calc_dpi_wan_ipv6_nat_hash(sess_hdl, dev_tgt, &match_spec, &entry_hdl);
            }
            else
            {
              p4_pd_balancer_tbl_dpi_wan_ipv6_hash_table_add_with_calc_dpi_wan_ipv6_mag_hash(sess_hdl, dev_tgt, &match_spec, &entry_hdl);
            }
          }
        }
        {
          p4_pd_balancer_tbl_dpi_lan_imac_hash_match_spec_t match_spec = { 0 };
          if (port_cfg[i].port_type == 1)
          {
            match_spec.ig_intr_md_ingress_port = port_cfg[i].dev_port;
            match_spec.outer_ipv4_valid = 0;
            match_spec.outer_ipv6_valid = 0;
            match_spec.inner_ethernet_valid = 1;

            if (port_cfg[i].is_nat)
            {
              p4_pd_balancer_tbl_dpi_lan_imac_hash_table_add_with_calc_dpi_lan_inner_mac_nat_hash(sess_hdl, dev_tgt, &match_spec, &entry_hdl);
            }
            else
            {
              p4_pd_balancer_tbl_dpi_lan_imac_hash_table_add_with_calc_dpi_lan_inner_mac_mag_hash(sess_hdl, dev_tgt, &match_spec, &entry_hdl);
            }
          }
        }
        {
          p4_pd_balancer_tbl_dpi_wan_imac_hash_match_spec_t match_spec = { 0 };
          if (port_cfg[i].port_type == 2)
          {
            match_spec.ig_intr_md_ingress_port = port_cfg[i].dev_port;
            match_spec.outer_ipv4_valid = 0;
            match_spec.outer_ipv6_valid = 0;
            match_spec.inner_ethernet_valid = 1;

            if (port_cfg[i].is_nat)
            {
              p4_pd_balancer_tbl_dpi_wan_imac_hash_table_add_with_calc_dpi_wan_inner_mac_nat_hash(sess_hdl, dev_tgt, &match_spec, &entry_hdl);
            }
            else
            {
              p4_pd_balancer_tbl_dpi_wan_imac_hash_table_add_with_calc_dpi_wan_inner_mac_mag_hash(sess_hdl, dev_tgt, &match_spec, &entry_hdl);
            }
          }
        }
        {
          p4_pd_balancer_tbl_dpi_lan_omac_hash_match_spec_t match_spec = { 0 };
          if (port_cfg[i].port_type == 1)
          {
            match_spec.ig_intr_md_ingress_port = port_cfg[i].dev_port;
            match_spec.outer_ipv4_valid = 0;
            match_spec.outer_ipv6_valid = 0;
            match_spec.inner_ethernet_valid = 0;

            if (port_cfg[i].is_nat)
            {
              p4_pd_balancer_tbl_dpi_lan_omac_hash_table_add_with_calc_dpi_lan_outer_mac_nat_hash(sess_hdl, dev_tgt, &match_spec, &entry_hdl);
            }
            else
            {
              p4_pd_balancer_tbl_dpi_lan_omac_hash_table_add_with_calc_dpi_lan_outer_mac_mag_hash(sess_hdl, dev_tgt, &match_spec, &entry_hdl);
            }
          }
        }
        {
          p4_pd_balancer_tbl_dpi_wan_omac_hash_match_spec_t match_spec = { 0 };
          if (port_cfg[i].port_type == 2)
          {
            match_spec.ig_intr_md_ingress_port = port_cfg[i].dev_port;
            match_spec.outer_ipv4_valid = 0;
            match_spec.outer_ipv6_valid = 0;
            match_spec.inner_ethernet_valid = 0;

            if (port_cfg[i].is_nat)
            {
              p4_pd_balancer_tbl_dpi_wan_omac_hash_table_add_with_calc_dpi_wan_outer_mac_nat_hash(sess_hdl, dev_tgt, &match_spec, &entry_hdl);
            }
            else
            {
              p4_pd_balancer_tbl_dpi_wan_omac_hash_table_add_with_calc_dpi_wan_outer_mac_mag_hash(sess_hdl, dev_tgt, &match_spec, &entry_hdl);
            }
          }
        }
      }
      {
        p4_pd_balancer_set_valid_hash_match_spec_t match_spec = { 0 };

        match_spec.ebmeta_port_type = 1;
        match_spec.outer_ipv4_valid = 1;
        match_spec.outer_ipv6_valid = 0;
        match_spec.inner_ethernet_valid = 0;

        p4_pd_balancer_set_valid_hash_table_add_with_choose_lan_ipv4_hash(sess_hdl, dev_tgt, &match_spec, &entry_hdl);

        match_spec.ebmeta_port_type = 2;
        match_spec.outer_ipv4_valid = 1;
        match_spec.outer_ipv6_valid = 0;
        match_spec.inner_ethernet_valid = 0;

        p4_pd_balancer_set_valid_hash_table_add_with_choose_wan_ipv4_hash(sess_hdl, dev_tgt, &match_spec, &entry_hdl);

        match_spec.ebmeta_port_type = 1;
        match_spec.outer_ipv4_valid = 1;
        match_spec.outer_ipv6_valid = 0;
        match_spec.inner_ethernet_valid = 1;

        p4_pd_balancer_set_valid_hash_table_add_with_choose_lan_ipv4_hash(sess_hdl, dev_tgt, &match_spec, &entry_hdl);

        match_spec.ebmeta_port_type = 2;
        match_spec.outer_ipv4_valid = 1;
        match_spec.outer_ipv6_valid = 0;
        match_spec.inner_ethernet_valid = 1;

        p4_pd_balancer_set_valid_hash_table_add_with_choose_wan_ipv4_hash(sess_hdl, dev_tgt, &match_spec, &entry_hdl);

        match_spec.ebmeta_port_type = 1;
        match_spec.outer_ipv4_valid = 0;
        match_spec.outer_ipv6_valid = 1;
        match_spec.inner_ethernet_valid = 0;

        p4_pd_balancer_set_valid_hash_table_add_with_choose_lan_ipv6_hash(sess_hdl, dev_tgt, &match_spec, &entry_hdl);

        match_spec.ebmeta_port_type = 2;
        match_spec.outer_ipv4_valid = 0;
        match_spec.outer_ipv6_valid = 1;
        match_spec.inner_ethernet_valid = 0;

        p4_pd_balancer_set_valid_hash_table_add_with_choose_wan_ipv6_hash(sess_hdl, dev_tgt, &match_spec, &entry_hdl);

        match_spec.ebmeta_port_type = 1;
        match_spec.outer_ipv4_valid = 0;
        match_spec.outer_ipv6_valid = 1;
        match_spec.inner_ethernet_valid = 1;

        p4_pd_balancer_set_valid_hash_table_add_with_choose_lan_ipv6_hash(sess_hdl, dev_tgt, &match_spec, &entry_hdl);

        match_spec.ebmeta_port_type = 2;
        match_spec.outer_ipv4_valid = 0;
        match_spec.outer_ipv6_valid = 1;
        match_spec.inner_ethernet_valid = 1;

        p4_pd_balancer_set_valid_hash_table_add_with_choose_wan_ipv6_hash(sess_hdl, dev_tgt, &match_spec, &entry_hdl);

        match_spec.ebmeta_port_type = 1;
        match_spec.outer_ipv4_valid = 0;
        match_spec.outer_ipv6_valid = 0;
        match_spec.inner_ethernet_valid = 0;

        p4_pd_balancer_set_valid_hash_table_add_with_choose_lan_outer_mac_hash(sess_hdl, dev_tgt, &match_spec, &entry_hdl);

        match_spec.ebmeta_port_type = 2;
        match_spec.outer_ipv4_valid = 0;
        match_spec.outer_ipv6_valid = 0;
        match_spec.inner_ethernet_valid = 0;

        p4_pd_balancer_set_valid_hash_table_add_with_choose_wan_outer_mac_hash(sess_hdl, dev_tgt, &match_spec, &entry_hdl);

        match_spec.ebmeta_port_type = 1;
        match_spec.outer_ipv4_valid = 0;
        match_spec.outer_ipv6_valid = 0;
        match_spec.inner_ethernet_valid = 1;

        p4_pd_balancer_set_valid_hash_table_add_with_choose_lan_inner_mac_hash(sess_hdl, dev_tgt, &match_spec, &entry_hdl);

        match_spec.ebmeta_port_type = 2;
        match_spec.outer_ipv4_valid = 0;
        match_spec.outer_ipv6_valid = 0;
        match_spec.inner_ethernet_valid = 1;

        p4_pd_balancer_set_valid_hash_table_add_with_choose_wan_inner_mac_hash(sess_hdl, dev_tgt, &match_spec, &entry_hdl);
      }
      {

        p4_pd_balancer_calc_mpls_offset_match_spec_t match_spec = { 0 };
        p4_pd_balancer_set_mpls_offset_action_spec_t action_spec = { 0 };

        match_spec.mpls_0__valid = 1;
        match_spec.outer_vlan_0__valid = 0;
        match_spec.outer_vlan_1__valid = 0;
        match_spec.outer_vlan_2__valid = 0;
        match_spec.outer_vlan_3__valid = 0;
        match_spec.outer_vlan_4__valid = 0;

        action_spec.action_offset = 14 + 4 * 0;

        p4_pd_balancer_calc_mpls_offset_table_add_with_set_mpls_offset(sess_hdl, dev_tgt, &match_spec, &action_spec, &entry_hdl);

        match_spec.mpls_0__valid = 1;
        match_spec.outer_vlan_0__valid = 1;
        match_spec.outer_vlan_1__valid = 0;
        match_spec.outer_vlan_2__valid = 0;
        match_spec.outer_vlan_3__valid = 0;
        match_spec.outer_vlan_4__valid = 0;

        action_spec.action_offset = 14 + 4 * 1;

        p4_pd_balancer_calc_mpls_offset_table_add_with_set_mpls_offset(sess_hdl, dev_tgt, &match_spec, &action_spec, &entry_hdl);

        match_spec.mpls_0__valid = 1;
        match_spec.outer_vlan_0__valid = 1;
        match_spec.outer_vlan_1__valid = 1;
        match_spec.outer_vlan_2__valid = 0;
        match_spec.outer_vlan_3__valid = 0;
        match_spec.outer_vlan_4__valid = 0;

        action_spec.action_offset = 14 + 4 * 2;

        p4_pd_balancer_calc_mpls_offset_table_add_with_set_mpls_offset(sess_hdl, dev_tgt, &match_spec, &action_spec, &entry_hdl);

        match_spec.mpls_0__valid = 1;
        match_spec.outer_vlan_0__valid = 1;
        match_spec.outer_vlan_1__valid = 1;
        match_spec.outer_vlan_2__valid = 1;
        match_spec.outer_vlan_3__valid = 0;
        match_spec.outer_vlan_4__valid = 0;

        action_spec.action_offset = 14 + 4 * 3;

        p4_pd_balancer_calc_mpls_offset_table_add_with_set_mpls_offset(sess_hdl, dev_tgt, &match_spec, &action_spec, &entry_hdl);

        match_spec.mpls_0__valid = 1;
        match_spec.outer_vlan_0__valid = 1;
        match_spec.outer_vlan_1__valid = 1;
        match_spec.outer_vlan_2__valid = 1;
        match_spec.outer_vlan_3__valid = 1;
        match_spec.outer_vlan_4__valid = 0;

        action_spec.action_offset = 14 + 4 * 4;

        p4_pd_balancer_calc_mpls_offset_table_add_with_set_mpls_offset(sess_hdl, dev_tgt, &match_spec, &action_spec, &entry_hdl);

        match_spec.mpls_0__valid = 1;
        match_spec.outer_vlan_0__valid = 1;
        match_spec.outer_vlan_1__valid = 1;
        match_spec.outer_vlan_2__valid = 1;
        match_spec.outer_vlan_3__valid = 1;
        match_spec.outer_vlan_4__valid = 1;

        action_spec.action_offset = 14 + 4 * 5;

        p4_pd_balancer_calc_mpls_offset_table_add_with_set_mpls_offset(sess_hdl, dev_tgt, &match_spec, &action_spec, &entry_hdl);
      }
#if 0
      {
/** Отдельная ипостасия **/
        p4_pd_balancer_bypass_mode_match_spec_t match_spec = { 0 };

        match_spec.ebmeta_port_type = 0;

        p4_pd_balancer_bypass_mode_table_add_with_mark_bypass_mode(sess_hdl, dev_tgt, &match_spec, &entry_hdl);
      }
#endif
      {
        p4_pd_balancer_aggregate_bypass_match_spec_t match_spec = { 0 };

        match_spec.bypass_meta_mode_enabled = 1;
        match_spec.bypass_meta_lacp_bfd = 0;
        match_spec.bypass_meta_multi4 = 0;
        match_spec.bypass_meta_multi6 = 0;
        match_spec.bypass_meta_multi_mpls = 0;

        p4_pd_balancer_aggregate_bypass_table_add_with_do_bypass(sess_hdl, dev_tgt, &match_spec, &entry_hdl);

        match_spec.bypass_meta_mode_enabled = 1;
        match_spec.bypass_meta_lacp_bfd = 1;
        match_spec.bypass_meta_multi4 = 0;
        match_spec.bypass_meta_multi6 = 0;
        match_spec.bypass_meta_multi_mpls = 0;

        p4_pd_balancer_aggregate_bypass_table_add_with_do_bypass(sess_hdl, dev_tgt, &match_spec, &entry_hdl);

        match_spec.bypass_meta_mode_enabled = 1;
        match_spec.bypass_meta_lacp_bfd = 1;
        match_spec.bypass_meta_multi4 = 0;
        match_spec.bypass_meta_multi6 = 0;
        match_spec.bypass_meta_multi_mpls = 1;

        p4_pd_balancer_aggregate_bypass_table_add_with_do_bypass(sess_hdl, dev_tgt, &match_spec, &entry_hdl);

        match_spec.bypass_meta_mode_enabled = 1;
        match_spec.bypass_meta_lacp_bfd = 0;
        match_spec.bypass_meta_multi4 = 0;
        match_spec.bypass_meta_multi6 = 0;
        match_spec.bypass_meta_multi_mpls = 1;

        p4_pd_balancer_aggregate_bypass_table_add_with_do_bypass(sess_hdl, dev_tgt, &match_spec, &entry_hdl);

        match_spec.bypass_meta_mode_enabled = 1;
        match_spec.bypass_meta_lacp_bfd = 0;
        match_spec.bypass_meta_multi4 = 1;
        match_spec.bypass_meta_multi6 = 0;
        match_spec.bypass_meta_multi_mpls = 0;

        p4_pd_balancer_aggregate_bypass_table_add_with_do_bypass(sess_hdl, dev_tgt, &match_spec, &entry_hdl);

        match_spec.bypass_meta_mode_enabled = 1;
        match_spec.bypass_meta_lacp_bfd = 0;
        match_spec.bypass_meta_multi4 = 1;
        match_spec.bypass_meta_multi6 = 0;
        match_spec.bypass_meta_multi_mpls = 1;

        p4_pd_balancer_aggregate_bypass_table_add_with_do_bypass(sess_hdl, dev_tgt, &match_spec, &entry_hdl);

        match_spec.bypass_meta_mode_enabled = 1;
        match_spec.bypass_meta_lacp_bfd = 0;
        match_spec.bypass_meta_multi4 = 0;
        match_spec.bypass_meta_multi6 = 1;
        match_spec.bypass_meta_multi_mpls = 0;

        p4_pd_balancer_aggregate_bypass_table_add_with_do_bypass(sess_hdl, dev_tgt, &match_spec, &entry_hdl);

        match_spec.bypass_meta_mode_enabled = 1;
        match_spec.bypass_meta_lacp_bfd = 0;
        match_spec.bypass_meta_multi4 = 0;
        match_spec.bypass_meta_multi6 = 1;
        match_spec.bypass_meta_multi_mpls = 1;

        p4_pd_balancer_aggregate_bypass_table_add_with_do_bypass(sess_hdl, dev_tgt, &match_spec, &entry_hdl);

        match_spec.bypass_meta_mode_enabled = 0;
        match_spec.bypass_meta_lacp_bfd = 1;
        match_spec.bypass_meta_multi4 = 0;
        match_spec.bypass_meta_multi6 = 0;
        match_spec.bypass_meta_multi_mpls = 0;

        p4_pd_balancer_aggregate_bypass_table_add_with_do_bypass(sess_hdl, dev_tgt, &match_spec, &entry_hdl);

        match_spec.bypass_meta_mode_enabled = 0;
        match_spec.bypass_meta_lacp_bfd = 1;
        match_spec.bypass_meta_multi4 = 0;
        match_spec.bypass_meta_multi6 = 0;
        match_spec.bypass_meta_multi_mpls = 1;

        p4_pd_balancer_aggregate_bypass_table_add_with_do_bypass(sess_hdl, dev_tgt, &match_spec, &entry_hdl);

        match_spec.bypass_meta_mode_enabled = 0;
        match_spec.bypass_meta_lacp_bfd = 0;
        match_spec.bypass_meta_multi4 = 0;
        match_spec.bypass_meta_multi6 = 0;
        match_spec.bypass_meta_multi_mpls = 1;

        p4_pd_balancer_aggregate_bypass_table_add_with_do_bypass(sess_hdl, dev_tgt, &match_spec, &entry_hdl);

        match_spec.bypass_meta_mode_enabled = 0;
        match_spec.bypass_meta_lacp_bfd = 0;
        match_spec.bypass_meta_multi4 = 1;
        match_spec.bypass_meta_multi6 = 0;
        match_spec.bypass_meta_multi_mpls = 0;

        p4_pd_balancer_aggregate_bypass_table_add_with_do_bypass(sess_hdl, dev_tgt, &match_spec, &entry_hdl);

        match_spec.bypass_meta_mode_enabled = 0;
        match_spec.bypass_meta_lacp_bfd = 0;
        match_spec.bypass_meta_multi4 = 1;
        match_spec.bypass_meta_multi6 = 0;
        match_spec.bypass_meta_multi_mpls = 1;

        p4_pd_balancer_aggregate_bypass_table_add_with_do_bypass(sess_hdl, dev_tgt, &match_spec, &entry_hdl);

        match_spec.bypass_meta_mode_enabled = 0;
        match_spec.bypass_meta_lacp_bfd = 0;
        match_spec.bypass_meta_multi4 = 0;
        match_spec.bypass_meta_multi6 = 1;
        match_spec.bypass_meta_multi_mpls = 0;

        p4_pd_balancer_aggregate_bypass_table_add_with_do_bypass(sess_hdl, dev_tgt, &match_spec, &entry_hdl);

        match_spec.bypass_meta_mode_enabled = 0;
        match_spec.bypass_meta_lacp_bfd = 0;
        match_spec.bypass_meta_multi4 = 0;
        match_spec.bypass_meta_multi6 = 1;
        match_spec.bypass_meta_multi_mpls = 1;

        p4_pd_balancer_aggregate_bypass_table_add_with_do_bypass(sess_hdl, dev_tgt, &match_spec, &entry_hdl);
      }
      {
        p4_pd_balancer_get_flow_ports_match_spec_t match_spec = { 0 };

        match_spec.tcp_valid = 1;
        match_spec.udp_valid = 0;
        match_spec.sctp_valid = 0;
        match_spec.udplite_valid = 0;

        p4_pd_balancer_get_flow_ports_table_add_with_set_tcp_flow_data(sess_hdl, dev_tgt, &match_spec, &entry_hdl);

        match_spec.tcp_valid = 0;
        match_spec.udp_valid = 1;
        match_spec.sctp_valid = 0;
        match_spec.udplite_valid = 0;

        p4_pd_balancer_get_flow_ports_table_add_with_set_udp_flow_data(sess_hdl, dev_tgt, &match_spec, &entry_hdl);

        match_spec.tcp_valid = 0;
        match_spec.udp_valid = 0;
        match_spec.sctp_valid = 1;
        match_spec.udplite_valid = 0;

        p4_pd_balancer_get_flow_ports_table_add_with_set_sctp_flow_data(sess_hdl, dev_tgt, &match_spec, &entry_hdl);

        match_spec.tcp_valid = 0;
        match_spec.udp_valid = 0;
        match_spec.sctp_valid = 0;
        match_spec.udplite_valid = 1;

        p4_pd_balancer_get_flow_ports_table_add_with_set_udplite_flow_data(sess_hdl, dev_tgt, &match_spec, &entry_hdl);
      }
      {
        p4_pd_balancer_update_byte_counters_match_spec_t match_spec = { 0 };

        match_spec.ebmeta_port_type = 1;

        p4_pd_balancer_update_byte_counters_table_add_with_do_update_byte_counters(sess_hdl, dev_tgt, &match_spec, &entry_hdl);

        match_spec.ebmeta_port_type = 2;

        p4_pd_balancer_update_byte_counters_table_add_with_do_update_byte_counters(sess_hdl, dev_tgt, &match_spec, &entry_hdl);
      }
      {
        p4_pd_balancer_update_packet_counters_match_spec_t match_spec = { 0 };

        match_spec.ebmeta_port_type = 1;

        p4_pd_balancer_update_packet_counters_table_add_with_do_update_packet_counters(sess_hdl, dev_tgt, &match_spec, &entry_hdl);

        match_spec.ebmeta_port_type = 2;

        p4_pd_balancer_update_packet_counters_table_add_with_do_update_packet_counters(sess_hdl, dev_tgt, &match_spec, &entry_hdl);
      }

      {
        p4_pd_balancer_tbl_flow_hash_lan_ipv4_match_spec_t match_spec = { 0 };

        match_spec.ebmeta_port_type = 1;
        match_spec.outer_ipv4_valid = 1;

        p4_pd_balancer_tbl_flow_hash_lan_ipv4_table_add_with_calc_flow_lan_ipv4(sess_hdl, dev_tgt, &match_spec, &entry_hdl);
      }
      {
        p4_pd_balancer_tbl_flow_hash_wan_ipv4_match_spec_t match_spec = { 0 };

        match_spec.ebmeta_port_type = 2;
        match_spec.outer_ipv4_valid = 1;

        p4_pd_balancer_tbl_flow_hash_wan_ipv4_table_add_with_calc_flow_wan_ipv4(sess_hdl, dev_tgt, &match_spec, &entry_hdl);
      }
      {
        p4_pd_balancer_tbl_flow_hash_parts_ipv4_match_spec_t match_spec = { 0 };

        match_spec.ebmeta_port_type = 1;
        match_spec.outer_ipv4_valid = 1;

        p4_pd_balancer_tbl_flow_hash_parts_ipv4_table_add_with_calc_flow_parts_ipv4(sess_hdl, dev_tgt, &match_spec, &entry_hdl);

        match_spec.ebmeta_port_type = 2;
        match_spec.outer_ipv4_valid = 1;

        p4_pd_balancer_tbl_flow_hash_parts_ipv4_table_add_with_calc_flow_parts_ipv4(sess_hdl, dev_tgt, &match_spec, &entry_hdl);
      }
      {
        p4_pd_balancer_tbl_flow_hash_lan_ipv6_match_spec_t match_spec = { 0 };

        match_spec.ebmeta_port_type = 1;
        match_spec.outer_ipv6_valid = 1;

        p4_pd_balancer_tbl_flow_hash_lan_ipv6_table_add_with_calc_flow_lan_ipv6(sess_hdl, dev_tgt, &match_spec, &entry_hdl);
      }
      {
        p4_pd_balancer_tbl_flow_hash_wan_ipv6_match_spec_t match_spec = { 0 };

        match_spec.ebmeta_port_type = 2;
        match_spec.outer_ipv6_valid = 1;

        p4_pd_balancer_tbl_flow_hash_wan_ipv6_table_add_with_calc_flow_wan_ipv6(sess_hdl, dev_tgt, &match_spec, &entry_hdl);
      }
      {
        p4_pd_balancer_tbl_flow_hash_parts_ipv6_match_spec_t match_spec = { 0 };

        match_spec.ebmeta_port_type = 1;
        match_spec.outer_ipv6_valid = 1;

        p4_pd_balancer_tbl_flow_hash_parts_ipv6_table_add_with_calc_flow_parts_ipv6(sess_hdl, dev_tgt, &match_spec, &entry_hdl);

        match_spec.ebmeta_port_type = 2;
        match_spec.outer_ipv6_valid = 1;

        p4_pd_balancer_tbl_flow_hash_parts_ipv6_table_add_with_calc_flow_parts_ipv6(sess_hdl, dev_tgt, &match_spec, &entry_hdl);
      }
      {
        p4_pd_balancer_tbl_flow_hash_lan_imac_match_spec_t match_spec = { 0 };

        match_spec.ebmeta_port_type = 1;
        match_spec.outer_ipv4_valid = 0;
        match_spec.outer_ipv6_valid = 0;
        match_spec.inner_ethernet_valid = 1;

        p4_pd_balancer_tbl_flow_hash_lan_imac_table_add_with_calc_flow_lan_imac(sess_hdl, dev_tgt, &match_spec, &entry_hdl);
      }
      {
        p4_pd_balancer_tbl_flow_hash_wan_imac_match_spec_t match_spec = { 0 };

        match_spec.ebmeta_port_type = 2;
        match_spec.outer_ipv4_valid = 0;
        match_spec.outer_ipv6_valid = 0;
        match_spec.inner_ethernet_valid = 1;

        p4_pd_balancer_tbl_flow_hash_wan_imac_table_add_with_calc_flow_wan_imac(sess_hdl, dev_tgt, &match_spec, &entry_hdl);
      }
      {
        p4_pd_balancer_tbl_flow_hash_parts_imac_match_spec_t match_spec = { 0 };

        match_spec.ebmeta_port_type = 1;
        match_spec.outer_ipv4_valid = 0;
        match_spec.outer_ipv6_valid = 0;
        match_spec.inner_ethernet_valid = 1;

        p4_pd_balancer_tbl_flow_hash_parts_imac_table_add_with_calc_flow_parts_imac(sess_hdl, dev_tgt, &match_spec, &entry_hdl);

        match_spec.ebmeta_port_type = 2;
        match_spec.outer_ipv4_valid = 0;
        match_spec.outer_ipv6_valid = 0;
        match_spec.inner_ethernet_valid = 1;

        p4_pd_balancer_tbl_flow_hash_parts_imac_table_add_with_calc_flow_parts_imac(sess_hdl, dev_tgt, &match_spec, &entry_hdl);
      }
      {
        p4_pd_balancer_tbl_flow_hash_lan_omac_match_spec_t match_spec = { 0 };

        match_spec.ebmeta_port_type = 1;
        match_spec.outer_ipv4_valid = 0;
        match_spec.outer_ipv6_valid = 0;
        match_spec.inner_ethernet_valid = 0;

        p4_pd_balancer_tbl_flow_hash_lan_omac_table_add_with_calc_flow_lan_omac(sess_hdl, dev_tgt, &match_spec, &entry_hdl);
      }
      {
        p4_pd_balancer_tbl_flow_hash_wan_omac_match_spec_t match_spec = { 0 };

        match_spec.ebmeta_port_type = 2;
        match_spec.outer_ipv4_valid = 0;
        match_spec.outer_ipv6_valid = 0;
        match_spec.inner_ethernet_valid = 0;

        p4_pd_balancer_tbl_flow_hash_wan_omac_table_add_with_calc_flow_wan_omac(sess_hdl, dev_tgt, &match_spec, &entry_hdl);
      }
      {
        p4_pd_balancer_tbl_flow_hash_parts_omac_match_spec_t match_spec = { 0 };

        match_spec.ebmeta_port_type = 1;
        match_spec.outer_ipv4_valid = 0;
        match_spec.outer_ipv6_valid = 0;
        match_spec.inner_ethernet_valid = 0;

        p4_pd_balancer_tbl_flow_hash_parts_omac_table_add_with_calc_flow_parts_omac(sess_hdl, dev_tgt, &match_spec, &entry_hdl);

        match_spec.ebmeta_port_type = 2;
        match_spec.outer_ipv4_valid = 0;
        match_spec.outer_ipv6_valid = 0;
        match_spec.inner_ethernet_valid = 0;

        p4_pd_balancer_tbl_flow_hash_parts_omac_table_add_with_calc_flow_parts_omac(sess_hdl, dev_tgt, &match_spec, &entry_hdl);
      }
      {
        p4_pd_balancer_set_flow_hash_match_spec_t match_spec = { 0 };

        match_spec.ebmeta_port_type = 1;
        match_spec.outer_ipv4_valid = 1;
        match_spec.outer_ipv6_valid = 0;
        match_spec.inner_ethernet_valid = 0;

        p4_pd_balancer_set_flow_hash_table_add_with_set_flow_hash_ipv4_lan(sess_hdl, dev_tgt, &match_spec, &entry_hdl);

        match_spec.ebmeta_port_type = 1;
        match_spec.outer_ipv4_valid = 1;
        match_spec.outer_ipv6_valid = 0;
        match_spec.inner_ethernet_valid = 1;

        p4_pd_balancer_set_flow_hash_table_add_with_set_flow_hash_ipv4_lan(sess_hdl, dev_tgt, &match_spec, &entry_hdl);

        match_spec.ebmeta_port_type = 2;
        match_spec.outer_ipv4_valid = 1;
        match_spec.outer_ipv6_valid = 0;
        match_spec.inner_ethernet_valid = 0;

        p4_pd_balancer_set_flow_hash_table_add_with_set_flow_hash_ipv4_wan(sess_hdl, dev_tgt, &match_spec, &entry_hdl);

        match_spec.ebmeta_port_type = 2;
        match_spec.outer_ipv4_valid = 1;
        match_spec.outer_ipv6_valid = 0;
        match_spec.inner_ethernet_valid = 1;

        p4_pd_balancer_set_flow_hash_table_add_with_set_flow_hash_ipv4_wan(sess_hdl, dev_tgt, &match_spec, &entry_hdl);

        match_spec.ebmeta_port_type = 1;
        match_spec.outer_ipv4_valid = 0;
        match_spec.outer_ipv6_valid = 1;
        match_spec.inner_ethernet_valid = 0;

        p4_pd_balancer_set_flow_hash_table_add_with_set_flow_hash_ipv6_lan(sess_hdl, dev_tgt, &match_spec, &entry_hdl);

        match_spec.ebmeta_port_type = 1;
        match_spec.outer_ipv4_valid = 0;
        match_spec.outer_ipv6_valid = 1;
        match_spec.inner_ethernet_valid = 1;

        p4_pd_balancer_set_flow_hash_table_add_with_set_flow_hash_ipv6_lan(sess_hdl, dev_tgt, &match_spec, &entry_hdl);

        match_spec.ebmeta_port_type = 2;
        match_spec.outer_ipv4_valid = 0;
        match_spec.outer_ipv6_valid = 1;
        match_spec.inner_ethernet_valid = 0;

        p4_pd_balancer_set_flow_hash_table_add_with_set_flow_hash_ipv6_wan(sess_hdl, dev_tgt, &match_spec, &entry_hdl);

        match_spec.ebmeta_port_type = 2;
        match_spec.outer_ipv4_valid = 0;
        match_spec.outer_ipv6_valid = 1;
        match_spec.inner_ethernet_valid = 1;

        p4_pd_balancer_set_flow_hash_table_add_with_set_flow_hash_ipv6_wan(sess_hdl, dev_tgt, &match_spec, &entry_hdl);

        match_spec.ebmeta_port_type = 1;
        match_spec.outer_ipv4_valid = 0;
        match_spec.outer_ipv6_valid = 0;
        match_spec.inner_ethernet_valid = 1;

        p4_pd_balancer_set_flow_hash_table_add_with_set_flow_hash_imac_lan(sess_hdl, dev_tgt, &match_spec, &entry_hdl);

        match_spec.ebmeta_port_type = 2;
        match_spec.outer_ipv4_valid = 0;
        match_spec.outer_ipv6_valid = 0;
        match_spec.inner_ethernet_valid = 1;

        p4_pd_balancer_set_flow_hash_table_add_with_set_flow_hash_imac_wan(sess_hdl, dev_tgt, &match_spec, &entry_hdl);

        match_spec.ebmeta_port_type = 1;
        match_spec.outer_ipv4_valid = 0;
        match_spec.outer_ipv6_valid = 0;
        match_spec.inner_ethernet_valid = 0;

        p4_pd_balancer_set_flow_hash_table_add_with_set_flow_hash_omac_lan(sess_hdl, dev_tgt, &match_spec, &entry_hdl);

        match_spec.ebmeta_port_type = 2;
        match_spec.outer_ipv4_valid = 0;
        match_spec.outer_ipv6_valid = 0;
        match_spec.inner_ethernet_valid = 0;

        p4_pd_balancer_set_flow_hash_table_add_with_set_flow_hash_omac_wan(sess_hdl, dev_tgt, &match_spec, &entry_hdl);
      }
      {
        bf_dev_port_t set_dpi_output_port[COUNT(port_cfg)];
        int set_dpi_output_port_count = 0;
        for (i = 0; i < COUNT(set_dpi_output_port); ++ i)
        {
          if (port_cfg[i].port_type == 3)
          {
            set_dpi_output_port[set_dpi_output_port_count ++] = port_cfg[i].dev_port;
          }
        }
        for (i = 0; i < 65536; ++ i)
        {
          {
            p4_pd_balancer_set_dpi_output_match_spec_t match_spec = { 0 };
            p4_pd_balancer_set_dpi_out_and_queue_action_spec_t action_spec = { 0 };

            match_spec.ebmeta_is_lanwan = 1;
            match_spec.ebmeta_port_hash = i;

            action_spec.action_port = set_dpi_output_port[i % set_dpi_output_port_count];
            action_spec.action_queue = i % 40 + 1;

            p4_pd_balancer_set_dpi_output_table_add_with_set_dpi_out_and_queue(sess_hdl, dev_tgt, &match_spec, &action_spec, &entry_hdl);
          }
        }
      }
      {
        int etherType = 0xEC00;
        for (i = 0; i < COUNT(port_cfg); ++ i)
        {
          if (port_cfg[i].port_type == 5)
          {
            p4_pd_balancer_forward_log_match_spec_t match_spec = { 0 };
            p4_pd_balancer_do_forward_log_action_spec_t action_spec = { 0 };

            match_spec.ebmeta_port_type = 3;
            match_spec.ecolog_valid = 1;
            match_spec.ecolog_etherType = etherType ++;

            action_spec.action_out_port = port_cfg[i].dev_port;

            p4_pd_balancer_forward_log_table_add_with_do_forward_log(sess_hdl, dev_tgt, &match_spec, &action_spec, &entry_hdl);
          }
        }
      }
      {
        p4_pd_balancer_drop_if_no_ebheader_match_spec_t match_spec = { 0 };

        match_spec.ebmeta_port_type = 3;
        match_spec.ebheader_valid = 0;
        match_spec.ecolog_valid = 0;

        p4_pd_balancer_drop_if_no_ebheader_table_add_with__drop(sess_hdl, dev_tgt, &match_spec, &entry_hdl);
      }
      {
        p4_pd_balancer_dpi_set_egress_port_match_spec_t match_spec = { 0 };

        match_spec.ebmeta_port_type = 3;

        p4_pd_balancer_dpi_set_egress_port_table_add_with_dpi_egress_port(sess_hdl, dev_tgt, &match_spec, &entry_hdl);
      }
      {
        p4_pd_balancer_add_ebheader_match_spec_t match_spec = { 0 };

        match_spec.ebmeta_port_type = 1;

        p4_pd_balancer_add_ebheader_table_add_with_do_add_ebheader(sess_hdl, dev_tgt, &match_spec, &entry_hdl);

        match_spec.ebmeta_port_type = 2;

        p4_pd_balancer_add_ebheader_table_add_with_do_add_ebheader(sess_hdl, dev_tgt, &match_spec, &entry_hdl);
      }
      {
        p4_pd_balancer_remove_ebheader_match_spec_t match_spec = { 0 };

        match_spec.ebmeta_port_type = 3;
        match_spec.ebheader_valid = 1;

        p4_pd_balancer_remove_ebheader_table_add_with_do_remove_ebheader(sess_hdl, dev_tgt, &match_spec, &entry_hdl);
      }
      p4_pd_complete_operations(sess_hdl);
      printf("Configured.\n");

      {
        int i;
        uint32_t count = 0;
        int first = 0;
        p4_pd_balancer_update_byte_counters_get_entry_count(sess_hdl, dev_tgt.device_id, &count);
        p4_pd_balancer_update_byte_counters_get_first_entry_handle(sess_hdl, dev_tgt, &first);
        printf("count = %u, first = %d\n", count, first);

        int entry_handles[10];
        if (count > 1)
          p4_pd_balancer_update_byte_counters_get_next_entry_handles(sess_hdl, dev_tgt.device_id, index, count - 1, entry_handles + 1);
        entry_handles[0] = first;
        for (i = 0; i < count; ++ i)
        {
          uint8_t action_data[512];
          int num_action_bytes = sizeof(action_data);
          p4_pd_balancer_update_byte_counters_match_spec_t match_spec;
          char* action_name = NULL;
          p4_pd_balancer_update_byte_counters_get_entry(
            sess_hdl,
            dev_tgt.device_id,
            entry_handles[i],
            1,
            &match_spec,
            &action_name,
            action_data,
            &num_action_bytes
          );
          printf("i = %d/%d, ebmeta_port_type = %d, action = %s\n", i, entry_handles[i], match_spec.ebmeta_port_type, action_name);
        }
      }
      {
        for (;;)
        {
          int i;
          p4_pd_balancer_counter_hw_sync_per_hash_packets_ctr(sess_hdl, dev_tgt, NULL, NULL);
          p4_pd_balancer_counter_hw_sync_per_hash_bytes_ctr(sess_hdl, dev_tgt, NULL, NULL);
          for (i = 0; i < 65535; ++ i)
          {
            p4_pd_counter_value_t packets = p4_pd_balancer_counter_read_per_hash_packets_ctr(sess_hdl, dev_tgt, i, 0);
            p4_pd_counter_value_t bytes = p4_pd_balancer_counter_read_per_hash_bytes_ctr(sess_hdl, dev_tgt, i, 0);
            if (packets.packets || bytes.bytes)
            {
              printf("hash = %5d, frames = %20lu, bytes = %20lu\n", i, packets.packets, bytes.bytes);
            }
          }
        }
      }
    }
  }
}
