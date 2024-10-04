classdef daqmx_recorder < handle
    % daqlogger.daqmx_recorder - acquire data from NI input channels and record data.
    %
    % Adapted from sitools.ai_recorder written by Rob Campbell - Basel, 2017
    % https://github.com/BaselLaserMouse/ScanImageTools/blob/master/code/%2Bsitools/%40ai_recorder/ai_recorder.m
    %
    % Usage
    % >> DAQMXRecorder = daqlogger.daqmx_recorder()
    % >> DAQMXRecorder.AI_channels=0:1; % acquire data on first two channels
    % >> DAQMXRecorder.AI_channels=[0,1]; % acquire data on first two channels
    % >> DAQMXRecorder.DI_channels={'port0/line0', 'port0/line1'}; % acquire data on first two channels
    % >> DAQMXRecordervoltageRange=1  % over +/- 1 volt
    % >> DAQMXRecorder.fname='test.bin';
    % >> DAQMXRecorder.start
    % >> DAQMXRecorder.stop
    %
    % KNOWN ISSUES
    % 1)
    % If you see "ERROR: A Task with name 'airecorder' already exists in
    % the DAQmx System" then check for existing instances of this class
    % and delete them (e.g. delete(myAIrec) ). If there are no instances
    % then there is an orphan task. You will either need to change the
    % "taskName" property to a different string or restart MATLAB. 
    % 2)
    % Changing data acquisition properties on the fly is not currently 
    % supported. You will need to change the settings, save the file,
    % close the object and re-load the file. This will be fixed in 
    % future. 

    properties (SetAccess=protected, Hidden=false)
        hTask % The DAQmx task handle is stored here
        OSCSender % For OSC protocol
        dataType = 'int16' % The format we will write the data in to binary file daqmx_recorder.fname
        devType = 'DAQmx';  % device type, can be only "DAQmx"
    end 

    properties
        % Saving and data configuration
        fname = ''  % File name for logging data to disk as binary using type ai_recoder.dataType
        devName = 'Dev1'      % Name of the DAQ device to which we will connect
        AI_channels = []    % Analog input channels from which to acquire data. e.g. 0:3
        DI_channels = {}     % Digital input channels from which to acquire data. e.g. 'port0/line0'
        voltageRange = 5      % Scalar defining the range over which data will be digitized
        sampleRate = 9E3      % Analog input sample Rate in Hz
        sampleReadSize = 1000  % Read off this many samples then plot and log to disk

        % OSC protocol
        useOSC = true % whether users use OSC protocol
        osc_ipadress = '127.0.0.1'
        osc_port = 59729
        osc_msg = {}
    end 

    properties (Hidden)
        taskName = 'airecorder' % Name for the task
        fid = -1  % File handle to which we will write data
    end 

    methods
        function obj = daqmx_recorder()
            success = obj.connectToDAQ;
            if obj.useOSC
                obj.connectOSC()
            end
        end

        function varargout=connectToDAQ(obj)
            switch lower(obj.devType)
                case 'daqmx'
                    % it is an NI device
                    varargout{1}=connectToNiDevice(obj);
                otherwise
                    error('devType must be NI DAQmx!')
            end
            return
        end
        
        function varargout=connectToNiDevice(obj)
            if ~exist('dabs.ni.daqmx.System','class')
                success=false;
                fprintf('No DAQmx wrapper found.\n')
                if nargout>0
                    varargout{1}=success;
                end
                return
            end
            if ~isempty(obj.hTask)
                fprintf('ERROR: Not connecting to NI DAQ device "%s". sitools.ai_recoder has already connected to the DAQ\n',...
                    obj.devName)
                success=false;
                if nargout>0
                    varargout{1}=success;
                end
                return
            end

            % Is the DAQ to which we are planning to connect present on the system?
            thisSystem = dabs.ni.daqmx.System;
            theseDevices = strsplit(thisSystem.devNames,', ');
            if isempty(strcmp(obj.devName, theseDevices) )
                fprintf('\nERROR: Device "%s" not present on system. Can not connect to DAQ. ',obj.devName)
                fprintf('Available devices are:\n')
                cellfun(@(x) fprintf(' * %s\n',x), theseDevices)
                success=false;
            else
                try
                    % Create a DAQmx task
                    obj.hTask = dabs.ni.daqmx.Task(obj.taskName);

                    % * Configure the sampling rate and the size of the buffer in samples using the on-board sanple clock
                    bufferSize_numSamplesPerChannel = obj.sampleReadSize; % The number of samples to be stored in the buffer per channel. 
                    obj.hTask.cfgSampClkTiming(obj.sampleRate, 'DAQmx_Val_ContSamps', bufferSize_numSamplesPerChannel, 'OnboardClock');

                    if ~isempty(obj.AI_channels)
                        % * Set up analog inputs
                        obj.hTask.createAIVoltageChan(obj.devName, obj.AI_channels, [], obj.voltageRange*-1, obj.voltageRange,[],[],'DAQmx_Val_NRSE');
                    end

                    if ~isempty(obj.DI_channels)
                        % * Set up digital inputs
                        obj.hTask.createAIVoltageChan(obj.devName, obj.AI_channels, [], obj.voltageRange*-1, obj.voltageRange,[],[],'DAQmx_Val_NRSE');
                        devNames = repelem({obj.devName},numel(obj.DI_channels));
                        obj.hTask.createDIChan(strcat(devNames, '/', obj.DI_channels),[],'DAQmx_Val_ChanPerLine')
                    end

                    % * Set up a callback function to regularly read the buffer and plot it or write to disk
                    obj.hTask.registerEveryNSamplesEvent(@obj.readData, obj.sampleReadSize, 1, 'Native');

                    success=true;
                catch ME
                    % If the connection to the DAQ failed, display the error
                    obj.reportError(ME)
                    success=false;
                end
            end

            if nargout>0
                varargout{1}=success;
            end
        end 

        function varargout=start(obj)
            if isempty(obj.hTask)
                fprintf('No NI DAQ connected to daqmx_recorder\n')
                return
            end
            try
                obj.openFileForWriting; % Only opens a file if the fname property is not empty
                obj.hTask.start % Task will start right away if there are no triggers configured
                fprintf('Recording data on %s. use stop method to halt acqusition.\n', obj.devName);
                success=true;
            catch ME
                obj.reportError(ME)
                success=false;
            end

            if nargout>0
                varargout{1}=success;
            end
        end 

        function varargout=stop(obj)
            if isempty(obj.hTask)
                fprintf('No NI DAQ connected to ai_recorder\n')
                return
            end
            try
                obj.hTask.stop;
                obj.closeDataFileForWriting;
                if obj.useOSC
                    osc_free_address(obj.OSCSender);
                end
                success=true;
            catch ME
                obj.reportError(ME)
                success=false;
            end
        
            if nargout>0
                varargout{1}=success;
            end
        end

        connectOSC(obj)
    end 

    methods (Hidden)
        % -----------------------------------------------------------
        % Declare external hidden methods
        function delete(obj)
            fprintf('sitools.ai_recorder is shutting down\n')
            obj.stop
            delete(obj.hTask)
        end 

        function openFileForWriting(obj)
            % Opens a data file for writing
            if ~isempty(obj.fname) && ischar(obj.fname)
                obj.fid=fopen(obj.fname,'w+');
                fprintf('Opened file %s for writing\n', obj.fname)
            else
                obj.fid=-1;
            end
        end 

        function closeDataFileForWriting(obj)
            if obj.fid>-1
                fclose(obj.fid);
                obj.fid=-1;
                obj.fname='';
            end
        end

        function reportError(~,ME)
            % Reports error from error structure, ME
            fprintf('ERROR: %s\n',ME.message)
            for ii=1:length(ME.stack)
                 fprintf(' on line %d of %s\n', ME.stack(ii).line,  ME.stack(ii).name)
            end
            fprintf('\n')
        end

        % -----------------------------------------------------------
        % Callbacks
        function readData(obj,~,evt)
            % This callback function runs each time a pre-defined number of points have been collected
            % This is defined at the hTask.registerEveryNSamplesEvent method call.
            errorMessage = evt.errorMessage;

            % check for errors and close the task if any occur. 
            if ~isempty(errorMessage)
                obj.delete
                error(errorMessage);
            else
                if isempty(evt.data)
                    fprintf('Input buffer is empty!\n' );
                else

                    for ii=1:size(evt.data,2)
                        msg = struct( ...
                            'path', obj.osc_msg(ii), ... 
                            'data', {evt.data(:,ii)} ...
                            );
                
                        err = osc_send(obj.OSCSender, msg); % send the message
                        
                        if ~isempty(err)
                            obj.reportError(err)
                        end
                    end
                    if obj.fid>=0
                        fwrite(obj.fid, evt.data', obj.dataType);
                    end
                end
            end
        end

    end

end