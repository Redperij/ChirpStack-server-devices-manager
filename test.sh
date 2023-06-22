#!/bin/sh

config_file="local.config"
worksheet="Sheet1"

while getopts s:c:w: flag
do
    case "${flag}" in
        s) spreadsheet=${OPTARG};;
        c) config_file=${OPTARG};;
        w) worksheet=${OPTARG};;
    esac
done

echo "Spreadsheet: $spreadsheet";
echo "Config file: $config_file";
echo "Worksheet: $worksheet";

if [ "$spreadsheet" = "" ];
then
    echo "No spreadsheet name given. unable to proceed.";
    exit;
else
    echo "Using \"$worksheet\" from \"$spreadsheet\" table, with \"$config_file\" as a config file.";
fi
