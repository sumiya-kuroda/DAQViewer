# DAQViewer
A simple, light, stand-alone python GUI to visualize DAQ events. 

It does **not** record events or do any sorts of complicated things: we believe you already have a GUI for that. If not, you can use `DAQLogger` which can record events and interact with `DAQViewer` nicely using opensoundcontrol protocol via UDP. 

## Getting Started
Install dependencies and codes using conda.
```sh
conda env create -f environment.yml
conda activate daqviewer

cd daqviewer
python main.py # launch GUI
```

## Customizing for your experiments
Every experiment is different. in order to customize the GUi for your needs, you need to create your own config `.yaml` file under `settings/`. 

## DAQlogger
Currently it supports Matlab, Python, and bonsai-rx. The communication between DAQViewer and DAQLogger is achieved by OSC protcol.

## Reference
This work is heavily inspired by some of the major existing pipelines, including
- [AllenNeuralDynamics/dynamic-foraging-task](AllenNeuralDynamics/dynamic-foraging-task)
- [pyControl](https://github.com/pyControl/code)
- [int-brain-lab/iblrig](https://github.com/int-brain-lab/iblrig)