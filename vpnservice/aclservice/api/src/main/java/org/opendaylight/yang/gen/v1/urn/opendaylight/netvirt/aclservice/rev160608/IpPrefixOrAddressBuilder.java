package org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.aclservice.rev160608;

import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.inet.types.rev130715.IpAddress;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.inet.types.rev130715.IpAddressBuilder;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.inet.types.rev130715.IpPrefix;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.inet.types.rev130715.IpPrefixBuilder;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * The purpose of generated class in src/main/java for Union types is to create new instances of unions from a string representation.
 * In some cases it is very difficult to automate it since there can be unions such as (uint32 - uint16), or (string - uint32).
 *
 * The reason behind putting it under src/main/java is:
 * This class is generated in form of a stub and needs to be finished by the user. This class is generated only once to prevent
 * loss of user code.
 *
 */
public final class IpPrefixOrAddressBuilder {

    private static final Logger LOG = LoggerFactory.getLogger(IpPrefixOrAddressBuilder.class);

    public static IpPrefixOrAddress getDefaultInstance(String defaultValue) {
        try {
            IpPrefix ipPrefix = IpPrefixBuilder.getDefaultInstance(defaultValue);
            return new IpPrefixOrAddress(ipPrefix);
        } catch (IllegalArgumentException e) {
            LOG.debug("{} is not of IpPrefix type; checking whether it's a IpAddress type", defaultValue);
            IpAddress ipAddress = IpAddressBuilder.getDefaultInstance(defaultValue);
            return new IpPrefixOrAddress(ipAddress);
        }
    }

    private IpPrefixOrAddressBuilder() { }
}
