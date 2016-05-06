#GetVMWareTools-CLC
PowerShell script to create a report of the VMWare tools version of every Virtual Machine in a given CenturyLink Cloud Account Alias
Note: This script will only work with Windows Machines
This script calls the CenturyLink Cloud V1 API to generate a list of servers that are in a given account alias.
It then queries each of these servers for their VMWare tools version.
You will need login credentials for each server being queried. You will be prompted if you want to use the same credentials for each server.
An output file with results will be opened automatically. It will also be stored locally at c:\users\public\clc