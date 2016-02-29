*** Settings ***
Documentation     Definitions of testing data for the system test robot suites of the
...               OpenDaylight dlux yangui project.


*** Variables *** 

${row_number_1}    1
${row_number_2}    2
${row_number_3}    3
${row_number_4}    4
${row_number_5}    5
${row_number_6}    6
${row_number_7}    7
${row_number_8}    8
${row_number_9}    9

### YANG UI API ###

${Default_ID}    [0]
${Topology_Id_0}    t0
${Topology_Id_1}    t1
${Topology_Id_2}    t2
${Topology_Id_3}    t3
${Node_Id_0}    t0n0
${Node_Id_1}    t0n1
${Node_Id_2}    t0n2
${Link_Id_0}    t0l0
${Link_Id_1}    t0l1
${Link_Id_2}    t0l2
${Source-node}    s0
${Destination-node}    d0
${Topology_ID}    ${EMPTY}
${Node_ID}    ${EMPTY}
${Link_ID}    ${EMPTY}
${Previewed_API}    ${EMPTY}

### YANG UI PARAMETERS ###

${Param_Name_1}    p1
${Param_Name_2}    p2
${Param_Name_3}    p3
${Param_Name_4}    p4
${Param_Name_5}    p5

${Param_Name_Incorrect}    ?

${Param_Value_1}    v1
${Param_Value_2}    v2
${Param_Value_3}    v3
${Param_Value_4}    v4
${Param_Value_5}    v5 
${Param_Value_1_Edited}    v1edited

${Parameters_To_Import_File_Path}    ${CURDIR}${/}parameters_to_import.json

### YANG UI HISTORY ###


### COLLECTION ###
${Name_1}    N1
${Name_2}    N2
${Name_3}    N3
${Name_4}    N4
${Name_5}    N5
${Name_6}    N6
${Name_7}    N7
${Name_8}    N8
${Name_9}    N9
${Name_10}    N10

${Group_1}    G1
${Group_2}    G2
${Group_3}    G3
${Group_4}    G4
${Group_5}    G5
${group_number_1}    1
${group_number_2}    2
${group_number_3}    3
${group_number_4}    4
${group_number_5}    5

${Nongroup_Collection_To_Import_File_Path}    ${CURDIR}${/}requestCollection_nongroup.json
${Mixed_Collection_To_Import_File_Path}    ${CURDIR}${/}requestCollection_mixed.json
${Group_Collection_To_Import_File_Path}    ${CURDIR}${/}requestCollection_group.json

  

