% Script to modify the marker files in order to tag the position of a real
% R-peak detected by the Librow algorithm (used for the HEP analysis). 
% 
% HEP analysis decision
% 10 - R-peak on sounds in synch condition
% 11 - R-peak on omission in synch condition
% 12 - R-peak closest to sound in asynch condition (min 500ms after last sound trigger of previous stim)
% 13 - R-peak closest to omission in asynch condition (min 500ms after last sound trigger of previous stim)
% 1- R-peak which is not associate to a stim
%
% For the detection in asynch, the R-peak must at leat 500ms after the previous stim (sound or omission).
% No limitation for after the stim (decision to avoid a possible effect the previous sound). 
% If two R-peak have exactely the same distance from the stim, choose the one after it. 
%
% INPUT:  
% - Need recording an file (*.bdf) 
% 	-> The first ECG channel must be on the electrodes EXG1 and EXG2. During the recording, the operator has to ensure that the R-peak signal EXG1-EXG2 is positive. .
% 
% OUTPUT
% - marker file '*.mrk'(* is replace by the input bdf file name) which
% contain the originals triggers in the '*.bdf' + marker R-peak position
% detected by the LIBROW script with the specification defined above. 
% - If you specify 'yes' to the final question, a '*ECG.eph' file (* is replace by the input bdf file name) which contain only the ECG signal mean centred to shift the 0 position (more easy to read).  
% - If you specify 'yes' to the final question, a '*ECG.eph.mrk' file (* is replace by the input bdf file name) which is the same marker as the fist output but readable in Cartool for the second file. 
%


%% Initialization
clear all
% Mapping the folder with the function used by this script
addpath(genpath('functions_needed')); %add path with sub-directories


%input EEG folder
path=uigetdir('R:\Experiments\Original Results\27 - Interoception\CAS\', 'Select folder which contains the raw bdf files');

%tell which are the best ECG channel
% answer1=questdlg('Which is the best ECG channel in this file', 'EXG1-EXG2','EXG1-EXG2','EXG3-EXG4','EXG3-EXG4');
% if strcmp (answer1, 'EXG3-EXG4')
%     bestECGchannel=2;
% else
%     bestECGchannel=1;
% end
bestECGchannel=1; % in CAS, it is systematically the EXG1-EXG2 (because we switch the electrode position on the EEG box when EXG3-EXG4 was better).

%save of not ECG alone
answer2=questdlg('Do you want to save a separate file with the ECG', 'Yes','Yes','No','No');

%look for files
files=dir(strcat(path,'\*\*.bdf'));

for i=1:size(files,1)
    %load EEG Data
    file=fullfile(files(i).folder,files(i).name);
    disp(file);
    [data,NumChan,ChanLabels,SamplingRate,~,eventVectorUnique]=open_bdf_modified(file); %open the recording file

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

    %% Compute HEP marker
    
    MRKtot2=MRKtot; %to avoid that a modif impact the next test
    
    for k=2:size(MRKtot,1)-1
        if or(MRKtot(k,3)==5,MRKtot(k,3)==6) %case synch
            if and(MRKtot(k-1,3)==1,MRKtot(k,1)-MRKtot(k-1,1)<110) %je décide d'imposer une limite de 54ms (110 TF) pour éviter les bad R-peak detection  
                if MRKtot(k,3)==5 
                    MRKtot2(k-1,3)=10; %sound
                else
                    MRKtot2(k-1,3)=11; %omission
                end
            elseif and(MRKtot(k+1,3)==1,MRKtot(k+1,1)-MRKtot(k,1)<110)
                if MRKtot(k,3)==5 
                    MRKtot2(k+1,3)=10; %sound
                else
                    MRKtot2(k+1,3)=11; %omission
                end
            end

        elseif or(MRKtot(k,3)==7,MRKtot(k,3)==8) %case asynch
            previousR=k-1;
            while MRKtot(previousR,3)~=1 %look for the R-peak before stim
                previousR=previousR-1;
            end
            nextR=k+1;
            while MRKtot(nextR,3)~=1 %look for the R-peak after stim
                nextR=nextR+1;
            end
            previousStim=k-1;
            while and(MRKtot(previousStim,3)~=7, MRKtot(previousStim,3)~=8) %find the position of previous stim
                previousStim=previousStim-1;
                if previousStim==1 %for the first stim
                    break;
                end
            end
                        
            
            diffpre=MRKtot(k,1)-MRKtot(previousR,1); %difference pre
            diffnext=MRKtot(nextR,1)-MRKtot(k,1);
            
            if diffnext<=diffpre %the next one is closest 
                if MRKtot(nextR,1)-MRKtot(previousStim,1)>1024 %check if previous stim is distante of at least of 500ms (1024 TF) from the R-peak
                    if MRKtot(k,3)==7 
                        MRKtot2(nextR,3)=12; %sound
                    else
                        MRKtot2(nextR,3)=13; %omission
                    end
                end
            else %the previous one is closest
                if MRKtot(previousR,1)-MRKtot(previousStim,1)>1024 %check if previous stim is distante of at least of 500ms (1024 TF) from the R-peak
                    if MRKtot(k,3)==7
                        MRKtot2(previousR,3)=12;
                    else
                        MRKtot2(previousR,3)=13;
                    end
                end
            end
                   
        end
        
    end
    
    
    
    %% Save EEG marker
    savefilename=strcat(path,'\mrk\',files(i).name(1:end-4),'_filtered_exported_ICApruned_interpolated_rereferenced.sef.mrk');
    WriteMRK_univeral (MRKtot2(:,1), MRKtot2(:,3), savefilename, 1);
    
    %% SaveECG
    if strcmp(answer2,'Yes')
        ecgFileName=strcat(path,'\ECG\',files(i).name(1:end-4),'_ECG.eph');
        save_eph(ecgFileName,(ecg-mean(ecg))',SamplingRate,1); %to a reading for easey, I mean center the ECG
        WriteMRK_univeral (MRKtot2(:,1), MRKtot2(:,3), strcat(ecgFileName,'.mrk'), 1); %now we correct all the onset by 1 for Cartool
    end
    
    %il faudra filtrer a high-pass 0.5 Hz pour supprimer le drift. 

end
