*** Settings ***
Documentation    This resource file provides keywords
...              to navigate through the ChirpStack
...              web UI for the LoraWan server.

Library    Collections
Library    String
Library    QWeb
Library    ConfigFileParser.py    ${CONFIG_FILENAME}
Library    GoogleSpreadsheetParser.py    ${APPLICATION}    ${SHEET}    ${GSPREAD_FILENAME}

*** Variables ***

#Variables modified in the command line.
${CONFIG_FILENAME}    local.config
${APPLICATION}    Devices1
${SHEET}    Main

#Variables modified by the config file.
${GSPREAD_FILENAME}    service_account.json
${LOGIN_URL}    http://localhost:8080
${BROWSER}      Firefox
${USERNAME}     admin
${PASSWORD}     admin
${DEVICE_PROFILE}    Metropolia_devices
${TENANT_NAME}    ChirpStack
${TENANT_ID}    ${None}

#Robot Framework variables.
@{DEVICE_NAMES}
@{DEVICE_EUIS}
${COMMON_DELAY}    0
${TABLE_MAX_ROWS}    ${100}
${GSPREAD_INIT}    ${False}

*** Keywords ***
####################################
# GO TO ############################
####################################
#"Go To" keywords provide an easy way to switch to the needed view.
#Every keyword always checks whether view is already opened.

Go To Tenants
    [Documentation]    Opens "Tenants" view.
    ...    Must be logged in to use this keyword.
    [Arguments]    ${force_switch}=${False}
    ${f_is_in_tens}=    Is In Tenants
    IF    '${f_is_in_tens}'=='${False}' or '${force_switch}'=='${True}'
        Set Config    Delay    1s
        Go To    ${LOGIN_URL}/#/tenants    10s
        Set Config    Delay    ${COMMON_DELAY}
        ${f_is_in_tens}=    Is In Tenants
    END

    [Return]    ${f_is_in_tens}

Go To Applications
    [Documentation]    Opens "Applications" view.
    ...    Must be logged in to use this keyword.
    [Arguments]    ${force_switch}=${False}
    ${f_is_in_apps}=    Is In Applications
    IF    '${f_is_in_apps}'=='${False}' or '${force_switch}'=='${True}'
        Go To    ${LOGIN_URL}/#/tenants/${TENANT_ID}/applications    10s
        ${f_is_in_apps}=    Is In Applications
    END

    [Return]    ${f_is_in_apps}

Go To Application
    [Documentation]    Opens certain application view.
    [Arguments]    ${app_name}    ${force_switch}=${False}
    ${f_is_in_app}=    Is In Application    ${app_name}
    IF    '${f_is_in_app}'=='${False}' or '${force_switch}'=='${True}'
        ${f_is_in_apps}=    Go To Applications
        IF  '${f_is_in_apps}'=='${True}'
            ${f_app_is_present}=    Applications Table Contains Name    ${app_name}                
            Run Keyword If    '${f_app_is_present}'=='${True}'    Click Text    ${app_name}
        END
        ${f_is_in_app}=    Is In Application    ${app_name}
    END
    [Return]    ${f_is_in_app}

Go To Application Devices
    [Documentation]    Opens certain application's "Devices" view.
    [Arguments]    ${app_name}    ${force_switch}=${False}
    ${f_is_in_app_devs}=    Is In Application Devices    ${app_name}
    IF    '${f_is_in_app_devs}'=='${False}' or '${force_switch}'=='${True}'
        ${f_is_in_app}=    Go To Application    ${app_name}
        Run Keyword If    '${f_is_in_app}'=='${True}'    Click Text    Devices    Multicast groups
        ${f_is_in_app_devs}=    Is In Application Devices    ${app_name}
    END
    [Return]    ${f_is_in_app_devs}

Go To Application Device
    [Documentation]    Opens certain application's certain device view.
    [Arguments]    ${app_name}    ${eui}    ${force_switch}=${False}
    ${f_is_in_app_dev}=    Is In Application Device    ${app_name}    ${eui}
    IF    '${f_is_in_app_dev}'=='${False}' or '${force_switch}'=='${True}'
        ${f_is_in_app_devs}=    Go To Application Devices    ${app_name}
        ${f_found_eui}=    Is Text    ${eui}
        Run Keyword If    '${f_found_eui}'=='${True}'    Click Text    ${eui}    Name
        ${f_is_in_app_dev}=    Is In Application Device    ${app_name}    ${eui}
    END
    [Return]    ${f_is_in_app_dev}

Go To Application Device Config
    [Documentation]    Opens specified device's configuration view.
    [Arguments]    ${app_name}    ${eui}    ${force_switch}=${False}
    ${f_is_in_app_dev_conf}=    Is In Application Device Config    ${app_name}    ${eui}
    IF    '${f_is_in_app_dev_conf}'=='${False}' or '${force_switch}'=='${True}'
        ${f_is_in_app_dev}=    Go To Application Device    ${app_name}    ${eui}
        Run Keyword If    '${f_is_in_app_dev}'=='${True}'    Click Text    Configuration    OTAA keys
        ${f_is_in_app_dev_conf}=    Is In Application Device Config    ${app_name}    ${eui}
    END
    [Return]    ${f_is_in_app_dev_conf}

Go To Application Device Keys
    [Documentation]    Opens specified device's app-keys view.
    [Arguments]    ${app_name}    ${eui}    ${force_switch}=${False}
    ${f_is_in_app_dev_key}=    Is In Application Device Keys    ${app_name}    ${eui}
    IF    '${f_is_in_app_dev_key}'=='${False}' or '${force_switch}'=='${True}'
        ${f_is_in_app_dev}=    Go To Application Device    ${app_name}    ${eui}
        Run Keyword If    '${f_is_in_app_dev}'=='${True}'    Click Text    OTAA keys    Configuration
        ${f_is_in_app_dev_key}=    Is In Application Device Keys    ${app_name}    ${eui}
    END
    [Return]    ${f_is_in_app_dev_key}

####################################
# IS IN ############################
####################################
#"Is In" keywords are used to identify the screen we are currently viewing.

Is In Tenants
    [Documentation]    Identifies, whether we are
    ...    in the "Tenants" view.
    ${has_tens_table}=    Is Element    xpath\=//table[@style\="table-layout: auto;"]    1s
    ${has_add_ten_but}=    Is Text    Add tenant
    ${is_in_tens}=    Set Variable If    '${has_tens_table}'=='${True}' and '${has_add_ten_but}'=='${True}'    ${True}    ${False}
    [Return]    ${is_in_tens}

Is In Applications
    [Documentation]    Identifies, whether we are
    ...    in the "Applications" view.
    ${has_apps_table}=    Is Element    xpath\=//table[@style\="table-layout: auto;"]    1s
    ${has_add_app_but}=    Is Text    Add application
    #What an utter crap. (is_in_apps = has_apps_table && res2)
    ${is_in_apps}=    Set Variable If    '${has_apps_table}'=='${True}' and '${has_add_app_but}'=='${True}'    ${True}    ${False}
    [Return]    ${is_in_apps}

Is In Application
    [Documentation]    Identifies, whether we are
    ...    in the certain "Application" view.
    [Arguments]    ${app_name}
    ${has_app_name}=    Is Text    ${app_name}    1s
    ${has_app_conf_but}=    Is Text    Application configuration    1s
    ${is_in_app}=    Set Variable If    '${has_app_name}'=='${True}' and '${has_app_conf_but}'=='${True}'    ${True}    ${False}
    [Return]    ${is_in_app}

Is In Application Devices
    [Documentation]    Identifies, whether we are
    ...    in the application "Devices" view.
    [Arguments]    ${app_name}
    ${has_app_name}=    Is In Application    ${app_name}
    ${has_last_seen_col}=    Is Text    Last seen    1s
    ${is_in_app_devs}=    Set Variable If    '${has_app_name}'=='${True}' and '${has_last_seen_col}'=='${True}'    ${True}    ${False}
    [Return]    ${is_in_app_devs}


Is In Application Device
    [Documentation]    Identifies, whether we are
    ...    in the application certain "Device" view.
    [Arguments]    ${app_name}    ${eui}
    ${has_app_name}=    Is Text    ${app_name}    1s
    ${has_eui}=    Is Text    ${eui}    1s
    ${has_keys_but}=    Is Text    OTAA keys    1s
    ${is_in_app_dev}=    Set Variable If    '${has_app_name}'=='${True}' and '${has_eui}'=='${True}' and '${has_keys_but}'=='${True}'    ${True}    ${False}
    [Return]    ${is_in_app_dev}

Is In Application Device Config
    [Documentation]    Identifies, whether we are
    ...    in the application certain device's "Configuration" view.
    [Arguments]    ${app_name}    ${eui}
    ${has_app_name}=    Is Text    ${app_name}    1s
    ${has_eui}=    Is Text    ${eui}    1s
    ${has_var_but}=    Is Text    Variables    1s
    ${is_in_app_dev_conf}=    Set Variable If    '${has_app_name}'=='${True}' and '${has_eui}'=='${True}' and '${has_var_but}'=='${True}'    ${True}    ${False}
    [Return]    ${is_in_app_dev_conf}

Is In Application Device Keys
    [Documentation]    Identifies, whether we are
    ...    in the application certain device's "Keys" view.
    [Arguments]    ${app_name}    ${eui}
    ${has_app_name}=    Is Text    ${app_name}    1s
    ${has_eui}=    Is Text    ${eui}    1s
    ${has_app_key_text}=    Is Text    Application key    1s
    ${is_in_app_dev_key}=    Set Variable If    '${has_app_name}'=='${True}' and '${has_eui}'=='${True}' and '${has_app_key_text}'=='${True}'    ${True}    ${False}
    [Return]    ${is_in_app_dev_key}

####################################
# DEVICES TABLE ####################
####################################
#"Devices Table" keywords provide more convinient navigation
# through the table of devices inside the application
Devices Table Contains Eui
    [Documentation]    Checks whether table contains the specified eui.
    [Arguments]    ${app_name}    ${eui}    ${return}=${True}
    ${f_found_eui}=    Set Variable    ${False}
    ${table_end}=    Set Variable    ${False}

    Go To Application Devices    ${app_name}    ${True}
    ${empty_table}=    Is Text    No Data    0.5s

    WHILE  '${table_end}'=='${False}' and '${empty_table}'!= '${True}'
        ${f_found_eui}=    Devices Table Sheet Contains Eui    ${eui}
        #Go forward inside the table.
        IF  '${f_found_eui}'=='${False}'
            ${table_end}=    Table Next
            ${table_end}=    Evaluate    not ${table_end}
        ELSE
            ${table_end}=    Set Variable    ${True}
        END
    END
    
    Run Keyword If    '${return}'=='${True}'    Go To Application Devices    ${app_name}    ${True}
    [Return]    ${f_found_eui}

Devices Table Sheet Contains Eui
    [Documentation]    Checks a sheet of Devices table for the device with specified eui.
    [Arguments]    ${eui}
    ${eui_on_sheet}=    Set Variable    ${False}
    ${eui_on_sheet}=    Is Text    ${eui}    0.2s
    [Return]    ${eui_on_sheet}

Devices Table Contains Name
    [Documentation]    Checks whether table contains the specified device name.
    [Arguments]    ${app_name}    ${device_name}    ${return}=${True}
    ${f_found_name}=    Set Variable    ${False}
    ${table_end}=    Set Variable    ${False}

    Go To Application Devices    ${app_name}    ${True}
    ${empty_table}=    Is Text    No Data    0.5s
    
    WHILE  '${table_end}'=='${False}'
        ${f_found_name}=    Devices Table Sheet Contains Name    ${device_name}
        #Go forward inside the table.
        IF  '${f_found_name}'=='${False}' and '${empty_table}'!= '${True}'
            ${table_end}=    Table Next
            ${table_end}=    Evaluate    not ${table_end}
        ELSE
            ${table_end}=    Set Variable    ${True}
        END
    END
    Run Keyword If    '${return}'=='${True}'    Go To Application Devices    ${app_name}    ${True}
    [Return]    ${f_found_name}

Devices Table Sheet Contains Name
    [Documentation]    Checks a sheet of Devices table for the device with specified name.
    [Arguments]    ${name}
    ${name_on_sheet}=    Set Variable    ${False}

    Use Table    Name
    FOR  ${i}  IN RANGE  ${TABLE_MAX_ROWS}
        TRY
            ${candidate}=    Get Cell Text    r?${name}/c?Name    ${i}    0.2s
            IF  '${candidate}'=='${name}'
                ${name_on_sheet}=    Set Variable    ${True}
                BREAK
            END
        EXCEPT
            BREAK
        END
    END
    
    [Return]    ${name_on_sheet}

Devices Table Sheet Get Name Row
    [Documentation]    Checks a sheet of Devices table for the device with specified name and gives its row.
    ...    If not found, gives 0.
    [Arguments]    ${name}
    ${name_row}=    Set Variable    ${0}

    Use Table    Name
    FOR  ${i}  IN RANGE  ${TABLE_MAX_ROWS}
        TRY
            ${candidate}=    Get Cell Text    r?${name}/c?Name    ${i}    0.2s
            ${candidate_eui}=    Get Cell Text    r?${name}/c?DevEUI    ${i}    0.2s
            ${candidate_row}=    Get Table Row    ${candidate}    ${candidate_eui}    0.2s
            IF  '${candidate}'=='${name}'
                ${name_row}=    Set Variable    ${candidate_row}
                BREAK
            END
        EXCEPT
            BREAK
        END
    END
    
    [Return]    ${name_row}

Devices Table Get Corresponding Name
    [Documentation]    Gets a device name corresponding to the specified eui.
    [Arguments]    ${app_name}    ${eui}    ${return}=${True}    ${same_sheet}=${False}
    ${name}=    Set Variable    ${None}
    ${f_found_eui}=    Set Variable    ${False}
    ${table_end}=    Set Variable    ${False}

    Run Keyword If    '${same_sheet}'=='${False}'    Go To Application Devices    ${app_name}    ${True}
    Use Table    Name
    ${empty_table}=    Is Text    No Data    0.5s
    
    WHILE  '${table_end}'=='${False}'
        ${f_found_eui}=    Devices Table Sheet Contains Eui    ${eui}
        #Go forward inside the table.
        IF  '${f_found_eui}'=='${False}' and '${empty_table}'!= '${True}'
            ${table_end}=    Table Next
            ${table_end}=    Evaluate    not ${table_end}
        ELSE
            #Log To Console    Getting corr name for: ${eui}\n
            ${name}=    Get Cell Text    r?${eui}/c?Name    1    0.2s
            ${table_end}=    Set Variable    ${True}
        END
    END
    Run Keyword If    '${return}'=='${True}'    Go To Application Devices    ${app_name}    ${True}
    [Return]    ${name}

Devices Table Get Corresponding Eui
    [Documentation]    Gets device eui corresponding to the first occurance of a specified name.
    [Arguments]    ${app_name}    ${dev_name}    ${return}=${True}    ${same_sheet}=${False}
    ${eui}=    Set Variable    ${None}
    ${table_end}=    Set Variable    ${False}

    Run Keyword If    '${same_sheet}'=='${False}'    Go To Application Devices    ${app_name}    ${True}
    Use Table    Name
    ${empty_table}=    Is Text    No Data    0.5s
    
    WHILE  '${table_end}'=='${False}'
        ${row_with_name}=    Devices Table Sheet Get Name Row    ${dev_name}
        #Go forward inside the table.
        IF  '${row_with_name}'=='${0}' and '${empty_table}'!= '${True}'
            ${table_end}=    Table Next
            ${table_end}=    Evaluate    not ${table_end}
        ELSE
            #Log To Console    Getting corr eui for: ${dev_name}\n
            ${eui}=    Get Cell Text    r${row_with_name}/c?DevEUI    1    0.2s
            ${table_end}=    Set Variable    ${True}
        END
    END
    Run Keyword If    '${return}'=='${True}'    Go To Application Devices    ${app_name}    ${True}
    [Return]    ${eui}

####################################
# APPLICATIONS TABLE ###############
####################################
#"Applications Table" keywords provide more convinient
# navigation through the table of applications.

Applications Table Contains Name
    [Documentation]    Checks whether table contains the specified application name.
    [Arguments]    ${app_name}    ${return}=${False}
    ${f_found_app_name}=    Set Variable    ${False}
    ${table_end}=    Set Variable    ${False}
    ${arrow_index}=    Set Variable    ${2}

    Go To Applications
    ${empty_table}=    Is Text    No Data    0.5s
    
    WHILE  '${table_end}'=='${False}'
        ${f_found_app_name}=    Applications Table Sheet Contains Name    ${app_name}
        #Go forward inside the table.
        IF  '${f_found_app_name}'=='${False}' and '${empty_table}'!= '${True}'
            ${table_end}=    Table Next
            ${table_end}=    Evaluate    not ${table_end}
        ELSE
            ${table_end}=    Set Variable    ${True}
        END
    END
    Run Keyword If    '${return}'=='${True}'    Go To Applications    ${True}
    [Return]    ${f_found_app_name}

Applications Table Sheet Contains Name
    [Documentation]    Checks a sheet of Applications table for the application with specified name.
    [Arguments]    ${app_name}
    ${app_name_on_sheet}=    Set Variable    ${False}

    Use Table    Name
    FOR  ${i}  IN RANGE  ${TABLE_MAX_ROWS}
        TRY
            ${candidate}=    Get Cell Text    r?${app_name}/c1    ${i}    0.2s
            IF  '${candidate}'=='${app_name}'
                ${app_name_on_sheet}=    Set Variable    ${True}
                BREAK
            END
        EXCEPT
            BREAK
        END
    END
    
    [Return]    ${app_name_on_sheet}

####################################
# TENANTS TABLE ####################
####################################
#"Tenants Table" keywords provide more convinient
# navigation through the table of tenants.

Tenants Table Contains Name
    [Documentation]    Checks whether table contains the specified tenant name.
    [Arguments]    ${ten_name}    ${return}=${False}
    ${f_found_ten_name}=    Set Variable    ${False}
    ${table_end}=    Set Variable    ${False}
    ${arrow_index}=    Set Variable    ${2}

    Go To Tenants
    ${empty_table}=    Is Text    No Data    0.5s
    
    WHILE  '${table_end}'=='${False}'
        ${f_found_ten_name}=    Tenants Table Sheet Contains Name    ${ten_name}
        #Go forward inside the table.
        IF  '${f_found_ten_name}'=='${False}' and '${empty_table}'!= '${True}'
            ${table_end}=    Table Next
            ${table_end}=    Evaluate    not ${table_end}
        ELSE
            ${table_end}=    Set Variable    ${True}
        END
    END
    Run Keyword If    '${return}'=='${True}'    Go To Tenants    ${True}
    [Return]    ${f_found_ten_name}

Tenants Table Sheet Contains Name
    [Documentation]    Checks a sheet of Tenants table for the tenant with specified name.
    [Arguments]    ${ten_name}
    ${ten_name_on_sheet}=    Set Variable    ${False}

    Use Table    Name
    FOR  ${i}  IN RANGE  ${TABLE_MAX_ROWS}
        TRY
            ${candidate_ten}=    Get Cell Text    r?${ten_name}/c1    ${i}    0.2s
            IF  '${candidate_ten}'=='${ten_name}'
                ${ten_name_on_sheet}=    Set Variable    ${True}
                BREAK
            END
        EXCEPT
            BREAK
        END
    END
    
    [Return]    ${ten_name_on_sheet}

####################################
# MISCELLANEOUS ####################
####################################
Table Next
    [Documentation]    Presses "next page" button
    ...    of the table, if possible.
    ${switch_successful}=    Set Variable    ${False}
    Set Config    Delay    0.5s
    ${disabled_next}=    Get Element Count    xpath\=//li[@class\="ant-pagination-next ant-pagination-disabled"]    0.5s
    IF    '${disabled_next}'!='${1}'
        Click Element    xpath\=//button[@class\="ant-pagination-item-link"]    0.5s    False    2
        ${switch_successful}=    Set Variable    ${True}
    END
    Set Config    Delay    ${COMMON_DELAY}
    [Return]    ${switch_successful}

Setup Application
    [Documentation]    Creates the app.
    [Arguments]    ${app_name}
    Click Text    Add application
    Verify Text    Description
    Type Text    xpath\=//input[@id\="name"]    ${app_name}
    Type Text    xpath\=//textarea[@id\="description"]    ${app_name}
    Click Text    Submit

Initialise And Open Application Screen
    [Documentation]    Getting to the APPLICATION screen
    [Arguments]    ${app_name}
    ${f_is_in_apps}=    Go To Applications
    Run Keyword If    '${f_is_in_apps}'=='${False}'    Fail    Failed to switch to applications screen
    ${app_is_present}=    Applications Table Contains Name    ${app_name}
    Run Keyword If    '${app_is_present}'=='${False}'    Setup Application    ${app_name}
    Run Keyword If    '${app_is_present}'=='${False}'    Applications Table Contains Name    ${app_name}
    Click Text    ${app_name}
    Verify Text    Devices

Log In
    [Documentation]    Tries to pass "Login" screen
    [Arguments]    ${username}    ${password}
    Verify Text    ChirpStack login
    Type Text    xpath\=//input[@id\="email"]    ${username}
    Type Text    xpath\=//input[@id\="password"]    ${password}
    Click Text    Submit

Get Tenant Id
    [Documentation]    This Keyword tries to get
    ...    specified tenant id from the web UI.
    [Arguments]    ${tenant_name}
    Go To Tenants

    Tenants Table Contains Name    ${TENANT_NAME}
    Click Text    ${TENANT_NAME}    Name
    ${tenant_id_string}=    Get Text    xpath\=//span[@class\="ant-page-header-heading-sub-title"]
    ${tenant_id}=    Fetch From Right    ${tenant_id_string}    ${SPACE}
    Set Global Variable    ${TENANT_ID}    ${tenant_id}


Initialise
    [Documentation]    Does preparation for running the suite.
    ...    Reads config file, logs into the web ui and
    ...    initialises the app, if needed.
    #ConfigFileParser.py
    ${login_url}=    Get From Config File    LOGIN_URL
    Set Global Variable    ${LOGIN_URL}    ${login_url}
    ${gspread_filename}=    Get From Config File    GSPREAD_FILENAME
    Set Global Variable    ${GSPREAD_FILENAME}    ${gspread_filename}
    ${browser}=    Get From Config File    BROWSER
    Set Global Variable    ${BROWSER}    ${browser}
    ${username}=    Get From Config File    USERNAME
    Set Global Variable    ${USERNAME}    ${username}
    ${password}=    Get From Config File    PASSWORD
    Set Global Variable    ${PASSWORD}    ${password}
    ${device_profile}=    Get From Config File    DEVICE_PROFILE
    Set Global Variable    ${DEVICE_PROFILE}    ${device_profile}
    ${tenant_name}=    Get From Config File    TENANT_NAME
    Set Global Variable    ${TENANT_NAME}    ${tenant_name}
    #/ConfigFileParser.py
    Log To Console    \nConfig: ${LOGIN_URL} ${GSPREAD_FILENAME} ${APPLICATION} ${SHEET} ${BROWSER} ${USERNAME} ${PASSWORD} ${DEVICE_PROFILE} ${TENANT_NAME}\n
    ${gspread_init}=    Initialise Google Spreadsheet Parser    ${APPLICATION}    ${SHEET}    ${GSPREAD_FILENAME}
    Set Global Variable    ${GSPREAD_INIT}    ${gspread_init}
    Open Browser    ${LOGIN_URL}    ${BROWSER}

    Set Config    Delay    ${COMMON_DELAY}
    Log In    ${USERNAME}    ${PASSWORD}
    Get Tenant Id    ${TENANT_NAME}
    Initialise And Open Application Screen    ${APPLICATION}
