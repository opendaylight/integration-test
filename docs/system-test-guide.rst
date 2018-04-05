System Test Guide
=================

Introduction
------------
This step by step guide aims to help projects with the task of creating a
System Test job that runs in Continuous Integration.

A System Test job will normally install a controller distribution in one or
more VMs and will run a functionality test using some test tool (e.g. mininet).
This job will run periodically, tipically once or twice a day.

All projects defining top-level features (essential functionality) and that have
decided to use the OpenDaylight CI for system test must create system test jobs.

System test jobs rely on Robot Framework, this is because Robot FW provides:

* Structure for test creation and execution (e.g. test suites, test cases that
  PASS/FAIL).
* Easy test debug (real time logs, etc...).
* Test reports in Jenkins.

For those projects creating system test, Integration group will provide:

* Robot Framework support and assistance.
* Review of system test code. The code will be pushed to integration/test git
  (csit/suites/$project/).
* JJB templates to install controller and execute a robot test to verify a
  project functionality (releng/builder git, jjb/integration/).

Create basic system test
------------------------
Download Integration/Test Repository::

  git clone ssh://${USERNAME}@git.opendaylight.org:29418/integration/test.git
  cd test

Follow the instructions in pulling-and-pushing-the-code_ to know more about
pulling and pushing code.

Create a folder for your project robot test::

  mkdir test/csit/suites/$project
  cd test/csit/suites/$project

Replace $project with your project name.

Move your robot suites (test folders) into the project folder:

If you do not have any robot test yet, copy integration basic folder suite into
your folder. You can later improve this suite or replace it by your own suites::

  cp -R test/csit/suites/integration/basic basic

This suite will verify Restconf is operational.

Create a test plan
^^^^^^^^^^^^^^^^^^
A test plan is a text file indicating which robot test suites (including
integration repo path) will be executed to test a project functionality::

  vim test/csit/testplans/$project-$functionality.txt

Replace $project with your project name and $functionality with the
functionality you want to test.

If you took the basic test from integration, the test plan file should look
like this::

  # Place the suites in run order:
  integration/test/csit/suites/$project/basic

Save the changes and exit editor.

Optional: Version specific test plan
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
Integration/Test is not part of the simultaneous release, so the same suites are
used for testing all supported ODL versions. There may be API changes between
different releases of ODL, which may require different logic in your Robot
tests. If the difference is small, it is recommended to act upon value of
ODL_STREAM variable (e.g. "beryllium", "boron", "carbon", etc).

If the difference is big, you may want to use different list of suites in
testplan. One way is to define separate jobs with different functionality names.
But the more convenient way is to define stream-specific testplan. For example::

  vim test/csit/testplans/$project-$functionality-boron.txt

would contain a list of suites for testing Boron, while
$project-$functionality.txt would still contain the default list (used for
streams without stream specific testplans).

Optional: Create a script or config plan
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
Sometimes the environment prepared by scripts in releng/builder is not suitable
as is, and there are changes to be done before controller is installed (script
plan) or before it is started (config plan). You may create as many bash scripts
as you need in test/csit/scripts/ and then list them in the scriplans or
configplans folder::

  vim test/csit/scriptplans/$project-$functionality.txt

Save and push Test changes
^^^^^^^^^^^^^^^^^^^^^^^^^^
Add the changes and push them in the integration/test repo::

  git add -A
  git commit -s
  git push

Create system test job
----------------------
Download RelEng Builder repository::

  git clone ssh://${USERNAME}@git.opendaylight.org:29418/releng/builder
  cd builder

Follow the instructions in pulling-and-pushing-the-code_ to know more about
pulling and pushing code.

Create a new file and modify the values according to your project::

  vim jjb/$project/$project-csit-$functionality.yaml

For a Managed project it should look like this::

  ---
  - project:
      name: openflowplugin-csit-flow-services
      jobs:
        - inttest-csit-1node

      # The project name
      project: 'openflowplugin'

      # The functionality under test
      functionality:
        - flow-services
        - gate-flow-services

      # Project branches
      stream:
        - fluorine:
            branch: 'master'
        - oxygen:
            branch: 'stable/oxygen'
        - nitrogen:
            branch: 'stable/nitrogen'
        - carbon:
            branch: 'stable/carbon'
            karaf-version: 'karaf3'

      install:
        - all:
            scope: 'all'

      # Features to install
      install-features: >
          odl-openflowplugin-flow-services-rest,
          odl-openflowplugin-app-table-miss-enforcer,
          odl-openflowplugin-nxm-extensions

      # Robot custom options
      robot-options: ''

Explanation:

* name: give some name like $project-csit-$functionality.
* jobs: replace 1node by 3node if your test is develop for 3node cluster.
* project: set your your project name here (e.g. openflowplugin).
* functionality: set the functionality you want to test (e.g. flow-services).
  Note this has also to match the robot test plan name you defined in the earlier
  section `<Create a test plan_>`_ (e.g. openflowplugin-flow-services.txt)
* stream: list the project branches you are going to generate system test. Only
  last branch if the project is new.
* install: this specifies controller installation, 'only' means only features in
  install-features will be installed, 'all' means all compatible features will
  be installed on top (multi-project features test).
* install-features: list of features you want to install in controller separated
  by comma.
* robot-options: robot option you want to pass to the test separated by space.

For Unmanaged project, we need 2 extra parameters:

* trigger-jobs: Unmanaged CSIT will run after succesful project merge, so just
  fill with '{project}-merge-{stream}'.
* bundle-url: Unmanaged CSIT uses project local distribution, you can get the
  local distribution URL from the Jenkins merge job itself (see example below).

So in this case it should look like this::

  ---
  - project:
      name: usc-csit-channel
      jobs:
        - inttest-csit-1node

      # The project name
      project: 'usc'

      # The functionality under test
      functionality: 'channel'

      # Project branches
      stream:
        - fluorine:
            branch: 'master'
            trigger-jobs: '{project}-merge-{stream}'
            # yamllint disable-line rule:line-length
            bundle-url: 'https://jenkins.opendaylight.org/releng/view/usc/job/usc-merge-fluorine/lastBuild/org.opendaylight.usc$usc-karaf/artifact/org.opendaylight.usc/usc-karaf/1.6.0-SNAPSHOT/usc-karaf-1.6.0-SNAPSHOT.zip'

      install:
        - all:
            scope: 'all'

      # Features to install
      install-features: 'odl-restconf,odl-mdsal-apidocs,odl-usc-channel-ui'

      # Robot custom options
      robot-options: ''

Save the changes and exit editor.

Optional: Change default tools image
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
By default a system test spins a tools VM that can be used to run some test tool
like mininet, netconf tool, BGP simulator, etc. The default values are listed
below and you only need to specify them if you are changing something, for
example "tools_system_count: 0" will skip the tools VM if you do not need it.
For a list of available images see images-list_::

  ---
  - project:
      name: openflowplugin-csit-flow-services
      jobs:
        - inttest-csit-1node

      # The project name
      project: 'openflowplugin'

      # The functionality under test
      functionality:
        - flow-services
        - gate-flow-services

      # Project branches
      stream:
        - fluorine:
            branch: 'master'
        - oxygen:
            branch: 'stable/oxygen'
        - nitrogen:
            branch: 'stable/nitrogen'
        - carbon:
            branch: 'stable/carbon'
            karaf-version: 'karaf3'

      install:
        - all:
            scope: 'all'

      # Job images
      tools_system_image: 'ZZCI - Ubuntu 16.04 - mininet-ovs-28 - 20180301-1041'

      # Features to install
      install-features: >
          odl-openflowplugin-flow-services-rest,
          odl-openflowplugin-app-table-miss-enforcer,
          odl-openflowplugin-nxm-extensions

      # Robot custom options
      robot-options: ''

Optional: Plot a graph from your job
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
Scalability and peformance tests not only PASS/FAIL but most important they
provide a number or value we want to plot in a graph and track over different
builds.

For that you can add the plot configuration like in this example below::

  ---
  - project:
      name: openflowplugin-csit-cbench
      jobs:
        - inttest-csit-1node

      # The project name
      project: 'openflowplugin'

      # The functionality under test
      functionality: 'cbench'

      # Project branches
      stream:
        - fluorine:
            branch: 'master'
        - oxygen:
            branch: 'stable/oxygen'
        - nitrogen:
            branch: 'stable/nitrogen'
        - carbon:
            branch: 'stable/carbon'
            karaf-version: 'karaf3'

      install:
        - only:
            scope: 'only'

      # Job images
      tools_system_image: 'ZZCI - Ubuntu 16.04 - mininet-ovs-28 - 20180301-1041'

      # Features to install
      install-features: 'odl-openflowplugin-flow-services-rest,odl-openflowplugin-drop-test'

      # Robot custom options
      robot-options: '-v duration_in_secs:60 -v throughput_threshold:20000 -v latency_threshold:5000'

      # Plot Info
      01-plot-title: 'Throughput Mode'
      01-plot-yaxis: 'flow_mods/sec'
      01-plot-group: 'Cbench Performance'
      01-plot-data-file: 'throughput.csv'
      02-plot-title: 'Latency Mode'
      02-plot-yaxis: 'flow_mods/sec'
      02-plot-group: 'Cbench Performance'
      02-plot-data-file: 'latency.csv'

Explanation:

* There are up to 10 plots per job and every plot can track different values,
  for example max, min, average recorded in a csv file. In the example above you
  can skip the 02-* lines if you do not use second plot.
* plot-title: title for your plot.
* plot-yaxis: your measurement (xaxis is build # so no need to fill).
* plot-group: just a label, use the same in case you have 2 plots.
* plot-data-file: this is the csv file generated by robot framework and contains
  the values to plot. Examples can be found in openflow-performance_.

Optional: Add Patch Test Job to verify project patches
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
With the steps above your new csit job will run daily on latest generated
distribution. There is one more extra and optional step if you also want to run
your system test to verify patches in your project.

The patch test is triggered in gerrit using the keyword::

  test-$project-$feature

The job will:

* Build the gerrit patch.
* Create a distribution containing the patch.
* Trigger some system test (csit) that already exists and you specify with the
  $feature definition below.

Create $project-patch-test.yaml file in your jjb folder::

  vim jjb/$project/$project-patch-test-jobs.yaml

Fill the information as below::

  ---
  - project:
      name: openflowplugin-patch-test
      jobs:
        - inttest-patch-test

      # The project name
      project: 'openflowplugin'

      # Project branches
      stream:
        - fluorine:
            branch: 'master'
            os-branch: 'queens'
        - oxygen:
            branch: 'stable/oxygen'
            os-branch: 'queens'
        - nitrogen:
            branch: 'stable/nitrogen'
            os-branch: 'pike'
        - carbon:
            branch: 'stable/carbon'
            os-branch: 'ocata'
            karaf-version: 'karaf3'

      jdk: 'openjdk8'

      feature:
        - core:
            csit-list: >
                openflowplugin-csit-1node-gate-flow-services-all-{stream},
                openflowplugin-csit-1node-gate-scale-only-{stream},
                openflowplugin-csit-1node-gate-perf-stats-collection-only-{stream},
                openflowplugin-csit-1node-gate-perf-bulkomatic-only-{stream},
                openflowplugin-csit-3node-gate-clustering-only-{stream},
                openflowplugin-csit-3node-gate-clustering-bulkomatic-only-{stream},
                openflowplugin-csit-3node-gate-clustering-perf-bulkomatic-only-{stream}

        - netvirt:
            csit-list: >
                netvirt-csit-1node-openstack-{os-branch}-gate-stateful-{stream}

        - cluster-netvirt:
            csit-list: >
                netvirt-csit-3node-openstack-{os-branch}-gate-stateful-{stream}

Explanation:

* name: give some name like $project-patch-test.
* project: set your your project name here (e.g. openflowplugin).
* stream: list the project branches you are going to generate system test. Only
  last branch if the project is new.
* feature: you can group system tests in features. Note there is a predefined
  feature -all- that triggers all features together.
* Fill the csit-list with all the system test jobs you want to run to verify a
  feature.

Debug System Test
-----------------
Before pushing your system test job into jenkins-releng_, it is recommended to
debug the job as well as the you system test code in the sandbox. To do that:

* Set up sandbox access using jenkins-sandbox-install_ instruction.
* Push your new csit job to sandbox:

  Method 1:

  you can write a comment in a releng/builder gerrit patch to have the job automatically created
  in the sandbox. The format of the comment is::

      jjb-deploy <job name>

  Method 2::

      jenkins-jobs --conf jenkins.ini update jjb/ $project-csit-1node-$functionality-only-$branch

* Open your job in jenkins-sandbox_ and start a build replacing the PATCHREFSPEC
  parameter by your int/test patch REFSPEC (e.g. refs/changes/85/23185/1). you
  can find this info in gerrit top right corner 'Download' button.
* Update the PATCHREFSPEC parameter every time you push a new patchset in the
  int/test repository.

Optional: Debug VM issues in sandbox
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
In case of problems with the test VMs, you can easily debug these issues in the
sandbox by adding the following lines in a Jenkins shell window::

  cat > ${WORKSPACE}/debug-script.sh <<EOF

  <<put your debug shell script here>>

  EOF
  scp ${WORKSPACE}/debug-script.sh ${TOOLS_SYSTEM_IP}:/tmp
  ssh ${TOOLS_SYSTEM_IP} 'sudo bash /tmp/debug-script.sh'

Note this will run a self-made debug script with sudo access in a VM of your
choice. In the example above you debug on the tools VM (TOOLS_SYSTEM_IP),
use ODL_SYSTEM_IP to debug in controller VM.

Save and push JJB changes
^^^^^^^^^^^^^^^^^^^^^^^^^
Once you are happy with your system test, save the changes and push them in the
releng builder repo::

  git add -A
  git commit -s
  git push

.. important::

  If this is your first system test job, it is recommended to add the int/test
  patch (gerrit link) in the commit message so that committers can merge both
  the int/test and the releng/builder patches at the same time.

Check system test jobs in Jenkins
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
Once your patches are merged your system test can be browsed in jenkins-releng_:

* $project-csit-1node-$functionality-only-$branch -> The single-feature test.
* $project-csit-1node-$functionality-all-$branch -> The multi-project test.
* $yourproject-patch-test-$feature-$branch -> Patch test job.

Note that jobs in jenkins-releng_ cannot be reconfigured, only jobs in
jenkins-sandbox_ can, that is why it is so important for testers to get access
to sandbox.

Support
-------
Integration people are happy to support with questions and recommendations:

* Integration IRC: OpenDaylight channel 'opendaylight-integration
* Integration Mail: OpenDaylight list 'integration-dev@lists.opendaylight.org'

.. _pulling-and-pushing-the-code: http://docs.opendaylight.org/en/stable-boron/developer-guide/pulling-and-pushing-the-code-from-the-cli.html
.. _images-list: http://docs.opendaylight.org/en/stable-boron/submodules/releng/builder/docs/jenkins.html#pool-odlpub-hot-heat-orchestration-templates
.. _openflow-performance: https://git.opendaylight.org/gerrit/gitweb?p=integration/test.git;a=blob;f=csit/suites/openflowplugin/Performance/010_Cbench.robot
.. _jenkins-releng: https://jenkins.opendaylight.org/releng/
.. _jenkins-sandbox: https://jenkins.opendaylight.org/sandbox/
.. _jenkins-sandbox-install: http://docs.opendaylight.org/en/stable-boron/submodules/releng/builder/docs/jenkins.html#jenkins-sandbox
