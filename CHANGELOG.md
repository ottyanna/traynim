# Changelog
All notable changes to this project will be documented in this file.

## [1.0.1] - 22/06/2022

### Fixed
- Fixed an issue with missing pfm image [#10](https://github.com/ottyanna/traynim/pull/10)
- Fixed bug with stackMain.sh script

## [1.0.0] - 18/06/2022

## Added
- **Major update**: new `renderer` command to add scene from file 
- **Major update**: new `stack` command to reduce noise
- Added compiler to parse scene from file

## Deprecated
- `demo` command


## [0.3.0] - 25/05/2022

## Added
- **Major update**: Path Tracing renderer
- **Major update**: Flat renderer
- **Major update**: Point Light renderer
- Antialiasing feature
- Some pigments and BRDFs


## [0.2.0] - 11/05/2022

### Added
- **Major update**: new `demo` command
- implemented spheres and planes
- on/off rendering feature

### Changed 
- **Major update**: nicer CLI using [cligen](https://github.com/c-blake/cligen)

### Removed
- Removed old CLI

## [0.1.1] - 27/04/2022

### Fixed
-   Fixed an issue with the vertical order of the images [#4](https://github.com/ottyanna/traynim/pull/4)

## [0.1.0] - 30/03/2022
First release of the code

### Added
- Reading from PFM files
- Tone mapping
- Gamma correction
- Saving files in PNG, PPM, BMP and QOI formats

[0.1.0]: https://github.com/ottyanna/traynim/releases/tag/v0.1.0
[0.1.1]: https://github.com/ottyanna/traynim/releases/tag/v0.1.1
[0.2.0]: https://github.com/ottyanna/traynim/releases/tag/v0.2.0
[0.3.0]: https://github.com/ottyanna/traynim/releases/tag/v0.3.0
[1.0.0]: https://github.com/ottyanna/traynim/releases/tag/v1.0.0
[1.0.1]: https://github.com/ottyanna/traynim/releases/tag/v1.0.1