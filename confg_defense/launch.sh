#!/bin/bash

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Navigate to the parent directory (PDCP_defense)
PDCP_DEFENSE_PATH="$(dirname "$SCRIPT_DIR")"

EPC="${PDCP_DEFENSE_PATH}/build/srsepc/src/srsepc"
ENB="${PDCP_DEFENSE_PATH}/build/srsenb/src/srsenb"
UE="${PDCP_DEFENSE_PATH}/build/srsue/src/srsue"

EPC_CONF="${PDCP_DEFENSE_PATH}/confg_defense/epc.conf"
ENB_CONF="${PDCP_DEFENSE_PATH}/confg_defense/enb.conf"
UE_CONF="${PDCP_DEFENSE_PATH}/confg_defense/ue.conf"

DB_FILE="${PDCP_DEFENSE_PATH}/confg_defense/user_db.csv"

SIB_CFG="${PDCP_DEFENSE_PATH}/confg_defense/sib.conf"
RR_CFG="${PDCP_DEFENSE_PATH}/confg_defense/rr.conf"
RB_CFG="${PDCP_DEFENSE_PATH}/confg_defense/rb.conf"

# IMPORTANT: Please fill your USRP serial number
# USRP_ENB=""
# USRP_UE=""

if [[ "$1" == "epc" ]]; then
    echo "Executing code for epc"
    $EPC $EPC_CONF --hss.db_file $DB_FILE
elif [[ "$1" == "enb_usrp" ]]; then
    echo "Executing code for enb with epc"
    if [[ -z "$USRP_ENB" ]]; then
        echo "Error: USRP_ENB parameter is empty. Please set the USRP serial number for eNodeB."
        echo "Edit the USRP_ENB variable in this script or set it as environment variable."
        exit 1
    fi
    $ENB $ENB_CONF \
    --enb_files.sib_config $SIB_CFG \
    --enb_files.rr_config $RR_CFG \
    --enb_files.rb_config $RB_CFG \
    --rf.device_name UHD \
    --rf.device_args clock=external,serial=$USRP_ENB
elif [[ "$1" == "enb_zmq" ]]; then
    echo "Executing code for enb with epc"
    $ENB $ENB_CONF \
    --enb_files.sib_config $SIB_CFG \
    --enb_files.rr_config $RR_CFG \
    --enb_files.rb_config $RB_CFG \
    --rf.device_name zmq \
    --rf.device_args fail_on_disconnect=true,tx_port=tcp://*:2000,rx_port=tcp://127.0.0.1:2001,id=enb,base_srate=23.04e6
elif [[ "$1" == "ue_usrp" ]]; then
    echo "Executing code for UE with USRP"
    if [[ -z "$USRP_UE" ]]; then
        echo "Error: USRP_UE parameter is empty. Please set the USRP serial number for UE."
        echo "Edit the USRP_UE variable in this script or set it as environment variable."
        exit 1
    fi
    # Check if network namespace ue1 exists, create if not
    if ! ip netns list | grep -q "ue1"; then
        echo "Creating network namespace ue1..."
        ip netns add ue1
        echo "Network namespace ue1 created successfully"
    fi
    $UE $UE_CONF \
    --rf.device_name UHD \
    --rf.device_args clock=external,serial=$USRP_UE
elif [[ "$1" == "ue_zmq" ]]; then
    echo "Executing code for UE with ZeroMQ"
    # Check if network namespace ue1 exists, create if not
    if ! ip netns list | grep -q "ue1"; then
        echo "Creating network namespace ue1..."
        ip netns add ue1
        echo "Network namespace ue1 created successfully"
    fi
    $UE $UE_CONF \
    --rf.device_name zmq \
    --rf.device_args tx_port=tcp://*:2001,rx_port=tcp://localhost:2000,id=ue,base_srate=23.04e6
else
    echo "Usage: $0 {epc|enb_usrp|enb_zmq|ue_usrp|ue_zmq}"
    echo ""
    echo "Available options:"
    echo "  epc      - Launch EPC (Evolved Packet Core)"
    echo "  enb_usrp - Launch eNodeB with USRP configuration"
    echo "  enb_zmq  - Launch eNodeB with ZeroMQ configuration"
    echo "  ue_usrp  - Launch UE (User Equipment) with USRP configuration"
    echo "  ue_zmq   - Launch UE (User Equipment) with ZeroMQ configuration"
    echo ""
    echo "Examples:"
    echo "  $0 epc       # Start the EPC"
    echo "  $0 enb_zmq   # Start eNodeB with ZeroMQ"
    echo "  $0 ue_zmq    # Start UE with ZeroMQ"
    exit 1
fi