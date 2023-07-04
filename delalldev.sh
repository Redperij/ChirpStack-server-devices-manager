#!/bin/sh

config_file="local.config"
worksheet="Sheet1"

#Help
DisplayHelp()
{
    echo "USAGE: ./delalldev.sh [OPTION]...";
    echo "Deletes all devices from the specified app on the server. (The same name as spreadsheet.)";
    echo "Spreadsheet readability is not checked."
    echo "OPTIONS: [-h|s|w|c]";
    echo "-h    Display this message";
    echo "-s    MANDATORY. App to delete devices from.";
    echo "-w    Unused. Worksheet inside the spreadsheet to use. Defaults to \"Sheet1\"";
    echo "-c    Config file to use for other settings. Defaults to \"local.config\". Has to be located in the same folder as robot and python scripts."
}

#Main
while getopts ":hs:c:w:" flag;
do
    case $flag in
        h) DisplayHelp
           exit;;
        s) spreadsheet=${OPTARG};;
        c) config_file=${OPTARG};;
        w) worksheet=${OPTARG};;
       \?) echo "Unexpected option, use -h to display help."
           exit;;
           
    esac
done

echo "Spreadsheet: $spreadsheet";
echo "Config file: $config_file";
echo "Worksheet: $worksheet";

if [ "$spreadsheet" = "" ];
then
    echo "No spreadsheet name given. unable to proceed. Use -h to display help.";
    exit;
else
    echo "Using \"$worksheet\" from \"$spreadsheet\" table, with \"$config_file\" as a config file.";
fi

robot --task "Delete All Devices" -v APPLICATION:"$spreadsheet" -v SHEET:"$worksheet" -v CONFIG_FILENAME:"$config_file" ./commands.robot
