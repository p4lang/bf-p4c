import logging
import sys
import os
import random
import re
#from pprint import pprint

import packet as scapy

from ptf import config
from ptf.thriftutils import *
import ptf.testutils as testutils
import bfrt_grpc.client as gc

from enum import Enum

from test_mau_tb_shared import *

#######################################
# LOW LEVEL FUNCTIONS
#######################################

def npb_validate_eth_add(self, target, tag_valid):
	pass;
#		if(TRANSPORT_ENABLE == True):
#			self.insert_table_entry(
#				target,
#				'SwitchIngress.pkt_validation_0.validate_ethernet',
##				[self.KeyField('hdr.ethernet.src_addr',                     self.to_bytes(0, 6), self.to_bytes(0, 6)),
##				 self.KeyField('hdr.ethernet.dst_addr',                     self.to_bytes(0, 6), self.to_bytes(0, 6)),
#				[self.KeyField('hdr.vlan_tag$0.$valid',                     self.to_bytes(tag_valid, 1), self.to_bytes(1, 1))],
#				'SwitchIngress.pkt_validation_0.valid_unicast_pkt_untagged')

#		self.insert_table_entry(
#			target,
#			'SwitchIngress.pkt_validation_1.validate_ethernet',
##			[self.KeyField('hdr.ethernet.src_addr',                     self.to_bytes(0, 6), self.to_bytes(0, 6)),
##			 self.KeyField('hdr.ethernet.dst_addr',                     self.to_bytes(0, 6), self.to_bytes(0, 6)),
#			[self.KeyField('hdr.vlan_tag$0.$valid',                     self.to_bytes(tag_valid, 1), self.to_bytes(1, 1))],
#			'SwitchIngress.pkt_validation_1.valid_unicast_pkt_untagged')

#		self.insert_table_entry(
#			target,
#			'SwitchIngress.pkt_validation_2.validate_ethernet',
##			[self.KeyField('hdr.ethernet.src_addr',                     self.to_bytes(0, 6), self.to_bytes(0, 6)),
##			 self.KeyField('hdr.ethernet.dst_addr',                     self.to_bytes(0, 6), self.to_bytes(0, 6)),
#			[self.KeyField('hdr.vlan_tag$0.$valid',                     self.to_bytes(tag_valid, 1), self.to_bytes(1, 1))],
#			'SwitchIngress.pkt_validation_2.valid_unicast_pkt_untagged')

def npb_validate_eth_del(self, target, tag_valid):
	pass;
#		if(TRANSPORT_ENABLE == True):
#			self.delete_table_entry(
#				 target,
#				'SwitchIngress.pkt_validation_0.validate_ethernet',
##				[self.KeyField('hdr.ethernet.src_addr',                     self.to_bytes(0, 6), self.to_bytes(0, 6)),
##				 self.KeyField('hdr.ethernet.dst_addr',                     self.to_bytes(0, 6), self.to_bytes(0, 6)),
#				[self.KeyField('hdr.vlan_tag$0.$valid',                     self.to_bytes(tag_valid, 1), self.to_bytes(1, 1))])

#		self.delete_table_entry(
#			target,
#			'SwitchIngress.pkt_validation_1.validate_ethernet',
##			[self.KeyField('hdr.ethernet.src_addr',                     self.to_bytes(0, 6), self.to_bytes(0, 6)),
##			 self.KeyField('hdr.ethernet.dst_addr',                     self.to_bytes(0, 6), self.to_bytes(0, 6)),
#			[self.KeyField('hdr.vlan_tag$0.$valid',                     self.to_bytes(tag_valid, 1), self.to_bytes(1, 1))])

#		self.delete_table_entry(
#			target,
#			'SwitchIngress.pkt_validation_2.validate_ethernet',
##			[self.KeyField('hdr.ethernet.src_addr',                     self.to_bytes(0, 6), self.to_bytes(0, 6)),
##			 self.KeyField('hdr.ethernet.dst_addr',                     self.to_bytes(0, 6), self.to_bytes(0, 6)),
#			[self.KeyField('hdr.vlan_tag$0.$valid',                     self.to_bytes(tag_valid, 1), self.to_bytes(1, 1))])

########################################

def npb_validate_ipv4_add(self, target):
	pass;
#		if(TRANSPORT_ENABLE == True):
#				self.insert_table_entry(
#				target,
#				'SwitchIngress.pkt_validation_0.validate_ipv4',
#				[self.KeyField('ipv4_checksum_err',                         self.to_bytes(0, 1), self.to_bytes(1, 1)),
#				 self.KeyField('hdr.ipv4.version',                          self.to_bytes(0x4, 1), self.to_bytes(0xf, 1)),
#				 self.KeyField('hdr.ipv4.ihl',                              self.to_bytes(0, 1), self.to_bytes(0, 1)),
#				 self.KeyField('hdr.ipv4.ttl',                              self.to_bytes(0, 1), self.to_bytes(0, 1)),
#				 self.KeyField('hdr.ipv4.src_addr[31:24]',                  self.to_bytes(0, 1), self.to_bytes(0, 1))],
#				'SwitchIngress.pkt_validation_0.valid_ipv4_pkt',
#				[self.DataField('ip_frag',                                  self.to_bytes(0, 1))])

#		self.insert_table_entry(
#			target,
#			'SwitchIngress.pkt_validation_1.validate_ipv4',
#			[self.KeyField('ipv4_checksum_err',                         self.to_bytes(0, 1), self.to_bytes(1, 1)),
#			 self.KeyField('hdr.ipv4.version',                          self.to_bytes(0x4, 1), self.to_bytes(0xf, 1)),
#			 self.KeyField('hdr.ipv4.ihl',                              self.to_bytes(0, 1), self.to_bytes(0, 1)),
#			 self.KeyField('hdr.ipv4.ttl',                              self.to_bytes(0, 1), self.to_bytes(0, 1)),
#			 self.KeyField('hdr.ipv4.src_addr[31:24]',                  self.to_bytes(0, 1), self.to_bytes(0, 1))],
#			'SwitchIngress.pkt_validation_1.valid_ipv4_pkt',
#			[self.DataField('ip_frag',                                  self.to_bytes(0, 1))])

#		self.insert_table_entry(
#			target,
#			'SwitchIngress.pkt_validation_2.validate_ipv4',
#			[self.KeyField('ipv4_checksum_err',                         self.to_bytes(0, 1), self.to_bytes(1, 1)),
#			 self.KeyField('hdr.ipv4.version',                          self.to_bytes(0x4, 1), self.to_bytes(0xf, 1)),
#			 self.KeyField('hdr.ipv4.ihl',                              self.to_bytes(0, 1), self.to_bytes(0, 1)),
#			 self.KeyField('hdr.ipv4.ttl',                              self.to_bytes(0, 1), self.to_bytes(0, 1))],
#			'SwitchIngress.pkt_validation_2.valid_ipv4_pkt')

def npb_validate_ipv4_del(self, target):
	pass;
#		if(TRANSPORT_ENABLE == True):
#			self.delete_table_entry(
#				target,
#				'SwitchIngress.pkt_validation_0.validate_ipv4',
#				[self.KeyField('ipv4_checksum_err',                        self.to_bytes(0, 1), self.to_bytes(1, 1)),
#				 self.KeyField('hdr.ipv4.version',                          self.to_bytes(0x4, 1), self.to_bytes(0xf, 1)),
#				 self.KeyField('hdr.ipv4.ihl',                              self.to_bytes(0, 1), self.to_bytes(0, 1)),
#				 self.KeyField('hdr.ipv4.ttl',                              self.to_bytes(0, 1), self.to_bytes(0, 1)),
#				 self.KeyField('hdr.ipv4.src_addr[31:24]',                  self.to_bytes(0, 1), self.to_bytes(0, 1))])

#		self.delete_table_entry(
#			target,
#			'SwitchIngress.pkt_validation_1.validate_ipv4',
#			[self.KeyField('ipv4_checksum_err',                        self.to_bytes(0, 1), self.to_bytes(1, 1)),
#			 self.KeyField('hdr.ipv4.version',                          self.to_bytes(0x4, 1), self.to_bytes(0xf, 1)),
#			 self.KeyField('hdr.ipv4.ihl',                              self.to_bytes(0, 1), self.to_bytes(0, 1)),
#			 self.KeyField('hdr.ipv4.ttl',                              self.to_bytes(0, 1), self.to_bytes(0, 1)),
#			 self.KeyField('hdr.ipv4.src_addr[31:24]',                  self.to_bytes(0, 1), self.to_bytes(0, 1))])

#		self.delete_table_entry(
#			target,
#			'SwitchIngress.pkt_validation_2.validate_ipv4',
#			[self.KeyField('ipv4_checksum_err',                        self.to_bytes(0, 1), self.to_bytes(1, 1)),
#			 self.KeyField('hdr.ipv4.version',                          self.to_bytes(0x4, 1), self.to_bytes(0xf, 1)),
#			 self.KeyField('hdr.ipv4.ihl',                              self.to_bytes(0, 1), self.to_bytes(0, 1)),
#			 self.KeyField('hdr.ipv4.ttl',                              self.to_bytes(0, 1), self.to_bytes(0, 1))])

########################################

def cpu_port_add(self, target):
	try:

		if(CPU_ENABLE == True):
			# todo: make these inputs instead of hard coding them
			cpu_etype      = 0x9001
			cpu_etype_mask = 0xFFFF #(2**16)-1
			cpu_port       = 2
			cpu_port_mask  = 0x01FF #(2** 9)-1

			table = self.bfrt_info.table_get("NpbIngressParser.cpu_port")
			table.entry_add(
				target,
				[table.make_key(
					[gc.KeyTuple('ether_type', cpu_etype, cpu_etype_mask),
					 gc.KeyTuple('port',       cpu_port,  cpu_port_mask)]
				)]
			)

	except:
		print("A table operation failed. This is typically due to adding or removing a duplicate, and can be ignored.")

def cpu_port_del(self, target):
	try:

		if(CPU_ENABLE == True):
			# todo: make these inputs instead of hard coding them
			cpu_etype      = 0x9001 
			cpu_etype_mask = 0xFFFF #(2**16)-1
			cpu_port       = 2
			cpu_port_mask  = 0x01FF #(2** 9)-1

			table = self.bfrt_info.table_get("NpbIngressParser.cpu_port")
			table.entry_del(
				target,
				[table.make_key(
					[gc.KeyTuple('ether_type', cpu_etype, cpu_etype_mask),
					 gc.KeyTuple('port',       cpu_port,  cpu_port_mask)]
				)]
			)

	except:
		print("A table operation failed. This is typically due to adding or removing a duplicate, and can be ignored.")

########################################

# rmac (npb vs bridge)

def npb_tunnel_rmac_add(self, target, dst_addr):
	try:
		if(BRIDGING_ENABLE == True):
#			table = self.bfrt_info.table_get('SwitchIngress.rmac.rmac')
#			table.entry_add(
#				target,
#				[table.make_key(
#					[gc.KeyTuple('hdr_0.ethernet.dst_addr', gc.mac_to_bytes(dst_addr))]
#				)],
#				[table.make_data(
#					[],
#					'SwitchIngress.rmac.rmac_hit'
#				)]
#			)

			table = self.bfrt_info.table_get("NpbIngressParser.my_mac_lo")
			table.entry_add(
				target,
				[table.make_key(
					[gc.KeyTuple('f1', gc.mac_to_bytes(dst_addr)[2:6], 0xffffffff)]
				)]
			)

			table = self.bfrt_info.table_get("NpbIngressParser.my_mac_hi")
			table.entry_add(
				target,
				[table.make_key(
					[gc.KeyTuple('f1', gc.mac_to_bytes(dst_addr)[0:2], 0xffff)]
				)]
			)

	except:
		print("A table operation failed. This is typically due to adding or removing a duplicate, and can be ignored.")

def npb_tunnel_rmac_del(self, target, dst_addr):
	try:
		if(BRIDGING_ENABLE == True):
#			table = self.bfrt_info.table_get('SwitchIngress.rmac.rmac')
#			table.entry_del(
#				target,
#				[table.make_key(
#					[gc.KeyTuple('hdr_0.ethernet.dst_addr', gc.mac_to_bytes(dst_addr))]
#				)]
#			)

			table = self.bfrt_info.table_get("NpbIngressParser.my_mac_lo")
			table.entry_del(
			target,
				[table.make_key(
					[gc.KeyTuple('f1', gc.mac_to_bytes(dst_addr)[2:6], 0xffffffff)]
				)]
			)

			table = self.bfrt_info.table_get("NpbIngressParser.my_mac_hi")
			table.entry_del(
			target,
				[table.make_key(
					[gc.KeyTuple('f1', gc.mac_to_bytes(dst_addr)[0:2], 0xffff)]
				)]
			)

	except:
		print("A table operation failed. This is typically due to adding or removing a duplicate, and can be ignored.")

########################################

def npb_ing_port_add(self, target, port, port_lag_ptr, bridging_enable, sap, vpn, spi, si, si_predec):

	for i in range(len(port)):

		try:

#			table = self.bfrt_info.table_get('NpbIngressParser.$PORT_METADATA')
#			table.entry_add(
#				target,
#				[table.make_key(
#					[gc.KeyTuple('ig_intr_md.ingress_port',                   port[i])],
#				)],
#				[table.make_data(
#					[gc.DataTuple('port_lag_index',                           port_lag_ptr),
#					 gc.DataTuple('l2_fwd_en',                                bridging_enable)],
#					None
#				)]
#			)

			########################################

			# Set all multicast port config in one entry_add API
			#print("Setting ALL multicast port config for port", port)
			table = self.bfrt_info.table_get('$pre.port')
			table.entry_mod(
				target,
				[table.make_key(
					[gc.KeyTuple('$DEV_PORT',                                 port[i])]
				)],
				[table.make_data(
#					[gc.DataTuple('$MULTICAST_BACKUP_PORT',                   backup_port),
					[gc.DataTuple('$COPY_TO_CPU_PORT_ENABLE',                 bool_val=True),
					 gc.DataTuple('$MULTICAST_FORWARD_STATE',                 bool_val=True),
					 gc.DataTuple('$MULTICAST_CLEAR_FAST_FAILOVER',           bool_val=True)]
				)]
			)

			########################################

			# insert both versions (nsh and non-nsh):

			table = self.bfrt_info.table_get('SwitchIngress.ingress_port_mapping.port_mapping')
			table.entry_add(
				target,
				[table.make_key(
					[gc.KeyTuple('ig_md.port',                                port[i]),
					 gc.KeyTuple('hdr.cpu.$valid',                            0)],
				)],
				[table.make_data(
#					[],
					[gc.DataTuple('port_lag_index',                           port_lag_ptr),
					 gc.DataTuple('l2_fwd_en',                                bridging_enable)],
					'SwitchIngress.ingress_port_mapping.set_port_properties'
				)]
			)

			########################################

			# insert both versions (cpu and non-cpu):

			table = self.bfrt_info.table_get('SwitchIngress.ingress_port_mapping.port_mapping')
			table.entry_add(
				target,
				[table.make_key(
					[gc.KeyTuple('ig_md.port',                                port[i]),
					 gc.KeyTuple('hdr.cpu.$valid',                            1)],
				)],
				[table.make_data(
					[gc.DataTuple('port_lag_index',                           port_lag_ptr),
					 gc.DataTuple('l2_fwd_en',                                bridging_enable)],
					'SwitchIngress.ingress_port_mapping.set_cpu_port_properties'
				)]
			)

		except:
			print("A table operation failed. This is typically due to adding or removing a duplicate, and can be ignored.")

	########################################

	try:

		table = self.bfrt_info.table_get('SwitchIngress.npb_ing_top.npb_ing_sfc_top.port_mapping')
		table.entry_add(
			target,
			[table.make_key(
				[gc.KeyTuple('port',                                      port[i])],
#				[gc.KeyTuple('port_lag_index',                            port_lag_ptr)],
			)],
			[table.make_data(
				[gc.DataTuple('sap',                                      sap),
				 gc.DataTuple('vpn',                                      vpn),
				 gc.DataTuple('spi',                                      spi),
				 gc.DataTuple('si',                                       si),
				 gc.DataTuple('si_predec',                                si_predec)],
				'SwitchIngress.npb_ing_top.npb_ing_sfc_top.set_port_properties'
			)]
		)

	except:
		print("A table operation failed. This is typically due to adding or removing a duplicate, and can be ignored.")

def npb_ing_port_del(self, target, port, port_lag_ptr):

	for i in range(len(port)):

		try:

#			table = self.bfrt_info.table_get('NpbIngressParser.$PORT_METADATA')
#			table.entry_del(
#				target,
#				[table.make_key(
#					[gc.KeyTuple('ig_intr_md.ingress_port',                   port[i])],
#				)]
#			)

			########################################

			# Clear all the multicast port config
			#print("Clearing ALL multicast port config for port", port)
			table = self.bfrt_info.table_get('$pre.port')
			table.entry_mod(
				target,
				[table.make_key(
					[gc.KeyTuple('$DEV_PORT',                                 port[i])]
				)],
				[table.make_data(
					[gc.DataTuple('$MULTICAST_BACKUP_PORT',                   port[i]),
					 gc.DataTuple('$COPY_TO_CPU_PORT_ENABLE',                 bool_val=False),
					 gc.DataTuple('$MULTICAST_FORWARD_STATE',                 bool_val=False),
					 gc.DataTuple('$MULTICAST_CLEAR_FAST_FAILOVER',           bool_val=True)]
				)]
			)

			########################################

			# delete both versions (nsh and non-nsh):

			table = self.bfrt_info.table_get('SwitchIngress.ingress_port_mapping.port_mapping')
			table.entry_del(
				target,
				[table.make_key(
					[gc.KeyTuple('ig_md.port',                                port[i]),
					 gc.KeyTuple('hdr.cpu.$valid',                            0)],
				)]
			)

			########################################

			# delete both versions (nsh and non-nsh):

			table = self.bfrt_info.table_get('SwitchIngress.ingress_port_mapping.port_mapping')
			table.entry_del(
				target,
				[table.make_key(
					[gc.KeyTuple('ig_md.port',                                port[i]),
					 gc.KeyTuple('hdr.cpu.$valid',                            1)],
				)]
			)

		except:
			print("A table operation failed. This is typically due to adding or removing a duplicate, and can be ignored.")

	########################################

	try:

		table = self.bfrt_info.table_get('SwitchIngress.npb_ing_top.npb_ing_sfc_top.port_mapping')
		table.entry_del(
			target,
			[table.make_key(
				[gc.KeyTuple('port',                                      port[i])],
#				[gc.KeyTuple('port_lag_index',                            port_lag_ptr)],
			)]
		)

	except:
		print("A table operation failed. This is typically due to adding or removing a duplicate, and can be ignored.")

########################################

def npb_ing_port_mirror_add(self, target, port, session_id):

		table = self.bfrt_info.table_get('SwitchIngress.ingress_port_mapping.port_mirror.port_mirror')
		table.entry_add(
			target,
			[table.make_key(
				[gc.KeyTuple('port',                             port)],
			)],
			[table.make_data(
				[gc.DataTuple('session_id',                      session_id)],
				'SwitchIngress.ingress_port_mapping.port_mirror.set_mirror_id',
			)]
		)

def npb_ing_port_mirror_del(self, target, port):

		table = self.bfrt_info.table_get('SwitchIngress.ingress_port_mapping.port_mirror.port_mirror')
		table.entry_del(
			target,
			[table.make_key(
				[gc.KeyTuple('port',                             port)],
			)],
		)

########################################

def npb_port_vlan_to_bd_add(self, target, port_lag_index, vid_valid, vid_valid_mask, vid, vid_mask, member_ptr, bd):

		try:
			# bottom
			table = self.bfrt_info.table_get('SwitchIngress.ingress_port_mapping.bd_action_profile')
			table.entry_add(
				target,
				[table.make_key(
					[gc.KeyTuple('$ACTION_MEMBER_ID',                     member_ptr)],
				)],
				[table.make_data(
					[gc.DataTuple('bd',                                   bd),
					 gc.DataTuple('rid',                                  0)],
					'SwitchIngress.ingress_port_mapping.set_bd_properties'
				)]
			)

		except:
			print("A table operation failed. This is typically due to adding or removing a duplicate, and can be ignored.")

		try:
			# top
			table = self.bfrt_info.table_get('SwitchIngress.ingress_port_mapping.port_vlan_to_bd_mapping')
			table.entry_add(
				target,
				[table.make_key(
					[gc.KeyTuple('ig_md.port_lag_index',                  port_lag_index),
#					 gc.KeyTuple('hdr.transport.vlan_tag$0.$valid',       vid_valid, vid_valid_mask),
#					 gc.KeyTuple('hdr.transport.vlan_tag$0.vid',          vid, vid_mask)],
					 gc.KeyTuple('hdr.outer.vlan_tag$0.$valid',           vid_valid, vid_valid_mask),
					 gc.KeyTuple('hdr.outer.vlan_tag$0.vid',              vid, vid_mask)],
				)],
				[table.make_data(
					[gc.DataTuple('$ACTION_MEMBER_ID',                    member_ptr)],
					None
				)]
			)

		except:
			print("A table operation failed. This is typically due to adding or removing a duplicate, and can be ignored.")

def npb_port_vlan_to_bd_del(self, target, port_lag_index, vid_valid, vid_valid_mask, vid, vid_mask, member_ptr):

		try:
			# top
			table = self.bfrt_info.table_get('SwitchIngress.ingress_port_mapping.port_vlan_to_bd_mapping')
			table.entry_del(
				target,
				[table.make_key(
					[gc.KeyTuple('ig_md.port_lag_index',                  port_lag_index),
#					 gc.KeyTuple('hdr.transport.vlan_tag$0.$valid',       vid_valid, vid_valid_mask),
#					 gc.KeyTuple('hdr.transport.vlan_tag$0.vid',          vid, vid_mask)],
					 gc.KeyTuple('hdr.outer.vlan_tag$0.$valid',           vid_valid, vid_valid_mask),
					 gc.KeyTuple('hdr.outer.vlan_tag$0.vid',              vid, vid_mask)],
				)],
			)

		except:
			print("A table operation failed. This is typically due to adding or removing a duplicate, and can be ignored.")

		try:
			# bottom
			table = self.bfrt_info.table_get('SwitchIngress.ingress_port_mapping.bd_action_profile')
			table.entry_del(
				target,
				[table.make_key(
					[gc.KeyTuple('$ACTION_MEMBER_ID',                     member_ptr)],
				)],
			)

		except:
			print("A table operation failed. This is typically due to adding or removing a duplicate, and can be ignored.")

########################################

def npb_vlan_to_bd_add(self, target, vid, member_ptr, bd):

		try:
			# bottom
			table = self.bfrt_info.table_get('SwitchIngress.ingress_port_mapping.bd_action_profile')
			table.entry_add(
				target,
				[table.make_key(
					[gc.KeyTuple('$ACTION_MEMBER_ID',                     member_ptr)],
				)],
				[table.make_data(
					[gc.DataTuple('bd',                                   bd)],
#					[gc.DataTuple('rid',                                  0)],
					'SwitchIngress.ingress_port_mapping.set_bd_properties'
				)]
			)

		except:
			print("A table operation failed. This is typically due to adding or removing a duplicate, and can be ignored.")

		try:
			# top
			table = self.bfrt_info.table_get('SwitchIngress.ingress_port_mapping.vlan_to_bd_mapping')
			table.entry_add(
				target,
				[table.make_key(
#					[gc.KeyTuple('hdr.transport.vlan_tag$0.vid',          vid)],
					[gc.KeyTuple('hdr.outer.vlan_tag$0.vid',              vid)],
				)],
				[table.make_data(
					[gc.DataTuple('$ACTION_MEMBER_ID',                    member_ptr)],
					None
				)]
			)

		except:
			print("A table operation failed. This is typically due to adding or removing a duplicate, and can be ignored.")

def npb_vlan_to_bd_del(self, target, vid, member_ptr):

		try:
			# top
			table = self.bfrt_info.table_get('SwitchIngress.ingress_port_mapping.vlan_to_bd_mapping')
			table.entry_del(
				target,
				[table.make_key(
#					[gc.KeyTuple('hdr.transport.vlan_tag$0.vid',          vid)],
					[gc.KeyTuple('hdr.outer.vlan_tag$0.vid',              vid)],
				)],
			)

		except:
			print("A table operation failed. This is typically due to adding or removing a duplicate, and can be ignored.")

		try:
			# bottom
			table = self.bfrt_info.table_get('SwitchIngress.ingress_port_mapping.bd_action_profile')
			table.entry_del(
				target,
				[table.make_key(
					[gc.KeyTuple('$ACTION_MEMBER_ID',                     member_ptr)],
				)],
			)

		except:
			print("A table operation failed. This is typically due to adding or removing a duplicate, and can be ignored.")

########################################

# dmac (bridge)

def npb_tunnel_dmac_add(self, target, bd, dst_addr, port_lag_ptr):
		if(BRIDGING_ENABLE == True):

			table = self.bfrt_info.table_get('SwitchIngress.dmac.dmac')
			table.entry_add(
				target,
				[table.make_key(
					[gc.KeyTuple('ig_md.bd',                              bd),
					 gc.KeyTuple('dst_addr',                              gc.mac_to_bytes(dst_addr))],
				)],
				[table.make_data(
					[gc.DataTuple('port_lag_index',                       port_lag_ptr)],
					'SwitchIngress.dmac.dmac_hit'
				)]
			)

def npb_tunnel_dmac_del(self, target, bd, dst_addr):
		if(BRIDGING_ENABLE == True):

			table = self.bfrt_info.table_get('SwitchIngress.dmac.dmac')
			table.entry_del(
				target,
				[table.make_key(
					[gc.KeyTuple('ig_md.bd',                              bd),
					 gc.KeyTuple('dst_addr',                              gc.mac_to_bytes(dst_addr))]
				)]
			)

########################################

# ing sfc: decap 0 (transport)

def npb_tunnel_network_dst_vtep_add(self, target,
		l3_src   = '0.0.0.0', l3_src_mask   = 0,
		l3_dst   = '0.0.0.0', l3_dst_mask   = 0,
		tun_type = 0,         tun_type_mask = 0,
		# results
		sap          = 0,
		vpn          = 0,
		port_lag_ptr = 0,
		drop         = 0
		):

		table = self.bfrt_info.table_get('SwitchIngress.npb_ing_top.npb_ing_sfc_top.tunnel_transport.dst_vtep')
		table.entry_add(
			target,
			[table.make_key(
				[gc.KeyTuple('src_addr',                                  gc.ipv4_to_bytes(l3_src), l3_src_mask),
				 gc.KeyTuple('dst_addr',                                  gc.ipv4_to_bytes(l3_dst), l3_dst_mask),
				 gc.KeyTuple('tunnel_type',                               tun_type)],
			)],
			[table.make_data(
				[gc.DataTuple('sap',                                      sap),
				 gc.DataTuple('vpn',                                      vpn),
#				 gc.DataTuple('port_lag_index',                           port_lag_ptr),
				 gc.DataTuple('drop',                                     drop)],
				'SwitchIngress.npb_ing_top.npb_ing_sfc_top.tunnel_transport.dst_vtep_hit'
			)]
		)

def npb_tunnel_network_dst_vtep_del(self, target,
		l3_src   = '0.0.0.0', l3_src_mask   = 0,
		l3_dst   = '0.0.0.0', l3_dst_mask   = 0,
		tun_type = 0,         tun_type_mask = 0
		):

		table = self.bfrt_info.table_get('SwitchIngress.npb_ing_top.npb_ing_sfc_top.tunnel_transport.dst_vtep')
		table.entry_del(
			target,
			[table.make_key(
				[gc.KeyTuple('src_addr',                                  gc.ipv4_to_bytes(l3_src), l3_src_mask),
				 gc.KeyTuple('dst_addr',                                  gc.ipv4_to_bytes(l3_dst), l3_dst_mask),
				 gc.KeyTuple('tunnel_type',                               tun_type)],
			)],
		)

########################################

# ing sfc: decap 0 (transport)

def npb_tunnel_network_src_vtep_add(self, target,
		l3_src   = '0.0.0.0', l3_src_mask   = 0,
		tun_type = 0,         tun_type_mask = 0,
		# results
		sap          = 0,
		vpn          = 0,
		port_lag_ptr = 0
		):

		table = self.bfrt_info.table_get('SwitchIngress.npb_ing_top.npb_ing_sfc_top.tunnel_transport.src_vtep')
		table.entry_add(
			target,
			[table.make_key(
				[gc.KeyTuple('src_addr',                                  gc.ipv4_to_bytes(l3_src), l3_src_mask),
				 gc.KeyTuple('tunnel_type',                               tun_type)],
			)],
			[table.make_data(
				[gc.DataTuple('sap',                                      sap),
				 gc.DataTuple('vpn',                                      vpn)],
#				 gc.DataTuple('port_lag_index',                           port_lag_ptr)],
				'SwitchIngress.npb_ing_top.npb_ing_sfc_top.tunnel_transport.src_vtep_hit'
			)]
		)

def npb_tunnel_network_src_vtep_del(self, target,
		l3_src   = '0.0.0.0', l3_src_mask   = 0,
		tun_type = 0,         tun_type_mask = 0
		):

		table = self.bfrt_info.table_get('SwitchIngress.npb_ing_top.npb_ing_sfc_top.tunnel_transport.src_vtep')
		table.entry_del(
			target,
			[table.make_key(
				[gc.KeyTuple('src_addr',                                  gc.ipv4_to_bytes(l3_src), l3_src_mask),
				 gc.KeyTuple('tunnel_type',                               tun_type)],
			)],
		)

########################################

# ing sfc: decap #1a (transport)

def npb_tunnel_network_sap_add(self, target,
		sap       = 0,
		tun_type  = 0, tun_type_mask = 0,
		# results
		sap_new   = 0,
		vpn       = 0
		):

		table = self.bfrt_info.table_get('SwitchIngress.npb_ing_top.npb_ing_sfc_top.tunnel_network.sap')
		table.entry_add(
			target,
			[table.make_key(
				[gc.KeyTuple('sap',                              sap),
				 gc.KeyTuple('tunnel_type',                      tun_type)],
			)],
			[table.make_data(
				[gc.DataTuple('sap',                             sap_new),
				 gc.DataTuple('vpn',                             vpn)],
				'SwitchIngress.npb_ing_top.npb_ing_sfc_top.tunnel_network.sap_hit'
			)]
		)

def npb_tunnel_network_sap_del(self, target,
		sap       = 0,
		tun_type  = 0, tun_type_mask = 0
		):

		table = self.bfrt_info.table_get('SwitchIngress.npb_ing_top.npb_ing_sfc_top.tunnel_network.sap')
		table.entry_del(
			target,
			[table.make_key(
				[gc.KeyTuple('sap',                              sap),
				 gc.KeyTuple('tunnel_type',                      tun_type)],
			)],
		)

########################################

# ing sfc: decap #1b (outer)

def npb_tunnel_outer_sap_add(self, target,
		sap       = 0,
		tun_type  = 0, tun_type_mask = 0,
		# results
		sap_new   = 0,
		vpn       = 0,
		scope     = 0,
		terminate = 0 # note: terminate & !scope is nonsense
		):

		# ensure that whenever "terminate" is set, "scope" is also set
		if(terminate):
			scope = 1;

		table = self.bfrt_info.table_get('SwitchIngress.npb_ing_top.npb_ing_sfc_top.tunnel_outer.sap_tcam')
		table.entry_add(
			target,
			[table.make_key(
				[gc.KeyTuple('sap',                              sap, 0xffff),
				 gc.KeyTuple('tunnel_type',                      tun_type, tun_type_mask)]
			)],
			[table.make_data(
				[gc.DataTuple('sap',                             sap_new),
				 gc.DataTuple('vpn',                             vpn),
				 gc.DataTuple('scope',                           scope),
				 gc.DataTuple('terminate',                       terminate)],
				'SwitchIngress.npb_ing_top.npb_ing_sfc_top.tunnel_outer.sap_tcam_hit'
			)]
		)

def npb_tunnel_outer_sap_del(self, target,
		sap       = 0,
		tun_type  = 0, tun_type_mask = 0
		):

		table = self.bfrt_info.table_get('SwitchIngress.npb_ing_top.npb_ing_sfc_top.tunnel_outer.sap_tcam')
		table.entry_del(
			target,
			[table.make_key(
				[gc.KeyTuple('sap',                              sap, 0xffff),
				 gc.KeyTuple('tunnel_type',                      tun_type, tun_type_mask)]
			)]
		)

########################################

# ing sfc: decap #2 (inner)

def npb_tunnel_inner_sap_add(self, target,
		sap       = 0,
		tun_type  = 0, tun_type_mask = 0,
		# results
		sap_new   = 0,
		vpn       = 0,
		scope     = 0,
		terminate = 0 # note: terminate & !scope is nonsense
		):

		# ensure that whenever "terminate" is set, "scope" is also set
		if(terminate):
			scope = 1;

		table = self.bfrt_info.table_get('SwitchIngress.npb_ing_top.npb_ing_sfc_top.tunnel_inner.sap_tcam')
		table.entry_add(
			target,
			[table.make_key(
				[gc.KeyTuple('sap',                              sap, 0xffff),
				 gc.KeyTuple('tunnel_type',                      tun_type, tun_type_mask)]
			)],
			[table.make_data(
				[gc.DataTuple('sap',                             sap_new),
				 gc.DataTuple('vpn',                             vpn),
				 gc.DataTuple('scope',                           scope),
				 gc.DataTuple('terminate',                       terminate)],
				'SwitchIngress.npb_ing_top.npb_ing_sfc_top.tunnel_inner.sap_tcam_hit'
			)]
		)

def npb_tunnel_inner_sap_del(self, target,
		sap       = 0,
		tun_type  = 0, tun_type_mask = 0
		):

		table = self.bfrt_info.table_get('SwitchIngress.npb_ing_top.npb_ing_sfc_top.tunnel_inner.sap_tcam')
		table.entry_del(
			target,
			[table.make_key(
				[gc.KeyTuple('sap',                              sap, 0xffff),
				 gc.KeyTuple('tunnel_type',                      tun_type, tun_type_mask)]
			)],
		)

########################################

# ing sfc: for packets w/  nsh header

def npb_npb_sfc_sf_sel_add(self, target, spi, si, si_predec):

		table = self.bfrt_info.table_get('SwitchIngress.npb_ing_top.npb_ing_sfc_top.ing_sfc_sf_sel')
		table.entry_add(
			target,
			[table.make_key(
				[gc.KeyTuple('spi',                               spi),
				 gc.KeyTuple('si',                                si)],
			)],
			[table.make_data(
				[gc.DataTuple('si_predec',                        si_predec)],
				'SwitchIngress.npb_ing_top.npb_ing_sfc_top.ing_sfc_sf_sel_hit'
			)]
		)

def npb_npb_sfc_sf_sel_del(self, target, spi, si):

		table = self.bfrt_info.table_get('SwitchIngress.npb_ing_top.npb_ing_sfc_top.ing_sfc_sf_sel')
		table.entry_del(
			target,
			[table.make_key(
				[gc.KeyTuple('spi',                               spi),
				 gc.KeyTuple('si',                                si)],
			)]
		)

########################################

# ing sf #0: action select

def npb_npb_sf0_action_sel_add(self, target, spi, si, bitmask):
	try:

		table = self.bfrt_info.table_get('SwitchIngress.npb_ing_top.npb_ing_sf_npb_basic_adv_top.ing_sf_action_sel')
		table.entry_add(
			target,
			[table.make_key(
				[gc.KeyTuple('spi',                               spi),
				 gc.KeyTuple('si',                                si)],
			)],
			[table.make_data(
				[],
				'SwitchIngress.npb_ing_top.npb_ing_sf_npb_basic_adv_top.ing_sf_action_sel_hit'
			)]
		)
	except:
		print("A table operation failed. This is typically due to adding or removing a duplicate, and can be ignored.")

def npb_npb_sf0_action_sel_del(self, target, spi, si):
	try:

		table = self.bfrt_info.table_get('SwitchIngress.npb_ing_top.npb_ing_sf_npb_basic_adv_top.ing_sf_action_sel')
		table.entry_del(
			target,
			[table.make_key(
				[gc.KeyTuple('spi',                               spi),
				 gc.KeyTuple('si',                                si)],
			)],
		)
	except:
		print("A table operation failed. This is typically due to adding or removing a duplicate, and can be ignored.")

########################################

# ing sf #0: ip_len range

def npb_npb_sf0_len_rng_add(self, target, l3_len_lo, l3_len_hi, l3_len_bitmask):

		table = self.bfrt_info.table_get('SwitchIngress.npb_ing_top.npb_ing_sf_npb_basic_adv_top.ing_sf_ip_len_rng')
		table.entry_add(
			target,
			[table.make_key(
				[gc.KeyTuple('ip_len',                              low=l3_len_lo, high=l3_len_hi)],
			)],
			[table.make_data(
				[gc.DataTuple('rng_bitmask',                        l3_len_bitmask)],
				'SwitchIngress.npb_ing_top.npb_ing_sf_npb_basic_adv_top.ing_sf_ip_len_rng_hit'
			)]
		)

def npb_npb_sf0_len_rng_del(self, target, l3_len_lo, l3_len_hi):

		table = self.bfrt_info.table_get('SwitchIngress.npb_ing_top.npb_ing_sf_npb_basic_adv_top.ing_sf_ip_len_rng')
		table.entry_del(
			target,
			[table.make_key(
				[gc.KeyTuple('ip_len',                              low=l3_len_lo, high=l3_len_hi)],
			)],
		)

########################################

# ing sf #0: l4_src_port range

def npb_npb_sf0_l4_src_port_rng_add(self, target, l3_len_lo, l3_len_hi, l3_len_bitmask):

		table = self.bfrt_info.table_get('SwitchIngress.npb_ing_top.npb_ing_sf_npb_basic_adv_top.ing_sf_l4_src_port_rng')
		table.entry_add(
			target,
			[table.make_key(
				[gc.KeyTuple('l4_src_port',                         low=l3_len_lo, high=l3_len_hi)],
			)],
			[table.make_data(
				[gc.DataTuple('rng_bitmask',                        l3_len_bitmask)],
				'SwitchIngress.npb_ing_top.npb_ing_sf_npb_basic_adv_top.ing_sf_l4_src_port_rng_hit'
			)]
		)

def npb_npb_sf0_l4_src_port_rng_del(self, target, l3_len_lo, l3_len_hi):

		table = self.bfrt_info.table_get('SwitchIngress.npb_ing_top.npb_ing_sf_npb_basic_adv_top.ing_sf_l4_src_port_rng')
		table.entry_del(
			target,
			[table.make_key(
				[gc.KeyTuple('l4_src_port',                         low=l3_len_lo, high=l3_len_hi)],
			)],
		)

########################################

# ing sf #0: l4_dst_port range

def npb_npb_sf0_l4_dst_port_rng_add(self, target, l3_len_lo, l3_len_hi, l3_len_bitmask):

		table = self.bfrt_info.table_get('SwitchIngress.npb_ing_top.npb_ing_sf_npb_basic_adv_top.ing_sf_l4_dst_port_rng')
		table.entry_add(
			target,
			[table.make_key(
				[gc.KeyTuple('l4_dst_port',                         low=l3_len_lo, high=l3_len_hi)],
			)],
			[table.make_data(
				[gc.DataTuple('rng_bitmask',                        l3_len_bitmask)],
				'SwitchIngress.npb_ing_top.npb_ing_sf_npb_basic_adv_top.ing_sf_l4_dst_port_rng_hit'
			)]
		)

def npb_npb_sf0_l4_dst_port_rng_del(self, target, l3_len_lo, l3_len_hi):

		table = self.bfrt_info.table_get('SwitchIngress.npb_ing_top.npb_ing_sf_npb_basic_adv_top.ing_sf_l4_dst_port_rng')
		table.entry_del(
			target,
			[table.make_key(
				[gc.KeyTuple('l4_dst_port',                         low=l3_len_lo, high=l3_len_hi)],
			)],
		)

########################################

# ing sf #0: policy l2

def npb_npb_sf0_policy_l2_add(self, target,
		sap         = 0, sap_mask      = 0xffff,
		l2_etype    = 0, l2_etype_mask = 0,
		tun_type    = 0, tun_type_mask = 0,
		# results
		flow_class  = 0,
		drop        = 0,
		scope       = 0,
		terminate   = 0, # note: terminate & !scope is nonsense
		trunc_enable= 0, trunc         = 0,
		copy_to_cpu = 0,
		redirect_to_cpu = 0,
		cpu_reason_code = 0,
		sfc_enable  = 0, sfc           = 0
		):

		# ensure that whenever "terminate" is set, "scope" is also set
		if(terminate):
			scope = 1;

		table = self.bfrt_info.table_get('SwitchIngress.npb_ing_top.npb_ing_sf_npb_basic_adv_top.acl.mac_acl.acl')
		table.entry_add(
			target,
			[table.make_key(
				[gc.KeyTuple('sap',                              sap,      sap_mask),
				 gc.KeyTuple('lkp.mac_src_addr',                 gc.mac_to_bytes('0:0:0:0:0:0'), 0),
				 gc.KeyTuple('lkp.mac_dst_addr',                 gc.mac_to_bytes('0:0:0:0:0:0'), 0),
				 gc.KeyTuple('lkp.mac_type',                     l2_etype, l2_etype_mask),
				 gc.KeyTuple('lkp.tunnel_type',                  tun_type, tun_type_mask)],
			)],
			[table.make_data(
				[gc.DataTuple('flow_class',                      flow_class),
				 gc.DataTuple('drop',                            drop),
				 gc.DataTuple('scope',                           scope),
				 gc.DataTuple('terminate',                       terminate),
				 gc.DataTuple('truncate_enable',                 trunc_enable),
				 gc.DataTuple('truncate_len',                    trunc),
				 gc.DataTuple('copy_to_cpu',                     copy_to_cpu),
				 gc.DataTuple('redirect_to_cpu',                 redirect_to_cpu),
				 gc.DataTuple('cpu_reason_code',                 cpu_reason_code),
				 gc.DataTuple('sfc_enable',                      sfc_enable),
				 gc.DataTuple('sfc',                             sfc)],
				'SwitchIngress.npb_ing_top.npb_ing_sf_npb_basic_adv_top.acl.mac_acl.hit'
			)]
		)

def npb_npb_sf0_policy_l2_del(self, target,
		sap         = 0, sap_mask      = 0xffff,
		l2_etype    = 0, l2_etype_mask = 0,
		tun_type    = 0, tun_type_mask = 0,
		):

		table = self.bfrt_info.table_get('SwitchIngress.npb_ing_top.npb_ing_sf_npb_basic_adv_top.acl.mac_acl.acl')

		# read counter
		resp = table.entry_get(
			target,
			[table.make_key(
				[gc.KeyTuple('sap',                              sap,      sap_mask),
				 gc.KeyTuple('lkp.mac_src_addr',                 gc.mac_to_bytes('0:0:0:0:0:0'), 0),
				 gc.KeyTuple('lkp.mac_dst_addr',                 gc.mac_to_bytes('0:0:0:0:0:0'), 0),
				 gc.KeyTuple('lkp.mac_type',                     l2_etype, l2_etype_mask),
				 gc.KeyTuple('lkp.tunnel_type',                  tun_type, tun_type_mask)],
			)],
			{"from_hw": True},
			table.make_data(
				[gc.DataTuple("$COUNTER_SPEC_BYTES"),
				 gc.DataTuple("$COUNTER_SPEC_PKTS")],
				'SwitchIngress.npb_ing_top.npb_ing_sf_npb_basic_adv_top.acl.mac_acl.hit',
				get=True
			)
		)

		data_dict = next(resp)[0].to_dict()
		recv_pkts = data_dict["$COUNTER_SPEC_PKTS"]
		recv_bytes = data_dict["$COUNTER_SPEC_BYTES"]

		print "Dumping npb_npb_sf0_policy_l2 counters: pkts", recv_pkts, "bytes", recv_bytes 

		# delete entry
		table.entry_del(
			target,
			[table.make_key(
				[gc.KeyTuple('sap',                              sap,      sap_mask),
				 gc.KeyTuple('lkp.mac_src_addr',                 gc.mac_to_bytes('0:0:0:0:0:0'), 0),
				 gc.KeyTuple('lkp.mac_dst_addr',                 gc.mac_to_bytes('0:0:0:0:0:0'), 0),
				 gc.KeyTuple('lkp.mac_type',                     l2_etype, l2_etype_mask),
				 gc.KeyTuple('lkp.tunnel_type',                  tun_type, tun_type_mask)],
			)]
		)

########################################

# ing sf #0: policy l3 v4

def npb_npb_sf0_policy_l34_v4_add(self, target,
		sap            = 0, sap_mask            = 0xffff,
		l3_len_bitmask = 0, l3_len_bitmask_mask = 0,
		l3_proto       = 0, l3_proto_mask       = 0,
		l4_src         = 0, l4_src_mask         = 0,
		l4_dst         = 0, l4_dst_mask         = 0,
		tun_type       = 0, tun_type_mask       = 0,
		# results
		flow_class     = 0,
		drop           = 0,
		scope          = 0,
		terminate      = 0, # note: terminate & !scope is nonsense
		trunc_enable   = 0, trunc         = 0,
		copy_to_cpu    = 0,
		redirect_to_cpu = 0,
		cpu_reason_code = 0,
		sfc_enable     = 0, sfc           = 0
		):

		# ensure that whenever "terminate" is set, "scope" is also set
		if(terminate):
			scope = 1;

		table = self.bfrt_info.table_get('SwitchIngress.npb_ing_top.npb_ing_sf_npb_basic_adv_top.acl.ipv4_acl.acl')
		table.entry_add(
			target,
			[table.make_key(
				[gc.KeyTuple('sap',                              sap,            sap_mask),
				 gc.KeyTuple('lkp.ip_len',                       l3_len_bitmask, l3_len_bitmask_mask),
				 gc.KeyTuple('lkp.ip_proto',                     l3_proto,       l3_proto_mask),
				 gc.KeyTuple('lkp.ip_src_addr[31:0]',            gc.ipv4_to_bytes('0.0.0.0'), 0),
				 gc.KeyTuple('lkp.ip_dst_addr[31:0]',            gc.ipv4_to_bytes('0.0.0.0'), 0),
				 gc.KeyTuple('lkp.l4_src_port',                  l4_src,         l4_src_mask),
				 gc.KeyTuple('lkp.l4_dst_port',                  l4_dst,         l4_dst_mask),
				 gc.KeyTuple('lkp.tunnel_type',                  tun_type,       tun_type_mask),
				 gc.KeyTuple('$MATCH_PRIORITY',                  655426)],
			)],
			[table.make_data(
				[gc.DataTuple('flow_class',                      flow_class),
				 gc.DataTuple('drop',                            drop),
				 gc.DataTuple('scope',                           scope),
				 gc.DataTuple('terminate',                       terminate),
				 gc.DataTuple('truncate_enable',                 trunc_enable),
				 gc.DataTuple('truncate_len',                    trunc),
				 gc.DataTuple('copy_to_cpu',                     copy_to_cpu),
				 gc.DataTuple('redirect_to_cpu',                 redirect_to_cpu),
				 gc.DataTuple('cpu_reason_code',                 cpu_reason_code),
				 gc.DataTuple('sfc_enable',                      sfc_enable),
				 gc.DataTuple('sfc',                             sfc)],
				'SwitchIngress.npb_ing_top.npb_ing_sf_npb_basic_adv_top.acl.ipv4_acl.hit'
			)]
		)

def npb_npb_sf0_policy_l34_v4_del(self, target,
		sap            = 0, sap_mask            = 0xffff,
		l3_len_bitmask = 0, l3_len_bitmask_mask = 0,
		l3_proto       = 0, l3_proto_mask       = 0,
		l4_src         = 0, l4_src_mask         = 0,
		l4_dst         = 0, l4_dst_mask         = 0,
		tun_type       = 0, tun_type_mask       = 0
		):

		table = self.bfrt_info.table_get('SwitchIngress.npb_ing_top.npb_ing_sf_npb_basic_adv_top.acl.ipv4_acl.acl')

		# read counter
		resp = table.entry_get(
			target,
			[table.make_key(
				[gc.KeyTuple('sap',                              sap,            sap_mask),
				 gc.KeyTuple('lkp.ip_len',                       l3_len_bitmask, l3_len_bitmask_mask),
				 gc.KeyTuple('lkp.ip_proto',                     l3_proto,       l3_proto_mask),
				 gc.KeyTuple('lkp.ip_src_addr[31:0]',            gc.ipv4_to_bytes('0.0.0.0'), 0),
				 gc.KeyTuple('lkp.ip_dst_addr[31:0]',            gc.ipv4_to_bytes('0.0.0.0'), 0),
				 gc.KeyTuple('lkp.l4_src_port',                  l4_src,         l4_src_mask),
				 gc.KeyTuple('lkp.l4_dst_port',                  l4_dst,         l4_dst_mask),
				 gc.KeyTuple('lkp.tunnel_type',                  tun_type,       tun_type_mask),
				 gc.KeyTuple('$MATCH_PRIORITY',                  655426)],
			)],
			{"from_hw": True},
			table.make_data(
				[gc.DataTuple("$COUNTER_SPEC_BYTES"),
				 gc.DataTuple("$COUNTER_SPEC_PKTS")],
				'SwitchIngress.npb_ing_top.npb_ing_sf_npb_basic_adv_top.acl.ipv4_acl.hit',
				get=True
			)
		)

		data_dict = next(resp)[0].to_dict()
		recv_pkts = data_dict["$COUNTER_SPEC_PKTS"]
		recv_bytes = data_dict["$COUNTER_SPEC_BYTES"]

		print "Dumping npb_npb_sf0_policy_l34_v4 counters: pkts", recv_pkts, "bytes", recv_bytes 

		# delete entry
		table.entry_del(
			target,
			[table.make_key(
				[gc.KeyTuple('sap',                              sap,            sap_mask),
				 gc.KeyTuple('lkp.ip_len',                       l3_len_bitmask, l3_len_bitmask_mask),
				 gc.KeyTuple('lkp.ip_proto',                     l3_proto,       l3_proto_mask),
				 gc.KeyTuple('lkp.ip_src_addr[31:0]',            gc.ipv4_to_bytes('0.0.0.0'), 0),
				 gc.KeyTuple('lkp.ip_dst_addr[31:0]',            gc.ipv4_to_bytes('0.0.0.0'), 0),
				 gc.KeyTuple('lkp.l4_src_port',                  l4_src,         l4_src_mask),
				 gc.KeyTuple('lkp.l4_dst_port',                  l4_dst,         l4_dst_mask),
				 gc.KeyTuple('lkp.tunnel_type',                  tun_type,       tun_type_mask),
				 gc.KeyTuple('$MATCH_PRIORITY',                  655426)],
			)]
		)

########################################

# ing sf #0: policy l3 v6

def npb_npb_sf0_policy_l34_v6_add(self, target,
		sap            = 0, sap_mask            = 0xffff,
		l3_len_bitmask = 0, l3_len_bitmask_mask = 0,
		l3_proto       = 0, l3_proto_mask       = 0,
		l4_src         = 0, l4_src_mask         = 0,
		l4_dst         = 0, l4_dst_mask         = 0,
		tun_type       = 0, tun_type_mask       = 0,
		# results
		flow_class     = 0,
		drop           = 0,
		scope          = 0,
		terminate      = 0, # note: terminate & !scope is nonsense
		trunc_enable   = 0, trunc               = 0,
		copy_to_cpu    = 0,
		redirect_to_cpu = 0,
		cpu_reason_code = 0,
		sfc_enable     = 0, sfc                 = 0
		):

		# ensure that whenever "terminate" is set, "scope" is also set
		if(terminate):
			scope = 1;

		table = self.bfrt_info.table_get('SwitchIngress.npb_ing_top.npb_ing_sf_npb_basic_adv_top.acl.ipv6_acl.acl')
		table.entry_add(
			target,
			[table.make_key(
				[gc.KeyTuple('sap',                              sap,            sap_mask),
				 gc.KeyTuple('lkp.ip_len',                       l3_len_bitmask, l3_len_bitmask_mask),
				 gc.KeyTuple('lkp.ip_proto',                     l3_proto,       l3_proto_mask),
				 gc.KeyTuple('lkp.ip_src_addr',                  0,              0),
				 gc.KeyTuple('lkp.ip_dst_addr',                  0,              0),
				 gc.KeyTuple('lkp.l4_src_port',                  l4_src,         l4_src_mask),
				 gc.KeyTuple('lkp.l4_dst_port',                  l4_dst,         l4_dst_mask),
				 gc.KeyTuple('lkp.tunnel_type',                  tun_type,       tun_type_mask)],
			)],
			[table.make_data(
				[gc.DataTuple('flow_class',                      flow_class),
				 gc.DataTuple('drop',                            drop),
				 gc.DataTuple('scope',                           scope),
				 gc.DataTuple('terminate',                       terminate),
				 gc.DataTuple('truncate_enable',                 trunc_enable),
				 gc.DataTuple('truncate_len',                    trunc),
				 gc.DataTuple('copy_to_cpu',                     copy_to_cpu),
				 gc.DataTuple('redirect_to_cpu',                 redirect_to_cpu),
				 gc.DataTuple('cpu_reason_code',                 cpu_reason_code),
				 gc.DataTuple('sfc_enable',                      sfc_enable),
				 gc.DataTuple('sfc',                             sfc)],
				'SwitchIngress.npb_ing_top.npb_ing_sf_npb_basic_adv_top.acl.ipv6_acl.hit'
			)]
		)

def npb_npb_sf0_policy_l34_v6_del(self, target,
		sap            = 0, sap_mask            = 0xffff,
		l3_len_bitmask = 0, l3_len_bitmask_mask = 0,
		l3_proto       = 0, l3_proto_mask       = 0,
		l4_src         = 0, l4_src_mask         = 0,
		l4_dst         = 0, l4_dst_mask         = 0,
		tun_type       = 0, tun_type_mask       = 0
		):

		table = self.bfrt_info.table_get('SwitchIngress.npb_ing_top.npb_ing_sf_npb_basic_adv_top.acl.ipv6_acl.acl')

		# read counter
		resp = table.entry_get(
			target,
			[table.make_key(
				[gc.KeyTuple('sap',                              sap,            sap_mask),
				 gc.KeyTuple('lkp.ip_len',                       l3_len_bitmask, l3_len_bitmask_mask),
				 gc.KeyTuple('lkp.ip_proto',                     l3_proto,       l3_proto_mask),
				 gc.KeyTuple('lkp.ip_src_addr',                  0,              0),
				 gc.KeyTuple('lkp.ip_dst_addr',                  0,              0),
				 gc.KeyTuple('lkp.l4_src_port',                  l4_src,         l4_src_mask),
				 gc.KeyTuple('lkp.l4_dst_port',                  l4_dst,         l4_dst_mask),
				 gc.KeyTuple('lkp.tunnel_type',                  tun_type,       tun_type_mask)],
			)],
			{"from_hw": True},
			table.make_data(
				[gc.DataTuple("$COUNTER_SPEC_BYTES"),
				 gc.DataTuple("$COUNTER_SPEC_PKTS")],
				'SwitchIngress.npb_ing_top.npb_ing_sf_npb_basic_adv_top.acl.ipv6_acl.hit',
				get=True
			)
		)

		data_dict = next(resp)[0].to_dict()
		recv_pkts = data_dict["$COUNTER_SPEC_PKTS"]
		recv_bytes = data_dict["$COUNTER_SPEC_BYTES"]

		print "Dumping npb_npb_sf0_policy_l34_v6 counters: pkts", recv_pkts, "bytes", recv_bytes 

		# delete entry
		table.entry_del(
			target,
			[table.make_key(
				[gc.KeyTuple('sap',                              sap,            sap_mask),
				 gc.KeyTuple('lkp.ip_len',                       l3_len_bitmask, l3_len_bitmask_mask),
				 gc.KeyTuple('lkp.ip_proto',                     l3_proto,       l3_proto_mask),
				 gc.KeyTuple('lkp.ip_src_addr',                  0,              0),
				 gc.KeyTuple('lkp.ip_dst_addr',                  0,              0),
				 gc.KeyTuple('lkp.l4_src_port',                  l4_src,         l4_src_mask),
				 gc.KeyTuple('lkp.l4_dst_port',                  l4_dst,         l4_dst_mask),
				 gc.KeyTuple('lkp.tunnel_type',                  tun_type,       tun_type_mask)],
			)]
		)

########################################

# ing sf #0: policy l7

def npb_npb_sf0_policy_l7_add(self, target,
		sap         = 0, sap_mask      = 0xffff,
		udf         = 0, udf_mask      = 0,
		# results
		drop        = 0,
		scope       = 0,
		terminate   = 0, # note: terminate & !scope is nonsense
		trunc_enable= 0, trunc         = 0,
		copy_to_cpu = 0,
		redirect_to_cpu = 0,
		cpu_reason_code = 0,
		sfc_enable  = 0, sfc           = 0
		):

		# ensure that whenever "terminate" is set, "scope" is also set
		if(terminate):
			scope = 1;

		table = self.bfrt_info.table_get('SwitchIngress.npb_ing_top.npb_ing_sf_npb_basic_adv_top.acl.l7_acl.acl')
		table.entry_add(
			target,
			[table.make_key(
				[gc.KeyTuple('sap',                              sap,            sap_mask),
				 gc.KeyTuple('hdr_udf.opaque',                   udf,            udf_mask)],
			)],
			[table.make_data(
				[gc.DataTuple('drop',                            drop),
				 gc.DataTuple('scope',                           scope),
				 gc.DataTuple('terminate',                       terminate),
				 gc.DataTuple('truncate_enable',                 trunc_enable),
				 gc.DataTuple('truncate_len',                    trunc),
				 gc.DataTuple('copy_to_cpu',                     copy_to_cpu),
				 gc.DataTuple('redirect_to_cpu',                 redirect_to_cpu),
				 gc.DataTuple('cpu_reason_code',                 cpu_reason_code),
				 gc.DataTuple('sfc_enable',                      sfc_enable),
				 gc.DataTuple('sfc',                             sfc)],
				'SwitchIngress.npb_ing_top.npb_ing_sf_npb_basic_adv_top.acl.l7_acl.hit'
			)]
		)

def npb_npb_sf0_policy_l7_del(self, target,
		sap         = 0, sap_mask      = 0xffff,
		udf         = 0, udf_mask      = 0
		):

		table = self.bfrt_info.table_get('SwitchIngress.npb_ing_top.npb_ing_sf_npb_basic_adv_top.acl.l7_acl.acl')

		# read counter
		resp = table.entry_get(
			target,
			[table.make_key(
				[gc.KeyTuple('sap',                              sap,            sap_mask),
				 gc.KeyTuple('hdr_udf.opaque',                   udf,            udf_mask)],
			)],
			{"from_hw": True},
			table.make_data(
				[gc.DataTuple("$COUNTER_SPEC_BYTES"),
				 gc.DataTuple("$COUNTER_SPEC_PKTS")],
				'SwitchIngress.npb_ing_top.npb_ing_sf_npb_basic_adv_top.acl.l7_acl.hit',
				get=True
			)
		)

		data_dict = next(resp)[0].to_dict()
		recv_pkts = data_dict["$COUNTER_SPEC_PKTS"]
		recv_bytes = data_dict["$COUNTER_SPEC_BYTES"]

		print "Dumping npb_npb_sf0_policy_l7 counters: pkts", recv_pkts, "bytes", recv_bytes 

		# delete entry
		table.entry_del(
			target,
			[table.make_key(
				[gc.KeyTuple('sap',                              sap,            sap_mask),
				 gc.KeyTuple('hdr_udf.opaque',                   udf,            udf_mask)],
			)],
		)

########################################

# ing sf #0 : scheduler flow class

def npb_npb_sf0_policy_sfp_sel_hash_add(self, target, vpn, flowclass):
	try:
			# insert both copies of the table:

			table = self.bfrt_info.table_get('SwitchIngress.npb_ing_top.npb_ing_sf_npb_basic_adv_sfp_hash_lkp_1.ing_flow_class')
			table.entry_add(
				target,
				[table.make_key(
					[gc.KeyTuple('vpn',                              vpn, 0xffff)],
				)],
				[table.make_data(
					[gc.DataTuple('flow_class',                      flowclass)],
					'SwitchIngress.npb_ing_top.npb_ing_sf_npb_basic_adv_sfp_hash_lkp_1.ing_flow_class_hit'
				)]
			)

#			table = self.bfrt_info.table_get('SwitchIngress.npb_ing_top.npb_ing_sf_npb_basic_adv_sfp_hash_lkp_2.ing_flow_class')
#			table.entry_add(
#				target,
#				[table.make_key(
#					[gc.KeyTuple('vpn',                              vpn, 0xffff)],
#				)],
#				[table.make_data(
#					[gc.DataTuple('flow_class',                      flowclass)],
#					'SwitchIngress.npb_ing_top.npb_ing_sf_npb_basic_adv_sfp_hash_lkp_2.ing_flow_class_hit'
#				)]
#			)

	except:
		print("A table operation failed. This is typically due to adding or removing a duplicate, and can be ignored.")

def npb_npb_sf0_policy_sfp_sel_hash_del(self, target, vpn):
	try:
			# delete both copies of the table:

			table = self.bfrt_info.table_get('SwitchIngress.npb_ing_top.npb_ing_sf_npb_basic_adv_sfp_hash_lkp_1.ing_flow_class')
			table.entry_add(
				target,
				[table.make_key(
					[gc.KeyTuple('vpn',                              vpn, 0xffff)],
				)],
			)

#			table = self.bfrt_info.table_get('SwitchIngress.npb_ing_top.npb_ing_sf_npb_basic_adv_sfp_hash_lkp_2.ing_flow_class')
#			table.entry_add(
#				target,
#				[table.make_key(
#					[gc.KeyTuple('vpn',                              vpn, 0xffff)],
#				)],
#			)

	except:
		print("A table operation failed. This is typically due to adding or removing a duplicate, and can be ignored.")

########################################

# ing sf #0: scheduler selector

def npb_npb_sf0_policy_sfp_sel_single_add(self, target, sfc, sfc_member_ptr, spi, si, si_predec):
		if(SFF_SCHD_SIMPLE == True):
			self.insert_table_entry(
				target,
				'SwitchIngress.npb_ing_top.npb_ing_sf_npb_basic_adv_sfp_sel.ing_schd',
				[self.KeyField('sfc',                              self.to_bytes(sfc, 2))],
				'SwitchIngress.npb_ing_top.npb_ing_sf_npb_basic_adv_sfp_sel.ing_schd_hit',
				[self.DataField('spi',                             self.to_bytes(spi, 3)),
				 self.DataField('si',                              self.to_bytes(si, 1)),
				 self.DataField('si_predec',                       self.to_bytes(si_predec, 1))])
		else:

			# bottom
#			table = self.bfrt_info.table_get('SwitchIngress.npb_ing_top.npb_ing_sf_npb_basic_adv_sfp_sel.schd_selector')
			table = self.bfrt_info.table_get('SwitchIngress.npb_ing_top.npb_ing_sf_npb_basic_adv_sfp_sel.schd_action_profile')
			table.entry_add(
				target,
				[table.make_key(
					[gc.KeyTuple('$ACTION_MEMBER_ID',                sfc_member_ptr)],
				)],
				[table.make_data(
					[gc.DataTuple('spi',                             spi),
					 gc.DataTuple('si',                              si),
					 gc.DataTuple('si_predec',                       si_predec)],
					'SwitchIngress.npb_ing_top.npb_ing_sf_npb_basic_adv_sfp_sel.ing_schd_hit'
				)]
			)

			try:

				# top
				table = self.bfrt_info.table_get('SwitchIngress.npb_ing_top.npb_ing_sf_npb_basic_adv_sfp_sel.ing_schd')
				table.entry_add(
					target,
					[table.make_key(
						[gc.KeyTuple('sfc',                              sfc)],
					)],
					[table.make_data(
						[gc.DataTuple('$ACTION_MEMBER_ID',               sfc_member_ptr)],
						None
					)]
				)

			except:
				print("A table operation failed. This is typically due to adding or removing a duplicate, and can be ignored.")

def npb_npb_sf0_policy_sfp_sel_single_del(self, target, sfc, sfc_member_ptr):
		if(SFF_SCHD_SIMPLE == True):
			self.delete_table_entry(
				target,
				'SwitchIngress.npb_ing_top.npb_ing_sf_npb_basic_adv_sfp_sel.ing_schd',
				[self.KeyField('sfc',                              self.to_bytes(sfc, 2))])
		else:
			try:

				# top
				table = self.bfrt_info.table_get('SwitchIngress.npb_ing_top.npb_ing_sf_npb_basic_adv_sfp_sel.ing_schd')
				table.entry_del(
					target,
					[table.make_key(
						[gc.KeyTuple('sfc',                              sfc)],
					)],
				)

			except:
				print("A table operation failed. This is typically due to adding or removing a duplicate, and can be ignored.")

			# bottom
#			table = self.bfrt_info.table_get('SwitchIngress.npb_ing_top.npb_ing_sf_npb_basic_adv_sfp_sel.schd_selector')
			table = self.bfrt_info.table_get('SwitchIngress.npb_ing_top.npb_ing_sf_npb_basic_adv_sfp_sel.schd_action_profile')
			table.entry_del(
				target,
				[table.make_key(
					[gc.KeyTuple('$ACTION_MEMBER_ID',                sfc_member_ptr)],
				)],
			)

########################################

# ing sf #0: scheduler selector

def npb_npb_sf0_policy_sfp_sel_multi_add(self, target, sfc, sfc_group_ptr, sfc_member_ptr, spi, si, si_predec):
		if(SFF_SCHD_SIMPLE == True):
			self.insert_table_entry(
				target,
				'SwitchIngress.npb_ing_top.npb_ing_sf_npb_basic_adv_sfp_sel.ing_schd',
				[self.KeyField('sfc',                              self.to_bytes(sfc, 2))],
				'SwitchIngress.npb_ing_top.npb_ing_sf_npb_basic_adv_sfp_sel.ing_schd_hit',
				[self.DataField('spi',                             self.to_bytes(spi[0], 3)),
				 self.DataField('si',                              self.to_bytes(si[0], 1)),
				 self.DataField('si_predec',                       self.to_bytes(si_predec[0], 1))])
		else:
			sfc_member_ptr_list = []
			sfc_member_sts_list = []

			for i in range(len(spi)):
				sfc_member_ptr_list.append(sfc_member_ptr+i)
				sfc_member_sts_list.append(True)

			for i in range(len(spi)):

				# bottom
#				table = self.bfrt_info.table_get('SwitchIngress.npb_ing_top.npb_ing_sf_npb_basic_adv_sfp_sel.schd_selector')
				table = self.bfrt_info.table_get('SwitchIngress.npb_ing_top.npb_ing_sf_npb_basic_adv_sfp_sel.schd_action_profile')
				table.entry_add(
					target,
					[table.make_key(
						[gc.KeyTuple('$ACTION_MEMBER_ID',                sfc_member_ptr_list[i])],
					)],
					[table.make_data(
						[gc.DataTuple('spi',                             spi[i]),
						 gc.DataTuple('si',                              si[i]),
						 gc.DataTuple('si_predec',                       si_predec[i])],
						'SwitchIngress.npb_ing_top.npb_ing_sf_npb_basic_adv_sfp_sel.ing_schd_hit'
					)]
				)

			# middle
#			table = self.bfrt_info.table_get('SwitchIngress.npb_ing_top.npb_ing_sf_npb_basic_adv_sfp_sel.schd_selector_sel')
			table = self.bfrt_info.table_get('SwitchIngress.npb_ing_top.npb_ing_sf_npb_basic_adv_sfp_sel.schd_selector')
			table.entry_add(
				target,
				[table.make_key(
					[gc.KeyTuple('$SELECTOR_GROUP_ID',               sfc_group_ptr)],
				)],
				[table.make_data(
					[gc.DataTuple('$ACTION_MEMBER_ID',               int_arr_val=sfc_member_ptr_list), # needs to be a list!
					 gc.DataTuple('$ACTION_MEMBER_STATUS',           bool_arr_val=sfc_member_sts_list), # needs to be a list!
					 gc.DataTuple('$MAX_GROUP_SIZE',                 len(spi))],
					None
				)]
			)

			# top
			table = self.bfrt_info.table_get('SwitchIngress.npb_ing_top.npb_ing_sf_npb_basic_adv_sfp_sel.ing_schd')
			table.entry_add(
				target,
				[table.make_key(
					[gc.KeyTuple('sfc',                              sfc)],
				)],
				[table.make_data(
					[gc.DataTuple('$SELECTOR_GROUP_ID',              sfc_group_ptr)],
					None
				)]
			)

def npb_npb_sf0_policy_sfp_sel_multi_del(self, target, sfc, sfc_group_ptr, sfc_member_ptr, num_entries):
		if(SFF_SCHD_SIMPLE == True):
			self.delete_table_entry(
				target,
				'SwitchIngress.npb_ing_top.npb_ing_sf_npb_basic_adv_sfp_sel.ing_schd',
				[self.KeyField('sfc',                              self.to_bytes(sfc, 2))])
		else:
			sfc_member_ptr_list = []

			for i in range(0, num_entries):
				sfc_member_ptr_list.append(sfc_member_ptr+i)

			# top
			table = self.bfrt_info.table_get('SwitchIngress.npb_ing_top.npb_ing_sf_npb_basic_adv_sfp_sel.ing_schd')
			table.entry_del(
				target,
				[table.make_key(
					[gc.KeyTuple('sfc',                              sfc)],
				)],
			)

			# middle
#			table = self.bfrt_info.table_get('SwitchIngress.npb_ing_top.npb_ing_sf_npb_basic_adv_sfp_sel.schd_selector_sel')
			table = self.bfrt_info.table_get('SwitchIngress.npb_ing_top.npb_ing_sf_npb_basic_adv_sfp_sel.schd_selector')
			table.entry_del(
				target,
				[table.make_key(
					[gc.KeyTuple('$SELECTOR_GROUP_ID',               sfc_group_ptr)],
				)],
			)

			for i in range(0, num_entries):

				# bottom
#				table = self.bfrt_info.table_get('SwitchIngress.npb_ing_top.npb_ing_sf_npb_basic_adv_sfp_sel.schd_selector')
				table = self.bfrt_info.table_get('SwitchIngress.npb_ing_top.npb_ing_sf_npb_basic_adv_sfp_sel.schd_action_profile')
				table.entry_del(
					target,
					[table.make_key(
						[gc.KeyTuple('$ACTION_MEMBER_ID',                sfc_member_ptr_list[i])],
					)],
				)

########################################

# ing sff: fib

def npb_npb_sff_fib_add(self, target, spi, si, nexthop_ptr, end_of_chain):

		try:

			table = self.bfrt_info.table_get('SwitchIngress.npb_ing_top.npb_ing_sff_top.ing_sff_fib')
			table.entry_add(
				target,
				[table.make_key(
					[gc.KeyTuple('spi',                              spi),
					 gc.KeyTuple('si',                               si)]
				)],
				[table.make_data(
					[gc.DataTuple('nexthop_index',                   nexthop_ptr),
					 gc.DataTuple('end_of_chain',                    end_of_chain)],
				'SwitchIngress.npb_ing_top.npb_ing_sff_top.unicast'
				)]
			)

		except:
			print("A table operation failed. This is typically due to adding or removing a duplicate, and can be ignored.")

def npb_npb_sff_fib_del(self, target, spi, si):

		try:

			table = self.bfrt_info.table_get('SwitchIngress.npb_ing_top.npb_ing_sff_top.ing_sff_fib')
			table.entry_del(
				target,
				[table.make_key(
					[gc.KeyTuple('spi',                              spi),
					 gc.KeyTuple('si',                               si)]
				)]
			)

		except:
			print("A table operation failed. This is typically due to adding or removing a duplicate, and can be ignored.")

########################################

# ing sf #1: multicast

def npb_npb_sf1_action_sel_add(self, target, spi, si, bitmask, mgid):

		table = self.bfrt_info.table_get('SwitchIngress.npb_ing_top.npb_ing_sf_multicast_top_part1.ing_sf_action_sel')
		table.entry_add(
			target,
			[table.make_key(
				[gc.KeyTuple('spi',                               spi),
				 gc.KeyTuple('si',                                si)],
			)],
			[table.make_data(
				[gc.DataTuple('mgid',                            mgid)],
				'SwitchIngress.npb_ing_top.npb_ing_sf_multicast_top_part1.ing_sf_action_sel_hit',
			)]
		)

def npb_npb_sf1_action_sel_del(self, target, spi, si):

		table = self.bfrt_info.table_get('SwitchIngress.npb_ing_top.npb_ing_sf_multicast_top_part1.ing_sf_action_sel')
		table.entry_del(
			target,
			[table.make_key(
				[gc.KeyTuple('spi',                               spi),
				 gc.KeyTuple('si',                                si)],
			)],
		)

########################################

def npb_nexthop_add(self, target, nexthop_ptr, bd, port_lag_ptr):

		try:

			table = self.bfrt_info.table_get('SwitchIngress.nexthop.nexthop')
			table.entry_add(
				target,
				[table.make_key(
					[gc.KeyTuple('ig_md.nexthop',                    nexthop_ptr)],
				)],
				[table.make_data(
					[gc.DataTuple('bd',                              bd),
					 gc.DataTuple('port_lag_index',                  port_lag_ptr)],
					'SwitchIngress.nexthop.set_nexthop_properties'
				)]
			)

			# ---------------------------
			# Egress portion of table
			# ---------------------------

			table = self.bfrt_info.table_get('SwitchEgress.rewrite.nexthop_rewrite')
			table.entry_add(
				target,
				[table.make_key(
					[gc.KeyTuple('eg_md.nexthop',                    nexthop_ptr)],
				)],
				[table.make_data(
					[],
					'NoAction'
				)]
			)

		except:
			print("A table operation failed. This is typically due to adding or removing a duplicate, and can be ignored.")

def npb_nexthop_tunnel_encap_add(self, target, nexthop_ptr, bd, tunnel_ptr, tun_type):

		try:

			table = self.bfrt_info.table_get('SwitchIngress.nexthop.nexthop')
			table.entry_add(
				target,
				[table.make_key(
					[gc.KeyTuple('ig_md.nexthop',                    nexthop_ptr)]
				)],
				[table.make_data(
					[gc.DataTuple('bd',                            bd),
					 gc.DataTuple('tunnel_index',                  tunnel_ptr)],
					'SwitchIngress.nexthop.set_nexthop_properties_tunnel'
				)]
			)

			# ---------------------------
			# Egress portion of table
			# ---------------------------

			table = self.bfrt_info.table_get('SwitchEgress.rewrite.nexthop_rewrite')
			table.entry_add(
				target,
				[table.make_key(
					[gc.KeyTuple('eg_md.nexthop',                    nexthop_ptr)]
				)],
				[table.make_data(
					[gc.DataTuple('type',                            tun_type)], # 3 means MAC-in-MAC tunnel!!!!
					'SwitchEgress.rewrite.rewrite_l2_with_tunnel'
				)]
			)

		except:
			print("A table operation failed. This is typically due to adding or removing a duplicate, and can be ignored.")

def npb_nexthop_del(self, target, nexthop_ptr):

		try:

			table = self.bfrt_info.table_get('SwitchIngress.nexthop.nexthop')
			table.entry_del(
				target,
				[table.make_key(
					[gc.KeyTuple('ig_md.nexthop',                    nexthop_ptr)]
				)]
			)

			# ---------------------------
			# Egress portion of table
			# ---------------------------

			table = self.bfrt_info.table_get('SwitchEgress.rewrite.nexthop_rewrite')
			table.entry_del(
				target,
				[table.make_key(
					[gc.KeyTuple('eg_md.nexthop',                    nexthop_ptr)]
				)],
			)

		except:
			print("A table operation failed. This is typically due to adding or removing a duplicate, and can be ignored.")

########################################

def npb_tunnel_encap_nexthop_add(self, target, tunnel_ptr, port_lag_ptr, outer_nexthop_ptr):

		table = self.bfrt_info.table_get('SwitchIngress.outer_fib.fib')
		table.entry_add(
			target,
			[table.make_key(
				[gc.KeyTuple('ig_md.tunnel_0.index',             tunnel_ptr)],
			)],
			[table.make_data(
				[gc.DataTuple('port_lag_index',                  port_lag_ptr),
				 gc.DataTuple('nexthop_index',                   outer_nexthop_ptr)],
				'SwitchIngress.outer_fib.set_nexthop_properties'
			)]
		)

		# ---------------------------
		# Egress portion of table
		# ---------------------------

def npb_tunnel_encap_nexthop_del(self, target, tunnel_ptr):

		table = self.bfrt_info.table_get('SwitchIngress.outer_fib.fib')
		table.entry_del(
			target,
			[table.make_key(
				[gc.KeyTuple('ig_md.tunnel_0.index',             tunnel_ptr)],
			)]
		)

		# ---------------------------
		# Egress portion of table
		# ---------------------------

########################################

def npb_lag_single_add(self, target, port_lag_ptr, port_lag_member_ptr, port):

		try:

			# bottom
#			table = self.bfrt_info.table_get('SwitchIngress.lag.lag_selector')
			table = self.bfrt_info.table_get('SwitchIngress.lag.lag_action_profile')
			table.entry_add(
				target,
				[table.make_key(
					[gc.KeyTuple('$ACTION_MEMBER_ID',                port_lag_member_ptr)],
				)],
				[table.make_data(
					[gc.DataTuple('port',                            port)],
					'SwitchIngress.lag.set_lag_port'
				)]
			)

			# top
			table = self.bfrt_info.table_get('SwitchIngress.lag.lag')
			table.entry_add(
				target,
				[table.make_key(
					[gc.KeyTuple('port_lag_index',                   port_lag_ptr)],
				)],
				[table.make_data(
					[gc.DataTuple('$ACTION_MEMBER_ID',               port_lag_member_ptr)],
					None
				)]
			)

		except:
			print("A table operation failed. This is typically due to adding or removing a duplicate, and can be ignored.")

def npb_lag_single_del(self, target, port_lag_ptr, port_lag_member_ptr):

		try:

			# top
			table = self.bfrt_info.table_get('SwitchIngress.lag.lag')
			table.entry_del(
				target,
				[table.make_key(
					[gc.KeyTuple('port_lag_index',                   port_lag_ptr)],
				)]
			)

			# bottom
#			table = self.bfrt_info.table_get('SwitchIngress.lag.lag_selector')
			table = self.bfrt_info.table_get('SwitchIngress.lag.lag_action_profile')
			table.entry_del(
				target,
				[table.make_key(
					[gc.KeyTuple('$ACTION_MEMBER_ID',                port_lag_member_ptr)],
				)],
			)

		except:
			print("A table operation failed. This is typically due to adding or removing a duplicate, and can be ignored.")

########################################

def npb_lag_multi_add(self, target, port_lag_ptr, port_lag_group_ptr, port_lag_member_ptr, port):
		port_lag_member_ptr_list = []
		port_lag_member_sts_list = []

		for i in range(len(port)):
			port_lag_member_ptr_list.append(port_lag_member_ptr+i)
			port_lag_member_sts_list.append(True)

		for i in range(len(port)):

			# bottom
#			table = self.bfrt_info.table_get('SwitchIngress.lag.lag_selector')
			table = self.bfrt_info.table_get('SwitchIngress.lag.lag_action_profile')
			table.entry_add(
				target,
				[table.make_key(
					[gc.KeyTuple('$ACTION_MEMBER_ID',                port_lag_member_ptr_list[i])],
				)],
				[table.make_data(
					[gc.DataTuple('port',                            port[i])],
					'SwitchIngress.lag.set_lag_port'
				)]
			)

		# middle
#		table = self.bfrt_info.table_get('SwitchIngress.lag.lag_selector_sel')
		table = self.bfrt_info.table_get('SwitchIngress.lag.lag_selector')
		table.entry_add(
			target,
			[table.make_key(
				[gc.KeyTuple('$SELECTOR_GROUP_ID',               port_lag_group_ptr)],
			)],
			[table.make_data(
				[gc.DataTuple('$ACTION_MEMBER_ID',               int_arr_val=port_lag_member_ptr_list), # needs to be a list!
				 gc.DataTuple('$ACTION_MEMBER_STATUS',           bool_arr_val=port_lag_member_sts_list), # needs to be a list!
				 gc.DataTuple('$MAX_GROUP_SIZE',                 len(port))],
				None
			)]
		)

		# top
		table = self.bfrt_info.table_get('SwitchIngress.lag.lag')
		table.entry_add(
			target,
			[table.make_key(
				[gc.KeyTuple('port_lag_index',                   port_lag_ptr)],
			)],
			[table.make_data(
				[gc.DataTuple('$SELECTOR_GROUP_ID',              port_lag_group_ptr)],
				None
			)]
		)

def npb_lag_multi_del(self, target, port_lag_ptr, port_lag_group_ptr, port_lag_member_ptr, num_entries):
		port_lag_member_ptr_list = []

		for i in range(0, num_entries):
			port_lag_member_ptr_list.append(port_lag_member_ptr+i)

		# top
		table = self.bfrt_info.table_get('SwitchIngress.lag.lag')
		table.entry_del(
			target,
			[table.make_key(
				[gc.KeyTuple('port_lag_index',                   port_lag_ptr)],
			)],
		)

		# middle
#		table = self.bfrt_info.table_get('SwitchIngress.lag.lag_selector_sel')
		table = self.bfrt_info.table_get('SwitchIngress.lag.lag_selector')
		table.entry_del(
			target,
			[table.make_key(
				[gc.KeyTuple('$SELECTOR_GROUP_ID',               port_lag_group_ptr)],
			)],
		)

		for i in range(0, num_entries):

			# bottom
#			table = self.bfrt_info.table_get('SwitchIngress.lag.lag_selector')
			table = self.bfrt_info.table_get('SwitchIngress.lag.lag_action_profile')
			table.entry_del(
				target,
				[table.make_key(
					[gc.KeyTuple('$ACTION_MEMBER_ID',                port_lag_member_ptr_list[i])],
				)],
			)


########################################
# TM: Multicast Node & MGID Tables
########################################

# Level 1 (upper level)

def npb_pre_mgid_add(self, target, mgid, nodes):

	table = self.bfrt_info.table_get("$pre.mgid")
	table.entry_add(
		target,
		[table.make_key(
			[gc.KeyTuple('$MGID',                         mgid)]
		)],
		[table.make_data(
			[gc.DataTuple('$MULTICAST_NODE_ID',           int_arr_val = nodes), # a list
			 gc.DataTuple('$MULTICAST_NODE_L1_XID_VALID', bool_arr_val= [0]),   # a list
			 gc.DataTuple('$MULTICAST_NODE_L1_XID',       int_arr_val = [0])]   # a list
		)]
	)

def npb_pre_mgid_del(self, target, mgid):

	table = self.bfrt_info.table_get("$pre.mgid")
	table.entry_del(
		target,
		[table.make_key(
			[gc.KeyTuple('$MGID',                         mgid)]
		)],
	)

########################################

# Level 2 (lower level)

def npb_pre_node_add(self, target, node, rid, lags, ports):

	table = self.bfrt_info.table_get("$pre.node")
	table.entry_add(
		target,
		[table.make_key(
			[gc.KeyTuple('$MULTICAST_NODE_ID',            node)]
		)],
		[table.make_data(
			[gc.DataTuple('$MULTICAST_RID',               rid),
			 gc.DataTuple('$MULTICAST_LAG_ID',            int_arr_val = lags),   # a list
			 gc.DataTuple('$DEV_PORT',                    int_arr_val = ports)]  # a lis?
		)]
	)

def npb_pre_node_del(self, target, node):
	table = self.bfrt_info.table_get("$pre.node")
	table.entry_del(
		target,
		[table.make_key(
			[gc.KeyTuple('$MULTICAST_NODE_ID',            node)]
		)],
	)

########################################
# TM: Multicast Port Table
########################################

def npb_pre_port_add(self, target, port):
	table = self.bfrt_info.table_get("$pre.port")
	table.entry_add(
		target,
		[table.make_key(
			[gc.KeyTuple('$DEV_PORT',                     port)]
		)],
		[table.make_data(
			[gc.DataTuple('$COPY_TO_CPU_PORT_ENABLE',     bool_val=True)],
		)]
	)

def npb_pre_port_del(self, target, port):
	# this table can't be deleted, only changed, since there is one entry per port

#	table = self.bfrt_info.table_get("$pre.port")
#	table.entry_del(
#		target,
#		[table.make_key(
#			[gc.KeyTuple('$DEV_PORT',                     port)]
#		)],
#	)

	table = self.bfrt_info.table_get("$pre.port")
	table.entry_add(
		target,
		[table.make_key(
			[gc.KeyTuple('$DEV_PORT',                     port)]
		)],
		[table.make_data(
			[gc.DataTuple('$COPY_TO_CPU_PORT_ENABLE',     bool_val=False)],
		)]
	)

########################################

def npb_pre_mirror_add(self, target, session_id, direction, port): # direction = INGRESS or EGRESS
	table = self.bfrt_info.table_get("$mirror.cfg")
	table.entry_add(
		target,
		[table.make_key(
			[gc.KeyTuple ('$sid',                     session_id)]
		)],
		[table.make_data(
			[gc.DataTuple('$direction',               str_val=direction),
			 gc.DataTuple('$ucast_egress_port',       port),
			 gc.DataTuple('$ucast_egress_port_valid', bool_val=True),
			 gc.DataTuple('$session_enable',          bool_val=True)],
			'$normal'
		)]
	)

def npb_pre_mirror_del(self, target, session_id):
	table = self.bfrt_info.table_get("$mirror.cfg")
	table.entry_del(
		target,
		[table.make_key(
			[gc.KeyTuple ('$sid',                     session_id)]
		)],
	)

########################################
# Egress
########################################

def npb_egr_port_add(self, target, port, port_lag_ptr):

	for i in range(len(port)):

		try:

			table = self.bfrt_info.table_get('SwitchEgress.egress_port_mapping.port_mapping')
			table.entry_add(
				target,
				[table.make_key(
					[gc.KeyTuple('port',                                      port[i])],
				)],
				[table.make_data(
					[gc.DataTuple('port_lag_index',                           port_lag_ptr)],
					'SwitchEgress.egress_port_mapping.port_normal'
				)]
			)

		except:
			print("A table operation failed. This is typically due to adding or removing a duplicate, and can be ignored.")

def npb_egr_port_cpu_add(self, target, port, port_lag_ptr):

	for i in range(len(port)):

		try:

			table = self.bfrt_info.table_get('SwitchEgress.egress_port_mapping.port_mapping')
			table.entry_add(
				target,
				[table.make_key(
					[gc.KeyTuple('port',                                      port[i])],
				)],
				[table.make_data(
					[gc.DataTuple('port_lag_index',                           port_lag_ptr)],
					'SwitchEgress.egress_port_mapping.port_cpu'
				)]
			)

		except:
			print("A table operation failed. This is typically due to adding or removing a duplicate, and can be ignored.")

def npb_egr_port_del(self, target, port):

	for i in range(len(port)):

		try:

			table = self.bfrt_info.table_get('SwitchEgress.egress_port_mapping.port_mapping')
			table.entry_del(
				target,
				[table.make_key(
					[gc.KeyTuple('port',                                      port[i])],
				)]
			)

		except:
			print("A table operation failed. This is typically due to adding or removing a duplicate, and can be ignored.")

########################################

def npb_egr_port_mirror_add(self, target, port, session_id):

		table = self.bfrt_info.table_get('SwitchEgress.egress_port_mapping.port_mirror.port_mirror')
		table.entry_add(
			target,
			[table.make_key(
				[gc.KeyTuple('port',                             port)],
			)],
			[table.make_data(
				[gc.DataTuple('session_id',                      session_id)],
				'SwitchEgress.egress_port_mapping.port_mirror.set_mirror_id',
			)]
		)

def npb_egr_port_mirror_del(self, target, port):

		table = self.bfrt_info.table_get('SwitchEgress.egress_port_mapping.port_mirror.port_mirror')
		table.entry_del(
			target,
			[table.make_key(
				[gc.KeyTuple('port',                             port)],
			)],
		)

########################################

def npb_mult_rid_add(self, target, rid, bd):

		table = self.bfrt_info.table_get('SwitchEgress.multicast_replication.rid')
		table.entry_add(
			target,
			[table.make_key(
				[gc.KeyTuple('replication_id',                   rid)],
			)],
			[table.make_data(
				[gc.DataTuple('bd',                              bd)],
				'SwitchEgress.multicast_replication.rid_hit_identical_copies',
			)]
		)

def npb_mult_rid_del(self, target, rid):

		table = self.bfrt_info.table_get('SwitchEgress.multicast_replication.rid')
		table.entry_del(
			target,
			[table.make_key(
				[gc.KeyTuple('replication_id',                   rid)],
			)],
		)

########################################

# egr sf #2: action select

def npb_npb_sf2_action_sel_add(self, target, spi, si, bitmask, dsap):
	try:

		table = self.bfrt_info.table_get('SwitchEgress.npb_egr_top.npb_egr_sf_proxy_top.egr_sf_action_sel')
		table.entry_add(
			target,
			[table.make_key(
				[gc.KeyTuple('spi',                              spi),
				 gc.KeyTuple('si',                               si)],
			)],
			[table.make_data(
				[gc.DataTuple('dsap',                            dsap)],
				'SwitchEgress.npb_egr_top.npb_egr_sf_proxy_top.egr_sf_action_sel_hit',
			)]
		)
	except:
		print("A table operation failed. This is typically due to adding or removing a duplicate, and can be ignored.")

def npb_npb_sf2_action_sel_del(self, target, spi, si):
	try:

		table = self.bfrt_info.table_get('SwitchEgress.npb_egr_top.npb_egr_sf_proxy_top.egr_sf_action_sel')
		table.entry_del(
			target,
			[table.make_key(
				[gc.KeyTuple('spi',                              spi),
				 gc.KeyTuple('si',                               si)],
			)],
		)
	except:
		print("A table operation failed. This is typically due to adding or removing a duplicate, and can be ignored.")

########################################

# ing sf #2: ip_len range

def npb_npb_sf2_len_rng_add(self, target, l3_len_lo, l3_len_hi, l3_len_bitmask):

		table = self.bfrt_info.table_get('SwitchEgress.npb_egr_top.npb_egr_sf_proxy_top.egr_sf_ip_len_rng')
		table.entry_add(
			target,
			[table.make_key(
				[gc.KeyTuple('ip_len',                              low=l3_len_lo, high=l3_len_hi)],
			)],
			[table.make_data(
				[gc.DataTuple('rng_bitmask',                        l3_len_bitmask)],
				'SwitchEgress.npb_egr_top.npb_egr_sf_proxy_top.egr_sf_ip_len_rng_hit'
			)]
		)

def npb_npb_sf2_len_rng_del(self, target, l3_len_lo, l3_len_hi):

		table = self.bfrt_info.table_get('SwitchEgress.npb_egr_top.npb_egr_sf_proxy_top.egr_sf_ip_len_rng')
		table.entry_del(
			target,
			[table.make_key(
				[gc.KeyTuple('ip_len',                              low=l3_len_lo, high=l3_len_hi)],
			)],
		)

########################################

# ing sf #2: l4_src_port range

def npb_npb_sf2_l4_src_port_rng_add(self, target, l3_len_lo, l3_len_hi, l3_len_bitmask):

		table = self.bfrt_info.table_get('SwitchEgress.npb_egr_top.npb_egr_sf_proxy_top.egr_sf_l4_src_port_rng')
		table.entry_add(
			target,
			[table.make_key(
				[gc.KeyTuple('l4_src_port',                         low=l3_len_lo, high=l3_len_hi)],
			)],
			[table.make_data(
				[gc.DataTuple('rng_bitmask',                        l3_len_bitmask)],
				'SwitchEgress.npb_egr_top.npb_egr_sf_proxy_top.egr_sf_l4_src_port_rng_hit'
			)]
		)

def npb_npb_sf2_l4_src_port_rng_del(self, target, l3_len_lo, l3_len_hi):

		table = self.bfrt_info.table_get('SwitchEgress.npb_egr_top.npb_egr_sf_proxy_top.egr_sf_l4_src_port_rng')
		table.entry_del(
			target,
			[table.make_key(
				[gc.KeyTuple('l4_src_port',                         low=l3_len_lo, high=l3_len_hi)],
			)],
		)

########################################

# ing sf #2: l4_dst_port range

def npb_npb_sf2_l4_dst_port_rng_add(self, target, l3_len_lo, l3_len_hi, l3_len_bitmask):

		table = self.bfrt_info.table_get('SwitchEgress.npb_egr_top.npb_egr_sf_proxy_top.egr_sf_l4_dst_port_rng')
		table.entry_add(
			target,
			[table.make_key(
				[gc.KeyTuple('l4_dst_port',                         low=l3_len_lo, high=l3_len_hi)],
			)],
			[table.make_data(
				[gc.DataTuple('rng_bitmask',                        l3_len_bitmask)],
				'SwitchEgress.npb_egr_top.npb_egr_sf_proxy_top.egr_sf_l4_dst_port_rng_hit'
			)]
		)

def npb_npb_sf2_l4_dst_port_rng_del(self, target, l3_len_lo, l3_len_hi):

		table = self.bfrt_info.table_get('SwitchEgress.npb_egr_top.npb_egr_sf_proxy_top.egr_sf_l4_dst_port_rng')
		table.entry_del(
			target,
			[table.make_key(
				[gc.KeyTuple('l4_dst_port',                         low=l3_len_lo, high=l3_len_hi)],
			)],
		)

########################################

# ing sf #2: policy l2

def npb_npb_sf2_policy_l2_add(self, target,
		dsap            = 0, dsap_mask           = 0x03ff,
		l2_etype        = 0, l2_etype_mask       = 0,
		tun_type        = 0, tun_type_mask       = 0,
		# results
		drop            = 0,
		terminate_outer = 0,
		terminate_inner = 0,
		terminate       = 0,
		trunc_enable    = 0, trunc               = 0,
		strip_tag_e     = 0,
		strip_tag_vn    = 0,
		strip_tag_vlan  = 0,
		add_tag_vlan_bd = 0,
		dedup_en        = 0,
		copy_to_cpu     = 0,
		redirect_to_cpu = 0,
		cpu_reason_code = 0
		):

		table = self.bfrt_info.table_get('SwitchEgress.npb_egr_top.npb_egr_sf_proxy_top.acl.egress_mac_acl.acl')
		table.entry_add(
			target,
			[table.make_key(
				[gc.KeyTuple('dsap',                             dsap,           dsap_mask),
				 gc.KeyTuple('lkp.mac_src_addr',                 gc.mac_to_bytes('0:0:0:0:0:0'), 0),
				 gc.KeyTuple('lkp.mac_dst_addr',                 gc.mac_to_bytes('0:0:0:0:0:0'), 0),
				 gc.KeyTuple('lkp.mac_type',                     l2_etype,       l2_etype_mask),
				 gc.KeyTuple('lkp.tunnel_type',                  tun_type,       tun_type_mask)],
			)],
			[table.make_data(
				[gc.DataTuple('drop',                            drop),
				 gc.DataTuple('terminate_outer',                 terminate_outer),
				 gc.DataTuple('terminate_inner',                 terminate_inner),
				 gc.DataTuple('terminate',                       terminate),
				 gc.DataTuple('truncate_enable',                 trunc_enable),
				 gc.DataTuple('truncate_len',                    trunc),
				 gc.DataTuple('strip_tag_e',                     strip_tag_e),
				 gc.DataTuple('strip_tag_vn',                    strip_tag_vn),
				 gc.DataTuple('strip_tag_vlan',                  strip_tag_vlan),
				 gc.DataTuple('add_tag_vlan_bd',                 add_tag_vlan_bd),
				 gc.DataTuple('dedup_en',                        dedup_en),
				 gc.DataTuple('copy_to_cpu',                     copy_to_cpu),
				 gc.DataTuple('redirect_to_cpu',                 redirect_to_cpu),
				 gc.DataTuple('cpu_reason_code',                 cpu_reason_code)],
				'SwitchEgress.npb_egr_top.npb_egr_sf_proxy_top.acl.egress_mac_acl.hit'
			)]
		)

def npb_npb_sf2_policy_l2_del(self, target,
		dsap            = 0, dsap_mask           = 0x03ff,
		l2_etype        = 0, l2_etype_mask       = 0,
		tun_type        = 0, tun_type_mask       = 0
		):

		table = self.bfrt_info.table_get('SwitchEgress.npb_egr_top.npb_egr_sf_proxy_top.acl.egress_mac_acl.acl')

		# read counter
		resp = table.entry_get(
			target,
			[table.make_key(
				[gc.KeyTuple('dsap',                             dsap,           dsap_mask),
				 gc.KeyTuple('lkp.mac_src_addr',                 gc.mac_to_bytes('0:0:0:0:0:0'), 0),
				 gc.KeyTuple('lkp.mac_dst_addr',                 gc.mac_to_bytes('0:0:0:0:0:0'), 0),
				 gc.KeyTuple('lkp.mac_type',                     l2_etype,       l2_etype_mask),
				 gc.KeyTuple('lkp.tunnel_type',                  tun_type,       tun_type_mask)],
			)],
			{"from_hw": True},
			table.make_data(
				[gc.DataTuple("$COUNTER_SPEC_BYTES"),
				 gc.DataTuple("$COUNTER_SPEC_PKTS")],
				'SwitchEgress.npb_egr_top.npb_egr_sf_proxy_top.acl.egress_mac_acl.hit',
				get=True
			)
		)

		data_dict = next(resp)[0].to_dict()
		recv_pkts = data_dict["$COUNTER_SPEC_PKTS"]
		recv_bytes = data_dict["$COUNTER_SPEC_BYTES"]

		print "Dumping npb_npb_sf2_policy_l2 counters: pkts", recv_pkts, "bytes", recv_bytes 

		# delete entry
		table.entry_del(
			target,
			[table.make_key(
				[gc.KeyTuple('dsap',                             dsap,           dsap_mask),
				 gc.KeyTuple('lkp.mac_src_addr',                 gc.mac_to_bytes('0:0:0:0:0:0'), 0),
				 gc.KeyTuple('lkp.mac_dst_addr',                 gc.mac_to_bytes('0:0:0:0:0:0'), 0),
				 gc.KeyTuple('lkp.mac_type',                     l2_etype,       l2_etype_mask),
				 gc.KeyTuple('lkp.tunnel_type',                  tun_type,       tun_type_mask)],
			)],
		)

########################################

# ing sf #2: policy l3 v4

def npb_npb_sf2_policy_l34_v4_add(self, target,
		dsap            = 0, dsap_mask           = 0x03ff,
		l3_len_bitmask  = 0, l3_len_bitmask_mask = 0,
		l3_proto        = 0, l3_proto_mask       = 0,
		l4_src          = 0, l4_src_mask         = 0,
		l4_dst          = 0, l4_dst_mask         = 0,
		tun_type        = 0, tun_type_mask       = 0,
		# results
		drop            = 0,
		terminate_outer = 0,
		terminate_inner = 0,
		terminate       = 0,
		trunc_enable    = 0, trunc               = 0,
		strip_tag_e     = 0,
		strip_tag_vn    = 0,
		strip_tag_vlan  = 0,
		add_tag_vlan_bd = 0,
		dedup_en        = 0,
		copy_to_cpu     = 0,
		redirect_to_cpu = 0,
		cpu_reason_code = 0
		):

		table = self.bfrt_info.table_get('SwitchEgress.npb_egr_top.npb_egr_sf_proxy_top.acl.egress_ipv4_acl.acl')
		table.entry_add(
			target,
			[table.make_key(
				[gc.KeyTuple('dsap',                             dsap,           dsap_mask),
				 gc.KeyTuple('lkp.ip_len',                       l3_len_bitmask, l3_len_bitmask_mask),
				 gc.KeyTuple('lkp.ip_proto',                     l3_proto,       l3_proto_mask),
				 gc.KeyTuple('lkp.ip_src_addr[31:0]',            gc.ipv4_to_bytes('0.0.0.0'), 0),
				 gc.KeyTuple('lkp.ip_dst_addr[31:0]',            gc.ipv4_to_bytes('0.0.0.0'), 0),
				 gc.KeyTuple('lkp.l4_src_port',                  l4_src,         l4_src_mask),
				 gc.KeyTuple('lkp.l4_dst_port',                  l4_dst,         l4_dst_mask),
				 gc.KeyTuple('lkp.tunnel_type',                  tun_type,       tun_type_mask)],
			)],
			[table.make_data(
				[gc.DataTuple('drop',                            drop),
				 gc.DataTuple('terminate_outer',                 terminate_outer),
				 gc.DataTuple('terminate_inner',                 terminate_inner),
				 gc.DataTuple('terminate',                       terminate),
				 gc.DataTuple('truncate_enable',                 trunc_enable),
				 gc.DataTuple('truncate_len',                    trunc),
				 gc.DataTuple('strip_tag_e',                     strip_tag_e),
				 gc.DataTuple('strip_tag_vn',                    strip_tag_vn),
				 gc.DataTuple('strip_tag_vlan',                  strip_tag_vlan),
				 gc.DataTuple('add_tag_vlan_bd',                 add_tag_vlan_bd),
				 gc.DataTuple('dedup_en',                        dedup_en),
				 gc.DataTuple('copy_to_cpu',                     copy_to_cpu),
				 gc.DataTuple('redirect_to_cpu',                 redirect_to_cpu),
				 gc.DataTuple('cpu_reason_code',                 cpu_reason_code)],
				'SwitchEgress.npb_egr_top.npb_egr_sf_proxy_top.acl.egress_ipv4_acl.hit'
			)]
		)

def npb_npb_sf2_policy_l34_v4_del(self, target,
		dsap            = 0, dsap_mask           = 0x03ff,
		l3_len_bitmask  = 0, l3_len_bitmask_mask = 0,
		l3_proto        = 0, l3_proto_mask       = 0,
		l4_src          = 0, l4_src_mask         = 0,
		l4_dst          = 0, l4_dst_mask         = 0,
		tun_type        = 0, tun_type_mask       = 0
		):

		table = self.bfrt_info.table_get('SwitchEgress.npb_egr_top.npb_egr_sf_proxy_top.acl.egress_ipv4_acl.acl')
		# read counter
		resp = table.entry_get(
			target,
			[table.make_key(
				[gc.KeyTuple('dsap',                             dsap,           dsap_mask),
				 gc.KeyTuple('lkp.ip_len',                       l3_len_bitmask, l3_len_bitmask_mask),
				 gc.KeyTuple('lkp.ip_proto',                     l3_proto,       l3_proto_mask),
				 gc.KeyTuple('lkp.ip_src_addr[31:0]',            gc.ipv4_to_bytes('0.0.0.0'), 0),
				 gc.KeyTuple('lkp.ip_dst_addr[31:0]',            gc.ipv4_to_bytes('0.0.0.0'), 0),
				 gc.KeyTuple('lkp.l4_src_port',                  l4_src,         l4_src_mask),
				 gc.KeyTuple('lkp.l4_dst_port',                  l4_dst,         l4_dst_mask),
				 gc.KeyTuple('lkp.tunnel_type',                  tun_type,       tun_type_mask)],
			)],
			{"from_hw": True},
			table.make_data(
				[gc.DataTuple("$COUNTER_SPEC_BYTES"),
				 gc.DataTuple("$COUNTER_SPEC_PKTS")],
				'SwitchEgress.npb_egr_top.npb_egr_sf_proxy_top.acl.egress_ipv4_acl.hit',
				get=True
			)
		)

		data_dict = next(resp)[0].to_dict()
		recv_pkts = data_dict["$COUNTER_SPEC_PKTS"]
		recv_bytes = data_dict["$COUNTER_SPEC_BYTES"]

		print "Dumping npb_npb_sf2_policy_l34_v4 counters: pkts", recv_pkts, "bytes", recv_bytes 

		# delete entry
		table.entry_del(
			target,
			[table.make_key(
				[gc.KeyTuple('dsap',                             dsap,           dsap_mask),
				 gc.KeyTuple('lkp.ip_len',                       l3_len_bitmask, l3_len_bitmask_mask),
				 gc.KeyTuple('lkp.ip_proto',                     l3_proto,       l3_proto_mask),
				 gc.KeyTuple('lkp.ip_src_addr[31:0]',            gc.ipv4_to_bytes('0.0.0.0'), 0),
				 gc.KeyTuple('lkp.ip_dst_addr[31:0]',            gc.ipv4_to_bytes('0.0.0.0'), 0),
				 gc.KeyTuple('lkp.l4_src_port',                  l4_src,         l4_src_mask),
				 gc.KeyTuple('lkp.l4_dst_port',                  l4_dst,         l4_dst_mask),
				 gc.KeyTuple('lkp.tunnel_type',                  tun_type,       tun_type_mask)],
			)],
		)

########################################

# ing sf #2: policy l3 v6

def npb_npb_sf2_policy_l34_v6_add(self, target,
		dsap            = 0, dsap_mask           = 0x03ff,
		l3_len_bitmask  = 0, l3_len_bitmask_mask = 0,
		l3_proto        = 0, l3_proto_mask       = 0,
		l4_src          = 0, l4_src_mask         = 0,
		l4_dst          = 0, l4_dst_mask         = 0,
		tun_type        = 0, tun_type_mask       = 0,
		# results
		drop            = 0,
		terminate_outer = 0,
		terminate_inner = 0,
		terminate       = 0,
		trunc_enable    = 0, trunc               = 0,
		strip_tag_e     = 0,
		strip_tag_vn    = 0,
		strip_tag_vlan  = 0,
		add_tag_vlan_bd = 0,
		dedup_en        = 0,
		copy_to_cpu     = 0,
		redirect_to_cpu = 0,
		cpu_reason_code = 0
		):

		table = self.bfrt_info.table_get('SwitchEgress.npb_egr_top.npb_egr_sf_proxy_top.acl.egress_ipv6_acl.acl')
		table.entry_add(
			target,
			[table.make_key(
				[gc.KeyTuple('dsap',                             dsap,           dsap_mask),
				 gc.KeyTuple('lkp.ip_len',                       l3_len_bitmask, l3_len_bitmask_mask),
				 gc.KeyTuple('lkp.ip_proto',                     l3_proto,       l3_proto_mask),
				 gc.KeyTuple('lkp.ip_src_addr',                  0,              0),
				 gc.KeyTuple('lkp.ip_dst_addr',                  0,              0),
				 gc.KeyTuple('lkp.l4_src_port',                  l4_src,         l4_src_mask),
				 gc.KeyTuple('lkp.l4_dst_port',                  l4_dst,         l4_dst_mask),
				 gc.KeyTuple('lkp.tunnel_type',                  tun_type,       tun_type_mask)],
			)],
			[table.make_data(
				[gc.DataTuple('drop',                            drop),
				 gc.DataTuple('terminate_outer',                 terminate_outer),
				 gc.DataTuple('terminate_inner',                 terminate_inner),
				 gc.DataTuple('terminate',                       terminate),
				 gc.DataTuple('truncate_enable',                 trunc_enable),
				 gc.DataTuple('truncate_len',                    trunc),
				 gc.DataTuple('strip_tag_e',                     strip_tag_e),
				 gc.DataTuple('strip_tag_vn',                    strip_tag_vn),
				 gc.DataTuple('strip_tag_vlan',                  strip_tag_vlan),
				 gc.DataTuple('add_tag_vlan_bd',                 add_tag_vlan_bd),
				 gc.DataTuple('dedup_en',                        dedup_en),
				 gc.DataTuple('copy_to_cpu',                     copy_to_cpu),
				 gc.DataTuple('redirect_to_cpu',                 redirect_to_cpu),
				 gc.DataTuple('cpu_reason_code',                 cpu_reason_code)],
				'SwitchEgress.npb_egr_top.npb_egr_sf_proxy_top.acl.egress_ipv6_acl.hit'
			)]
		)

def npb_npb_sf2_policy_l34_v6_del(self, target,
		dsap            = 0, dsap_mask           = 0x03ff,
		l3_len_bitmask  = 0, l3_len_bitmask_mask = 0,
		l3_proto        = 0, l3_proto_mask       = 0,
		l4_src          = 0, l4_src_mask         = 0,
		l4_dst          = 0, l4_dst_mask         = 0,
		tun_type        = 0, tun_type_mask       = 0
		):

		table = self.bfrt_info.table_get('SwitchEgress.npb_egr_top.npb_egr_sf_proxy_top.acl.egress_ipv6_acl.acl')

		# read counter
		resp = table.entry_get(
			target,
			[table.make_key(
				[gc.KeyTuple('dsap',                             dsap,           dsap_mask),
				 gc.KeyTuple('lkp.ip_len',                       l3_len_bitmask, l3_len_bitmask_mask),
				 gc.KeyTuple('lkp.ip_proto',                     l3_proto,       l3_proto_mask),
				 gc.KeyTuple('lkp.ip_src_addr',                  0,              0),
				 gc.KeyTuple('lkp.ip_dst_addr',                  0,              0),
				 gc.KeyTuple('lkp.l4_src_port',                  l4_src,         l4_src_mask),
				 gc.KeyTuple('lkp.l4_dst_port',                  l4_dst,         l4_dst_mask),
				 gc.KeyTuple('lkp.tunnel_type',                  tun_type,       tun_type_mask)],
			)],
			{"from_hw": True},
			table.make_data(
				[gc.DataTuple("$COUNTER_SPEC_BYTES"),
				 gc.DataTuple("$COUNTER_SPEC_PKTS")],
				'SwitchEgress.npb_egr_top.npb_egr_sf_proxy_top.acl.egress_ipv6_acl.hit',
				get=True
			)
		)

		data_dict = next(resp)[0].to_dict()
		recv_pkts = data_dict["$COUNTER_SPEC_PKTS"]
		recv_bytes = data_dict["$COUNTER_SPEC_BYTES"]

		print "Dumping npb_npb_sf2_policy_l34_v6 counters: pkts", recv_pkts, "bytes", recv_bytes 

		# delete entry
		table.entry_del(
			target,
			[table.make_key(
				[gc.KeyTuple('dsap',                             dsap,           dsap_mask),
				 gc.KeyTuple('lkp.ip_len',                       l3_len_bitmask, l3_len_bitmask_mask),
				 gc.KeyTuple('lkp.ip_proto',                     l3_proto,       l3_proto_mask),
				 gc.KeyTuple('lkp.ip_src_addr',                  0,              0),
				 gc.KeyTuple('lkp.ip_dst_addr',                  0,              0),
				 gc.KeyTuple('lkp.l4_src_port',                  l4_src,         l4_src_mask),
				 gc.KeyTuple('lkp.l4_dst_port',                  l4_dst,         l4_dst_mask),
				 gc.KeyTuple('lkp.tunnel_type',                  tun_type,       tun_type_mask)],
			)],
		)

########################################

def npb_npb_sf2_policy_hdr_edit_add(self, target,
		bd  = 0,
		pcp = 0,
		vid = 0
		):

		table = self.bfrt_info.table_get('SwitchEgress.npb_egr_top.npb_egr_sf_proxy_top.npb_egr_sf_proxy_hdr_edit.bd_to_vlan_mapping')
		table.entry_add(
			target,
			[table.make_key(
				[gc.KeyTuple('bd',                               bd)],
			)],
			[table.make_data(
				[gc.DataTuple('pcp',                             pcp),
				 gc.DataTuple('vid',                             vid)],
				'SwitchEgress.npb_egr_top.npb_egr_sf_proxy_top.npb_egr_sf_proxy_hdr_edit.set_vlan_tagged'
			)]
		)

def npb_npb_sf2_policy_hdr_edit_del(self, target,
		bd  = 0
		):

		table = self.bfrt_info.table_get('SwitchEgress.npb_egr_top.npb_egr_sf_proxy_top.npb_egr_sf_proxy_hdr_edit.bd_to_vlan_mapping')
		table.entry_del(
			target,
			[table.make_key(
				[gc.KeyTuple('bd',                               bd)],
			)],
		)

########################################

# currently unused (we are now always doing encaps, never rewrites)

def npb_rewrite_bd_mapping_add(self, target, bd, smac_ptr):
		self.insert_table_entry(
			target,
			'SwitchEgress.rewrite.egress_bd.bd_mapping',
			[self.KeyField('bd',                               self.to_bytes(bd, 2))],
			'SwitchEgress.rewrite.egress_bd.set_bd_properties',
			[self.DataField('smac_index',                      self.to_bytes(smac_ptr, 2))])

def npb_rewrite_bd_mapping_del(self, target, bd):
		self.delete_table_entry(
			target,
			'SwitchEgress.rewrite.egress_bd.bd_mapping',
			[self.KeyField('bd',                               self.to_bytes(bd, 2))])

########################################

# currently unused (we are now always doing encaps, never rewrites)

def npb_rewrite_smac_rewrite_add(self, target, smac_ptr, smac):
		self.insert_table_entry(
			target,
			'SwitchEgress.rewrite.smac_rewrite',
			[self.KeyField('smac_index',                       self.to_bytes(smac_ptr, 2))],
			'SwitchEgress.rewrite.rewrite_smac',
			[self.DataField('smac',                            self.mac_to_bytes(smac))])

def npb_rewrite_smac_rewrite_del(self, target, smac_ptr):
		self.delete_table_entry(
			target,
			'SwitchEgress.rewrite.smac_rewrite',
			[self.KeyField('smac_index',                       self.to_bytes(smac_ptr, 2))])

########################################

# this is a constant table (barefoot should really hard-code this, not wure why they dont)

# so here we just program up all the tunnel types -- add more as needed

def npb_tunnel_encap_add(self, target):
	try:

		table = self.bfrt_info.table_get('SwitchEgress.tunnel_encap.tunnel')
		table.entry_add(
			target,
			[table.make_key(
				[gc.KeyTuple('tunnel_.type',                     EgressTunnelType.NSH.value)],
			)],
			[table.make_data(
				[],
				'SwitchEgress.tunnel_encap.rewrite_mac_in_mac'
			)]
		)

		table = self.bfrt_info.table_get('SwitchEgress.tunnel_encap.tunnel')
		table.entry_add(
			target,
			[table.make_key(
				[gc.KeyTuple('tunnel_.type',                     EgressTunnelType.IPV4_GRE.value)],
			)],
			[table.make_data(
				[],
				'SwitchEgress.tunnel_encap.rewrite_ipv4_gre'
			)]
		)

		table = self.bfrt_info.table_get('SwitchEgress.tunnel_encap.tunnel')
		table.entry_add(
			target,
			[table.make_key(
				[gc.KeyTuple('tunnel_.type',                     EgressTunnelType.IPV6_GRE.value)],
			)],
			[table.make_data(
				[],
				'SwitchEgress.tunnel_encap.rewrite_ipv6_gre'
			)]
		)

		table = self.bfrt_info.table_get('SwitchEgress.tunnel_encap.tunnel')
		table.entry_add(
			target,
			[table.make_key(
				[gc.KeyTuple('tunnel_.type',                     EgressTunnelType.IPV4_ERSPAN.value)],
			)],
			[table.make_data(
				[],
				'SwitchEgress.tunnel_encap.rewrite_ipv4_erspan'
			)]
		)

	except:
		print("A table operation failed. This is typically due to adding or removing a duplicate, and can be ignored.")

def npb_tunnel_encap_del(self, target):
	try:

		table = self.bfrt_info.table_get('SwitchEgress.tunnel_encap.tunnel')
		table.entry_del(
			target,
			[table.make_key(
				[gc.KeyTuple('tunnel_.type',                     EgressTunnelType.NSH.value)],
			)]
		)

		table = self.bfrt_info.table_get('SwitchEgress.tunnel_encap.tunnel')
		table.entry_del(
			target,
			[table.make_key(
				[gc.KeyTuple('tunnel_.type',                     EgressTunnelType.IPV4_GRE.value)],
			)]
		)

		table = self.bfrt_info.table_get('SwitchEgress.tunnel_encap.tunnel')
		table.entry_del(
			target,
			[table.make_key(
				[gc.KeyTuple('tunnel_.type',                     EgressTunnelType.IPV6_GRE.value)],
			)]
		)

		table = self.bfrt_info.table_get('SwitchEgress.tunnel_encap.tunnel')
		table.entry_del(
			target,
			[table.make_key(
				[gc.KeyTuple('tunnel_.type',                     EgressTunnelType.IPV4_ERSPAN.value)],
			)]
		)

	except:
		print("A table operation failed. This is typically due to adding or removing a duplicate, and can be ignored.")

########################################

def npb_tunnel_encap_nexthop_rewrite_add(self, target, outer_nexthop_ptr, bd, dmac):
	try:

		table = self.bfrt_info.table_get('SwitchEgress.tunnel_rewrite.nexthop_rewrite')
		table.entry_add(
			target,
			[table.make_key(
				[gc.KeyTuple('eg_md.outer_nexthop',              outer_nexthop_ptr)],
			)],
			[table.make_data(
				[gc.DataTuple('bd',                              bd),
				 gc.DataTuple('dmac',                            gc.mac_to_bytes(dmac))],
				'SwitchEgress.tunnel_rewrite.rewrite_tunnel'
			)]
		)

	except:
		print("A table operation failed. This is typically due to adding or removing a duplicate, and can be ignored.")

def npb_tunnel_encap_nexthop_rewrite_del(self, target, outer_nexthop_ptr):
	try:

		table = self.bfrt_info.table_get('SwitchEgress.tunnel_rewrite.nexthop_rewrite')
		table.entry_del(
			target,
			[table.make_key(
				[gc.KeyTuple('eg_md.outer_nexthop',              outer_nexthop_ptr)],
			)]
		)

	except:
		print("A table operation failed. This is typically due to adding or removing a duplicate, and can be ignored.")

########################################

def npb_tunnel_encap_bd_mapping_add(self, target, bd, smac_ptr):
	try:

		table = self.bfrt_info.table_get('SwitchEgress.tunnel_rewrite.egress_bd.bd_mapping')
		table.entry_add(
			target,
			[table.make_key(
				[gc.KeyTuple('bd',                               bd)],
			)],
			[table.make_data(
				[gc.DataTuple('smac_index',                      smac_ptr)],
				'SwitchEgress.tunnel_rewrite.egress_bd.set_bd_properties'
			)]
		)

	except:
		print("A table operation failed. This is typically due to adding or removing a duplicate, and can be ignored.")

def npb_tunnel_encap_bd_mapping_del(self, target, bd):
	try:

		table = self.bfrt_info.table_get('SwitchEgress.tunnel_rewrite.egress_bd.bd_mapping')
		table.entry_del(
			target,
			[table.make_key(
				[gc.KeyTuple('bd',                               bd)],
			)]
		)

	except:
		print("A table operation failed. This is typically due to adding or removing a duplicate, and can be ignored.")

########################################

def npb_tunnel_encap_sip_rewrite_v4_add(self, target, bd, sip):

		table = self.bfrt_info.table_get('SwitchEgress.tunnel_rewrite.src_addr_rewrite')
		table.entry_add(
			target,
			[table.make_key(
				[gc.KeyTuple('eg_md.bd',                         bd)],
			)],
			[table.make_data(
				[gc.DataTuple('src_addr',                        gc.ipv4_to_bytes(sip))],
				'SwitchEgress.tunnel_rewrite.rewrite_ipv4_src'
			)]
		)

def npb_tunnel_encap_sip_rewrite_v4_del(self, target, bd):

		table = self.bfrt_info.table_get('SwitchEgress.tunnel_rewrite.src_addr_rewrite')
		table.entry_del(
			target,
			[table.make_key(
				[gc.KeyTuple('eg_md.bd',                         bd)],
			)]
		)

########################################

def npb_tunnel_encap_sip_rewrite_v6_add(self, target, bd, sip):

		table = self.bfrt_info.table_get('SwitchEgress.tunnel_rewrite.src_addr_rewrite')
		table.entry_add(
			target,
			[table.make_key(
				[gc.KeyTuple('eg_md.bd',                         bd)],
			)],
			[table.make_data(
				[gc.DataTuple('src_addr',                        gc.ipv6_to_bytes(sip))],
				'SwitchEgress.tunnel_rewrite.rewrite_ipv6_src'
			)]
		)

def npb_tunnel_encap_sip_rewrite_v6_del(self, target, bd):

		table = self.bfrt_info.table_get('SwitchEgress.tunnel_rewrite.src_addr_rewrite')
		table.entry_del(
			target,
			[table.make_key(
				[gc.KeyTuple('eg_md.bd',                         bd)],
			)]
		)

########################################

def npb_tunnel_encap_dip_rewrite_v4_add(self, target, tunnel_ptr, dip):

		table = self.bfrt_info.table_get('SwitchEgress.tunnel_rewrite.ipv4_dst_addr_rewrite')
		table.entry_add(
			target,
			[table.make_key(
				[gc.KeyTuple('tunnel.index',                     tunnel_ptr)],
			)],
			[table.make_data(
				[gc.DataTuple('dst_addr',                        gc.ipv4_to_bytes(dip))],
				'SwitchEgress.tunnel_rewrite.rewrite_ipv4_dst'
			)]
		)

def npb_tunnel_encap_dip_rewrite_v4_del(self, target, tunnel_ptr):

		table = self.bfrt_info.table_get('SwitchEgress.tunnel_rewrite.ipv4_dst_addr_rewrite')
		table.entry_del(
			target,
			[table.make_key(
				[gc.KeyTuple('tunnel.index',                     tunnel_ptr)],
			)]
		)

########################################

def npb_tunnel_encap_dip_rewrite_v6_add(self, target, tunnel_ptr, dip):

		table = self.bfrt_info.table_get('SwitchEgress.tunnel_rewrite.ipv6_dst_addr_rewrite')
		table.entry_add(
			target,
			[table.make_key(
				[gc.KeyTuple('tunnel.index',                     tunnel_ptr)],
			)],
			[table.make_data(
				[gc.DataTuple('dst_addr',                        gc.ipv6_to_bytes(dip))],
				'SwitchEgress.tunnel_rewrite.rewrite_ipv6_dst'
			)]
		)

def npb_tunnel_encap_dip_rewrite_v6_del(self, target, tunnel_ptr):

		table = self.bfrt_info.table_get('SwitchEgress.tunnel_rewrite.ipv6_dst_addr_rewrite')
		table.entry_del(
			target,
			[table.make_key(
				[gc.KeyTuple('tunnel.index',                     tunnel_ptr)],
			)]
		)

########################################

def npb_tunnel_encap_smac_rewrite_add(self, target, smac_ptr, smac):
	try:

		table = self.bfrt_info.table_get('SwitchEgress.tunnel_rewrite.smac_rewrite')
		table.entry_add(
			target,
			[table.make_key(
				[gc.KeyTuple('smac_index',                       smac_ptr)],
			)],
			[table.make_data(
				[gc.DataTuple('smac',                            gc.mac_to_bytes(smac))],
				'SwitchEgress.tunnel_rewrite.rewrite_smac'
			)]
		)

	except:
		print("A table operation failed. This is typically due to adding or removing a duplicate, and can be ignored.")

def npb_tunnel_encap_smac_rewrite_del(self, target, smac_ptr):
	try:

		table = self.bfrt_info.table_get('SwitchEgress.tunnel_rewrite.smac_rewrite')
		table.entry_del(
			target,
			[table.make_key(
				[gc.KeyTuple('smac_index',                       smac_ptr)],
			)]
		)

	except:
		print("A table operation failed. This is typically due to adding or removing a duplicate, and can be ignored.")

########################################

def npb_port_bd_to_vlan_add(self, target, port_lag_index, bd, vid, pcp):

		table = self.bfrt_info.table_get('SwitchEgress.vlan_xlate.port_bd_to_vlan_mapping')
		table.entry_add(
			target,
			[table.make_key(
				[gc.KeyTuple('port_lag_index',                   por_lag_index),
				 gc.KeyTuple('bd',                               bd)],
			)],
			[table.make_data(
				[gc.DataTuple('vid',                             vid),
				 gc.DataTuple('pcp',                             pcp)],
				'SwitchEgress.vlan_xlate.set_vlan_tagged'
			)]
		)

def npb_port_bd_to_vlan_del(self, target, port_lag_index, bd):

		table = self.bfrt_info.table_get('SwitchEgress.vlan_xlate.port_bd_to_vlan_mapping')
		table.entry_del(
			target,
			[table.make_key(
				[gc.KeyTuple('bd',                               bd)],
			)],
		)

########################################

def npb_bd_to_vlan_add(self, target, bd, vid, pcp):

		table = self.bfrt_info.table_get('SwitchEgress.vlan_xlate.bd_to_vlan_mapping')
		table.entry_add(
			target,
			[table.make_key(
				[gc.KeyTuple('bd',                               bd)],
			)],
			[table.make_data(
				[gc.DataTuple('vid',                             vid),
				 gc.DataTuple('pcp',                             pcp)],
				'SwitchEgress.vlan_xlate.set_vlan_tagged'
			)]
		)

def npb_bd_to_vlan_del(self, target, bd):

		table = self.bfrt_info.table_get('SwitchEgress.vlan_xlate.bd_to_vlan_mapping')
		table.entry_del(
			target,
			[table.make_key(
				[gc.KeyTuple('bd',                               bd)],
			)],
		)

#######################################
# MIDDLE LEVEL FUNCTIONS
#######################################

def npb_nexthop_tunnel_mac_add(self, target,
	# ingress nexthop
	nexthop_ptr, ig_bd_ptr, port_lag_ptr,
	tunnel_ptr, tun_type, outer_nexthop_ptr,
	# egress encap
	eg_bd_ptr, dmac,
	smac_ptr,
	smac
):
	# ingress nexthop
	npb_nexthop_tunnel_encap_add                (self, target, nexthop_ptr, ig_bd_ptr, tunnel_ptr, tun_type)
	npb_tunnel_encap_nexthop_add                (self, target, tunnel_ptr, port_lag_ptr, outer_nexthop_ptr)
	# egress encap
	npb_tunnel_encap_nexthop_rewrite_add        (self, target, outer_nexthop_ptr, eg_bd_ptr, dmac)
	npb_tunnel_encap_bd_mapping_add             (self, target, eg_bd_ptr, smac_ptr)
	npb_tunnel_encap_smac_rewrite_add           (self, target, smac_ptr, smac)

def npb_nexthop_tunnel_mac_del(self, target,
	# ingress nexthop
	nexthop_ptr,
	tunnel_ptr, outer_nexthop_ptr,
	# egress encap
	eg_bd_ptr,
	smac_ptr
):
	# ingress nexthop
	npb_nexthop_del                             (self, target, nexthop_ptr)
	npb_tunnel_encap_nexthop_del                (self, target, tunnel_ptr)
	# egress encap
	npb_tunnel_encap_nexthop_rewrite_del        (self, target, outer_nexthop_ptr)
	npb_tunnel_encap_bd_mapping_del             (self, target, eg_bd_ptr)
	npb_tunnel_encap_smac_rewrite_del           (self, target, smac_ptr)

#######################################

def npb_npb_sfp_sel_add(self, target,
	# ingress
	vpn, flowclass,
	sfc, sfc_group_ptr, sfc_member_ptr, spi, si, sf_bitmask
	# egress
):
	# ---------------------------------

	# we have to modify 

	spi_new       = []
	si_new        = []
	si_predec_new = []

	for i in range(len(spi)):
		# note: we can hard-subtract 1 from the si here, because we know the packet had to go through sf#0 to get here....
		spi_new.append      (spi[i])
		si_new.append       (si[i]-1)
		si_predec_new.append(si[i]-(popcount(sf_bitmask[i]&6))-1)  # only 'and' with sf's that are after the sff

	# ---------------------------------

	npb_npb_sf0_policy_sfp_sel_hash_add         (self, target, vpn, flowclass)
	if(len(spi) == 1):
		npb_npb_sf0_policy_sfp_sel_single_add       (self, target, sfc,                sfc_member_ptr, spi_new[0], si_new[0], si_predec_new[0])
	else:
		npb_npb_sf0_policy_sfp_sel_multi_add        (self, target, sfc, sfc_group_ptr, sfc_member_ptr, spi_new,    si_new,    si_predec_new)

def npb_npb_sfp_sel_del(self, target,
	# ingress
	vpn,
	sfc, sfc_group_ptr, sfc_member_ptr, spi_num_entries
	# egress
):
	npb_npb_sf0_policy_sfp_sel_hash_del         (self, target, vpn)
	if(spi_num_entries == 1):
		npb_npb_sf0_policy_sfp_sel_single_del       (self, target, sfc,                sfc_member_ptr)
	else:
		npb_npb_sf0_policy_sfp_sel_multi_del        (self, target, sfc, sfc_group_ptr, sfc_member_ptr, spi_num_entries)

#######################################
# HIGH LEVEL FUNCTIONS
#######################################

# note: mgid, dsap inputs are only used when corresponding sf is enabled

def npb_nsh_chain_start_end_add(self, target,
	# ingress
	ig_port, ig_port_lag_ptr, bridging_enable, sap, vpn, spi, si, sf_bitmask, rmac, nexthop_ptr, ig_bd,  eg_port_lag_ptr, eg_port_lag_group_ptr, eg_port_lag_member_ptr, eg_port, mgid, dsap
	# egress
):
	cpu_port_add              (self, target)
	npb_ing_port_add          (self, target, ig_port, ig_port_lag_ptr, bridging_enable, sap, vpn, spi, si, si-(popcount(sf_bitmask&6))) # only 'and' with sf's that are after the sff
	npb_tunnel_rmac_add       (self, target, rmac);
#	npb_npb_sfc_sf_sel_add    (self, target, spi, si, si-(popcount(sf_bitmask&6))) # only 'and' with sf's that are after the sff
	if(sf_bitmask&1):
		npb_npb_sf0_action_sel_add(self, target, spi, si-(popcount(sf_bitmask&0)), 0)
	npb_npb_sff_fib_add       (self, target, spi, si-(popcount(sf_bitmask)), nexthop_ptr, 1) # 1 = end of chain
	if(sf_bitmask&2):
		npb_npb_sf1_action_sel_add(self, target, spi, si-(popcount(sf_bitmask&1)), 0, mgid)
	npb_nexthop_add           (self, target, nexthop_ptr, ig_bd, eg_port_lag_ptr)
	if(len(eg_port) == 1):
		npb_lag_single_add        (self, target, eg_port_lag_ptr,                        eg_port_lag_member_ptr, eg_port[0])
	else:
		npb_lag_multi_add         (self, target, eg_port_lag_ptr, eg_port_lag_group_ptr, eg_port_lag_member_ptr, eg_port)

	npb_egr_port_add          (self, target, eg_port, eg_port_lag_ptr)
	if(sf_bitmask&4):
		npb_npb_sf2_action_sel_add(self, target, spi, si-(popcount(sf_bitmask&3)), 0, dsap)

def npb_nsh_chain_start_end_del(self, target,
	# ingress
	ig_port, ig_port_lag_ptr, spi, si, sf_bitmask, rmac, nexthop_ptr, eg_port_lag_ptr, eg_port_lag_group_ptr, eg_port_lag_member_ptr, eg_port_num_entries, eg_port
	# egress
):
	cpu_port_del              (self, target)
	npb_ing_port_del          (self, target, ig_port, ig_port_lag_ptr)
	npb_tunnel_rmac_del       (self, target, rmac);
#	npb_npb_sfc_sf_sel_del    (self, target, spi, si) # adding this allows acting as a middle too
	if(sf_bitmask&1):
		npb_npb_sf0_action_sel_del(self, target, spi, si-(popcount(sf_bitmask&0)))
	npb_npb_sff_fib_del       (self, target, spi, si-(popcount(sf_bitmask)))
	if(sf_bitmask&2):
		npb_npb_sf1_action_sel_del(self, target, spi, si-(popcount(sf_bitmask&1)))
	npb_nexthop_del           (self, target, nexthop_ptr)
	if(eg_port_num_entries == 1):
		npb_lag_single_del        (self, target, eg_port_lag_ptr,                        eg_port_lag_member_ptr)
	else:
		npb_lag_multi_del         (self, target, eg_port_lag_ptr, eg_port_lag_group_ptr, eg_port_lag_member_ptr, eg_port_num_entries)

	npb_egr_port_del          (self, target, eg_port)
	if(sf_bitmask&4):
		npb_npb_sf2_action_sel_del(self, target, spi, si-(popcount(sf_bitmask&3)))

#######################################

# note: mgid, dsap inputs are only used when corresponding sf is enabled

def npb_nsh_chain_start_end_with_tunnel_add(self, target,
	# ingress
	ig_port, ig_port_lag_ptr, bridging_enable, sap, vpn, spi, si, sf_bitmask, rmac, nexthop_ptr, ig_bd, eg_port_lag_ptr, eg_port_lag_group_ptr, eg_port_lag_member_ptr, eg_port, mgid, dsap,
	# tunnel
	tunnel_ptr, tun_type, outer_nexthop_ptr, eg_bd_ptr, dmac, smac_ptr, smac
	# egress
):
	cpu_port_add              (self, target)
	npb_ing_port_add          (self, target, ig_port, ig_port_lag_ptr, bridging_enable, sap, vpn, spi, si, si-(popcount(sf_bitmask&6))) # only 'and' with sf's that are after the sff
	npb_tunnel_rmac_add       (self, target, rmac);
#	npb_npb_sfc_sf_sel_add    (self, target, spi, si, si-(popcount(sf_bitmask&6))) # only 'and' with sf's that are after the sff
	if(sf_bitmask&1):
		npb_npb_sf0_action_sel_add(self, target, spi, si-(popcount(sf_bitmask&0)), 0)
	npb_npb_sff_fib_add       (self, target, spi, si-(popcount(sf_bitmask)), nexthop_ptr, 1) # 1 = end of chain
	if(sf_bitmask&2):
		npb_npb_sf1_action_sel_add(self, target, spi, si-(popcount(sf_bitmask&1)), 0, mgid)
	npb_nexthop_tunnel_mac_add(self, target, nexthop_ptr, ig_bd, eg_port_lag_ptr, tunnel_ptr, tun_type, outer_nexthop_ptr, eg_bd_ptr, dmac, smac_ptr, smac)
	if(len(eg_port) == 1):
		npb_lag_single_add        (self, target, eg_port_lag_ptr,                        eg_port_lag_member_ptr, eg_port[0])
	else:
		npb_lag_multi_add         (self, target, eg_port_lag_ptr, eg_port_lag_group_ptr, eg_port_lag_member_ptr, eg_port)

	npb_egr_port_add          (self, target, eg_port, eg_port_lag_ptr)
	if(sf_bitmask&4):
		npb_npb_sf2_action_sel_add(self, target, spi, si-(popcount(sf_bitmask&3)), 0, dsap)
	npb_tunnel_encap_add      (self, target) # this is a constant table, independent of the test (barefoot should really set automatically!)

def npb_nsh_chain_start_end_with_tunnel_del(self, target,
	# ingress
	ig_port, ig_port_lag_ptr, spi, si, sf_bitmask, rmac, nexthop_ptr, eg_port_lag_ptr, eg_port_lag_group_ptr, eg_port_lag_member_ptr, eg_port_num_entries, eg_port,
	# tunnel
	tunnel_ptr, outer_nexthop_ptr, eg_bd_ptr, smac_ptr
	# egress
):
	cpu_port_del              (self, target)
	npb_ing_port_del          (self, target, ig_port, ig_port_lag_ptr)
	npb_tunnel_rmac_del       (self, target, rmac);
#	npb_npb_sfc_sf_sel_del    (self, target, spi, si) # adding this allows acting as a middle too
	if(sf_bitmask&1):
		npb_npb_sf0_action_sel_del(self, target, spi, si-(popcount(sf_bitmask&0)))
	npb_npb_sff_fib_del       (self, target, spi, si-(popcount(sf_bitmask)))
	if(sf_bitmask&2):
		npb_npb_sf1_action_sel_del(self, target, spi, si-(popcount(sf_bitmask&1)))
	npb_nexthop_tunnel_mac_del(self, target, nexthop_ptr, tunnel_ptr, outer_nexthop_ptr, eg_bd_ptr, smac_ptr)
	if(eg_port_num_entries == 1):
		npb_lag_single_del        (self, target, eg_port_lag_ptr,                        eg_port_lag_member_ptr)
	else:
		npb_lag_multi_del         (self, target, eg_port_lag_ptr, eg_port_lag_group_ptr, eg_port_lag_member_ptr, eg_port_num_entries)

	npb_egr_port_del          (self, target, eg_port)
	if(sf_bitmask&4):
		npb_npb_sf2_action_sel_del(self, target, spi, si-(popcount(sf_bitmask&3)))
	npb_tunnel_encap_del      (self, target) # this is a constant table, independent of the test (barefoot should really set automatically!)

#######################################

# note: mgid, dsap inputs are only used when corresponding sf is enabled

def npb_nsh_chain_start_add(self, target,
	# ingress
	ig_port, ig_port_lag_ptr, bridging_enable, sap, vpn, spi, si, sf_bitmask, rmac, nexthop_ptr, ig_bd, eg_port_lag_ptr, eg_port_lag_group_ptr, eg_port_lag_member_ptr, eg_port, mgid, dsap,
	# tunnel
	tunnel_ptr, tun_type, outer_nexthop_ptr, eg_bd_ptr, dmac, smac_ptr, smac
	# egress
):
	cpu_port_add              (self, target)
	npb_ing_port_add          (self, target, ig_port, ig_port_lag_ptr, bridging_enable, sap, vpn, spi, si, si-(popcount(sf_bitmask&6))) # only 'and' with sf's that are after the sff
	npb_tunnel_rmac_add       (self, target, rmac);
#	npb_npb_sfc_sf_sel_add    (self, target, spi, si, si-(popcount(sf_bitmask&6))) # only 'and' with sf's that are after the sff
	if(sf_bitmask&1):
		npb_npb_sf0_action_sel_add(self, target, spi, si-(popcount(sf_bitmask&0)), 0)
	npb_npb_sff_fib_add       (self, target, spi, si-(popcount(sf_bitmask)), nexthop_ptr, 0) # 0 = not end of chain
	if(sf_bitmask&2):
		npb_npb_sf1_action_sel_add(self, target, spi, si-(popcount(sf_bitmask&1)), 0, mgid)
	npb_nexthop_tunnel_mac_add(self, target, nexthop_ptr, ig_bd, eg_port_lag_ptr, tunnel_ptr, tun_type, outer_nexthop_ptr, eg_bd_ptr, dmac, smac_ptr, smac)
	if(len(eg_port) == 1):
		npb_lag_single_add        (self, target, eg_port_lag_ptr,                        eg_port_lag_member_ptr, eg_port[0])
	else:
		npb_lag_multi_add         (self, target, eg_port_lag_ptr, eg_port_lag_group_ptr, eg_port_lag_member_ptr, eg_port)

	npb_egr_port_add          (self, target, eg_port, eg_port_lag_ptr)
	if(sf_bitmask&4):
		npb_npb_sf2_action_sel_add(self, target, spi, si-(popcount(sf_bitmask&3)), 0, dsap)
	npb_tunnel_encap_add      (self, target) # this is a constant table, independent of the test (barefoot should really set automatically!)

def npb_nsh_chain_start_del(self, target,
	# ingress
	ig_port, ig_port_lag_ptr, spi, si, sf_bitmask, rmac, nexthop_ptr, eg_port_lag_ptr, eg_port_lag_group_ptr, eg_port_lag_member_ptr, eg_port_num_entries, eg_port,
	# tunnel
	tunnel_ptr, outer_nexthop_ptr, eg_bd_ptr, smac_ptr
	# egress
):
	cpu_port_del              (self, target)
	npb_ing_port_del          (self, target, ig_port, ig_port_lag_ptr)
	npb_tunnel_rmac_del       (self, target, rmac);
#	npb_npb_sfc_sf_sel_del    (self, target, spi, si) # adding this allows acting as a middle too
	if(sf_bitmask&1):
		npb_npb_sf0_action_sel_del(self, target, spi, si-(popcount(sf_bitmask&0)))
	npb_npb_sff_fib_del       (self, target, spi, si-(popcount(sf_bitmask)))
	if(sf_bitmask&2):
		npb_npb_sf1_action_sel_del(self, target, spi, si-(popcount(sf_bitmask&1)))
	npb_nexthop_tunnel_mac_del(self, target, nexthop_ptr, tunnel_ptr, outer_nexthop_ptr, eg_bd_ptr, smac_ptr)
	if(eg_port_num_entries == 1):
		npb_lag_single_del        (self, target, eg_port_lag_ptr,                        eg_port_lag_member_ptr)
	else:
		npb_lag_multi_del         (self, target, eg_port_lag_ptr, eg_port_lag_group_ptr, eg_port_lag_member_ptr, eg_port_num_entries)

	npb_egr_port_del          (self, target, eg_port)
	if(sf_bitmask&4):
		npb_npb_sf2_action_sel_del(self, target, spi, si-(popcount(sf_bitmask&3)))
	npb_tunnel_encap_del      (self, target) # this is a constant table, independent of the test (barefoot should really set automatically!)

#######################################

# note: mgid, dsap inputs are only used when corresponding sf is enabled

def npb_nsh_chain_middle_add(self, target,
	# ingress
	ig_port, ig_port_lag_ptr, bridging_enable, spi, si, sf_bitmask, rmac, nexthop_ptr, ig_bd, eg_port_lag_ptr, eg_port_lag_group_ptr, eg_port_lag_member_ptr, eg_port, mgid, dsap,
	# tunnel
	tunnel_ptr, tun_type, outer_nexthop_ptr, eg_bd_ptr, dmac, smac_ptr, smac
	# egress
):
	cpu_port_add              (self, target)
	npb_ing_port_add          (self, target, ig_port, ig_port_lag_ptr, bridging_enable, 0, 0, 0, 0, 0)
	npb_tunnel_rmac_add       (self, target, rmac);
	npb_npb_sfc_sf_sel_add    (self, target, spi, si, si-(popcount(sf_bitmask&6))) # only 'and' with sf's that are after the sff
	if(sf_bitmask&1):
		npb_npb_sf0_action_sel_add(self, target, spi, si-(popcount(sf_bitmask&0)), 0)
	npb_npb_sff_fib_add       (self, target, spi, si-(popcount(sf_bitmask)), nexthop_ptr, 0) # 0 = not end of chain
	if(sf_bitmask&2):
		npb_npb_sf1_action_sel_add(self, target, spi, si-(popcount(sf_bitmask&1)), 0, mgid)
	npb_nexthop_tunnel_mac_add(self, target, nexthop_ptr, ig_bd, eg_port_lag_ptr, tunnel_ptr, tun_type, outer_nexthop_ptr, eg_bd_ptr, dmac, smac_ptr, smac)
	if(len(eg_port) == 1):
		npb_lag_single_add        (self, target, eg_port_lag_ptr,                        eg_port_lag_member_ptr, eg_port[0])
	else:
		npb_lag_multi_add         (self, target, eg_port_lag_ptr, eg_port_lag_group_ptr, eg_port_lag_member_ptr, eg_port)

	npb_egr_port_add          (self, target, eg_port, eg_port_lag_ptr)
	if(sf_bitmask&4):
		npb_npb_sf2_action_sel_add(self, target, spi, si-(popcount(sf_bitmask&3)), 0, dsap)
	npb_tunnel_encap_add      (self, target) # this is a constant table, independent of the test (barefoot should really set automatically!)

def npb_nsh_chain_middle_del(self, target,
	# ingress
	ig_port, ig_port_lag_ptr, spi, si, sf_bitmask, rmac, nexthop_ptr, eg_port_lag_ptr, eg_port_lag_group_ptr, eg_port_lag_member_ptr, eg_port_num_entries, eg_port,
	# tunnel
	tunnel_ptr, outer_nexthop_ptr, eg_bd_ptr, smac_ptr
	# egress
):
	cpu_port_del              (self, target)
	npb_ing_port_del          (self, target, ig_port, ig_port_lag_ptr)
	npb_tunnel_rmac_del       (self, target, rmac);
	npb_npb_sfc_sf_sel_del    (self, target, spi, si)
	if(sf_bitmask&1):
		npb_npb_sf0_action_sel_del(self, target, spi, si-(popcount(sf_bitmask&0)))
	npb_npb_sff_fib_del       (self, target, spi, si-(popcount(sf_bitmask)))
	if(sf_bitmask&2):
		npb_npb_sf1_action_sel_del(self, target, spi, si-(popcount(sf_bitmask&1)))
	npb_nexthop_tunnel_mac_del(self, target, nexthop_ptr, tunnel_ptr, outer_nexthop_ptr, eg_bd_ptr, smac_ptr)
	if(eg_port_num_entries == 1):
		npb_lag_single_del        (self, target, eg_port_lag_ptr,                        eg_port_lag_member_ptr)
	else:
		npb_lag_multi_del         (self, target, eg_port_lag_ptr, eg_port_lag_group_ptr, eg_port_lag_member_ptr, eg_port_num_entries)

	npb_egr_port_del          (self, target, eg_port)
	if(sf_bitmask&4):
		npb_npb_sf2_action_sel_del(self, target, spi, si-(popcount(sf_bitmask&3)))
	npb_tunnel_encap_del      (self, target) # this is a constant table, independent of the test (barefoot should really set automatically!)

#######################################

# note: mgid, dsap inputs are only used when corresponding sf is enabled

def npb_nsh_chain_end_add(self, target,
	# ingress
	ig_port, ig_port_lag_ptr, bridging_enable, spi, si, sf_bitmask, rmac, nexthop_ptr, ig_bd,  eg_port_lag_ptr, eg_port_lag_group_ptr, eg_port_lag_member_ptr, eg_port, mgid, dsap
	# egress
):
	cpu_port_add              (self, target)
	npb_ing_port_add          (self, target, ig_port, ig_port_lag_ptr, bridging_enable, 0, 0, 0, 0, 0)
	npb_tunnel_rmac_add       (self, target, rmac);
	npb_npb_sfc_sf_sel_add    (self, target, spi, si, si-(popcount(sf_bitmask&6))) # only 'and' with sf's that are after the sff
	if(sf_bitmask&1):
		npb_npb_sf0_action_sel_add(self, target, spi, si-(popcount(sf_bitmask&0)), 0)
	npb_npb_sff_fib_add       (self, target, spi, si-(popcount(sf_bitmask)), nexthop_ptr, 1) # 1 = end of chain
	if(sf_bitmask&2):
		npb_npb_sf1_action_sel_add(self, target, spi, si-(popcount(sf_bitmask&1)), 0, mgid)
	npb_nexthop_add           (self, target, nexthop_ptr, ig_bd, eg_port_lag_ptr)
	if(len(eg_port) == 1):
		npb_lag_single_add        (self, target, eg_port_lag_ptr,                        eg_port_lag_member_ptr, eg_port[0])
	else:
		npb_lag_multi_add         (self, target, eg_port_lag_ptr, eg_port_lag_group_ptr, eg_port_lag_member_ptr, eg_port)

	npb_egr_port_add          (self, target, eg_port, eg_port_lag_ptr)
	if(sf_bitmask&4):
		npb_npb_sf2_action_sel_add(self, target, spi, si-(popcount(sf_bitmask&3)), 0, dsap)

def npb_nsh_chain_end_del(self, target,
	# ingress
	ig_port, ig_port_lag_ptr, spi, si, sf_bitmask, rmac, nexthop_ptr, eg_port_lag_ptr, eg_port_lag_group_ptr, eg_port_lag_member_ptr, eg_port_num_entries, eg_port
	# egress
):
	cpu_port_del              (self, target)
	npb_ing_port_del          (self, target, ig_port, ig_port_lag_ptr)
	npb_tunnel_rmac_del       (self, target, rmac);
	npb_npb_sfc_sf_sel_del    (self, target, spi, si)
	if(sf_bitmask&1):
		npb_npb_sf0_action_sel_del(self, target, spi, si-(popcount(sf_bitmask&0)))
	npb_npb_sff_fib_del       (self, target, spi, si-(popcount(sf_bitmask)))
	if(sf_bitmask&2):
		npb_npb_sf1_action_sel_del(self, target, spi, si-(popcount(sf_bitmask&1)))
	npb_nexthop_del           (self, target, nexthop_ptr)
	if(eg_port_num_entries == 1):
		npb_lag_single_del        (self, target, eg_port_lag_ptr,                        eg_port_lag_member_ptr)
	else:
		npb_lag_multi_del         (self, target, eg_port_lag_ptr, eg_port_lag_group_ptr, eg_port_lag_member_ptr, eg_port_num_entries)

	npb_egr_port_del          (self, target, eg_port)
	if(sf_bitmask&4):
		npb_npb_sf2_action_sel_del(self, target, spi, si-(popcount(sf_bitmask&3)))

#######################################

def npb_nsh_bridge_add(self, target,
	#ingress
	ig_port, ig_port_lag_ptr, rmac, bd, bd_member_ptr, dmac, eg_port_lag_ptr, eg_port_lag_group_ptr, eg_port_lag_member_ptr, eg_port
	#egress
):
	cpu_port_add              (self, target)
	npb_ing_port_add          (self, target, ig_port, ig_port_lag_ptr, 1, 0, 0, 0, 0, 0)
	npb_port_vlan_to_bd_add   (self, self.target, ig_port_lag_ptr, 0, 0, 0, 0, bd_member_ptr, bd)
	npb_tunnel_rmac_add       (self, target, rmac);
	npb_tunnel_dmac_add       (self, target, bd, dmac, eg_port_lag_ptr);
	if(len(eg_port) == 1):
		npb_lag_single_add        (self, target, eg_port_lag_ptr,                        eg_port_lag_member_ptr, eg_port[0])
	else:
		npb_lag_multi_add         (self, target, eg_port_lag_ptr, eg_port_lag_group_ptr, eg_port_lag_member_ptr, eg_port)

	npb_egr_port_add          (self, target, eg_port, eg_port_lag_ptr)

def npb_nsh_bridge_cpu_add(self, target,
	#ingress
	ig_port, ig_port_lag_ptr, rmac, bd, bd_member_ptr, dmac, eg_port_lag_ptr, eg_port_lag_group_ptr, eg_port_lag_member_ptr, eg_port
	#egress
):
	cpu_port_add              (self, target)
	npb_ing_port_add          (self, target, ig_port, ig_port_lag_ptr, 1, 0, 0, 0, 0, 0)
	npb_port_vlan_to_bd_add   (self, self.target, ig_port_lag_ptr, 0, 0, 0, 0, bd_member_ptr, bd)
	npb_tunnel_rmac_add       (self, target, rmac);
	npb_tunnel_dmac_add       (self, target, bd, dmac, eg_port_lag_ptr);
	if(len(eg_port) == 1):
		npb_lag_single_add        (self, target, eg_port_lag_ptr,                        eg_port_lag_member_ptr, eg_port[0])
	else:
		npb_lag_multi_add         (self, target, eg_port_lag_ptr, eg_port_lag_group_ptr, eg_port_lag_member_ptr, eg_port)

	npb_egr_port_cpu_add      (self, target, eg_port, eg_port_lag_ptr)

def npb_nsh_bridge_del(self, target,
	#ingress
	ig_port, ig_port_lag_ptr, rmac, bd, bd_member_ptr, dmac, eg_port_lag_ptr, eg_port_lag_group_ptr, eg_port_lag_member_ptr, eg_port_num_entries, eg_port
	#egress
):
	cpu_port_del              (self, target)
	npb_ing_port_del          (self, target, ig_port, ig_port_lag_ptr)
	npb_port_vlan_to_bd_del   (self, self.target, ig_port_lag_ptr, 0, 0, 0, 0, bd_member_ptr)
	npb_tunnel_rmac_del       (self, target, rmac);
	npb_tunnel_dmac_del       (self, target, bd, dmac);
	if(eg_port_num_entries == 1):
		npb_lag_single_del        (self, target, eg_port_lag_ptr,                        eg_port_lag_member_ptr)
	else:
		npb_lag_multi_del         (self, target, eg_port_lag_ptr, eg_port_lag_group_ptr, eg_port_lag_member_ptr, eg_port_num_entries)

	npb_egr_port_del          (self, target, eg_port)
