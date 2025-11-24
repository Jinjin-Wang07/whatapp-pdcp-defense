/**
 * @file pdcp_pcap.h
 * @author Zishuai Cheng (5786734+WingPig99@users.noreply.github.com)
 * @brief
 * @version 0.1
 * @date 2022-08-02
 *
 * @copyright Copyright (c) 2022
 *
 */
#ifndef SRSUE_PDCP_PCAP_H
#define SRSUE_PDCP_PCAP_H

#include <cstdio>
#include <stdint.h>
#include <string>

namespace srsran {
class pdcp_pcap
{
private:
  std::string pcap_filename;
  bool        enable_write;
  FILE*       pcap_file;
  uint32_t    dlt;

public:
  pdcp_pcap(uint32_t DLT);
  ~pdcp_pcap();
  uint32_t open(const char* filename);
  void     close();

  void enbale();

  void write_dl_pdu(uint16_t rnti, uint32_t eps_bearer_id, int32_t sn, uint8_t* pdu, uint32_t len);
  void write_ul_pdu(uint16_t rnti, uint32_t eps_bearer_id, int32_t sn, uint8_t* pdu, uint32_t len);
};
} // namespace srsran

#endif