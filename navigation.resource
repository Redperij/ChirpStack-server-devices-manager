*** Settings ***
Documentation    This resource file provides keywords
...              to navigate through the ChirpStack
...              web UI for the LoraWan server.

Library    Collections
Library    QWeb
Library    ConfigFileParser.py    ${CONFIG_FILENAME}

*** Variables ***

${CONFIG_FILENAME}    local.config
${LOGIN_URL}    http://192.168.1.66:8080
${BROWSER}      Firefox
${USERNAME}     admin
${PASSWORD}     admin
${APPLICATION}    FixMe
${APPLICATION_PROFILE}    Lorix1_service
${DEVICE_PROFILE}    Metropolia_devices
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
        #Makes it viable only for the first organization.
        #Take that into account later on.
        Go To    http://192.168.1.66:8080/#/organizations/1/applications    10s
        ${res}=    Is In Applications
    END

    [Return]    ${res}
    
Go To Application
    [Documentation]    Opens certain application view.
    [Arguments]    ${app_name}
    ${res}=    Is In Application    ${app_name}
    IF    '${res}'=='${False}'
        ${res}=    Go To Applications
        Run Keyword If    '${res}'=='${True}'    Click Text    ${app_name}
        ${res}=    Is In Application    ${app_name}
    END
    [Return]    ${res}

Go To Application Devices
    [Documentation]    Opens certain application's "Devices" view.
    [Arguments]    ${app_name}
    ${res}=    Is In Application Devices    ${app_name}
    IF    '${res}'=='${False}'
        ${res}=    Go To Application    ${app_name}
        Run Keyword If    '${res}'=='${True}'    Click Text    Devices    Application Configuration
        ${res}=    Is In Application Devices    ${app_name}
    END
    [Return]    ${res}

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

Go To Application Device Keys
    [Documentation]    Opens specified device's app-keys view.
    [Arguments]    ${app_name}    ${device_name}
    ${res}=    Is In Application Device Keys    ${app_name}    ${device_name}
    IF    '${res}'=='${False}'
        ${res}=    Go To Application Device    ${app_name}    ${device_name}
        Run Keyword If    '${res}'=='${True}'    Click Text    Keys (OTAA)    Configuration
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
    ${res1}=    Is Element    xpath\=//table[@class\="MuiTable-root"]    1s
    ${res2}=    Is Text    ID
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
    ${res1}=    Is Text    ${app_name}    1s
    ${res2}=    Is Text    Last seen    1s
    ${res}=    Set Variable If    '${res1}'=='${True}' and '${res2}'=='${True}'    ${True}    ${False}
    [Return]    ${res}


Is In Application Device
    [Documentation]    Identifies, whether we are
    ...    in the application certain "Device" view.
    [Arguments]    ${app_name}    ${device_name}
    ${res1}=    Is Text    ${app_name}    1s
    ${res2}=    Is Text    ${device_name}    1s
    ${res3}=    Is Text    Details    1s
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

Devices Table Sheet Contains Eui
    [Documentation]    Checks a sheet of Devices table for the device with specified eui.
    [Arguments]    ${eui}
    ${res}=    Set Variable    ${False}
    ${res}=    Is Text    ${eui}    0.2s
    [Return]    ${res}


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

Devices Table Sheet Contains Name
    [Documentation]    Checks a sheet of Devices table for the device with specified name.
    [Arguments]    ${name}
    ${res}=    Set Variable    ${False}

    Use Table    xpath\=//table[@class\="MuiTable-root"]
    FOR  ${i}  IN RANGE  ${100}
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

Devices Table Get Corresponding Name
    [Documentation]    Gets a device name corresponding to the specified eui.
    [Arguments]    ${app_name}    ${eui}    ${return}=${True}    ${same_sheet}=${False}
    ${name}=    Set Variable    ${None}
    ${res}=    Set Variable    ${False}
    ${table_end}=    Set Variable    ${False}
    ${arrow_index}=    Set Variable    ${1}

    Run Keyword If    '${same_sheet}'=='${False}'    Devices Table Switch To First Page    ${app_name}
    Use Table    xpath\=//table[@class\="MuiTable-root"]
    
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

Devices Table Switch To First Page
    [Documentation]    Unconventionally swithces to the first page of devices table of specified application.
    #Can be done via pressing arrow in opposite direction, but it may take longer in case if there are a lot of entries.
    [Arguments]    ${app_name}
    Go To Applications
    Go To Application    ${app_name}
    ${res}=    Go To Application Devices    ${app_name}
    [Return]    ${res}

####################################
# MISCELLANEOUS ####################
####################################

Log In
    [Documentation]    Tries to pass "Login" screen
    [Arguments]    ${username}    ${password}
    Verify Text    Login
    Type Text    xpath\=//input[@id\="username"]    ${username}
    Type Text    xpath\=//input[@id\="password"]    ${password}
    Click Text    Login    2

Initialise
    ${LOGIN_URL}=    Get From Config File    LOGIN_URL
    ${BROWSER}=    Get From Config File    BROWSER
    ${USERNAME}=    Get From Config File    USERNAME
    ${PASSWORD}=    Get From Config File    PASSWORD
    ${APPLICATION_PROFILE}=    Get From Config File    APPLICATION_PROFILE
    ${DEVICE_PROFILE}=    Get From Config File    DEVICE_PROFILE
    Log To Console    Config: ${LOGIN_URL} ${BROWSER} ${USERNAME} ${PASSWORD} ${APPLICATION_PROFILE} ${DEVICE_PROFILE}
    Start Browser

Start Browser
    Open Browser    ${LOGIN_URL}    ${BROWSER}

Stop Browser
    Close Browser