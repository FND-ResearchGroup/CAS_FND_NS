% Determine the R-peak position and write it in a marker file + Record a separate file for the ECG signal
% 
% INPUT:  
% - Need recording an file (*.bdf) 
% 	-> The first ECG channel must be on the electrodes EXG1 and EXG2. During the recording, the operator has to ensure that the R-peak signal EXG1-EXG2 is positive. 
% 	-> The second ECG channel must be on the electrodes EXG3 and EXG4. During the recording, the operator has to ensure that the R-peak signal EXG3-EXG4 is positive.
% - Specify if the ecg detection must be performed on the ecg1 (EXG1-EXG2) or ecg2 (EXG3-EXG4). Warning: In the case of a CAS experiment recording, this is always the first option. 
% - Specify manually the Internal threshold which must be used in the LIBROW script for R-peak detection. Default value is 4. Decrease this value only in cas of an error message during the proccessing.
% - Specify if you want to create a separate file with only the ECG signal in it. 
% 
% OUTPUT
% - marker file '*.mrk'(* is replace by the input bdf file name) which contain the originals triggers of the '*.bdf' + marker 1 = R-peak position detected by the LIBROW script
% - If you specify 'yes' to the final question, a '*ECGonly.eph' file (* is replace by the input bdf file name) which contain only the ECG signal mean centred to shift the 0 position (more easy to read).  
% - If you specify 'yes' to the final question, a '*ECGonly.eph.mrk' file (* is replace by the input bdf file name) which is the same marker as the fist output but readable in Cartool for the second file. 

%% Initialization
clear all
% Mapping the folder with the function used by this script
addpath(genpath('functions_needed')); %add path with sub-directories


%input EEG files
[file,path]=uigetfile('*.bdf', 'Select the EEG/ECG recording file of one participant','MultiSelect','off');

%tell which are the best ECG channel
answer1=questdlg('Which is the best ECG channel in this file', 'EXG1-EXG2','EXG1-EXG2','EXG3-EXG4','EXG3-EXG4');
if strcmp (answer1, 'EXG3-EXG4')
    bestECGchannel=2;
else
    bestECGchannel=1;
end


%save of not ECG alone
answer2=questdlg('Do you want to save a separate file with the ECG', 'Yes','Yes','No','No');

%load EEG Data
[data,NumChan,ChanLabels,SamplingRate,~,eventVectorUnique]=open_bdf_modified(strcat(path, file)); %open the recording file

%Adjust value to have the same scaling as the data transmit to Matlab
%(factor determine during pilot, see comparaison_singal_Actiview_Matlab
%folder)
%data=data.*8192;

%write marker file 

startData=1;
[endData,~]=size(data);

%% Load ECG

%Extraction of each ECG channel
EXG1=data(startData:endData,find(strcmp(ChanLabels, 'EXG1')==1))';
EXG2=data(startData:endData,find(strcmp(ChanLabels, 'EXG2')==1))';
EXG3=data(startData:endData,find(strcmp(ChanLabels, 'EXG3')==1))';
EXG4=data(startData:endData,find(strcmp(ChanLabels, 'EXG4')==1))';

switch bestECGchannel
    case 1
        ecg=EXG1-EXG2; 
    case 2
        ecg=EXG3-EXG4;
end

%% R-peak detection

%detection of the R peaks            
[peakPositionsECG, ecg1Filtered]=RpeakDetectionPositionV2(ecg,SamplingRate);

%% Create the mrk which combine the eeg file trigger and R-peak marker (=1)
savefilename=strcat(path,file,'.mrk');

%generate marker matrix with the trigger file
[MRKbdf]=create_mrk_mic(savefilename,eventVectorUnique,0); %not correct the position now

%generate marker matrix for R-peak detection
MRKr_peak=horzcat(peakPositionsECG',peakPositionsECG',ones(length(peakPositionsECG),1));

%concatenate both marker
MRKtot=vertcat(MRKbdf, MRKr_peak);

%sort this MRKtot
MRKtot=sortrows(MRKtot,1);

%write the mrk
WriteMRK_univeral (MRKtot(:,1), MRKtot(:,3), savefilename, 1); %now we correct all the onset by 1 for Cartool

%% Save a file only with ECG
if strcmp(answer2,'Yes')
    ecgFileName=strcat(path,file(1:end-4),'_ECGonly.eph');
    save_eph(ecgFileName,(ecg-mean(ecg))',SamplingRate,1); %to a reading for easey, I mean center the ECG
    WriteMRK_univeral (MRKtot(:,1), MRKtot(:,3), strcat(ecgFileName,'.mrk'), 1); %now we correct all the onset by 1 for Cartool
end
