/**
 * @file ip_reassemble.h
 * @author Zishuai Cheng (5786734+WingPig99@users.noreply.github.com)
 * @brief
 * @version 0.1
 * @date 2022-09-16
 *
 * @copyright Copyright (c) 2022
 *
 */
#include "srsran/common/byte_buffer.h"
#include "srsran/common/standard_streams.h"
#include <atomic>
#include <cstdint>

#ifndef SRSRAN_IP_REASSEMBLE_H
#define SRSRAN_IP_REASSEMBLE_H
namespace srsran {
namespace pdcp_utils {
typedef enum { Unkown = 0, IPv4 = 4, IPv6 = 6 } ip_version_t;
typedef struct ip_pkt {
  ip_version_t         version;
  uint8_t              hdr_len;
  uint16_t             len;
  unique_byte_buffer_t data;
  std::atomic<bool>    waiting_hdr  = {false};
  std::atomic<bool>    waiting_body = {false};

  ip_pkt() { reset(); }
  ~ip_pkt() = default;

  void reset()
  {
    version      = ip_version_t::Unkown;
    hdr_len      = 0;
    len          = 0;
    data         = make_byte_buffer();
    waiting_hdr  = false;
    waiting_body = false;
  }

  int append(unique_byte_buffer_t& pdu, uint32_t sn)
  {
    uint8_t sum = 0;
    for (uint32_t i = 0; i < pdu->N_bytes; i++) {
      sum |= pdu->msg[i];
    }

    if (data->N_bytes == 0 && sum == 0) {
      // this is padding
      pdu->msg += pdu->N_bytes;
      pdu->N_bytes = 0;
      return -1;
    }
    // decode the first nibble to determine the version of IP packet
    if (hdr_len == 0) {
      switch (pdu->msg[0] >> 4) {
        case 4:
          version     = ip_version_t::IPv4;
          hdr_len     = 20;
          waiting_hdr = true;
          break;
        case 6:
          version     = ip_version_t::IPv6;
          hdr_len     = 40;
          waiting_hdr = true;
          break;
        default:
          srsran::console("failed in reassemble PDCP packet %lu\n", sn);
          srsran::console_hex(pdu->msg, pdu->N_bytes);
          // exit(0);
          return 0;
          break;
      }
    }
    // reassemble the header part
    if (waiting_hdr) {
      uint8_t rmng_hdr = hdr_len - data->N_bytes;
      if (rmng_hdr > pdu->N_bytes) {
        // copy all contents from pdu to data, and still needs to wait next packt to reassemble the header
        data->append_bytes(pdu->msg, pdu->N_bytes);
        pdu->msg += pdu->N_bytes;
        pdu->N_bytes = 0;
        return 0;
      } else {
        // copy part of pdu to data
        data->append_bytes(pdu->msg, rmng_hdr);
        pdu->msg += rmng_hdr;
        pdu->N_bytes -= rmng_hdr;
        waiting_hdr = false;
      }
    }
    // decode the IP packet header
    if (waiting_hdr == false && waiting_body == false) {
      IP_pkt_len(data->msg);
      waiting_body = true;
    }
    if (waiting_body == true) {
      uint16_t rmng = len - data->N_bytes;
      if (pdu->N_bytes >= rmng) {
        data->append_bytes(pdu->msg, rmng);
        pdu->msg += rmng;
        pdu->N_bytes -= rmng;
        return 1;
      } else {
        data->append_bytes(pdu->msg, pdu->N_bytes);
        pdu->msg += pdu->N_bytes;
        pdu->N_bytes = 0;
        return 0;
      }
    }
    return -1;
  }

  void IP_pkt_len(uint8_t* payload)
  {
    if (version == ip_version_t::IPv4) {
      // IPv4
      len |= payload[2] << 8;
      len |= payload[3];
    } else if (version == ip_version_t::IPv6) {
      // IPv6
      len |= payload[4] << 8;
      len |= payload[5];
      len += hdr_len;
    }
  }
} ip_pkt_t;

} // namespace pdcp_utils
} // namespace srsran
#endif