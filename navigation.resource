*** Settings ***
Documentation    This resource file provides keywords
...              to navigate through the ChirpStack
...              web UI for the LoraWan server.

Library    Collections
Library    QWeb

*** Variables ***

${LOGIN URL}    http://192.168.1.66:8080
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
#"Go To" keywords provide an easy way to switch to the needed view.
Go To Applications
    [Documentation]    Opens "Applications" view.
    ...    Must be logged in to use this keyword.
    ${res}=    Is In Applications
    IF    '${res}'=='${False}'
        #Makes it viable only for the first organization.
        #Take that into account later on.
        Go To    http://192.168.1.66:8080/#/organizations/1/applications
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


Log In
    [Documentation]    Tries to pass "Login" screen
    [Arguments]    ${username}    ${password}
    Verify Text    Login
    Type Text    xpath\=//input[@id\="username"]    ${username}
    Type Text    xpath\=//input[@id\="password"]    ${password}
    Click Text    Login    2