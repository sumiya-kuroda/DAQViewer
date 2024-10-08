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
    % >> DAQMXRecorder.voltageRange=1  % over +/- 1 volt
    % >> DAQMXRecorder.fname='test.bin';
    % >> DAQMXRecorder.start
    % >> DAQMXRecorder.stop
    %
    % KNOWN ISSUES
    % Changing data acquisition properties on the fly is not currently 
    % supported. You will need to change the settings, save the file,
    % close the object and re-load the file. This will be fixed in 
    % future. 

    properties (SetAccess=protected, Hidden=false)
        hTask = [] % The DAQmx task handle is stored here
        OSCSender % For OSC protocol
        dataType = 'double' % The format we will write the data in to binary file daqmx_recorder.fname
        devType = 'DAQmx';  % device type, can be only "DAQmx"
    end 

    properties
        % Saving and data configuration
        fname = ''  % File name for logging data to disk as binary using type ai_recoder.dataType
        devName = 'Dev1'      % Name of the DAQ device to which we will connect
        AI_channels = []    % Analog input channels from which to acquire data. e.g. 0:3
        CI_channels = 'ctr0' % Counter input channels from which to acquire data. e.g. 'ctr0'
        % DI_channels = {}     % Digital input channels from which to acquire data. e.g. 'port0/line0'
        voltageRange = 5      % Scalar defining the range over which data will be digitized
        sampleRate = 9E3      % Analog input sample Rate in Hz
        sampleReadSize = 1000  % Read off this many samples then plot and log to disk

        % OSC protocol
        useOSC = true % whether users use OSC protocol
        osc_ipadress = '127.0.0.1'
        osc_port = 59729
        osc_msg_AI = {}
        osc_msg_CI = {}
        osc_msgs = {}
    end 

    properties (Hidden)
        % taskName = 'daqmxrecorder' % Name for the task
        listeners = {} % Reserved for listeners we might make
        fid = -1  % File handle to which we will write data
    end 

    methods
        function obj = daqmx_recorder()
            % success = obj.connectToDAQ;
            if obj.useOSC
                obj.connectOSC()
            end
        end

        function success=setLogger(obj)
            try
                obj.listeners{length(obj.listeners)+1}=addlistener(obj.hTask, 'DataAvailable', @obj.readData);  
                if obj.useOSC
                    ainpts = repelem({'/ai'},numel(obj.AI_channels));
                    obj.osc_msg_AI = strcat(ainpts, arrayfun(@(x) num2str(x), obj.AI_channels, 'UniformOutput', false));
                    obj.osc_msg_CI = {strcat('/',obj.CI_channels)};
                    obj.osc_msgs = [obj.osc_msg_AI,obj.osc_msg_CI];
                end
                success=true;
            catch ME
                % If the connection to the DAQ failed, display the error
                obj.reportError(ME)
                success=false;
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
            obj.setLogger;
            return
        end
        
        function varargout=connectToNiDevice(obj)
            if ~isempty(obj.hTask)
                fprintf('ERROR: Not connecting to NI DAQ device "%s". daqmx_recoder has already connected to the DAQ\n',...
                    obj.devName)
                success=false;
                if nargout>0
                    varargout{1}=success;
                end
                return
            end

            % Is the DAQ to which we are planning to connect present on the system?
            theseDevices = daq.getDevices; % supports only one for now
            theseDevices = {theseDevices.ID};
            if isempty(strcmp(obj.devName, theseDevices) )
                fprintf('\nERROR: Device "%s" not present on system. Can not connect to DAQ. ',obj.devName)
                fprintf('Available devices are:\n')
                cellfun(@(x) fprintf(' * %s\n',x), theseDevices)
                success=false;
            else
                try 
                    obj.hTask = daq.createSession('ni');
                    obj.hTask.IsContinuous = true;
                    
                    % * Configure the sampling rate and the size of the buffer in samples using the on-board sanple clock
                    bufferSize_numSamplesPerChannel = obj.sampleReadSize; % The number of samples to be stored in the buffer per channel. 
                    obj.hTask.Rate=obj.sampleRate;
                    obj.hTask.NotifyWhenDataAvailableExceeds=bufferSize_numSamplesPerChannel;                   
                    
                    if ~isempty(obj.AI_channels)
                        % * Set up analog inputs
                        ch_AI = obj.hTask.addAnalogInputChannel(obj.devName,obj.AI_channels,'Voltage');
                        for i = 1:numel(ch_AI)
                            ch_AI(i).Range = [obj.voltageRange*-1, obj.voltageRange];
                        end
      
                    end

                    if ~isempty(obj.CI_channels)
                        % * Set up counter inputs
                        ch_CI=addCounterInputChannel(obj.hTask,obj.devName,obj.CI_channels,'Position'); 
                        ch_CI.InitialCount=1000;
                        % ch_CI.EncoderType = 'X2';
                    end

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
                obj.hTask.startBackground; % Task will start right away if there are no triggers configured
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
                success=true;
            catch ME
                obj.reportError(ME)
                success=false;
            end
        
            if nargout>0
                varargout{1}=success;
            end
        end

        function connectOSC(obj)
            obj.OSCSender = osc_new_address(obj.osc_ipadress, obj.osc_port);
        end
    end 

    methods (Hidden)
        % -----------------------------------------------------------
        % Declare external hidden methods
        function delete(obj)
            fprintf('daqmx_recorder is shutting down\n')
            obj.stop
            if obj.useOSC
                osc_free_address(obj.OSCSender);
            end
            cellfun(@delete,obj.listeners)
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
            if isempty(evt.Data)
                fprintf('Input buffer is empty!\n' );
            else

                for ii=1:size(evt.Data,2)
                    msg = struct( ...
                        'path', obj.osc_msgs(ii), ... 
                        'data', {{evt.Data(:,ii)}} ... % {evt.Data(:,ii)}
                        );

                    err = osc_send(obj.OSCSender, msg); % send the message

%                     if ~isempty(err)
%                         fprintf('ERROR: %s\n',err)
%                     end
                end
                if obj.fid>=0
                    fwrite(obj.fid, evt.Data', obj.dataType);
                end
            end
        end
    end

end