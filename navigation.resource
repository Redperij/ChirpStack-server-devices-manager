*** Settings ***
Documentation    This resource file provides keywords
...              to navigate through the ChirpStack
...              web UI for the LoraWan server.

Library    Collections
Library    QWeb
Library    ConfigFileParser.py    ${CONFIG_FILENAME}
Library    GoogleSpreadsheetParser.py    ${APPLICATION}    ${SHEET}

*** Variables ***

${CONFIG_FILENAME}    local.config
${APPLICATION}    Devices1
${SHEET}    Main
${TABLE_MAX_ROWS}    ${100}

${LOGIN_URL}    http://localhost:8080
${BROWSER}      Firefox
${USERNAME}     admin
${PASSWORD}     admin
${DEVICE_PROFILE}    Metropolia_devices
${ORG_ID}    1
@{DEVICE_NAMES}
@{DEVICE_EUIS}
${COMMON_DELAY}    0

*** Keywords ***
####################################
# GO TO ############################
####################################
#"Go To" keywords provide an easy way to switch to the needed view.

Go To Applications
    [Documentation]    Opens "Applications" view.
    ...    Must be logged in to use this keyword.
    ${res}=    Is In Applications
    IF    '${res}'=='${False}'
        #Makes it viable only for the certain tenant.
        #Take that into account later on and do it via tenant name.
        Go To    ${LOGIN_URL}/#/tenants/${ORG_ID}/applications    10s
        ${res}=    Is In Applications
    END

    [Return]    ${res}

Go To Application
    [Documentation]    Opens certain application view.
    [Arguments]    ${app_name}
    ${is_in_app}=    Is In Application    ${app_name}
    IF    '${is_in_app}'=='${False}'
        ${is_in_apps}=    Go To Applications
        IF  '${is_in_apps}'=='${True}'
            ${app_is_present}=    Applications Table Contains Name    ${app_name}                
            Run Keyword If    '${app_is_present}'=='${True}'    Click Text    ${app_name}
        END
        ${is_in_app}=    Is In Application    ${app_name}
    END
    [Return]    ${is_in_app}

Go To Application Devices
    [Documentation]    Opens certain application's "Devices" view.
    [Arguments]    ${app_name}
    ${res}=    Is In Application Devices    ${app_name}
    IF    '${res}'=='${False}'
        ${res}=    Go To Application    ${app_name}
        Run Keyword If    '${res}'=='${True}'    Click Text    Devices    Multicast groups
        ${res}=    Is In Application Devices    ${app_name}
    END
    [Return]    ${res}

#TODO
#Won't work. Has to be done via eui now.
Go To Application Device
    [Documentation]    Opens certain application's certain device view.
    [Arguments]    ${app_name}    ${device_name}
    ${res}=    Is In Application Device    ${app_name}    ${device_name}
    IF    '${res}'=='${False}'
        ${res}=    Go To Application Devices    ${app_name}
        ${res}=    Is Text    ${device_name}
        Run Keyword If    '${res}'=='${True}'    Click Text    ${device_name}    Device name
        ${res}=    Is In Application Device    ${app_name}    ${device_name}
    END
    [Return]    ${res}

Go To Application Device Config
    [Documentation]    Opens specified device's configuration view.
    [Arguments]    ${app_name}    ${device_name}
    ${res}=    Is In Application Device Config    ${app_name}    ${device_name}
    IF    '${res}'=='${False}'
        ${res}=    Go To Application Device    ${app_name}    ${device_name}
        Run Keyword If    '${res}'=='${True}'    Click Text    Configuration    OTAA keys
        ${res}=    Is In Application Device Config    ${app_name}    ${device_name}
    END
    [Return]    ${res}

Go To Application Device Keys
    [Documentation]    Opens specified device's app-keys view.
    [Arguments]    ${app_name}    ${device_name}
    ${res}=    Is In Application Device Keys    ${app_name}    ${device_name}
    IF    '${res}'=='${False}'
        ${res}=    Go To Application Device    ${app_name}    ${device_name}
        Run Keyword If    '${res}'=='${True}'    Click Text    OTAA keys    Configuration
        ${res}=    Is In Application Device Keys    ${app_name}    ${device_name}
    END
    [Return]    ${res}

####################################
# IS IN ############################
####################################
#"Is In" keywords are used to identify the screen we are currently viewing.

Is In Applications
    [Documentation]    Identifies, whether we are
    ...    in the "Applications" view.
    ${res1}=    Is Element    xpath\=//table[@style\="table-layout: auto;"]    1s
    ${res2}=    Is Text    Add application
    #What an utter crap. (res = res1 && res2)
    ${res}=    Set Variable If    '${res1}'=='${True}' and '${res2}'=='${True}'    ${True}    ${False}
    [Return]    ${res}

Is In Application
    [Documentation]    Identifies, whether we are
    ...    in the certain "Application" view.
    [Arguments]    ${app_name}
    ${res1}=    Is Text    ${app_name}    1s
    ${res2}=    Is Text    Application configuration    1s
    ${res}=    Set Variable If    '${res1}'=='${True}' and '${res2}'=='${True}'    ${True}    ${False}
    [Return]    ${res}

Is In Application Devices
    [Documentation]    Identifies, whether we are
    ...    in the application "Devices" view.
    [Arguments]    ${app_name}
    ${res1}=    Is In Application    ${app_name}
    ${res2}=    Is Text    Last seen    1s
    ${res}=    Set Variable If    '${res1}'=='${True}' and '${res2}'=='${True}'    ${True}    ${False}
    [Return]    ${res}


Is In Application Device
    [Documentation]    Identifies, whether we are
    ...    in the application certain "Device" view.
    [Arguments]    ${app_name}    ${device_name}
    ${res1}=    Is Text    ${app_name}    1s
    ${res2}=    Is Text    ${device_name}    1s
    ${res3}=    Is Text    OTAA keys    1s
    ${res}=    Set Variable If    '${res1}'=='${True}' and '${res2}'=='${True}' and '${res3}'=='${True}'    ${True}    ${False}
    [Return]    ${res}

Is In Application Device Config
    [Documentation]    Identifies, whether we are
    ...    in the application certain device's "Configuration" view.
    [Arguments]    ${app_name}    ${device_name}
    ${res1}=    Is Text    ${app_name}    1s
    ${res2}=    Is Text    ${device_name}    1s
    ${res3}=    Is Text    Variables    1s
    ${res}=    Set Variable If    '${res1}'=='${True}' and '${res2}'=='${True}' and '${res3}'=='${True}'    ${True}    ${False}
    [Return]    ${res}

Is In Application Device Keys
    [Documentation]    Identifies, whether we are
    ...    in the application certain device's "Keys" view.
    [Arguments]    ${app_name}    ${device_name}
    ${res1}=    Is Text    ${app_name}    1s
    ${res2}=    Is Text    ${device_name}    1s
    ${res3}=    Is Text    Application key    1s
    ${res}=    Set Variable If    '${res1}'=='${True}' and '${res2}'=='${True}' and '${res3}'=='${True}'    ${True}    ${False}
    [Return]    ${res}

####################################
# DEVICES TABLE ####################
####################################
#"Devices Table" keywords provide more convinient navigation
# through the table of devices inside the application
#TODO
Devices Table Contains Eui
    [Documentation]    Checks whether table contains the specified eui.
    [Arguments]    ${app_name}    ${eui}    ${return}=${True}
    ${res}=    Set Variable    ${False}
    ${table_end}=    Set Variable    ${False}
    ${arrow_index}=    Set Variable    ${1}

    Devices Table Switch To First Page    ${app_name}
    
    WHILE  '${table_end}'=='${False}'
        ${res}=    Devices Table Sheet Contains Eui    ${eui}
        IF  '${res}'=='${False}'
            #We always have to press the right arrow. On the first page it is the only one clickable, so index is 1
            #On all other pages it is second clickable element - thus index is 2.
            #On the last page we still try to click second element and receive an exception.
            TRY 
                Click Element    xpath\=//button[@class\="MuiButtonBase-root MuiIconButton-root MuiIconButton-colorInherit"]    0.5s    False    ${arrow_index}
                ${arrow_index}=    Set Variable    ${2}
            EXCEPT
                ${table_end}=    Set Variable    ${True}
            END 
        ELSE
            ${table_end}=    Set Variable    ${True}
        END
    END
    
    Run Keyword If    '${return}'=='${True}'    Devices Table Switch To First Page    ${app_name}
    [Return]    ${res}

#TODO
Devices Table Sheet Contains Eui
    [Documentation]    Checks a sheet of Devices table for the device with specified eui.
    [Arguments]    ${eui}
    ${res}=    Set Variable    ${False}
    ${res}=    Is Text    ${eui}    0.2s
    [Return]    ${res}

#TODO
Devices Table Contains Name
    [Documentation]    Checks whether table contains the specified device name.
    [Arguments]    ${app_name}    ${device_name}    ${return}=${True}
    ${res}=    Set Variable    ${False}
    ${table_end}=    Set Variable    ${False}
    ${arrow_index}=    Set Variable    ${1}

    Devices Table Switch To First Page    ${app_name}
    
    WHILE  '${table_end}'=='${False}'
        ${res}=    Devices Table Sheet Contains Name    ${device_name}
        IF  '${res}'=='${False}'
            Set Config    Delay    0.5s
            #We always have to press the right arrow. On the first page it is the only one clickable, so index is 1
            #On all other pages it is second clickable element - thus index is 2.
            #On the last page we still try to click second element and receive an exception.
            TRY
                Click Element    xpath\=//button[@class\="MuiButtonBase-root MuiIconButton-root MuiIconButton-colorInherit"]    0.5s    False    ${arrow_index}
                ${arrow_index}=    Set Variable    ${2}
            EXCEPT
                ${table_end}=    Set Variable    ${True}
            END
            Set Config    Delay    ${COMMON_DELAY}
        ELSE
            ${table_end}=    Set Variable    ${True}
        END
    END
    Run Keyword If    '${return}'=='${True}'    Devices Table Switch To First Page    ${app_name}
    [Return]    ${res}

#TODO
Devices Table Sheet Contains Name
    [Documentation]    Checks a sheet of Devices table for the device with specified name.
    [Arguments]    ${name}
    ${res}=    Set Variable    ${False}

    Use Table    Name
    FOR  ${i}  IN RANGE  ${TABLE_MAX_ROWS}
        TRY
            ${candidate}=    Get Cell Text    r?${name}/c2    ${i}    0.2s
            IF  '${candidate}'=='${name}'
                ${res}=    Set Variable    ${True}
                BREAK
            END
        EXCEPT
            BREAK
        END
    END
    
    [Return]    ${res}

#TODO
Devices Table Get Corresponding Name
    [Documentation]    Gets a device name corresponding to the specified eui.
    [Arguments]    ${app_name}    ${eui}    ${return}=${True}    ${same_sheet}=${False}
    ${name}=    Set Variable    ${None}
    ${res}=    Set Variable    ${False}
    ${table_end}=    Set Variable    ${False}
    ${arrow_index}=    Set Variable    ${1}

    Run Keyword If    '${same_sheet}'=='${False}'    Devices Table Switch To First Page    ${app_name}
    Use Table    Name
    
    WHILE  '${table_end}'=='${False}'
        ${res}=    Devices Table Sheet Contains Eui    ${eui}
        IF  '${res}'=='${False}'
            #We always have to press the right arrow. On the first page it is the only one clickable, so index is 1
            #On all other pages it is second clickable element - thus index is 2.
            #On the last page we still try to click second element and receive an exception.
            TRY 
                Click Element    xpath\=//button[@class\="MuiButtonBase-root MuiIconButton-root MuiIconButton-colorInherit"]    0.5s    False    ${arrow_index}
                ${arrow_index}=    Set Variable    ${2}
            EXCEPT
                ${table_end}=    Set Variable    ${True}
            END 
        ELSE
            #Log To Console    Getting corr name for: ${eui}\n
            ${name}=    Get Cell Text    r?${eui}/c2    1    0.2s
            ${table_end}=    Set Variable    ${True}
        END
    END
    Run Keyword If    '${return}'=='${True}'    Devices Table Switch To First Page    ${app_name}
    [Return]    ${name}

#TODO
Devices Table Switch To First Page
    [Documentation]    Unconventionally swithces to the first page of devices table of specified application.
    #Can be done via pressing arrow in opposite direction, but it may take longer in case if there are a lot of entries.
    [Arguments]    ${app_name}
    Go To Applications
    Go To Application    ${app_name}
    ${res}=    Go To Application Devices    ${app_name}
    [Return]    ${res}

####################################
# APPLICATIONS TABLE ###############
####################################
#"Applications Table" keywords provide more convinient
# navigation through the table of applications.

Applications Table Contains Name
    [Documentation]    Checks whether table contains the specified application name.
    [Arguments]    ${app_name}    ${return}=${False}
    ${res}=    Set Variable    ${False}
    ${table_end}=    Set Variable    ${False}
    ${arrow_index}=    Set Variable    ${2}

    Go To Applications
    
    WHILE  '${table_end}'=='${False}'
        ${res}=    Applications Table Sheet Contains Name    ${app_name}
        IF  '${res}'=='${False}'
            Set Config    Delay    0.5s
            ${disabled_next}=    Get Element Count    xpath\=//li[@class\="ant-pagination-next ant-pagination-disabled"]    0.5s
            IF    '${disabled_next}'=='${1}'
                ${table_end}=    Set Variable    ${True}
            ELSE
                Click Element    xpath\=//button[@class\="ant-pagination-item-link"]    0.5s    False    2
            END
            Set Config    Delay    ${COMMON_DELAY}
        ELSE
            ${table_end}=    Set Variable    ${True}
        END
    END
    Run Keyword If    '${return}'=='${True}'    Go To Applications
    [Return]    ${res}

Applications Table Sheet Contains Name
    [Documentation]    Checks a sheet of Devices table for the device with specified name.
    [Arguments]    ${app_name}
    ${res}=    Set Variable    ${False}

    Use Table    Name
    FOR  ${i}  IN RANGE  ${TABLE_MAX_ROWS}
        TRY
            ${candidate}=    Get Cell Text    r?${app_name}/c1    ${i}    0.2s
            IF  '${candidate}'=='${app_name}'
                ${res}=    Set Variable    ${True}
                BREAK
            END
        EXCEPT
            BREAK
        END
    END
    
    [Return]    ${res}

####################################
# MISCELLANEOUS ####################
####################################

Log In
    [Documentation]    Tries to pass "Login" screen
    [Arguments]    ${username}    ${password}
    Verify Text    ChirpStack login
    Type Text    xpath\=//input[@id\="email"]    ${username}
    Type Text    xpath\=//input[@id\="password"]    ${password}
    Click Text    Submit

Initialise
    ${login_url}=    Get From Config File    LOGIN_URL
    Set Global Variable    ${LOGIN_URL}    ${login_url}
    ${browser}=    Get From Config File    BROWSER
    Set Global Variable    ${BROWSER}    ${browser}
    ${username}=    Get From Config File    USERNAME
    Set Global Variable    ${USERNAME}    ${username}
    ${password}=    Get From Config File    PASSWORD
    Set Global Variable    ${PASSWORD}    ${password}
    ${device_profile}=    Get From Config File    DEVICE_PROFILE
    Set Global Variable    ${DEVICE_PROFILE}    ${device_profile}
    ${org_id}=    Get From Config File    TENANT_ID
    Set Global Variable    ${ORG_ID}    ${org_id}
    Log To Console    \nConfig: ${LOGIN_URL} ${BROWSER} ${USERNAME} ${PASSWORD} ${DEVICE_PROFILE} ${ORG_ID}\n
    Start Browser    ${LOGIN_URL}    ${BROWSER}

Start Browser
    [Arguments]    ${url}    ${browser}
    Open Browser    ${url}    ${browser}

Stop Browser
    Close Browser