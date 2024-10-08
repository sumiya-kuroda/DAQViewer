% Set DAQLogger
DAQMXRecorder = daqlogger.daqmx_recorder();
DAQMXRecorder.AI_channels=[0,3,4,7,8,9,10,11,12]; % acquire data on first two channels
DAQMXRecorder.fname='./20241008.bin';
DAQMXRecorder.connectToDAQ;
% Start the task
DAQMXRecorder.start

% Stop the task
DAQMXRecorder.stop
DAQMXRecorder.delete

% Open the bin file
fid = fopen('./20241008.bin','r');
[data,count] = fread(fid,[10,inf],'double');
fclose(fid);