<p align="center"> 
  <img src="img/icon_trn.svg" alt="TRN Logo" width="80px" height="80px">
</p>
<h1 align="center"> TrayNim </h1>
<h3 align="center"> A simple ray tracer written in Nim </h3>  

</br>

<p align="center"> 
  <img src="img/traynim_banner.gif" alt="Sample signal" width="80%" height="80%">
</p>

<!-- Add buttons here -->

![GitHub release (latest by date including pre-releases)](https://img.shields.io/github/v/release/ottyanna/traynim?include_prereleases)
![GitHub last commit](https://img.shields.io/github/last-commit/ottyanna/traynim)
![GitHub issues](https://img.shields.io/github/issues-raw/ottyanna/traynim)
![GitHub pull requests](https://img.shields.io/github/issues-pr/ottyanna/traynim)
![GitHub](https://img.shields.io/github/license/ottyanna/traynim)
![GitHub Workflow Status](https://img.shields.io/github/workflow/status/ottyanna/traynim/BuildAndTest)
![GitHub status](https://img.shields.io/badge/status-WIP-informational)

Traynim is a CLI program written in Nim that lets you create photorealistic images using spheres and planes. 
It can also be used as a tool for converting PFM files to PNG, PPM, BMP and QOI.

## Demo-Preview

Traynim can produce images like this with four different renderers: path tracer, on/off, point light and flat renderer respectively.

<p align="center"> 
  <img src="img/demo/Antialiasing/pathTracingr4s16.png" alt="Sample signal" width="45%" height="50%">
  <img src="img/demo/spheres-perspective.gif" alt="Sample signal" width="45%" height="50%">
</p>

<p align="center">
  <img src="img/demo/Antialiasing/PointLightr4s16.png" alt="Sample signal" width="45%" height="50%">
  <img src="img/demo/Antialiasing/flatr4s25.png" alt="Sample signal" width="45%" height="50%">
</p>


# Table of contents

- [Demo-Preview](#demo-preview)
- [Table of contents](#table-of-contents)
- [Installation](#installation)
- [Usage](#usage)
- [Examples](#examples)
- [Contribute](#contribute)
- [Release History](#release-history)
- [License](#license)
- [Footnotes](#footnotes)

## Installation
[(Back to top)](#table-of-contents)

### Dependencies
- [nim](https://github.com/nim-lang) >= 1.6.4
- [nimble](https://github.com/nim-lang/nimble)
- [ffmpeg](https://www.ffmpeg.org/) and [parallel](https://en.wikipedia.org/wiki/GNU_parallel) for the animations



### Download and building
You can download the latest stable release [here](https://github.com/ottyanna/traynim/releases), and unpack it
   ``` sh
   $ tar -xvf /path/to/tar #or zip file -C /path/to/your/directory
   ```
or if you want, you can clone this repository
   ``` sh
   $ git clone https://github.com/ottyanna/traynim.git
   ```

### Testing
You can test if the code works fine by running the following command:
``` sh
   $ nimble test
   ```

## Usage
[(Back to top)](#table-of-contents)

```sh
$ nimble run traynim
```
will generate the executable.

To display the command-line help, you can use

```sh
$ ./traynim --help

Usage:
  traynim {SUBCMD}  [sub-command options & parameters]
where {SUBCMD} is one of:
  help        print comprehensive or per-cmd help
  pfm2format  
  demo        

traynim {-h|--help} or with no args at all prints this message.
traynim --help-syntax gives general cligen syntax help.
Run "traynim {help SUBCMD|SUBCMD --help}" to see help for just SUBCMD.
Run "traynim help" to get *comprehensive* help.
```

To generate one demo image with default parameters use

```sh
$ ./traynim demo
```

You can change the size of the image, the angle view or the camera type by running `--help`.

As it is shown in [Demo-Preview](#demo-preview), it is possible to use different rendering methods by using the `--algorithm` flag.

 Renderer |  Feature
:-------------------------:|:-------------------------: 
Simple Path Tracer  | Uses Russian roulette method
Point Light Renderer  | The source light is considered a dirac delta
Flat Renderer | The scene is traced without considering the light, so it is in solid colors
On/off renderer | There are just two colors, one for the objects, one for the background

While the path tracer is really slow, the flat, point light and on/off renderers are fast, so they are useful for debugging or to get an idea if the object positions are right. The time scale depends really on the scene but for a simple scene it can take up to 5 minutes for the path tracing while about 5/20 seconds for the others. 
<!--- Moreover, bear in mind that if you use a sphere for the sky the on/off renderer--> 

To generate the on/off tracer demo animation shown in [Demo-Preview](#demo-preview), in UNIX systems just run

```sh
$ ./animation.sh NUM_OF_CORES >/dev/null
```

where `NUM_OF_CORES` are the number of cores to parallelize the generation.

To use the `pfm2format` feature, you have to bear in mind that just PNG, PPM, BMP and [QOI](https://en.wikipedia.org/wiki/QOI_(image_format)) formats are supported.


## Examples

### Antialiasing with flat rendering:

The scene has a white light in coordinates (-50, 30, 30). The number of rays is always 4 (`-r=4`) and the luminosity is 0.8.

 `-s=1` |  `-s=4` | `-s=25`
:-------------------------:|:-------------------------:|:-------------------------: 
![](img/demo/Antialiasing/flatr4.png)  |  ![](img/demo/Antialiasing/flatr4s4.png) | ![](img/demo/Antialiasing/flatr4s25.png)
4 seconds | 16 seconds | 104 seconds

As you can see the noise is sensibly reduced by increasing the samplesPerPixel.



### `--gamma` and `--factor` variation in `pfm2format` feature:

<!---maybe we need to write the site of the image--->

|    options     | `-f=0.15`             |  `-f=0.30` | `-f=0.50`
:---------:|:-------------------------:|:-------------------------:|:-------------------------: 
`-g=1.0` | ![](img/pfm2formatExamples/sample1.00.15.png)  |  ![](img/pfm2formatExamples/sample1.00.30.png) | ![](img/pfm2formatExamples/sample1.00.50.png) 
`-g=2.2` | ![](img/pfm2formatExamples/sample2.20.15.png) | ![](img/pfm2formatExamples/sample2.20.30.png)  |  ![](img/pfm2formatExamples/sample2.20.50.png)

You can compare different values for `gamma` and `factor` tweaking the bash script in [img/pfm2formatExamples](img/pfm2formatExamples/) folder<sup id="a1">[1](#f1)</sup>

## Contribute
[(Back to top)](#table-of-contents)

If you wish to contribute or you found any bug, feel free to open an issue or a pull request on the GitHub repository.

## Release History
[(Back to top)](#table-of-contents)

See the [CHANGELOG.md](https://github.com/ottyanna/traynim/blob/master/CHANGELOG.md) file.

## License
[(Back to top)](#table-of-contents)

[GNU GPLv3](https://choosealicense.com/licenses/gpl-3.0/)

## Footnotes
<b id="f1">1</b> The sample image was taken from [here](https://filesamples.com/formats/pfm). [↩](#a1) 