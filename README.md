# Installation
## Installation
### With Nix
If you have Nix installed on your system, the process is really simple:
Just run
```
nix run github.com:spl3g/pixel-sorting
```
### Without nix
Install `odin` with your systems package manager and run:
```
git clone https://github.com/spl3g/pixel-sortin
cd pixel-sorting
odin build .
```
# How to use
```sh
./pixsort [INPUT] [OUTPUT] *flags*
optional flags:
  -f: float, from threashold
  -t: float, to threashold
  -i: bool, inverse threashold
```
# Some results
![image](https://github.com/spl3g/pixel-sorting/assets/58591608/9d0786ba-fd9e-47bd-b8f9-a693f3d43981)
![image](https://github.com/spl3g/pixel-sorting/assets/58591608/7e61fb72-c57c-4193-90a5-760e2bb795c3)
![image](https://github.com/spl3g/pixel-sorting/assets/58591608/d87ce2dd-ee65-4e39-a11c-ea891cf27ead)
