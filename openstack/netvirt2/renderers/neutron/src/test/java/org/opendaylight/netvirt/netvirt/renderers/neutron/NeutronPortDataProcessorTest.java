package org.opendaylight.netvirt.netvirt.renderers.neutron;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertNotNull;
import static org.junit.Assert.assertNull;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

import com.google.common.base.Optional;
import java.util.ArrayList;
import java.util.List;
import org.junit.Test;
import org.opendaylight.controller.md.sal.binding.api.DataBroker;
import org.opendaylight.controller.md.sal.binding.test.AbstractDataBrokerTest;
import org.opendaylight.controller.md.sal.common.api.data.LogicalDatastoreType;
import org.opendaylight.controller.sal.binding.api.BindingAwareBroker.ProviderContext;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.inet.types.rev130715.IpAddress;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.yang.types.rev130715.MacAddress;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.yang.types.rev130715.Uuid;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.ports.rev150712.port.attributes.FixedIps;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.ports.rev150712.port.attributes.FixedIpsBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.ports.rev150712.ports.attributes.Ports;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.ports.rev150712.ports.attributes.ports.Port;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.ports.rev150712.ports.attributes.ports.PortBuilder;
import org.opendaylight.yangtools.yang.binding.InstanceIdentifier;

/**
 * Unit test for {@link NeutronPortDataProcessor}
 */
public class NeutronPortDataProcessorTest extends AbstractDataBrokerTest {
    private static final Uuid portId = new Uuid("aaaaaaaa-bbbb-cccc-dddd-123456789012");
    private static final Uuid portId2 = new Uuid("11111111-2222-3333-4444-555555555555");
    private static final Uuid portId3 = new Uuid("33333333-3333-3333-3333-333333333333");
    ProviderContext session;
    NeutronPortDataProcessor neutronPortDataProcessor;
    boolean initialized = false;

    private org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.ports.rev151227.ports.Port readFromMdSal(Uuid uuid) throws Exception {
        InstanceIdentifier<org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.ports.rev151227.ports.Port> portIid =
                MdsalHelper.createPortInstanceIdentifier(uuid);

        Optional<org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.ports.rev151227.ports.Port> data =
            getDataBroker()
            .newReadOnlyTransaction()
            .read(LogicalDatastoreType.CONFIGURATION, portIid)
            .get();
        return data.orNull();
    }

    private Port createNeutronPort(Uuid uuid, String name, boolean adminStateUp ) throws Exception {
        String addr = "100.100.100.100";
        List<FixedIps> ips = new ArrayList<>();
        FixedIpsBuilder fixedIpsBuilder = new FixedIpsBuilder()
                .setIpAddress(new IpAddress(addr.toCharArray()))
                .setSubnetId(new Uuid("12345678-1234-1234-1234-222222222222"));
        ips.add(fixedIpsBuilder.build());


        return (new PortBuilder()
                .setStatus("Up")
                .setAdminStateUp(adminStateUp)
                .setName(name)
                .setDeviceOwner("compute:nova")
                .setDeviceId("12345678-1234-1234-1234-123456789012")
                .setUuid(uuid)
                .setMacAddress(new MacAddress("00:00:01:02:03:04"))
                .setFixedIps(ips)
                .build());
    }

    private void initialize() {
        if (!initialized) {
            session = mock(ProviderContext.class);
            when(session.getSALService(DataBroker.class)).thenReturn(getDataBroker());
            neutronPortDataProcessor = new NeutronPortDataProcessor(getDataBroker());
            initialized = true;
        }
    }

    @Test
    public void testRemove() throws Exception {
        //Do some setup and initialization
        initialize();

        //Create Neutron port
        Port neutronPort = createNeutronPort(portId2, "testRemovePort", true);
        InstanceIdentifier<Port> instanceIdentifier = InstanceIdentifier.create(Ports.class).child(Port.class);

        //Add the Neutron port.This should result in a Netvirt port being created, and added to mdsal.
        neutronPortDataProcessor.add(instanceIdentifier, neutronPort);

        //Verify the Netvirt port was added to mdsal
        assertNotNull(readFromMdSal(neutronPort.getUuid()));

        //Delete the Netvirt port that was just put into mdsal, and verify that it was removed from mdsal.
        neutronPortDataProcessor.remove(instanceIdentifier, neutronPort);
        assertNull(readFromMdSal(neutronPort.getUuid()));
    }

    @Test
    public void testUpdate() throws Exception {
        //Do some setup and initialization
        initialize();

        //Create Neutron port
        Port neutronPort = createNeutronPort(portId3, "testUpdatePort", true);
        InstanceIdentifier<Port> instanceIdentifier = InstanceIdentifier.create(Ports.class).child(Port.class);

        //Add the Neutron port. This should result in a Netvirt port being created, and added to mdsal.
        neutronPortDataProcessor.add(instanceIdentifier, neutronPort);

        //Verify the Netvirt port was added to mdsal
        assertNotNull(readFromMdSal(neutronPort.getUuid()));

        //Create a second Neutron port, with different values for "name" and "AdminStateUp"
        Port neutronPort1 = createNeutronPort(portId3, "portUpdatedTest", false);

        //Update the Neutron port. This should result in the netvirt port in mdsal being updated, with a new name and
        //admin state
        neutronPortDataProcessor.update(instanceIdentifier, neutronPort, neutronPort1);

        //Verify that the netvirt port was updated in mdsal
        org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.ports.rev151227.ports.Port netvirtPort = readFromMdSal(neutronPort1.getUuid());
        assertNotNull(netvirtPort);
        assertEquals("Error, name not updated", netvirtPort.getName(), neutronPort1.getName());
        assertEquals("Error, admin state not updated", netvirtPort.isAdminStateUp(), neutronPort1.isAdminStateUp());
    }

    @Test
    public void testAdd() throws Exception {
        //Do some setup and initialization
        initialize();

        //Create Neutron port.
        Port neutronPort = createNeutronPort(portId, "testAddPort", true);
        InstanceIdentifier<Port> instanceIdentifier = InstanceIdentifier.create(Ports.class).child(Port.class);

        //Add the Neutron port.This should result in a Netvirt port being created, and added to mdsal.
        neutronPortDataProcessor.add(instanceIdentifier, neutronPort);

        //Verify that the Netvirt port was added to mdsal, and that the contents of the Netvirt port are correct.
        org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.ports.rev151227.ports.Port netvirtPort = readFromMdSal(neutronPort.getUuid());
        assertNotNull(netvirtPort);
        assertEquals("Error, status not correct", netvirtPort.getStatus(), neutronPort.getStatus());
        assertEquals("Error, name not correct", netvirtPort.getName(), neutronPort.getName());
        assertEquals("Error, admin state not correct", netvirtPort.isAdminStateUp(), neutronPort.isAdminStateUp());
        assertEquals("Error, dev id is not correct", netvirtPort.getDeviceUuid().getValue(), neutronPort.getDeviceId());
        assertEquals("Error, uuid is not correct", netvirtPort.getUuid().getValue(), neutronPort.getUuid().getValue());
    }

}
