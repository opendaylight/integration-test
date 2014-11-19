## Wrapped CBench (WCBench)

CBench, wrapped in stuff that makes it useful.

- [Wrapped CBench (WCBench)](#user-content-wrapped-cbench-wcbench)
    - [Overview](#user-content-overview)
    - [Usage](#user-content-usage)
        - [Usage Overview](#user-content-usage-overview)
        - [Usage Details: wcbench.sh](#user-content-usage-details-wcbenchsh)
        - [Usage Details: loop_wcbench.sh](#user-content-usage-details-loop_wcbenchsh)
        - [Usage Details: stats.py](#user-content-usage-details-statspy)
    - [WCBench Results](#user-content-wcbench-results)
    - [Detailed Walkthrough: Vagrant](#user-content-detailed-walkthrough-vagrant)
    - [Detailed Walkthrough: Manual](#user-content-detailed-walkthrough-manual)
    - [Contributing](#user-content-contributing)
    - [Contact](#user-content-contact)

### Overview

CBench is a somewhat classic SDN controller benchmark tool. It blasts a controller with OpenFlow packet-in messages and counts the rate of flow mod messages returned. WCBench consumes CBench as a library, then builds a robust test automation, stats collection and stats analysis/graphing system around it.

WCBench currently only supports the Helium release of the OpenDaylight SDN controller, but it would be fairly easy to add support for other controllers. Community contributions are encouraged!

### Usage

#### Usage Overview

The help outputs produced by `./wcbench.sh -h`, `./loop_wcbench.sh -h` and `stats.py -h` are quite useful:

```
Usage ./wcbench.sh [options]

Setup and/or run CBench and/or OpenDaylight.

OPTIONS:
    -h Show this message
    -v Output verbose debug info
    -c Install CBench
    -t <time> Run CBench for given number of minutes
    -r Run CBench against OpenDaylight
    -i Install OpenDaylight Helium 0.2.1
    -p <processors> Pin ODL to given number of processors
    -o Start and configure OpenDaylight Helium 0.2.1
    -k Kill OpenDaylight
    -d Delete local ODL and CBench code
```

```
Usage ./loop_wcbench.sh [options]

Run WCBench against OpenDaylight in a loop.

OPTIONS:
    -h Show this help message
    -v Output verbose debug info
    -l Loop WCBench runs without restarting ODL
    -r Loop WCBench runs, restart ODL between runs
    -t <time> Run WCBench for a given number of minutes
    -p <processors> Pin ODL to given number of processors
```

```
usage: stats.py [-h] [-S]
                [-s {five_load,ram,steal_time,one_load,iowait,fifteen_load,runtime,flows} [{five_load,ram,steal_time,one_load,iowait,fifteen_load,runtime,flows} ...]]
                [-G]
                [-g {five_load,ram,steal_time,one_load,iowait,fifteen_load,runtime,flows} [{five_load,ram,steal_time,one_load,iowait,fifteen_load,runtime,flows} ...]]

Compute stats about CBench data

optional arguments:
  -h, --help            show this help message and exit
  -S, --all-stats       compute all stats
  -s {five_load,ram,steal_time,one_load,iowait,fifteen_load,runtime,flows} [{five_load,ram,steal_time,one_load,iowait,fifteen_load,runtime,flows} ...], --stats {five_load,ram,steal_time,one_load,iowait,fifteen_load,runtime,flows} [{five_load,ram,steal_time,one_load,iowait,fifteen_load,runtime,flows} ...]
                        compute stats on specified data
  -G, --all-graphs      graph all data
  -g {five_load,ram,steal_time,one_load,iowait,fifteen_load,runtime,flows} [{five_load,ram,steal_time,one_load,iowait,fifteen_load,runtime,flows} ...], --graphs {five_load,ram,steal_time,one_load,iowait,fifteen_load,runtime,flows} [{five_load,ram,steal_time,one_load,iowait,fifteen_load,runtime,flows} ...]
                        graph specified data
```

#### Usage Details: wcbench.sh

Most of the work in WCBench happens in `wcbench.sh`. It's the bit that directly wraps CBench, automates CBench/ODL installation, collects system stats, starts/stops ODL, and runs CBench against ODL.

In more detail, the `wcbench.sh` script supports:

* Trivially cloning, building and installing CBench via the [oflops repo](https://github.com/andi-bigswitch/oflops).
* Changing a set of CBench params (MS_PER_TEST, TEST_PER_SWITCH and CBENCH_WARMUP) to easily set the overall length of a CBench run in minutes. Long CBench runs typically produce results with a lower standard deviation.
* Running CBench against an instance of OpenDaylight. The CBench and ODL processes can be on the same machine or different machines. Change the `CONTROLLER_IP` and `CONTROLLER_PORT` variables in `wcbench.sh` to point CBench at the correct ODL process. To run against a local ODL process that's on the default port, set `CONTROLLER_IP="localhost"` and `CONTROLLER_PORT=6633`. To run CBench against a remote ODL process, set `CONTROLLER_IP` to the IP address of the machine running ODL and `CONTROLLER_PORT` to the port ODL is listening on. Obviously the two machines have to have network connectivity with each other. Additionally, since WCBench connects to the remote machine to pull system stats, the remote machine needs to have sshd running and properly configured. The local machine should have its `~/.ssh/config` file and public keys setup such that `ssh $SSH_HOSTNAME` works without a password or RSA unknown-key prompt. To do this, setup something like the following in `~/.ssh/config`:

```
Host cbench
    Hostname 209.132.178.170
    User fedora
    IdentityFile /home/daniel/.ssh/id_rsa_nopass
    StrictHostKeyChecking no
```

As you likely know, `ssh-copy-id` can help you setup your system to connect with the remote box via public key crypto. If you don't have keys setup for public key crypto, google for guides (very out of scope). Finally, note that the `SSH_HOSTNAME` var in `wcbench.sh` must be set to the exact same value given on the `Host` line above.
* Trivially installing/configuring ODL from the last successful build (via an Integration team Jenkins job).
* Pinning the OpenDaylight process to a given number of CPU cores. This is useful for ensuring that ODL is properly pegged, working as hard as it can with given resource limits. It can also expose bad ODL behavior that comes about when the process is pegged.
* Running OpenDaylight and issuing all of the required configurations.
* Stopping the OpenDaylight process. This is done cleanly via the `run.sh` script, not `kill` or `pkill`.
* Cleaning up everything changed by the `wcbench.sh` script, including deleting ODL and CBench sources and binaries.


#### Usage Details: loop_wcbench.sh

The `loop_wcbench.sh` script is a fairly simple wrapper around `wcbench.sh` ("I hear you like wrappers, so I wrapped your wrapper in a wrapper"). Its reason for existing is to enable long series of repeated WCBench runs. As described in the [WCBench Results](https://github.com/dfarrell07/cbench_regression#wcbench-results) section, these results will be stored in a CSV file and can be analyzed with `stats.py`, as described in the [Usage Details: stats.py](https://github.com/dfarrell07/cbench_regression#usage-details-statspy) section. Doing many WCBench runs allows trends over time to be observed (like decreasing perf or increasing RAM). More results can also yield more representative stats.

In more detail, the `loop_wcbench.sh` script supports:

* Repeatedly running WCBench against ODL without restarting ODL between runs. This test revealed the perf degradation over time described in [bug 1395](https://bugs.opendaylight.org/show_bug.cgi?id=1395).
* Repeatedly running WCBench against ODL, restarting ODL between runs. This acted as a control when finding [bug 1395](https://bugs.opendaylight.org/show_bug.cgi?id=1395), as restarting ODL between runs mitigated perf decreases. 
* Pass run length info to WCBench, causing WCBench runs to last for the given number of minutes. Note that longer runs seem to result in lower standard deviation flows/sec results.
* Pin ODL to a given number of processors. This is basically a thin hand-off to `wcbench.sh`. As mentioned above, pinning ODL allows it to be tested while the process is properly pegged.

#### Usage Details: stats.py

The `stats.py` script parses the output of `wcbench.sh`, which is stored in the file pointed at by the `RESULTS_FILE` variable in `wcbench.sh`. See the [WCBench Results](https://github.com/dfarrell07/cbench_regression#wcbench-results) section for more info on the results file. Both pure stats and graphs of results are supported by `stats.py`.

Any set of names for data points can be given to the `-s` flag to calculate their stats and to the `-g` flag to graph them against run numbers. All stats can be computed with `./stats.py -S`, just as all graphs can be generated with `-G`.

Examples are useful:

```
# CBench flows/sec stats
./stats.py -s flows
{'flows': {'max': 15036,
           'mean': 8958.426,
           'min': 4981,
           'relstddev': 32.032,
           'stddev': 2869.584},
 'sample_size': 115}
```

```
# All stats
./stats.py -S
{'fifteen_load': {'max': 0,
                  'mean': 0.62,
                  'min': 0,
                  'relstddev': 0.0,
                  'stddev': 0.0},
 'five_load': {'max': 0,
               'mean': 0.96,
               'min': 0,
               'relstddev': 0.0,
               'stddev': 0.0},
 'flows': {'max': 22384,
           'mean': 22384.52,
           'min': 22384,
           'relstddev': 0.0,
           'stddev': 0.0},
 'iowait': {'max': 0, 'mean': 0.0, 'min': 0, 'relstddev': 0.0, 'stddev': 0.0},
 'one_load': {'max': 0,
              'mean': 0.85,
              'min': 0,
              'relstddev': 0.0,
              'stddev': 0.0},
 'runtime': {'max': 120,
             'mean': 120.0,
             'min': 120,
             'relstddev': 0.0,
             'stddev': 0.0},
 'sample_size': 1,
 'steal_time': {'max': 0,
                'mean': 0.0,
                'min': 0,
                'relstddev': 0.0,
                'stddev': 0.0},
 'used_ram': {'max': 3657,
              'mean': 3657.0,
              'min': 3657,
              'relstddev': 0.0,
              'stddev': 0.0}}
```

```
# Create graphs of flows/sec and used RAM stats
./stats.py -g flows ram
```

Graph results:

![Graphs of flows/sec and used RAM against run number](https://cloud.githubusercontent.com/assets/880273/3562723/5b854538-0a02-11e4-8fb1-dd1544d20ae6.png)


### WCBench Results

Results from `wcbench.sh` are stored in the file pointed at by the `RESULTS_FILE` variable in `wcbench.sh`. That variable defaults to `RESULTS_FILE=$BASE_DIR/"results.csv"`, which in turn resolves to `~/results.csv` by default. As you can guess from the file name, results are stored in CSV format. Note that this format was chosen because it's what's consumed by the Jenkins Plot Plugin, which ODL uses to [automatically run a subset of the functionality provided by WCBench against ODL builds](https://jenkins.opendaylight.org/integration/job/integration-master-performance-plugin/plot/).

Note that manually modifying the results file (adding/deleting lines) will cause incorrect run number values.

The data collected by WCBench and stored in the results file for each run includes:
* A run number for each run, starting at 0 and counting up
* The flows/sec average from the CBench run
* Unix time in seconds at the beginning of the run
* Unix time in seconds at the end of the run
* The IP address of the controller
* Human-readable time that the run finished
* The number of switches simulated by CBench
* The number of MAC addresses used by CBench
* The `TESTS_PER_SWITCH` value passed to CBench
* The duration of each test in milliseconds
* The steal time on the system running ODL at the start of the test
* The steal time on the system running ODL at the end of the test
* The total RAM on the system running ODL
* The used RAM on the system running ODL at the end of a test run
* The free RAM on the system running ODL at the end of a test run
* The number of CPUs on the system running ODL
* The one minute load of the system running ODL
* The five minute load of the system running ODL
* The fifteen minute load of the system running ODL
* The name of the controller under test
* The iowait value at the start of the test on the system running ODL
* The iowait value at the end of the test on the system running ODL

### Detailed Walkthrough: Vagrant

A Vagrantfile is provided for WCBench, which allows you to get an OpenDaylight+WCBench environment up-and-running trivially easily. Vagrant also allows folks on otherwise unsupported operating systems (Ubuntu, Debian, Windows) to use WCBench.

If you don't have Vagrant installed already, head over to [their docs](https://docs.vagrantup.com/v2/installation/) and get that knocked out.

If you haven't already, you'll need to clone the WCBench repo:

```
[~]$ git clone https://github.com/dfarrell07/wcbench.git
```

You can now trivially stand up a VM with OpenDaylight+CBench+WCBench properly configured:

```
[~/wcbench]$ vagrant up
```

If this is your first time using the `chef/fedora-20` Vagrant box, that'll have to download. Future `vagrant up`s will use a locally cached version. Once the box is provisioned, you can connect to it like this:

```
[~/wcbench]$ vagrant ssh
Last login: Mon Nov 17 14:29:33 2014 from 10.0.2.2
[vagrant@localhost ~]$
```

WCBench, OpenDaylight and CBench are already installed and configured. You can start OpenDaylight like this:

```
[vagrant@localhost ~]$ cd wcbench/
[vagrant@localhost wcbench]$ ./wcbench.sh -o
Starting OpenDaylight
Will repeatedly attempt connecting to Karaf shell until it's ready
Issued `dropAllPacketsRpc on` command via Karaf shell to localhost:8101
Issued `log:set ERROR` command via Karaf shell to localhost:8101
```

Run CBench against OpenDaylight like this:

```
[vagrant@localhost wcbench]$ ./wcbench.sh -r
Collecting pre-test stats
Running CBench against ODL on localhost:6633
Collecting post-test stats
Collecting time-irrelevant stats
Average responses/second: 29486.95
```

Since the WCBench Vagrant box is headless, you'll want to move the `results.txt` to a system with a GUI for graphing.

Vagrant hard-links `/home/vagrant/wcbench/` to the directory on your local system that contains WCBench's Vagrantfile. Dropping `results.txt` in `/home/vagrant/wcbench/` will therefore move it to your local system for analysis. You can also modify the `RESULTS_FILE` variable in `wcbench.sh` to point at `/home/vagrant/wcbench/`, if you'd like to put it there by default.

```
# Move results.txt to hard-linked dir
[vagrant@localhost wcbench]$ mv ../results.csv .
```

```
# Configure wcbench to create results.txt in hard-linked dir
RESULTS_FILE=$BASE_DIR/wcbench/"results.csv"
```

You can now generate graphs and stats, as described in the [Usage Details: stats.py](#user-content-usage-details-statspy) section.

To run long batches of tests, use `loop_wcbench.sh`, as described in [Usage Details: loop_wcbench.sh](#user-content-usage-details-loop_wcbenchsh).

Once you're done, you can kill OpenDaylight like this:

```
[vagrant@localhost wcbench]$ ./wcbench.sh -k
Stopping OpenDaylight
```

Unless you want a fresh WCBench Vagrant box, you can save yourself some time at your next `vagrant up` by suspending (instead of destroying) the box:

```
# On my local system
[~/wcbench]$ vagrant suspend
==> default: Saving VM state and suspending execution...
```

### Detailed Walkthrough: Manual

This walkthrough describes how to setup a system for WCBench testing, starting with a totally fresh [Fedora 20 Cloud](http://fedoraproject.org/get-fedora#clouds) install. I'm going to leave out the VM creation details for the sake of space. As long as you can SSH into the machine and it has access to the Internet, all of the following should work as-is. Note that this process has also been tested on CentOS 6.5 (so obviously should work on RHEL).

I suggest starting by adding the WCBench VM to your `~/.ssh/config` file, to allow quick access without having to remember details.

```
[~]$ vim .ssh/config
```

Add something like the following:

```
Host wcbench
    Hostname 10.3.9.110
    User fedora
    IdentityFile /home/daniel/.ssh/id_rsa_nopass
    StrictHostKeyChecking no
```

You can now SSH into your fresh VM:

```
[~]$ ssh wcbench
Warning: Permanently added '10.3.9.110' (RSA) to the list of known hosts.
[fedora@dfarrell-wcbench ~]$
```

You'll need a utility like screen or tmux, so you can start long-running tests, log out of the system and leave them running. My Linux configurations are very scripted, so here's how I install tmux and its configuration file. You're welcome to copy this.

From my local system:

```
[~]$ rsync ~/.dotfiles/linux_setup.sh wcbench:/home/fedora
```

That `linux_setup.sh` script can be found [here](https://github.com/dfarrell07/dotfiles/blob/master/linux_setup.sh).

Back on the remote VM:

```
[fedora@dfarrell-wcbench ~]$ sudo yum update -y; ./linux_setup.sh -t
```

Go get some coffee, this will take a while.

Once your VM is updated and tmux is installed, drop into a tmux session.

```
[fedora@dfarrell-wcbench ~]$ tmux new
```

For the sake of simplicity, I'm going to do an HTTPS clone of the WCBench repo. You may want to setup your SSH info on the VM and clone via SSH if you're going to be contributing (which is encouraged!).

NB: Git was installed for me during the `./linux_setup.sh -t` step, as that cloned my [.dotfiles repo](https://github.com/dfarrell07/dotfiles/). If you don't have git, install it with `sudo yum install git -y`.

```
[fedora@dfarrell-wcbench ~]$ git clone https://github.com/dfarrell07/wcbench.git
[fedora@dfarrell-wcbench ~]$ ls -rc
linux_setup.sh  wcbench
[fedora@dfarrell-wcbench ~]$ cd wcbench/
```

Huzzah! You now have WCBench "installed" on your VM. Now, to install CBench and OpenDaylight.

```
[fedora@dfarrell-wcbench wcbench]$ ./wcbench.sh -ci
CBench is not installed
Installing CBench dependencies
Cloning CBench repo into /home/fedora/oflops
Cloning openflow source code into /home/fedora/openflow
Building oflops/configure file
Building CBench
CBench is installed
Successfully installed CBench
Installing OpenDaylight dependencies
Downloading OpenDaylight Helium 0.2.1
Unzipping OpenDaylight Helium 0.2.1
odl-openflowplugin-flow-services added to features installed at boot
odl-openflowplugin-drop-test added to features installed at boot
```

Huzzah! You now have CBench and OpenDaylight installed/configured.

You're ready to get started using WCBench. You can start ODL like this:

```
[fedora@dfarrell-wcbench wcbench]$ ./wcbench.sh -o
Starting OpenDaylight
Will repeatedly attempt connecting to Karaf shell until it's ready
Issued `dropAllPacketsRpc on` command via Karaf shell to localhost:8101
Issued `log:set ERROR` command via Karaf shell to localhost:8101
```

Here's an example of running a two minute CBench test against OpenDaylight:

```
[fedora@dfarrell-wcbench wcbench]$ ./wcbench.sh -t 2 -r
Set MS_PER_TEST to 120000, TESTS_PER_SWITCH to 1, CBENCH_WARMUP to 0
Collecting pre-test stats
Running CBench against ODL on localhost:6633
Collecting post-test stats
Collecting time-irrelevant stats
Average responses/second: 22384.52
/home/fedora/results.csv not found or empty, building fresh one
```

I suggest copying your results.csv file back to your local system for analysis, especially if you want to generate graphs. From my local system:

```
[~/wcbench]$ rsync wcbench:/home/fedora/results.csv .
```

You can now generate graphs and stats, as described in the [Usage Details: stats.py](#user-content-usage-details-statspy) section.

If you'd like to collect some serious long-term data, use the `loop_wcbench.sh` script (of course, back on the VM).

```
[fedora@dfarrell-wcbench wcbench]$ ./loop_wcbench.sh -t 2 -r
# I'm not going to let this run, you get the idea
```

You can then disconnect from your tmux session with `ctrl + a + d`, or `ctrl + b + d` if you're using the standard `~/.tmux.conf`. Let this loop run for a few days, then run lots of `stats.py` commands against it to see all kinds of cool stuff.

Once you're done, you can stop ODL and clean up the CBench and ODL source/binaries.

```
[fedora@dfarrell-wcbench wcbench]$ ./wcbench.sh -k
Stopping OpenDaylight
[fedora@dfarrell-wcbench wcbench]$ ./wcbench.sh -d
Removing /home/fedora/distribution-karaf-0.2.1-Helium-SR1
Removing /home/fedora/distribution-karaf-0.2.1-Helium-SR1.zip
Removing /home/fedora/openflow
Removing /home/fedora/oflops
Removing /usr/local/bin/cbench
```

### Contributing

Contributions are encuraged! Contributions are encuraged! Contributions are encuraged! <- I can't say this enough.

The best way to contribute code is to jump on an existing [GitHub Issue](https://github.com/dfarrell07/wcbench/issues) or raise your own, then fork the code, make your changes and submit a pull request to merge your changes back into the main codebase.

Bugs or feature requests should be raised as [Issues](https://github.com/dfarrell07/wcbench/issues).

Note that the code is Open Source under a BSD 2-clause license.

### Contact

For feature requests, bug reports and questions please raise an [Issue](https://github.com/dfarrell07/wcbench/issues). Daniel Farrell is the primary developer of this tool. He can be contacted directly at dfarrell@redhat.com or on IRC (dfarrell07 on Freenode). **Prefer public, documented communication like Issues over direct 1-1 communication. This is an Open Source project. Keep the community in the loop.**
