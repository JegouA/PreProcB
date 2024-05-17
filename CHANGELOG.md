# Changelog

All notable changes to the project PreProcB will be documented in this file.

## [1.3.2] - 2024-05-17

### Fixed

- Visualization after the filtering, dowsampling, montage process
- Adding a minimum value for the frequency of the TFmap depending of the filter value

## [1.3.1] - 2024-05-08

### Added

- Adding functionnal connectivity process, for now only Cross-correlation

### Fixed

- minor bugs

## [1.2.1] - 2024-04-10

### Added

- Adding option in processing to reject the bad trials form epoching
- Adding the option to normalize the Time-frequency analysis to avoid 1/f
- Adding information in one message box

### Changed

- Highest frequency value in TF processing is now determine by default but still can be changed 

## [1.1.2] - 2024-04-4

### Fixed

- Creating an error if EMU ID is not given in Processing panel because cannot write the output path.

### Changed

- For the markers, I change the duration to 0 to make it as a single event and be able to use it in Brainstorm to create epochs.

## [1.1.1] - 2024-03-26

### Fixed

- Change the feildtrip structure variable for epochs to be able to import it in Brainstorm
- Solving some bugs from preprocessing, protocol issue.
- Solving some bugs in processing.

### Added

- Possibility to call visualize outside PreprocB.


## [1.1.0] - 2024-03-22

First operationel version of processing.

Processing is divided in three parts. The firs part is to prepre the data with filtering, dowsampling and montage. The second part
is to create the epochs according to specific marker name. The last part is to perform Time-Frequency analysis on the epochs. At each par, a mat-file
is saved containing a fieldtrip structure that can be imported in Brainstrom.

## [1.0.0] - 2024-02-27

First operational version for preprocessing part. The processing part is not available yet.

This pre-release focuses on the alignement of the behavior events to SEEG data. The events are created in csv table, and
also in AnyWave marker, so it can be imported in AnyWave and Brainstorm. If there is multiple SEEG files for one behavior, 
the SEEG files are concatenated to have only one version.

The filtering and Bad Channel preprocessing is also operational.