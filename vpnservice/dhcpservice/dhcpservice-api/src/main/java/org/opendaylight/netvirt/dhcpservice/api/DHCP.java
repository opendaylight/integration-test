/*
 * Copyright (c) 2015 Ericsson India Global Services Pvt Ltd. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */

package org.opendaylight.netvirt.dhcpservice.api;

import static org.opendaylight.netvirt.dhcpservice.api.DHCPConstants.BOOTREPLY;
import static org.opendaylight.netvirt.dhcpservice.api.DHCPConstants.DHCP_MAX_SIZE;
import static org.opendaylight.netvirt.dhcpservice.api.DHCPConstants.DHCP_MIN_SIZE;
import static org.opendaylight.netvirt.dhcpservice.api.DHCPConstants.DHCP_NOOPT_HDR_SIZE;
import static org.opendaylight.netvirt.dhcpservice.api.DHCPConstants.HTYPE_ETHER;
import static org.opendaylight.netvirt.dhcpservice.api.DHCPConstants.MAGIC_COOKIE;
import static org.opendaylight.netvirt.dhcpservice.api.DHCPConstants.OPT_MESSAGE_TYPE;

import java.net.InetAddress;
import java.net.UnknownHostException;
import java.util.Arrays;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Map.Entry;
import org.apache.commons.lang3.ArrayUtils;
import org.apache.commons.lang3.tuple.ImmutablePair;
import org.apache.commons.lang3.tuple.Pair;
import org.opendaylight.controller.liblldp.BitBufferHelper;
import org.opendaylight.controller.liblldp.BufferException;
import org.opendaylight.controller.liblldp.HexEncode;
import org.opendaylight.controller.liblldp.NetUtils;
import org.opendaylight.controller.liblldp.Packet;
import org.opendaylight.controller.liblldp.PacketException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class DHCP extends Packet {
    protected static final Logger LOG = LoggerFactory
            .getLogger(DHCP.class);
    private static final String OP      = "Op";
    private static final String HTYPE   = "Htype";
    private static final String HLEN    = "Hlen";
    private static final String HOPS    = "Hops";
    private static final String XID     = "Xid";
    private static final String SECS    = "Secs";
    private static final String FLAGS   = "Flags";
    private static final String CIADDR  = "Ciaddr";
    private static final String YIADDR  = "Yiaddr";
    private static final String SIADDR  = "Siaddr";
    private static final String GIADDR  = "Giaddr";
    private static final String CHADDR  = "Chaddr";
    private static final String SNAME   = "Sname";
    private static final String FILE    = "File";
    private static final String MCOOKIE = "Mcookie";
    private static final String OPTIONS = "Options";
    private DHCPOptions dhcpOptions = null;

    private static Map<String, Pair<Integer, Integer>> fieldCoordinates =
            new LinkedHashMap<String, Pair<Integer, Integer>>() {
        private static final long serialVersionUID = 1L;
        {
            put(OP, new ImmutablePair<>(0, 8));
            put(HTYPE, new ImmutablePair<>(8, 8));
            put(HLEN, new ImmutablePair<>(16, 8));
            put(HOPS, new ImmutablePair<>(24, 8));
            put(XID, new ImmutablePair<>(32, 32));
            put(SECS, new ImmutablePair<>(64, 16));
            put(FLAGS, new ImmutablePair<>(80, 16));
            put(CIADDR, new ImmutablePair<>(96, 32));
            put(YIADDR, new ImmutablePair<>(128, 32));
            put(SIADDR, new ImmutablePair<>(160, 32));
            put(GIADDR, new ImmutablePair<>(192, 32));
            put(CHADDR, new ImmutablePair<>(224, 128));
            put(SNAME, new ImmutablePair<>(352, 512));
            put(FILE, new ImmutablePair<>(864, 1024));
            put(MCOOKIE, new ImmutablePair<>(1888, 32));
            put(OPTIONS, new ImmutablePair<>(1920, 0));
        }
    };

    private final Map<String, byte[]> fieldValues;

    public DHCP() {
        this(false);
    }

    public DHCP(boolean writeAccess) {
        super(writeAccess);
        fieldValues = new HashMap<>();
        hdrFieldCoordMap = fieldCoordinates;
        hdrFieldsMap = fieldValues;
        corrupted = false;

        setOp(BOOTREPLY);
        setHtype(HTYPE_ETHER);
        setHlen((byte)6);
        setHops((byte)0);
        setXid(0);
        setSecs((short) 0);
        setFlags((short) 0);
        setCiaddr(0);
        setYiaddr(0);
        setSiaddr(0);
        setGiaddr(0);
        setChaddr(new byte[16]);
        setSname(new byte[64]);
        setFile(new byte[128]);
        setMcookie(MAGIC_COOKIE);
        setOptions(new byte[0]);
        this.dhcpOptions = new DHCPOptions();
    }

    //Getters
    public byte getOp() {
        return (BitBufferHelper.getByte(fieldValues.get(OP)));
    }

    public byte getHtype() {
        return (BitBufferHelper.getByte(fieldValues.get(HTYPE)));
    }

    public byte getHlen() {
        return (BitBufferHelper.getByte(fieldValues.get(HLEN)));
    }

    public byte getHops() {
        return (BitBufferHelper.getByte(fieldValues.get(HOPS)));
    }

    public int getXid() {
        return (BitBufferHelper.getInt(fieldValues.get(XID)));
    }

    public short getSecs() {
        return (BitBufferHelper.getShort(fieldValues.get(SECS)));
    }

    public short getFlags() {
        return (BitBufferHelper.getShort(fieldValues.get(FLAGS)));
    }

    public byte[] getCiaddr() {
        return fieldValues.get(CIADDR);
    }

    public byte[] getYiaddr() {
        return fieldValues.get(YIADDR);
    }


    public byte[] getSiaddr() {
        return fieldValues.get(SIADDR);
    }

    public InetAddress getSiaddrAsInetAddr() {
        return DHCPUtils.byteArrayToInetAddr(fieldValues.get(SIADDR));
    }

    public byte[] getGiaddr() {
        return fieldValues.get(GIADDR);
    }

    public byte[] getChaddr() {
        return fieldValues.get(CHADDR);
    }

    public byte[] getSname() {
        return fieldValues.get(SNAME);
    }

    public byte[] getFile() {
        return fieldValues.get(FILE);
    }

    public int getMCookie() {
        return (BitBufferHelper.getInt(fieldValues.get(MCOOKIE)));
    }

    public byte[] getOptions() {
        return fieldValues.get(OPTIONS);
    }

//    TODO:
//    public byte[] getPadding() {
//        return this.pad;
//    }

    // Setters
    @Override
    public void setHeaderField(String headerField, byte[] readValue) {
        if (headerField.equals(OPTIONS) && (readValue == null || readValue.length == 0)) {
            hdrFieldsMap.remove(headerField);
            return;
        }
        hdrFieldsMap.put(headerField, readValue);
    }

    public DHCP setOp(byte dhcpOp) {
        byte[] op = BitBufferHelper.toByteArray(dhcpOp);
        fieldValues.put(OP, op);
        return this;
    }

    public DHCP setHtype(byte dhcpHtype) {
        byte[] htype = BitBufferHelper.toByteArray(dhcpHtype);
        fieldValues.put(HTYPE, htype);
        return this;
    }

    public DHCP setHlen(byte dhcpHlen) {
        byte[] hlen = BitBufferHelper.toByteArray(dhcpHlen);
        fieldValues.put(HLEN, hlen);
        return this;
    }

    public DHCP setHops(byte dhcpHops ) {
        byte[] hops = BitBufferHelper.toByteArray(dhcpHops);
        fieldValues.put(HOPS, hops);
        return this;
    }

    public DHCP setXid(int dhcpXid ) {
        byte[] xid = BitBufferHelper.toByteArray(dhcpXid);
        fieldValues.put(XID, xid);
        return this;
    }

    public DHCP setSecs(short dhcpSecs ) {
        byte[] secs = BitBufferHelper.toByteArray(dhcpSecs);
        fieldValues.put(SECS, secs);
        return this;
    }

    public DHCP setFlags(short dhcpFlags ) {
        byte[] flags = BitBufferHelper.toByteArray(dhcpFlags);
        fieldValues.put(FLAGS, flags);
        return this;
    }

    public DHCP setCiaddr(byte[] ciaddr) {
        fieldValues.put(CIADDR, ciaddr);
        return this;
    }

    public DHCP setCiaddr(int dhcpCiaddr ) {
        byte[] ciaddr = BitBufferHelper.toByteArray(dhcpCiaddr);
        fieldValues.put(CIADDR, ciaddr);
        return this;
    }

    public DHCP setCiaddr(InetAddress dhcpCiaddr ) {
        byte[] ciaddr = dhcpCiaddr.getAddress();
        fieldValues.put(CIADDR, ciaddr);
        return this;
    }

    public DHCP setCiaddr(String dhcpCiaddr) {
        byte[] ciaddr = NetUtils.parseInetAddress(dhcpCiaddr).getAddress();
        fieldValues.put(CIADDR, ciaddr);
        return this;
    }

    public DHCP setYiaddr(byte[] yiaddr) {
        fieldValues.put(YIADDR, yiaddr);
        return this;
    }

    public DHCP setYiaddr(int dhcpYiaddr ) {
        byte[] yiaddr = BitBufferHelper.toByteArray(dhcpYiaddr);
        fieldValues.put(YIADDR, yiaddr);
        return this;
    }

    public DHCP setYiaddr(InetAddress dhcpYiaddr ) {
        byte[] yiaddr = dhcpYiaddr.getAddress();
        fieldValues.put(YIADDR, yiaddr);
        return this;
    }

    public DHCP setYiaddr(String dhcpYiaddr) {
        byte[] yiaddr = NetUtils.parseInetAddress(dhcpYiaddr).getAddress();
        fieldValues.put(YIADDR, yiaddr);
        return this;
    }

    public DHCP setSiaddr(byte[] siaddr) {
        fieldValues.put(SIADDR, siaddr);
        return this;
    }

    public DHCP setSiaddr(int dhcpSiaddr ) {
        byte[] siaddr = BitBufferHelper.toByteArray(dhcpSiaddr);
        fieldValues.put(SIADDR, siaddr);
        return this;
    }

    public DHCP setSiaddr(InetAddress dhcpSiaddr ) {
        byte[] siaddr = dhcpSiaddr.getAddress();
        fieldValues.put(SIADDR, siaddr);
        return this;
    }

    public DHCP setSiaddr(String dhcpSiaddr) {
        byte[] siaddr = NetUtils.parseInetAddress(dhcpSiaddr).getAddress();
        fieldValues.put(SIADDR, siaddr);
        return this;
    }

    public DHCP setGiaddr(byte[] giaddr) {
        fieldValues.put(GIADDR, giaddr);
        return this;
    }

    public DHCP setGiaddr(int dhcpGiaddr ) {
        byte[] giaddr = BitBufferHelper.toByteArray(dhcpGiaddr);
        fieldValues.put(GIADDR, giaddr);
        return this;
    }

    public DHCP setGiaddr(InetAddress dhcpGiaddr ) {
        byte[] giaddr = dhcpGiaddr.getAddress();
        fieldValues.put(GIADDR, giaddr);
        return this;
    }

    public DHCP setGiaddr(String dhcpGiaddr) {
        byte[] giaddr = NetUtils.parseInetAddress(dhcpGiaddr).getAddress();
        fieldValues.put(GIADDR, giaddr);
        return this;
    }

    public DHCP setChaddr(byte[] chaddr) {
        fieldValues.put(CHADDR, chaddr);
        return this;
    }

    public DHCP setSname(byte[] sname) {
        fieldValues.put(SNAME, sname);
        return this;
    }

    public DHCP setFile(byte[] file) {
        fieldValues.put(FILE, file);
        return this;
    }

    public DHCP setMcookie(int dhcpMc ) {
        byte[] mc = BitBufferHelper.toByteArray(dhcpMc);
        fieldValues.put(MCOOKIE, mc);
        return this;
    }

    public DHCP setOptions(byte[] options) {
        fieldValues.put(OPTIONS, options);
        return this;
    }

//    public void setPadding(byte[] pad) {
//        this.pad = pad;
//    }

    /**
     * This method deserializes the data bits obtained from the wire into the
     * respective header and payload which are of type Packet.
     *
     * @param data       byte[] data from wire to deserialize
     * @param bitOffset  int    bit position where packet header starts in data
     *        array
     * @param size       int    size of packet in bits
     * @return Packet
     * @throws PacketException the packet deserialization failed
     *
     * <p>Note: Copied from org.opendaylight.controller.sal.packet.Packet</p>
     */
    @Override
    public Packet deserialize(byte[] data, int bitOffset, int size)
            throws PacketException {

        // Deserialize the header fields one by one
        int startOffset = 0;
        int numBits = 0;
        for (Entry<String, Pair<Integer, Integer>> pairs : hdrFieldCoordMap
                .entrySet()) {
            String hdrField = pairs.getKey();
            startOffset = bitOffset + this.getfieldOffset(hdrField);
            if (hdrField.equals(OPTIONS)) {
                numBits = (size - DHCP_NOOPT_HDR_SIZE) * 8;
            } else {
                numBits = this.getfieldnumBits(hdrField);
            }
            byte[] hdrFieldBytes = null;
            try {
                hdrFieldBytes = BitBufferHelper.getBits(data, startOffset,
                        numBits);
            } catch (BufferException e) {
                throw new PacketException(e.getMessage());
            }

            /*
             * Store the raw read value, checks the payload type and set the
             * payloadClass accordingly
             */
            this.setHeaderField(hdrField, hdrFieldBytes);

            if (LOG.isTraceEnabled()) {
                LOG.trace("{}: {}: {} (offset {} bitsize {})",
                        this.getClass().getSimpleName(), hdrField,
                        HexEncode.bytesToHexString(hdrFieldBytes),
                        startOffset, numBits);
            }
        }

        // Deserialize the payload now
        int payloadStart = startOffset + numBits;
        int payloadSize = data.length * NetUtils.NumBitsInAByte - payloadStart;

        if (payloadClass != null) {
            try {
                payload = payloadClass.newInstance();
            } catch (InstantiationException | IllegalAccessException e) {
                throw new RuntimeException(
                        "Error parsing payload for Ethernet packet", e);
            }
            payload.deserialize(data, payloadStart, payloadSize);
            payload.setParent(this);
        } else {
            /*
             *  The payload class was not set, it means no class for parsing
             *  this payload is present. Let's store the raw payload if any.
             */
            int start = payloadStart / NetUtils.NumBitsInAByte;
            int stop = start + payloadSize / NetUtils.NumBitsInAByte;
            rawPayload = Arrays.copyOfRange(data, start, stop);
        }
        // Take care of computation that can be done only after deserialization
        postDeserializeCustomOperation(data, payloadStart - getHeaderSize());

        return this;
    }

    @Override
    public byte[] serialize() throws PacketException {
        this.setOptions(this.dhcpOptions.serialize());
        byte[] data = super.serialize();
        // Check for OPT_END at end of options
        if (data.length > DHCP_MAX_SIZE) {
            // shouldn't have happened
            // Add exception?
            LOG.error("DHCP Packet too big");
        } else if (data[data.length - 1] != (byte)255) {
            // DHCP Options not ended properly
            //throw new PacketException("Missing DHCP Option END");
            LOG.error("Missing DHCP Option END");
        } else if (data.length < DHCP_MIN_SIZE) {
            byte[] padding = new byte[DHCP_MIN_SIZE - data.length];
            LOG.debug("DHCP Pkt too small: {}, padding added {}",
                    data.length, padding.length);
            data = ArrayUtils.addAll(data, padding);
        }
        return data;
    }

    @Override
    /**
     * Gets the number of bits for the fieldname specified
     * If the fieldname has variable length like "Options", then this value is computed using the header length
     * @param fieldname - String
     * @return number of bits for fieldname - int
     */
    public int getfieldnumBits(String fieldName) {
        if (fieldName.equals(OPTIONS)) {
            byte[] barr = fieldValues.get(OPTIONS);
            return (barr.length) * NetUtils.NumBitsInAByte;
        }
        return hdrFieldCoordMap.get(fieldName).getRight();
    }

    @Override
    public int getHeaderSize() {
        byte[] barr = fieldValues.get(OPTIONS);
        int len = 0;
        if (barr != null) {
            len = barr.length;
        }
        return (DHCP_NOOPT_HDR_SIZE + len) * 8;
    }

    @Override
    protected void postDeserializeCustomOperation(byte[] data, int startBitOffset) {
        //TODO: Anything need to be done here?
        // Check for MAGIC_COOKIE. This means we only support DHCP, not BOOTP
        int cookie = BitBufferHelper.getInt(fieldValues.get(MCOOKIE));
        if (cookie != MAGIC_COOKIE) {
            LOG.debug("Not DHCP packet");
            // Throw exception?
        }
        // parse options into DHCPOptions
        this.dhcpOptions.deserialize(this.getOptions());
        // reset options byte array, this will also drop padding
        this.setOptions(this.dhcpOptions.serialize());
    }

    // Set/get operations for Options
    public void setMsgType(byte type) {
        dhcpOptions.setOptionByte(OPT_MESSAGE_TYPE, type);
    }

    public byte getMsgType() {
        return dhcpOptions.getOptionByte(OPT_MESSAGE_TYPE);
    }

    public void setOptionByte(byte code, byte opt) {
        dhcpOptions.setOptionByte(code, opt);
    }

    public byte getOptionByte(byte code) {
        return dhcpOptions.getOptionByte(code);
    }

    public void setOptionBytes(byte code, byte[] opt) {
        dhcpOptions.setOption(code, opt);
    }

    public byte[] getOptionBytes(byte code) {
        return dhcpOptions.getOptionBytes(code);
    }

    public void setOptionShort(byte code, short opt) {
        dhcpOptions.setOptionShort(code, opt);
    }

    public short getOptionShort(byte code) {
        return dhcpOptions.getOptionShort(code);
    }

    public void setOptionInt(byte code, int opt) {
        dhcpOptions.setOptionInt(code, opt);
    }

    public int getOptionInt(byte code) {
        return dhcpOptions.getOptionInt(code);
    }

    public InetAddress getOptionInetAddr(byte code) {
        return dhcpOptions.getOptionInetAddr(code);
    }

    public void setOptionInetAddr(byte code, InetAddress addr) {
        dhcpOptions.setOptionInetAddr(code, addr);
    }

    public void setOptionInetAddr(byte code, String addr) throws UnknownHostException {
        dhcpOptions.setOptionStrAddr(code, addr);
    }

    public String getOptionStrAddr(byte code) {
        return dhcpOptions.getOptionStrAddr(code);
    }

    public void setOptionStrAddrs(byte code, List<String> opt) throws UnknownHostException {
        dhcpOptions.setOptionStrAddrs(code, opt);
    }

    public void setOptionString(byte code, String str) {
        dhcpOptions.setOptionString(code, str);
    }

    public boolean containsOption(byte code) {
        // TODO Auto-generated method stub
        return dhcpOptions.containsOption(code);
    }

    public void unsetOption(byte code) {
        dhcpOptions.unsetOption(code);
    }

    @Override
    public String toString() {
        StringBuilder ret = new StringBuilder();
        ret.append(super.toString()).append(dhcpOptions);

        return ret.toString();
    }
}
