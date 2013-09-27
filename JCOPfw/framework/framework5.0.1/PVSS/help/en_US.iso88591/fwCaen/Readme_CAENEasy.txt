Instructions for the CAEN Easy System in the JCOP Framework
===========================================================

The following steps have to be followed:

1. In the Device Editor and Navigator, create an SY1527
crate in the usual way.

2. Then add an Easy branch controller (the device type is
CAEN SY1527 Board A1676)

3. Then in the editor panel of the branch controller,
click on the 'Advanced options' button. This will open
the 'CAEN Easy Branch Controller A1676 Import' panel.

4. In this panel first select the branch controller 
XML configuration file generated with the CAEN rack
configurator and press 'Parse file'. The devices available
in the file will then appear in the table.

5. If you want to import the available devices, press
'Create devices in table'. This will create in PVSS all
the Easy devices.

6. Afterwards, you may want to configure also the addresses
for the just created devices. Before performing this action,
make sure that the correspondent OPC client or SIM driver
(number 6) is running.

Note: it is not necessary anymore to add the bin directory of
the project to the system path.
