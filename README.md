# traynim [Work-in-progress]

Traynim is a ray tracer written in Nim.

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