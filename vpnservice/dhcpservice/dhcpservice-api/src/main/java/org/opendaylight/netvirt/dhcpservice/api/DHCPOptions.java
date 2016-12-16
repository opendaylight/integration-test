/*
 * Copyright (c) 2015 Ericsson India Global Services Pvt Ltd. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */

package org.opendaylight.netvirt.dhcpservice.api;

import static org.opendaylight.netvirt.dhcpservice.api.DHCPConstants.OPT_END;
import static org.opendaylight.netvirt.dhcpservice.api.DHCPConstants.OPT_PAD;

import java.net.InetAddress;
import java.net.UnknownHostException;
import java.util.LinkedHashMap;
import java.util.List;
import org.apache.commons.lang3.ArrayUtils;
import org.opendaylight.controller.liblldp.HexEncode;
import org.opendaylight.controller.liblldp.NetUtils;

public class DHCPOptions {

    class DhcpOption {
        private byte code;
        private byte length;
        private byte[] value;

        DhcpOption(byte code, byte[] value) {
            if ((code != OPT_PAD) && (code != OPT_END) && (value != null)) {
                this.code = code;
                this.value = value;
                this.length = (byte) value.length;
            }
        }

        public byte getCode() {
            return this.code;
        }

        public byte[] getValue() {
            return this.value;
        }

        public byte[] serialize() {
            byte[] opt1 = new byte[2];
            opt1[0] = this.code;
            opt1[1] = this.length;
            return ArrayUtils.addAll(opt1, this.value);
        }

        @Override
        public String toString() {
            StringBuilder sb = new StringBuilder();
            sb.append("{ ")
                    .append("code: ").append(this.code)
                    .append(", len: ").append(this.length)
                    .append(", value: 0x").append(HexEncode.bytesToHexString(this.value))
                    .append(" }");
            return sb.toString();
        }
    }

    private LinkedHashMap<Byte, DhcpOption> options;

    public DHCPOptions() {
        options = new LinkedHashMap<>();
    }

    private DhcpOption getOption(byte code) {
        return this.options.get(code);
    }

    private void setOption(DhcpOption opt) {
        this.options.put(opt.getCode(), opt);
    }

    public void setOption(byte code, byte[] opt) {
        this.setOption(new DhcpOption(code, opt));
    }

    public byte[] getOptionBytes(byte code) {
        try {
            return this.getOption(code).getValue();
        } catch (NullPointerException e) {
            return null;
        }
    }

    public void setOptionByte(byte code, byte opt) {
        this.setOption(new DhcpOption(code, DHCPUtils.byteToByteArray(opt)));
    }

    public byte getOptionByte(byte code) {
        return this.getOption(code).getValue()[0];
    }

    public void setOptionShort(byte code, short opt) {
        this.setOption(new DhcpOption(code, DHCPUtils.shortToByteArray(opt)));
    }

    public short getOptionShort(byte code) {
        byte[] opt = this.getOptionBytes(code);
        return DHCPUtils.byteArrayToShort(opt);
    }

    public void setOptionInt(byte code, int opt) {
        this.setOption(new DhcpOption(code, DHCPUtils.intToByteArray(opt)));
    }

    public int getOptionInt(byte code) {
        byte[] opt = this.getOptionBytes(code);
        return NetUtils.byteArray4ToInt(opt);
    }

    public void setOptionInetAddr(byte code, InetAddress opt) {
        this.setOption(new DhcpOption(code, DHCPUtils.inetAddrToByteArray(opt)));
    }

    public InetAddress getOptionInetAddr(byte code) {
        byte[] opt = this.getOptionBytes(code);
        try {
            return InetAddress.getByAddress(opt);
        } catch (UnknownHostException | NullPointerException e) {
            return null;
        }
    }

    public void setOptionStrAddr(byte code, String opt) throws UnknownHostException {
        this.setOption(new DhcpOption(code, DHCPUtils.strAddrToByteArray(opt)));
    }

    public String getOptionStrAddr(byte code) {
        byte[] opt = this.getOptionBytes(code);
        try {
            return InetAddress.getByAddress(opt).getHostAddress();
        } catch (UnknownHostException | NullPointerException e) {
            return null;
        }
    }

    public void setOptionStrAddrs(byte code, List<String> addrs) throws UnknownHostException {
        if (!addrs.isEmpty()) {
            this.setOption(new DhcpOption(code, DHCPUtils.strListAddrsToByteArray(addrs)));
        }
    }

    public void setOptionString(byte code, String str) {
        this.setOption(new DhcpOption(code, str.getBytes()));
    }

    public byte[] serialize() {
        byte[] options = new byte[0];
        for (DhcpOption dhcpOption: this.options.values()) {
            options = ArrayUtils.addAll(options, dhcpOption.serialize());
        }
        byte[] end = new byte[] {(byte)255};
        options = ArrayUtils.addAll(options, end);
        return options;
    }

    private byte[] getOptionValArray(byte[] opt, int pos, int len) {
        byte[] val = new byte[len];
        for (int i = 0; i < len; i++) {
            val[i] = opt[pos + i];
        }
        return val;
    }

    public void deserialize(byte[] options) {
        int pos = 0;
        byte code;
        byte len;
        byte[] value;
        if (options != null) {
            while (pos < options.length) {
                code = options[pos++];
                if (code == OPT_END) {
                    break;
                }
                len = options[pos++];
                if ((len + pos) > options.length) {
                    // Throw exception???
                    break;
                }
                value = getOptionValArray(options, pos, len);
                setOption(code, value);
                pos += len;
            }
        }
    }

    @Override
    public String toString() {
        StringBuilder sb = new StringBuilder();
        sb.append("{");
        int count = 1;
        for (DhcpOption dhcpOption: this.options.values()) {
            //options = ArrayUtils.addAll(options, dOpt.serialize());
            sb.append("Option").append(count++).append(dhcpOption.toString());
        }
        sb.append("}");
        return sb.toString();
    }

    public boolean containsOption(byte code) {
        return options.containsKey(code);
    }

    public DhcpOption unsetOption(byte code) {
        return options.remove(code);
    }

}

