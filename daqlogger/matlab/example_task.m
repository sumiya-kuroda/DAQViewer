% Set DAQLogger
DAQMXRecorder = daqlogger.daqmx_recorder();
DAQMXRecorder.AI_channels=[0,1]; % acquire data on first two channels
DAQMXRecorder.fname='./test.bin';
DAQMXRecorder.connectToDAQ;
% Start the task
DAQMXRecorder.start

% Stop the task
DAQMXRecorder.stop
DAQMXRecorder.delete

% Open the bin file
fid = fopen('./test.bin','r');
[data,count] = fread(fid,[3,inf],'double');
fclose(fid);