switch.p4
=========

The switch.p4 program describes a data plane of an L2/L3 switch.

Supported Features
------------------
1. Basic L2 switching: Flooding, learning and STP
2. Basic L3 Routing: IPv4 and IPv6 and VRF
3. LAG
4. ECMP
5. Tunneling: VXLAN
6. Basic ACL: MAC and IP ACLs
7. Unicast RPF check
8. Host interface
9. Mirroring: Ingress and egress mirroring with ERSPAN
10. Counters/Statistics


Naming Convention
-----------------
1. Types and struct types are named using lower case words separated by `_`
  followed by `_t`. For example, `switch_port_t`.
2. Control types and extern object types are named using CamelCase. For
  example `IngressParser`.
3. Actions, extern methods, extern functions, headers, structs, and
  instances of controls and externs start with lower case and words
  are separated using `_`. For example `send_to_port`.
4. Enum members, const definitions, and #define constants are all
  caps, with words separated by `_`. For example 'ETHERTYPE_IPV4'.


