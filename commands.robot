*** Settings ***
Documentation    Controlling the server interface with Robot Framework

Resource    navigation.resource

Task Setup      Initialise
Task Teardown   Stop Browser

*** Variables ***

*** Tasks ***
#TODO
Add Devices
    Set Config    Delay    ${COMMON_DELAY}
    
    #GoogleSpreadsheetParser.py
    &{d}=    Read Devices From Spreadsheet
    #/GoogleSpreadsheetParser.py
    Parse Devices Dictionary    &{d}

    Log In    ${USERNAME}    ${PASSWORD}
    Initialise And Open Application Screen    ${APPLICATION}

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

    Log To Console    Updating the ${APPLICATION} spreadsheet.
    #GoogleSpreadsheetParser.py
    ${f_written_to_spreadsheet}=    Write To Spreadsheet    ${d}
    #/GoogleSpreadsheetParser.py
    
    IF    '${f_written_to_spreadsheet}'=='${True}'
        Log To Console    Successfully written app-keys to the Google doc.
    ELSE
        Log To Console    Failed to write app-keys to google doc.
    END

#TODO
Delete Devices
    Set Config    Delay    ${COMMON_DELAY}
    
    #GoogleSpreadsheetParser.py
    &{d}=    Read Devices From Spreadsheet
    #/GoogleSpreadsheetParser.py
    Parse Devices Dictionary    &{d}

    Log In    ${USERNAME}    ${PASSWORD}
    Initialise And Open Application Screen    ${APPLICATION}
    Go To Application Devices    ${APPLICATION}
    
    ${dev_num}=    Get Length    ${DEVICE_NAMES}
    FOR  ${i}  IN RANGE  ${dev_num}
        ${dev_name}=    Get From List    ${DEVICE_NAMES}    ${i}
        Delete Device    ${APPLICATION}    ${dev_name}
        ${res}=    Devices Table Contains Name    ${APPLICATION}    ${dev_name}    ${False}
        Run Keyword If    '${res}'=='${True}'    Fail    Was unable to delete device "${dev_name}", aborting.
    END

#TODO
Delete All Devices
    Set Config    Delay    ${COMMON_DELAY}
    Log In    ${USERNAME}    ${PASSWORD}
    Initialise And Open Application Screen    ${APPLICATION}
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
    Initialise And Open Application Screen    ${APPLICATION}
    ${res}=    Go To Application Devices    ${APPLICATION}

    IF  '${res}'=='${True}'
        Click Text    Delete application
        Type Text    xpath\=//input[@placeholder\="${APPLICATION}"]    ${APPLICATION}
        Click Text    Delete    confirm you want to delete this application
        ${is_app}=    Applications Table Contains Name    ${APPLICATION}    ${True}
        Verify No Text    ${APPLICATION}
        Run Keyword If    '${is_app}'=='${True}'    Fail    Was unable to delete the "${APPLICATION}" app.
    ELSE
        Fail    Was unable to delete the "${APPLICATION}" app.
    END

Test
    Set Config    Delay    0
    Log In    ${USERNAME}    ${PASSWORD}
    Initialise And Open Application Screen    ${APPLICATION}
    Go To Application    ${APPLICATION}

*** Keywords ***
Initialise And Open Application Screen
    [Documentation]    Getting to the APPLICATION screen
    [Arguments]    ${app_name}
    ${res}=    Go To Applications
    Run Keyword If    '${res}'=='${False}'    Fail    Failed to switch to applications screen
    ${app_is_present}=    Applications Table Contains Name    ${app_name}
    Run Keyword If    '${app_is_present}'=='${False}'    Setup Application    ${app_name}
    Run Keyword If    '${app_is_present}'=='${False}'    Applications Table Contains Name    ${app_name}
    Click Text    ${app_name}
    Verify Text    Devices

Setup Application
    [Documentation]    Creates the app.
    [Arguments]    ${app_name}
    Click Text    Add application
    Verify Text    Description
    Type Text    xpath\=//input[@id\="name"]    ${app_name}
    Type Text    xpath\=//textarea[@id\="description"]    ${app_name}
    Click Text    Submit

#Device naming convention:
#Between apps: eui must be unique.
#Inside an app: name and eui must be unique.
#TODO
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
                ${app_key}=    Rename Device    ${app_name}    ${corr_name}    ${eui}    ${name}    ${device_profile}
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

#TODO
Delete Device
    [Documentation]    Deletes device from the specified app.
    ...    Does nothing if device was not found.
    [Arguments]    ${app_name}    ${device_name}    ${on_screen}=${False}
    Run Keyword If    '${on_screen}'=='${False}'    Devices Table Contains Name    ${app_name}    ${device_name}    ${False}
    ${res}=    Go To Application Device    ${app_name}    ${device_name}
    IF  '${res}'=='${True}'
        Click Text    Delete
        Close Alert    Accept    5s
    ELSE
        Log To Console    Was unable to find device "${device_name}" in the table.
    END

#TODO
Update Device
    [Documentation]    Basically, just checks/creates the device app-key.
    ...    Always returns view to the "Application Devices"
    [Arguments]    ${app_name}    ${device_name}    ${on_screen}=${False}
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

#TODO
Rename Device
    [Documentation]    Renames the device and checks the app-key.
    ...    Always returns view to the "Application Devices"
    [Arguments]    ${app_name}    ${old_name}    ${eui}    ${new_name}    ${device_profile}    ${on_screen}=${False}
    Run Keyword If    '${on_screen}'=='${False}'    Devices Table Contains Name    ${app_name}    ${old_name}    ${False}
    ${res}=    Go To Application Device Config    ${app_name}    ${old_name}
    IF  '${res}'=='${True}'
        Type Text    xpath\=//input[@id\="name"]    ${new_name}    clear_key={CONTROL + a}
        Type Text    xpath\=//input[@id\="description"]    ${new_name}    clear_key={CONTROL + a}
        Set Config    Delay    0.5s
        Click Element    xpath\=//input[@id\="deviceProfileID"]
        Click Text    ${device_profile}
        Set Config    Delay    ${COMMON_DELAY}
        Click Text    Update device

        Devices Table Contains Name    ${app_name}    ${new_name}    ${False}
        ${app_key}=    Update Device    ${app_name}    ${new_name}    ${True}
    ELSE
        Run Keyword And Warn On Failure    Fail    Was unable to rename the '${old_name}' device. Does it actually exist?
        ${app_key}=    Set Variable    ERROR:"Device with eui: '${eui}' unaccessible."
    END
    [Return]    ${app_key}

#TODO
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
    Set Config    Delay    0.5s
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
        ${app_key}=    Set Variable    ERROR:"Was not able to create device '${name}' (${eui}). Hint: It is possible that EUI is occupied by the device in other application."    
    END
    
    [Return]    ${app_key}

#TODO
Generate App Key
    [Documentation]    Generates app key if called from the device's "Keys" view.
    Verify Text    Application key
    Click Element    xpath\=//*[@title\="Generate random key."]
    ${app_key}=    Get Input Value    xpath\=//input[@id\="nwkKey"]
    Click Text    Set device-keys
    [Return]    ${app_key}

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
