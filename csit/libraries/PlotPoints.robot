*** Settings ***
Documentation     Robot keyword library Plotting Points
Library           ${CURDIR}/PlotPoints.py

*** Keywords ***
Create JVM Plots                                                                 
    [Documentation]    Draw plot of two lists
    [Arguments]     ${x_list}        ${y_list}       ${x_label}      ${y_label}     ${title}        ${filename}
    PlotPoints.Plot Points      ${x_list}       ${y_list}       ${x_label}      ${y_label}      ${title}        ${filename}
