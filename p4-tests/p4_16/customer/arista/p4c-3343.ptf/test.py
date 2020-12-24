################################################################################
# BAREFOOT NETWORKS CONFIDENTIAL & PROPRIETARY
#
# Copyright (c) 2018-2019 Barefoot Networks, Inc.

# All Rights Reserved.
#
# NOTICE: All information contained herein is, and remains the property of
# Barefoot Networks, Inc. and its suppliers, if any. The intellectual and
# technical concepts contained herein are proprietary to Barefoot Networks,
# Inc.
# and its suppliers and may be covered by U.S. and Foreign Patents, patents in
# process, and are protected by trade secret or copyright law.
# Dissemination of this information or reproduction of this material is
# strictly forbidden unless prior written permission is obtained from
# Barefoot Networks, Inc.
#
# No warranty, explicit or implicit is provided, unless granted under a
# written agreement with Barefoot Networks, Inc.
#
###############################################################################

import logging
import pdb

from ptf import config
from ptf.thriftutils import *
from ptf.testutils import *

from bfruntime_client_base_tests import BfRuntimeTest
import bfrt_grpc.bfruntime_pb2 as bfruntime_pb2
import bfrt_grpc.client as gc

logger = logging.getLogger                   ('Test')
logger.addHandler(logging.StreamHandler())

swports = []
for device, port, ifname in config["interfaces"]:
    swports.append(port)
    swports.sort()

if swports == []:
    swports = range(9)

p4_name = "p4c_3343"
num_pipes = int(test_param_get('num_pipes'))

tbl_def_actions = [('Sunman', 'McKenney'),
                   ('FairOaks', 'Chewalla'),
                   ('Baranof', 'Bucklin'),
                   ('Anita', 'NoAction'),
                   ('Cairo', 'Chewalla'),
                   ('Spanaway', 'Yulee'),
                   ('Leland', 'Dahlgren'),
                   ('Lewellen', 'Chewalla'),
                   ('Absecon', 'Chewalla'),
                   ('Skene', 'Chewalla'),
                   ('Scottdale', 'NoAction'),
                   ('Horatio', 'Chewalla'),
                   ('Rives', 'NoAction'),
                   ('Sedona', 'Chewalla'),
                   ('Kotzebue', 'RedLake'),
                   ('Felton', 'Ruston'),
                   ('Arial', 'LaPlant'),
                   ('Amalga', 'Laclede'),
                   ('Meyers', 'NoAction'),
                   ('Pachuta', 'BigRock'),
                   ('Amherst', 'NoAction'),
                   ('Luttrell', 'Woodsboro'),
                   ('Papeton', 'Oregon'),
                   #('Yatesboro', 'NoAction'),
                   ('Maxwelton', 'Bostic'),
                   ('Ihlen', 'NoAction'),
                   ('Faulkton', 'NoAction'),
                   ('Philmont', 'Chewalla'),
                   ('ElCentro', 'NoAction'),
                   ('Bains', 'Macon'),
                   ('Islen', 'Mayview'),
                   ('BarNunn', 'Neosho'),
                   ('Aptos', 'Somis'),
                   ('Miltona', 'Rhodell'),
                   ('Wakeman', 'Wakefield'),
                   ('DeRidder', 'Mendoza'),
                   ('Bechyn', 'NoAction'),
                   ('Cropper', 'Barnwell'),
                   ('Blakeman', 'NoAction'),
                   ('Palco', 'Chewalla'),
                   ('Farner', 'FourTown'),
                   ('Mondovi', 'Forepaugh'),
                   ('Govan', 'OldTown'),
                   ('McKee', 'Rumson'),
                   ('Brownson', 'Jauca'),
                   #('Owentown', 'NoAction'),
                   ('Basye', 'NoAction'),
                   ('Berlin', 'Agawam'),
                   ('Addicks', 'Astatula'),
                   ('Wyandanch', 'NoAction'),
                   ('Inkom', 'NoAction'),
                   ('Clermont', 'NoAction'),
                   ('Ghent', 'Snook'),
                   ('Encinitas', 'Goldsmith'),
                   ('DeBeque', 'NoAction'),
                   ('Langhorne', 'Cornwall'),
                   ('Natalbany', 'Bovina'),
                   ('Romeo', 'NoAction'),
                   ('Carlson', 'NoAction'),
                   ('Newland', 'Kevil'),
                   ('Gunder', 'NoAction'),
                   ('Amsterdam', 'Luverne'),
                   ('Council', 'NoAction'),
                   ('Belcourt', 'Doyline'),
                   ('Corydon', 'NoAction'),
                   ('Bluff', 'Comunas'),
                   ('Archer', 'NoAction'),
                   #('Mynard', 'Redfield'),
                   ('Mantee', 'Deeth'),
                   ('Walland', 'Buras'),
                   ('Chalco', 'Angeles'),
                   ('Broadford', 'Ferndale'),
                   ('Trail', 'Tillicum'),
                   ('Boyes', 'NoAction'),
                   ('Renfroe', 'Chewalla'),
                   ('McCallum', 'NoAction'),
                   ('Waucousta', 'Nicollet'),
                   ('Selvin', 'NoAction'),
                   ('Kiron', 'Kinard'),
                   ('DewyRose', 'Pendleton'),
                   ('Chandalar', 'NoAction'),
                   ('Burgdorf', 'NoAction'),
                   ('Haworth', 'NoAction'),
                   ('Shauck', 'NoAction'),
                   ('Picacho', 'Veradale'),
                   ('Covington', 'Sanatoga'),
                   ('Cisne', 'NoAction'),
                   ('Perryton', 'Chewalla'),
                   ('Stamford', 'Engle'),
                   ('Tampa', 'Sultana'),
                   ('Pierson', 'NoAction'),
                   ('Piedmont', 'NoAction'),
                   ('Ripley', 'NoAction'),
                   ('Conejo', 'Chewalla'),
                   ('Nordheim', 'NoAction'),
                   ('Canton', 'NoAction'),
                   ('Waterford', 'NoAction'),
                   ('Browning', 'Naguabo'),
                   ('Arion', 'NoAction'),
                   ('Asher', 'Burnett'),
                   ('Lovett', 'NoAction'),
                   ('Rembrandt', 'Cruso'),
                   ('Valmont', 'NoAction'),
                   ('Waretown', 'Decorah'),
                   ('Stout', 'NoAction'),
                   ('Forbes', 'Ludowici'),
                   ('Dedham', 'Wrens'),
                   ('Statham', 'Doral'),
                   ('Folcroft', 'Albin'),
                   ('Sharon', 'Neuse'),
                   ('Separ', 'Supai'),
                   ('Hookstown', 'Rodessa'),
                   ('FarrWest', 'Holcut'),
                   ('Aguilita', 'NoAction'),
                   ('Mocane', 'Anniston'),
                   ('Easley', 'Nashua'),
                   ('Rawson', 'NoAction'),
                   ('Oakford', 'NoAction'),
                   ('Switzer', 'Tolley'),
                   ('Flats', 'BigBay'),
                   ('Lenapah', 'Wildell'),
                   #('Colburn', 'NoAction'),
                   ('Kirkwood', 'Chewalla'),
                   ('Munich', 'NoAction'),
                   ('Nuevo', 'NoAction'),
                   ('Vincent', 'NoAction'),
                   ('Cowan', 'Sigsbee'),
                   ('Masardis', 'NoAction'),
                   ('WolfTrap', 'NoAction ')]

class TestMasardis(BfRuntimeTest):
  ''' Test Masardis table '''
  def setUp(self):
    client_id = 0
    BfRuntimeTest.setUp(self, client_id, p4_name)
    self.bfrt_info = self.interface.bfrt_info_get(p4_name)

  def tearDown(self):
    #trgt = gc.Target(device_id=0, pipe_id=0xFFFF)
    #for tbl, dflt_act in tbl_def_actions:
    #    logger.info("Deleting entry for table %s", tbl)
    #    t = self.bfrt_info.table_get(tbl)
    #    if t: t.entry_del(trgt)
    #BfRuntimeTest.tearDown(self)
    pass

  def runTest(self):
    print(num_pipes)
    trgt = gc.Target(device_id=0, pipe_id=0xFFFF)

    #for tbl, dflt_act in tbl_def_actions:
    #    logger.info("Testing table %s", tbl)
    #    t = self.bfrt_info.table_get(tbl)
        
    t = self.bfrt_info.table_get('Masardis')
    #t.attribute_entry_scope_set(trgt,
    #        predefined_pipe_scope=True,
    #        predefined_pipe_scope_val=bfruntime_pb2.Mode.ALL)
    t.attribute_entry_scope_set(trgt,
            predefined_pipe_scope=True,
            predefined_pipe_scope_val=bfruntime_pb2.Mode.SINGLE)
