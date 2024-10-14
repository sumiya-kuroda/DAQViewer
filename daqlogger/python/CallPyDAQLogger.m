%%
% 1. Determine the location of the Python executable
% Run following line inside your conda environment: 
% python -c "import sys; print(sys.executable)"
% 
% 2. Set Python executable for Matlab
% PathToPython = "C:\Users\Sumiya\miniconda3\envs\daqviewer\python.exe"
pyenv('Version', PathToPython)
% 'InProcess' (default) | 'OutOfProcess'

AIfname = './testmat_ai.bin';
CIfname = './testmat_ci.bin';

DAQLogger = py.PyDAQLogger.PyDAQLogger(AIfname, CIfname);
DAQLogger.semd_oscmsg('/expid', 'dmdm');

% Start
DAQLogger.start_acquisition();

% Stop
DAQLogger.stop_acquisition();
DAQLogger.close_tasks();