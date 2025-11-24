-- IP wrapper
 -- Extend Wireshark's default IP dissector for PDCP data

 local ip_wrapper_proto = Proto("ip_pdcp", "Extra analysis of the SRSRLY-PDCP data")

 -- Extra fields
 local F_IP_rnti = ProtoField.uint16("ip.rnti", "RNTI", base.DEC)
 local F_IP_direction = ProtoField.uint8("ip.dir", "Direction", base.DEC)
 local F_IP_lcid = ProtoField.uint16("ip.lcid", "LCID", base.DEC)
 local F_IP_type = ProtoField.uint8("ip.type", "DataType", base.DEC)
 local F_IP_sn = ProtoField.uint32("ip.sn", "Sequence Number", base.DEC)
 local F_IP_len = ProtoField.uint16("ip.len", "Length", base.DEC)

 ip_wrapper_proto.fields = {F_IP_rnti, F_IP_direction, F_IP_lcid, F_IP_type, F_IP_sn, F_IP_len}

 -- Dissectors
 local ip_dissector = Dissector.get("ip")

 local direction_opts = {
     [0] = "UPLINK",
     [1] = "DOWNLINK"
 }
 local dataType_opts = {
     [0] = "Normal",
     [1] = "Multicast"
 }
 function ip_wrapper_proto.dissector(tvbuffer, pinfo, treeitem)
     local itemtext = "Unknown"
     local subtreeitem = treeitem:add(ip_wrapper_proto, tvbuffer)
     pinfo.cols.protocol = "IP_Extra"

     -- RNTI
     local rnti =tvbuffer(0,2):uint()
     subtreeitem:add(F_IP_rnti, tvbuffer(0,2), rnti):set_text(
         string.format("RNTI: %d (0x%x)", rnti, rnti))
     -- Direction
     local direction = tvbuffer(2, 1):uint()
     subtreeitem:add(F_IP_direction, tvbuffer(2, 1), direction):set_text(
         string.format("Direction: %d (%s)",direction,direction_opts[direction]))
     -- LCID
     local lcid = tvbuffer(3, 2):uint()
     if lcid == 1 then
         itemtext = "SRB 1"
     elseif lcid == 2 then
         itemtext = "SRB 2"
     elseif lcid >= 3 then
         if lcid == 3 then
             itemtext = string.format("DRB 1 (Normal Internet)")
         elseif lcid == 4 then
             itemtext = string.format("DRB 2 (SIP Signalling)")
         elseif lcid == 5 then
             itemtext = string.format("DRB 3 (Voice Data)")
         else
             itemtext = string.format("DRB %d (Unkown)", lcid-2)
         end
     end
     subtreeitem:add(F_IP_lcid, tvbuffer(3, 2), lcid):set_text(
         string.format("LCID: %d (%s)", lcid, itemtext)
     )
     -- SN
     local sn = tvbuffer(5, 4):int()
     if sn == -1 then
         subtreeitem:add(F_IP_type, tvbuffer(5, 4), sn):set_text(
             string.format("Sequence Number: %d (Invalid)", sn)
         )
     else
         subtreeitem:add(F_IP_type, tvbuffer(5, 4), sn):set_text(
             string.format("Sequence Number: %d", sn)
         )
     end
     -- Lenth
     local len =tvbuffer(9,2):uint()
     subtreeitem:add(F_IP_len, tvbuffer(9,2), len):set_text(
         string.format("Length: %d", len))

     -- decode reamind data
     local raw_data = tvbuffer(11, tvbuffer:len() - 11)
     ip_dissector:call(raw_data:tvb(), pinfo, treeitem)
 end