# ChirpStack server devices manager

This repo holds the code for automating the process of setting up a device access to the [LoRa](https://en.wikipedia.org/wiki/LoRa) gateway using the [ChirpStack web UI](https://github.com/chirpstack/chirpstack). It is still required to configure the gateway and device profile manually, but device addition and app-key lease will be done automatically, which is especially helpful with 60> devices.

## Features

  - [Robot Framework](https://robotframework.org/) controlled navigation through [ChirpStack web UI v4.*](https://github.com/chirpstack/chirpstack).
  - [QWeb](https://github.com/qentinelqi/qweb) is used for navigation through the web UI. It is very web UI specific, so only v4 of ChirpStack web UI is supported, and any small change in the UI may break things.
  - Data extraction from [Google spreadsheets](https://docs.google.com/spreadsheets) using [gspread](https://docs.gspread.org/en).
  - Shell scripts to run robot scripts without too much hastle.

## Usage

First of all you need [python3](https://www.python.org/downloads/) on your device. Then scripts will require [Robot Framework](https://robotframework.org/) installation with [QWeb](https://github.com/qentinelqi/qweb), as well as [gspread](https://docs.gspread.org/en) for python scripts.

After installing all needed dependencies you have to configure service account, which will be used by [gspread](https://docs.gspread.org/en) to access the spreadsheet. To do it, please, follow [this guide](https://github.com/Redperij/ChirpStack-server-devices-manager/blob/main/documentation/gspread_setup_guide.pdf).

Then you need to copy [local.config.example](https://github.com/Redperij/ChirpStack-server-devices-manager/blob/main/local.config.example) in the same directory and name it "local.config". Then you can change it to fit your needs. Also, if you would like to have different column names in your spreadsheet, you can change "*_column_text" variables in [GoogleSpreadsheetParser.py](https://github.com/Redperij/ChirpStack-server-devices-manager/blob/main/GoogleSpreadsheetParser.py) script.

After performing the configuration, you will be able to run one of the shell scripts ([adddev.sh](https://github.com/Redperij/ChirpStack-server-devices-manager/blob/main/adddev.sh), [deldev.sh](https://github.com/Redperij/ChirpStack-server-devices-manager/blob/main/deldev.sh), [delalldev.sh](https://github.com/Redperij/ChirpStack-server-devices-manager/blob/main/delalldev.sh), [delapp.sh](https://github.com/Redperij/ChirpStack-server-devices-manager/blob/main/delapp.sh).)

  - -h option used to view the help message.
  - -s option is **mandatory**. It specifies the spreadsheet name to use as well as the app name on the server. Automation works so that application on the server is named acccording to the spreadsheet name.
  - -w option specifies the worksheet to use, (sheets of your spreadsheet.) Defaults to "Sheet1".
  - -c option specifies the config filename. In case if you want to use different config files. Defaults to "local.config".

Scripts overview.

  - [adddev.sh](https://github.com/Redperij/ChirpStack-server-devices-manager/blob/main/adddev.sh) script reads the specified spreadsheet, checks the validity of entries, configures devices on the server and writes app keys back to the spreadsheet. Application name on the server corresponds to the spreadsheet name, if there is no such app on the server, it will create one. It will not overwrite the existing devices (same name and eui), script will only take care of their app-keys, copying the existing ones or creating new keys, if the app-key field was blank.
  - [deldev.sh](https://github.com/Redperij/ChirpStack-server-devices-manager/blob/main/deldev.sh) script reads the specified spreadsheet, checks the validity of entries and cleans the application table of the specified devices.
  - [delalldev.sh](https://github.com/Redperij/ChirpStack-server-devices-manager/blob/main/delalldev.sh) script omits spreadsheet step and cleans the application table of all devices. -s specifies only the app name in this case.
  - [delapp.sh](https://github.com/Redperij/ChirpStack-server-devices-manager/blob/main/delapp.sh) script omits spreadsheet step and deletes the application on the server. -s specifies only the app name in this case.

If you use Windows, then take a look at the last line of every script, it is exactly what you want to run, change the values given to variables (-v option) and run the command. Scripts don't handle mentioned actions on their own, it is done through the robot tasks and python scripts, so running the robot command directly has the same effect as running the shell script, which serves only as simplification of the robot command.

Here is the [example](https://docs.google.com/spreadsheets/d/1f-xilLtXDja_L4sdjM1Iouc3nTT9PIcVBg3Si9t0LZM/edit?usp=sharing) of the valid spreadsheet page. "Devices1" is used as spreadsheet name, "Main" is used as worksheet name.
So adding devices from the example spreadsheet to the corresponding app looks like this:
```sh
./adddev.sh -s "Devices1" -w "Main"
#It results in executing this robot command:
#robot --task "Add Devices" -v APPLICATION:"Devices1" -v SHEET:"Main" -v CONFIG_FILENAME:"local.config" ./commands.robot 
```
Deleting all devices from the app:
```sh
./delalldev.sh -s "Devices1"
```

## Additional information

[commands.robot](https://github.com/Redperij/ChirpStack-server-devices-manager/blob/main/commands.robot) and [navigation.resource](https://github.com/Redperij/ChirpStack-server-devices-manager/blob/main/navigation.resource) are [Robot Framework](https://robotframework.org/) files that perform most of the heavy lifting through the [Charpstack web UI](https://github.com/chirpstack/chirpstack). If you have v3.* of the [Charpstack web UI](https://github.com/chirpstack/chirpstack), then you may take a look at [this commit](https://github.com/Redperij/ChirpStack-server-devices-manager/tree/2bb351897f5198f1bd01fd6678142762da704689), at this state automation was written for the v3, and some features like device addition worked to some extend. You will have to use robot directly though. I am not planning to support v3.

If you want to use or modify the code from this repository, please, feel free to do so.
