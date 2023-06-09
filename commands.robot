*** Settings ***
Documentation    Controlling the server interface with Robot Framework

Resource    navigation.resource

Task Setup      Start Browser
Task Teardown   Stop Browser

*** Variables ***

*** Tasks ***
Add Devices
    Set Config    Delay    ${COMMON_DELAY}

    Read Devices From File

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

Delete Devices
    Set Config    Delay    ${COMMON_DELAY}
    
    Read Devices From File

    Log In    ${USERNAME}    ${PASSWORD}
    Initialise And Open Application Screen    ${APPLICATION}    ${APPLICATION_PROFILE}
    Go To Application Devices    ${APPLICATION}
    
    ${dev_num}=    Get Length    ${DEVICE_NAMES}
    FOR  ${i}  IN RANGE  ${dev_num}
        ${dev_name}=    Get From List    ${DEVICE_NAMES}    ${i}
        Delete Device    ${APPLICATION}    ${dev_name}
        Verify No Text    ${dev_name}
    END

Delete All Devices
    Set Config    Delay    ${COMMON_DELAY}
    Log In    ${USERNAME}    ${PASSWORD}
    Initialise And Open Application Screen    ${APPLICATION}    ${APPLICATION_PROFILE}
    Go To Application Devices    ${APPLICATION}

    Use Table    xpath\=//table[@class\="MuiTable-root"]
    ${stop}=    Is Text    0-0 of 0
    WHILE  '${stop}'=='${False}'
        ${dev_name}=    Get Cell Text    r1c2
        Delete Device    ${APPLICATION}    ${dev_name}
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

    #2cf7f1204200708d
    IF  '${res}'=='${True}'
        ${res}=    Devices Table Contains Eui    2cf7f1204200708a
        Log To Console    Device is ${res}
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
    Set Config    Delay    0.1s
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
    #"Check for name"  MUST CHECK THE WHOLE CELL VALUE!
    #Check for eui
    #Exists.
        #Device already cannot be created.
        #Check table for corresponding name
        #If corr_name != name
            #Check for name
            #Exists
                #We are not able to update eui.
                #Delete the device.
                #Create from scratch.
            #Not Exists
                #Change name of the device.
                #Check key.
        #else
            #The same device - check key.
    #Not exists.
        #Check for name
        #Exists
            #Wrong eui. We are not able to update it.
            #Delete the device.
            #Create from scratch.
        #Not Exists
            #Just create the device.
    
#    ${same_eui}=    Is Text    ${eui}    0.2s
#    IF  '${same_eui}'=='${True}'
#        #Check corresponding name via table
#    ELSE
#        
#    END

    ${same_name}=    Is Text    ${name}    0.2s
    ${same_eui}=    Is Text    ${eui}    0.2s
    #We have the same device configured - just get the app-key.
    IF  '${same_name}'=='${True}' and '${same_eui}'=='${True}'
        ${app_key}=    Update Device    ${app_name}    ${name}
    
    #We have the same name, but wrong eui - purge existing device and set the new one.
    #Server doesn't allow to have the same name.
    ELSE IF    '${same_name}'=='${True}' and '${same_eui}'=='${False}'
        Delete Device    ${app_name}    ${name}
        ${same_name}=    Is Text    ${name}    0.2s
        ${same_eui}=    Is Text    ${eui}    0.2s
        Run Keyword If    '${same_name}'=='${True}' and '${same_eui}'=='${True}'    Fail    Device ${name} was not deleted.
        ${app_key}=    Create Device    ${name}    ${eui}    ${device_profile}
    
    #Same eui, but not the name. What a nightmare to handle.
    ELSE IF    '${same_name}'=='${False}' and '${same_eui}'=='${True}'
        Fail    I DON'T WANT TO HANDLE THE SAME EUI WITH DIFFERENT NAMES!\nWHAT A MESS!\nHOW YOU ENDED UP IN THIS SITUATION ANYWAY!?

    ELSE
        ${app_key}=    Create Device    ${name}    ${eui}    ${device_profile}
    END
    
    [Return]    ${app_key}    

#Figure it out by eui, use the table.
Delete Device
    [Documentation]    Deletes device from the specified app.
    ...    Does nothing if device was not found.
    [Arguments]    ${app_name}    ${device_name}
    ${res}=    Go To Application Device    ${app_name}    ${device_name}
    IF  '${res}'=='${True}'
        Click Text    Delete
        Close Alert    Accept    5s
    END

#Figure it out by eui, use the table.
Update Device
    [Documentation]    Basically, just checks/creates the device app-key.
    ...    Always returns view to the "Application Devices"
    [Arguments]    ${app_name}    ${device_name}
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
        Fail    Was unable to update the ${device_name} device. Does it actually exist?
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
    Set Config    Delay    0.1s
    Click Text    Device-profile    Disable frame-counter validation
    Click Text    ${device_profile}
    Set Config    Delay    ${COMMON_DELAY}
    Click Text    Create device
    
    #NOTE: If device (same eui) exists at least in one app - server won't allow us to create a device.
    #This is painful, since the only way to fix it would be to go through all apps and delete the device.
    #For now we will just fail.
    #Implement try-catch on "Verify Text    Application key"
    #Actually, it won't be a good solution, we really have to check if something messed up upon the creation.
    
    ${app_key}=    Generate App Key
    [Return]    ${app_key}

Generate App Key
    [Documentation]    Generates app key if called from the device's "Keys" view.
    Verify Text    Application key
    Click Element    xpath\=//*[@title\="Generate random key."]
    ${app_key}=    Get Input Value    xpath\=//input[@id\="nwkKey"]
    Click Text    Set device-keys
    [Return]    ${app_key}

Devices Table Contains Eui
    [Documentation]    Checks whether table contains the specified eui.
    [Arguments]    ${eui}
    ${res}=    Set Variable    ${False}
    ${table_end}=    Set Variable    ${False}
    ${arrow_index}=    Set Variable    ${1}
    
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
    
    [Return]    ${res}

Devices Table Sheet Contains Eui
    [Documentation]    Checks a sheet of Devices table for the device with specified eui
    [Arguments]    ${eui}
    ${res}=    Set Variable    ${False}
    ${res}=    Is Text    ${eui}    0.2s
    [Return]    ${res}


Devices Table Contains Name
    [Documentation]    Checks whether table contains the specified device name.
    [Arguments]    ${device_name}
    ${res}=    Set Variable    ${False}
    #Completely wrong way to do it.
    #First: table can be located on multiple pages.
    #Second: "Device1" and "Device12" both contain "Device1" as text, so it must be checked.
    ${res}=    Is Text    ${device_name}    0.2s
    [Return]    ${res}

Device Table Get Corresponding Name
    [Documentation]    Gets a device name corresponding to the specified eui.
    [Arguments]    ${eui}
    ${name}=    Set Variable    ${None}

    [Return]    ${name}

#Should be python keyword.
#Python must set two lists:
#DEVICE_NAMES and DEVICE_EUIS
#based on the data from the file or google doc.
#Or it would be better to use Dictionary.
Read Devices From File
    #Append To List    ${DEVICE_NAMES}    Device1    Device2    Device3    Device4    Device5
    #Append To List    ${DEVICE_EUIS}    2cf7f12042007dff    2cf7f1204200708d    2cf7f120420036fe    2cf7f12042007da2    2cf7f12042007a39
    Append To List    ${DEVICE_NAMES}    ice1    ice2    Device3    Dice4    Devic    Dev5    ice7
    Append To List    ${DEVICE_EUIS}    2ca7f12042007dff    2af7f1204200708d    1cf7f120420036fe    2cd7f12052007da2    2af7f12042007a90    2cf7f12042007a1a    2cf7c12842007a56

Start Browser
    Open Browser    ${LOGIN URL}    ${BROWSER}

Stop Browser
    Close Browser