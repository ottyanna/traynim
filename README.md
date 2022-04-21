<p align="center"> 
  <img src="img/icon_trn.svg" alt="TRN Logo" width="80px" height="80px">
</p>
<h1 align="center"> TrayNim </h1>
<h3 align="center"> A simple ray tracer written in Nim </h3>  

</br>

<p align="center"> 
  <img src="img/traynim_banner.gif" alt="Sample signal" width="60%" height="60%">
</p>

<!-- Add buttons here -->

![GitHub release (latest by date including pre-releases)](https://img.shields.io/github/v/release/ottyanna/traynim?include_prereleases)
![GitHub last commit](https://img.shields.io/github/last-commit/ottyanna/traynim)
![GitHub issues](https://img.shields.io/github/issues-raw/ottyanna/traynim)
![GitHub pull requests](https://img.shields.io/github/issues-pr/ottyanna/traynim)
![GitHub](https://img.shields.io/github/license/ottyanna/traynim)
![GitHub Workflow Status](https://img.shields.io/github/workflow/status/ottyanna/traynim/BuildAndTest)
![GitHub status](https://img.shields.io/badge/status-WIP-informational)

Functionalities implemented:
- Read from PFM files
- Tone mapping
- Gamma correction
- Save files in PNG, PPM, BMP and QOI formats

## Usage

```console
~$ nimble run traynim INPUT_PFM_FILE FACTOR GAMMA OUTPUT_FILE.FORMAT
```

Example:

```console
~$ nimble run traynim tests/HdrImageReferences/memorial.pfm 0.2 1.0 tests/HdrImageReferences/output_test.png
```


## License
[GNU GPLv3](https://choosealicense.com/licenses/gpl-3.0/)