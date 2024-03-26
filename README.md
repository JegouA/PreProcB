# PreProcB

Tis project has two goals. The first one is to align the event of behavior data to the SEEG signal, and the second is to provide a small SEEG processing.

## Description

This project can be run using graphical interface or by using the functions. It is link to the EMU data server but can be used locally.
Preprocessing focuses on the alignement of the behavior events to SEEG data. The events are created in csv table, and
also in AnyWave marker, so it can be imported in AnyWave and Brainstorm. If there is multiple SEEG files for one behavior, 
the SEEG files are concatenated to have only one version. A protocol file is required for this part.
Processing is divided in three parts. The firs part is to prepre the data with filtering, dowsampling and montage. The second part
is to create the epochs according to specific marker name. The last part is to perform Time-Frequency analysis on the epochs. At each par, a mat-file
is saved containing a fieldtrip structure that can be imported in Brainstrom.

## Getting Started

### Dependencies

* Matlab installes
If not using apps:
* fieldtrip toolbox

### Installing

* Matlab: Add the project path and fieldtrip to you current Matlab path, then type "PreProcB" in command line.
* App: Select APPS panel on Matlab, and install App, then install the file provided in apps folder.

## Help

Read the tutorial (draft available). 
Please contact Aude Jegou for any questions. If error appears, send it to Aude with screenshot of the error.

## Authors

Contributors names and contact info:
* Aude Jegou (main developer): auj10@pitt.edu
* Eliza Reedy (protocols & behavior data): reedyem@upmc.edu
* Steven Salazar (database & EMU server): sas901@pitt.edu

## License

This project is under GPL-v3 License.