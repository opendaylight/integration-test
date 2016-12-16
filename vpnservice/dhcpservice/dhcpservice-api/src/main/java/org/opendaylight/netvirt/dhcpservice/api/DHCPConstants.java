/*
 * Copyright (c) 2015 Ericsson India Global Services Pvt Ltd. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */

package org.opendaylight.netvirt.dhcpservice.api;

public final class DHCPConstants {

    // DHCP BOOTP CODES
    public static final byte BOOTREQUEST    = 1;
    public static final byte BOOTREPLY      = 2;

    // DHCP HTYPE CODES
    public static final byte HTYPE_ETHER    = 1;

    // DHCP MESSAGE CODES
    public static final byte MSG_DISCOVER   =  1;
    public static final byte MSG_OFFER      =  2;
    public static final byte MSG_REQUEST    =  3;
    public static final byte MSG_DECLINE    =  4;
    public static final byte MSG_ACK        =  5;
    public static final byte MSG_NAK        =  6;
    public static final byte MSG_RELEASE    =  7;
    public static final byte MSG_INFORM     =  8;
    public static final byte MSG_FORCERENEW =  9;

    // DHCP OPTIONS CODE
    public static final byte OPT_PAD                          =   0;
    public static final byte OPT_SUBNET_MASK                  =   1;
    public static final byte OPT_TIME_OFFSET                  =   2;
    public static final byte OPT_ROUTERS                      =   3;
    public static final byte OPT_TIME_SERVERS                 =   4;
    public static final byte OPT_NAME_SERVERS                 =   5;
    public static final byte OPT_DOMAIN_NAME_SERVERS          =   6;
    public static final byte OPT_LOG_SERVERS                  =   7;
    public static final byte OPT_COOKIE_SERVERS               =   8;
    public static final byte OPT_LPR_SERVERS                  =   9;
    public static final byte OPT_IMPRESS_SERVERS              =  10;
    public static final byte OPT_RESOURCE_LOCATION_SERVERS    =  11;
    public static final byte OPT_HOST_NAME                    =  12;
    public static final byte OPT_BOOT_SIZE                    =  13;
    public static final byte OPT_MERIT_DUMP                   =  14;
    public static final byte OPT_DOMAIN_NAME                  =  15;
    public static final byte OPT_SWAP_SERVER                  =  16;
    public static final byte OPT_ROOT_PATH                    =  17;
    public static final byte OPT_EXTENSIONS_PATH              =  18;
    public static final byte OPT_IP_FORWARDING                =  19;
    public static final byte OPT_NON_LOCAL_SOURCE_ROUTING     =  20;
    public static final byte OPT_POLICY_FILTER                =  21;
    public static final byte OPT_MAX_DGRAM_REASSEMBLY         =  22;
    public static final byte OPT_DEFAULT_IP_TTL               =  23;
    public static final byte OPT_PATH_MTU_AGING_TIMEOUT       =  24;
    public static final byte OPT_PATH_MTU_PLATEAU_TABLE       =  25;
    public static final byte OPT_INTERFACE_MTU                =  26;
    public static final byte OPT_ALL_SUBNETS_LOCAL            =  27;
    public static final byte OPT_BROADCAST_ADDRESS            =  28;
    public static final byte OPT_PERFORM_MASK_DISCOVERY       =  29;
    public static final byte OPT_MASK_SUPPLIER                =  30;
    public static final byte OPT_ROUTER_DISCOVERY             =  31;
    public static final byte OPT_ROUTER_SOLICITATION_ADDRESS  =  32;
    public static final byte OPT_STATIC_ROUTES                =  33;
    public static final byte OPT_TRAILER_ENCAPSULATION        =  34;
    public static final byte OPT_ARP_CACHE_TIMEOUT            =  35;
    public static final byte OPT_IEEE802_3_ENCAPSULATION      =  36;
    public static final byte OPT_DEFAULT_TCP_TTL              =  37;
    public static final byte OPT_TCP_KEEPALIVE_INTERVAL       =  38;
    public static final byte OPT_TCP_KEEPALIVE_GARBAGE        =  39;
    public static final byte OPT_NIS_SERVERS                  =  41;
    public static final byte OPT_NTP_SERVERS                  =  42;
    public static final byte OPT_VENDOR_ENCAPSULATED_OPTIONS  =  43;
    public static final byte OPT_NETBIOS_NAME_SERVERS         =  44;
    public static final byte OPT_NETBIOS_DD_SERVER            =  45;
    public static final byte OPT_NETBIOS_NODE_TYPE            =  46;
    public static final byte OPT_NETBIOS_SCOPE                =  47;
    public static final byte OPT_FONT_SERVERS                 =  48;
    public static final byte OPT_X_DISPLAY_MANAGER            =  49;
    public static final byte OPT_REQUESTED_ADDRESS            =  50;
    public static final byte OPT_LEASE_TIME                   =  51;
    public static final byte OPT_OPTION_OVERLOAD              =  52;
    public static final byte OPT_MESSAGE_TYPE                 =  53;
    public static final byte OPT_SERVER_IDENTIFIER            =  54;
    public static final byte OPT_PARAMETER_REQUEST_LIST       =  55;
    public static final byte OPT_MESSAGE                      =  56;
    public static final byte OPT_MAX_MESSAGE_SIZE             =  57;
    public static final byte OPT_RENEWAL_TIME                 =  58;
    public static final byte OPT_REBINDING_TIME               =  59;
    public static final byte OPT_VENDOR_CLASS_IDENTIFIER      =  60;
    public static final byte OPT_CLIENT_IDENTIFIER            =  61;
    public static final byte OPT_NWIP_DOMAIN_NAME             =  62;
    public static final byte OPT_NWIP_SUBOPTIONS              =  63;
    public static final byte OPT_NISPLUS_DOMAIN               =  64;
    public static final byte OPT_NISPLUS_SERVER               =  65;
    public static final byte OPT_TFTP_SERVER                  =  66;
    public static final byte OPT_BOOTFILE                     =  67;
    public static final byte OPT_MOBILE_IP_HOME_AGENT         =  68;
    public static final byte OPT_SMTP_SERVER                  =  69;
    public static final byte OPT_POP3_SERVER                  =  70;
    public static final byte OPT_NNTP_SERVER                  =  71;
    public static final byte OPT_WWW_SERVER                   =  72;
    public static final byte OPT_FINGER_SERVER                =  73;
    public static final byte OPT_IRC_SERVER                   =  74;
    public static final byte OPT_STREETTALK_SERVER            =  75;
    public static final byte OPT_STDA_SERVER                  =  76;
    public static final byte OPT_USER_CLASS                   =  77;
    public static final byte OPT_FQDN                         =  81;
    public static final byte OPT_AGENT_OPTIONS                =  82;
    public static final byte OPT_NDS_SERVERS                  =  85;
    public static final byte OPT_NDS_TREE_NAME                =  86;
    public static final byte OPT_NDS_CONTEXT                  =  87;
    public static final byte OPT_CLIENT_LAST_TRANSACTION_TIME =  91;
    public static final byte OPT_ASSOCIATED_IP                =  92;
    public static final byte OPT_USER_AUTHENTICATION_PROTOCOL =  98;
    public static final byte OPT_AUTO_CONFIGURE               = 116;
    public static final byte OPT_NAME_SERVICE_SEARCH          = 117;
    public static final byte OPT_SUBNET_SELECTION             = 118;
    public static final byte OPT_DOMAIN_SEARCH                = 119;
    public static final byte OPT_CLASSLESS_ROUTE              = 121;
    public static final byte OPT_END                          =  -1;

    public static final int MAGIC_COOKIE = 0x63825363;

    public static final int DHCP_MIN_SIZE        = 300;
    public static final int DHCP_MAX_SIZE        = 576;

    public static final int DHCP_NOOPT_HDR_SIZE        = 240;
}
