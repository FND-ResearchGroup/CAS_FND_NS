% Script to look if the omission modify the RR time
% 
% INPUT:  
% - Need recording an file (*.bdf) 
% 	-> The first ECG channel must be on the electrodes EXG1 and EXG2. During the recording, the operator has to ensure that the R-peak signal EXG1-EXG2 is positive. 
% 	-> The second ECG channel must be on the electrodes EXG3 and EXG4. During the recording, the operator has to ensure that the R-peak signal EXG3-EXG4 is positive.
% 
% OUTPUT
% -  Excel file with one sheet with the mean of RR distance around the omission (-1, 0, 1, ..., 10) for each participant. Data were cleaned by removing R-peak overdetection (shorter than 453 ms).
%
% Modification to take account the next R-peak instead of the previous one
% "Controlling for differences between ECG time-locked to R peaks
% during sound omission in synch vs async condition and whether sound omission induced changes of the heartbeat rhythm."
%
% 20.01.2025
% Extract 10 consecutive R peak after an omission and 1 R peak before it. 
% Split the these RR time interval across theses 12 intervals (-1 : one
% before, 0 : the R-peak closest from omission, 1-10: the ten R-peak after
% omission


%% Initialization
clear all
% Mapping the folder with the function used by this script
addpath(genpath('functions_needed')); %add path with sub-directories


%input EEG folder
path=uigetdir('R:\Experiments\Original Results\27 - Interoception\CAS\', 'Select folder which contains the raw bdf files');

%outputpile
[outputFile, outputPath] = uiputfile(strcat(path,'\Interpeak_distance_bins_separation.xlsx'),'Select the output file');

%tell which are the best ECG channel
% answer1=questdlg('Which is the best ECG channel in this file', 'EXG1-EXG2','EXG1-EXG2','EXG3-EXG4','EXG3-EXG4');
% if strcmp (answer1, 'EXG3-EXG4')
%     bestECGchannel=2;
% else
    bestECGchannel=1;
% end

%look for files
files=dir(strcat(path,'\*\*.bdf'));

%initialisation
output=cell(size(files,1),13); %on fait une matrice avec une toutes les valeur sur une ligne


% to store the intervals (nb of omission x nb of intervales)
bins= cell(300, 12); 

currentParticipant=files(1).folder(end-3:end);
currentParticipantIndice=1;
outputALL{1,1}=currentParticipant;

for i=1:size(files,1)
    %load EEG Data
    file=fullfile(files(i).folder,files(i).name);
    disp(file);
    [data,NumChan,ChanLabels,SamplingRate,~,eventVectorUnique]=open_bdf_modified(file); %open the recording file

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
    %EXG3=data(startData:endData,find(strcmp(ChanLabels, 'EXG3')==1))';
    %EXG4=data(startData:endData,find(strcmp(ChanLabels, 'EXG4')==1))';

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
    savefilename=strcat(file,'.mrk');

    %generate marker matrix with the trigger file
    [MRKbdf]=create_mrk_mic(savefilename,eventVectorUnique,0); %not correct the position now

    %generate marker matrix for R-peak detection
    MRKr_peak=horzcat(peakPositionsECG',peakPositionsECG',ones(length(peakPositionsECG),1));

    %concatenate both marker
    MRKtot=vertcat(MRKbdf, MRKr_peak);

    %sort this MRKtot
    MRKtot=sortrows(MRKtot,1);

    %% Compute the distance between R-peaks
    
    count=0;
    output{i,1}=files(i).name;
    
    RRvector=0;
    indiceRR=0;

    %compute RR distances
    for k=1:size(MRKtot,1)-1     
        if MRKtot(k,3)==1
            nextR=k+1;
            while MRKtot(nextR,3)~=1 %look for the next R-peak 
                nextR=nextR+1;
                if nextR==size(MRKtot,1)+1 %safety for the end of the file
                    nextR=nextR-1;
                    break
                end

            end
            if (MRKtot(nextR,1)-MRKtot(k,1))*(1000/SamplingRate) >= 453 %remove overdetection values smaller than 453ms (=
                count=count+1; 
                RRvector(count)=(MRKtot(nextR,1)-MRKtot(k,1))*(1000/SamplingRate); %compute the distance between stim and nextR R-peak, and convert in ms
                indiceRR(count)=k;
            end
        end
    end

    %look at the RR position around omission
    countRR=0;
    for k=1:size(MRKtot,1)-1
        if or(MRKtot(k,3)==6, MRKtot(k,3)==8)
            [~, closestIndex]=min(abs(indiceRR - k));
            countRR=countRR+1;
            bins{countRR,1} = RRvector(closestIndex-1); % bin -1
            bins{countRR,2} = RRvector(closestIndex); % bin 0 (omission)
            if closestIndex+1 <= length(indiceRR)
                bins{countRR,3} = RRvector(closestIndex+1); % bin 1
            end
            if closestIndex+2 <= length(indiceRR)
                bins{countRR,4} = RRvector(closestIndex+2); % bin 2
            end
            if closestIndex+3 <= length(indiceRR)
                bins{countRR,5} = RRvector(closestIndex+3); % bin 3
            end
            if closestIndex+4 <= length(indiceRR)
                bins{countRR,6} = RRvector(closestIndex+4); % bin 4
            end
            if closestIndex+5 <= length(indiceRR)
                bins{countRR,7} = RRvector(closestIndex+5); % bin 5
            end
            if closestIndex+6 <= length(indiceRR)
                bins{countRR,8} = RRvector(closestIndex+6); % bin 6
            end
            if closestIndex+7 <= length(indiceRR)
                bins{countRR,9} = RRvector(closestIndex+7); % bin 7
            end
            if closestIndex+8 <= length(indiceRR)
                bins{countRR,10} = RRvector(closestIndex+8); % bin 8
            end
            if closestIndex+9 <= length(indiceRR)
                bins{countRR,11} = RRvector(closestIndex+9); % bin 9
            end
            if closestIndex+10 <= length(indiceRR)
                bins{countRR,12} = RRvector(closestIndex+10); % bin 10
            end
        end
    end

    %compute output
    for z=1:12
        output{i,z+1}=median(cell2mat(bins(:,z)));
    end
    disp(num2str(i));
end

%save output file
headerOutput={'filenames','bin -1','bin 0','bin 1','bin 2','bin 3','bin 4','bin 5','bin 6','bin 7','bin 8','bin 9','bin 10'}; 
writecell([headerOutput;output],fullfile(outputPath,outputFile),'Sheet','All_data');

