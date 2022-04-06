import logging
import sys
import os
import random
import re
from pprint import pprint

####### PTF MODULE IMPORTS #######
import ptf
from   ptf.mask import Mask
#from   ptf.testutils import *
import ptf.testutils as testutils
#from   scapy.all     import *
import ptf.packet    as scapy

####### PTF modules for BFRuntime Client Library APIs #######
import grpc
import bfrt_grpc.bfruntime_pb2 as bfruntime_pb2
import bfrt_grpc.client        as gc
from   bfruntime_client_base_tests import BfRuntimeTest

####### PTF modules for Fixed APIs (Thrift) #######
import pd_base_tests
from   ptf.thriftutils import *
from   res_pd_rpc      import * # Common data types
from   mc_pd_rpc       import * # Multicast-specific data types
from   mirror_pd_rpc   import * # Mirror-specific data types

####### Additional imports #######
import pdb # To debug insert pdb.set_trace() anywhere
import json

from test_mau_tb_top import *
from test_mau_tb_shared import *

#######################################
# LOW LEVEL FUNCTIONS
#######################################


def npb_validate_eth_add(self, target, ig_pipe, tag_valid):
	pass;
#		if(PipelineParams.TRANSPORT_ENABLE == True):
#			self.insert_table_entry(
#				target,
#				'SwitchIngress_0.pkt_validation_0.validate_ethernet',
##				[self.KeyField('hdr.ethernet.src_addr',                     self.to_bytes(0, 6), self.to_bytes(0, 6)),
##				 self.KeyField('hdr.ethernet.dst_addr',                     self.to_bytes(0, 6), self.to_bytes(0, 6)),
#				[self.KeyField('hdr.vlan_tag$0.$valid',                     self.to_bytes(tag_valid, 1), self.to_bytes(1, 1))],
#				'SwitchIngress_0.pkt_validation_0.valid_unicast_pkt_untagged')

#		self.insert_table_entry(
#			target,
#			'SwitchIngress_0.pkt_validation_1.validate_ethernet',
##			[self.KeyField('hdr.ethernet.src_addr',                     self.to_bytes(0, 6), self.to_bytes(0, 6)),
##			 self.KeyField('hdr.ethernet.dst_addr',                     self.to_bytes(0, 6), self.to_bytes(0, 6)),
#			[self.KeyField('hdr.vlan_tag$0.$valid',                     self.to_bytes(tag_valid, 1), self.to_bytes(1, 1))],
#			'SwitchIngress_0.pkt_validation_1.valid_unicast_pkt_untagged')

#		self.insert_table_entry(
#			target,
#			'SwitchIngress_0.pkt_validation_2.validate_ethernet',
##			[self.KeyField('hdr.ethernet.src_addr',                     self.to_bytes(0, 6), self.to_bytes(0, 6)),
##			 self.KeyField('hdr.ethernet.dst_addr',                     self.to_bytes(0, 6), self.to_bytes(0, 6)),
#			[self.KeyField('hdr.vlan_tag$0.$valid',                     self.to_bytes(tag_valid, 1), self.to_bytes(1, 1))],
#			'SwitchIngress_0.pkt_validation_2.valid_unicast_pkt_untagged')

def npb_validate_eth_del(self, target, ig_pipe, tag_valid):
	pass;
#		if(PipelineParams.TRANSPORT_ENABLE == True):
#			self.delete_table_entry(
#				 target,
#				'SwitchIngress_0.pkt_validation_0.validate_ethernet',
##				[self.KeyField('hdr.ethernet.src_addr',                     self.to_bytes(0, 6), self.to_bytes(0, 6)),
##				 self.KeyField('hdr.ethernet.dst_addr',                     self.to_bytes(0, 6), self.to_bytes(0, 6)),
#				[self.KeyField('hdr.vlan_tag$0.$valid',                     self.to_bytes(tag_valid, 1), self.to_bytes(1, 1))])

#		self.delete_table_entry(
#			target,
#			'SwitchIngress_0.pkt_validation_1.validate_ethernet',
##			[self.KeyField('hdr.ethernet.src_addr',                     self.to_bytes(0, 6), self.to_bytes(0, 6)),
##			 self.KeyField('hdr.ethernet.dst_addr',                     self.to_bytes(0, 6), self.to_bytes(0, 6)),
#			[self.KeyField('hdr.vlan_tag$0.$valid',                     self.to_bytes(tag_valid, 1), self.to_bytes(1, 1))])

#		self.delete_table_entry(
#			target,
#			'SwitchIngress_0.pkt_validation_2.validate_ethernet',
##			[self.KeyField('hdr.ethernet.src_addr',                     self.to_bytes(0, 6), self.to_bytes(0, 6)),
##			 self.KeyField('hdr.ethernet.dst_addr',                     self.to_bytes(0, 6), self.to_bytes(0, 6)),
#			[self.KeyField('hdr.vlan_tag$0.$valid',                     self.to_bytes(tag_valid, 1), self.to_bytes(1, 1))])

########################################

def npb_validate_ipv4_add(self, target):
	pass;
#		if(PipelineParams.TRANSPORT_ENABLE == True):
#				self.insert_table_entry(
#				target,
#				'SwitchIngress_0.pkt_validation_0.validate_ipv4',
#				[self.KeyField('ipv4_checksum_err',                         self.to_bytes(0, 1), self.to_bytes(1, 1)),
#				 self.KeyField('hdr.ipv4.version',                          self.to_bytes(0x4, 1), self.to_bytes(0xf, 1)),
#				 self.KeyField('hdr.ipv4.ihl',                              self.to_bytes(0, 1), self.to_bytes(0, 1)),
#				 self.KeyField('hdr.ipv4.ttl',                              self.to_bytes(0, 1), self.to_bytes(0, 1)),
#				 self.KeyField('hdr.ipv4.src_addr[31:24]',                  self.to_bytes(0, 1), self.to_bytes(0, 1))],
#				'SwitchIngress_0.pkt_validation_0.valid_ipv4_pkt',
#				[self.DataField('ip_frag',                                  self.to_bytes(0, 1))])

#		self.insert_table_entry(
#			target,
#			'SwitchIngress_0.pkt_validation_1.validate_ipv4',
#			[self.KeyField('ipv4_checksum_err',                         self.to_bytes(0, 1), self.to_bytes(1, 1)),
#			 self.KeyField('hdr.ipv4.version',                          self.to_bytes(0x4, 1), self.to_bytes(0xf, 1)),
#			 self.KeyField('hdr.ipv4.ihl',                              self.to_bytes(0, 1), self.to_bytes(0, 1)),
#			 self.KeyField('hdr.ipv4.ttl',                              self.to_bytes(0, 1), self.to_bytes(0, 1)),
#			 self.KeyField('hdr.ipv4.src_addr[31:24]',                  self.to_bytes(0, 1), self.to_bytes(0, 1))],
#			'SwitchIngress_0.pkt_validation_1.valid_ipv4_pkt',
#			[self.DataField('ip_frag',                                  self.to_bytes(0, 1))])

#		self.insert_table_entry(
#			target,
#			'SwitchIngress_0.pkt_validation_2.validate_ipv4',
#			[self.KeyField('ipv4_checksum_err',                         self.to_bytes(0, 1), self.to_bytes(1, 1)),
#			 self.KeyField('hdr.ipv4.version',                          self.to_bytes(0x4, 1), self.to_bytes(0xf, 1)),
#			 self.KeyField('hdr.ipv4.ihl',                              self.to_bytes(0, 1), self.to_bytes(0, 1)),
#			 self.KeyField('hdr.ipv4.ttl',                              self.to_bytes(0, 1), self.to_bytes(0, 1))],
#			'SwitchIngress_0.pkt_validation_2.valid_ipv4_pkt')

def npb_validate_ipv4_del(self, target):
	pass;
#		if(PipelineParams.TRANSPORT_ENABLE == True):
#			self.delete_table_entry(
#				target,
#				'SwitchIngress_0.pkt_validation_0.validate_ipv4',
#				[self.KeyField('ipv4_checksum_err',                        self.to_bytes(0, 1), self.to_bytes(1, 1)),
#				 self.KeyField('hdr.ipv4.version',                          self.to_bytes(0x4, 1), self.to_bytes(0xf, 1)),
#				 self.KeyField('hdr.ipv4.ihl',                              self.to_bytes(0, 1), self.to_bytes(0, 1)),
#				 self.KeyField('hdr.ipv4.ttl',                              self.to_bytes(0, 1), self.to_bytes(0, 1)),
#				 self.KeyField('hdr.ipv4.src_addr[31:24]',                  self.to_bytes(0, 1), self.to_bytes(0, 1))])

#		self.delete_table_entry(
#			target,
#			'SwitchIngress_0.pkt_validation_1.validate_ipv4',
#			[self.KeyField('ipv4_checksum_err',                        self.to_bytes(0, 1), self.to_bytes(1, 1)),
#			 self.KeyField('hdr.ipv4.version',                          self.to_bytes(0x4, 1), self.to_bytes(0xf, 1)),
#			 self.KeyField('hdr.ipv4.ihl',                              self.to_bytes(0, 1), self.to_bytes(0, 1)),
#			 self.KeyField('hdr.ipv4.ttl',                              self.to_bytes(0, 1), self.to_bytes(0, 1)),
#			 self.KeyField('hdr.ipv4.src_addr[31:24]',                  self.to_bytes(0, 1), self.to_bytes(0, 1))])

#		self.delete_table_entry(
#			target,
#			'SwitchIngress_0.pkt_validation_2.validate_ipv4',
#			[self.KeyField('ipv4_checksum_err',                        self.to_bytes(0, 1), self.to_bytes(1, 1)),
#			 self.KeyField('hdr.ipv4.version',                          self.to_bytes(0x4, 1), self.to_bytes(0xf, 1)),
#			 self.KeyField('hdr.ipv4.ihl',                              self.to_bytes(0, 1), self.to_bytes(0, 1)),
#			 self.KeyField('hdr.ipv4.ttl',                              self.to_bytes(0, 1), self.to_bytes(0, 1))])

########################################

cpu_port_static_port_list = []

def cpu_port_add(self, target, ig_pipe, port):

	for i in range(len(port)):

		if(port[i] not in cpu_port_static_port_list): # barefoot allows duplicate writes to parser tables for some reason (bug?), so we have to disallow them here....
			cpu_port_static_port_list.append(port[i])

			try:

				if(PipelineParams.CPU_ENABLE == True):
					# todo: make these inputs instead of hard coding them
					cpu_etype      = 0x9001
					cpu_etype_mask = 0xFFFF #(2**16)-1
					cpu_port       = port[i]
					cpu_port_mask  = 0x01FF #(2** 9)-1

					table = self.bfrt_info.table_get("%s.cpu_port" % iprsr_s[0])
					table.entry_add(
						target,
						[table.make_key(
							[gc.KeyTuple('ether_type', cpu_etype, cpu_etype_mask),
							 gc.KeyTuple('port',       cpu_port,  cpu_port_mask)]
						)]
					)

			except:
				print("A table operation failed. This is typically due to adding or removing a duplicate, and can be ignored 0.")

		else:
			print("A table operation failed. This is typically due to adding or removing a duplicate, and can be ignored 0.")

def cpu_port_del(self, target, ig_pipe, port):

	for i in range(len(port)):

		if(port[i] in cpu_port_static_port_list): # barefoot allows duplicate writes to parser tables for some reason (bug?), so we have to disallow them here....
			cpu_port_static_port_list.remove(port[i])

			try:

				if(PipelineParams.CPU_ENABLE == True):
					# todo: make these inputs instead of hard coding them
					cpu_etype      = 0x9001
					cpu_etype_mask = 0xFFFF #(2**16)-1
					cpu_port       = port[i]
					cpu_port_mask  = 0x01FF #(2** 9)-1

					table = self.bfrt_info.table_get("%s.cpu_port" % iprsr_s[0])
					table.entry_del(
						target,
						[table.make_key(
							[gc.KeyTuple('ether_type', cpu_etype, cpu_etype_mask),
							 gc.KeyTuple('port',       cpu_port,  cpu_port_mask)]
						)]
					)

			except:
				print("A table operation failed. This is typically due to adding or removing a duplicate, and can be ignored 0.")

		else:
			print("A table operation failed. This is typically due to adding or removing a duplicate, and can be ignored 0.")

########################################

# rmac (npb vs bridge)

def npb_tunnel_rmac_add(self, target, ig_pipe, dst_addr):
	# for our all-to-one program, need to edit the path to this table
	if(p4_name == 'pgm_mp_npb_igOnly_npb_igOnly_npb_igOnly_npb_egOnly_top'):
		ig_pipes2 = ig_pipes.copy()
		ig_pipes2.insert(0, 0)
	else:
		ig_pipes2 = ig_pipes.copy()

	try:
		for ig_pipe2 in ig_pipes2:
			if(PipelineParams.BRIDGING_ENABLE == True):
#				table = self.bfrt_info.table_get('%s.rmac.rmac' % ictl_s[ig_pipe2])
#				table.entry_add(
#					target,
#					[table.make_key(
#						[gc.KeyTuple('hdr_0.ethernet.dst_addr', gc.mac_to_bytes(dst_addr))]
#					)],
#					[table.make_data(
#						[],
#						'%s.rmac.rmac_hit' % ictl_s[ig_pipe2]
#					)]
#				)			

				table = self.bfrt_info.table_get("%s.my_mac_lo" % iprsr_s[ig_pipe2])
				table.entry_add(
					target,
					[table.make_key(
						[gc.KeyTuple('f1', gc.mac_to_bytes(dst_addr)[2:6], 0xffffffff)]
					)]
				)	

				table = self.bfrt_info.table_get("%s.my_mac_hi" % iprsr_s[ig_pipe2])
				table.entry_add(
					target,
					[table.make_key(
						[gc.KeyTuple('f1', gc.mac_to_bytes(dst_addr)[0:2], 0xffff)]
					)]
				)
	
	except:
		print("A table operation failed. This is typically due to adding or removing a duplicate, and can be ignored 1.")

def npb_tunnel_rmac_del(self, target, ig_pipe, dst_addr):
	# for our all-to-one program, need to edit the path to this table
	if(p4_name == 'pgm_mp_npb_igOnly_npb_igOnly_npb_igOnly_npb_egOnly_top'):
		ig_pipes2 = ig_pipes.copy()
		ig_pipes2.insert(0, 0)
	else:
		ig_pipes2 = ig_pipes.copy()

	try:
		for ig_pipe2 in ig_pipes2:
			if(PipelineParams.BRIDGING_ENABLE == True):
#				table = self.bfrt_info.table_get('%s.rmac.rmac' % ictl_s[ig_pipe2])
#				table.entry_del(
#					target,
#					[table.make_key(
#						[gc.KeyTuple('hdr_0.ethernet.dst_addr', gc.mac_to_bytes(dst_addr))]
#					)]
#				)

				table = self.bfrt_info.table_get("%s.my_mac_lo" % iprsr_s[ig_pipe2])
				table.entry_del(
				target,
					[table.make_key(
						[gc.KeyTuple('f1', gc.mac_to_bytes(dst_addr)[2:6], 0xffffffff)]
					)]
				)
	
				table = self.bfrt_info.table_get("%s.my_mac_hi" % iprsr_s[ig_pipe2])
				table.entry_del(
				target,
					[table.make_key(
						[gc.KeyTuple('f1', gc.mac_to_bytes(dst_addr)[0:2], 0xffff)]
					)]
				)

	except:
		print("A table operation failed. This is typically due to adding or removing a duplicate, and can be ignored 1.")

########################################

def npb_ing_port_add(self, target, ig_pipe, port, port_lag_ptr, bridging_enable, sap, vpn, spi, si, si_predec):
	# for our all-to-one program, need to edit the path to this table
	if(p4_name == 'pgm_mp_npb_igOnly_npb_igOnly_npb_igOnly_npb_egOnly_top'):
		ig_pipes2 = ig_pipes.copy()
		ig_pipes2.insert(0, 0)
	else:
		ig_pipes2 = ig_pipes.copy()

	for i in range(len(port)):

		try:
			for ig_pipe2 in ig_pipes2:

				if(PipelineParams.CPU_HDR_CONTAINS_EG_PORT == False):
					table = self.bfrt_info.table_get('%s.$PORT_METADATA' % iprsr_s[ig_pipe2])
					table.entry_add(
						target,
						[table.make_key(
						[gc.KeyTuple('ig_intr_md.ingress_port',                   port[i])],
						)],
						[table.make_data(
							[gc.DataTuple('port_lag_index',                           port_lag_ptr),
							 gc.DataTuple('l2_fwd_en',                                bridging_enable)],
							None
						)]
					)

					########################################

					# insert both versions (cpu and non-cpu):

					table = self.bfrt_info.table_get('%s.ingress_port_mapping.port_mapping' % ictl_s[ig_pipe2])
					table.entry_add(
						target,
						[table.make_key(
							[gc.KeyTuple('ig_md.port',                                port[i]),
							 gc.KeyTuple('hdr.cpu.$valid',                            0)],
						)],
						[table.make_data(
							[],
							'%s.ingress_port_mapping.set_port_properties' % ictl_s[ig_pipe2]
						)]
					)

					table = self.bfrt_info.table_get('%s.ingress_port_mapping.port_mapping' % ictl_s[ig_pipe2])
					table.entry_add(
						target,
						[table.make_key(
							[gc.KeyTuple('ig_md.port',                                port[i]),
							 gc.KeyTuple('hdr.cpu.$valid',                            1)],
						)],
						[table.make_data(
							[gc.DataTuple('port_lag_index',                           port_lag_ptr),
							 gc.DataTuple('l2_fwd_en',                                bridging_enable)],
							'%s.ingress_port_mapping.set_cpu_port_properties' % ictl_s[ig_pipe2]
						)]
					)

				else:
					# insert both versions (cpu and non-cpu):
					table = self.bfrt_info.table_get('%s.ingress_port_mapping.port_mapping' % ictl_s[ig_pipe2])
					table.entry_add(
						target,
						[table.make_key(
							[gc.KeyTuple('ig_md.port',                                port[i]),
							 gc.KeyTuple('hdr.cpu.$valid',                            0)],
						)],
						[table.make_data(
							[gc.DataTuple('port_lag_index',                           port_lag_ptr)],
#							 gc.DataTuple('l2_fwd_en',                                bridging_enable)],
							'%s.ingress_port_mapping.set_port_properties' % ictl_s[ig_pipe2]
						)]
					)

					table = self.bfrt_info.table_get('%s.ingress_port_mapping.port_mapping' % ictl_s[ig_pipe2])
					table.entry_add(
						target,
						[table.make_key(
							[gc.KeyTuple('ig_md.port',                                port[i]),
							 gc.KeyTuple('hdr.cpu.$valid',                            1)],
						)],
						[table.make_data(
							[gc.DataTuple('port_lag_index',                           port_lag_ptr)],
#							 gc.DataTuple('l2_fwd_en',                                bridging_enable)],
							'%s.ingress_port_mapping.set_cpu_port_properties' % ictl_s[ig_pipe2]
						)]
					)

		except:
			print("A table operation failed. This is typically due to adding or removing a duplicate, and can be ignored 2a.")

			########################################

		try:
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

		except:
			print("A table operation failed. This is typically due to adding or removing a duplicate, and can be ignored 2c.")

		########################################

		try:

			table = self.bfrt_info.table_get('%s.npb_ing_top.npb_ing_sfc_top.port_mapping' % ictl_s[ig_pipe])
			table.entry_add(
				target,
				[table.make_key(
					[gc.KeyTuple('port',                                      port[i])],
#					[gc.KeyTuple('port_lag_index',                            port_lag_ptr)],
				)],
				[table.make_data(
					[gc.DataTuple('sap',                                      sap),
					 gc.DataTuple('vpn',                                      vpn),
					 gc.DataTuple('spi',                                      spi),
					 gc.DataTuple('si',                                       si),
					 gc.DataTuple('si_predec',                                si_predec)],
					'%s.npb_ing_top.npb_ing_sfc_top.set_port_properties' % ictl_s[ig_pipe]
				)]
			)

		except:
			print("A table operation failed. This is typically due to adding or removing a duplicate, and can be ignored 2b.")

def npb_ing_port_del(self, target, ig_pipe, port, port_lag_ptr):
	# for our all-to-one program, need to edit the path to this table
	if(p4_name == 'pgm_mp_npb_igOnly_npb_igOnly_npb_igOnly_npb_egOnly_top'):
		ig_pipes2 = ig_pipes.copy()
		ig_pipes2.insert(0, 0)
	else:
		ig_pipes2 = ig_pipes.copy()

	for i in range(len(port)):

		try:
			for ig_pipe2 in ig_pipes2:

				if(PipelineParams.CPU_HDR_CONTAINS_EG_PORT == False):

					table = self.bfrt_info.table_get('%s.$PORT_METADATA' % iprsr_s[ig_pipe2])
					table.entry_del(
						target,
						[table.make_key(
							[gc.KeyTuple('ig_intr_md.ingress_port',                   port[i])],
						)]
					)

					########################################

					# delete both versions (cpu and non-cpu):

					table = self.bfrt_info.table_get('%s.ingress_port_mapping.port_mapping' % ictl_s[ig_pipe2])
					table.entry_del(
						target,
						[table.make_key(
							[gc.KeyTuple('ig_md.port',                                port[i]),
							 gc.KeyTuple('hdr.cpu.$valid',                            0)],
						)]
					)

					table = self.bfrt_info.table_get('%s.ingress_port_mapping.port_mapping' % ictl_s[ig_pipe2])
					table.entry_del(
						target,
						[table.make_key(
							[gc.KeyTuple('ig_md.port',                                port[i]),
							 gc.KeyTuple('hdr.cpu.$valid',                            1)],
						)]
					)

				else:

					# delete both versions (cpu and non-cpu):

					table = self.bfrt_info.table_get('%s.ingress_port_mapping.port_mapping' % ictl_s[ig_pipe2])
					table.entry_del(
						target,
						[table.make_key(
							[gc.KeyTuple('ig_md.port',                                port[i]),
							 gc.KeyTuple('hdr.cpu.$valid',                            0)],
						)]
					)

					table = self.bfrt_info.table_get('%s.ingress_port_mapping.port_mapping' % ictl_s[ig_pipe2])
					table.entry_del(
						target,
						[table.make_key(
							[gc.KeyTuple('ig_md.port',                                port[i]),
							 gc.KeyTuple('hdr.cpu.$valid',                            1)],
						)]
					)

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

		except:
			print("A table operation failed. This is typically due to adding or removing a duplicate, and can be ignored 2.")

		########################################

		try:

			table = self.bfrt_info.table_get('%s.npb_ing_top.npb_ing_sfc_top.port_mapping' % ictl_s[ig_pipe])
			table.entry_del(
				target,
				[table.make_key(
					[gc.KeyTuple('port',                                      port[i])],
#					[gc.KeyTuple('port_lag_index',                            port_lag_ptr)],
				)]
			)

		except:
			print("A table operation failed. This is typically due to adding or removing a duplicate, and can be ignored 2.")

########################################

def npb_ing_port_mirror_add(self, target, ig_pipe, port, session_id):
	# for our all-to-one program, need to edit the path to this table
	if(p4_name == 'pgm_mp_npb_igOnly_npb_igOnly_npb_igOnly_npb_egOnly_top'):
		ig_pipes2 = ig_pipes.copy()
		ig_pipes2.insert(0, 0)
	else:
		ig_pipes2 = ig_pipes.copy()

	for ig_pipe2 in ig_pipes2:
		table = self.bfrt_info.table_get('%s.ingress_port_mapping.port_mirror.port_mirror' % ictl_s[ig_pipe2])
		table.entry_add(
			target,
			[table.make_key(
				[gc.KeyTuple('port',                             port)],
			)],
			[table.make_data(
				[gc.DataTuple('session_id',                      session_id)],
				'%s.ingress_port_mapping.port_mirror.set_mirror_id' % ictl_s[ig_pipe2],
			)]
		)

def npb_ing_port_mirror_del(self, target, ig_pipe, port):
	# for our all-to-one program, need to edit the path to this table
	if(p4_name == 'pgm_mp_npb_igOnly_npb_igOnly_npb_igOnly_npb_egOnly_top'):
		ig_pipes2 = ig_pipes.copy()
		ig_pipes2.insert(0, 0)
	else:
		ig_pipes2 = ig_pipes.copy()

	for ig_pipe2 in ig_pipes2:
		table = self.bfrt_info.table_get('%s.ingress_port_mapping.port_mirror.port_mirror' % ictl_s[ig_pipe2])
		table.entry_del(
			target,
			[table.make_key(
				[gc.KeyTuple('port',                             port)],
			)],
		)

########################################

def npb_port_vlan_to_bd_add(self, target, ig_pipe, port_lag_index, vid_valid, vid_valid_mask, vid, vid_mask, member_ptr, bd):
		# for our all-to-one program, need to edit the path to this table
		if(p4_name == 'pgm_mp_npb_igOnly_npb_igOnly_npb_igOnly_npb_egOnly_top'):
			ig_pipes2 = ig_pipes.copy()
			ig_pipes2.insert(0, 0)
		else:
			ig_pipes2 = ig_pipes.copy()

		try:
			for ig_pipe2 in ig_pipes2:
				# bottom
				table = self.bfrt_info.table_get('%s.ingress_port_mapping.bd_action_profile' % ictl_s[ig_pipe2])
				table.entry_add(
					target,
					[table.make_key(
						[gc.KeyTuple('$ACTION_MEMBER_ID',                     member_ptr)],
					)],
					[table.make_data(
						[gc.DataTuple('bd',                                   bd),
						 gc.DataTuple('rid',                                  0)],
						'%s.ingress_port_mapping.set_bd_properties' % ictl_s[ig_pipe2]
					)]
				)

		except:
			print("A table operation failed. This is typically due to adding or removing a duplicate, and can be ignored 3.")

		try:
			for ig_pipe2 in ig_pipes2:
				# top
				table = self.bfrt_info.table_get('%s.ingress_port_mapping.port_vlan_to_bd_mapping' % ictl_s[ig_pipe2])
				table.entry_add(
					target,
					[table.make_key(
						[gc.KeyTuple('ig_md.port_lag_index',                  port_lag_index),
#						 gc.KeyTuple('hdr.transport.vlan_tag$0.$valid',       vid_valid, vid_valid_mask),
#						 gc.KeyTuple('hdr.transport.vlan_tag$0.vid',          vid, vid_mask)],
						 gc.KeyTuple('hdr.outer.vlan_tag$0.$valid',           vid_valid, vid_valid_mask),
						 gc.KeyTuple('hdr.outer.vlan_tag$0.vid',              vid, vid_mask)],
					)],
					[table.make_data(
						[gc.DataTuple('$ACTION_MEMBER_ID',                    member_ptr)],
						None
					)]
				)

		except:
			print("A table operation failed. This is typically due to adding or removing a duplicate, and can be ignored 3.")

def npb_port_vlan_to_bd_del(self, target, ig_pipe, port_lag_index, vid_valid, vid_valid_mask, vid, vid_mask, member_ptr):
		# for our all-to-one program, need to edit the path to this table
		if(p4_name == 'pgm_mp_npb_igOnly_npb_igOnly_npb_igOnly_npb_egOnly_top'):
			ig_pipes2 = ig_pipes.copy()
			ig_pipes2.insert(0, 0)
		else:
			ig_pipes2 = ig_pipes.copy()

		try:
			for ig_pipe2 in ig_pipes2:
				# top
				table = self.bfrt_info.table_get('%s.ingress_port_mapping.port_vlan_to_bd_mapping' % ictl_s[ig_pipe2])
				table.entry_del(
					target,
					[table.make_key(
						[gc.KeyTuple('ig_md.port_lag_index',                  port_lag_index),
#						 gc.KeyTuple('hdr.transport.vlan_tag$0.$valid',       vid_valid, vid_valid_mask),
#						 gc.KeyTuple('hdr.transport.vlan_tag$0.vid',          vid, vid_mask)],
						 gc.KeyTuple('hdr.outer.vlan_tag$0.$valid',           vid_valid, vid_valid_mask),
						 gc.KeyTuple('hdr.outer.vlan_tag$0.vid',              vid, vid_mask)],
					)],
				)

		except:
			print("A table operation failed. This is typically due to adding or removing a duplicate, and can be ignored 4.")

		try:
			for ig_pipe2 in ig_pipes2:
				# bottom
				table = self.bfrt_info.table_get('%s.ingress_port_mapping.bd_action_profile' % ictl_s[ig_pipe2])
				table.entry_del(
					target,
					[table.make_key(
						[gc.KeyTuple('$ACTION_MEMBER_ID',                     member_ptr)],
					)],
				)

		except:
			print("A table operation failed. This is typically due to adding or removing a duplicate, and can be ignored 4.")

########################################

def npb_vlan_to_bd_add(self, target, ig_pipe, vid, member_ptr, bd):
		# for our all-to-one program, need to edit the path to this table
		if(p4_name == 'pgm_mp_npb_igOnly_npb_igOnly_npb_igOnly_npb_egOnly_top'):
			ig_pipes2 = ig_pipes.copy()
			ig_pipes2.insert(0, 0)
		else:
			ig_pipes2 = ig_pipes.copy()

		try:
			for ig_pipe2 in ig_pipes2:
				# bottom
				table = self.bfrt_info.table_get('%s.ingress_port_mapping.bd_action_profile' % ictl_s[ig_pipe2])
				table.entry_add(
					target,
					[table.make_key(
						[gc.KeyTuple('$ACTION_MEMBER_ID',                     member_ptr)],
					)],
					[table.make_data(
						[gc.DataTuple('bd',                                   bd)],
#						[gc.DataTuple('rid',                                  0)],
						'%s.ingress_port_mapping.set_bd_properties' % ictl_s[ig_pipe2]
					)]
				)

		except:
			print("A table operation failed. This is typically due to adding or removing a duplicate, and can be ignored 5.")

		try:
			for ig_pipe2 in ig_pipes2:
				# top
				table = self.bfrt_info.table_get('%s.ingress_port_mapping.vlan_to_bd_mapping' % ictl_s[ig_pipe2])
				table.entry_add(
					target,
					[table.make_key(
#						[gc.KeyTuple('hdr.transport.vlan_tag$0.vid',          vid)],
						[gc.KeyTuple('hdr.outer.vlan_tag$0.vid',              vid)],
					)],
					[table.make_data(
						[gc.DataTuple('$ACTION_MEMBER_ID',                    member_ptr)],
						None
					)]
				)

		except:
			print("A table operation failed. This is typically due to adding or removing a duplicate, and can be ignored 5.")

def npb_vlan_to_bd_del(self, target, ig_pipe, vid, member_ptr):
		# for our all-to-one program, need to edit the path to this table
		if(p4_name == 'pgm_mp_npb_igOnly_npb_igOnly_npb_igOnly_npb_egOnly_top'):
			ig_pipes2 = ig_pipes.copy()
			ig_pipes2.insert(0, 0)
		else:
			ig_pipes2 = ig_pipes.copy()

		try:
			for ig_pipe2 in ig_pipes2:
				# top
				table = self.bfrt_info.table_get('%s.ingress_port_mapping.vlan_to_bd_mapping' % ictl_s[ig_pipe2])
				table.entry_del(
					target,
					[table.make_key(
#						[gc.KeyTuple('hdr.transport.vlan_tag$0.vid',          vid)],
						[gc.KeyTuple('hdr.outer.vlan_tag$0.vid',              vid)],
					)],
				)

		except:
			print("A table operation failed. This is typically due to adding or removing a duplicate, and can be ignored 6.")

		try:
			for ig_pipe2 in ig_pipes2:
				# bottom
				table = self.bfrt_info.table_get('%s.ingress_port_mapping.bd_action_profile' % ictl_s[ig_pipe2])
				table.entry_del(
					target,
					[table.make_key(
						[gc.KeyTuple('$ACTION_MEMBER_ID',                     member_ptr)],
					)],
				)

		except:
			print("A table operation failed. This is typically due to adding or removing a duplicate, and can be ignored 6.")

########################################

# dmac (bridge)

def npb_tunnel_dmac_add(self, target, ig_pipe, ig_port_lag_ptr, ethertype, ethertype_mask, vid_isValid, vid_isValid_mask, vid, vid_mask, dst_addr, dst_addr_mask, eg_port_lag_ptr):
		# for our all-to-one program, need to edit the path to this table
		if(p4_name == 'pgm_mp_npb_igOnly_npb_igOnly_npb_igOnly_npb_egOnly_top'):
			ig_pipes2 = ig_pipes.copy()
			ig_pipes2.insert(0, 0)
		else:
			ig_pipes2 = ig_pipes.copy()

		if(PipelineParams.BRIDGING_ENABLE == True):
			for ig_pipe2 in ig_pipes2:
				table = self.bfrt_info.table_get('%s.dmac.dmac' % ictl_s[ig_pipe2])
				table.entry_add(
					target,
					[table.make_key(
#						[gc.KeyTuple('vlan_tag.isValid',                      vid_isValid, vid_isValid_mask),
						[gc.KeyTuple('vid',                                   vid, vid_mask),
						 gc.KeyTuple('mac_dst_addr',                          gc.mac_to_bytes(dst_addr), dst_addr_mask),
						 gc.KeyTuple('port_lag_index',                        ig_port_lag_ptr, 0x3ff),
						 gc.KeyTuple('mac_type',                              ethertype, ethertype_mask)]
					)],
					[table.make_data(
						[gc.DataTuple('port_lag_index',                       eg_port_lag_ptr)],
						'%s.dmac.dmac_hit' % ictl_s[ig_pipe2]
					)]
				)

def npb_tunnel_dmac_del(self, target, ig_pipe, ig_port_lag_ptr, ethertype, ethertype_mask, vid_isValid, vid_isValid_mask, vid, vid_mask, dst_addr, dst_addr_mask):
		# for our all-to-one program, need to edit the path to this table
		if(p4_name == 'pgm_mp_npb_igOnly_npb_igOnly_npb_igOnly_npb_egOnly_top'):
			ig_pipes2 = ig_pipes.copy()
			ig_pipes2.insert(0, 0)
		else:
			ig_pipes2 = ig_pipes.copy()

		if(PipelineParams.BRIDGING_ENABLE == True):
			for ig_pipe2 in ig_pipes2:
				table = self.bfrt_info.table_get('%s.dmac.dmac' % ictl_s[ig_pipe2])
				table.entry_del(
					target,
					[table.make_key(
#						[gc.KeyTuple('vlan_tag.isValid',                      vid_isValid, vid_isValid_mask),
						[gc.KeyTuple('vid',                                   vid, vid_mask),
						 gc.KeyTuple('mac_dst_addr',                          gc.mac_to_bytes(dst_addr), dst_addr_mask),
						 gc.KeyTuple('port_lag_index',                        ig_port_lag_ptr, 0x3ff),
						 gc.KeyTuple('mac_type',                              ethertype, ethertype_mask)]
					)]
				)

########################################

# ing sfc: decap 0 (transport)

def npb_tunnel_network_dst_vtep_add(self, target, ig_pipe,
		l3_src   = '0.0.0.0', l3_src_mask   = 0,
		l3_dst   = '0.0.0.0', l3_dst_mask   = 0,
		tun_type = 0,         tun_type_mask = 0,
		tun_id   = 0,         tun_id_mask   = 0,
		# results
		sap           = 0,
		vpn           = 0,
		port_lag_ptr  = 0,
		drop          = 0,
		mirror_enable = 0,    mirror_id   = 0,
		):

		for ig_pipe2 in ig_pipes:
			table = self.bfrt_info.table_get('%s.npb_ing_top.npb_ing_sfc_top.tunnel_transport.dst_vtep' % ictl_s[ig_pipe2])
			table.entry_add(
				target,
				[table.make_key(
					[gc.KeyTuple('src_addr',                                  gc.ipv4_to_bytes(l3_src), l3_src_mask),
					 gc.KeyTuple('dst_addr',                                  gc.ipv4_to_bytes(l3_dst), l3_dst_mask),
					 gc.KeyTuple('tunnel_type',                               tun_type, tun_type_mask),
					 gc.KeyTuple('tunnel_id',                               tun_id, tun_id_mask)],
				)],
				[table.make_data(
					[gc.DataTuple('sap',                                      sap),
					 gc.DataTuple('vpn',                                      vpn),
#					 gc.DataTuple('port_lag_index',                           port_lag_ptr),
					 gc.DataTuple('drop',                                     drop),
					 gc.DataTuple('mirror_enable',                            mirror_enable),
					 gc.DataTuple('mirror_session_id',                        mirror_id)],
					'%s.npb_ing_top.npb_ing_sfc_top.tunnel_transport.dst_vtep_hit' % ictl_s[ig_pipe2]
				)]
			)

def npb_tunnel_network_dst_vtep_del(self, target, ig_pipe,
		l3_src   = '0.0.0.0', l3_src_mask   = 0,
		l3_dst   = '0.0.0.0', l3_dst_mask   = 0,
		tun_id   = 0,         tun_id_mask   = 0,
		tun_type = 0,         tun_type_mask = 0
		):
		for ig_pipe2 in ig_pipes:
			table = self.bfrt_info.table_get('%s.npb_ing_top.npb_ing_sfc_top.tunnel_transport.dst_vtep' % ictl_s[ig_pipe2])

			# read counter
			resp = table.entry_get(
				target,
				[table.make_key(
					[gc.KeyTuple('src_addr',                                  gc.ipv4_to_bytes(l3_src), l3_src_mask),
					 gc.KeyTuple('dst_addr',                                  gc.ipv4_to_bytes(l3_dst), l3_dst_mask),
					 gc.KeyTuple('tunnel_type',                               tun_type, tun_type_mask),
					 gc.KeyTuple('tunnel_id',                                 tun_id, tun_id_mask)],
				)],
				{"from_hw": True},
				table.make_data(
					[gc.DataTuple("$COUNTER_SPEC_BYTES"),
					 gc.DataTuple("$COUNTER_SPEC_PKTS")],
					'%s.npb_ing_top.npb_ing_sfc_top.tunnel_transport.dst_vtep_hit' % ictl_s[ig_pipe2],
					get=True
				)
			)

			data_dict = next(resp)[0].to_dict()
			recv_pkts = data_dict["$COUNTER_SPEC_PKTS"]
			recv_bytes = data_dict["$COUNTER_SPEC_BYTES"]

			print("Dumping npb_tunnel_network_dst_vtep counters: pkts", recv_pkts, "bytes", recv_bytes)

			# delete entry
			table.entry_del(
				target,
				[table.make_key(
					[gc.KeyTuple('src_addr',                                  gc.ipv4_to_bytes(l3_src), l3_src_mask),
					 gc.KeyTuple('dst_addr',                                  gc.ipv4_to_bytes(l3_dst), l3_dst_mask),
					 gc.KeyTuple('tunnel_type',                               tun_type, tun_type_mask),
					 gc.KeyTuple('tunnel_id',                                 tun_id, tun_id_mask)],
				)],
			)

########################################

# ing sfc: decap 0 (transport)

def npb_tunnel_network_src_vtep_add(self, target, ig_pipe,
		l3_src   = '0.0.0.0', l3_src_mask   = 0,
		tun_type = 0,         tun_type_mask = 0,
		# results
		sap          = 0,
		vpn          = 0,
		port_lag_ptr = 0
		):

		for ig_pipe2 in ig_pipes:
			table = self.bfrt_info.table_get('%s.npb_ing_top.npb_ing_sfc_top.tunnel_transport.src_vtep' % ictl_s[ig_pipe2])
			table.entry_add(
				target,
				[table.make_key(
					[gc.KeyTuple('src_addr',                                  gc.ipv4_to_bytes(l3_src), l3_src_mask),
					 gc.KeyTuple('tunnel_type',                               tun_type)],
				)],
				[table.make_data(
					[gc.DataTuple('sap',                                      sap),
					 gc.DataTuple('vpn',                                      vpn)],
#					 gc.DataTuple('port_lag_index',                           port_lag_ptr)],
					'%s.npb_ing_top.npb_ing_sfc_top.tunnel_transport.src_vtep_hit' % ictl_s[ig_pipe2]
				)]
			)

def npb_tunnel_network_src_vtep_del(self, target, ig_pipe,
		l3_src   = '0.0.0.0', l3_src_mask   = 0,
		tun_type = 0,         tun_type_mask = 0
		):

		for ig_pipe2 in ig_pipes:
			table = self.bfrt_info.table_get('%s.npb_ing_top.npb_ing_sfc_top.tunnel_transport.src_vtep' % ictl_s[ig_pipe2])
			table.entry_del(
				target,
				[table.make_key(
					[gc.KeyTuple('src_addr',                                  gc.ipv4_to_bytes(l3_src), l3_src_mask),
					 gc.KeyTuple('tunnel_type',                               tun_type)],
				)],
			)

########################################

# ing sfc: decap #1a (transport)

def npb_tunnel_network_sap_add(self, target, ig_pipe,
		sap       = 0,
		tun_type  = 0, tun_type_mask = 0,
		# results
		sap_new   = 0,
		vpn       = 0
		):

		for ig_pipe2 in ig_pipes:
			table = self.bfrt_info.table_get('%s.npb_ing_top.npb_ing_sfc_top.tunnel_network.sap' % ictl_s[ig_pipe2])
			table.entry_add(
				target,
				[table.make_key(
					[gc.KeyTuple('sap',                              sap),
					 gc.KeyTuple('tunnel_type',                      tun_type)],
				)],
				[table.make_data(
					[gc.DataTuple('sap',                             sap_new),
					 gc.DataTuple('vpn',                             vpn)],
					'%s.npb_ing_top.npb_ing_sfc_top.tunnel_network.sap_hit' % ictl_s[ig_pipe2]
				)]
			)

def npb_tunnel_network_sap_del(self, target, ig_pipe,
		sap       = 0,
		tun_type  = 0, tun_type_mask = 0
		):

		for ig_pipe2 in ig_pipes:
			table = self.bfrt_info.table_get('%s.npb_ing_top.npb_ing_sfc_top.tunnel_network.sap' % ictl_s[ig_pipe2])
			table.entry_del(
				target,
				[table.make_key(
					[gc.KeyTuple('sap',                              sap),
					 gc.KeyTuple('tunnel_type',                      tun_type)],
				)],
			)

########################################

# ing sfc: decap #1b (outer)

def npb_tunnel_outer_sap_add(self, target, ig_pipe,
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

		for ig_pipe2 in ig_pipes:
			table = self.bfrt_info.table_get('%s.npb_ing_top.npb_ing_sfc_top.tunnel_outer.sap_tcam' % ictl_s[ig_pipe2])
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
					'%s.npb_ing_top.npb_ing_sfc_top.tunnel_outer.sap_tcam_hit' % ictl_s[ig_pipe2]
				)]
			)

def npb_tunnel_outer_sap_del(self, target, ig_pipe,
		sap       = 0,
		tun_type  = 0, tun_type_mask = 0
		):

		for ig_pipe2 in ig_pipes:
			table = self.bfrt_info.table_get('%s.npb_ing_top.npb_ing_sfc_top.tunnel_outer.sap_tcam' % ictl_s[ig_pipe2])
			table.entry_del(
				target,
				[table.make_key(
					[gc.KeyTuple('sap',                              sap, 0xffff),
					 gc.KeyTuple('tunnel_type',                      tun_type, tun_type_mask)]
				)]
			)

########################################

# ing sfc: decap #2 (inner)

def npb_tunnel_inner_sap_add(self, target, ig_pipe,
		sap            = 0,
		l3_proto       = 0, l3_proto_mask       = 0,
		l3_type        = 0, l3_type_mask         = 0,
		l3_sip         = '0.0.0.0', l3_sip_mask         = 0,
		l3_dip         = '0.0.0.0', l3_dip_mask         = 0,
		l4_src         = 0, l4_src_mask         = 0,
		l4_dst         = 0, l4_dst_mask         = 0,
		tun_id    = 0,      tun_id_mask         = 0,
		tun_type  = 0, tun_type_mask = 0,
		# results
		sap_new   = 0,
		vpn       = 0,
		scope     = 0,
		terminate = 0, # note: terminate & !scope is nonsense
		drop      = 0
		):

		# ensure that whenever "terminate" is set, "scope" is also set
		if(terminate):
			scope = 1;

		for ig_pipe2 in ig_pipes:
			table = self.bfrt_info.table_get('%s.npb_ing_top.npb_ing_sfc_top.tunnel_inner.sap_tcam' % ictl_s[ig_pipe2])
			table.entry_add(
				target,
				[table.make_key(
					[gc.KeyTuple('sap',                              sap,         0xffff),
					 gc.KeyTuple('ip_type',                          l3_type,     l3_type_mask),
					 gc.KeyTuple('ip_src_addr',                      gc.ipv4_to_bytes(l3_sip),      l3_sip_mask),
					 gc.KeyTuple('ip_dst_addr',                      gc.ipv4_to_bytes(l3_dip),      l3_dip_mask),
					 gc.KeyTuple('ip_proto',                         l3_proto,    l3_proto_mask),
					 gc.KeyTuple('l4_src_port',                      l4_src,      l4_src_mask),
					 gc.KeyTuple('l4_dst_port',                      l4_dst,      l4_dst_mask),
					 gc.KeyTuple('tunnel_id',                        tun_id,      tun_id_mask),
					 gc.KeyTuple('tunnel_type',                      tun_type,    tun_type_mask)]
				)],
				[table.make_data(
					[gc.DataTuple('sap',                             sap_new),
					 gc.DataTuple('vpn',                             vpn),
					 gc.DataTuple('scope',                           scope),
					 gc.DataTuple('terminate',                       terminate),
					 gc.DataTuple('drop',                            drop)],
					'%s.npb_ing_top.npb_ing_sfc_top.tunnel_inner.sap_tcam_hit' % ictl_s[ig_pipe2]
				)]
			)

def npb_tunnel_inner_sap_del(self, target, ig_pipe,
		sap       = 0,
		l3_proto       = 0, l3_proto_mask       = 0,
		l3_type        = 0, l3_type_mask         = 0,
		l3_sip         = '0.0.0.0', l3_sip_mask         = 0,
		l3_dip         = '0.0.0.0', l3_dip_mask         = 0,
		l4_src         = 0, l4_src_mask         = 0,
		l4_dst         = 0, l4_dst_mask         = 0,
		tun_id    = 0,      tun_id_mask         = 0,
		tun_type  = 0, tun_type_mask = 0
		):

		for ig_pipe2 in ig_pipes:
			table = self.bfrt_info.table_get('%s.npb_ing_top.npb_ing_sfc_top.tunnel_inner.sap_tcam' % ictl_s[ig_pipe2])

			# read counter
			resp = table.entry_get(
				target,
				[table.make_key(
					[gc.KeyTuple('sap',                              sap, 0xffff),
					 gc.KeyTuple('ip_type',                          l3_type,     l3_type_mask),
					 gc.KeyTuple('ip_src_addr',                      gc.ipv4_to_bytes(l3_sip),      l3_sip_mask),
					 gc.KeyTuple('ip_dst_addr',                      gc.ipv4_to_bytes(l3_dip),      l3_dip_mask),
					 gc.KeyTuple('ip_proto',                         l3_proto,    l3_proto_mask),
					 gc.KeyTuple('l4_src_port',                      l4_src,      l4_src_mask),
					 gc.KeyTuple('l4_dst_port',                      l4_dst,      l4_dst_mask),
					 gc.KeyTuple('tunnel_id',                        tun_id,      tun_id_mask),
					 gc.KeyTuple('tunnel_type',                      tun_type, tun_type_mask)]
				)],
				{"from_hw": True},
				table.make_data(
					[gc.DataTuple("$COUNTER_SPEC_BYTES"),
					 gc.DataTuple("$COUNTER_SPEC_PKTS")],
					'%s.npb_ing_top.npb_ing_sfc_top.tunnel_inner.sap_tcam_hit' % ictl_s[ig_pipe2],
					get=True
				)
			)	

			data_dict = next(resp)[0].to_dict()
			recv_pkts = data_dict["$COUNTER_SPEC_PKTS"]
			recv_bytes = data_dict["$COUNTER_SPEC_BYTES"]

			print("Dumping npb_tunnel_inner_sap counters: pkts", recv_pkts, "bytes", recv_bytes)

			# delete entry
			table.entry_del(
				target,
				[table.make_key(
					[gc.KeyTuple('sap',                              sap, 0xffff),
					 gc.KeyTuple('ip_type',                          l3_type,     l3_type_mask),
					 gc.KeyTuple('ip_src_addr',                      gc.ipv4_to_bytes(l3_sip),      l3_sip_mask),
					 gc.KeyTuple('ip_dst_addr',                      gc.ipv4_to_bytes(l3_dip),      l3_dip_mask),
					 gc.KeyTuple('ip_proto',                         l3_proto,    l3_proto_mask),
					 gc.KeyTuple('l4_src_port',                      l4_src,      l4_src_mask),
					 gc.KeyTuple('l4_dst_port',                      l4_dst,      l4_dst_mask),
					 gc.KeyTuple('tunnel_id',                        tun_id,      tun_id_mask),
					 gc.KeyTuple('tunnel_type',                      tun_type, tun_type_mask)]
				)],
			)

########################################

# ing sfc: for packets w/  nsh header

def npb_npb_sfc_sf_sel_add(self, target, ig_pipe, spi, si, si_predec):

		for ig_pipe2 in ig_pipes:
			table = self.bfrt_info.table_get('%s.npb_ing_top.npb_ing_sfc_top.ing_sfc_sf_sel' % ictl_s[ig_pipe2])
			table.entry_add(
				target,
				[table.make_key(
					[gc.KeyTuple('spi',                               spi),
					 gc.KeyTuple('si',                                si)],
				)],
				[table.make_data(
					[gc.DataTuple('si_predec',                        si_predec)],
					'%s.npb_ing_top.npb_ing_sfc_top.ing_sfc_sf_sel_hit' % ictl_s[ig_pipe2]
				)]
			)

def npb_npb_sfc_sf_sel_del(self, target, ig_pipe, spi, si):

		for ig_pipe2 in ig_pipes:
			table = self.bfrt_info.table_get('%s.npb_ing_top.npb_ing_sfc_top.ing_sfc_sf_sel' % ictl_s[ig_pipe2])
			table.entry_del(
				target,
				[table.make_key(
					[gc.KeyTuple('spi',                               spi),
					 gc.KeyTuple('si',                                si)],
				)]
			)

########################################

def npb_sfc_sf_sel_nsh_xlate_add(self, target, ig_pipe, ta, ttl, spi, si, si_predec):

		for ig_pipe2 in ig_pipes:
			table = self.bfrt_info.table_get('%s.npb_ing_top.npb_ing_sfc_top.ing_sfc_sf_sel_nsh_xlate' % ictl_s[ig_pipe2])
			table.entry_add(
				target,
				[table.make_key(
					[gc.KeyTuple('tool_address',                     ta)],
				)],
				[table.make_data(
					[gc.DataTuple('ttl',                             ttl),
					 gc.DataTuple('spi',                             spi),
					 gc.DataTuple('si',                              si),
					 gc.DataTuple('si_predec',                      si_predec)],
					'%s.npb_ing_top.npb_ing_sfc_top.ing_sfc_sf_sel_nsh_xlate_hit' % ictl_s[ig_pipe2]
				)]
			)

def npb_sfc_sf_sel_nsh_xlate_del(self, target, ig_pipe, ta):

		for ig_pipe2 in ig_pipes:
			table = self.bfrt_info.table_get('%s.npb_ing_top.npb_ing_sfc_top.ing_sfc_sf_sel_nsh_xlate' % ictl_s[ig_pipe2])
			table.entry_del(
				target,
				[table.make_key(
					[gc.KeyTuple('tool_address',                               ta)],
				)],
			)



########################################

# ing sf #0: action select

def npb_npb_sf0_action_sel_add(self, target, ig_pipe, spi, si, bitmask):
	try:

		for ig_pipe2 in ig_pipes:
			table = self.bfrt_info.table_get('%s.npb_ing_top.npb_ing_sf_npb_basic_adv_top.ing_sf_action_sel' % ictl_s[ig_pipe2])
			table.entry_add(
				target,
				[table.make_key(
					[gc.KeyTuple('spi',                               spi),
					 gc.KeyTuple('si',                                si)],
				)],
				[table.make_data(
					[],
					'%s.npb_ing_top.npb_ing_sf_npb_basic_adv_top.ing_sf_action_sel_hit' % ictl_s[ig_pipe2]
				)]
			)
	except:
		print("A table operation failed. This is typically due to adding or removing a duplicate, and can be ignored 7.")

def npb_npb_sf0_action_sel_del(self, target, ig_pipe, spi, si):
	try:

		for ig_pipe2 in ig_pipes:
			table = self.bfrt_info.table_get('%s.npb_ing_top.npb_ing_sf_npb_basic_adv_top.ing_sf_action_sel' % ictl_s[ig_pipe2])
			table.entry_del(
				target,
				[table.make_key(
					[gc.KeyTuple('spi',                               spi),
					 gc.KeyTuple('si',                                si)],
				)],
			)
	except:
		print("A table operation failed. This is typically due to adding or removing a duplicate, and can be ignored 7.")

########################################

# ing sf #0: ip_len range

def npb_npb_sf0_len_rng_add(self, target, ig_pipe, l3_len_lo, l3_len_hi, l3_len_rng):

		for ig_pipe2 in ig_pipes:
			table = self.bfrt_info.table_get('%s.npb_ing_top.npb_ing_sf_npb_basic_adv_top.ing_sf_ip_len_rng' % ictl_s[ig_pipe2])
			table.entry_add(
				target,
				[table.make_key(
					[gc.KeyTuple('ip_len',                              low=l3_len_lo, high=l3_len_hi)],
				)],
				[table.make_data(
					[gc.DataTuple('rng_bitmask',                        l3_len_rng)],
					'%s.npb_ing_top.npb_ing_sf_npb_basic_adv_top.ing_sf_ip_len_rng_hit' % ictl_s[ig_pipe2]
				)]
			)

def npb_npb_sf0_len_rng_del(self, target, ig_pipe, l3_len_lo, l3_len_hi):

		for ig_pipe2 in ig_pipes:
			table = self.bfrt_info.table_get('%s.npb_ing_top.npb_ing_sf_npb_basic_adv_top.ing_sf_ip_len_rng' % ictl_s[ig_pipe2])
			table.entry_del(
				target,
				[table.make_key(
					[gc.KeyTuple('ip_len',                              low=l3_len_lo, high=l3_len_hi)],
				)],
			)

########################################

# ing sf #0: l4_src_port range

def npb_npb_sf0_l4_src_port_rng_add(self, target, ig_pipe, l3_len_lo, l3_len_hi, l3_len_rng):

		for ig_pipe2 in ig_pipes:
			table = self.bfrt_info.table_get('%s.npb_ing_top.npb_ing_sf_npb_basic_adv_top.ing_sf_l4_src_port_rng' % ictl_s[ig_pipe2])
			table.entry_add(
				target,
				[table.make_key(
					[gc.KeyTuple('l4_src_port',                         low=l3_len_lo, high=l3_len_hi)],
				)],
				[table.make_data(
					[gc.DataTuple('rng_bitmask',                        l3_len_rng)],
					'%s.npb_ing_top.npb_ing_sf_npb_basic_adv_top.ing_sf_l4_src_port_rng_hit' % ictl_s[ig_pipe2]
				)]
			)

def npb_npb_sf0_l4_src_port_rng_del(self, target, ig_pipe, l3_len_lo, l3_len_hi):

		for ig_pipe2 in ig_pipes:
			table = self.bfrt_info.table_get('%s.npb_ing_top.npb_ing_sf_npb_basic_adv_top.ing_sf_l4_src_port_rng' % ictl_s[ig_pipe2])
			table.entry_del(
				target,
				[table.make_key(
					[gc.KeyTuple('l4_src_port',                         low=l3_len_lo, high=l3_len_hi)],
				)],
			)

########################################

# ing sf #0: l4_dst_port range

def npb_npb_sf0_l4_dst_port_rng_add(self, target, ig_pipe, l3_len_lo, l3_len_hi, l3_len_rng):

		for ig_pipe2 in ig_pipes:
			table = self.bfrt_info.table_get('%s.npb_ing_top.npb_ing_sf_npb_basic_adv_top.ing_sf_l4_dst_port_rng' % ictl_s[ig_pipe2])
			table.entry_add(
				target,
				[table.make_key(
					[gc.KeyTuple('l4_dst_port',                         low=l3_len_lo, high=l3_len_hi)],
				)],
				[table.make_data(
					[gc.DataTuple('rng_bitmask',                        l3_len_rng)],
					'%s.npb_ing_top.npb_ing_sf_npb_basic_adv_top.ing_sf_l4_dst_port_rng_hit' % ictl_s[ig_pipe2]
				)]
			)

def npb_npb_sf0_l4_dst_port_rng_del(self, target, ig_pipe, l3_len_lo, l3_len_hi):

		for ig_pipe2 in ig_pipes:
			table = self.bfrt_info.table_get('%s.npb_ing_top.npb_ing_sf_npb_basic_adv_top.ing_sf_l4_dst_port_rng' % ictl_s[ig_pipe2])
			table.entry_del(
				target,
				[table.make_key(
					[gc.KeyTuple('l4_dst_port',                         low=l3_len_lo, high=l3_len_hi)],
				)],
			)

########################################

# ing sf #0: policy l2

def npb_npb_sf0_policy_l2_add(self, target, ig_pipe,
		sap         = 0, sap_mask      = 0xffff,
		vpn         = 0, vpn_mask      = 0xffff,
		l2_sa       = '0:0:0:0:0:0', l2_sa_mask = 0,
		l2_da       = '0:0:0:0:0:0', l2_da_mask = 0,
		l2_etype    = 0, l2_etype_mask = 0,
		tun_type    = 0, tun_type_mask = 0,
		# results
		flow_class  = 0,
		drop        = 0,
		scope       = 0,
		terminate   = 0, # note: terminate & !scope is nonsense
		trunc_enable= 0, trunc         = 0,
		mirror_enable = 0, mirror_id   = 0,
		cpu_reason_code = 0,
		sfc_enable  = 0,
		sfc         = 0
		):

		# ensure that whenever "terminate" is set, "scope" is also set
		if(terminate):
			scope = 1;

		for ig_pipe2 in ig_pipes:
			table = self.bfrt_info.table_get('%s.npb_ing_top.npb_ing_sf_npb_basic_adv_top.acl.mac_acl.acl' % ictl_s[ig_pipe2])
			table.entry_add(
				target,
				[table.make_key(
					[gc.KeyTuple('sap',                              sap,      sap_mask),
					 gc.KeyTuple('vpn',                              vpn,      vpn_mask),
					 gc.KeyTuple('lkp.mac_src_addr',                 gc.mac_to_bytes(l2_sa), l2_sa_mask),
					 gc.KeyTuple('lkp.mac_dst_addr',                 gc.mac_to_bytes(l2_da), l2_da_mask),
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
					 gc.DataTuple('mirror_enable',                   mirror_enable),
					 gc.DataTuple('mirror_session_id',               mirror_id),
					 gc.DataTuple('cpu_reason_code',                 cpu_reason_code),
					 gc.DataTuple('sfc_enable',                      sfc_enable),
					 gc.DataTuple('sfc',                             sfc)],
					'%s.npb_ing_top.npb_ing_sf_npb_basic_adv_top.acl.mac_acl.hit' % ictl_s[ig_pipe2]
				)]
			)

def npb_npb_sf0_policy_l2_del(self, target, ig_pipe,
		sap         = 0, sap_mask      = 0xffff,
		vpn         = 0, vpn_mask      = 0xffff,
		l2_sa       = '0:0:0:0:0:0', l2_sa_mask = 0,
		l2_da       = '0:0:0:0:0:0', l2_da_mask = 0,
		l2_etype    = 0, l2_etype_mask = 0,
		tun_type    = 0, tun_type_mask = 0
		):

		for ig_pipe2 in ig_pipes:
			table = self.bfrt_info.table_get('%s.npb_ing_top.npb_ing_sf_npb_basic_adv_top.acl.mac_acl.acl' % ictl_s[ig_pipe2])

			# read counter
			resp = table.entry_get(
				target,
				[table.make_key(
					[gc.KeyTuple('sap',                              sap,      sap_mask),
					 gc.KeyTuple('vpn',                              vpn,      vpn_mask),
					 gc.KeyTuple('lkp.mac_src_addr',                 gc.mac_to_bytes(l2_sa), l2_sa_mask),
					 gc.KeyTuple('lkp.mac_dst_addr',                 gc.mac_to_bytes(l2_da), l2_da_mask),
					 gc.KeyTuple('lkp.mac_type',                     l2_etype, l2_etype_mask),
					 gc.KeyTuple('lkp.tunnel_type',                  tun_type, tun_type_mask)],
				)],
				{"from_hw": True},
				table.make_data(
					[gc.DataTuple("$COUNTER_SPEC_BYTES"),
					 gc.DataTuple("$COUNTER_SPEC_PKTS")],
					'%s.npb_ing_top.npb_ing_sf_npb_basic_adv_top.acl.mac_acl.hit' % ictl_s[ig_pipe2],
					get=True
				)
			)

			data_dict = next(resp)[0].to_dict()
			recv_pkts = data_dict["$COUNTER_SPEC_PKTS"]
			recv_bytes = data_dict["$COUNTER_SPEC_BYTES"]

			print("Dumping npb_npb_sf0_policy_l2 counters: pkts", recv_pkts, "bytes", recv_bytes)
			#if (recv_pkts != 1):
				#logging.error("Number of received packets on SF0 L2 ACL is incorrect!!!!")
				#test.fail("Number of received packets on SF0 L2 ACL is incorrect")
				#return None


		# delete entry
			table.entry_del(
				target,
				[table.make_key(
					[gc.KeyTuple('sap',                              sap,      sap_mask),
					 gc.KeyTuple('vpn',                              vpn,      vpn_mask),
					 gc.KeyTuple('lkp.mac_src_addr',                 gc.mac_to_bytes(l2_sa), l2_sa_mask),
					 gc.KeyTuple('lkp.mac_dst_addr',                 gc.mac_to_bytes(l2_da), l2_da_mask),
					 gc.KeyTuple('lkp.mac_type',                     l2_etype, l2_etype_mask),
					 gc.KeyTuple('lkp.tunnel_type',                  tun_type, tun_type_mask)],
				)]
			)

########################################

# ing sf #0: policy l3 v4

def npb_npb_sf0_policy_l34_v4_add(self, target, ig_pipe,
		sap            = 0, sap_mask            = 0xffff,
		vpn            = 0, vpn_mask            = 0x0,
		l3_len         = 0, l3_len_mask         = 0,
		l3_len_rng     = 0, l3_len_rng_mask     = 0,
		l3_proto       = 0, l3_proto_mask       = 0,
		l3_sip         = '0.0.0.0', l3_sip_mask         = 0,
		l3_dip         = '0.0.0.0', l3_dip_mask         = 0,
		l4_src         = 0, l4_src_mask         = 0,
		l4_src_rng     = 0, l4_src_rng_mask     = 0,
		l4_dst         = 0, l4_dst_mask         = 0,
		l4_dst_rng     = 0, l4_dst_rng_mask     = 0,
		tun_type       = 0, tun_type_mask       = 0,
		# results
		flow_class     = 0,
		drop           = 0,
		scope          = 0,
		terminate      = 0, # note: terminate & !scope is nonsense
		trunc_enable   = 0, trunc               = 0,
		mirror_enable  = 0, mirror_id           = 0,
		cpu_reason_code= 0,
		sfc_enable     = 0,
		sfc            = 0
		):

		# ensure that whenever "terminate" is set, "scope" is also set
		if(terminate):
			scope = 1;

		for ig_pipe2 in ig_pipes:
			table = self.bfrt_info.table_get('%s.npb_ing_top.npb_ing_sf_npb_basic_adv_top.acl.ipv4_acl.acl' % ictl_s[ig_pipe2])
			table.entry_add(
				target,
				[table.make_key(
					[gc.KeyTuple('sap',                              sap,            sap_mask),
					 gc.KeyTuple('vpn',                              vpn,            vpn_mask),
					 gc.KeyTuple('lkp.ip_len',                       l3_len,         l3_len_mask),
					 gc.KeyTuple('lkp.ip_len_rng',                   l3_len_rng,     l3_len_rng_mask),
					 gc.KeyTuple('lkp.ip_proto',                     l3_proto,       l3_proto_mask),
					 gc.KeyTuple('lkp.ip_src_addr[31:0]',            gc.ipv4_to_bytes(l3_sip), l3_sip_mask),
					 gc.KeyTuple('lkp.ip_dst_addr[31:0]',            gc.ipv4_to_bytes(l3_dip), l3_dip_mask),
					 gc.KeyTuple('lkp.l4_src_port',                  l4_src,         l4_src_mask),
					 gc.KeyTuple('lkp.l4_src_port_rng',              l4_src_rng,     l4_src_rng_mask),
					 gc.KeyTuple('lkp.l4_dst_port',                  l4_dst,         l4_dst_mask),
					 gc.KeyTuple('lkp.l4_dst_port_rng',              l4_dst_rng,     l4_dst_rng_mask),
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
					 gc.DataTuple('mirror_enable',                   mirror_enable),
					 gc.DataTuple('mirror_session_id',               mirror_id),
					 gc.DataTuple('cpu_reason_code',                 cpu_reason_code),
					 gc.DataTuple('sfc_enable',                      sfc_enable),
					 gc.DataTuple('sfc',                             sfc)],
					'%s.npb_ing_top.npb_ing_sf_npb_basic_adv_top.acl.ipv4_acl.hit' % ictl_s[ig_pipe2]
				)]
			)

def npb_npb_sf0_policy_l34_v4_del(self, target, ig_pipe,
		sap            = 0, sap_mask            = 0xffff,
		vpn            = 0, vpn_mask            = 0x0,
		l3_len         = 0, l3_len_mask         = 0,
		l3_len_rng     = 0, l3_len_rng_mask     = 0,
		l3_proto       = 0, l3_proto_mask       = 0,
		l3_sip         = '0.0.0.0', l3_sip_mask         = 0,
		l3_dip         = '0.0.0.0', l3_dip_mask         = 0,
		l4_src         = 0, l4_src_mask         = 0,
		l4_src_rng     = 0, l4_src_rng_mask     = 0,
		l4_dst         = 0, l4_dst_mask         = 0,
		l4_dst_rng     = 0, l4_dst_rng_mask     = 0,
		tun_type       = 0, tun_type_mask       = 0
		):

		for ig_pipe2 in ig_pipes:
			table = self.bfrt_info.table_get('%s.npb_ing_top.npb_ing_sf_npb_basic_adv_top.acl.ipv4_acl.acl' % ictl_s[ig_pipe2])	

			# read counter
			resp = table.entry_get(
				target,
				[table.make_key(
					[gc.KeyTuple('sap',                              sap,            sap_mask),
					 gc.KeyTuple('vpn',                              vpn,            vpn_mask),
					 gc.KeyTuple('lkp.ip_len',                       l3_len,         l3_len_mask),
					 gc.KeyTuple('lkp.ip_len_rng',                   l3_len_rng,     l3_len_rng_mask),
					 gc.KeyTuple('lkp.ip_proto',                     l3_proto,       l3_proto_mask),
					 gc.KeyTuple('lkp.ip_src_addr[31:0]',            gc.ipv4_to_bytes(l3_sip), l3_sip_mask),
					 gc.KeyTuple('lkp.ip_dst_addr[31:0]',            gc.ipv4_to_bytes(l3_dip), l3_dip_mask),
					 gc.KeyTuple('lkp.l4_src_port',                  l4_src,         l4_src_mask),
					 gc.KeyTuple('lkp.l4_src_port_rng',              l4_src_rng,     l4_src_rng_mask),
					 gc.KeyTuple('lkp.l4_dst_port',                  l4_dst,         l4_dst_mask),
					 gc.KeyTuple('lkp.l4_dst_port_rng',              l4_dst_rng,     l4_dst_rng_mask),
					 gc.KeyTuple('lkp.tunnel_type',                  tun_type,       tun_type_mask),
					 gc.KeyTuple('$MATCH_PRIORITY',                  655426)],
				)],
				{"from_hw": True},
				table.make_data(
					[gc.DataTuple("$COUNTER_SPEC_BYTES"),
					 gc.DataTuple("$COUNTER_SPEC_PKTS")],
					'%s.npb_ing_top.npb_ing_sf_npb_basic_adv_top.acl.ipv4_acl.hit' % ictl_s[ig_pipe2],
					get=True
				)
			)

			data_dict = next(resp)[0].to_dict()
			recv_pkts = data_dict["$COUNTER_SPEC_PKTS"]
			recv_bytes = data_dict["$COUNTER_SPEC_BYTES"]	

			print("Dumping npb_npb_sf0_policy_l34_v4 counters: pkts", recv_pkts, "bytes", recv_bytes)
			#if (recv_pkts != 1):
				#logging.error("Number of received packets on SF0 L3/4 ACL is incorrect!!!!")
				#test.fail("Number of received packets on SF0 L3/4 ACL is incorrect")
				#return None

			# delete entry
			table.entry_del(
				target,
				[table.make_key(
					[gc.KeyTuple('sap',                              sap,            sap_mask),
					 gc.KeyTuple('vpn',                              vpn,            vpn_mask),
					 gc.KeyTuple('lkp.ip_len',                       l3_len,         l3_len_mask),
					 gc.KeyTuple('lkp.ip_len_rng',                   l3_len_rng,     l3_len_rng_mask),
					 gc.KeyTuple('lkp.ip_proto',                     l3_proto,       l3_proto_mask),
					 gc.KeyTuple('lkp.ip_src_addr[31:0]',            gc.ipv4_to_bytes(l3_sip), l3_sip_mask),
					 gc.KeyTuple('lkp.ip_dst_addr[31:0]',            gc.ipv4_to_bytes(l3_dip), l3_dip_mask),
					 gc.KeyTuple('lkp.l4_src_port',                  l4_src,         l4_src_mask),
					 gc.KeyTuple('lkp.l4_src_port_rng',              l4_src_rng,     l4_src_rng_mask),
					 gc.KeyTuple('lkp.l4_dst_port',                  l4_dst,         l4_dst_mask),
					 gc.KeyTuple('lkp.l4_dst_port_rng',              l4_dst_rng,     l4_dst_rng_mask),
					 gc.KeyTuple('lkp.tunnel_type',                  tun_type,       tun_type_mask),
					 gc.KeyTuple('$MATCH_PRIORITY',                  655426)],
				)]
			)

########################################

# ing sf #0: policy l3 v6

def npb_npb_sf0_policy_l34_v6_add(self, target, ig_pipe,
		sap            = 0, sap_mask            = 0xffff,
		vpn            = 0, vpn_mask            = 0xffff,
		mac_type       = 0, mac_type_mask       = 0xffff,
		vid            = 0, vid_mask            = 0xfff,
		l3_len         = 0, l3_len_mask         = 0,
		l3_len_rng     = 0, l3_len_rng_mask     = 0,
		l3_proto       = 0, l3_proto_mask       = 0,
		l3_tos         = 0, l3_tos_mask         = 0,
		l3_sip         = "0:0:0:0:0:0:0:0", l3_sip_mask         = 0,
		l3_dip         = "0:0:0:0:0:0:0:0", l3_dip_mask         = 0,
		l4_src         = 0, l4_src_mask         = 0,
		l4_src_rng     = 0, l4_src_rng_mask     = 0,
		l4_dst         = 0, l4_dst_mask         = 0,
		l4_dst_rng     = 0, l4_dst_rng_mask     = 0,
		tcp_flags      = 0, tcp_flags_mask      = 0,
		tun_type       = 0, tun_type_mask       = 0,
		tun_id         = 0, tun_id_mask         = 0,
		# results
		flow_class     = 0,
		drop           = 0,
		scope          = 0,
		terminate      = 0, # note: terminate & !scope is nonsense
		trunc_enable   = 0, trunc               = 0,
		mirror_enable  = 0, mirror_id           = 0,
		cpu_reason_code= 0,
		sfc_enable     = 0,
		sfc            = 0
		):

		# ensure that whenever "terminate" is set, "scope" is also set
		if(terminate):
			scope = 1;

		#gc.KeyTuple('lkp.vid',                          vid,            vid_mask),
		#gc.KeyTuple('vpn',                              vpn,            vpn_mask),


		for ig_pipe2 in ig_pipes:
			table = self.bfrt_info.table_get('%s.npb_ing_top.npb_ing_sf_npb_basic_adv_top.acl.ipv6_acl.acl' % ictl_s[ig_pipe2])
			table.entry_add(
				target,
				[table.make_key(
					[gc.KeyTuple('sap',                              sap,            sap_mask),
					 #gc.KeyTuple('vpn',                             vpn,            vpn_mask),
					 gc.KeyTuple('lkp.vid',                          vid,            vid_mask),
					 gc.KeyTuple('lkp.ip_len',                       l3_len,         l3_len_mask),
					 gc.KeyTuple('lkp.ip_len_rng',                   l3_len_rng,     l3_len_rng_mask),
					 gc.KeyTuple('lkp.ip_proto',                     l3_proto,       l3_proto_mask),
					 gc.KeyTuple('lkp.ip_tos',                       l3_tos,         l3_tos_mask),
					 gc.KeyTuple('lkp.ip_src_addr',                  gc.ipv6_to_bytes(l3_sip),         l3_sip_mask),
					 gc.KeyTuple('lkp.ip_dst_addr',                  gc.ipv6_to_bytes(l3_dip),         l3_dip_mask),
					 gc.KeyTuple('lkp.l4_src_port',                  l4_src,         l4_src_mask),
					 gc.KeyTuple('lkp.l4_src_port_rng',              l4_src_rng,     l4_src_rng_mask),
					 gc.KeyTuple('lkp.l4_dst_port',                  l4_dst,         l4_dst_mask),
					 gc.KeyTuple('lkp.l4_dst_port_rng',              l4_dst_rng,     l4_dst_rng_mask),
					 gc.KeyTuple('lkp.tcp_flags',                    tcp_flags,      tcp_flags_mask),
					 gc.KeyTuple('lkp.tunnel_type',                  tun_type,       tun_type_mask),
					 gc.KeyTuple('lkp.tunnel_id',                    tun_id,         tun_id_mask)],
				)],
				[table.make_data(
					[gc.DataTuple('flow_class',                      flow_class),
					 gc.DataTuple('drop',                            drop),
					 gc.DataTuple('scope',                           scope),
					 gc.DataTuple('terminate',                       terminate),
					 gc.DataTuple('truncate_enable',                 trunc_enable),
					 gc.DataTuple('truncate_len',                    trunc),
					 gc.DataTuple('mirror_enable',                   mirror_enable),
					 gc.DataTuple('mirror_session_id',               mirror_id),
					 gc.DataTuple('cpu_reason_code',                 cpu_reason_code),
					 gc.DataTuple('sfc_enable',                      sfc_enable),
					 gc.DataTuple('sfc',                             sfc)],
					'%s.npb_ing_top.npb_ing_sf_npb_basic_adv_top.acl.ipv6_acl.hit' % ictl_s[ig_pipe2]
				)]
			)

def npb_npb_sf0_policy_l34_v6_del(self, target, ig_pipe,
		sap            = 0, sap_mask            = 0xffff,
		vpn            = 0, vpn_mask            = 0xffff,
		vid            = 0, vid_mask            = 0xfff,
		l3_len         = 0, l3_len_mask         = 0,
		l3_len_rng     = 0, l3_len_rng_mask     = 0,
		l3_proto       = 0, l3_proto_mask       = 0,
		l3_tos         = 0, l3_tos_mask         = 0,
		l3_sip         = "0:0:0:0:0:0:0:0", l3_sip_mask         = 0,
		l3_dip         = "0:0:0:0:0:0:0:0", l3_dip_mask         = 0,
		l4_src         = 0, l4_src_mask         = 0,
		l4_src_rng     = 0, l4_src_rng_mask     = 0,
		l4_dst         = 0, l4_dst_mask         = 0,
		l4_dst_rng     = 0, l4_dst_rng_mask     = 0,
		tcp_flags      = 0, tcp_flags_mask      = 0,
		tun_type       = 0, tun_type_mask       = 0,
		tun_id         = 0, tun_id_mask         = 0
		):

		for ig_pipe2 in ig_pipes:
			table = self.bfrt_info.table_get('%s.npb_ing_top.npb_ing_sf_npb_basic_adv_top.acl.ipv6_acl.acl' % ictl_s[ig_pipe2])

			# read counter
			resp = table.entry_get(
				target,
				[table.make_key(
					[gc.KeyTuple('sap',                              sap,            sap_mask),
					 #gc.KeyTuple('vpn',                             vpn,            vpn_mask),
					 gc.KeyTuple('lkp.vid',                          vid,            vid_mask),
					 gc.KeyTuple('lkp.ip_len',                       l3_len,         l3_len_mask),
					 gc.KeyTuple('lkp.ip_len_rng',                   l3_len_rng,     l3_len_rng_mask),
					 gc.KeyTuple('lkp.ip_proto',                     l3_proto,       l3_proto_mask),
					 gc.KeyTuple('lkp.ip_tos',                       l3_tos,         l3_tos_mask),
					 gc.KeyTuple('lkp.ip_src_addr',                  gc.ipv6_to_bytes(l3_sip),         l3_sip_mask),
					 gc.KeyTuple('lkp.ip_dst_addr',                  gc.ipv6_to_bytes(l3_dip),         l3_dip_mask),
					 gc.KeyTuple('lkp.l4_src_port',                  l4_src,         l4_src_mask),
					 gc.KeyTuple('lkp.l4_src_port_rng',              l4_src_rng,     l4_src_rng_mask),
					 gc.KeyTuple('lkp.l4_dst_port',                  l4_dst,         l4_dst_mask),
					 gc.KeyTuple('lkp.l4_dst_port_rng',              l4_dst_rng,     l4_dst_rng_mask),
					 gc.KeyTuple('lkp.tcp_flags',                    tcp_flags,      tcp_flags_mask),
					 gc.KeyTuple('lkp.tunnel_type',                  tun_type,       tun_type_mask),
					 gc.KeyTuple('lkp.tunnel_id',                    tun_id,         tun_id_mask)],
				)],
				{"from_hw": True},
				table.make_data(
					[gc.DataTuple("$COUNTER_SPEC_BYTES"),
					 gc.DataTuple("$COUNTER_SPEC_PKTS")],
					'%s.npb_ing_top.npb_ing_sf_npb_basic_adv_top.acl.ipv6_acl.hit' % ictl_s[ig_pipe2],
					get=True
				)
			)

			data_dict = next(resp)[0].to_dict()
			recv_pkts = data_dict["$COUNTER_SPEC_PKTS"]
			recv_bytes = data_dict["$COUNTER_SPEC_BYTES"]

			print("Dumping npb_npb_sf0_policy_l34_v6 counters: pkts", recv_pkts, "bytes", recv_bytes)

			# delete entry
			table.entry_del(
				target,
				[table.make_key(
					[gc.KeyTuple('sap',                              sap,            sap_mask),
					 #gc.KeyTuple('vpn',                              vpn,            vpn_mask),
					 gc.KeyTuple('lkp.vid',                          vid,            vid_mask),
					 gc.KeyTuple('lkp.ip_len',                       l3_len,         l3_len_mask),
					 gc.KeyTuple('lkp.ip_len_rng',                   l3_len_rng,     l3_len_rng_mask),
					 gc.KeyTuple('lkp.ip_proto',                     l3_proto,       l3_proto_mask),
					 gc.KeyTuple('lkp.ip_tos',                       l3_tos,         l3_tos_mask),
					 gc.KeyTuple('lkp.ip_src_addr',                  gc.ipv6_to_bytes(l3_sip),         l3_sip_mask),
					 gc.KeyTuple('lkp.ip_dst_addr',                  gc.ipv6_to_bytes(l3_dip),         l3_dip_mask),
					 gc.KeyTuple('lkp.l4_src_port',                  l4_src,         l4_src_mask),
					 gc.KeyTuple('lkp.l4_src_port_rng',              l4_src_rng,     l4_src_rng_mask),
					 gc.KeyTuple('lkp.l4_dst_port',                  l4_dst,         l4_dst_mask),
					 gc.KeyTuple('lkp.l4_dst_port_rng',              l4_dst_rng,     l4_dst_rng_mask),
					 gc.KeyTuple('lkp.tcp_flags',                    tcp_flags,      tcp_flags_mask),
					 gc.KeyTuple('lkp.tunnel_type',                  tun_type,       tun_type_mask),
					 gc.KeyTuple('lkp.tunnel_id',                    tun_id,         tun_id_mask)],
				)]
			)

########################################

# ing sf #0: policy l7

def npb_npb_sf0_policy_l7_add(self, target, ig_pipe,
		sap         = 0, sap_mask      = 0xffff,
		udf         = 0, udf_mask      = 0,
		# results
		drop        = 0,
		scope       = 0,
		terminate   = 0, # note: terminate & !scope is nonsense
		trunc_enable= 0, trunc         = 0,
		mirror_enable = 0, mirror_id   = 0,
		cpu_reason_code = 0,
		sfc_enable  = 0,
		sfc         = 0
		):

		# ensure that whenever "terminate" is set, "scope" is also set
		if(terminate):
			scope = 1;

		for ig_pipe2 in ig_pipes:
			table = self.bfrt_info.table_get('%s.npb_ing_top.npb_ing_sf_npb_basic_adv_top.acl.l7_acl.acl' % ictl_s[ig_pipe2])
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
					 gc.DataTuple('mirror_enable',                   mirror_enable),
					 gc.DataTuple('mirror_session_id',               mirror_id),
					 gc.DataTuple('cpu_reason_code',                 cpu_reason_code),
					 gc.DataTuple('sfc_enable',                      sfc_enable),
					 gc.DataTuple('sfc',                             sfc)],
					'%s.npb_ing_top.npb_ing_sf_npb_basic_adv_top.acl.l7_acl.hit' % ictl_s[ig_pipe2]
				)]
			)

def npb_npb_sf0_policy_l7_del(self, target, ig_pipe,
		sap         = 0, sap_mask      = 0xffff,
		udf         = 0, udf_mask      = 0
		):

		for ig_pipe2 in ig_pipes:
			table = self.bfrt_info.table_get('%s.npb_ing_top.npb_ing_sf_npb_basic_adv_top.acl.l7_acl.acl' % ictl_s[ig_pipe2])

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
					'%s.npb_ing_top.npb_ing_sf_npb_basic_adv_top.acl.l7_acl.hit' % ictl_s[ig_pipe2],
					get=True
				)
			)	

			data_dict = next(resp)[0].to_dict()
			recv_pkts = data_dict["$COUNTER_SPEC_PKTS"]
			recv_bytes = data_dict["$COUNTER_SPEC_BYTES"]	

			print("Dumping npb_npb_sf0_policy_l7 counters: pkts", recv_pkts, "bytes", recv_bytes)

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

def npb_npb_sf0_policy_sfp_sel_hash_add(self, target, ig_pipe, vpn, flowclass):
	try:
		for ig_pipe2 in ig_pipes:
			# insert both copies of the table:
			table = self.bfrt_info.table_get('%s.npb_ing_top.npb_ing_sf_npb_basic_adv_sfp_hash_lkp_1.ing_flow_class' % ictl_s[ig_pipe2])
			table.entry_add(
				target,
				[table.make_key(
					[gc.KeyTuple('vpn',                              vpn, 0xffff)],
				)],
				[table.make_data(
					[gc.DataTuple('flow_class',                      flowclass)],
					'%s.npb_ing_top.npb_ing_sf_npb_basic_adv_sfp_hash_lkp_1.ing_flow_class_hit' % ictl_s[ig_pipe2]
				)]
			)

#			table = self.bfrt_info.table_get('%s.npb_ing_top.npb_ing_sf_npb_basic_adv_sfp_hash_lkp_2.ing_flow_class' % ictl_s[ig_pipe2])
#			table.entry_add(
#				target,
#				[table.make_key(
#					[gc.KeyTuple('vpn',                              vpn, 0xffff)],
#				)],
#				[table.make_data(
#					[gc.DataTuple('flow_class',                      flowclass)],
#					'%s.npb_ing_top.npb_ing_sf_npb_basic_adv_sfp_hash_lkp_2.ing_flow_class_hit' % ictl_s[ig_pipe2]
#				)]
#			)

	except:
		print("A table operation failed. This is typically due to adding or removing a duplicate, and can be ignored 8.")

def npb_npb_sf0_policy_sfp_sel_hash_del(self, target, ig_pipe, vpn):
	try:
		for ig_pipe2 in ig_pipes:
			# delete both copies of the table:

			table = self.bfrt_info.table_get('%s.npb_ing_top.npb_ing_sf_npb_basic_adv_sfp_hash_lkp_1.ing_flow_class' % ictl_s[ig_pipe2])
			table.entry_del(
				target,
				[table.make_key(
					[gc.KeyTuple('vpn',                              vpn, 0xffff)],
				)],
			)

#			table = self.bfrt_info.table_get('%s.npb_ing_top.npb_ing_sf_npb_basic_adv_sfp_hash_lkp_2.ing_flow_class' % ictl_s[ig_pipe2])
#			table.entry_del(
#				target,
#				[table.make_key(
#					[gc.KeyTuple('vpn',                              vpn, 0xffff)],
#				)],
#			)

	except:
		print("A table operation failed. This is typically due to adding or removing a duplicate, and can be ignored 8.")

########################################

# ing sf #0: scheduler selector

def npb_npb_sf0_policy_sfp_sel_single_add(self, target, ig_pipe, sfc, sfc_member_ptr, spi, si, si_predec):
		if(PipelineParams.SFF_SCHD_SIMPLE == True):
			for ig_pipe2 in ig_pipes:
				table = self.bfrt_info.table_get('%s.npb_ing_top.npb_ing_sf_npb_basic_adv_sfp_sel.ing_schd' % ictl_s[ig_pipe2])
				table.entry_add(
					target,
					[table.make_key(
						[gc.KeyTuple('sfc',                              sfc)],
					)],
					[table.make_data(
						[gc.DataTuple('spi',                             spi),
						 gc.DataTuple('si',                              si),
						 gc.DataTuple('si_predec',                       si_predec)],
						'%s.npb_ing_top.npb_ing_sf_npb_basic_adv_sfp_sel.ing_schd_hit' % ictl_s[ig_pipe2]
					)]
				)
		else:

			for ig_pipe2 in ig_pipes:
				# bottom
#				table = self.bfrt_info.table_get('%s.npb_ing_top.npb_ing_sf_npb_basic_adv_sfp_sel.schd_selector' % ictl_s[ig_pipe2])
				table = self.bfrt_info.table_get('%s.npb_ing_top.npb_ing_sf_npb_basic_adv_sfp_sel.schd_action_profile' % ictl_s[ig_pipe2])
				table.entry_add(
					target,
					[table.make_key(
						[gc.KeyTuple('$ACTION_MEMBER_ID',                sfc_member_ptr)],
					)],
					[table.make_data(
						[gc.DataTuple('spi',                             spi),
						 gc.DataTuple('si',                              si),
						 gc.DataTuple('si_predec',                       si_predec)],
						'%s.npb_ing_top.npb_ing_sf_npb_basic_adv_sfp_sel.ing_schd_hit' % ictl_s[ig_pipe2]
					)]
				)

			try:

				for ig_pipe2 in ig_pipes:
					# top
					table = self.bfrt_info.table_get('%s.npb_ing_top.npb_ing_sf_npb_basic_adv_sfp_sel.ing_schd' % ictl_s[ig_pipe2])
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
				print("A table operation failed. This is typically due to adding or removing a duplicate, and can be ignored 9.")

def npb_npb_sf0_policy_sfp_sel_single_del(self, target, ig_pipe, sfc, sfc_member_ptr):
		if(PipelineParams.SFF_SCHD_SIMPLE == True):
			for ig_pipe2 in ig_pipes:
				table = self.bfrt_info.table_get('%s.npb_ing_top.npb_ing_sf_npb_basic_adv_sfp_sel.ing_schd' % ictl_s[ig_pipe2])
				table.entry_del(
					target,
					[table.make_key(
						[gc.KeyTuple('sfc',                              sfc)],
					)],
				)
		else:
			try:

				for ig_pipe2 in ig_pipes:
					# top
					table = self.bfrt_info.table_get('%s.npb_ing_top.npb_ing_sf_npb_basic_adv_sfp_sel.ing_schd' % ictl_s[ig_pipe2])
					table.entry_del(
						target,
						[table.make_key(
							[gc.KeyTuple('sfc',                              sfc)],
						)],
					)

			except:
				print("A table operation failed. This is typically due to adding or removing a duplicate, and can be ignored 9.")

			for ig_pipe2 in ig_pipes:
				# bottom
#				table = self.bfrt_info.table_get('%s.npb_ing_top.npb_ing_sf_npb_basic_adv_sfp_sel.schd_selector' % ictl_s[ig_pipe2])
				table = self.bfrt_info.table_get('%s.npb_ing_top.npb_ing_sf_npb_basic_adv_sfp_sel.schd_action_profile' % ictl_s[ig_pipe2])
				table.entry_del(
					target,
					[table.make_key(
						[gc.KeyTuple('$ACTION_MEMBER_ID',                sfc_member_ptr)],
					)],
				)

########################################

# ing sf #0: scheduler selector

def npb_npb_sf0_policy_sfp_sel_multi_add(self, target, ig_pipe, sfc, sfc_group_ptr, sfc_member_ptr, spi, si, si_predec):
		if(PipelineParams.SFF_SCHD_SIMPLE == True):
			for ig_pipe2 in ig_pipes:
				self.insert_table_entry(
					target,
					'%s.npb_ing_top.npb_ing_sf_npb_basic_adv_sfp_sel.ing_schd' % ictl_s[ig_pipe2],
					[self.KeyField('sfc',                              self.to_bytes(sfc, 2))],
					'%s.npb_ing_top.npb_ing_sf_npb_basic_adv_sfp_sel.ing_schd_hit' % ictl_s[ig_pipe2],
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

				for ig_pipe2 in ig_pipes:
					# bottom
#					table = self.bfrt_info.table_get('%s.npb_ing_top.npb_ing_sf_npb_basic_adv_sfp_sel.schd_selector' % ictl_s[ig_pipe2])
					table = self.bfrt_info.table_get('%s.npb_ing_top.npb_ing_sf_npb_basic_adv_sfp_sel.schd_action_profile' % ictl_s[ig_pipe2])
					table.entry_add(
						target,
						[table.make_key(
							[gc.KeyTuple('$ACTION_MEMBER_ID',                sfc_member_ptr_list[i])],
						)],
						[table.make_data(
							[gc.DataTuple('spi',                             spi[i]),
							 gc.DataTuple('si',                              si[i]),
							 gc.DataTuple('si_predec',                       si_predec[i])],
							'%s.npb_ing_top.npb_ing_sf_npb_basic_adv_sfp_sel.ing_schd_hit' % ictl_s[ig_pipe2]
						)]
					)

			for ig_pipe2 in ig_pipes:
				# middle
#				table = self.bfrt_info.table_get('%s.npb_ing_top.npb_ing_sf_npb_basic_adv_sfp_sel.schd_selector_sel' % ictl_s[ig_pipe2])
				table = self.bfrt_info.table_get('%s.npb_ing_top.npb_ing_sf_npb_basic_adv_sfp_sel.schd_selector' % ictl_s[ig_pipe2])
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
				table = self.bfrt_info.table_get('%s.npb_ing_top.npb_ing_sf_npb_basic_adv_sfp_sel.ing_schd' % ictl_s[ig_pipe2])
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

def npb_npb_sf0_policy_sfp_sel_multi_del(self, target, ig_pipe, sfc, sfc_group_ptr, sfc_member_ptr, spi, si):
		if(PipelineParams.SFF_SCHD_SIMPLE == True):
			for ig_pipe2 in ig_pipes:
				self.delete_table_entry(
					target,
					'%s.npb_ing_top.npb_ing_sf_npb_basic_adv_sfp_sel.ing_schd' % ictl_s[ig_pipe2],
					[self.KeyField('sfc',                              self.to_bytes(sfc, 2))])
		else:
			sfc_member_ptr_list = []

			for i in range(0, len(spi)):
				sfc_member_ptr_list.append(sfc_member_ptr+i)

			for ig_pipe2 in ig_pipes:
				# top
				table = self.bfrt_info.table_get('%s.npb_ing_top.npb_ing_sf_npb_basic_adv_sfp_sel.ing_schd' % ictl_s[ig_pipe2])
				table.entry_del(
					target,
					[table.make_key(
						[gc.KeyTuple('sfc',                              sfc)],
					)],
				)

				# middle
#				table = self.bfrt_info.table_get('%s.npb_ing_top.npb_ing_sf_npb_basic_adv_sfp_sel.schd_selector_sel' % ictl_s[ig_pipe2])
				table = self.bfrt_info.table_get('%s.npb_ing_top.npb_ing_sf_npb_basic_adv_sfp_sel.schd_selector' % ictl_s[ig_pipe2])
				table.entry_del(
					target,
					[table.make_key(
						[gc.KeyTuple('$SELECTOR_GROUP_ID',               sfc_group_ptr)],
					)],
				)	

			for i in range(0, len(spi)):

				for ig_pipe2 in ig_pipes:
					# bottom
#					table = self.bfrt_info.table_get('%s.npb_ing_top.npb_ing_sf_npb_basic_adv_sfp_sel.schd_selector' % ictl_s[ig_pipe2])
					table = self.bfrt_info.table_get('%s.npb_ing_top.npb_ing_sf_npb_basic_adv_sfp_sel.schd_action_profile' % ictl_s[ig_pipe2])
					table.entry_del(
						target,
						[table.make_key(
							[gc.KeyTuple('$ACTION_MEMBER_ID',                sfc_member_ptr_list[i])],
						)],
					)

########################################

# ing sff: fib

def npb_npb_sff_fib_add(self, target, ig_pipe,  spi, si, nexthop_ptr, end_of_chain):

		try:

			for ig_pipe2 in ig_pipes:
				table = self.bfrt_info.table_get('%s.npb_ing_top.npb_ing_sff_top.ing_sff_fib' % ictl_s[ig_pipe2])
				table.entry_add(
					target,
					[table.make_key(
						[gc.KeyTuple('spi',                              spi),
						 gc.KeyTuple('si',                               si)]
					)],
					[table.make_data(
						[gc.DataTuple('nexthop_index',                   nexthop_ptr),
						 gc.DataTuple('end_of_chain',                    end_of_chain)],
					'%s.npb_ing_top.npb_ing_sff_top.redirect' % ictl_s[ig_pipe2]
					)]
				)

		except:
			print("A table operation failed. This is typically due to adding or removing a duplicate, and can be ignored 10.")

def npb_npb_sff_fib_del(self, target, ig_pipe, spi, si):

		try:

			for ig_pipe2 in ig_pipes:
				table = self.bfrt_info.table_get('%s.npb_ing_top.npb_ing_sff_top.ing_sff_fib' % ictl_s[ig_pipe2])
				table.entry_del(
					target,
					[table.make_key(
						[gc.KeyTuple('spi',                              spi),
						 gc.KeyTuple('si',                               si)]
					)]
				)

		except:
			print("A table operation failed. This is typically due to adding or removing a duplicate, and can be ignored 10.")

########################################

# ing sf #1: multicast

def npb_npb_sf1_action_sel_add(self, target, ig_pipe, spi, si, bitmask, mgid):

		for ig_pipe2 in ig_pipes:
			table = self.bfrt_info.table_get('%s.npb_ing_top.npb_ing_sf_multicast_top_part1.ing_sf_action_sel' % ictl_s[ig_pipe2])
			table.entry_add(
				target,
				[table.make_key(
					[gc.KeyTuple('spi',                               spi),
					 gc.KeyTuple('si',                                si)],
				)],
				[table.make_data(
					[gc.DataTuple('mgid',                            mgid)],
					'%s.npb_ing_top.npb_ing_sf_multicast_top_part1.ing_sf_action_sel_hit' % ictl_s[ig_pipe2],
				)]
			)

def npb_npb_sf1_action_sel_del(self, target, ig_pipe, spi, si):

		for ig_pipe2 in ig_pipes:
			table = self.bfrt_info.table_get('%s.npb_ing_top.npb_ing_sf_multicast_top_part1.ing_sf_action_sel' % ictl_s[ig_pipe2])

			# read counter
			resp = table.entry_get(
				target,
				[table.make_key(
					[gc.KeyTuple('spi',                               spi),
					 gc.KeyTuple('si',                                si)],
				)],
				{"from_hw": True},
				table.make_data(
					[gc.DataTuple("$COUNTER_SPEC_BYTES"),
					 gc.DataTuple("$COUNTER_SPEC_PKTS")],
					'%s.npb_ing_top.npb_ing_sf_multicast_top_part1.ing_sf_action_sel_hit' % ictl_s[ig_pipe2],
					get=True
				)
			)

			data_dict = next(resp)[0].to_dict()
			recv_pkts = data_dict["$COUNTER_SPEC_PKTS"]
			recv_bytes = data_dict["$COUNTER_SPEC_BYTES"]	

			print("Dumping npb_npb_sf1_multicast (ingress) counters: pkts", recv_pkts, "bytes", recv_bytes)

			# delete entry
			table.entry_del(
				target,
				[table.make_key(
					[gc.KeyTuple('spi',                               spi),
					 gc.KeyTuple('si',                                si)],
				)],
			)

########################################

def npb_nexthop_add(self, target, ig_pipe, nexthop_ptr, bd, port_lag_ptr):
		# for our all-to-one program, need to edit the path to this table
		if(p4_name == 'pgm_mp_npb_igOnly_npb_igOnly_npb_igOnly_npb_egOnly_top'):
			ig_pipes2 = ig_pipes.copy()
			ig_pipes2.insert(0, 0)
		else:
			ig_pipes2 = ig_pipes.copy()

		try:
			for ig_pipe2 in ig_pipes2:
				table = self.bfrt_info.table_get('%s.nexthop.nexthop' % ictl_s[ig_pipe2])
				table.entry_add(
					target,
					[table.make_key(
						[gc.KeyTuple('ig_md.nexthop',                    nexthop_ptr)],
					)],
					[table.make_data(
						[gc.DataTuple('bd',                              bd),
						 gc.DataTuple('port_lag_index',                  port_lag_ptr)],
						'%s.nexthop.set_nexthop_properties' % ictl_s[ig_pipe2]
					)]
				)

			# ---------------------------
			# Egress portion of table
			# ---------------------------

			table = self.bfrt_info.table_get('%s.rewrite.nexthop_rewrite' % ectl)
			table.entry_add(
				target,
				[table.make_key(
					[gc.KeyTuple('eg_md.nexthop',                    nexthop_ptr)],
				)],
				[table.make_data(
					[],
					'no_action'
				)]
			)

		except:
			print("A table operation failed. This is typically due to adding or removing a duplicate, and can be ignored 11a.")

def npb_nexthop_tunnel_encap_part2_add(self, target, ig_pipe, nexthop_ptr, tun_type):
		try: 
			# ---------------------------
			# Egress portion of table
			# ---------------------------

			table = self.bfrt_info.table_get('%s.rewrite.nexthop_rewrite' % ectl)
			table.entry_add(
				target,
				[table.make_key(
					[gc.KeyTuple('eg_md.nexthop',                    nexthop_ptr)]
				)],
				[table.make_data(
					[gc.DataTuple('type',                            tun_type)], # 3 means MAC-in-MAC tunnel!!!!
					'%s.rewrite.rewrite_l2_with_tunnel' % ectl
				)]
			)

		except:
			print("A table operation failed. This is typically due to adding or removing a duplicate, and can be ignored 11b.")

def npb_nexthop_tunnel_encap_add(self, target, ig_pipe, nexthop_ptr, bd, tunnel_ptr, tun_type):
		# for our all-to-one program, need to edit the path to this table
		if(p4_name == 'pgm_mp_npb_igOnly_npb_igOnly_npb_igOnly_npb_egOnly_top'):
			ig_pipes2 = ig_pipes.copy()
			ig_pipes2.insert(0, 0)
		else:
			ig_pipes2 = ig_pipes.copy()

		try:

			for ig_pipe2 in ig_pipes2:
				table = self.bfrt_info.table_get('%s.nexthop.nexthop' % ictl_s[ig_pipe2])
				table.entry_add(
					target,
					[table.make_key(
						[gc.KeyTuple('ig_md.nexthop',                    nexthop_ptr)]
					)],
					[table.make_data(
						[gc.DataTuple('bd',                            bd),
						 gc.DataTuple('tunnel_index',                  tunnel_ptr)], # aka dip_index!!!
						'%s.nexthop.set_nexthop_properties_tunnel' % ictl_s[ig_pipe2]
					)]
				)

			# ---------------------------
			# Egress portion of table
			# ---------------------------

			npb_nexthop_tunnel_encap_part2_add(self, target, ig_pipe, nexthop_ptr, tun_type)

		except:
			print("A table operation failed. This is typically due to adding or removing a duplicate, and can be ignored 11c.")

def npb_nexthop_part2_del(self, target, ig_pipe, nexthop_ptr):

		try: 
			# ---------------------------
			# Egress portion of table
			# ---------------------------

			table = self.bfrt_info.table_get('%s.rewrite.nexthop_rewrite' % ectl)
			table.entry_del(
				target,
				[table.make_key(
					[gc.KeyTuple('eg_md.nexthop',                    nexthop_ptr)]
				)],
			)

		except:
			print("A table operation failed. This is typically due to adding or removing a duplicate, and can be ignored 11d.")

def npb_nexthop_del(self, target, ig_pipe, nexthop_ptr):
		# for our all-to-one program, need to edit the path to this table
		if(p4_name == 'pgm_mp_npb_igOnly_npb_igOnly_npb_igOnly_npb_egOnly_top'):
			ig_pipes2 = ig_pipes.copy()
			ig_pipes2.insert(0, 0)
		else:
			ig_pipes2 = ig_pipes.copy()

		try:

			for ig_pipe2 in ig_pipes2:
				table = self.bfrt_info.table_get('%s.nexthop.nexthop' % ictl_s[ig_pipe2])
				table.entry_del(
					target,
					[table.make_key(
						[gc.KeyTuple('ig_md.nexthop',                    nexthop_ptr)]
					)]
				)

			# ---------------------------
			# Egress portion of table
			# ---------------------------

			npb_nexthop_part2_del(self, target, ig_pipe, nexthop_ptr)

		except:
			print("A table operation failed. This is typically due to adding or removing a duplicate, and can be ignored 11e.")

########################################

def npb_tunnel_encap_nexthop_add(self, target, ig_pipe, tunnel_ptr, port_lag_ptr, outer_nexthop_ptr):
		# for our all-to-one program, need to edit the path to this table
		if(p4_name == 'pgm_mp_npb_igOnly_npb_igOnly_npb_igOnly_npb_egOnly_top'):
			ig_pipes2 = ig_pipes.copy()
			ig_pipes2.insert(0, 0)
		else:
			ig_pipes2 = ig_pipes.copy()

		for ig_pipe2 in ig_pipes2:
			table = self.bfrt_info.table_get('%s.outer_fib.fib' % ictl_s[ig_pipe2])
			table.entry_add(
				target,
				[table.make_key(
					[gc.KeyTuple('ig_md.tunnel_0.index',             tunnel_ptr)],
				)],
				[table.make_data(
					[gc.DataTuple('port_lag_index',                  port_lag_ptr),
					 gc.DataTuple('nexthop_index',                   outer_nexthop_ptr)],
					'%s.outer_fib.set_nexthop_properties' % ictl_s[ig_pipe2]
				)]
			)

		# ---------------------------
		# Egress portion of table
		# ---------------------------

def npb_tunnel_encap_nexthop_del(self, target, ig_pipe, tunnel_ptr):
		# for our all-to-one program, need to edit the path to this table
		if(p4_name == 'pgm_mp_npb_igOnly_npb_igOnly_npb_igOnly_npb_egOnly_top'):
			ig_pipes2 = ig_pipes.copy()
			ig_pipes2.insert(0, 0)
		else:
			ig_pipes2 = ig_pipes.copy()

		for ig_pipe2 in ig_pipes2:
			table = self.bfrt_info.table_get('%s.outer_fib.fib' % ictl_s[ig_pipe2])
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

def npb_lag_single_add(self, target, ig_pipe, port_lag_ptr, port_lag_member_ptr, port):
		# for our all-to-one program, need to edit the path to this table
		if(p4_name == 'pgm_mp_npb_igOnly_npb_igOnly_npb_igOnly_npb_egOnly_top'):
			ig_pipes2 = ig_pipes.copy()
			ig_pipes2.insert(0, 0)
		else:
			ig_pipes2 = ig_pipes.copy()

		try:
			# bottom
#			table = self.bfrt_info.table_get('%s.lag.lag_selector' % ictl_s[ig_pipe])
			table = self.bfrt_info.table_get('%s.lag.lag_action_profile' % ictl_s[ig_pipe])
			table.entry_add(
				target,
				[table.make_key(
					[gc.KeyTuple('$ACTION_MEMBER_ID',                port_lag_member_ptr)],
				)],
				[table.make_data(
					[gc.DataTuple('port',                            port)],
					'%s.lag.set_lag_port' % ictl_s[ig_pipe]
				)]
			)		

			# top
			table = self.bfrt_info.table_get('%s.lag.lag' % ictl_s[ig_pipe])
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
			print("A table operation failed. This is typically due to adding or removing a duplicate, and can be ignored 12.")

def npb_lag_single_del(self, target, ig_pipe, port_lag_ptr, port_lag_member_ptr):
		# for our all-to-one program, need to edit the path to this table
		if(p4_name == 'pgm_mp_npb_igOnly_npb_igOnly_npb_igOnly_npb_egOnly_top'):
			ig_pipes2 = ig_pipes.copy()
			ig_pipes2.insert(0, 0)
		else:
			ig_pipes2 = ig_pipes.copy()

		try:
			# top
			table = self.bfrt_info.table_get('%s.lag.lag' % ictl_s[ig_pipe])
			table.entry_del(
				target,
				[table.make_key(
					[gc.KeyTuple('port_lag_index',                   port_lag_ptr)],
				)]
			)

			# bottom
#			table = self.bfrt_info.table_get('%s.lag.lag_selector' % ictl_s[ig_pipe])
			table = self.bfrt_info.table_get('%s.lag.lag_action_profile' % ictl_s[ig_pipe])
			table.entry_del(
				target,
				[table.make_key(
					[gc.KeyTuple('$ACTION_MEMBER_ID',                port_lag_member_ptr)],
				)],
			)

		except:
			print("A table operation failed. This is typically due to adding or removing a duplicate, and can be ignored 12.")

########################################

def npb_lag_multi_add(self, target, ig_pipe, port_lag_ptr, port_lag_group_ptr, port_lag_member_ptr, port):
		# for our all-to-one program, need to edit the path to this table
		if(p4_name == 'pgm_mp_npb_igOnly_npb_igOnly_npb_igOnly_npb_egOnly_top'):
			ig_pipes2 = ig_pipes.copy()
			ig_pipes2.insert(0, 0)
		else:
			ig_pipes2 = ig_pipes.copy()

		port_lag_member_ptr_list = []
		port_lag_member_sts_list = []

		for i in range(len(port)):
			port_lag_member_ptr_list.append(port_lag_member_ptr+i)
			port_lag_member_sts_list.append(True)

		for i in range(len(port)):

			# bottom
#			table = self.bfrt_info.table_get('%s.lag.lag_selector' % ictl_s[ig_pipe])
			table = self.bfrt_info.table_get('%s.lag.lag_action_profile' % ictl_s[ig_pipe])
			table.entry_add(
				target,
				[table.make_key(
					[gc.KeyTuple('$ACTION_MEMBER_ID',                port_lag_member_ptr_list[i])],
				)],
				[table.make_data(
					[gc.DataTuple('port',                            port[i])],
					'%s.lag.set_lag_port' % ictl_s[ig_pipe]
				)]
			)

		# middle
#		table = self.bfrt_info.table_get('%s.lag.lag_selector_sel' % ictl_s[ig_pipe])
		table = self.bfrt_info.table_get('%s.lag.lag_selector' % ictl_s[ig_pipe])
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
		table = self.bfrt_info.table_get('%s.lag.lag' % ictl_s[ig_pipe])
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

def npb_lag_multi_del(self, target, ig_pipe, port_lag_ptr, port_lag_group_ptr, port_lag_member_ptr, port):
		# for our all-to-one program, need to edit the path to this table
		if(p4_name == 'pgm_mp_npb_igOnly_npb_igOnly_npb_igOnly_npb_egOnly_top'):
			ig_pipes2 = ig_pipes.copy()
			ig_pipes2.insert(0, 0)
		else:
			ig_pipes2 = ig_pipes.copy()

		port_lag_member_ptr_list = []

		for i in range(0, len(port)):
			port_lag_member_ptr_list.append(port_lag_member_ptr+i)

		# top
		table = self.bfrt_info.table_get('%s.lag.lag' % ictl_s[ig_pipe])
		table.entry_del(
			target,
			[table.make_key(
				[gc.KeyTuple('port_lag_index',                   port_lag_ptr)],
			)],
		)

		# middle
#		table = self.bfrt_info.table_get('%s.lag.lag_selector_sel' % ictl_s[ig_pipe])
		table = self.bfrt_info.table_get('%s.lag.lag_selector' % ictl_s[ig_pipe])
		table.entry_del(
			target,
			[table.make_key(
				[gc.KeyTuple('$SELECTOR_GROUP_ID',               port_lag_group_ptr)],
			)],
		)

		for i in range(0, len(port)):

			# bottom
#			table = self.bfrt_info.table_get('%s.lag.lag_selector' % ictl_s[ig_pipe])
			table = self.bfrt_info.table_get('%s.lag.lag_action_profile' % ictl_s[ig_pipe])
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

def npb_pre_mgid_add(self, target, ig_pipe, mgid, nodes):

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

def npb_pre_mgid_del(self, target, ig_pipe, mgid):

	table = self.bfrt_info.table_get("$pre.mgid")
	table.entry_del(
		target,
		[table.make_key(
			[gc.KeyTuple('$MGID',                         mgid)]
		)],
	)

########################################

# Level 2 (lower level)

def npb_pre_node_add(self, target, ig_pipe, node, rid, lags, ports):
	#print("pAttempting to add pre.node", node)
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

def npb_pre_node_del(self, target, ig_pipe, node):
	#print("pAttempting to delete pre.node", node)
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

def npb_pre_port_add(self, target, ig_pipe, port):
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

def npb_pre_port_del(self, target, ig_pipe, port):
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

def npb_pre_mirror_add(self, target, ig_pipe, session_id, direction, port): # direction = INGRESS or EGRESS
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

def npb_pre_mirror_del(self, target, ig_pipe, session_id):
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

def npb_egr_port_add(self, target, ig_pipe, port, eg_port_is_cpu, port_lag_ptr):

	for i in range(len(port)):

		try:

			if(eg_port_is_cpu):

				table = self.bfrt_info.table_get('%s.egress_port_mapping.port_mapping' % ectl_F)
				table.entry_add(
					target,
					[table.make_key(
						[gc.KeyTuple('port',                                      port[i])],
					)],
					[table.make_data(
						[gc.DataTuple('port_lag_index',                           port_lag_ptr)],
						'%s.egress_port_mapping.port_cpu' % ectl_F
					)]
				)

				if(PipelineParams.SPLIT_EG_PORT_TBL == True):
					table = self.bfrt_info.table_get('%s.cpu_rewrite.cpu_port_rewrite' % ectl_F)
					table.entry_add(
						target,
						[table.make_key(
							[gc.KeyTuple('port',                                      port[i])],
						)],
						[table.make_data(
							[],
							'%s.cpu_rewrite.cpu_rewrite' % ectl_F
						)]
					)

			else:

				table = self.bfrt_info.table_get('%s.egress_port_mapping.port_mapping' % ectl_F)
				table.entry_add(
					target,
					[table.make_key(
						[gc.KeyTuple('port',                                      port[i])],
					)],
					[table.make_data(
						[gc.DataTuple('port_lag_index',                           port_lag_ptr)],
						'%s.egress_port_mapping.port_normal' % ectl_F
					)]
				)
				'''
				if(PipelineParams.SPLIT_EG_PORT_TBL == True):
					table = self.bfrt_info.table_get('%s.cpu_rewrite.cpu_port_rewrite' % ectl_F)
					table.entry_add(
						target,
						[table.make_key(
							[gc.KeyTuple('port',                                      port[i])],
						)],
						[table.make_data(
							[],
							'%s.cpu_rewrite.normal_rewrite' % ectl_F
						)]
					)
				'''

		except:
			print("A table operation failed. This is typically due to adding or removing a duplicate, and can be ignored 13.")

def npb_egr_port_del(self, target, ig_pipe, port):

	for i in range(len(port)):

		try:

			table = self.bfrt_info.table_get('%s.egress_port_mapping.port_mapping' % ectl_F)
			table.entry_del(
				target,
				[table.make_key(
					[gc.KeyTuple('port',                                      port[i])],
				)]
			)

			if(PipelineParams.SPLIT_EG_PORT_TBL == True):
				table = self.bfrt_info.table_get('%s.cpu_rewrite.cpu_port_rewrite' % ectl_F)
				table.entry_del(
					target,
					[table.make_key(
					[gc.KeyTuple('port',                                      port[i])],
					)]
				)

		except:
			print("A table operation failed. This is typically due to adding or removing a duplicate, and can be ignored 13.")

########################################

def npb_egr_port_mirror_add(self, target, ig_pipe, port, session_id):

		table = self.bfrt_info.table_get('%s.egress_port_mapping.port_mirror.port_mirror' % ectl_F)
		table.entry_add(
			target,
			[table.make_key(
				[gc.KeyTuple('port',                             port)],
			)],
			[table.make_data(
				[gc.DataTuple('session_id',                      session_id)],
				'%s.egress_port_mapping.port_mirror.set_mirror_id' % ectl_F,
			)]
		)

def npb_egr_port_mirror_del(self, target, ig_pipe, port):

		table = self.bfrt_info.table_get('%s.egress_port_mapping.port_mirror.port_mirror' % ectl_F)
		table.entry_del(
			target,
			[table.make_key(
				[gc.KeyTuple('port',                             port)],
			)],
		)

########################################

def npb_mult_rid_identical_add(self, target, ig_pipe, rid, bd):

		table = self.bfrt_info.table_get('%s.multicast_replication.rid' % ectl_F)
		table.entry_add(
			target,
			[table.make_key(
				[gc.KeyTuple('replication_id',                   rid)],
			)],
			[table.make_data(
				[gc.DataTuple('bd',                              bd)],
				'%s.multicast_replication.rid_hit_identical_copies' % ectl_F,
			)]
		)

def npb_mult_rid_identical_del(self, target, ig_pipe, rid):

		table = self.bfrt_info.table_get('%s.multicast_replication.rid' % ectl_F)

		# read counter
		resp = table.entry_get(
			target,
			[table.make_key(
				[gc.KeyTuple('replication_id',                   rid)],
			)],
			{"from_hw": True},
			table.make_data(
				[gc.DataTuple("$COUNTER_SPEC_BYTES"),
				 gc.DataTuple("$COUNTER_SPEC_PKTS")],
				'%s.multicast_replication.rid_hit_identical_copies' % ectl_F,
				get=True
			)
		)

		data_dict = next(resp)[0].to_dict()
		recv_pkts = data_dict["$COUNTER_SPEC_PKTS"]
		recv_bytes = data_dict["$COUNTER_SPEC_BYTES"]

		print("Dumping npb_npb_sf1_multicast (egress) counters: pkts", recv_pkts, "bytes", recv_bytes)

		table.entry_del(
			target,
			[table.make_key(
				[gc.KeyTuple('replication_id',                   rid)],
			)],
		)

########################################

def npb_mult_rid_unique_add(self, target, ig_pipe, rid, bd, spi, si, nexthop_index, tunnel_index, outer_nexthop_index):

		table = self.bfrt_info.table_get('%s.multicast_replication.rid' % ectl_F)
		table.entry_add(
			target,
			[table.make_key(
				[gc.KeyTuple('replication_id',                   rid)],
			)],
			[table.make_data(
				[gc.DataTuple('bd',                              bd),
				 gc.DataTuple('spi',                             spi),
				 gc.DataTuple('si',                              si),
				 gc.DataTuple('nexthop_index',                   nexthop_index),
				 gc.DataTuple('tunnel_index',                    tunnel_index),
				 gc.DataTuple('outer_nexthop_index',             outer_nexthop_index)],
				'%s.multicast_replication.rid_hit_unique_copies' % ectl_F,
			)]
		)

def npb_mult_rid_unique_del(self, target, ig_pipe, rid):

		table = self.bfrt_info.table_get('%s.multicast_replication.rid' % ectl_F)

		# read counter
		resp = table.entry_get(
			target,
			[table.make_key(
				[gc.KeyTuple('replication_id',                   rid)],
			)],
			{"from_hw": True},
			table.make_data(
				[gc.DataTuple("$COUNTER_SPEC_BYTES"),
				 gc.DataTuple("$COUNTER_SPEC_PKTS")],
				'%s.multicast_replication.rid_hit_unique_copies' % ectl_F,
				get=True
			)
		)

		data_dict = next(resp)[0].to_dict()
		recv_pkts = data_dict["$COUNTER_SPEC_PKTS"]
		recv_bytes = data_dict["$COUNTER_SPEC_BYTES"]

		print("Dumping npb_npb_sf1_multicast (egress) counters: pkts", recv_pkts, "bytes", recv_bytes)

		# delete entry
		table.entry_del(
			target,
			[table.make_key(
				[gc.KeyTuple('replication_id',                   rid)],
			)],
		)

########################################

# egr sf #2: action select

def npb_npb_sf2_action_sel_add(self, target, ig_pipe, spi, si, bitmask, dsap):

	# for our folded program, need to edit the path to this table
	if(p4_name == 'pgm_fp_npb_dedup_dtel_vcpFw_top'):
		ectl_F_ = ectl_F.replace("_A_0", "_B_0")
	else:
		ectl_F_ = ectl_F

	try:

		table = self.bfrt_info.table_get('%s.npb_egr_top.npb_egr_sf_proxy_top.egr_sf_action_sel' % ectl_F_)
		table.entry_add(
			target,
			[table.make_key(
				[gc.KeyTuple('spi',                              spi),
				 gc.KeyTuple('si',                               si)],
			)],
			[table.make_data(
				[gc.DataTuple('dsap',                            dsap)],
				'%s.npb_egr_top.npb_egr_sf_proxy_top.egr_sf_action_sel_hit' % ectl_F_
			)]
		)
	except:
		print("A table operation failed. This is typically due to adding or removing a duplicate, and can be ignored 14.")

def npb_npb_sf2_action_sel_del(self, target, ig_pipe, spi, si):

	# for our the folded program, need to edit the path to this table
	if(p4_name == 'pgm_fp_npb_dedup_dtel_vcpFw_top'):
		ectl_F_ = ectl_F.replace("_A_0", "_B_0")
	else:
		ectl_F_ = ectl_F

	try:

		table = self.bfrt_info.table_get('%s.npb_egr_top.npb_egr_sf_proxy_top.egr_sf_action_sel' % ectl_F_)
		table.entry_del(
			target,
			[table.make_key(
				[gc.KeyTuple('spi',                              spi),
				 gc.KeyTuple('si',                               si)],
			)],
		)
	except:
		print("A table operation failed. This is typically due to adding or removing a duplicate, and can be ignored 14.")

########################################

# ing sf #2: ip_len range

def npb_npb_sf2_len_rng_add(self, target, ig_pipe, l3_len_lo, l3_len_hi, l3_len_rng):

	# for our folded program, need to edit the path to this table
	if(p4_name == 'pgm_fp_npb_dedup_dtel_vcpFw_top'):
		ectl_F_ = ectl_F.replace("_A_0", "_B_0")
	else:
		ectl_F_ = ectl_F

	try:
		table = self.bfrt_info.table_get('%s.npb_egr_top.npb_egr_sf_proxy_top.egr_sf_ip_len_rng' % ectl_F_)
		table.entry_add(
			target,
			[table.make_key(
				[gc.KeyTuple('ip_len',                              low=l3_len_lo, high=l3_len_hi)],
			)],
			[table.make_data(
				[gc.DataTuple('rng_bitmask',                        l3_len_rng)],
				'%s.npb_egr_top.npb_egr_sf_proxy_top.egr_sf_ip_len_rng_hit' % ectl_F_
			)]
		)
	except:
		pass

def npb_npb_sf2_len_rng_del(self, target, ig_pipe, l3_len_lo, l3_len_hi):

	# for our folded program, need to edit the path to this table
	if(p4_name == 'pgm_fp_npb_dedup_dtel_vcpFw_top'):
		ectl_F_ = ectl_F.replace("_A_0", "_B_0")
	else:
		ectl_F_ = ectl_F

	try:
		table = self.bfrt_info.table_get('%s.npb_egr_top.npb_egr_sf_proxy_top.egr_sf_ip_len_rng' % ectl_F_)
		table.entry_del(
			target,
			[table.make_key(
				[gc.KeyTuple('ip_len',                              low=l3_len_lo, high=l3_len_hi)],
			)],
		)
	except:
		pass

########################################

# ing sf #2: l4_src_port range

def npb_npb_sf2_l4_src_port_rng_add(self, target, ig_pipe, l3_len_lo, l3_len_hi, l3_len_rng):

	# for our folded program, need to edit the path to this table
	if(p4_name == 'pgm_fp_npb_dedup_dtel_vcpFw_top'):
		ectl_F_ = ectl_F.replace("_A_0", "_B_0")
	else:
		ectl_F_ = ectl_F

	try:
		table = self.bfrt_info.table_get('%s.npb_egr_top.npb_egr_sf_proxy_top.egr_sf_l4_src_port_rng' % ectl_F_)
		table.entry_add(
			target,
			[table.make_key(
				[gc.KeyTuple('l4_src_port',                         low=l3_len_lo, high=l3_len_hi)],
			)],
			[table.make_data(
				[gc.DataTuple('rng_bitmask',                        l3_len_rng)],
				'%s.npb_egr_top.npb_egr_sf_proxy_top.egr_sf_l4_src_port_rng_hit' % ectl_F_
			)]
		)
	except:
		pass

def npb_npb_sf2_l4_src_port_rng_del(self, target, ig_pipe, l3_len_lo, l3_len_hi):

	# for our folded program, need to edit the path to this table
	if(p4_name == 'pgm_fp_npb_dedup_dtel_vcpFw_top'):
		ectl_F_ = ectl_F.replace("_A_0", "_B_0")
	else:
		ectl_F_ = ectl_F

	try:
		table = self.bfrt_info.table_get('%s.npb_egr_top.npb_egr_sf_proxy_top.egr_sf_l4_src_port_rng' % ectl_F_)
		table.entry_del(
			target,
			[table.make_key(
				[gc.KeyTuple('l4_src_port',                         low=l3_len_lo, high=l3_len_hi)],
			)],
		)
	except:
		pass

########################################

# ing sf #2: l4_dst_port range

def npb_npb_sf2_l4_dst_port_rng_add(self, target, ig_pipe, l3_len_lo, l3_len_hi, l3_len_rng):

	# for our folded program, need to edit the path to this table
	if(p4_name == 'pgm_fp_npb_dedup_dtel_vcpFw_top'):
		ectl_F_ = ectl_F.replace("_A_0", "_B_0")
	else:
		ectl_F_ = ectl_F

	try:
		table = self.bfrt_info.table_get('%s.npb_egr_top.npb_egr_sf_proxy_top.egr_sf_l4_dst_port_rng' % ectl_F_)
		table.entry_add(
			target,
			[table.make_key(
				[gc.KeyTuple('l4_dst_port',                         low=l3_len_lo, high=l3_len_hi)],
			)],
			[table.make_data(
				[gc.DataTuple('rng_bitmask',                        l3_len_rng)],
				'%s.npb_egr_top.npb_egr_sf_proxy_top.egr_sf_l4_dst_port_rng_hit' % ectl_F_
			)]
		)
	except:
		pass

def npb_npb_sf2_l4_dst_port_rng_del(self, target, ig_pipe, l3_len_lo, l3_len_hi):

	# for our folded program, need to edit the path to this table
	if(p4_name == 'pgm_fp_npb_dedup_dtel_vcpFw_top'):
		ectl_F_ = ectl_F.replace("_A_0", "_B_0")
	else:
		ectl_F_ = ectl_F

	try:
		table = self.bfrt_info.table_get('%s.npb_egr_top.npb_egr_sf_proxy_top.egr_sf_l4_dst_port_rng' % ectl_F_)
		table.entry_del(
			target,
			[table.make_key(
				[gc.KeyTuple('l4_dst_port',                         low=l3_len_lo, high=l3_len_hi)],
			)],
		)
	except:
		pass

########################################

# egr sf #2: policy l2

def npb_npb_sf2_policy_l2_add(self, target, ig_pipe,
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
		mirror_enable   = 0, mirror_id           = 0,
		cpu_reason_code = 0
		):

	# for our folded program, need to edit the path to this table
	if(p4_name == 'pgm_fp_npb_dedup_dtel_vcpFw_top'):
		ectl_F_ = ectl_F.replace("_A_0", "_B_0")
	else:
		ectl_F_ = ectl_F

	try:
		table = self.bfrt_info.table_get('%s.npb_egr_top.npb_egr_sf_proxy_top.acl.egress_mac_acl.acl' % ectl_F_)
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
				 gc.DataTuple('mirror_enable',                   mirror_enable),
				 gc.DataTuple('mirror_session_id',               mirror_id),
				 gc.DataTuple('cpu_reason_code',                 cpu_reason_code)],
				'%s.npb_egr_top.npb_egr_sf_proxy_top.acl.egress_mac_acl.hit' % ectl_F_
			)]
		)
	except:
		pass

def npb_npb_sf2_policy_l2_del(self, target, ig_pipe,
		dsap            = 0, dsap_mask           = 0x03ff,
		l2_etype        = 0, l2_etype_mask       = 0,
		tun_type        = 0, tun_type_mask       = 0
		):

	# for our folded program, need to edit the path to this table
	if(p4_name == 'pgm_fp_npb_dedup_dtel_vcpFw_top'):
		ectl_F_ = ectl_F.replace("_A_0", "_B_0")
	else:
		ectl_F_ = ectl_F

	try:
		table = self.bfrt_info.table_get('%s.npb_egr_top.npb_egr_sf_proxy_top.acl.egress_mac_acl.acl' % ectl_F_)

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
				'%s.npb_egr_top.npb_egr_sf_proxy_top.acl.egress_mac_acl.hit' % ectl_F_,
				get=True
			)
		)

		data_dict = next(resp)[0].to_dict()
		recv_pkts = data_dict["$COUNTER_SPEC_PKTS"]
		recv_bytes = data_dict["$COUNTER_SPEC_BYTES"]

		print("Dumping npb_npb_sf2_policy_l2 counters: pkts", recv_pkts, "bytes", recv_bytes)

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
	except:
		pass

########################################

# egr sf #2: policy l3 v4

def npb_npb_sf2_policy_l34_v4_add(self, target, ig_pipe,
		dsap            = 0, dsap_mask           = 0x03ff,
		l3_len          = 0, l3_len_mask         = 0,
		l3_len_rng      = 0, l3_len_rng_mask     = 0,
		l3_proto        = 0, l3_proto_mask       = 0,
		l4_src          = 0, l4_src_mask         = 0,
		l4_src_rng      = 0, l4_src_rng_mask     = 0,
		l4_dst          = 0, l4_dst_mask         = 0,
		l4_dst_rng      = 0, l4_dst_rng_mask     = 0,
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
		mirror_enable   = 0, mirror_id           = 0,
		cpu_reason_code = 0
		):

	# for our folded program, need to edit the path to this table
	if(p4_name == 'pgm_fp_npb_dedup_dtel_vcpFw_top'):
		ectl_F_ = ectl_F.replace("_A_0", "_B_0")
	else:
		ectl_F_ = ectl_F

	try:
		table = self.bfrt_info.table_get('%s.npb_egr_top.npb_egr_sf_proxy_top.acl.egress_ipv4_acl.acl' % ectl_F_)
		table.entry_add(
			target,
			[table.make_key(
				[gc.KeyTuple('dsap',                             dsap,           dsap_mask),
				 gc.KeyTuple('lkp.ip_len',                       l3_len,         l3_len_mask),
				 gc.KeyTuple('lkp.ip_len_rng',                   l3_len_rng,     l3_len_rng_mask),
				 gc.KeyTuple('lkp.ip_proto',                     l3_proto,       l3_proto_mask),
				 gc.KeyTuple('lkp.ip_src_addr[31:0]',            gc.ipv4_to_bytes('0.0.0.0'), 0),
				 gc.KeyTuple('lkp.ip_dst_addr[31:0]',            gc.ipv4_to_bytes('0.0.0.0'), 0),
				 gc.KeyTuple('lkp.l4_src_port',                  l4_src,         l4_src_mask),
				 gc.KeyTuple('lkp.l4_src_port_rng',              l4_src_rng,     l4_src_rng_mask),
				 gc.KeyTuple('lkp.l4_dst_port',                  l4_dst,         l4_dst_mask),
				 gc.KeyTuple('lkp.l4_dst_port_rng',              l4_dst_rng,     l4_dst_rng_mask),
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
				 gc.DataTuple('mirror_enable',                   mirror_enable),
				 gc.DataTuple('mirror_session_id',               mirror_id),
				 gc.DataTuple('cpu_reason_code',                 cpu_reason_code)],
				'%s.npb_egr_top.npb_egr_sf_proxy_top.acl.egress_ipv4_acl.hit' % ectl_F_
			)]
		)
	except:
		pass

def npb_npb_sf2_policy_l34_v4_del(self, target, ig_pipe,
		dsap            = 0, dsap_mask           = 0x03ff,
		l3_len          = 0, l3_len_mask         = 0,
		l3_len_rng      = 0, l3_len_rng_mask     = 0,
		l3_proto        = 0, l3_proto_mask       = 0,
		l4_src          = 0, l4_src_mask         = 0,
		l4_src_rng      = 0, l4_src_rng_mask     = 0,
		l4_dst          = 0, l4_dst_mask         = 0,
		l4_dst_rng      = 0, l4_dst_rng_mask     = 0,
		tun_type        = 0, tun_type_mask       = 0
		):

	# for our folded program, need to edit the path to this table
	if(p4_name == 'pgm_fp_npb_dedup_dtel_vcpFw_top'):
		ectl_F_ = ectl_F.replace("_A_0", "_B_0")
	else:
		ectl_F_ = ectl_F

	try:
		table = self.bfrt_info.table_get('%s.npb_egr_top.npb_egr_sf_proxy_top.acl.egress_ipv4_acl.acl' % ectl_F_)
		# read counter
		resp = table.entry_get(
			target,
			[table.make_key(
				[gc.KeyTuple('dsap',                             dsap,           dsap_mask),
				 gc.KeyTuple('lkp.ip_len',                       l3_len,         l3_len_mask),
				 gc.KeyTuple('lkp.ip_len_rng',                   l3_len_rng,     l3_len_rng_mask),
				 gc.KeyTuple('lkp.ip_proto',                     l3_proto,       l3_proto_mask),
				 gc.KeyTuple('lkp.ip_src_addr[31:0]',            gc.ipv4_to_bytes('0.0.0.0'), 0),
				 gc.KeyTuple('lkp.ip_dst_addr[31:0]',            gc.ipv4_to_bytes('0.0.0.0'), 0),
				 gc.KeyTuple('lkp.l4_src_port',                  l4_src,         l4_src_mask),
				 gc.KeyTuple('lkp.l4_src_port_rng',              l4_src_rng,     l4_src_rng_mask),
				 gc.KeyTuple('lkp.l4_dst_port',                  l4_dst,         l4_dst_mask),
				 gc.KeyTuple('lkp.l4_dst_port_rng',              l4_dst_rng,     l4_dst_rng_mask),
				 gc.KeyTuple('lkp.tunnel_type',                  tun_type,       tun_type_mask)],
			)],
			{"from_hw": True},
			table.make_data(
				[gc.DataTuple("$COUNTER_SPEC_BYTES"),
				 gc.DataTuple("$COUNTER_SPEC_PKTS")],
				'%s.npb_egr_top.npb_egr_sf_proxy_top.acl.egress_ipv4_acl.hit' % ectl_F_,
				get=True
			)
		)

		data_dict = next(resp)[0].to_dict()
		recv_pkts = data_dict["$COUNTER_SPEC_PKTS"]
		recv_bytes = data_dict["$COUNTER_SPEC_BYTES"]

		print("Dumping npb_npb_sf2_policy_l34_v4 counters: pkts", recv_pkts, "bytes", recv_bytes)

		# delete entry
		table.entry_del(
			target,
			[table.make_key(
				[gc.KeyTuple('dsap',                             dsap,           dsap_mask),
				 gc.KeyTuple('lkp.ip_len',                       l3_len,         l3_len_mask),
				 gc.KeyTuple('lkp.ip_len_rng',                   l3_len_rng,     l3_len_rng_mask),
				 gc.KeyTuple('lkp.ip_proto',                     l3_proto,       l3_proto_mask),
				 gc.KeyTuple('lkp.ip_src_addr[31:0]',            gc.ipv4_to_bytes('0.0.0.0'), 0),
				 gc.KeyTuple('lkp.ip_dst_addr[31:0]',            gc.ipv4_to_bytes('0.0.0.0'), 0),
				 gc.KeyTuple('lkp.l4_src_port',                  l4_src,         l4_src_mask),
				 gc.KeyTuple('lkp.l4_src_port_rng',              l4_src_rng,     l4_src_rng_mask),
				 gc.KeyTuple('lkp.l4_dst_port',                  l4_dst,         l4_dst_mask),
				 gc.KeyTuple('lkp.l4_dst_port_rng',              l4_dst_rng,     l4_dst_rng_mask),
				 gc.KeyTuple('lkp.tunnel_type',                  tun_type,       tun_type_mask)],
			)],
		)
	except:
		pass

########################################

# egr sf #2: policy l3 v6

def npb_npb_sf2_policy_l34_v6_add(self, target, ig_pipe,
		dsap            = 0, dsap_mask           = 0x03ff,
		l3_len          = 0, l3_len_mask         = 0,
		l3_len_rng      = 0, l3_len_rng_mask     = 0,
		l3_proto        = 0, l3_proto_mask       = 0,
		l4_src          = 0, l4_src_mask         = 0,
		l4_src_rng      = 0, l4_src_rng_mask     = 0,
		l4_dst          = 0, l4_dst_mask         = 0,
		l4_dst_rng      = 0, l4_dst_rng_mask     = 0,
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
		mirror_enable   = 0, mirror_id           = 0,
		cpu_reason_code = 0
		):

	# for our folded program, need to edit the path to this table
	if(p4_name == 'pgm_fp_npb_dedup_dtel_vcpFw_top'):
		ectl_F_ = ectl_F.replace("_A_0", "_B_0")
	else:
		ectl_F_ = ectl_F

	try:
		table = self.bfrt_info.table_get('%s.npb_egr_top.npb_egr_sf_proxy_top.acl.egress_ipv6_acl.acl' % ectl_F_)
		table.entry_add(
			target,
			[table.make_key(
				[gc.KeyTuple('dsap',                             dsap,           dsap_mask),
				 gc.KeyTuple('lkp.ip_len',                       l3_len,         l3_len_mask),
				 gc.KeyTuple('lkp.ip_len_rng',                   l3_len_rng,     l3_len_rng_mask),
				 gc.KeyTuple('lkp.ip_proto',                     l3_proto,       l3_proto_mask),
				 gc.KeyTuple('lkp.ip_src_addr',                  0,              0),
				 gc.KeyTuple('lkp.ip_dst_addr',                  0,              0),
				 gc.KeyTuple('lkp.l4_src_port',                  l4_src,         l4_src_mask),
				 gc.KeyTuple('lkp.l4_src_port_rng',              l4_src_rng,     l4_src_rng_mask),
				 gc.KeyTuple('lkp.l4_dst_port',                  l4_dst,         l4_dst_mask),
				 gc.KeyTuple('lkp.l4_dst_port_rng',              l4_dst_rng,     l4_dst_rng_mask),
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
				 gc.DataTuple('mirror_enable',                   mirror_enable),
				 gc.DataTuple('mirror_session_id',               mirror_id),
				 gc.DataTuple('cpu_reason_code',                 cpu_reason_code)],
				'%s.npb_egr_top.npb_egr_sf_proxy_top.acl.egress_ipv6_acl.hit' % ectl_F_
			)]
		)
	except:
		pass

def npb_npb_sf2_policy_l34_v6_del(self, target, ig_pipe,
		dsap            = 0, dsap_mask           = 0x03ff,
		l3_len          = 0, l3_len_mask         = 0,
		l3_len_rng      = 0, l3_len_rng_mask     = 0,
		l3_proto        = 0, l3_proto_mask       = 0,
		l4_src          = 0, l4_src_mask         = 0,
		l4_src_rng      = 0, l4_src_rng_mask     = 0,
		l4_dst          = 0, l4_dst_mask         = 0,
		l4_dst_rng      = 0, l4_dst_rng_mask     = 0,
		tun_type        = 0, tun_type_mask       = 0
		):

	# for our folded program, need to edit the path to this table
	if(p4_name == 'pgm_fp_npb_dedup_dtel_vcpFw_top'):
		ectl_F_ = ectl_F.replace("_A_0", "_B_0")
	else:
		ectl_F_ = ectl_F

	try:
		table = self.bfrt_info.table_get('%s.npb_egr_top.npb_egr_sf_proxy_top.acl.egress_ipv6_acl.acl' % ectl_F_)

		# read counter
		resp = table.entry_get(
			target,
			[table.make_key(
				[gc.KeyTuple('dsap',                             dsap,           dsap_mask),
				 gc.KeyTuple('lkp.ip_len',                       l3_len,         l3_len_mask),
				 gc.KeyTuple('lkp.ip_len_rng',                   l3_len_rng,     l3_len_rng_mask),
				 gc.KeyTuple('lkp.ip_proto',                     l3_proto,       l3_proto_mask),
				 gc.KeyTuple('lkp.ip_src_addr',                  0,              0),
				 gc.KeyTuple('lkp.ip_dst_addr',                  0,              0),
				 gc.KeyTuple('lkp.l4_src_port',                  l4_src,         l4_src_mask),
				 gc.KeyTuple('lkp.l4_src_port_rng',              l4_src_rng,     l4_src_rng_mask),
				 gc.KeyTuple('lkp.l4_dst_port',                  l4_dst,         l4_dst_mask),
				 gc.KeyTuple('lkp.l4_dst_port_rng',              l4_dst_rng,     l4_dst_rng_mask),
				 gc.KeyTuple('lkp.tunnel_type',                  tun_type,       tun_type_mask)],
			)],
			{"from_hw": True},
			table.make_data(
				[gc.DataTuple("$COUNTER_SPEC_BYTES"),
				 gc.DataTuple("$COUNTER_SPEC_PKTS")],
				'%s.npb_egr_top.npb_egr_sf_proxy_top.acl.egress_ipv6_acl.hit' % ectl_F_,
				get=True
			)
		)

		data_dict = next(resp)[0].to_dict()
		recv_pkts = data_dict["$COUNTER_SPEC_PKTS"]
		recv_bytes = data_dict["$COUNTER_SPEC_BYTES"]

		print("Dumping npb_npb_sf2_policy_l34_v6 counters: pkts", recv_pkts, "bytes", recv_bytes)

		# delete entry
		table.entry_del(
			target,
			[table.make_key(
				[gc.KeyTuple('dsap',                             dsap,           dsap_mask),
				 gc.KeyTuple('lkp.ip_len',                       l3_len,         l3_len_mask),
				 gc.KeyTuple('lkp.ip_len_rng',                   l3_len_rng,     l3_len_rng_mask),
				 gc.KeyTuple('lkp.ip_proto',                     l3_proto,       l3_proto_mask),
				 gc.KeyTuple('lkp.ip_src_addr',                  0,              0),
				 gc.KeyTuple('lkp.ip_dst_addr',                  0,              0),
				 gc.KeyTuple('lkp.l4_src_port',                  l4_src,         l4_src_mask),
				 gc.KeyTuple('lkp.l4_src_port_rng',              l4_src_rng,     l4_src_rng_mask),
				 gc.KeyTuple('lkp.l4_dst_port',                  l4_dst,         l4_dst_mask),
				 gc.KeyTuple('lkp.l4_dst_port_rng',              l4_dst_rng,     l4_dst_rng_mask),
				 gc.KeyTuple('lkp.tunnel_type',                  tun_type,       tun_type_mask)],
			)],
		)
	except:
		pass

########################################

def npb_npb_sf2_policy_hdr_edit_add(self, target, ig_pipe,
		bd  = 0,
		pcp = 0,
		vid = 0
		):

	# for our folded program, need to edit the path to this table
	if(p4_name == 'pgm_fp_npb_dedup_dtel_vcpFw_top'):
		ectl_F_ = ectl_F.replace("_A_0", "_B_0")
	else:
		ectl_F_ = ectl_F

	try:
		table = self.bfrt_info.table_get('%s.npb_egr_top.npb_egr_sf_proxy_top.npb_egr_sf_proxy_hdr_edit.bd_to_vlan_mapping' % ectl_F_)
		table.entry_add(
			target,
			[table.make_key(
				[gc.KeyTuple('bd',                               bd)],
			)],
			[table.make_data(
				[gc.DataTuple('pcp',                             pcp),
				 gc.DataTuple('vid',                             vid)],
				'%s.npb_egr_top.npb_egr_sf_proxy_top.npb_egr_sf_proxy_hdr_edit.set_vlan_tagged' % ectl_F_
			)]
		)
	except:
		pass

def npb_npb_sf2_policy_hdr_edit_del(self, target, ig_pipe,
		bd  = 0
		):

	# for our folded program, need to edit the path to this table
	if(p4_name == 'pgm_fp_npb_dedup_dtel_vcpFw_top'):
		ectl_F_ = ectl_F.replace("_A_0", "_B_0")
	else:
		ectl_F_ = ectl_F

	try:
		table = self.bfrt_info.table_get('%s.npb_egr_top.npb_egr_sf_proxy_top.npb_egr_sf_proxy_hdr_edit.bd_to_vlan_mapping' % ectl_F_)
		table.entry_del(
			target,
			[table.make_key(
				[gc.KeyTuple('bd',                               bd)],
			)],
		)
	except:
		pass

########################################

def npb_egr_sff_fib_nshtype1_add(self, target, ig_pipe,
		spi  = 0,
		si = 0,
		ta = 0
		):

		table = self.bfrt_info.table_get('%s.npb_egr_top.npb_egr_sff_top.egr_sff_fib' % ectl)
		table.entry_add(
			target,
			[table.make_key(
				[gc.KeyTuple('spi',                             spi),
				 gc.KeyTuple('si',                               si)],
			)],
			[table.make_data(
				[gc.DataTuple('tool_address',                               ta)],
				'%s.npb_egr_top.npb_egr_sff_top.fwd_pkt_nsh_hdr_ver_1' % ectl
			)]
		)

def npb_egr_sff_fib_nshtype1_del(self, target, ig_pipe,
		spi  = 0,
		si = 0
		):

		table = self.bfrt_info.table_get('%s.npb_egr_top.npb_egr_sff_top.egr_sff_fib' % ectl)
		table.entry_del(
			target,
			[table.make_key(
				[gc.KeyTuple('spi',                               spi),
				gc.KeyTuple('si',                                 si)],
			)],
		)

########################################

# currently unused (we are now always doing encaps, never rewrites)

def npb_rewrite_bd_mapping_add(self, target, ig_pipe, bd, smac_ptr):
		self.insert_table_entry(
			target,
			'%s.rewrite.egress_bd.bd_mapping' % ectl,
			[self.KeyField('bd',                               self.to_bytes(bd, 2))],
			'%s.rewrite.egress_bd.set_bd_properties' % ectl,
			[self.DataField('smac_index',                      self.to_bytes(smac_ptr, 2))])

def npb_rewrite_bd_mapping_del(self, target, ig_pipe, bd):
		self.delete_table_entry(
			target,
			'%s.rewrite.egress_bd.bd_mapping' % ectl,
			[self.KeyField('bd',                               self.to_bytes(bd, 2))])

########################################

# currently unused (we are now always doing encaps, never rewrites)

def npb_rewrite_smac_rewrite_add(self, target, ig_pipe, smac_ptr, smac):
		self.insert_table_entry(
			target,
			'%s.rewrite.smac_rewrite' % ectl,
			[self.KeyField('smac_index',                       self.to_bytes(smac_ptr, 2))],
			'%s.rewrite.rewrite_smac' % ectl,
			[self.DataField('smac',                            self.mac_to_bytes(smac))])

def npb_rewrite_smac_rewrite_del(self, target, ig_pipe, smac_ptr):
		self.delete_table_entry(
			target,
			'%s.rewrite.smac_rewrite' % ectl,
			[self.KeyField('smac_index',                       self.to_bytes(smac_ptr, 2))])

########################################

# this is a constant table (barefoot should really hard-code this, not sure why they dont)

# so here we just program up all the tunnel types -- add more as needed

def npb_tunnel_encap_add(self, target):
	try:

		table = self.bfrt_info.table_get('%s.tunnel_encap.tunnel' % ectl)
		table.entry_add(
			target,
			[table.make_key(
				[gc.KeyTuple('tunnel_.type',                     EgressTunnelType.NSH.value)],
			)],
			[table.make_data(
				[],
				'%s.tunnel_encap.rewrite_mac_in_mac' % ectl
			)]
		)

		table = self.bfrt_info.table_get('%s.tunnel_encap.tunnel' % ectl)
		table.entry_add(
			target,
			[table.make_key(
				[gc.KeyTuple('tunnel_.type',                     EgressTunnelType.IPV4_GRE.value)],
			)],
			[table.make_data(
				[],
				'%s.tunnel_encap.rewrite_ipv4_gre' % ectl
			)]
		)

		table = self.bfrt_info.table_get('%s.tunnel_encap.tunnel' % ectl)
		table.entry_add(
			target,
			[table.make_key(
				[gc.KeyTuple('tunnel_.type',                     EgressTunnelType.IPV6_GRE.value)],
			)],
			[table.make_data(
				[],
				'%s.tunnel_encap.rewrite_ipv6_gre' % ectl
			)]
		)
		'''
		table = self.bfrt_info.table_get('%s.tunnel_encap.tunnel' % ectl)
		table.entry_add(
			target,
			[table.make_key(
				[gc.KeyTuple('tunnel_.type',                     EgressTunnelType.IPV4_ERSPAN.value)],
			)],
			[table.make_data(
				[],
				'%s.tunnel_encap.rewrite_ipv4_erspan' % ectl
			)]
		)
		'''
		table = self.bfrt_info.table_get('%s.tunnel_encap.tunnel' % ectl)
		table.entry_add(
			target,
			[table.make_key(
				[gc.KeyTuple('tunnel_.type',                     EgressTunnelType.IPV4_UDP.value)],
			)],
			[table.make_data(
				[],
				'%s.tunnel_encap.rewrite_ipv4_udp' % ectl
			)]
		)

	except:
		print("A table operation failed. This is typically due to adding or removing a duplicate, and can be ignored 15.")

def npb_tunnel_encap_del(self, target):
	try:

		table = self.bfrt_info.table_get('%s.tunnel_encap.tunnel' % ectl)
		table.entry_del(
			target,
			[table.make_key(
				[gc.KeyTuple('tunnel_.type',                     EgressTunnelType.NSH.value)],
			)]
		)

		table = self.bfrt_info.table_get('%s.tunnel_encap.tunnel' % ectl)
		table.entry_del(
			target,
			[table.make_key(
				[gc.KeyTuple('tunnel_.type',                     EgressTunnelType.IPV4_GRE.value)],
			)]
		)

		table = self.bfrt_info.table_get('%s.tunnel_encap.tunnel' % ectl)
		table.entry_del(
			target,
			[table.make_key(
				[gc.KeyTuple('tunnel_.type',                     EgressTunnelType.IPV6_GRE.value)],
			)]
		)
		'''
		table = self.bfrt_info.table_get('%s.tunnel_encap.tunnel' % ectl)
		table.entry_del(
			target,
			[table.make_key(
				[gc.KeyTuple('tunnel_.type',                     EgressTunnelType.IPV4_ERSPAN.value)],
			)]
		)
		'''
		table = self.bfrt_info.table_get('%s.tunnel_encap.tunnel' % ectl)
		table.entry_del(
			target,
			[table.make_key(
				[gc.KeyTuple('tunnel_.type',                     EgressTunnelType.IPV4_UDP.value)],
			)]
		)

	except:
		print("A table operation failed. This is typically due to adding or removing a duplicate, and can be ignored 15.")

########################################

def npb_tunnel_encap_nexthop_rewrite_add(self, target, ig_pipe, outer_nexthop_ptr, bd, dmac):
	try:

		table = self.bfrt_info.table_get('%s.tunnel_rewrite.nexthop_rewrite' % ectl)
		table.entry_add(
			target,
			[table.make_key(
				[gc.KeyTuple('eg_md.outer_nexthop',              outer_nexthop_ptr)],
			)],
			[table.make_data(
				[gc.DataTuple('bd',                              bd),
				 gc.DataTuple('dmac',                            gc.mac_to_bytes(dmac))],
				'%s.tunnel_rewrite.rewrite_tunnel' % ectl
			)]
		)

	except:
		print("A table operation failed. This is typically due to adding or removing a duplicate, and can be ignored 16.")

def npb_tunnel_encap_nexthop_rewrite_del(self, target, ig_pipe, outer_nexthop_ptr):
	try:

		table = self.bfrt_info.table_get('%s.tunnel_rewrite.nexthop_rewrite' % ectl)
		table.entry_del(
			target,
			[table.make_key(
				[gc.KeyTuple('eg_md.outer_nexthop',              outer_nexthop_ptr)],
			)]
		)

	except:
		print("A table operation failed. This is typically due to adding or removing a duplicate, and can be ignored 16.")

########################################

def npb_tunnel_encap_bd_mapping_add(self, target, ig_pipe, bd, smac_ptr):
	try:

		table = self.bfrt_info.table_get('%s.tunnel_rewrite.egress_bd.bd_mapping' % ectl)
		table.entry_add(
			target,
			[table.make_key(
				[gc.KeyTuple('bd',                               bd)],
			)],
			[table.make_data(
				[gc.DataTuple('smac_index',                      smac_ptr)],
				'%s.tunnel_rewrite.egress_bd.set_bd_properties' % ectl
			)]
		)

	except:
		print("A table operation failed. This is typically due to adding or removing a duplicate, and can be ignored 17.")

def npb_tunnel_encap_bd_mapping_del(self, target, ig_pipe, bd):
	try:

		table = self.bfrt_info.table_get('%s.tunnel_rewrite.egress_bd.bd_mapping' % ectl)
		table.entry_del(
			target,
			[table.make_key(
				[gc.KeyTuple('bd',                               bd)],
			)]
		)

	except:
		print("A table operation failed. This is typically due to adding or removing a duplicate, and can be ignored 17.")

########################################

def npb_tunnel_encap_sip_rewrite_v4_add(self, target, ig_pipe, bd, sip):

		table = self.bfrt_info.table_get('%s.tunnel_rewrite.src_addr_rewrite' % ectl)
		table.entry_add(
			target,
			[table.make_key(
				[gc.KeyTuple('eg_md.bd',                         bd)],
			)],
			[table.make_data(
				[gc.DataTuple('src_addr',                        gc.ipv4_to_bytes(sip))],
				'%s.tunnel_rewrite.rewrite_ipv4_src' % ectl
			)]
		)

def npb_tunnel_encap_sip_rewrite_v4_del(self, target, ig_pipe, bd):

		table = self.bfrt_info.table_get('%s.tunnel_rewrite.src_addr_rewrite' % ectl)
		table.entry_del(
			target,
			[table.make_key(
				[gc.KeyTuple('eg_md.bd',                         bd)],
			)]
		)

########################################

def npb_tunnel_encap_sip_rewrite_v6_add(self, target, ig_pipe, bd, sip):

		table = self.bfrt_info.table_get('%s.tunnel_rewrite.src_addr_rewrite' % ectl)
		table.entry_add(
			target,
			[table.make_key(
				[gc.KeyTuple('eg_md.bd',                         bd)],
			)],
			[table.make_data(
				[gc.DataTuple('src_addr',                        gc.ipv6_to_bytes(sip))],
				'%s.tunnel_rewrite.rewrite_ipv6_src' % ectl
			)]
		)

def npb_tunnel_encap_sip_rewrite_v6_del(self, target, ig_pipe, bd):

		table = self.bfrt_info.table_get('%s.tunnel_rewrite.src_addr_rewrite' % ectl)
		table.entry_del(
			target,
			[table.make_key(
				[gc.KeyTuple('eg_md.bd',                         bd)],
			)]
		)

########################################

def npb_tunnel_encap_dip_rewrite_v4_add(self, target, ig_pipe, tunnel_ptr, dip):

		table = self.bfrt_info.table_get('%s.tunnel_rewrite.ipv4_dst_addr_rewrite' % ectl)
		table.entry_add(
			target,
			[table.make_key(
				[gc.KeyTuple('tunnel.index',                     tunnel_ptr)], # aka dip_index!!!
			)],
			[table.make_data(
				[gc.DataTuple('dst_addr',                        gc.ipv4_to_bytes(dip))],
				'%s.tunnel_rewrite.rewrite_ipv4_dst' % ectl
			)]
		)

def npb_tunnel_encap_dip_rewrite_v4_del(self, target, ig_pipe, tunnel_ptr):

		table = self.bfrt_info.table_get('%s.tunnel_rewrite.ipv4_dst_addr_rewrite' % ectl)
		table.entry_del(
			target,
			[table.make_key(
				[gc.KeyTuple('tunnel.index',                     tunnel_ptr)], # aka dip_index!!!
			)]
		)

########################################

def npb_tunnel_encap_dip_rewrite_v6_add(self, target, ig_pipe, tunnel_ptr, dip):

		table = self.bfrt_info.table_get('%s.tunnel_rewrite.ipv6_dst_addr_rewrite' % ectl)
		table.entry_add(
			target,
			[table.make_key(
				[gc.KeyTuple('tunnel.index',                     tunnel_ptr)], # aka dip_index!!!
			)],
			[table.make_data(
				[gc.DataTuple('dst_addr',                        gc.ipv6_to_bytes(dip))],
				'%s.tunnel_rewrite.rewrite_ipv6_dst' % ectl
			)]
		)

def npb_tunnel_encap_dip_rewrite_v6_del(self, target, ig_pipe, tunnel_ptr):

		table = self.bfrt_info.table_get('%s.tunnel_rewrite.ipv6_dst_addr_rewrite' % ectl)
		table.entry_del(
			target,
			[table.make_key(
				[gc.KeyTuple('tunnel.index',                     tunnel_ptr)], # aka dip_index!!!
			)]
		)

########################################

def npb_tunnel_encap_smac_rewrite_add(self, target, ig_pipe, smac_ptr, smac):
	try:

		table = self.bfrt_info.table_get('%s.tunnel_rewrite.smac_rewrite' % ectl)
		table.entry_add(
			target,
			[table.make_key(
				[gc.KeyTuple('smac_index',                       smac_ptr)],
			)],
			[table.make_data(
				[gc.DataTuple('smac',                            gc.mac_to_bytes(smac))],
				'%s.tunnel_rewrite.rewrite_smac' % ectl
			)]
		)

	except:
		print("A table operation failed. This is typically due to adding or removing a duplicate, and can be ignored 18.")

def npb_tunnel_encap_smac_rewrite_del(self, target, ig_pipe, smac_ptr):
	try:

		table = self.bfrt_info.table_get('%s.tunnel_rewrite.smac_rewrite' % ectl)
		table.entry_del(
			target,
			[table.make_key(
				[gc.KeyTuple('smac_index',                       smac_ptr)],
			)]
		)

	except:
		print("A table operation failed. This is typically due to adding or removing a duplicate, and can be ignored 18.")

########################################

def npb_port_bd_to_vlan_add(self, target, ig_pipe, port_lag_index, bd, vid, pcp):

		table = self.bfrt_info.table_get('%s.vlan_xlate.port_bd_to_vlan_mapping' % ectl)
		table.entry_add(
			target,
			[table.make_key(
				[gc.KeyTuple('port_lag_index',                   por_lag_index),
				 gc.KeyTuple('bd',                               bd)],
			)],
			[table.make_data(
				[gc.DataTuple('vid',                             vid),
				 gc.DataTuple('pcp',                             pcp)],
				'%s.vlan_xlate.set_vlan_tagged' % ectl
			)]
		)

def npb_port_bd_to_vlan_del(self, target, ig_pipe, port_lag_index, bd):

		table = self.bfrt_info.table_get('%s.vlan_xlate.port_bd_to_vlan_mapping' % ectl)
		table.entry_del(
			target,
			[table.make_key(
				[gc.KeyTuple('bd',                               bd)],
			)],
		)

########################################

def npb_bd_to_vlan_add(self, target, ig_pipe, bd, vid, pcp):

		table = self.bfrt_info.table_get('%s.vlan_xlate.bd_to_vlan_mapping' % ectl)
		table.entry_add(
			target,
			[table.make_key(
				[gc.KeyTuple('bd',                               bd)],
			)],
			[table.make_data(
				[gc.DataTuple('vid',                             vid),
				 gc.DataTuple('pcp',                             pcp)],
				'%s.vlan_xlate.set_vlan_tagged' % ectl
			)]
		)

def npb_bd_to_vlan_del(self, target, ig_pipe, bd):

		table = self.bfrt_info.table_get('%s.vlan_xlate.bd_to_vlan_mapping' % ectl)
		table.entry_del(
			target,
			[table.make_key(
				[gc.KeyTuple('bd',                               bd)],
			)],
		)

########################################

def dtel_flow_report_array1_add(self, target, ig_pipe,
	index               = 0,
	data                = 0
):

		table = self.bfrt_info.table_get('%s.dtel.flow_report0.array1' % ectl)
		table.entry_add(
			target,
			[table.make_key(
				[gc.KeyTuple('$REGISTER_INDEX',                  index)]
			)],
			[table.make_data(
				[gc.DataTuple('%s.dtel.flow_report0.array1.f1'  % ectl, data)]
			)]
		)

def dtel_flow_report_array1_del(self, target, ig_pipe,
	index               = 0
):
		
		table = self.bfrt_info.table_get('%s.dtel.flow_report0.array1' % ectl)
		table.entry_del(
			target,
			[table.make_key(
				[gc.KeyTuple('$REGISTER_INDEX',                  index)]
			)],
		)


########################################

def dtel_flow_report_array2_add(self, target, ig_pipe,
	index               = 0,
	data                = 0
):

		table = self.bfrt_info.table_get('%s.dtel.flow_report0.array2' % ectl)
		table.entry_add(
			target,
			[table.make_key(
				[gc.KeyTuple('$REGISTER_INDEX',                  index)]
			)],
			[table.make_data(
				[gc.DataTuple('%s.dtel.flow_report0.array2.f1'  % ectl, data)]
			)]
		)

def dtel_flow_report_array2_del(self, target, ig_pipe,
	index               = 0
):
		
		table = self.bfrt_info.table_get('%s.dtel.flow_report0.array2' % ectl)
		#print("******************* DUMP ARRAY2 *****************")
		#table.entry_mod(0, 0)
		#print(dir(table))
		#sys.exit(0)

		#register2 = self.bfrt_info.register_get('%s.dtel.flow_report0.array2' % ectl)
		#print(table)
		#print register2
		#register2.write(0,0)
		#table.dump(table=True)
		#array_name = '%s.dtel.flow_report0.array2' % ectl
		#print array_name
		#table.entry_del(target,[table.make_key(
		#		[gc.KeyTuple('$REGISTER_INDEX',                  index)]
		#	)], )
		#report_array = '%s.dtel.flow_report0.array2' % ectl
		#report_array = 0
		#value = table.read(index)
		#print value
		
########################################

def dtel_queue_report_thresholds_add(self, target, ig_pipe,
	index               = 0,
	qdepth              = 0,
	latency             = 0
	):

		table = self.bfrt_info.table_get('%s.dtel.queue_report.thresholds' % ectl)
		table.entry_add(
			target,
			[table.make_key(
				[gc.KeyTuple('$REGISTER_INDEX',                  index)]
			)],
			[table.make_data(
				[gc.DataTuple('%s.dtel.queue_report.thresholds.qdepth'  % ectl, qdepth),
				 gc.DataTuple('%s.dtel.queue_report.thresholds.latency' % ectl, latency)],
			)]
		)

def dtel_queue_report_thresholds_del(self, target, ig_pipe,
	index               = 0,
	):

		table = self.bfrt_info.table_get('%s.dtel.queue_report.thresholds' % ectl)
		table.entry_del(
			target,
			[table.make_key(
				[gc.KeyTuple('$REGISTER_INDEX',                  index)]
			)],
		)

########################################

def dtel_queue_report_quotas_add(self, target, ig_pipe,
	index               = 0,
	counter             = 0,
	latency             = 0
	):

		table = self.bfrt_info.table_get('%s.dtel.queue_report.quotas' % ectl)
		table.entry_add(
			target,
			[table.make_key(
				[gc.KeyTuple('$REGISTER_INDEX',                  index)]
			)],
			[table.make_data(
				[gc.DataTuple('%s.dtel.queue_report.quotas.counter' % ectl, counter),
				 gc.DataTuple('%s.dtel.queue_report.quotas.latency' % ectl, latency)],
			)]
		)

def dtel_queue_report_quotas_del(self, target, ig_pipe,
	index               = 0,
	):

		table = self.bfrt_info.table_get('%s.dtel.queue_report.quotas' % ectl)
		table.entry_del(
			target,
			[table.make_key(
				[gc.KeyTuple('$REGISTER_INDEX',                  index)]
			)],
		)

########################################

def dtel_queue_report_queue_alert_table_add(self, target, ig_pipe,
	qid                 = 0,
	port                = 0,
	quota               = 0,
	quantization_mask   = 0
	):

		table = self.bfrt_info.table_get('%s.dtel.queue_report.queue_alert' % ectl)
		table.entry_add(
			target,
			[table.make_key(
				[gc.KeyTuple('qid',                              qid),
				 gc.KeyTuple('port',                             port)],
			)],
			[table.make_data(
				[gc.DataTuple('quota',                           quota),
				 gc.DataTuple('quantization_mask',               quantization_mask)],
				'%s.dtel.queue_report.set_qalert' % ectl
			)]
		)

def dtel_queue_report_queue_alert_table_del(self, target, ig_pipe,
	qid                 = 0,
	port                = 0
	):

		table = self.bfrt_info.table_get('%s.dtel.queue_report.queue_alert' % ectl)
		table.entry_del(
			target,
			[table.make_key(
				[gc.KeyTuple('qid',                              qid),
				 gc.KeyTuple('port',                             port)],
			)],
		)

########################################

def dtel_queue_report_check_quota_table_update_add(self, target, ig_pipe,
	pkt_src             = 0,
	qalert              = 0,
	qid                 = 0,
	port                = 0,
	index               = 0
	):

		table = self.bfrt_info.table_get('%s.dtel.queue_report.check_quota' % ectl)
		table.entry_add(
			target,
			[table.make_key(
				[gc.KeyTuple('eg_md.pkt_src',                    pkt_src),
				 gc.KeyTuple('qalert',                           qalert),
				 gc.KeyTuple('qid',                              qid),
				 gc.KeyTuple('port',                             port)],
			)],
			[table.make_data(
				[gc.DataTuple('index',                           index)],
				'%s.dtel.queue_report.check_latency_and_update_quota_' % ectl
			)]
		)

def dtel_queue_report_check_quota_table_reset_add(self, target, ig_pipe,
	pkt_src             = 0,
	qalert              = 0,
	qid                 = 0,
	port                = 0,
	index               = 0
	):

		table = self.bfrt_info.table_get('%s.dtel.queue_report.check_quota' % ectl)
		table.entry_add(
			target,
			[table.make_key(
				[gc.KeyTuple('eg_md.pkt_src',                    pkt_src),
				 gc.KeyTuple('qalert',                           qalert),
				 gc.KeyTuple('qid',                              qid),
				 gc.KeyTuple('port',                             port)],
			)],
			[table.make_data(
				[gc.DataTuple('index',                           index)],
				'%s.dtel.queue_report.reset_quota_' % ectl
			)]
		)

def dtel_queue_report_check_quota_table_del(self, target, ig_pipe,
	pkt_src             = 0,
	qalert              = 0,
	qid                 = 0,
	port                = 0
	):

		table = self.bfrt_info.table_get('%s.dtel.queue_report.check_quota' % ectl)
		table.entry_del(
			target,
			[table.make_key(
				[gc.KeyTuple('eg_md.pkt_src',                    pkt_src),
				 gc.KeyTuple('qalert',                           qalert),
				 gc.KeyTuple('qid',                              qid),
				 gc.KeyTuple('port',                             port)],
			)],
		)

########################################

def dtel_config_update_add(self, target, ig_pipe,
	pkt_src             = 0, pkt_src_mask             = 0,
	report_type         = 0, report_type_mask         = 0,
	drop_report_flag    = 0, drop_report_flag_mask    = 0,
	flow_report_flag    = 0, flow_report_flag_mask    = 0,
	queue_report_flag   = 0, queue_report_flag_mask   = 0,
	drop_reason         = 0, drop_reason_mask         = 0,
	mirror_type         = 0, mirror_type_mask         = 0,
	drop_report_valid   = 0, drop_report_valid_mask   = 0,
	action              = "update",
	report_type_out     = 0
	):

		table = self.bfrt_info.table_get('%s.dtel_config.config' % ectl)
		table.entry_add(
			target,
			[table.make_key(
				[gc.KeyTuple('eg_md.pkt_src',                    pkt_src,             pkt_src_mask),
				 gc.KeyTuple('eg_md.dtel.report_type',           report_type,         report_type_mask),
				 gc.KeyTuple('eg_md.dtel.drop_report_flag',      drop_report_flag,    drop_report_flag_mask),
				 gc.KeyTuple('eg_md.dtel.flow_report_flag',      flow_report_flag,    flow_report_flag_mask),
				 gc.KeyTuple('eg_md.dtel.queue_report_flag',     queue_report_flag,   queue_report_flag_mask),
#				 gc.KeyTuple('eg_md.drop_reason',                drop_reason,         drop_reason_mask),
				 gc.KeyTuple('eg_md.mirror.type',                mirror_type,         mirror_type_mask),
				 gc.KeyTuple('hdr.dtel_drop_report.$valid',      drop_report_valid,   drop_report_valid_mask)],
			)],
			[table.make_data(
				[gc.DataTuple('report_type',                     report_type_out)],
#				'%s.dtel_config.update' % ectl
				action
			)]
		)

def dtel_config_mirror_add(self, target, ig_pipe,
	pkt_src             = 0, pkt_src_mask             = 0,
	report_type         = 0, report_type_mask         = 0,
	drop_report_flag    = 0, drop_report_flag_mask    = 0,
	flow_report_flag    = 0, flow_report_flag_mask    = 0,
	queue_report_flag   = 0, queue_report_flag_mask   = 0,
	drop_reason         = 0, drop_reason_mask         = 0,
	mirror_type         = 0, mirror_type_mask         = 0,
	drop_report_valid   = 0, drop_report_valid_mask   = 0,
	action              = "mirror_switch_local_and_drop"
	):

		table = self.bfrt_info.table_get('%s.dtel_config.config' % ectl)
		table.entry_add(
			target,
			[table.make_key(
				[gc.KeyTuple('eg_md.pkt_src',                    pkt_src,             pkt_src_mask),
				 gc.KeyTuple('eg_md.dtel.report_type',           report_type,         report_type_mask),
				 gc.KeyTuple('eg_md.dtel.drop_report_flag',      drop_report_flag,    drop_report_flag_mask),
				 gc.KeyTuple('eg_md.dtel.flow_report_flag',      flow_report_flag,    flow_report_flag_mask),
				 gc.KeyTuple('eg_md.dtel.queue_report_flag',     queue_report_flag,   queue_report_flag_mask),
#				 gc.KeyTuple('eg_md.drop_reason',                drop_reason,         drop_reason_mask),
				 gc.KeyTuple('eg_md.mirror.type',                mirror_type,         mirror_type_mask),
				 gc.KeyTuple('hdr.dtel_drop_report.$valid',      drop_report_valid,   drop_report_valid_mask)],
			)],
			[table.make_data(
				[],
#				'%s.dtel_config.%s' %(ectl, action)
				action
			)]
		)

def dtel_config_del(self, target, ig_pipe,
	pkt_src             = 0, pkt_src_mask             = 0,
	report_type         = 0, report_type_mask         = 0,
	drop_report_flag    = 0, drop_report_flag_mask    = 0,
	flow_report_flag    = 0, flow_report_flag_mask    = 0,
	queue_report_flag   = 0, queue_report_flag_mask   = 0,
	drop_reason         = 0, drop_reason_mask         = 0,
	mirror_type         = 0, mirror_type_mask         = 0,
	drop_report_valid   = 0, drop_report_valid_mask   = 0
	):

		table = self.bfrt_info.table_get('%s.dtel_config.config' % ectl)
		table.entry_del(
			target,
			[table.make_key(
				[gc.KeyTuple('eg_md.pkt_src',                    pkt_src,             pkt_src_mask),
				 gc.KeyTuple('eg_md.dtel.report_type',           report_type,         report_type_mask),
				 gc.KeyTuple('eg_md.dtel.drop_report_flag',      drop_report_flag,    drop_report_flag_mask),
				 gc.KeyTuple('eg_md.dtel.flow_report_flag',      flow_report_flag,    flow_report_flag_mask),
				 gc.KeyTuple('eg_md.dtel.queue_report_flag',     queue_report_flag,   queue_report_flag_mask),
#				 gc.KeyTuple('eg_md.drop_reason',                drop_reason,         drop_reason_mask),
				 gc.KeyTuple('eg_md.mirror.type',                mirror_type,         mirror_type_mask),
				 gc.KeyTuple('hdr.dtel_drop_report.$valid',      drop_report_valid,   drop_report_valid_mask)],
			)],
		)

#######################################
# MIDDLE LEVEL FUNCTIONS
#######################################

# function for adding an egress l2 tunnel (an ethernet header) to a packet

def npb_nexthop_tunnel_mac_add(self, target, ig_pipe,
	# ingress nexthop
	nexthop_ptr, ig_bd_ptr, port_lag_ptr,
	tunnel_ptr, tun_type, outer_nexthop_ptr,
	# egress encap
	eg_bd_ptr, dmac,
	smac_ptr,
	smac
):
	# ingress nexthop
	npb_nexthop_tunnel_encap_add                (self, target, ig_pipe, nexthop_ptr, ig_bd_ptr, tunnel_ptr, tun_type)
	npb_tunnel_encap_nexthop_add                (self, target, ig_pipe, tunnel_ptr, port_lag_ptr, outer_nexthop_ptr)
	# egress encap
	npb_tunnel_encap_nexthop_rewrite_add        (self, target, ig_pipe, outer_nexthop_ptr, eg_bd_ptr, dmac)
	npb_tunnel_encap_bd_mapping_add             (self, target, ig_pipe, eg_bd_ptr, smac_ptr)
	npb_tunnel_encap_smac_rewrite_add           (self, target, ig_pipe, smac_ptr, smac)

def npb_nexthop_tunnel_mac_del(self, target, ig_pipe,
	# ingress nexthop
	nexthop_ptr,
	tunnel_ptr, outer_nexthop_ptr,
	# egress encap
	eg_bd_ptr,
	smac_ptr
):
	# ingress nexthop
	npb_nexthop_del                             (self, target, ig_pipe, nexthop_ptr)
	npb_tunnel_encap_nexthop_del                (self, target, ig_pipe, tunnel_ptr)
	# egress encap
	npb_tunnel_encap_nexthop_rewrite_del        (self, target, ig_pipe, outer_nexthop_ptr)
	npb_tunnel_encap_bd_mapping_del             (self, target, ig_pipe, eg_bd_ptr)
	npb_tunnel_encap_smac_rewrite_del           (self, target, ig_pipe, smac_ptr)

#######################################

def npb_npb_sfp_sel_add(self, target, ig_pipe,
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

	npb_npb_sf0_policy_sfp_sel_hash_add         (self, target, ig_pipe, vpn, flowclass)
	if(len(spi) == 1):
		npb_npb_sf0_policy_sfp_sel_single_add       (self, target, ig_pipe, sfc,                sfc_member_ptr, spi_new[0], si_new[0], si_predec_new[0])
	else:
		npb_npb_sf0_policy_sfp_sel_multi_add        (self, target, ig_pipe, sfc, sfc_group_ptr, sfc_member_ptr, spi_new,    si_new,    si_predec_new)

def npb_npb_sfp_sel_del(self, target, ig_pipe,
	# ingress
	vpn,
	sfc, sfc_group_ptr, sfc_member_ptr, spi, si
	# egress
):
	npb_npb_sf0_policy_sfp_sel_hash_del         (self, target, ig_pipe, vpn)
	if(len(spi) == 1):
		npb_npb_sf0_policy_sfp_sel_single_del       (self, target, ig_pipe, sfc,                sfc_member_ptr)
	else:
		npb_npb_sf0_policy_sfp_sel_multi_del        (self, target, ig_pipe, sfc, sfc_group_ptr, sfc_member_ptr, spi, si)

#######################################

def npb_lag_add(self, target, ig_pipe,
	eg_port_lag_ptr, eg_port_lag_group_ptr, eg_port_lag_member_ptr, eg_port
):
	if(len(eg_port) == 1):
		npb_lag_single_add        (self, target, ig_pipe, eg_port_lag_ptr,                        eg_port_lag_member_ptr, eg_port[0])
	else:
		npb_lag_multi_add         (self, target, ig_pipe, eg_port_lag_ptr, eg_port_lag_group_ptr, eg_port_lag_member_ptr, eg_port)

def npb_lag_del(self, target, ig_pipe,
	eg_port_lag_ptr, eg_port_lag_group_ptr, eg_port_lag_member_ptr, eg_port
):
	if(len(eg_port) == 1):
		npb_lag_single_del        (self, target, ig_pipe, eg_port_lag_ptr,                        eg_port_lag_member_ptr)
	else:
		npb_lag_multi_del         (self, target, ig_pipe, eg_port_lag_ptr, eg_port_lag_group_ptr, eg_port_lag_member_ptr, eg_port)

#######################################

def dtel_flow_report_array_add(self, target, ig_pipe,
	index = 0,
	data0 = 0,
	data1 = 0
):

	dtel_flow_report_array1_add(self, target, ig_pipe, index, data0)
	dtel_flow_report_array2_add(self, target, ig_pipe, index, data1)

def dtel_flow_report_array_del(self, target, ig_pipe,
	index = 0
):
	
	#dtel_flow_report_array1_del(self, target, ig_pipe, index)
	dtel_flow_report_array2_del(self, target, ig_pipe, index)
	

#######################################

def dtel_queue_report_queue_alert_add(self, target, ig_pipe,
	port              = 0,
	qid               = 0,
	quota             = 0,
	quantization_mask = 0,
	reg_index         = 0,
    reg_data_qdepth   = 0,
    reg_data_latency  = 0
):

	# set dtel queue report (register)
	dtel_queue_report_thresholds_add(self, target, ig_pipe,
		index             = reg_index,
		qdepth            = reg_data_qdepth,
		latency           = reg_data_latency
	)

	# set dtel queue report (table)
	dtel_queue_report_queue_alert_table_add(self, target, ig_pipe,
		qid               = qid,
		port              = port,
		quota             = quota,
		quantization_mask = quantization_mask
	)

def dtel_queue_report_queue_alert_del(self, target, ig_pipe,
	port              = 0,
	qid               = 0,
	reg_index         = 0
):
	'''
	# set dtel queue report (register)
	dtel_queue_report_thresholds_del(self, target, ig_pipe,
		index             = reg_index
	)
	'''
	# set dtel queue report (table)
	dtel_queue_report_queue_alert_table_del(self, target, ig_pipe,
		qid               = qid,
		port              = port
	)

#######################################

def dtel_queue_report_check_quota_add(self, target, ig_pipe,
	port             = 0,
	qid              = 0,
	quota            = 0,
	reg_index        = 0,
	reg_data_latency = 0
):

	# set dtel queue report (register)
	dtel_queue_report_quotas_add(self, self.target,
		index             = reg_index,
		counter           = quota, # gets reloaded automatically in the p4 code
		latency           = reg_data_latency 
	)

	# set dtel queue report (table)
	dtel_queue_report_check_quota_table_update_add(self, self.target,
		pkt_src           = PktSrc.BRIDGED.value,
		qalert            = 1,
		qid               = qid,
		port              = port,
		index             = reg_index
	)

	# set dtel queue report (table)
	dtel_queue_report_check_quota_table_reset_add(self, self.target,
		pkt_src           = PktSrc.BRIDGED.value,
		qalert            = 0,
		qid               = qid,
		port              = port,
		index             = reg_index
	)

def dtel_queue_report_check_quota_del(self, target, ig_pipe,
	port             = 0,
	qid              = 0,
	reg_index        = 0
):
	'''
	# set dtel queue report (register)
	dtel_queue_report_quotas_del(self, self.target,
		index             = reg_index
	)
	'''
	# set dtel queue report (table)
	dtel_queue_report_check_quota_table_del(self, self.target,
		pkt_src           = PktSrc.BRIDGED.value,
		qalert            = 1,
		qid               = qid,
		port              = port
	)

	# set dtel queue report (table)
	dtel_queue_report_check_quota_table_del(self, self.target,
		pkt_src           = PktSrc.BRIDGED.value,
		qalert            = 0,
		qid               = qid,
		port              = port
	)

#######################################

def dtel_config_init_add(self, target, ig_pipe,
	flow_report_en       = True,
	queue_report_en      = False
):
	#######################################
	# Bridging Entries
	#######################################

	#B-1 if flow_report enabled, suppression is ignore, qalert true, mirror
	if(queue_report_en):
		action_ = "%s.dtel_config.mirror_switch_local_and_set_q_bit" %(ectl)
	elif(flow_report_en):
		action_ = "%s.dtel_config.mirror_switch_local" %(ectl)
	else:
		action_ = "NoAction"
	dtel_config_mirror_add(self, self.target, ig_pipe,
		pkt_src           = PktSrc.BRIDGED.value,                                      pkt_src_mask           = 0xff, # 0xff
		report_type       = DtelReportType.FLOW.value | DtelReportType.SUPPRESS.value, report_type_mask       = 0xff, # 0xff
		flow_report_flag  = 0,                                                         flow_report_flag_mask  = 0x0,  # 0x3
		queue_report_flag = 1,                                                         queue_report_flag_mask = 0x1,  # 0x1
		drop_report_flag  = 0,                                                         drop_report_flag_mask  = 0x0,  # 0x3
		drop_report_valid = 0,                                                         drop_report_valid_mask = 0x0,
		action = action_
	)

	#B-2 if flow_report enabled, flow flag is 0, qalert true, mirror
	if(queue_report_en):
		action_ = "%s.dtel_config.mirror_switch_local_and_set_q_bit" %(ectl)
	elif(flow_report_en):
		action_ = "%s.dtel_config.mirror_switch_local" %(ectl)
	else:
		action_ = "NoAction"
	dtel_config_mirror_add(self, self.target, ig_pipe,
		pkt_src           = PktSrc.BRIDGED.value,                                      pkt_src_mask           = 0xff, # 0xff
		report_type       = DtelReportType.FLOW.value,                                 report_type_mask       = 0xff, # 0xff
		flow_report_flag  = 0,                                                         flow_report_flag_mask  = 0x3,  # 0x3
		queue_report_flag = 1,                                                         queue_report_flag_mask = 0x1,  # 0x1
		drop_report_flag  = 0,                                                         drop_report_flag_mask  = 0x0,  # 0x3
		drop_report_valid = 0,                                                         drop_report_valid_mask = 0x0,
		action = action_
	)

	#B-3 if flow_report enabled, flow flag is 1*, qalert true, mirror
	if(queue_report_en):
		action_ = "%s.dtel_config.mirror_switch_local_and_set_q_bit" %(ectl)
	elif(flow_report_en):
		action_ = "%s.dtel_config.mirror_switch_local" %(ectl)
	else:
		action_ = "NoAction"
	dtel_config_mirror_add(self, self.target, ig_pipe,
		pkt_src           = PktSrc.BRIDGED.value,                                      pkt_src_mask           = 0xff, # 0xff
		report_type       = DtelReportType.FLOW.value,                                 report_type_mask       = 0xff, # 0xff
		flow_report_flag  = 2,                                                         flow_report_flag_mask  = 0x2,  # 0x3
		queue_report_flag = 1,                                                         queue_report_flag_mask = 0x1,  # 0x1
		drop_report_flag  = 0,                                                         drop_report_flag_mask  = 0x0,  # 0x3
		drop_report_valid = 0,                                                         drop_report_valid_mask = 0x0,
		action = action_
	)

	#B-4 if qalert is true, mirror
	if(queue_report_en):
		action_ = "%s.dtel_config.mirror_switch_local_and_set_q_bit" %(ectl)
	else:
		action_ = "NoAction"
	dtel_config_mirror_add(self, self.target, ig_pipe,
		pkt_src           = PktSrc.BRIDGED.value,                                      pkt_src_mask           = 0xff, # 0xff
		report_type       = DtelReportType.NONE.value,                                 report_type_mask       = 0x00, # 0xff
		flow_report_flag  = 0,                                                         flow_report_flag_mask  = 0x0,  # 0x3
		queue_report_flag = 1,                                                         queue_report_flag_mask = 0x1,  # 0x1
		drop_report_flag  = 0,                                                         drop_report_flag_mask  = 0x0,  # 0x3
		drop_report_valid = 0,                                                         drop_report_valid_mask = 0x0,
		action = action_
	)

	#B-5 if flow_report is enabled and suppression is ignore, mirror
	if(flow_report_en):
		action_ = "%s.dtel_config.mirror_switch_local" %(ectl)
	else:
		action_ = "NoAction"
	dtel_config_mirror_add(self, self.target, ig_pipe,
		pkt_src           = PktSrc.BRIDGED.value,                                      pkt_src_mask           = 0xff, # 0xff
		report_type       = DtelReportType.FLOW.value | DtelReportType.SUPPRESS.value, report_type_mask       = 0xff, # 0xff
		flow_report_flag  = 0,                                                         flow_report_flag_mask  = 0x0,  # 0x3
		queue_report_flag = 0,                                                         queue_report_flag_mask = 0x0,  # 0x1
		drop_report_flag  = 0,                                                         drop_report_flag_mask  = 0x0,  # 0x3
		drop_report_valid = 0,                                                         drop_report_valid_mask = 0x0,
		action = action_
	)

	#B-6 if flow_report is enabled and flow flag is 0, mirror
	if(flow_report_en):
		action_ = "%s.dtel_config.mirror_switch_local" %(ectl)
	else:
		action_ = "NoAction"
	dtel_config_mirror_add(self, self.target, ig_pipe,
		pkt_src           = PktSrc.BRIDGED.value,                                      pkt_src_mask           = 0xff, # 0xff
		report_type       = DtelReportType.FLOW.value,                                 report_type_mask       = 0xff, # 0xff
		flow_report_flag  = 0,                                                         flow_report_flag_mask  = 0x3,  # 0x3
		queue_report_flag = 0,                                                         queue_report_flag_mask = 0x0,  # 0x1
		drop_report_flag  = 0,                                                         drop_report_flag_mask  = 0x0,  # 0x3
		drop_report_valid = 0,                                                         drop_report_valid_mask = 0x0,
		action = action_
	)

	#B-7 if flow_report is enabled and flow flag is 1*, mirror
	if(flow_report_en):
		action_ = "%s.dtel_config.mirror_switch_local" %(ectl)
	else:
		action_ = "NoAction"
	dtel_config_mirror_add(self, self.target, ig_pipe,
		pkt_src           = PktSrc.BRIDGED.value,                                      pkt_src_mask           = 0xff, # 0xff
		report_type       = DtelReportType.FLOW.value,                                 report_type_mask       = 0xff, # 0xff
		flow_report_flag  = 2,                                                         flow_report_flag_mask  = 0x2,  # 0x3
		queue_report_flag = 0,                                                         queue_report_flag_mask = 0x0,  # 0x1
		drop_report_flag  = 0,                                                         drop_report_flag_mask  = 0x0,  # 0x3
		drop_report_valid = 0,                                                         drop_report_valid_mask = 0x0,
		action = action_
	)
	'''
	#B-14 if qalert is true, mirror
	if(queue_report_en):
		action_ = "%s.dtel_config.mirror_switch_local_and_set_q_bit" %(ectl)
	else:
		action_ = "NoAction"
	dtel_config_mirror_add(self, self.target, ig_pipe,
		pkt_src           = PktSrc.BRIDGED.value,                                      pkt_src_mask           = 0xff, # 0xff
		report_type       = DtelReportType.NONE.value,                                 report_type_mask       = 0x00, # 0xff
		flow_report_flag  = 0,                                                         flow_report_flag_mask  = 0x0,  # 0x3
		queue_report_flag = 1,                                                         queue_report_flag_mask = 0x1,  # 0x1
		drop_report_flag  = 0,                                                         drop_report_flag_mask  = 0x0,  # 0x3
		drop_report_valid = 0,                                                         drop_report_valid_mask = 0x0,
		action = action_
	)
	'''

	#######################################
	# Eg Mirror Entries
	#######################################

	#CE-1 if flow_report && queue_report enabled, update
	if(flow_report_en and not queue_report_en):
		report_type_ = DtelReportType.FLOW.value
	elif(not flow_report_en and queue_report_en):
		report_type_ = DtelReportType.QUEUE.value
	else:
		report_type_ = DtelReportType.FLOW.value | DtelReportType.QUEUE.value
	dtel_config_update_add(self, self.target, ig_pipe,
		pkt_src           = PktSrc.CLONED_EGRESS.value,                                pkt_src_mask           = 0xff, # 0xff
		report_type       = DtelReportType.FLOW.value | DtelReportType.QUEUE.value,    report_type_mask       = 0xff, # 0xff
		flow_report_flag  = 0,                                                         flow_report_flag_mask  = 0x0,  # 0x3
		queue_report_flag = 0,                                                         queue_report_flag_mask = 0x0,  # 0x1
		drop_report_flag  = 0,                                                         drop_report_flag_mask  = 0x1,  # 0x3
		drop_report_valid = 0,                                                         drop_report_valid_mask = 0x0,
		action = "%s.dtel_config.update" %(ectl),
		report_type_out   = report_type_
	)

	#CE-2 if queue_report is enabled, then update dtel header
	report_type_ = DtelReportType.QUEUE.value
	dtel_config_update_add(self, self.target, ig_pipe,
		pkt_src           = PktSrc.CLONED_EGRESS.value,                                pkt_src_mask           = 0xff, # 0xff
		report_type       = DtelReportType.QUEUE.value,                                report_type_mask       = 0xff, # 0xff
		flow_report_flag  = 0,                                                         flow_report_flag_mask  = 0x0,  # 0x3
		queue_report_flag = 0,                                                         queue_report_flag_mask = 0x0,  # 0x1
		drop_report_flag  = 0,                                                         drop_report_flag_mask  = 0x1,  # 0x3
		drop_report_valid = 0,                                                         drop_report_valid_mask = 0x0,
		action = "%s.dtel_config.update" %(ectl),
		report_type_out   = report_type_
	)

	#CE-3 if flow_report is enabled, then update dtel header
	report_type_ = DtelReportType.FLOW.value
	dtel_config_update_add(self, self.target, ig_pipe,
		pkt_src           = PktSrc.CLONED_EGRESS.value,                                pkt_src_mask           = 0xff, # 0xff
		report_type       = DtelReportType.FLOW.value,                                 report_type_mask       = 0xff, # 0xff
		flow_report_flag  = 0,                                                         flow_report_flag_mask  = 0x0,  # 0x3
		queue_report_flag = 0,                                                         queue_report_flag_mask = 0x0,  # 0x1
		drop_report_flag  = 0,                                                         drop_report_flag_mask  = 0x1,  # 0x3
		drop_report_valid = 0,                                                         drop_report_valid_mask = 0x0,
		action = "%s.dtel_config.update" %(ectl),
		report_type_out   = report_type_
	)

def dtel_config_init_del(self, target
):
	#######################################
	# Bridging Entries
	#######################################

	#B-1 if flow_report enabled, suppression is ignore, qalert true, mirror
	dtel_config_del(self, self.target, ig_pipe,
		pkt_src           = PktSrc.BRIDGED.value,                                      pkt_src_mask           = 0xff, # 0xff
		report_type       = DtelReportType.FLOW.value | DtelReportType.SUPPRESS.value, report_type_mask       = 0xff, # 0xff
		flow_report_flag  = 0,                                                         flow_report_flag_mask  = 0x0,  # 0x3
		queue_report_flag = 1,                                                         queue_report_flag_mask = 0x1,  # 0x1
		drop_report_flag  = 0,                                                         drop_report_flag_mask  = 0x0,  # 0x3
		drop_report_valid = 0,                                                         drop_report_valid_mask = 0x0
	)

	#B-2 if flow_report enabled, flow flag is 0, qalert true, mirror
	dtel_config_del(self, self.target, ig_pipe,
		pkt_src           = PktSrc.BRIDGED.value,                                      pkt_src_mask           = 0xff, # 0xff
		report_type       = DtelReportType.FLOW.value,                                 report_type_mask       = 0xff, # 0xff
		flow_report_flag  = 0,                                                         flow_report_flag_mask  = 0x3,  # 0x3
		queue_report_flag = 1,                                                         queue_report_flag_mask = 0x1,  # 0x1
		drop_report_flag  = 0,                                                         drop_report_flag_mask  = 0x0,  # 0x3
		drop_report_valid = 0,                                                         drop_report_valid_mask = 0x0
	)

	#B-3 if flow_report enabled, flow flag is 1*, qalert true, mirror
	dtel_config_del(self, self.target, ig_pipe,
		pkt_src           = PktSrc.BRIDGED.value,                                      pkt_src_mask           = 0xff, # 0xff
		report_type       = DtelReportType.FLOW.value,                                 report_type_mask       = 0xff, # 0xff
		flow_report_flag  = 2,                                                         flow_report_flag_mask  = 0x2,  # 0x3
		queue_report_flag = 1,                                                         queue_report_flag_mask = 0x1,  # 0x1
		drop_report_flag  = 0,                                                         drop_report_flag_mask  = 0x0,  # 0x3
		drop_report_valid = 0,                                                         drop_report_valid_mask = 0x0
	)

	#B-4 if qalert is true, mirror
	dtel_config_del(self, self.target, ig_pipe,
		pkt_src           = PktSrc.BRIDGED.value,                                      pkt_src_mask           = 0xff, # 0xff
		report_type       = DtelReportType.NONE.value,                                 report_type_mask       = 0x00, # 0xff
		flow_report_flag  = 0,                                                         flow_report_flag_mask  = 0x0,  # 0x3
		queue_report_flag = 1,                                                         queue_report_flag_mask = 0x1,  # 0x1
		drop_report_flag  = 0,                                                         drop_report_flag_mask  = 0x0,  # 0x3
		drop_report_valid = 0,                                                         drop_report_valid_mask = 0x0
	)

	#B-5 if flow_report is enabled and suppression is ignore, mirror
	dtel_config_del(self, self.target, ig_pipe,
		pkt_src           = PktSrc.BRIDGED.value,                                      pkt_src_mask           = 0xff, # 0xff
		report_type       = DtelReportType.FLOW.value | DtelReportType.SUPPRESS.value, report_type_mask       = 0xff, # 0xff
		flow_report_flag  = 0,                                                         flow_report_flag_mask  = 0x0,  # 0x3
		queue_report_flag = 0,                                                         queue_report_flag_mask = 0x0,  # 0x1
		drop_report_flag  = 0,                                                         drop_report_flag_mask  = 0x0,  # 0x3
		drop_report_valid = 0,                                                         drop_report_valid_mask = 0x0
	)

	#B-6 if flow_report is enabled and flow flag is 0, mirror
	dtel_config_del(self, self.target, ig_pipe,
		pkt_src           = PktSrc.BRIDGED.value,                                      pkt_src_mask           = 0xff, # 0xff
		report_type       = DtelReportType.FLOW.value,                                 report_type_mask       = 0xff, # 0xff
		flow_report_flag  = 0,                                                         flow_report_flag_mask  = 0x3,  # 0x3
		queue_report_flag = 0,                                                         queue_report_flag_mask = 0x0,  # 0x1
		drop_report_flag  = 0,                                                         drop_report_flag_mask  = 0x0,  # 0x3
		drop_report_valid = 0,                                                         drop_report_valid_mask = 0x0
	)

	#B-7 if flow_report is enabled and flow flag is 1*, mirror
	dtel_config_del(self, self.target, ig_pipe,
		pkt_src           = PktSrc.BRIDGED.value,                                      pkt_src_mask           = 0xff, # 0xff
		report_type       = DtelReportType.FLOW.value,                                 report_type_mask       = 0xff, # 0xff
		flow_report_flag  = 2,                                                         flow_report_flag_mask  = 0x2,  # 0x3
		queue_report_flag = 0,                                                         queue_report_flag_mask = 0x0,  # 0x1
		drop_report_flag  = 0,                                                         drop_report_flag_mask  = 0x0,  # 0x3
		drop_report_valid = 0,                                                         drop_report_valid_mask = 0x0
	)
	'''
	#B-14 if qalert is true, mirror
	dtel_config_del(self, self.target, ig_pipe,
		pkt_src           = PktSrc.BRIDGED.value,                                      pkt_src_mask           = 0xff, # 0xff
		report_type       = DtelReportType.NONE.value,                                 report_type_mask       = 0x00, # 0xff
		flow_report_flag  = 0,                                                         flow_report_flag_mask  = 0x0,  # 0x3
		queue_report_flag = 1,                                                         queue_report_flag_mask = 0x1,  # 0x1
		drop_report_flag  = 0,                                                         drop_report_flag_mask  = 0x0,  # 0x3
		drop_report_valid = 0,                                                         drop_report_valid_mask = 0x0
	)
	'''

	#######################################
	# Eg Mirror Entries
	#######################################

	#CE-1 if flow_report && queue_report enabled, update
	dtel_config_del(self, self.target, ig_pipe,
		pkt_src           = PktSrc.CLONED_EGRESS.value,                                pkt_src_mask           = 0xff, # 0xff
		report_type       = DtelReportType.FLOW.value | DtelReportType.QUEUE.value,    report_type_mask       = 0xff, # 0xff
		flow_report_flag  = 0,                                                         flow_report_flag_mask  = 0x0,  # 0x3
		queue_report_flag = 0,                                                         queue_report_flag_mask = 0x0,  # 0x1
		drop_report_flag  = 0,                                                         drop_report_flag_mask  = 0x1,  # 0x3
		drop_report_valid = 0,                                                         drop_report_valid_mask = 0x0,
	)

	#CE-2 if queue_report is enabled, then update dtel header
	dtel_config_del(self, self.target, ig_pipe,
		pkt_src           = PktSrc.CLONED_EGRESS.value,                                pkt_src_mask           = 0xff, # 0xff
		report_type       = DtelReportType.QUEUE.value,                                report_type_mask       = 0xff, # 0xff
		flow_report_flag  = 0,                                                         flow_report_flag_mask  = 0x0,  # 0x3
		queue_report_flag = 0,                                                         queue_report_flag_mask = 0x0,  # 0x1
		drop_report_flag  = 0,                                                         drop_report_flag_mask  = 0x1,  # 0x3
		drop_report_valid = 0,                                                         drop_report_valid_mask = 0x0,
	)

	#CE-3 if flow_report is enabled, then update dtel header
	dtel_config_del(self, self.target, ig_pipe,
		pkt_src           = PktSrc.CLONED_EGRESS.value,                                pkt_src_mask           = 0xff, # 0xff
		report_type       = DtelReportType.FLOW.value,                                 report_type_mask       = 0xff, # 0xff
		flow_report_flag  = 0,                                                         flow_report_flag_mask  = 0x0,  # 0x3
		queue_report_flag = 0,                                                         queue_report_flag_mask = 0x0,  # 0x1
		drop_report_flag  = 0,                                                         drop_report_flag_mask  = 0x1,  # 0x3
		drop_report_valid = 0,                                                         drop_report_valid_mask = 0x0,
	)

#######################################
# HIGH LEVEL FUNCTIONS
#######################################

# note: mgid, dsap inputs are only used when corresponding sf is enabled

def npb_nsh_chain_start_end_add(self, target, ig_pipe,
	# ingress
	ig_port, ig_port_lag_ptr, bridging_enable, sap, vpn, spi, si, sf_bitmask, rmac, nexthop_ptr, ig_bd,  eg_port_lag_ptr, eg_port_lag_group_ptr, eg_port_lag_member_ptr, eg_port, eg_port_is_cpu, mgid, dsap
	# egress
):
	cpu_port_add              (self, target, ig_pipe, ig_port)
	npb_ing_port_add          (self, target, ig_pipe, ig_port, ig_port_lag_ptr, bridging_enable, sap, vpn, spi, si, si-(popcount(sf_bitmask&6))) # only 'and' with sf's that are after the sff
	npb_tunnel_rmac_add       (self, target, ig_pipe, rmac);
#	npb_npb_sfc_sf_sel_add    (self, target, ig_pipe, spi, si, si-(popcount(sf_bitmask&6))) # only 'and' with sf's that are after the sff
	if(sf_bitmask&1):
		npb_npb_sf0_action_sel_add(self, target, ig_pipe, spi, si-(popcount(sf_bitmask&0)), 0)
	npb_npb_sff_fib_add       (self, target, ig_pipe, spi, si-(popcount(sf_bitmask)), nexthop_ptr, 1) # 1 = end of chain
	if(sf_bitmask&2):
		npb_npb_sf1_action_sel_add(self, target, ig_pipe, spi, si-(popcount(sf_bitmask&1)), 0, mgid)
	npb_nexthop_add           (self, target, ig_pipe, nexthop_ptr, ig_bd, eg_port_lag_ptr)
	npb_lag_add               (self, target, ig_pipe, eg_port_lag_ptr, eg_port_lag_group_ptr, eg_port_lag_member_ptr, eg_port)

	npb_egr_port_add          (self, target, ig_pipe, eg_port, eg_port_is_cpu, eg_port_lag_ptr)
	if(sf_bitmask&4):
		npb_npb_sf2_action_sel_add(self, target, ig_pipe, spi, si-(popcount(sf_bitmask&3)), 0, dsap)

def npb_nsh_chain_start_end_del(self, target, ig_pipe,
	# ingress
	ig_port, ig_port_lag_ptr, spi, si, sf_bitmask, rmac, nexthop_ptr, eg_port_lag_ptr, eg_port_lag_group_ptr, eg_port_lag_member_ptr, eg_port
	# egress
):
	cpu_port_del              (self, target, ig_pipe, ig_port)
	npb_ing_port_del          (self, target, ig_pipe, ig_port, ig_port_lag_ptr)
	npb_tunnel_rmac_del       (self, target, ig_pipe, rmac);
#	npb_npb_sfc_sf_sel_del    (self, target, ig_pipe, spi, si) # adding this allows acting as a middle too
	if(sf_bitmask&1):
		npb_npb_sf0_action_sel_del(self, target, ig_pipe, spi, si-(popcount(sf_bitmask&0)))
	npb_npb_sff_fib_del       (self, target, ig_pipe, spi, si-(popcount(sf_bitmask)))
	if(sf_bitmask&2):
		npb_npb_sf1_action_sel_del(self, target, ig_pipe, spi, si-(popcount(sf_bitmask&1)))
	npb_nexthop_del           (self, target, ig_pipe, nexthop_ptr)
	npb_lag_del               (self, target, ig_pipe, eg_port_lag_ptr, eg_port_lag_group_ptr, eg_port_lag_member_ptr, eg_port)

	if(eg_port_lag_ptr < 99) :
		npb_egr_port_del          (self, target, ig_pipe, eg_port)
	if(sf_bitmask&4):
		npb_npb_sf2_action_sel_del(self, target, ig_pipe, spi, si-(popcount(sf_bitmask&3)))

#######################################

# note: mgid, dsap inputs are only used when corresponding sf is enabled

def npb_nsh_chain_start_end_with_tunnel_add(self, target, ig_pipe,
	# ingress
	ig_port, ig_port_lag_ptr, bridging_enable, sap, vpn, spi, si, sf_bitmask, rmac, nexthop_ptr, ig_bd, eg_port_lag_ptr, eg_port_lag_group_ptr, eg_port_lag_member_ptr, eg_port, eg_port_is_cpu, mgid, dsap,
	# tunnel
	tunnel_ptr, tun_type, outer_nexthop_ptr, eg_bd_ptr, dmac, smac_ptr, smac
	# egress
):
	cpu_port_add              (self, target, ig_pipe, ig_port)
	npb_ing_port_add          (self, target, ig_pipe, ig_port, ig_port_lag_ptr, bridging_enable, sap, vpn, spi, si, si-(popcount(sf_bitmask&6))) # only 'and' with sf's that are after the sff
	npb_tunnel_rmac_add       (self, target, ig_pipe, rmac);
#	npb_npb_sfc_sf_sel_add    (self, target, ig_pipe, spi, si, si-(popcount(sf_bitmask&6))) # only 'and' with sf's that are after the sff
	if(sf_bitmask&1):
		npb_npb_sf0_action_sel_add(self, target, ig_pipe, spi, si-(popcount(sf_bitmask&0)), 0)
	npb_npb_sff_fib_add       (self, target, ig_pipe, spi, si-(popcount(sf_bitmask)), nexthop_ptr, 1) # 1 = end of chain
	if(sf_bitmask&2):
		npb_npb_sf1_action_sel_add(self, target, ig_pipe, spi, si-(popcount(sf_bitmask&1)), 0, mgid)
	npb_nexthop_tunnel_mac_add(self, target, ig_pipe, nexthop_ptr, ig_bd, eg_port_lag_ptr, tunnel_ptr, tun_type, outer_nexthop_ptr, eg_bd_ptr, dmac, smac_ptr, smac)
	npb_lag_add               (self, target, ig_pipe, eg_port_lag_ptr, eg_port_lag_group_ptr, eg_port_lag_member_ptr, eg_port)

	npb_egr_port_add          (self, target, ig_pipe, eg_port, eg_port_is_cpu, eg_port_lag_ptr)
	if(sf_bitmask&4):
		npb_npb_sf2_action_sel_add(self, target, ig_pipe, spi, si-(popcount(sf_bitmask&3)), 0, dsap)
	npb_tunnel_encap_add      (self, target) # this is a constant table, independent of the test (barefoot should really set automatically!)

def npb_nsh_chain_start_end_with_tunnel_del(self, target, ig_pipe,
	# ingress
	ig_port, ig_port_lag_ptr, spi, si, sf_bitmask, rmac, nexthop_ptr, eg_port_lag_ptr, eg_port_lag_group_ptr, eg_port_lag_member_ptr, eg_port,
	# tunnel
	tunnel_ptr, outer_nexthop_ptr, eg_bd_ptr, smac_ptr
	# egress
):
	cpu_port_del              (self, target, ig_pipe, ig_port)
	npb_ing_port_del          (self, target, ig_pipe, ig_port, ig_port_lag_ptr)
	npb_tunnel_rmac_del       (self, target, ig_pipe, rmac);
#	npb_npb_sfc_sf_sel_del    (self, target, ig_pipe, spi, si) # adding this allows acting as a middle too
	if(sf_bitmask&1):
		npb_npb_sf0_action_sel_del(self, target, ig_pipe, spi, si-(popcount(sf_bitmask&0)))
	npb_npb_sff_fib_del       (self, target, ig_pipe, spi, si-(popcount(sf_bitmask)))
	if(sf_bitmask&2):
		npb_npb_sf1_action_sel_del(self, target, ig_pipe, spi, si-(popcount(sf_bitmask&1)))
	npb_nexthop_tunnel_mac_del(self, target, ig_pipe, nexthop_ptr, tunnel_ptr, outer_nexthop_ptr, eg_bd_ptr, smac_ptr)
	npb_lag_del               (self, target, ig_pipe, eg_port_lag_ptr, eg_port_lag_group_ptr, eg_port_lag_member_ptr, eg_port)

	npb_egr_port_del          (self, target, ig_pipe, eg_port)
	if(sf_bitmask&4):
		npb_npb_sf2_action_sel_del(self, target, ig_pipe, spi, si-(popcount(sf_bitmask&3)))
	npb_tunnel_encap_del      (self, target) # this is a constant table, independent of the test (barefoot should really set automatically!)

#######################################

# note: mgid, dsap inputs are only used when corresponding sf is enabled

def npb_nsh_chain_start_add(self, target, ig_pipe, 
	# ingress
	ig_port, ig_port_lag_ptr, bridging_enable, sap, vpn, spi, si, sf_bitmask, rmac, nexthop_ptr, ig_bd, eg_port_lag_ptr, eg_port_lag_group_ptr, eg_port_lag_member_ptr, eg_port, eg_port_is_cpu, mgid, dsap,
	# tunnel
	tunnel_ptr, tun_type, outer_nexthop_ptr, eg_bd_ptr, dmac, smac_ptr, smac
	# egress
):
	cpu_port_add              (self, target, ig_pipe,  ig_port)
	npb_ing_port_add          (self, target, ig_pipe,  ig_port, ig_port_lag_ptr, bridging_enable, sap, vpn, spi, si, si-(popcount(sf_bitmask&6))) # only 'and' with sf's that are after the sff
	npb_tunnel_rmac_add       (self, target, ig_pipe,  rmac);
#	npb_npb_sfc_sf_sel_add    (self, target, ig_pipe, spi, si, si-(popcount(sf_bitmask&6))) # only 'and' with sf's that are after the sff
	if(sf_bitmask&1):
		npb_npb_sf0_action_sel_add(self, target, ig_pipe, spi, si-(popcount(sf_bitmask&0)), 0)
	npb_npb_sff_fib_add       (self, target, ig_pipe,  spi, si-(popcount(sf_bitmask)), nexthop_ptr, 0) # 0 = not end of chain
	if(sf_bitmask&2):
		npb_npb_sf1_action_sel_add(self, target, ig_pipe, spi, si-(popcount(sf_bitmask&1)), 0, mgid)
	npb_nexthop_tunnel_mac_add(self, target, ig_pipe, nexthop_ptr, ig_bd, eg_port_lag_ptr, tunnel_ptr, tun_type, outer_nexthop_ptr, eg_bd_ptr, dmac, smac_ptr, smac)

	npb_lag_add               (self, target, ig_pipe, eg_port_lag_ptr, eg_port_lag_group_ptr, eg_port_lag_member_ptr, eg_port)

	npb_egr_port_add          (self, target, ig_pipe, eg_port, eg_port_is_cpu, eg_port_lag_ptr)
	if(sf_bitmask&4):
		npb_npb_sf2_action_sel_add(self, target, ig_pipe, spi, si-(popcount(sf_bitmask&3)), 0, dsap)
	npb_tunnel_encap_add      (self, target) # this is a constant table, independent of the test (barefoot should really set automatically!)

def npb_nsh_chain_start_del(self, target, ig_pipe, 
	# ingress
	ig_port, ig_port_lag_ptr, spi, si, sf_bitmask, rmac, nexthop_ptr, eg_port_lag_ptr, eg_port_lag_group_ptr, eg_port_lag_member_ptr, eg_port,
	# tunnel
	tunnel_ptr, outer_nexthop_ptr, eg_bd_ptr, smac_ptr
	# egress
):
	cpu_port_del              (self, target, ig_pipe,  ig_port)
	npb_ing_port_del          (self, target, ig_pipe,  ig_port, ig_port_lag_ptr)
	npb_tunnel_rmac_del       (self, target, ig_pipe, rmac);
#	npb_npb_sfc_sf_sel_del    (self, target, ig_pipe, spi, si) # adding this allows acting as a middle too
	if(sf_bitmask&1):
		npb_npb_sf0_action_sel_del(self, target, ig_pipe, spi, si-(popcount(sf_bitmask&0)))
	npb_npb_sff_fib_del       (self, target, ig_pipe, spi, si-(popcount(sf_bitmask)))
	if(sf_bitmask&2):
		npb_npb_sf1_action_sel_del(self, target, ig_pipe, spi, si-(popcount(sf_bitmask&1)))
	npb_nexthop_tunnel_mac_del(self, target, ig_pipe, nexthop_ptr, tunnel_ptr, outer_nexthop_ptr, eg_bd_ptr, smac_ptr)
	npb_lag_del               (self, target, ig_pipe, eg_port_lag_ptr, eg_port_lag_group_ptr, eg_port_lag_member_ptr, eg_port)

	npb_egr_port_del          (self, target, ig_pipe, eg_port)
	if(sf_bitmask&4):
		npb_npb_sf2_action_sel_del(self, target, ig_pipe, spi, si-(popcount(sf_bitmask&3)))
	npb_tunnel_encap_del      (self, target) # this is a constant table, independent of the test (barefoot should really set automatically!)

#######################################

# note: mgid, dsap inputs are only used when corresponding sf is enabled

def npb_nsh_chain_middle_add(self, target, ig_pipe,
	# ingress
	ig_port, ig_port_lag_ptr, bridging_enable, ta, spi, si, sf_bitmask, rmac, nexthop_ptr, ig_bd, eg_port_lag_ptr, eg_port_lag_group_ptr, eg_port_lag_member_ptr, eg_port, eg_port_is_cpu, mgid, dsap,
	# tunnel
	tunnel_ptr, tun_type, outer_nexthop_ptr, eg_bd_ptr, dmac, smac_ptr, smac
	# egress
):
	cpu_port_add              (self, target, ig_pipe, ig_port)
	npb_ing_port_add          (self, target, ig_pipe, ig_port, ig_port_lag_ptr, bridging_enable, 0, 0, 0, 0, 0)
	npb_tunnel_rmac_add       (self, target, ig_pipe, rmac);

	npb_npb_sfc_sf_sel_add    (self, target, ig_pipe, spi, si, si-(popcount(sf_bitmask&6))) # only 'and' with sf's that are after the sff
	npb_sfc_sf_sel_nsh_xlate_add(self, target, ig_pipe, ta, 63, spi, si, si-(popcount(sf_bitmask&6)) )

	if(sf_bitmask&1):
		npb_npb_sf0_action_sel_add(self, target, ig_pipe, spi, si-(popcount(sf_bitmask&0)), 0)
	npb_npb_sff_fib_add       (self, target, ig_pipe, spi, si-(popcount(sf_bitmask)), nexthop_ptr, 0) # 0 = not end of chain
	if(sf_bitmask&2):
		npb_npb_sf1_action_sel_add(self, target, ig_pipe, spi, si-(popcount(sf_bitmask&1)), 0, mgid)
	npb_nexthop_tunnel_mac_add(self, target, ig_pipe, nexthop_ptr, ig_bd, eg_port_lag_ptr, tunnel_ptr, tun_type, outer_nexthop_ptr, eg_bd_ptr, dmac, smac_ptr, smac)
	npb_lag_add               (self, target, ig_pipe, eg_port_lag_ptr, eg_port_lag_group_ptr, eg_port_lag_member_ptr, eg_port)

	npb_egr_port_add          (self, target, ig_pipe, eg_port, eg_port_is_cpu, eg_port_lag_ptr)
	if(sf_bitmask&4):
		npb_npb_sf2_action_sel_add(self, target, ig_pipe, spi, si-(popcount(sf_bitmask&3)), 0, dsap)
	npb_tunnel_encap_add      (self, target) # this is a constant table, independent of the test (barefoot should really set automatically!)

def npb_nsh_chain_middle_del(self, target, ig_pipe,
	# ingress
	ig_port, ig_port_lag_ptr, ta, spi, si, sf_bitmask, rmac, nexthop_ptr, eg_port_lag_ptr, eg_port_lag_group_ptr, eg_port_lag_member_ptr, eg_port,
	# tunnel
	tunnel_ptr, outer_nexthop_ptr, eg_bd_ptr, smac_ptr
	# egress
):
	cpu_port_del              (self, target, ig_pipe, ig_port)
	npb_ing_port_del          (self, target, ig_pipe, ig_port, ig_port_lag_ptr)
	npb_tunnel_rmac_del       (self, target, ig_pipe, rmac);
	npb_npb_sfc_sf_sel_del    (self, target, ig_pipe, spi, si)
	npb_sfc_sf_sel_nsh_xlate_del(self, target, ig_pipe, ta)
	if(sf_bitmask&1):
		npb_npb_sf0_action_sel_del(self, target, ig_pipe, spi, si-(popcount(sf_bitmask&0)))
	npb_npb_sff_fib_del       (self, target, ig_pipe, spi, si-(popcount(sf_bitmask)))
	if(sf_bitmask&2):
		npb_npb_sf1_action_sel_del(self, target, ig_pipe, spi, si-(popcount(sf_bitmask&1)))
	npb_nexthop_tunnel_mac_del(self, target, ig_pipe, nexthop_ptr, tunnel_ptr, outer_nexthop_ptr, eg_bd_ptr, smac_ptr)
	npb_lag_del               (self, target, ig_pipe, eg_port_lag_ptr, eg_port_lag_group_ptr, eg_port_lag_member_ptr, eg_port)

	npb_egr_port_del          (self, target, ig_pipe, eg_port)
	if(sf_bitmask&4):
		npb_npb_sf2_action_sel_del(self, target, ig_pipe, spi, si-(popcount(sf_bitmask&3)))
	npb_tunnel_encap_del      (self, target) # this is a constant table, independent of the test (barefoot should really set automatically!)

#######################################

# note: mgid, dsap inputs are only used when corresponding sf is enabled

def npb_nsh_chain_end_add(self, target, ig_pipe,
	# ingress
	ig_port, ig_port_lag_ptr, bridging_enable, ta, spi, si, sf_bitmask, rmac, nexthop_ptr, ig_bd,  eg_port_lag_ptr, eg_port_lag_group_ptr, eg_port_lag_member_ptr, eg_port, eg_port_is_cpu, mgid, dsap
	# egress
):
	cpu_port_add              (self, target, ig_pipe, ig_port)
	npb_ing_port_add          (self, target, ig_pipe, ig_port, ig_port_lag_ptr, bridging_enable, 0, 0, 0, 0, 0)
	npb_tunnel_rmac_add       (self, target, ig_pipe, rmac);
	npb_npb_sfc_sf_sel_add    (self, target, ig_pipe, spi, si, si-(popcount(sf_bitmask&6))) # only 'and' with sf's that are after the sff
	npb_sfc_sf_sel_nsh_xlate_add(self, target, ig_pipe, ta, 63, spi, si, si-(popcount(sf_bitmask&6)) )
	if(sf_bitmask&1):
		npb_npb_sf0_action_sel_add(self, target, ig_pipe, spi, si-(popcount(sf_bitmask&0)), 0)
	npb_npb_sff_fib_add       (self, target, ig_pipe, spi, si-(popcount(sf_bitmask)), nexthop_ptr, 1) # 1 = end of chain
	if(sf_bitmask&2):
		npb_npb_sf1_action_sel_add(self, target, ig_pipe, spi, si-(popcount(sf_bitmask&1)), 0, mgid)
	npb_nexthop_add           (self, target, ig_pipe, nexthop_ptr, ig_bd, eg_port_lag_ptr)
	npb_lag_add               (self, target, ig_pipe, eg_port_lag_ptr, eg_port_lag_group_ptr, eg_port_lag_member_ptr, eg_port)

	npb_egr_port_add          (self, target, ig_pipe, eg_port, eg_port_is_cpu, eg_port_lag_ptr)
	if(sf_bitmask&4):
		npb_npb_sf2_action_sel_add(self, target, ig_pipe, spi, si-(popcount(sf_bitmask&3)), 0, dsap)

def npb_nsh_chain_end_del(self, target, ig_pipe,
	# ingress
	ig_port, ig_port_lag_ptr, ta, spi, si, sf_bitmask, rmac, nexthop_ptr, eg_port_lag_ptr, eg_port_lag_group_ptr, eg_port_lag_member_ptr, eg_port
	# egress
):
	cpu_port_del              (self, target, ig_pipe, ig_port)
	npb_ing_port_del          (self, target, ig_pipe, ig_port, ig_port_lag_ptr)
	npb_tunnel_rmac_del       (self, target, ig_pipe, rmac);
	npb_npb_sfc_sf_sel_del    (self, target, ig_pipe, spi, si)
	npb_sfc_sf_sel_nsh_xlate_del(self, target, ig_pipe, ta)
	if(sf_bitmask&1):
		npb_npb_sf0_action_sel_del(self, target, ig_pipe, spi, si-(popcount(sf_bitmask&0)))
	npb_npb_sff_fib_del       (self, target, ig_pipe, spi, si-(popcount(sf_bitmask)))
	if(sf_bitmask&2):
		npb_npb_sf1_action_sel_del(self, target, ig_pipe, spi, si-(popcount(sf_bitmask&1)))
	npb_nexthop_del           (self, target, ig_pipe, nexthop_ptr)
	npb_lag_del               (self, target, ig_pipe, eg_port_lag_ptr, eg_port_lag_group_ptr, eg_port_lag_member_ptr, eg_port)

	npb_egr_port_del          (self, target, ig_pipe, eg_port)
	if(sf_bitmask&4):
		npb_npb_sf2_action_sel_del(self, target, ig_pipe, spi, si-(popcount(sf_bitmask&3)))

#######################################

def npb_nsh_bridge_add(self, target, ig_pipe,
	#ingress
#	ig_port, ig_port_lag_ptr, rmac, bd, bd_member_ptr, dmac, eg_port_lag_ptr, eg_port_lag_group_ptr, eg_port_lag_member_ptr, eg_port
	ig_port, ig_port_lag_ptr, rmac, nexthop_ptr, bd, ethertype, ethertype_mask, vid_isValid, vid_isValid_mask, vid, vid_mask, dmac, dmac_mask, eg_port_lag_ptr, eg_port_lag_group_ptr, eg_port_lag_member_ptr, eg_port, eg_port_is_cpu
	#egress
):
	cpu_port_add              (self, target, ig_pipe, ig_port)
	npb_ing_port_add          (self, target, ig_pipe, ig_port, ig_port_lag_ptr, 1, 0, 0, 0, 0, 0)
#	npb_port_vlan_to_bd_add   (self, self.target, ig_port_lag_ptr, 0, 0, 0, 0, bd_member_ptr, bd)
	npb_tunnel_rmac_add       (self, target, ig_pipe, rmac);
	npb_tunnel_dmac_add       (self, target, ig_pipe, ig_port_lag_ptr, ethertype, ethertype_mask, vid_isValid, vid_isValid_mask, vid, vid_mask, dmac, dmac_mask, eg_port_lag_ptr);
#	npb_nexthop_add           (self, target, ig_pipe, nexthop_ptr, bd, eg_port_lag_ptr)
	npb_lag_add               (self, target, ig_pipe, eg_port_lag_ptr, eg_port_lag_group_ptr, eg_port_lag_member_ptr, eg_port)
	npb_egr_port_add          (self, target, ig_pipe, eg_port, eg_port_is_cpu, eg_port_lag_ptr)

def npb_nsh_bridge_del(self, target, ig_pipe,
	#ingress
#	ig_port, ig_port_lag_ptr, rmac, bd, bd_member_ptr, dmac, eg_port_lag_ptr, eg_port_lag_group_ptr, eg_port_lag_member_ptr, eg_port
	ig_port, ig_port_lag_ptr, rmac, nexthop_ptr, ethertype, ethertype_mask, vid_isValid, vid_isValid_mask, vid, vid_mask, dmac, dmac_mask, eg_port_lag_ptr, eg_port_lag_group_ptr, eg_port_lag_member_ptr, eg_port
	#egress
):
	cpu_port_del              (self, target, ig_pipe, ig_port)
	npb_ing_port_del          (self, target, ig_pipe, ig_port, ig_port_lag_ptr)
#	npb_port_vlan_to_bd_del   (self, self.target, ig_port_lag_ptr, 0, 0, 0, 0, bd_member_ptr)
	npb_tunnel_rmac_del       (self, target, ig_pipe, rmac);
	npb_tunnel_dmac_del       (self, target, ig_pipe, ig_port_lag_ptr, ethertype, ethertype_mask, vid_isValid, vid_isValid_mask, vid, vid_mask, dmac, dmac_mask);
#	npb_nexthop_del           (self, target, ig_pipe, nexthop_ptr)
	npb_lag_del               (self, target, ig_pipe, eg_port_lag_ptr, eg_port_lag_group_ptr, eg_port_lag_member_ptr, eg_port)
	npb_egr_port_del          (self, target, ig_pipe, eg_port)

#######################################

def npb_nsh_bridge_no_eg_lag_add(self, target, ig_pipe,
	#ingress
#	ig_port, ig_port_lag_ptr, rmac, bd, bd_member_ptr, dmac, eg_port_lag_ptr, eg_port_lag_group_ptr, eg_port_lag_member_ptr, eg_port
	ig_port, ig_port_lag_ptr, rmac, nexthop_ptr, bd, ethertype, ethertype_mask, vid_isValid, vid_isValid_mask, vid, vid_mask, dmac, dmac_mask, eg_port_lag_ptr, eg_port_lag_group_ptr, eg_port_lag_member_ptr, eg_port
	#egress
):
	cpu_port_add              (self, target, ig_pipe, ig_port)
	npb_ing_port_add          (self, target, ig_pipe, ig_port, ig_port_lag_ptr, 1, 0, 0, 0, 0, 0)
#	npb_port_vlan_to_bd_add   (self, self.target, ig_port_lag_ptr, 0, 0, 0, 0, bd_member_ptr, bd)
	npb_tunnel_rmac_add       (self, target, ig_pipe, rmac);
	npb_tunnel_dmac_add       (self, target, ig_pipe, ig_port_lag_ptr, ethertype, ethertype_mask, vid_isValid, vid_isValid_mask, vid, vid_mask, dmac, dmac_mask, eg_port_lag_ptr);

# Egress lag removed if sharing with other flows

def npb_nsh_bridge_no_eg_lag_del(self, target, ig_pipe,
	#ingress
#	ig_port, ig_port_lag_ptr, rmac, bd, bd_member_ptr, dmac, eg_port_lag_ptr, eg_port_lag_group_ptr, eg_port_lag_member_ptr, eg_port
	ig_port, ig_port_lag_ptr, rmac, nexthop_ptr, ethertype, ethertype_mask, vid_isValid, vid_isValid_mask, vid, vid_mask, dmac, dmac_mask, eg_port_lag_ptr, eg_port_lag_group_ptr, eg_port_lag_member_ptr, eg_port
	#egress
):
	cpu_port_del              (self, target, ig_pipe, ig_port)
	npb_ing_port_del          (self, target, ig_pipe, ig_port, ig_port_lag_ptr)
#	npb_port_vlan_to_bd_del   (self, self.target, ig_port_lag_ptr, 0, 0, 0, 0, bd_member_ptr)
	npb_tunnel_rmac_del       (self, target, ig_pipe, rmac);
	npb_tunnel_dmac_del       (self, target, ig_pipe, ig_port_lag_ptr, ethertype, ethertype_mask, vid_isValid, vid_isValid_mask, vid, vid_mask, dmac, dmac_mask);

# Egress lag removed if sharing with other flows

#######################################
# Table Cleanup
#######################################

# Use Cleanup Method to clear the tables before and after the test starts
# (the latter is done as a part of tearDown()
def cleanUpGlobal(self):
	print("Performing Table Cleanup \n")
	#print("=========================")

	#Is there a better way to figure out which ports are being used rather than hardcode these?
	for p in ig_pipes: 
		cpu_port_del(self, self.target, p, [ig_swports[p][0],ig_swports[p][1],ig_swports[p][2],ig_swports[p][3]])
	

	self.tables = []
	table_names = []
	lag_action_paths = []
	lag_selector_paths = []
	my_mac_lo_paths = []
	my_mac_hi_paths = []

	table_attributes = [ 'ConstTable' ]
	# Create a list of tables to clean up directly from the json file
	for tbl in all_tables:
		#Add tables directly from json file. However some types of tables do not support
		#being cleared in this manner
		table_names.append(self.bfrt_info.table_get(tbl).info.name_get())
		if(("ConstTable" not in self.bfrt_info.table_get(tbl).info.attributes) and
	  	(self.bfrt_info.table_get(tbl).info.table_type != 'Action') and
	  	(self.bfrt_info.table_get(tbl).info.table_type != 'Counter') and
		(self.bfrt_info.table_get(tbl).info.table_type != 'DynHashCompute') and
		(self.bfrt_info.table_get(tbl).info.table_type != 'DynHashConfigure') and
		(self.bfrt_info.table_get(tbl).info.table_type != 'DynHashAlgorithm') and
		(self.bfrt_info.table_get(tbl).info.table_type != 'ParserValueSet') and
		(self.bfrt_info.table_get(tbl).info.table_type != 'PortMetadata') and
		(self.bfrt_info.table_get(tbl).info.table_type != 'Meter') and
		(self.bfrt_info.table_get(tbl).info.table_type != 'Selector') and
		(self.bfrt_info.table_get(tbl).info.table_type != 'SelectorGetMember') and
		(self.bfrt_info.table_get(tbl).info.table_type != 'SnapshotCfg') and
		(self.bfrt_info.table_get(tbl).info.table_type != 'SnapshotData') and
		(self.bfrt_info.table_get(tbl).info.table_type != 'SnapshotLiveness')  and
		(self.bfrt_info.table_get(tbl).info.table_type != 'SnapshotTrigger')  and
		(self.bfrt_info.table_get(tbl).info.table_type != 'Register')  and
		(self.bfrt_info.table_get(tbl).info.table_type != 'TblDbgCnt') ):
			#print("Adding table {}".format(self.bfrt_info.table_get(tbl).info.name_get()))
			self.tables.append(self.bfrt_info.table_get(tbl))

		#This will get us around the folded pipe case where the hardcoded tables that need to be deleted after the MAT are removed
		if("lag.lag_action_profile" in self.bfrt_info.table_get(tbl).info.name_get()):		
			lag_action_paths.append(self.bfrt_info.table_get(tbl).info.name_get())
		if("lag.lag_selector" in self.bfrt_info.table_get(tbl).info.name_get()):		
			lag_selector_paths.append(self.bfrt_info.table_get(tbl).info.name_get())
		if("my_mac_lo" in self.bfrt_info.table_get(tbl).info.name_get()):		
			my_mac_lo_paths.append(self.bfrt_info.table_get(tbl).info.name_get())
		if("my_mac_hi" in self.bfrt_info.table_get(tbl).info.name_get()):		
			my_mac_hi_paths.append(self.bfrt_info.table_get(tbl).info.name_get())



	try:
		for t in self.tables:
			#print("Clearing Table2 {}".format(t.info.name_get()))
			# Empty list of keys means "all entries"
			t.entry_del(self.target, [])

			# Not all tables support default entry
			try:
				t.default_entry_reset(self.target)
			except:
				#print("default entry not supported")
				pass


	except Exception as e:
		print("Error cleaning up: {}".format(e))


	#Add a few that are not in json file
	
	#if("$mirror.cfg" in table_names): #Is this table always present?
	mirror_cfg_table = self.bfrt_info.table_get("$mirror.cfg")
	#print("  Clearing Table {}".format(mirror_cfg_table.info.name_get()))
	for sid in range(0, mirror_cfg_table.info.size):
		try:
			mirror_cfg_table.entry_del(self.target, [mirror_cfg_table.make_key([gc.KeyTuple('$sid', sid)])])
		except:
			pass

	for lag_action_path in lag_action_paths:
		if(lag_action_path in lag_action_paths):
			lag_action_table = self.bfrt_info.table_get(lag_action_path)
			#print("  Clearing Table {}".format(lag_action_table.info.name_get()))
			for ami in range(0, 32) : #lag_action_table.info.size):
				try:
					#print("Lag action profile cleared1")
					lag_action_table.entry_del(self.target, [lag_action_table.make_key([gc.KeyTuple('$ACTION_MEMBER_ID', ami)])])
				except:
					#print("Lag action profile not cleared1")
					pass

			try:
				#print("Lag action profile cleared2")
				lag_action_table.entry_del(self.target, [])
			except:
				#print("Lag action profile not cleared2")
				pass


	for lag_selector_path in lag_selector_paths:
		if(lag_selector_path in table_names):
			lag_selector_table = self.bfrt_info.table_get(lag_selector_path)
			#print("  Clearing Table {}".format(lag_selector_table.info.name_get()))
			try:
				#print("Lag selector cleared")
				lag_selector_table.entry_del(self.target, [])
			except:
				#print("Lag selector not cleared")
				pass

	
	for my_mac_lo_path in my_mac_lo_paths:
		if(my_mac_lo_path in table_names):
			my_mac_lo_table = self.bfrt_info.table_get(my_mac_lo_path)
			#print("  Clearing Table {}".format(my_mac_lo_table.info.name_get()))
			try:
				#print("My Mac lo cleared")
				my_mac_lo_table.entry_del(self.target, [])
			except:
				#print("My Mac lo not cleared")
				pass

	for my_mac_hi_path in my_mac_hi_paths:
		if(my_mac_hi_path in table_names):
			my_mac_hi_table = self.bfrt_info.table_get(my_mac_hi_path)
			#print("  Clearing Table {}".format(my_mac_hi_table.info.name_get()))
			try:
				#print("My Mac hi cleared")
				my_mac_hi_table.entry_del(self.target, [])
			except:
				#print("My Mac hi not cleared")
				pass
	 
	#if("$pre.node" in table_names):
		node_table = self.bfrt_info.table_get("$pre.node")
		#print("  Clearing Table {}".format(node_table.info.name_get()))
		for node in range(0, 32):#node_table.info.size):
			try:
				#print("Pre Node cleared", node)
				#table.entry_del(self.target, [gc.KeyTuple('$MULTICAST_NODE_ID',            node)])
				npb_pre_node_del(self, self.target, ig_pipe, node) # lower
			except:
				#print("Pre Node not cleared", node)
				pass
	
	#if("$pre.mgid" in table_names):
		mgid_table = self.bfrt_info.table_get("$pre.mgid")
		#print("  Clearing Table {}".format(mgid_table.info.name_get()))
		for mgid in range(0, 32): #mgid_table.info.size):
			try:
				#print("Pre MGID cleared", mgid)
				#table.entry_del(self.target, [gc.KeyTuple('$MGID',                         mgid)])
				npb_pre_mgid_del(self, self.target, ig_pipe, mgid=mgid)                                 # upper
			except:
				#print("Pre MGID not cleared", mgid)
				pass
