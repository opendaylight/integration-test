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

    public static void main(String[] args) {

        Jbench options = new Jbench();
        JCommander cmd = new JCommander(options);
        cmd.setProgramName("Jbench");
        try {
            cmd.parse(args);
            if (options.help) {
                LOG.info("help message");
                cmd.usage();
                return;
            }

            ControllerInfo[] controller = options.processControllerInfo();
            LOG.info("Jbench: Java-based controller benchmarking tool");
            LOG.info("\trunning in mode '{}'", options.operationMode.toLowerCase());
            LOG.info("\tconnecting to controller at:");
            for (int controllerCount = 0; controllerCount < options.numControllers; controllerCount++) {
                LOG.info("\t{} : {}", controller[controllerCount].getHost(),
                     controller[controllerCount].getPort());
            }
            LOG.info("\tfaking 1000 switches {} tests each, {} ms per test",
                    options.loops, options.msPerTest);
            LOG.info("\twith {} unique source MACs per switch", options.macCountPerSwitch);
            LOG.info("\tstarting test with {} ms delay after features_reply", options.delay);
            LOG.info("\tignoring first {} warmup and last {} cooldown loops",
                    options.warmup, options.cooldown);
            if (options.debug == 0) {
                LOG.info("\tdebugging info is off");
            } else {
                LOG.info("\tdebugging info is on");
            }
        } catch (ParameterException ex) {
            LOG.error(ex.getMessage());
            cmd.usage();
        }

    }

    public ControllerInfo[] processControllerInfo() {
        final int DEFAULTPORT = 6633;
        ControllerInfo[] controller = new ControllerInfo[numControllers];
        int numDefaultController = 0;

        if ((numControllers - controllerIp.size()) > 0) {
            numDefaultController = numControllers - controllerIp.size();
        }
        for (int controllerCount = 0; controllerCount < numControllers; controllerCount++) {
            controller[controllerCount] = new ControllerInfo();
        }

        for (int controllerCount = 0; controllerCount < (numControllers - controllerIp.size()); controllerCount++) {
            controller[controllerCount].setHost("localhost");
            controller[controllerCount].setPort(DEFAULTPORT);
        }

        for (int controllerCount = numDefaultController; controllerCount < numControllers; controllerCount++) {
            String[] controllerTuples = controllerIp.get(controllerCount - numDefaultController).split(":");
            if (controllerTuples[0] != null) {
                controller[controllerCount].setHost(controllerTuples[0]);
            } else {
                controller[controllerCount].setHost("localhost");
            }
            if (controllerTuples.length > 1 && controllerTuples[1] != null) {
                controller[controllerCount].setPort(Integer.parseInt(controllerTuples[1]));
            } else {
                controller[controllerCount].setPort(DEFAULTPORT);
            }
        }
        return controller;
    }
}

class ControllerInfo {
    private String host;
    private Integer port;

    public void setHost(String hostName) {
        host = hostName;
    }

    public void setPort(Integer portNum) {
        port = portNum;
    }

    public String getHost() {
        return host;
    }

    public Integer getPort() {
        return port;
    }

}
