# Changelog

All notable changes to the project PreProcB will be documented in this file.

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