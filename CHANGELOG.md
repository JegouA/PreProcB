# Changelog

All notable changes to the project PreProcB will be documented in this file.

## [1.0.0] - 2024-02-27

First operational version for preprocessing part. The processing part is not available yet.

This pre-release focuses on the alignement of the behavior events to SEEG data. The events are created in csv table, and
also in AnyWave marker, so it can be imported in AnyWave and Brainstorm. If there is multiple SEEG files for one behavior, 
the SEEG files are concatenated to have only one version.

The filtering and Bad Channel preprocessing is also operational.