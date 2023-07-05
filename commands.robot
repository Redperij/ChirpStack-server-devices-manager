*** Settings ***
Documentation    Controlling the server interface with Robot Framework

Resource    navigation.resource

Task Setup      Initialise
Task Teardown   Stop Browser

*** Variables ***

*** Tasks ***
Add Devices
    [Documentation]    Reads spreadsheet and makes sure that all devices from the received list are created
    ...    in the specified server application and that they all have app-keys, which are then written back into the spreadsheet.
    #GoogleSpreadsheetParser.py
    IF  '${GSPREAD_INIT}'=='${True}'
        &{d}=    Read Devices From Spreadsheet
    ELSE
        Fail    No key for gspread provided. Please, check if the private key file exists.
    END
    #/GoogleSpreadsheetParser.py

    Parse Devices Dictionary    &{d}

    Go To Application Devices    ${APPLICATION}
    
    ${dev_num}=    Get Length    ${DEVICE_NAMES}
    Run Keyword If    '${dev_num}'=='${0}'    Fail    Was unable to access provided spreadsheet or worksheet, or it was empty.

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

Delete Devices
    [Documentation]    Reads spreadsheet and makes sure to clear specified app devices table of all listed devices.
    ...    Deletion is eui-specific, so we don't care about names.
    #GoogleSpreadsheetParser.py
    IF  '${GSPREAD_INIT}'=='${True}'
        &{d}=    Read Devices From Spreadsheet
    ELSE
        Fail    No key for gspread provided. Please, check if the private key file exists.
    END
    #/GoogleSpreadsheetParser.py
    Parse Devices Dictionary    &{d}

    Go To Application Devices    ${APPLICATION}
    
    ${dev_num}=    Get Length    ${DEVICE_NAMES}
    Run Keyword If    '${dev_num}'=='${0}'    Fail    Was unable to access provided spreadsheet or worksheet, or it was empty.

    FOR  ${i}  IN RANGE  ${dev_num}
        ${dev_eui}=    Get From List    ${DEVICE_EUIS}    ${i}
        Delete Device    ${APPLICATION}    ${dev_eui}
        ${f_not_deleted}=    Devices Table Contains Eui    ${APPLICATION}    ${dev_eui}    ${False}
        Run Keyword If    '${f_not_deleted}'=='${True}'    Fail    Was unable to delete device "${dev_eui}", aborting.
    END

Delete All Devices
    [Documentation]    Follows very simple algorithm of deleting the first entry in the table until it is empty.
    Go To Application Devices    ${APPLICATION}

    Use Table    Name
    ${stop}=    Is Text    No Data    0.2s
    WHILE  '${stop}'=='${False}'
        ${dev_eui}=    Get Cell Text    r2/c?DevEUI    
        Delete Device    ${APPLICATION}    ${dev_eui}    ${True}
        ${stop}=    Is Text    No Data    0.5s
    END

Delete Application
    [Documentation]    Deletes the specified application from the server.
    ...    The fastest way to clean the app of all devices is to delete it. :)
    ${f_in_app_devices_to_delete_app}=    Go To Application Devices    ${APPLICATION}

    IF  '${f_in_app_devices_to_delete_app}'=='${True}'
        Click Text    Delete application
        Type Text    xpath\=//input[@placeholder\="${APPLICATION}"]    ${APPLICATION}
        Click Text    Delete    confirm you want to delete this application
        ${is_app}=    Applications Table Contains Name    ${APPLICATION}    ${True}
        Verify No Text    ${APPLICATION}
        Run Keyword If    '${is_app}'=='${True}'    Fail    Was unable to delete the "${APPLICATION}" app.
    ELSE
        Fail    Was unable to delete the "${APPLICATION}" app.
    END

*** Keywords ***
Add Device
    [Documentation]    Adds a device with the specified name and eui
    ...    for the specified app. Assigns app-key to the device and returns it.
    ...    Device naming convention: eui must be unique, but in our case we also try to keep the name unique inside the app.
    [Arguments]    ${app_name}    ${name}    ${eui}    ${device_profile}
    #Moving to devices screen.
    ${f_is_in_app_devs}=    Is In Application Devices    ${app_name}
    IF  '${f_is_in_app_devs}'=='${False}'
        ${f_is_in_app_devs}=    Go To Application Devices    ${app_name}
        Run Keyword If    '${f_is_in_app_devs}'=='${False}'    Fail    Was unable to switch to the app devices screen to create a device.
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
                ${app_key}=    Set Variable    ERROR:"'${eui}' is associated with '${corr_name}' device. Device '${name}' cannot be created."
                Devices Table Contains Eui    ${app_name}    ${eui}    ${False}
                Run Keyword And Warn On Failure    Fail    Device's '${name}' EUI (${eui}) is held by '${corr_name}' device.
            ELSE
                #Wrong name.
                ${app_key}=    Rename Device    ${app_name}    ${corr_name}    ${eui}    ${name}    ${device_profile}
            END
            
            
        ELSE
            #Device already exists
            ${app_key}=    Update Device    ${app_name}    ${eui}    ${True}
        END
    ELSE
        ${same_name}=    Devices Table Contains Name    ${app_name}    ${name}    ${False}
        IF  '${same_name}'=='${True}'
            #Wrong eui
            #Theoretically, it will clean up the whole table of the same names. (Do I really need to?)
            ${dev_eui_to_delete}=    Devices Table Get Corresponding Eui    ${app_name}    ${name}    ${False}    ${True}
            Delete Device    ${app_name}    ${dev_eui_to_delete}    ${True}
            #Yeah, it's recursion.
            ${app_key}=    Add Device    ${app_name}    ${name}    ${eui}    ${device_profile}
        ELSE
            #No such device
            ${app_key}=    Create Device    ${name}    ${eui}    ${device_profile}
        END
        
    END
    
    [Return]    ${app_key}    

Delete Device
    [Documentation]    Deletes device from the specified app.
    ...    Does nothing if device was not found.
    [Arguments]    ${app_name}    ${eui}    ${on_screen}=${False}
    Run Keyword If    '${on_screen}'=='${False}'    Devices Table Contains Eui    ${app_name}    ${eui}    ${False}
    ${name_to_delete}=    Devices Table Get Corresponding Name    ${app_name}    ${eui}    ${False}    ${True}
    ${f_is_in_app_dev}=    Go To Application Device    ${app_name}    ${eui}
    IF  '${f_is_in_app_dev}'=='${True}'
        Click Text    Delete device
        Type Text    xpath\=//input[@placeholder\="${name_to_delete}"]    ${name_to_delete}    clear_key={CONTROL + a}
        Click Text    Delete    to confirm you want to delete this
    ELSE
        Log To Console    Was unable to find device "${eui}" in the table.
    END

Update Device
    [Documentation]    Basically, just checks/creates the device app-key.
    ...    Always returns view to the "Application Devices"
    [Arguments]    ${app_name}    ${eui}    ${on_screen}=${False}
    Run Keyword If    '${on_screen}'=='${False}'    Devices Table Contains Eui    ${app_name}    ${eui}    ${False}

    ${f_is_in_app_dev_key}=    Go To Application Device Keys    ${app_name}    ${eui}
    IF  '${f_is_in_app_dev_key}'=='${True}'
        #Check the app key.
        Verify Text    Application key
        TRY
            ${app_key}=    Get Input Value    xpath\=//input[@id\="nwkKeyRender"]    1    1s
        EXCEPT
            #We don't have an app key, what a shame.
            ${app_key}=    Generate App Key
        END
        Go To Application Devices    ${app_name}        
    ELSE
        Run Keyword And Warn On Failure    Fail    Was unable to update the '${eui}' device. Does it actually exist?
        ${app_key}=    Set Variable    ERROR:"'${eui}' unaccessible."
    END
    [Return]    ${app_key}

Rename Device
    [Documentation]    Renames the device and checks the app-key.
    ...    Always returns view to the "Application Devices"
    [Arguments]    ${app_name}    ${old_name}    ${eui}    ${new_name}    ${device_profile}    ${on_screen}=${False}
    Run Keyword If    '${on_screen}'=='${False}'    Devices Table Contains Name    ${app_name}    ${old_name}    ${False}
    ${f_is_in_app_dev_conf}=    Go To Application Device Config    ${app_name}    ${eui}
    IF  '${f_is_in_app_dev_conf}'=='${True}'
        Type Text    xpath\=//input[@id\="name"]    ${new_name}    clear_key={CONTROL + a}
        Type Text    xpath\=//textarea[@id\="description"]    ${new_name}    clear_key={CONTROL + a}
        Set Config    Delay    0.5s
        Click Element    xpath\=//span[@class\="ant-select-selection-item"]    index=2
        Click Text    ${device_profile}
        Set Config    Delay    ${COMMON_DELAY}
        Click Text    Submit

        Devices Table Contains Name    ${app_name}    ${new_name}    ${False}
        ${app_key}=    Update Device    ${app_name}    ${eui}    ${True}
    ELSE
        Run Keyword And Warn On Failure    Fail    Was unable to rename the '${old_name}' device. Does it actually exist?
        ${app_key}=    Set Variable    ERROR:"Device with eui: '${eui}' unaccessible."
    END
    [Return]    ${app_key}

Create Device
    [Documentation]    Handles the device creation.
    ...    Must be called from the "Device" screen.
    ...    Returns app-key
    [Arguments]    ${name}    ${eui}    ${device_profile}
    
    Click Text    Add device
    Verify Text    Variables
    Type Text    xpath\=//input[@id\="name"]    ${name}
    Type Text    xpath\=//textarea[@id\="description"]    Added by robotframework
    Type Text    xpath\=//input[@id\="devEuiRender"]    ${eui}
    Set Config    Delay    0.5s
    Click Element    xpath\=//div[@class\="ant-select ant-select-in-form-item ant-select-single ant-select-show-arrow ant-select-show-search"]
    Click Text    ${device_profile}
    Set Config    Delay    ${COMMON_DELAY}
    Click Text    Submit
    
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

Generate App Key
    [Documentation]    Generates app key if called from the device's "Keys" view.
    Verify Text    Application key
    Click Element    xpath\=//button[@class\="ant-btn ant-btn-circle ant-btn-text ant-btn-sm"]
    ${app_key}=    Get Input Value    xpath\=//input[@id\="nwkKeyRender"]
    Click Text    Submit
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
