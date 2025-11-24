/**
 * @file pdcp_pcap.cc
 * @author Zishuai Cheng (5786734+WingPig99@users.noreply.github.com)
 * @brief
 * @version 0.1
 * @date 2022-08-02
 *
 * @copyright Copyright (c) 2022
 *
 */

#include "srsran/common/pdcp_pcap.h"
#include "srsran/common/pcap.h"
#include "srsran/srsran.h"

namespace srsran {
pdcp_pcap::pdcp_pcap(uint32_t DLT) : enable_write(false)
{
  dlt = DLT;
}

pdcp_pcap::~pdcp_pcap()
{
  close();
}

void pdcp_pcap::enbale()
{
  enable_write = true;
}

uint32_t pdcp_pcap::open(const char* filename)
{
  pcap_filename.assign(filename, sizeof(filename));
  pcap_file = DLT_PCAP_Open(dlt, filename);
  if (pcap_file == nullptr) {
    return SRSRAN_ERROR;
  }
  enable_write = true;
  return SRSRAN_SUCCESS;
}

void pdcp_pcap::close()
{
  enable_write = false;
  if (pcap_file != nullptr) {
    fprintf(stdout,
            "Saving PDCP(%s) PCAP file (DLT %d) to %s\n",
            dlt == PDCP_ENCRYPTED_DLT ? "Encrypted" : "Plaintext",
            dlt,
            pcap_filename.c_str());
    DLT_PCAP_Close(pcap_file);
    pcap_file = nullptr;
  }
}

void pdcp_pcap::write_dl_pdu(uint16_t rnti, uint32_t eps_bearer_id, int32_t sn, uint8_t* pdu, uint32_t pdu_len_bytes)
{
  if (enable_write) {
    PDCP_Context_Info_t context;
    context.rnti      = rnti;
    context.channelID = uint8_t(eps_bearer_id);
    context.direction = DIRECTION_DOWNLINK;
    context.sn        = sn;

    PCAP_PDCP_Write_PDU(pcap_file, &context, pdu, pdu_len_bytes);
  }
}

void pdcp_pcap::write_ul_pdu(uint16_t rnti, uint32_t eps_bearer_id, int32_t sn, uint8_t* pdu, uint32_t pdu_len_bytes)
{
  if (enable_write) {
    PDCP_Context_Info_t context;
    context.rnti      = rnti;
    context.channelID = uint8_t(eps_bearer_id);
    context.direction = DIRECTION_UPLINK;
    context.sn        = sn;

    PCAP_PDCP_Write_PDU(pcap_file, &context, pdu, pdu_len_bytes);
  }
}

} // namespace srsran