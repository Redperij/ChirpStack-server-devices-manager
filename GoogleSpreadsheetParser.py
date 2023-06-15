import os
import gspread

class GoogleSpreadsheetParser(object):
    '''Library for reading and parsing the google spreadsheet for Lora Wan server automation.
    '''
    ROBOT_LIBRARY_SCOPE = "SUITE"

    def __init__(self, spreadsheet_name, worksheet_name="Sheet1"):
        self._service_account = gspread.service_account()
        #self._spreadsheet = self._service_account.open(spreadsheet_name)
        self._f_opened_spreadsheet = self.open_spreadsheet(spreadsheet_name)
        self._f_opened_worksheet = self.open_worksheet(worksheet_name)

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
            res_list.append(row[key_name].strip())

        return res_list
    
    def read_devices_from_spreadsheet(self):
        if(self._f_opened_worksheet == False):
           return None

        devices = self.get_list_of("Device name")
        euis = self.get_list_of("EUI")
        resdict = dict(zip(euis, devices))
        return resdict
    
    def write_to_spreadsheet(self, devices_dict):
        if(self._f_opened_worksheet == False):
            return False
        
        app_key_cell = self._worksheet.find("App key")
        error_cell = self._worksheet.find("ERROR")

        for eui in devices_dict:
            eui_cell = self._worksheet.find(eui)
            if(devices_dict[eui].find("ERROR:") != -1):
                #trim "ERROR:" part and write message to the ERROR column.
                err, devices_dict[eui] = devices_dict[eui].split(":", 1)
                self._worksheet.update_cell(eui_cell.row, error_cell.col, devices_dict[eui])
                self._worksheet.update_cell(eui_cell.row, app_key_cell.col, "")
            else:
                #Write app key to the "App key" column.
                self._worksheet.update_cell(eui_cell.row, error_cell.col, "")
                self._worksheet.update_cell(eui_cell.row, app_key_cell.col, devices_dict[eui])

        return True

#def main():
#    sp = GoogleSpreadsheetParser("Devices1", "Main")
#    res_dictionary = sp.read_devices_from_spreadsheet()
#
#    print("Result:\n")
#    print(res_dictionary)
#
#if __name__ == "__main__":
#    main()
