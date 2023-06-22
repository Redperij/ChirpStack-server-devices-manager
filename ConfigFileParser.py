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
            ind = 0
            found = False

            while ind != -1 and found == False:
                ind = raw_contents[i].find("#", ind + 1)
                if ind == 0:
                    raw_contents[i] = raw_contents[i][:ind]
                    found = True
                else:
                    if ind != -1 and raw_contents[i][ind - 1] != '\\':
                        raw_contents[i] = raw_contents[i][:ind]
                        found = True
                    else:
                        if ind != -1 and raw_contents[i][ind - 1] == '\\':
                            raw_contents[i] = raw_contents[i].replace("\\#", "#", 1)

        raw_key_pairs = []
        for line in raw_contents:
            if line != '':
                raw_key_pairs.append(line)

        return raw_key_pairs

    def get_from_config_file(self, key_name):
        rkp = self.get_raw_key_pairs()
        entry = None
        value = None
        for pair in rkp:
            if(pair.find(key_name + ":") != -1):
                entry = pair
                break
        if entry != None:
            key, value = entry.split(":", 1)
            value = value.strip()
            value = value[value.find("\"") + 1:value.rfind("\"")]
        return value

#def main():
#    cfp = ConfigFileParser('local.config')
#
#    print("Username: ", cfp.get_from_config_file("USERNAME"))
#    print("Password: ", cfp.get_from_config_file("PASSWORD"))
#    print("Email: ", cfp.get_from_config_file("EMAIL"))
#    print("Login url: ", cfp.get_from_config_file("LOGIN_URL"))
#    print("Browser: ", cfp.get_from_config_file("BROWSER"))
#    print("Device profile: ", cfp.get_from_config_file("DEVICE_PROFILE"))
#    print("Tenant name: ", cfp.get_from_config_file("TENANT_NAME"))
#
#
#if __name__ == "__main__":
#    main()