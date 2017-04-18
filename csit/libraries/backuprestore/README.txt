== Backup-Restore test support library ==

=== 1. Introduction ===

The purpose of this library is to allow the generic verification
of feature correctness in backup + restore scenarios.

A feature is correct from a backup+restore standpoint when,
at any provisioning point, a controller backup, followed by a
restore, can be performed, and the execution of that procedure
will not have any impact on traffic tests or datastore state
check in respect to the expected behaviour when no backup + restore
procedures are performed.

The library can also be used (with minimal modifications) to check
whether a feature is safe (continues operating correctly) in the
event of a controller reboot (e.g. SFC is known not to, because of
keeping certain information (rendered service paths) in the
operational DS only and being unable to reconstruct that information
after a reboot).

=== 2. Library usage ===

==== 2.1. Use as Robot Library keywords ====

The library is delivered as a readily-available Robot FW library in
the ODL integration/test repository. It provides two keywords:

- A new keyword ('''BackupRestoreCheck'''), which:

# Performs a complete datastore export (using Daexim export rpc)
# Does a backup, then a restore of the backup previously
  created. NOTE: this step is purposefully not implemented in the
  keyword (a placeholder for concrete backup & restore scripts is
  provided instead). ODL does not provide a comprehensive B&R implementation:
  such implementation shall include both the datastore and certain
  configuration files, but those configuration files depend on the
  concrete ODL distribution / deployment, so ODL provides only some
  pieces to implement that backup (i.e. the datastore backup RPCs).
  This library is contributed with the purpose of easing the testing
  of any backup&restore implementation; therefore that implementation
  shall be incorporated to this library (by modifying this step)
# Performs a new datastore export
# Compares both config & operational datastores for differences (that
  is, pre-backup and post-restore exports for both datastores), optionally
  prefiltering those exports using pre-filter files (those prefilter files
  are passed as parameters to the keyword)
# Fails when pre-backup and post-restore exports are different even after
  removing the specified filtered parts

- A new keyword ('''ConditionalBackupRestoreCheck'''), which performs
  the same steps than BackupRestoreCheck only when a command-line flag ("-v
  BR_TESTING_ENABLED:true") is present. This allows to easily add
backup-restore verification on existing tests, allowing to toggle
the execution of that verification

===== 2.1.1. Adding the br verification keyword to an existing robot test =====

The library has been designed from the ground up to allow its use in
existing testcases, so specific feature provisioning can be tested for
correctness in backup-restore scenarios. The design premises for the
library were:
* To be very easy to incorporate into existing testcases (just one resource
 import + the verification keyword, that shall be inserted in the existing
 testcase just after test specific provisioning and before existing test
verification steps)
* To be togglable (that is, to allow whether to execute / to bypass the
export + backup + restore + export + exports comparison block)

===== 2.1.2. Steps to add backup-restore verification to an existing test suite =====
1) Suite setup: Add ClusterManagement Setup (it is needed for Daexim export
 to work). Hint: if the testsuite already contains an init suite keyword, you
 can use the Run Keywords construct in order to run both initialization keywords.

(Subsequent examples use diff-format):

*** Settings ***
Documentation     Test suite for SFC Service Functions, Operates functions from Restconf APIs.
-Suite Setup       Init Suite
+Suite Setup       Run Keywords    Init Suite    ClusterManagement Setup
Suite Teardown    Delete All Sessions

2) Import Backup-Restore support library

Resource          ../../../libraries/TemplatedRequests.robot
+Resource          ../../../libraries/BackupRestoreKeywords.robot

3) Add the verification keyword (after provisioning, before assertions/traffic verification)
Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
   ${elements}=    Create List    SFC1-100-Path-1    "parent-service-function-path":"SFC1-100"    "hop-number":0    "service-index":255    "ho
...    "service-index":254    "hop-number":2    "service-index":253
+    ConditionalBackupRestoreCheck    -    -    -    -
Check For Elements At URI    ${OPERATIONAL_RSPS_URI}    ${elements}

4) Execute the suite without passing the enablement flag (or pass it disabled:
  '-v BR_TESTING_ENABLED:false'). Note how the testcase runs as always
5)  Execute the suite, now passing the enablement flag ('-v BR_TESTING_ENABLED:true'):
5.1. If the testcases pass, that means the suite provisioning is safe for B&R
  (that is, both config and operational DSs are identical before and after the
  procedure, and any assert / traffic verification the cases perform are also correct.
5.2. If a testcase fail:
5.2.1. If it is the ConditionalBackupRestoreCheck keyword what fails: it means
  differences are found in the datastores before the backup / after the restore. Test
log should include the list of differences found. Two types of differences:
5.2.1.1. If differences are non-issues (e.g. elements whose changes are expected
  after a backup + restore, as elements containing timestamps that are recalculated
  after the restore, or elements showing transitory states which are not important
  regarding B&R correctness), then create as many pre-filter entries as necessary
  in the corresponding prefilter file (4 prefilter files can be passed to the
  keyword: prefilter for the config DS before the backup, config DS after restore,
  operational DS before the backup and operational DS after the restore. Repeat until
  all unimportant DS entries are filtered
5.2.1.2. Differences found on which the former rule is not applicable should be
  checked carefully, as they are likely to showcase application bugs (regading B&R /
  controller reboots)
5.2.2 Errors in the testcase execution when the BR_TESTING_ENABLED:true flag is
  passed, in keywords other than the verification keyword, are also candidates to
  point to application bugs (e.g. because of using runtime-required in-memory
  state that they fail to reconstruct after the restore), thus requiring careful revision

==== 2.2. Execution as a standalone commandline utility ====
In scenarios where Robot FW is not used for testing, the library core (this is, the
prefiltered json comparison) can also be used from the command line. The tool is
provided as a python commandline utility. Help follows: 

  odluser@odluser-VirtualBox:~/odl/test/csit/libraries/backuprestore\> python JsonDiffTool.py -h
  usage: JsonDiffTool.py [-h] -i INITIALFILE -f FINALFILE [-ipf INITIALPREFILTER] [-fpf FINALPREFILTER] [-pd] [-v]
  both initial and final json files are compared for differences. The program
  returns 0 when the json contents are the same, or the number of differences
  otherwise. Both json files can be prefiltered for certain patterns before
  checking the differences
  optional arguments:
  -h, --help            show this help message and exit
  -i INITIALFILE, --initialFile INITIALFILE
                        initial json file
  -f FINALFILE, --finalFile FINALFILE
                        final json file
  -ipf INITIALPREFILTER, --initialPreFilter INITIALPREFILTER
                        File with pre-filtering patterns to apply to the
                        initial json file before comparing
  -fpf FINALPREFILTER, --finalPreFilter FINALPREFILTER
                        File with pre-filtering patterns to apply to the final
                        json file before comparing
  -pd, --printDifferences
                        on differences found, prints the list of paths for the
                        found differences before exitting
  -v, --verbose         generate log information

===== 2.2.1. Command-line usage examples =====
- Checking for differences between two json files (showing only the number of differences)
  odluser@odluser-VirtualBox:~/odl/test/csit/libraries/backuprestore\> python JsonDiffTool.py -i ./testinput/arrayTwoNames.json -f ./testinput/arrayThreeNamesSorted.json
  1

- Checking for differences and displaying the differences (jsonpatch format)
  odluser@odluser-VirtualBox:~/odl/test/csit/libraries/backuprestore\> python JsonDiffTool.py -i ./testinput/arrayTwoNames.json -f ./testinput/arrayThreeNamesSorted.json -pd
  {"path": "/2", "value": {"Name": "Tom"}, "op": "add"}
  1

- Checking for differences (and displaying them), using a pre-filter file for the initial json file
  odluser@odluser-VirtualBox:~/odl/test/csit/libraries/backuprestore\> python JsonDiffTool.py -i ./testinput/mainTestCase/odl_backup_operational_before.json -f testinput/mainTestCase/odl_backup_operational_after.json -ipf testinput/mainTestCase/json_prefilter.conf -pd
  {"path": "/entity-owners:entity-owners/entity-type/2", "op": "remove"}
  {"path": "/entity-owners:entity-owners/entity-type/4", "value": {"type": "iface", "entity": [{"owner": "member-1", "id": "/general-entity:entity[general-entity:name='iface']", "candidate": [{"name": "member-1"}]}]}, "op": "add"}
  {"path": "/network-topology:network-topology/topology/3", "value": {"node": [{"netconf-node-topology:host": "127.0.0.1", "netconf-node-topology:port": 1830, "netconf-node-topology:connection-status": "connecting", "node-id": "CONTROLLER1"}, {"netconf-node-topology:host": "127.0.0.1", "netconf-node-topology:port": 1830, "netconf-node-topology:connection-status": "connecting", "node-id": "CONTROLLER2"}], "topology-id": "topology-netconf"}, "op": "replace"}
  {"path": "/ietf-yang-library:modules-state/module-set-id", "value": "3", "op": "replace"}
  {"path": "/ietf-yang-library:modules-state/module/56", "op": "remove"}
  {"path": "/ietf-yang-library:modules-state/module/116", "op": "remove"}
  {"path": "/ietf-yang-library:modules-state/module/127", "op": "remove"}
  {"path": "/ietf-yang-library:modules-state/module/140", "op": "remove"}
  {"path": "/ietf-yang-library:modules-state/module/139", "op": "remove"}
  {"path": "/ietf-yang-library:modules-state/module/185", "op": "remove"}
  {"path": "/ietf-yang-library:modules-state/module/238", "op": "remove"}
  {"path": "/ietf-yang-library:modules-state/module/267", "op": "remove"}
  {"path": "/ietf-yang-library:modules-state/module/269", "op": "remove"}
  {"path": "/ietf-yang-library:modules-state/module/278", "op": "remove"}
  {"path": "/ietf-yang-library:modules-state/module/277", "op": "remove"}
  15

===== 2.2.2. Unit tests ===== 
A handful of unit tests (testing both jsonpath - jsonpatch expression transformation,
difference evaluation, use of filters and error cases) are provided. They can be
executed as standard python unittests from the commandline:

  odluser@odluser-VirtualBox:~/odl/test/csit/libraries/backuprestore\> python backuprestoretest.py
  0
  .2
  .usage: backuprestoretest.py [-h] -i INITIALFILE -f FINALFILE
                              [-ipf INITIALPREFILTER] [-fpf FINALPREFILTER]
                              [-pd] [-v]
  backuprestoretest.py: error: argument -i/--initialFile is required
  .14
  14
  .16
  16
  .16
  16
  .1
  ..16
  16
  ...
  ----------------------------------------------------------------------
  Ran 11 tests in 0.881s
  OK

=== 3. Prefilter file format ===
Prefilter files:
* Can contain any number of jsonpath expressions ([http://goessner.net/articles/JsonPath/ jsonpath expressions specification])
* Use "#" as line prefix for comments
Example:
  #
  # Pre-filter file example (removes the module from ietf-yang-library:modules-state which name is 'extension-resync-message')
  #
  $.ietf-yang-library:modules-state.module[?(@.name=='extension-resync-message')]
  # $.ietf-yang-library:modules-state.module[?(@.name=='extension-switchfeatures-message')]

=== 4. Dependencies / discarded alternatives ===

The library includes in the commit itself the jsonpath library by Phil Budne
(https://pypi.python.org/pypi/jsonpath/). This had to be done in order to rename
the module (from jsonpath to jsonpathl), because RIDE fails to import a class
from a module with the same name, which is the case for this library. The library
license (MIT) allows for including / modifying it, so this inclusion is safe license-wise.

Other alternatives to this library were explored, but were found unfit for the
purpose. Specifically, we tried to use the popular jsonpath-rw library, but it
does not support json query filtering by attribute values (only by field names),
which is a must. Also objectpath, but the library does not support the return of
the path of matching objects (only matched objects themselves). Those paths are
required (they are the ones which are transformed into jsonpatch expressions)

jsonpatch library (https://pypi.python.org/pypi/jsonpatch) is expected to be
installed in order for this library to work. The library is used for removing json
elements via patches
