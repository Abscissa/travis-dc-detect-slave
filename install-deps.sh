#!/bin/sh
DMD_ZIP=dmd.2.070.2.linux.zip
wget http://downloads.dlang.org/releases/2016/$DMD_ZIP
unzip -d local-dmd $DMD_ZIP

echo "// See config.example.sdl for documentation for this file" > config.sdl
echo "reporter-command \"cd reporter/postToHTTPS && dub run --compiler=../../local-dmd/dmd2/linux/bin64/dmd -- https://semitwist.com/travis-d-compilers/compiler\"" >> config.sdl
