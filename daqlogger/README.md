# DAQLogger
These files are simply examples explaining how you can record events and use OSC protocol to communicate with DAQViewer. One needs to add these features to their own behavioral codes eventually to make it work. So fat we have only tested Bonsai-rx, Python 3, and Matlab, but in theory, any scripts/softwares that can interact with NI-DAQmx should work.

## Bonsai-rx
Tested using Bonsai ver.2.8.5 on Windows 10.
Install following dependencies.
- Bonsai
- Bonsai.DAQmx 
- NI-DAQmax **version 19.0** (The only version that works with Bonsai.DAQmx as of Sep 2024.)

![image](https://github.com/sumiya-kuroda/DAQViewer/blob/gallery/gallery/bonsai_screenshot.PNG)

## Python
Install following dependencies.
- `conda env create -f environment.yml`
- NI-DAQmax version 19.0 (on Windows 10) or version XXX (on xubuntu 16.04)
This example only shows about how to setup OSC. There are so many amazing examples explaining how one can interact with DAQ using Python, so please take a look at them. e.g. [SWC-Advanced-Microscopy/SimplePyScanner](https://github.com/SWC-Advanced-Microscopy/SimplePyScanner).

## Matlab
Tested using Matlab R2019b on Windows 10. As of Sep 2024, Matlab's `Data Acquisition Toolbox` only works with Windows.
Install following dependencies. 
- Matlab >=R2019b
- Matlab AddOn `MATLAB Support for MinGW-w64 C/C++/Fortran Compiler` and `Data Acquisition Toolbox`
- NI-DAQmax version 19.0 (on Windows 10) 
- [oscmex](https://sourceforge.net/projects/oscmex/). For Windows 10, use [this precompiled script](https://github.com/sumiya-kuroda/oscmex/tree/master).

For the DAQmx interaction, please also check [this amazing example by Rob Campbell](https://github.com/BaselLaserMouse/ScanImageTools/blob/master/code/%2Bsitools/%40ai_recorder/ai_recorder.m).

To compile oscmex, you should follow [this guideline](https://stackoverflow.com/questions/14789656/linking-matlab-to-a-dll-library) and [this readme](https://github.com/kronihias/oscmex).