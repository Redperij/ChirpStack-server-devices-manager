*** Settings ***
Documentation    Controlling the server interface with Robot Framework

Resource    navigation.resource

Task Setup      Initialise
Task Teardown   Stop Browser

*** Variables ***

*** Tasks ***
Add Devices
    Set Config    Delay    ${COMMON_DELAY}

    &{d}=    Read Devices From File
    Parse Devices Dictionary    &{d}

    Log In    ${USERNAME}    ${PASSWORD}
    Initialise And Open Application Screen    ${APPLICATION}    ${APPLICATION_PROFILE}

    Go To Application Devices    ${APPLICATION}
    
    ${dev_num}=    Get Length    ${DEVICE_NAMES}
    @{app_keys}=    Create List
    FOR  ${i}  IN RANGE  ${dev_num}
        ${dev_name}=    Get From List    ${DEVICE_NAMES}    ${i}
        ${dev_eui}=    Get From List    ${DEVICE_EUIS}    ${i}
        ${app_key}=    Add Device    ${APPLICATION}    ${dev_name}    ${dev_eui}    ${DEVICE_PROFILE}
        Append To List    ${app_keys}    ${app_key}
    END

    Log To Console    \nReceived:\n
    FOR  ${app_key}  IN  ${app_keys}
        Log To Console    [${app_key}]\n
    END

    &{d}=    Create Dictionary From Lists    ${DEVICE_EUIS}    ${app_keys}
    Log Dictionary    ${d}


Delete Devices
    Set Config    Delay    ${COMMON_DELAY}
    
    &{d}=    Read Devices From File
    Parse Devices Dictionary    &{d}

    Log In    ${USERNAME}    ${PASSWORD}
    Initialise And Open Application Screen    ${APPLICATION}    ${APPLICATION_PROFILE}
    Go To Application Devices    ${APPLICATION}
    
    ${dev_num}=    Get Length    ${DEVICE_NAMES}
    FOR  ${i}  IN RANGE  ${dev_num}
        ${dev_name}=    Get From List    ${DEVICE_NAMES}    ${i}
        Delete Device    ${APPLICATION}    ${dev_name}
        ${res}=    Devices Table Contains Name    ${APPLICATION}    ${dev_name}    ${False}
        Run Keyword If    '${res}'=='${True}'    Fail    Was unable to delete device "${dev_name}", aborting.
        #Verify No Text    ${dev_name}
    END

Delete All Devices
    Set Config    Delay    ${COMMON_DELAY}
    Log In    ${USERNAME}    ${PASSWORD}
    Initialise And Open Application Screen    ${APPLICATION}    ${APPLICATION_PROFILE}
    Go To Application Devices    ${APPLICATION}

    Use Table    xpath\=//table[@class\="MuiTable-root"]
    ${stop}=    Is Text    0-0 of 0    0.2s
    WHILE  '${stop}'=='${False}'
        ${dev_name}=    Get Cell Text    r1c2
        Delete Device    ${APPLICATION}    ${dev_name}    ${True}
        ${stop}=    Is Text    0-0 of 0    0.5s
    END

Delete Application
    Set Config    Delay    ${COMMON_DELAY}
    Log In    ${USERNAME}    ${PASSWORD}
    Initialise And Open Application Screen    ${APPLICATION}    ${APPLICATION_PROFILE}
    ${res}=    Go To Application Devices    ${APPLICATION}

    IF  '${res}'=='${True}'
        Click Text    Delete
        Close Alert    Accept    5s
        Verify No Text    ${APPLICATION}
    ELSE
        Fail    Was unable to delete the "${APPLICATION}" app.
    END

#Yeah, this crap may also be needed.
Rename Devices
    #Searching for a device by uid and editting its name via figuring out the row of the table.

Test
    Set Config    Delay    ${COMMON_DELAY}
    Log In    ${USERNAME}    ${PASSWORD}
    Initialise And Open Application Screen    ${APPLICATION}    ${APPLICATION_PROFILE}
    ${res}=    Go To Application Devices    ${APPLICATION}
    IF  '${res}'=='${True}'
        ${res}=    Devices Table Contains Eui    ${APPLICATION}    2cf7f12042007da2    ${False}
        Log To Console    Device with eui 2cf7f12042007da2 is ${res}
    ELSE
        Fail    Was unable to reach the "${APPLICATION}" app.
    END

    ${res}=    Devices Table Switch To First Page    ${APPLICATION}
    IF  '${res}'=='${True}'
        ${res}=    Devices Table Contains Name    ${APPLICATION}    Device5    ${False}
        Log To Console    Device name Device5 is ${res}
    ELSE
        Fail    Was unable to reach the "${APPLICATION}" app.
    END

    ${res}=    Devices Table Switch To First Page    ${APPLICATION}
    IF  '${res}'=='${True}'
        ${res}=    Devices Table Get Corresponding Name    ${APPLICATION}    2cf7f1204200708d    ${False}    ${True}
        Log To Console    Device name for 2cf7f1204200708d is ${res}
    ELSE
        Fail    Was unable to reach the "${APPLICATION}" app.
    END

*** Keywords ***
Initialise And Open Application Screen
    [Documentation]    Getting to the APPLICATION screen
    [Arguments]    ${app_name}    ${app_profile}
    ${res}=    Go To Applications
    Run Keyword If    '${res}'=='${False}'    Fail    Failed to switch to applications screen
    ${res}=    Is Text    ${app_name}    1s
    Run Keyword If    '${res}'=='${False}'    Setup Application    ${app_name}    ${app_profile}
    Click Text    ${app_name}
    Verify Text    Devices

Setup Application
    [Documentation]    Creates the app.
    [Arguments]    ${app_name}    ${app_profile}
    Click Text    Create
    Verify Text    Application name
    Type Text    xpath\=//input[@id\="name"]    ${app_name}
    Type Text    xpath\=//input[@id\="description"]    ${app_name}
    Set Config    Delay    0.2s
    Click Text    Select service-profile    1
    Click Text    ${app_profile}
    Set Config    Delay    ${COMMON_DELAY}
    Click Text    Create application

#Device naming convention:
#Between apps: eui must be unique.
#Inside an app: name and eui must be unique.

Add Device
    [Documentation]    Adds a device with the specified name and eui
    ...    for the specified app. Assigns app-key to the device and returns it.
    ...    Encountering a device with the same name and eui - deletes the device.
    [Arguments]    ${app_name}    ${name}    ${eui}    ${device_profile}
    ${res}=    Is In Application Devices    ${app_name}
    IF  '${res}'=='${False}'
        ${res}=    Go To Application Devices    ${app_name}
        Run Keyword If    '${res}'=='${False}'    Fail    Was unable to switch to the app devices screen to create a device.
    END

    #Now we have to figure out if device exists.
    ${same_eui}=    Devices Table Contains Eui    ${app_name}    ${eui}    ${False}
    IF  '${same_eui}'=='${True}'
        ${corr_name}=    Devices Table Get Corresponding Name    ${app_name}    ${eui}    ${False}    ${True}
        IF  '${corr_name}'!='${name}'
            ${same_name}=    Devices Table Contains Name    ${app_name}    ${name}    ${False}
            IF  '${same_name}'=='${True}'
                #We have same eui not in the same row with the same name
                #Give a warning, do nothing.
                #${app_key}=    Update Device    ${app_name}    ${corr_name}
                ${app_key}=    Set Variable    ERROR:"'${eui}' is associated with '${corr_name}' device. Device '${name}' cannot be created."
                Devices Table Contains Eui    ${app_name}    ${eui}    ${False}
                Run Keyword And Warn On Failure    Fail    Device's '${name}' EUI (${eui}) is held by '${corr_name}' device.
            ELSE
                #Wrong name.
                #Delete the device for now, but just rename it later on.
                Delete Device    ${app_name}    ${corr_name}
                ${app_key}=    Create Device    ${name}    ${eui}    ${device_profile}
            END
            
            
        ELSE
            #Device already exists
            ${app_key}=    Update Device    ${app_name}    ${name}    ${True}
        END
        
    ELSE
        ${same_name}=    Devices Table Contains Name    ${app_name}    ${name}    ${False}
        IF  '${same_name}'=='${True}'
            #Wrong eui
            Delete Device    ${app_name}    ${name}    ${True}
            ${app_key}=    Create Device    ${name}    ${eui}    ${device_profile}
        ELSE
            #No such device
            ${app_key}=    Create Device    ${name}    ${eui}    ${device_profile}
        END
        
    END
    
    [Return]    ${app_key}    

Delete Device
    [Documentation]    Deletes device from the specified app.
    ...    Does nothing if device was not found.
    [Arguments]    ${app_name}    ${device_name}    ${on_screen}=${False}
    Run Keyword If    '${on_screen}'=='${False}'    Devices Table Switch To First Page    ${app_name}
    Run Keyword If    '${on_screen}'=='${False}'    Devices Table Contains Name    ${app_name}    ${device_name}    ${False}
    ${res}=    Go To Application Device    ${app_name}    ${device_name}
    IF  '${res}'=='${True}'
        Click Text    Delete
        Close Alert    Accept    5s
    END

Update Device
    [Documentation]    Basically, just checks/creates the device app-key.
    ...    Always returns view to the "Application Devices"
    [Arguments]    ${app_name}    ${device_name}    ${on_screen}=${False}
    Run Keyword If    '${on_screen}'=='${False}'    Devices Table Switch To First Page    ${app_name}
    Run Keyword If    '${on_screen}'=='${False}'    Devices Table Contains Name    ${app_name}    ${device_name}    ${False}
    ${res}=    Go To Application Device Keys    ${app_name}    ${device_name}
    IF  '${res}'=='${True}'
        #Checking the app key.
        Verify Text    Application key
        TRY
            ${app_key}=    Get Input Value    xpath\=//input[@id\="nwkKey"]    1    1s
        EXCEPT
            #We don't have an app key, what a shame.
            ${app_key}=    Generate App Key
        END
        Go To Application Devices    ${app_name}        
    ELSE
        Run Keyword And Warn On Failure    Fail    Was unable to update the '${device_name}' device. Does it actually exist?
        ${app_key}=    Set Variable    ERROR:"'${device_name}' unaccessible."
    END
    [Return]    ${app_key}

Create Device
    [Documentation]    Handles the device creation.
    ...    Must be called from the "Device" screen.
    ...    Returns app-key
    [Arguments]    ${name}    ${eui}    ${device_profile}
    
    Click Text    Create
    Verify Text    Device name
    Type Text    xpath\=//input[@id\="name"]    ${name}
    Type Text    xpath\=//input[@id\="description"]    ${name}
    Type Text    xpath\=//input[@id\="devEUI"]    ${eui}
    Set Config    Delay    0.2s
    Click Text    Device-profile    Disable frame-counter validation
    Click Text    ${device_profile}
    Set Config    Delay    ${COMMON_DELAY}
    Click Text    Create device
    
    #NOTE: If device (same eui) exists at least in one app - server won't allow us to create a device.
    #This is painful, since the only way to fix it would be to go through all apps and delete the device.
    #For now we will just fail.
    #Implement try-catch on "Verify Text    Application key"
    #Actually, it won't be a good solution, we really have to check if something messed up upon the creation.
    
    ${f_device_created}=    Is Text    Application key    1s
    IF  '${f_device_created}'=='${True}'
        ${app_key}=    Generate App Key
    ELSE
        Run Keyword And Warn On Failure    Fail    Was not able to create device '${name}' (${eui}).\nProbably EUI is held by the other app.   
        ${app_key}=    Set Variable    ERROR:"Was not able to create device '${name}' (${eui}).\nHint: It is possible that EUI is occupied by the device in other application."    
    END
    
    [Return]    ${app_key}

Generate App Key
    [Documentation]    Generates app key if called from the device's "Keys" view.
    Verify Text    Application key
    Click Element    xpath\=//*[@title\="Generate random key."]
    ${app_key}=    Get Input Value    xpath\=//input[@id\="nwkKey"]
    Click Text    Set device-keys
    [Return]    ${app_key}

#Should be python keyword.
#Python must set two lists:
#DEVICE_NAMES and DEVICE_EUIS
#based on the data from the file or google doc.
#Or it would be better to use Dictionary.
Read Devices From File
    #Append To List    ${DEVICE_NAMES}    Device1    Device2    Device3    Device4    Device5
    #Append To List    ${DEVICE_EUIS}    2cf7f12042007dff    2cf7f1204200708d    2cf7f120420036fe    2cf7f12042007da2    2cf7f12042007a39
    #Append To List    ${DEVICE_NAMES}    ice1    ice2    Devic3    Dice4    Devic    Dev5    ice7
    #Append To List    ${DEVICE_EUIS}    2ca7f12042007dff    2af7f1204200708d    1cf7f120420036fe    2cd7f12052007da2    2af7f12042007a90    2cf7f12042007a1a    2cf7c12842007a56
    #Append To List    ${DEVICE_NAMES}    ice12    ice32    Devc    Dice    Devic43    De    ic7    ice1    ice2    Devic3    Dice4    Devic    Dev5    ice7
    #Append To List    ${DEVICE_EUIS}    2ca7f12042007fff    2af7f1234200708d    12f7f120420036fe    2c37f12052007da2    2a57f12042007a90    2cf7312042007a1a    2cf7c12942007a56    2ca7f12042007dff    2af7f1204200708d    1cf7f120420036fe    2cd7f12052007da2    2af7f12042007a90    2cf7f12042007a1a    2cf7c12842007a56
    #Append To List    ${DEVICE_NAMES}    Device1    Device2    Device3    Device4    Device5    ice12    ice32    Devc    Dice    Devic43    De    ic7    ice1    ice2    Devic3    Dice4    Devic    Dev5    ice7    art    abba    Device200    f    DD
    #Append To List    ${DEVICE_EUIS}    2cf7f12042007dff    2cf7f1204200708d    2cf7f120420036fe    2cf7f12042007da2    2cf7f12042007a39    2ca7f12042007fff    2af7f1234200708d    12f7f120420036fe    2c37f12052007da2    2a57f12042007a90    2cf7312042007a1a    2cf7c12942007a56    2ca7f12042007dff    2af7f1204200708d    1cf7f120420036fe    2cd7f12052007da2    2af7f12042007a90    2cf7f12042007a1a    2cf7c12842007a56    2afba1204200708d    2abba1abba00708d    2cf7312ddda07a1a    ffffffffff007da2    4ef167e594428eba
    &{d}=    Create Dictionary    2cf7f12042007dff=Device1    2cf7f1204200708d=Device2    2cf7f120420036fe=Device3    2cf7f12042007da2=Device4    2cf7f12042007a39=Device5
    [Return]    &{d}

Parse Devices Dictionary
    [Arguments]    &{dict}
    FOR  ${key}  IN  @{dict}
        Append To List    ${DEVICE_EUIS}    ${key}
        Append To List    ${DEVICE_NAMES}    ${dict}[${key}]
    END

Create Dictionary From Lists
    [Arguments]    ${keys}    ${values}
    &{res_dict}=    Create Dictionary
    ${keys_len}=    Get Length    ${keys}
    ${values_len}=    Get Length    ${values}
    IF  '${keys_len}'=='${values_len}'
        FOR  ${i}  IN RANGE  ${keys_len}
            ${key}=    Get From List    ${keys}    ${i}
            ${value}=    Get From List    ${values}    ${i}
            Set To Dictionary    ${res_dict}    ${key}=${value}
        END
    END

    [Return]    &{res_dict}
