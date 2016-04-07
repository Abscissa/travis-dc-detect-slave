#!/bin/sh
DMD_ZIP=dmd.2.070.2.linux.zip

if [ ! -d "local-dmd" ]; then
	wget http://downloads.dlang.org/releases/2016/$DMD_ZIP
	unzip -d local-dmd $DMD_ZIP
fi
