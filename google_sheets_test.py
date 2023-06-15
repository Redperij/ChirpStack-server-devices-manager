import gspread

#sa = gspread.service_account(filename="service_account.json") #Should provide path to "key" file.
sa = gspread.service_account() #File is in ~/.config/gspread dir.
sh = sa.open("Devices1")

wsh = sh.worksheet("Main")

print("Rows: ", wsh.row_count)
print("Columns: ", wsh.col_count)

print(wsh.acell('B7').value)

print(wsh.cell(1, 2).value)

print(wsh.get('A1:B3'))

print(wsh.get_all_records())

#print(wsh.get_all_values())

#wsh.update('C2', 'Some app key')

#wsh.update('C3:C4', [['Hey'], ['There']])

#wsh.update('D3', '=A2', raw=False)

#wsh.delete_rows(1)
