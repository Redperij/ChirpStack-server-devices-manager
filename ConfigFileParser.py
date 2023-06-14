import os
import sys

class ConfigFileParser(object):
    '''Library for parsing the config file for Lora Wan server automation.
    '''
    ROBOT_LIBRARY_SCOPE = "SUITE"

    def __init__(self, config_file):
        self._filename = config_file

    def get_raw_key_pairs(self):
        if not os.path.exists(self._filename):
            raise FileNotFoundError(self._filename)

        ifile = open(self._filename, "r")
        raw_contents = ifile.read()
        raw_contents = raw_contents.splitlines()

        for i in range(0, len(raw_contents)):
            ind = raw_contents[i].find("#")
            if ind != -1:
                raw_contents[i] = raw_contents[i][:ind]

        raw_key_pairs = []
        for line in raw_contents:
            if line != '':
                raw_key_pairs.append(line)

        return raw_key_pairs

    def get_from_config_file(self, key_name):
        rkp = self.get_raw_key_pairs()
        entry = None
        for pair in rkp:
            if(pair.find(key_name + ":") != -1):
                entry = pair
                break
        key, value = entry.split(":", 1)
        value = value.strip()
        value = value[value.find("\"") + 1:value.rfind("\"")]
        return value
    


#inputfile = 'local.config'
#
#def get_raw_key_pairs():
#    if not os.path.exists(inputfile):
#        raise FileNotFoundError(inputfile)
#
#    ifile = open(inputfile, "r")
#    raw_contents = ifile.read()
#    raw_contents = raw_contents.splitlines()
#
#    for i in range(0, len(raw_contents)):
#        ind = raw_contents[i].find("#")
#        if ind != -1:
#            raw_contents[i] = raw_contents[i][:ind]
#
#    raw_key_pairs = []
#    for line in raw_contents:
#        if line != '':
#            raw_key_pairs.append(line)
#
#    return raw_key_pairs
#
#def get_from_config_file(key_name):
#    rkp = get_raw_key_pairs()
#    entry = None
#    for pair in rkp:
#        if(pair.find(key_name + ":") != -1):
#            entry = pair
#            break
#    key, value = entry.split(":", 1)
#    value = value.strip()
#    value = value[value.find("\"") + 1:value.rfind("\"")]
#    return value
#
#def main():
#    print("Username: ", get_from_config_file("USERNAME"))
#    print("Password: ", get_from_config_file("PASSWORD"))
#    print("Email: ", get_from_config_file("EMAIL"))
#    print("Login url: ", get_from_config_file("LOGIN_URL"))
#    print("Browser: ", get_from_config_file("BROWSER"))
#    print("App profile: ", get_from_config_file("APPLICATION_PROFILE"))
#    print("Device profile: ", get_from_config_file("DEVICE_PROFILE"))
#    print("Org id: ", get_from_config_file("ORGANIZATION_ID"))
#
#
#if __name__ == "__main__":
#    main()