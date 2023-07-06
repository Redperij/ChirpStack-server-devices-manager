#!/bin/sh

config_file="local.config"

#Help
DisplayHelp()
{
    echo "USAGE: ./adddev.sh [OPTION]...";
    echo "Adds valid devices from google spreadsheet to the devices table of LoRa server. Gives them app keys and writes them back into the spreadsheet.";
    echo "Spreadsheet must have only 1 row header, which contains \"Device name\", \"EUI\" and \"ERROR\" column headers."
    echo "OPTIONS: [-h|s|w|c]";
    echo "-h    Display this message";
    echo "-s    MANDATORY. Google spreadsheet name to extract devices from. This script will put extracted devices into the corresponding app on the server.";
    echo "-w    MANDATORY. Worksheet inside the spreadsheet to use. CONTENTS OF THE WORKSHEET WILL BE LOST!";
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

if [ "$spreadsheet" = "" ] || [ "$worksheet" = "" ];
then
    echo "No spreadsheet or worksheet name given. unable to proceed. Use -h to display help.";
    exit;
else
    echo "Using \"$worksheet\" from \"$spreadsheet\" table, with \"$config_file\" as a config file.";
fi

robot --task "Dump Application Contents" -v APPLICATION:"$spreadsheet" -v SHEET:"$worksheet" -v CONFIG_FILENAME:"$config_file" ./commands.robot
