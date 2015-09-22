/*
 * Copyright (c) 2015 Intel Corp. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */

package org.opendaylight.jbench;

import com.beust.jcommander.JCommander;
import com.beust.jcommander.Parameter;
import com.beust.jcommander.ParameterException;
import java.util.ArrayList;
import java.util.List;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * <p>This is the driver class for Jbench tool. The methods in this class provide CLI using Jcommander library,
 * instantiate objects of SdnController class and instantiate FakeSwitchGroup threads.</p>
 * @author Raksha Madhava Bangera
 *
 */
public class Jbench {

    private static final Logger LOG = LoggerFactory.getLogger(Jbench.class);

    @Parameter(names = { "-c", "--controller" }, variableArity = true, description = "controller ip and port number")
    private List<String> controllerIp = new ArrayList<>();

    @Parameter(names = { "-d", "--debug" }, description = "enable debugging")
    private int debug = 0;

    @Parameter(names = { "-h", "--help" }, help = true, description = "print this message")
    private boolean help;

    @Parameter(names = { "-l", "--loops" }, description = "loops per test")
    private int loops = 16;

    @Parameter(names = { "-m", "--ms-per-test" }, description = "test length in ms")
    private int msPerTest = 1000;

    @Parameter(names = { "-n", "--number" }, description = "number of controllers")
    private int numControllers = 1;

    @Parameter(names = { "-s", "--switches" }, description = "number of switches")
    private int numSwitches = 16;

    @Parameter(names = { "-w", "--warmup" }, description = "loops to be disregarded on test start (warmup)")
    private int warmup = 1;

    @Parameter(names = { "-C", "--cooldown" }, description = "loops to be disregarded at test end (cooldown)")
    private int cooldown = 0;

    @Parameter(names = { "-D",
            "--delay" }, description = "delay starting testing after features_reply is received (in ms)")
    private int delay = 0;

    @Parameter(names = { "-M", "--mac-addresses" }, description = "unique source mac addresses per switch")
    private int macCountPerSwitch = 100000;

    @Parameter(names = { "-O",
            "--operation-mode" }, required = true, validateWith = OperationMode.class, description = "latency or "
                    + "throughput mode")
    private String operationMode;

    /**
     * <p>This is the entry point of Jbench tool. It parses the command-line options passed by the user and stores it
     * as respective name value pairs.</p>
     * @param args command line options to Jbench program passed by the user
     */
    public static void main(String[] args) {

        Jbench jbench = new Jbench();
        JCommander jcommander = new JCommander(jbench);
        jcommander.setProgramName("Jbench");
        try {
            jcommander.parse(args);
            if (jbench.help) {
                LOG.info("help message");
                jcommander.usage();
                return;
            } else if ( jbench.controllerIp.size() != jbench.numControllers ) {
                LOG.info("Number of Controller Ip:port tuples supplied and number of controllers didn't match");
                jcommander.usage();
                return;
            }

            SdnController[] controllerArray = jbench.returnControllerArray();
            LOG.info("Jbench: Java-based controller benchmarking tool");
            LOG.info("\trunning in mode '{}'", jbench.operationMode.toLowerCase());
            LOG.info("\tconnecting to controller at:");
            for (int controllerCount = 0; controllerCount < jbench.numControllers; controllerCount++) {
                LOG.info("\t{} : {}", controllerArray[controllerCount].getHost(),
                     controllerArray[controllerCount].getPort());
            }
            LOG.info("\tfaking {} switches {} tests each, {} ms per test",
                    jbench.numSwitches, jbench.loops, jbench.msPerTest);
            LOG.info("\twith {} unique source MACs per switch", jbench.macCountPerSwitch);
            LOG.info("\tstarting test with {} ms delay after features_reply", jbench.delay);
            LOG.info("\tignoring first {} warmup and last {} cooldown loops",
                    jbench.warmup, jbench.cooldown);
            if (jbench.debug == 0) {
                LOG.info("\tdebugging info is off");
            } else {
                LOG.info("\tdebugging info is on");
            }
        } catch (ParameterException ex) {
            LOG.error(ex.getMessage());
            jcommander.usage();
        }

    }

    private SdnController[] returnControllerArray() {

        SdnController[] controllerArray = new SdnController[numControllers];

        for (int controllerCount = 0; controllerCount < numControllers; controllerCount++) {
            controllerArray[controllerCount] = new SdnController();
            controllerArray[controllerCount].extractIpAndPort(controllerIp.get(controllerCount));
        }
        return controllerArray;
    }
}