/*!
 * @file latency_stat.p4
 * @brief latency_statistic calculation
 */
#if __TARGET_TOFINO__ == 2
#include <t2na.p4>
#else
#include <tna.p4>
#endif
#include "headers.p4"

control l47_latency_flow_stat(in bit<1> first_pkt, in stats_index_t stat_index,
                      in bit<32> latency )(bit<32> num_stats) {
   @KS_stats_service_counter(Latency, eagle_counters)
   @KS_stats_service_columns(sum)
   @KS_stats_service_units(ns)
   Register<lat_tot_layout, stats_index_t>(num_stats) data_storage;
   RegisterAction<lat_tot_layout, stats_index_t, bit<32>>(data_storage)
   write_data = {
      void apply(inout lat_tot_layout value) {
         //register_data = register_data + latency;
         lat_tot_layout register_data;
         register_data = value;
         if (latency + register_data.lo <= 32w0xffffffff) {
               value.hi = register_data.hi;
         }
         else {
            value.hi = register_data.hi + 32w1;
         }
         value.lo = latency + register_data.lo;
       }
   };

   /*RegisterAction<lat_tot_layout, stats_index_t, bit<32>>(data_storage)
   first_data = {
      void apply(inout lat_tot_layout value) {
         lat_tot_layout register_data;
         register_data = value;
         value.lo = latency;
         value.hi = 0;
       }
   };*/

  /***************************************************/
  apply
   {
      //if (first_pkt == 1w0)
      //  first_data.execute(stat_index);
      //else
      write_data.execute(stat_index);
   }
}

control latency_stat( in bit<1> bank, in stats_index_t stat_index,
   in bit<32> latency ) {

   bit<1> first_pkt;
   //reset for minimum latency
   Register<bit<1>, stats_index_t>(size=FLOW_STATS_SIZE, initial_value=0) first_pkt_reg;
   l47_latency_flow_stat(FLOW_STATS_SIZE) l47_latencyA;
   @KS_stats_service_counter(Min Latency, eagle_counters)
   @KS_stats_service_columns(max)
   @KS_stats_service_units(ns)
   Register<bit<32>, stats_index_t>(size=FLOW_STATS_SIZE, initial_value=0) store_lat_minA;
   
   @KS_stats_service_counter(Max Latency, eagle_counters)
   @KS_stats_service_columns(min)
   @KS_stats_service_units(ns)
   Register<bit<32>, stats_index_t>(size=FLOW_STATS_SIZE, initial_value=0) store_lat_maxA;

   @KS_stats_service_counter(Pkt Count, eagle_counters)
   @KS_stats_service_columns(packets)
   @KS_stats_service_units(packets)
   Register<bit<32>, stats_index_t>(size=FLOW_STATS_SIZE, initial_value=0) store_pktA;

  
   RegisterAction<bit<1>, stats_index_t, bit<1>>(first_pkt_reg)
   write_first_pkt = {
      void apply(inout bit<1> register_data, out bit<1> result)
      {
         result = register_data;
         register_data = 1;
      }
   };

   RegisterAction<bit<32>, stats_index_t, bit<32>>(store_lat_minA)
   write_lat_minA = {
      void apply(inout bit<32> register_data) {
         register_data = min(latency, register_data);
      }
   };

   RegisterAction<bit<32>, stats_index_t, bit<32>>(store_lat_minA)
   first_lat_minA = {
      void apply(inout bit<32> register_data) {
         register_data = latency;
      }
   };

   RegisterAction<bit<32>, stats_index_t, bit<32>>(store_lat_maxA)
   write_lat_maxA = {
       void apply(inout bit<32> register_data) {
          register_data = max(latency, register_data);
       }
   };

   RegisterAction<bit<32>, stats_index_t, bit<32>>(store_lat_maxA)
   first_lat_maxA = {
      void apply(inout bit<32> register_data) {
         register_data = latency;
      }
   };

   RegisterAction<bit<32>, stats_index_t, bit<32>>(store_pktA)
   incr_pkt_countA = {
      void apply(inout bit<32> register_data) {
         register_data = register_data + 1;
      }
   };

  /***************************************************/
  apply
  {
      first_pkt = write_first_pkt.execute(stat_index);
      l47_latencyA.apply(first_pkt, stat_index, latency);
      if (first_pkt == 1w0)
      {
         first_lat_minA.execute(stat_index);
         first_lat_maxA.execute(stat_index);
      }
      else
      {
         write_lat_minA.execute(stat_index);
         write_lat_maxA.execute(stat_index);
      }
      incr_pkt_countA.execute(stat_index);
  }
}
