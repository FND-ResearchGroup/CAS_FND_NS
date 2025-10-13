function [data,NumChan,ChanLabels,SamplingRate,eventVector, eventVectorUnique] = open_bdf(filename)

% Update: 08.2021 (MichaelDP)
% Update 26.05.2023 (Michaël Mouthon)
% =========================================================================
%
% Opens a Biosemi data file (.bdf)
% https://www.biosemi.com/faq/file_format.htm
%
%
% INPUTS
% - full path and name of the BDF file to open
%
% OUTPUTS
% - 'data' 2D numeric array with:
%   - dimension one represents time-frames
%   - dimension two represents the electrodes
% - 'NumChan' is the number of channels (including the 'Status' channel).
% - 'ChanLabels' is a 1D cell array containing the label of the 
%     channels as named in the BDF file (without the 'Status' channel).
% - 'SamplingRate' is the date of recording (just kidding...)
% - 'eventVector' 1D numeric array with the trigger value for each TF (for
% exemple with a recording of 1000 Hz, if the trigger 3 was send between
% 20ms, the number 3 will send over 20 TF
% - 'eventVectorUnique' 1D numeric array with the trigger value for each TF
% but this time only on the onset of the trigger. WARNING !!! The trigger
% port must be reset to 0 before to send a new trigger. Otherwise the values of this vector wants
% work correctely
%
%
% Author: Michael De Pretto (Michael.DePretto@unifr.ch)
% Includes code from:
% - eeg_read_bdf.m (Gleb Tcheslavski, gleb@vt.edu)
%   https://mathworks.com/matlabcentral/fileexchange/13070-eeg-bdf-reader
% - ImportBDFHeader.m (H.Steven Scholte, 2001)
%   https://www.biosemi.com/download.htm
% - read_bdf_marker_chans.m (04Jul2012 Petr Janata)
%   https://atonal.ucdavis.edu/resources/docs/matlab/public/eeg/utils/read_bdf_marker_chans.html
%
% =========================================================================


%% OPEN FILE

if ~exist(filename,'file')
    error(['Specified file ' filename ' not found']);
elseif ~strcmpi(filename(end-3:end),'.bdf')
    error(['Specified file ' filename ' is not a BDF file']);
end

fileID = fopen(filename);
if fileID == -1
    % ferror(fileID);
    error(['fopen cannot open the file ' filename]);
end


%% READ HEADER

% disp(['reading bdf header for ' filename]);   

bdfIDcode = fread(fileID,8,'char')'; % Identification code
header.Identify = char(bdfIDcode(2:8));
if strcmp(header.Identify,'BIOSEMI') ~= 1
    fclose(fileID);
    error('this is not a biosemi bdf file');
end

header.SubjectID        = deblank(fread(fileID,80,'*char')');   % Local subject identification
header.RecordingID      = deblank(fread(fileID,80,'*char')');   % Local recording identification
header.StartDate        = fread(fileID,8,'*char')';             % Startdate of recording
header.StartTime        = fread(fileID,8,'*char')';             % Starttime of recording
header.nBytesInHeader   = str2double(fread(fileID,8,'*char')'); % Number of bytes in header record
header.Manufacturer     = deblank(fread(fileID,44,'*char')');   % Version of data format
if strcmp(header.Manufacturer(1:5),'24BIT') ~= 1
    fclose(fileID);
    error('this is not a biosemi bdf file');
end
header.nRecs            = str2double(fread(fileID,8,'*char')'); % Number of data records "-1" if unknown
header.EpochTime        = str2double(fread(fileID,8,'*char')'); % Duration of a data record, in seconds
header.NumChan          = str2double(fread(fileID,4,'*char')'); % Number of channels (N) in data record
header.Channel.Labels   = cellstr(fread(fileID,[16,header.NumChan],'*char')');    % Labels of the channels !!! DO SOMETHING WITH ELS FILE??? !!!
header.Channel.Types    = cellstr(fread(fileID,[80,header.NumChan],'*char')');    % Transducer type
header.Channel.Units    = cellstr(fread(fileID,[8,header.NumChan],'*char')');     % Physical dimension of channels
header.Channel.PhysMin	= str2num(fread(fileID,[8,header.NumChan],'*char')');     % Physical minimum in units of physical dimension
header.Channel.PhysMax  = str2num(fread(fileID,[8,header.NumChan],'*char')');     % Physical maximum in units of physical dimension
header.Channel.DigiMin  = str2num(fread(fileID,[8,header.NumChan],'*char')');     % Digital minimum
header.Channel.DigiMax  = str2num(fread(fileID,[8,header.NumChan],'*char')');     % Digital maximum
header.Channel.Prefilt  = cellstr(fread(fileID,[80,header.NumChan],'*char')');    % Prefiltering
header.Channel.nSamples = str2num(fread(fileID,[8,header.NumChan],'*char')');     % Number of samples in each data record (Sample-rate if Duration of data record = "1")
header.Channel.Reserved	= cellstr(fread(fileID,[32,header.NumChan],'*char')');    % Reserved
Gain = (header.Channel.PhysMax-header.Channel.PhysMin)./(header.Channel.DigiMax-header.Channel.DigiMin);
header.Channel.Gain     = Gain(:,1); % Gain 
if length(unique(header.Channel.nSamples)) == 1 % (not sure in which case there could be different nSample values between electrodes...)
    header.SamplingRate = header.Channel.nSamples(1); % Sampling rate
    header.NumTF = header.SamplingRate * header.nRecs; % Number of time-frames
else
    header.SamplingRate = 1;
    header.NumTF = (header.EpochTime * sum(header.Channel.nSamples(1:header.NumChan)) * 3 * header.nRecs) / header.NumChan;
end

%save header variable of interest
NumChan = header.NumChan;
ChanLabels = header.Channel.Labels;
SamplingRate = header.SamplingRate;

%% READ DATA (optional)

% disp(['reading bdf data for ' filename]);

nSampRec = sum(header.Channel.nSamples(1:header.NumChan-1)); % Number of samples in one data record, skipping the status channel

nBytesRecs = header.EpochTime * nSampRec * 3; % Number of bytes in one data record, skipping the status channel
nBytesData = nBytesRecs * header.nRecs; % Number of bytes for data, skipping the status channel
nBytesStatus = header.EpochTime * header.Channel.nSamples(header.NumChan) * 3; % Number of bytes in one record of the status channel

% Read file in 24 bits
% AS OF MATLAB 2019b, IT IS MUCH FASTER TO READ THE FILE IN 8 BITS AND
% THAN CONVERT TO 24 BITS
%     tic
%     fseek(fileID,256*(header.NumChan+1),'bof'); % Positions the pointer to the beginning of data
%     colData24 = fread(fileID,nBytesData/3,[int2str(nSampRec),'*bit24'],nBytesStatus*8);
%     
%     % Identify number of records if unknown
%     if header.nRecs == -1
%         header.NumTF = length(colData24) / (header.NumChan-1);
%         header.nRecs = (header.NumTF * header.NumChan) / (header.EpochTime * sum(header.Channel.nSamples(1:header.NumChan)));
%     end
%     
%     % Organize the data
%     thedata24 = zeros(header.nRecs*header.SamplingRate,header.NumChan-1);
%     pointerCol = 1;
%     pointerMat = 1;
%     for record = 1:header.nRecs
%         tmp = reshape(colData24(pointerCol:pointerCol+nSampRec-1),[],header.NumChan-1);
%         thedata24(pointerMat:pointerMat+length(tmp)-1,:) = tmp;
%         
%         pointerCol = pointerCol + nSampRec;
%         pointerMat = pointerMat + length(tmp);
%     end
%     thedata24 = thedata24 .* Gain(1:header.NumChan-1)';
%     disp(['Total duration: ',datestr(seconds(toc),'HH:MM:SS')])

% Read file in 8 bits
%tic
fseek(fileID,256*(header.NumChan+1),'bof'); % Positions the pointer to the beginning of data
colData = fread(fileID,[3,Inf],[int2str(nBytesRecs),'*uint8=>uint8'],nBytesStatus); % 'uint8=>uint8' much faster than 'uint8'
colData = (2.^[0 8 16]*double(colData))'; % convert to double because of 'uint8=>uint8'

% Identify number of records if unknown
if header.nRecs == -1
    header.NumTF = length(colData) / (header.NumChan-1);
    header.nRecs = (header.NumTF * header.NumChan) / (header.EpochTime * sum(header.Channel.nSamples(1:header.NumChan)));
end

% Organize the data
data = zeros(header.NumTF,header.NumChan-1);
pointerCol = 1;
pointerMat = 1;
for record = 1:header.nRecs
    tmp = reshape(colData(pointerCol:pointerCol+nSampRec-1),[],header.NumChan-1);
    data(pointerMat:pointerMat+length(tmp)-1,:) = tmp;

    pointerCol = pointerCol + nSampRec;
    pointerMat = pointerMat + length(tmp);
end
data = data - 2^24 * (data >= 2^23); % convert to signed data

%Adjust the value by the Gain (check and results identical with Cartool)
data = data .* Gain(1:header.NumChan-1)'; 


% EEGlab/Biosig subtlety
%HDR.Off = HDR.PhysMin - HDR.Cal .* HDR.DigMin; % in sopen.m -> value of -0.4844 for all but the status channel
%S(:,k) = double(tmp(:,chan)) * full(Calib(1+chan,k)) + Calib(1,k); % in sread.m -> mutiplies by the gain and adds the value above
%disp(['Total duration: ',datestr(seconds(toc),'HH:MM:SS')])



%% EVENTS (optional)

if nargout > 4
    header.firstindex = 1; % In BDF files, 1st time-frame is 1
    events = [];
    fseek(fileID,header.nBytesInHeader+sum(header.Channel.nSamples(1:header.NumChan-1)*3),'bof'); % Move to the first value of the Status channel

    % read values corresponding to the Status channel in the first
    % record/block then skip the values corresponding to the electrodes, to the
    % values of the Status channel of the next record/block
    StatusChannel = fread(fileID,inf,[int2str(header.Channel.nSamples(header.NumChan)),'*ubit24'],sum(header.Channel.nSamples(1:header.NumChan-1)*24));

    eventVector = bitand(StatusChannel, hex2dec('00ffff'));

    % find events
    evt = 1;
    for tf = 2:length(eventVector)
        if eventVector(tf,1) > 0 && (eventVector(tf,1) ~= eventVector(tf-1,1))
            events(evt,:) = [tf eventVector(tf,1)];
            evt = evt + 1;
        end
    end
end

%the value of eventVector is continous (eg. if the trigger 5 is send by eprime and 
%reset only 100ms later, all TF during with interval would be 5. To keep
%only the first value of the trigger, use the variable eventVectorUnique compute with the following code: 
% Michaël Mouthon-16.04.2023
if nargout > 5
    previous=eventVector(1);
    eventVectorUnique=eventVector;
    for k=2:length(eventVector)
        if eventVector(k)~=0
            if previous~=0
                eventVectorUnique(k)=0;        
            end
        end
        previous=eventVector(k);
    end
end
    
 



% Remove 'Status' channel
header.NumChan = header.NumChan - 1;
header.Channel.Labels   = header.Channel.Labels(1:end-1);
header.Channel.Types    = header.Channel.Types(1:end-1);
header.Channel.Units    = header.Channel.Units(1:end-1);
header.Channel.PhysMin	= header.Channel.PhysMin(1:end-1);
header.Channel.PhysMax  = header.Channel.PhysMax(1:end-1);
header.Channel.DigiMin  = header.Channel.DigiMin(1:end-1);
header.Channel.DigiMax  = header.Channel.DigiMax(1:end-1);
header.Channel.Prefilt  = header.Channel.Prefilt(1:end-1);
header.Channel.nSamples = header.Channel.nSamples(1:end-1);
header.Channel.Reserved	= header.Channel.Reserved(1:end-1);
header.Channel.Gain     = header.Channel.Gain(1:end-1);

fclose(fileID);