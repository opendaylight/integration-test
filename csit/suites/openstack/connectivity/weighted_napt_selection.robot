Anything you write above the Settings block is ignored by robot.

*** Settings ***
Documentation
...    = Proposed change =\n\n
...
...              We'll introduce a new configuration parameter called ``odl_base_weight`` which\n\n
...              will be configured in ``external_ids`` parameter of ``Open_vSwitch`` in specific\n\n
...              switches. This will be part of 0-day orchestration. Value for this will be a\n\n
...              number. If nothing is configured bas weight will be considered to be ``0``.\n\n
...
...              Higher the ``odl_base_weight``, greater the number of VRFs designated on a\n\n
...              given switch.
...
...              ``NAPTSwitchSelector`` will be modified to factor in this parameter when selecting\n\n
...              a designate NAPT switch. Currently weight of a given switch is only number of VRFs\n\n
...              hosted on it with base weight of 0. Weight of switch is incremented by *1* for each\n\n
...              VRF hosted on it. Switch with least weight at time of selection ends up being selected\n\n
...              as designated Switch. ``odl_base_weight`` of *X* will translate to weight *-X* in\n\n
...              ``NAPTSwitchSelector``.
...
...    You can put pictures of handsomeness: https://en.gravatar.com/userimage/130296909/cfdfdaf7664d7cc8704572c284859772.jpeg
...
...    You can make a list
...    - winter
...    - is
...    - coming
...
...    There are other tricks too...

*** Variables ***

*** Test Cases ***
Test Napt Base Weight 0
    [Documentation]    This should work like existing logic.
    Fail

Test NAPT base weight 2
    [Documentation]    Create 4 VMs in 2 VRFs on both computes
    ...    Compute with base weight 2 is designated for both VRFs
    Fail

*** Keywords ***
