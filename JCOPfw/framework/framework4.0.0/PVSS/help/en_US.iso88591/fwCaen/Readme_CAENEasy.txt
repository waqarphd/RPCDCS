Instructions for the CAEN Easy System in the JCOP Framework
===========================================================

The following steps have to be followed (available only
in Windows systems):

1. Add the bin directory of your project directory to
the Operating System path environment variable. Afterwards
you will need to completely restart PVSS (the project, the 
console and the project administrator) 

2. In the Device Editor and Navigator, create an SY1527
crate in the usual way.

3. Then add an Easy branch controller (the device type is
CAEN SY1527 Board A1676)

4. Then in the editor panel of the branch controller,
click on the 'Advanced options' button. This will open
the 'CAEN Easy Branch Controller A1676 Import' panel.

5. In this panel first select the branch controller 
XML configuration file generated with the CAEN rack
configurator and press 'Parse file'. The devices available
in the file will then appear in the table.

6. If you want to import the available devices, press
'Create devices in table'. This will create in PVSS all
the Easy devices.

7. Afterwards, you may want to configure also the addresses
for the just created devices. Before performing this action,
make sure that the correspondent OPC client or SIM driver
(number 6) is running.

