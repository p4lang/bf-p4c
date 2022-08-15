
# The following code gets appended to the following file:
# $SDE/pkgsrc/ptf-modules/ptf/src/ptf/packet.py

VNTag = None
if not config.get("disable_vntag", False):
    try:
        scapy.main.load_contrib("vntag")
        VNTag = scapy.contrib.vntag.VNTag
        logging.info("VNTag support found in Scapy")
    except:
        logging.warn("VNTag support not found in Scapy")
        pass


Dot1BR = None
if not config.get("disable_dot1br", False):
    try:
        scapy.main.load_contrib("dot1br")
        Dot1BR = scapy.contrib.dot1br.Dot1BR
        logging.info("Dot1BR support found in Scapy")
    except:
        logging.warn("Dot1BR support not found in Scapy")
        pass

#GTPHeader = None
GTP_U_Header = None
if not config.get("disable_gtp", False):
    try:
        scapy.main.load_contrib("gtp")
        #GTPHeader = scapy.contrib.gtp.GTPHeader
        GTP_U_Header = scapy.contrib.gtp.GTP_U_Header
        logging.info("GTP support found in Scapy")
    except:
        logging.warn("GTP support not found in Scapy")
        pass

GTPHeader = None
if not config.get("disable_gtp_v2", False):
    try:
        scapy.main.load_contrib("gtp_v2")
        GTPHeader = scapy.contrib.gtp_v2.GTPHeader
        logging.info("GTP_V2 support found in Scapy")
    except:
        logging.warn("GTP_V2 support not found in Scapy")
        pass



DTEL = None
if not config.get("disable_dtel", False):
    try:
        scapy.main.load_contrib("dtel")
        DTEL = scapy.contrib.dtel.DTEL
        logging.info("DTEL support found in Scapy")
    except:
        logging.warn("DTEL support not found in Scapy")
        pass


NSH = None
NSHTLV = None
Metadata = None
if not config.get("disable_nsh", False):
    try:
        scapy.main.load_contrib("nsh")
        NSH = scapy.contrib.nsh.NSH
        NSHTLV = scapy.contrib.nsh.NSHTLV
        Metadata = scapy.contrib.nsh.Metadata
        logging.info("NSH support found in Scapy")
    except:
        logging.warn("NSH support not found in Scapy")
        pass


NpbFabric = None
NpbCpu = None
if not config.get("disable_extreme_npb_cpu", False):
    try:
        scapy.main.load_contrib("extreme_npb_cpu")
        NpbFabric = scapy.contrib.extreme_npb_cpu.NpbFabric
        NpbCpu = scapy.contrib.extreme_npb_cpu.NpbCpu
        logging.info("Extreme NpbCpu support found in Scapy")
    except:
        logging.warn("Extreme NpbCpu support not found in Scapy")
        pass


SlowProtocol = None
LACP = None
MarkerProtocol = None
if not config.get("disable_lacp", False):
    try:
        scapy.main.load_contrib("lacp")
        SlowProtocol = scapy.contrib.lacp.SlowProtocol
        LACP = scapy.contrib.lacp.LACP
        MarkerProtocol = scapy.contrib.lacp.MarkerProtocol
        logging.info("LACP support found in Scapy")
    except:
        logging.warn("LACP support not found in Scapy")
        pass

    
ERSPAN = None
if not config.get("disable_erspan", False):
    try:
        scapy.main.load_contrib("erspan")
        ERSPAN = scapy.contrib.erspan.ERSPAN
        logging.info("ERSPAN support found in Scapy")
    except:
        logging.warn("ERSPAN support not found in Scapy")
        pass


NVGRE = None
if not config.get("disable_nvgre", False):
    try:
        scapy.main.load_contrib("nvgre")
        NVGRE = scapy.contrib.nvgre.NVGRE
        logging.info("NVGRE support found in Scapy")
    except:
        logging.warn("NVGRE support not found in Scapy")
        pass

    
GENEVE = None
if not config.get("disable_geneve", False):
    try:
        scapy.main.load_contrib("geneve")
        GENEVE = scapy.contrib.geneve.GENEVE
        logging.info("GENEVE support found in Scapy")
    except:
        logging.warn("GENEVE support not found in Scapy")
        pass

# VXLAN = None
# if not config.get("disable_vxlan", False):
#     try:
#         scapy.main.load_contrib("vxlan")
#         VXLAN = scapy.contrib.vxlan.VXLAN
#         logging.info("VXLAN support found in Scapy")
#     except:
#         logging.warn("VXLAN support not found in Scapy")
#         pass

# VXLAN = None
# if not config.get("disable_vxlan", False):
#     try:
#         scapy.main.load_layer("vxlan")
#         VXLAN = scapy.layer.vxlan.VXLAN
#         logging.info("VXLAN support found in Scapy")
#     except:
#         logging.warn("VXLAN support not found in Scapy")
#         pass

SPBM = None
if not config.get("disable_spbm", False):
    try:
        scapy.main.load_contrib("spbm")
        SPBM = scapy.contrib.spbm.SPBM
        logging.info("SPBM support found in Scapy")
    except:
        logging.warn("SPBM support not found in Scapy")
        pass
