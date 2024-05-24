This file demonstrated the objectives of the project and the steps to achieve it.

# Objectives :
- Developing a shell script that shall act as a user-interface for our tcl script that takes in an input csv file as it's argument.
- This csv file consists of important parameters like : design name, rtl directory, path to constraints file, cell library path, output directory path.
- The tcl script should be capable of processing this information and also check if any of these information is missing and then report it accordingly to the user.
- The constraints file provided must be converted into SDC format for the tools to interpret the design constraints.
- These constraints along with the rtl is provided to the open-source synthesis tool `Yosys`
- The gate-level netlist generated by `Yosys` is then provided to STA tool `OpenTimer` alongside timing constraints for post-synthesis timing analysis.
- A final report is generated

# Sub-Tasks :
- Create a command - vsdsynth that takes a .csv file provided as an argument and passes it to TCL script.
- Converting input files to a format (format[1]) which is interpreted by the Yosys tool and additionally converting input constraint csv into an SDC format.
- Converting format[1] and SDC file into a format (format[2]) which is interpreted by OpenTimer tool
- Generate output report

### Micro tasks to achieve Sub-Task 1 (Convert i/p to format[1] & SDC format. and pass to Yosys tool) :

- Create variables through csv file

- Check existence of the directories mentioned in csv file

- Read 'Constraints File' from .csv and convert it into SDC format

- Read all files in 'Netlist Directory'

- Create main synthesis script in format[1]

- Pass this script to Yosys
