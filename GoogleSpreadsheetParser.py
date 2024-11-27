import os
import time
import gspread
import regex as re

class GoogleSpreadsheetParser(object):
    '''Library for reading and parsing the google spreadsheet for Lora Wan server automation.
    '''
    ROBOT_LIBRARY_SCOPE = "SUITE"

    def __init__(self, spreadsheet_name, worksheet_name="Sheet1", gspread_filename="service_account.json"):
        self.error_column_text = "ERROR"
        self.name_column_text = "Device name"
        self.key_column_text = "App key"
        self.eui_column_text = "EUI"
        self._f_opened_spreadsheet = False
        self._f_opened_worksheet = False
        self._f_req_init = True
        self.initialise_google_spreadsheet_parser(spreadsheet_name, worksheet_name, gspread_filename)
    
    def initialise_google_spreadsheet_parser(self, spreadsheet_name, worksheet_name="Sheet1", gspread_filename="service_account.json"):
        try:
            service_acc_path = gspread.auth.get_config_dir() / gspread_filename
            self._service_account = gspread.service_account(service_acc_path)
            self._f_req_init = False
        except:
            self._f_req_init = True
            return False
 
        if(self._f_req_init == False):
            self._f_opened_spreadsheet = self.open_spreadsheet(spreadsheet_name)
            self._f_opened_worksheet = self.open_worksheet(worksheet_name)
        
        return True

    def open_spreadsheet(self, spreadsheet_name):
        try:
            self._spreadsheet = self._service_account.open(spreadsheet_name)
            self._f_opened_spreadsheet = True
            return True
        except:
            self._f_opened_spreadsheet = False
            return False
        

    def open_worksheet(self, worksheet_name):
        if(self._f_opened_spreadsheet == False):
            return False
        try:
            self._worksheet = self._spreadsheet.worksheet(worksheet_name)
            self._f_opened_worksheet = True
            return True
        except (gspread.exceptions.WorksheetNotFound):
            self._f_opened_worksheet = False
            return False
        
    def get_list_of(self, key_name):
        if(self._f_opened_worksheet == False):
           return None

        raw_key_contents = self._worksheet.get_all_records()
        res_list = []
        for row in raw_key_contents:
            res_list.append(str(row[key_name]).strip())

        return res_list
    
    def write_duplicate_error(self, key_name, orig_ind, dup_ind):
        error_cell = self._worksheet.find(self.error_column_text)
        self._worksheet.update_cell(dup_ind + 2, error_cell.col, "\"Device is a duplicate of device in a row %d. Same %s.\"" % (orig_ind + 2, key_name))
    
    def write_wrong_eui_error(self, ind, eui):
        error_cell = self._worksheet.find(self.error_column_text)
        self._worksheet.update_cell(ind + 2, error_cell.col, "\"Device has corrupted eui (%s). Has to consist of 16 characters from \"0123456789abcdef\".\"" % (eui))

    def write_wrong_name_error(self, ind, name):
        error_cell = self._worksheet.find(self.error_column_text)
        self._worksheet.update_cell(ind + 2, error_cell.col, "\"Device has corrupted name (%s). Only alphanumeric characters are allowed.\"" % name)

    def write_empty_error(self, ind, key):
        error_cell = self._worksheet.find(self.error_column_text)
        self._worksheet.update_cell(ind + 2, error_cell.col, "\"Device has empty %s.\"" % key)

    def verify_eui(self, eui):
        return_val = True
        for char in eui:
            if("0123456789abcdef".find(char) == -1):
                return_val = False
        if (len(eui) != 16):
            return_val = False

        return return_val

    def verify_and_delete_duplicates(self, devices, euis):
        #I guess this can exceed quota, since 60> errors certainly is something unexpected.
        #0. Clear indexes with empty fields.
        for i in range(0, len(euis)):
            if(euis[i] == ""):
                self.write_empty_error(i, "eui")
                euis[i] = ""
                devices[i] = ""
            else:
                if(devices[i] == ""):
                    self.write_empty_error(i, "device name")
                    euis[i] = ""
                    devices[i] = ""

        #1. Clear indexes with incorrect euis and non-alphanumeric names
        for i in range(0, len(euis)):
            euis[i] = euis[i].lower()
            if((euis[i] != "") and (self.verify_eui(euis[i]) == False)):
                self.write_wrong_eui_error(i, euis[i])
                euis[i] = ""
                devices[i] = ""
            if((devices[i] != "") and (devices[i].isalnum() == False)):
                self.write_wrong_name_error(i, devices[i])
                euis[i] = ""
                devices[i] = ""
        
        #2. Clear indexes with duplicate euis.
        for i in range(0, len(euis) - 1):
            for q in range(i + 1, len(euis)):
                if((euis[i] != "") and (euis[i] == euis[q])):
                    self.write_duplicate_error(self.eui_column_text, i, q)
                    euis[q] = ""
                    devices[q] = ""

        #3. Clear indexes with duplicate names.
        for i in range(0, len(devices) - 1):
            for q in range(i + 1, len(devices)):
                if((devices[i] != "") and (devices[i] == devices[q])):
                    self.write_duplicate_error(self.name_column_text, i, q)
                    euis[q] = ""
                    devices[q] = ""
        
        #Remove all empty entries.
        while(euis.count("") != 0):
            euis.remove("")

        while(devices.count("") != 0):
            devices.remove("")

    def read_devices_from_spreadsheet(self):
        if(self._f_opened_worksheet == False):
           print("Unable to read spreadsheet")
           return None

        devices = self.get_list_of(self.name_column_text)
        euis = self.get_list_of(self.eui_column_text)
        self.verify_and_delete_duplicates(devices, euis)
        resdict = dict(zip(euis, devices))
        return resdict
    
    def write_to_spreadsheet(self, devices_dict):
        if(self._f_opened_worksheet == False):
            return False
        quota_crap = 0
        
        app_key_cell = self._worksheet.find(self.key_column_text)
        error_cell = self._worksheet.find(self.error_column_text)

        for eui in devices_dict:
            #I hate it, but you have to pay not to wait this minute. (per user max is 60 requests/minute)
            #Even funnier, there is overall write requests quota of 300 per minute.
            if quota_crap >= 60:
                time.sleep(60)
                quota_crap = 0
            
            # Find column by EUI. Looks for a string match inside of the column value
            # to be delimited by empty strings or whitespaces.
            eui_cell = self._worksheet.find(re.compile(rf"(\b|\s){eui}(\b|\s)", re.IGNORECASE), case_sensitive=False)
            if(devices_dict[eui].find("ERROR:") != -1):
                #trim "ERROR:" part and write message to the error column.
                err, devices_dict[eui] = devices_dict[eui].split(":", 1)
                self._worksheet.update_cell(eui_cell.row, error_cell.col, devices_dict[eui])
                self._worksheet.update_cell(eui_cell.row, app_key_cell.col, "")
            else:
                #Write app key to the app key column.
                self._worksheet.update_cell(eui_cell.row, error_cell.col, "")
                self._worksheet.update_cell(eui_cell.row, app_key_cell.col, devices_dict[eui])
            quota_crap += 2

        return True

    def dump_to_spreadsheet(self, list_of_lists):
        if(self._f_opened_worksheet == False):
            return False
        quota_crap = 0

        #eui_col = 1
        #name_col = 0
        #key_col = 2
        #euis_l = list_of_lists[0]
        #names_l = list_of_lists[1]
        #keys_l = list_of_lists[2]

        contents_col = [2, 1, 3]

        self._worksheet.clear()
        self._worksheet.update_cell(1, contents_col[0], self.eui_column_text)
        self._worksheet.update_cell(1, contents_col[1], self.name_column_text)
        self._worksheet.update_cell(1, contents_col[2], self.key_column_text)

        for i in range(3):
            q = 2
            for item in list_of_lists[i]:
                #I hate it, but you have to pay not to wait this minute. (per user max is 60 requests)
                #Even funnier, there is overall write requests quota of 300 per minute.
                if quota_crap >= 60:
                    time.sleep(60)
                    quota_crap = 0
                
                self._worksheet.update_cell(q, contents_col[i], item)
                quota_crap += 1
                q += 1
    
        return True

#def main():
#    sp = GoogleSpreadsheetParser("Devices1", "Main", "service_account.json")
#    res_dictionary = sp.read_devices_from_spreadsheet()
#
#    print("Result:\n")
#    print(res_dictionary)
#
#if __name__ == "__main__":
#    main()
