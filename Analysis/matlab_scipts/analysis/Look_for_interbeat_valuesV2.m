% Script to look at the interbeat
% 
% INPUT:  
% - Need recording an file (*.bdf) 
% 	-> The first ECG channel must be on the electrodes EXG1 and EXG2. During the recording, the operator has to ensure that the R-peak signal EXG1-EXG2 is positive. 
% 	-> The second ECG channel must be on the electrodes EXG3 and EXG4. During the recording, the operator has to ensure that the R-peak signal EXG3-EXG4 is positive.
% - Specify if the ecg detection must be performed on the ecg1 (EXG1-EXG2) or ecg2 (EXG3-EXG4). Warning: In the case of a CAS experiment recording, this is always the first option. 
% 
% OUTPUT
% Excel file with one sheet for individual values and one sheet with the summary values per files (mean, std, median, 1.4826*mad). Data were cleaned by removing R-peak overdetection (shorter than 453 ms).
%
% 18.12.2024
% Add of the computation of the RMSSD (Root mean square of successive RR
% interval differences) in summary table as explained in the paper https://pmc.ncbi.nlm.nih.gov/articles/PMC5624990/

%% Initialization
clear all
% Mapping the folder with the function used by this script
addpath(genpath('functions_needed')); %add path with sub-directories


%input EEG folder
path=uigetdir('R:\Experiments\Original Results\27 - Interoception\CAS\', 'Select folder which contains the raw bdf files');

%outputpile
[outputFile, outputPath] = uiputfile(strcat(path,'\Interpeak_distance.xlsx'),'Select the output file');

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
output=cell(size(files,1),1000); %on fait une matrice avec une toutes les valeur sur une ligne
outputALL=cell(size(files,1),4000); %on fait une matrice avec une toutes les valeur sur une ligne par participant
SummaryOutput=cell(size(files,1),6); %on fait un feuille avec le résumé de cette variabilité: mean, std, median, MAD
SummaryOutputALL=cell(size(files,1),6); %on fait un feuille avec le résumé de cette variabilité: mean, std, median, MAD par participant

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
    
    count=1;
    output{i,1}=files(i).name;
    
    for k=1:size(MRKtot,1)-1     
        if MRKtot(k,3)==1
            nextR=k+1;
            while MRKtot(nextR,3)~=1 %look for the R-peak before stim
                nextR=nextR+1;
                if nextR==size(MRKtot,1)+1 %safety for the end of the file
                    nextR=nextR-1;
                    break
                end
            end
            if (MRKtot(nextR,1)-MRKtot(k,1))*(1000/SamplingRate) >= 453 %remove overdetection values smaller than 453ms (=
                count=count+1; 
                output{i,count}=(MRKtot(nextR,1)-MRKtot(k,1))*(1000/SamplingRate); %compute the distance between stim and nextR R-peak, and convert in ms 
            end
        end
    end
    
    %compute summary
    SummaryOutput{i,1}=files(i).name;
    vecValues=cell2mat(output(i,2:end)); %put everything into a vector
    
    SummaryOutput{i,2}=mean(vecValues); %mean
    SummaryOutput{i,3}=std(vecValues); %std
    SummaryOutput{i,4}=median(vecValues); %median
    SummaryOutput{i,5}=mad(vecValues,1)*1.4826; %mad
    
    %compute the RMSSD
    SummaryOutput{i,6}=computeRMSSD(vecValues); %call the RMSSD function

    
    %ALL Participant data fusion 
    if ~strcmp(currentParticipant,files(i).folder(end-3:end)); %check if new participant
        %compute summary per participant
        SummaryOutputALL{currentParticipantIndice,1}=currentParticipant;
        vecValues=cell2mat(outputALL(currentParticipantIndice,2:end)); %put everything into a vector
        
        SummaryOutputALL{currentParticipantIndice,2}=mean(vecValues); %mean
        SummaryOutputALL{currentParticipantIndice,3}=std(vecValues); %std
        SummaryOutputALL{currentParticipantIndice,4}=median(vecValues); %median
        SummaryOutputALL{currentParticipantIndice,5}=mad(vecValues,1)*1.4826; %mad
        SummaryOutputALL{currentParticipantIndice,6}=computeRMSSD(vecValues); %compute RMSSD


        %new participant
        currentParticipantIndice=currentParticipantIndice+1;
        currentParticipant=files(i).folder(end-3:end);
        outputALL{currentParticipantIndice,1}=currentParticipant;

    end
    temp=horzcat(cell2mat(outputALL(currentParticipantIndice,2:end)), cell2mat(output(i,2:end)));
    outputALL(currentParticipantIndice,2:size(temp,2)+1)=num2cell(temp);


end

%save summary for last participant
SummaryOutputALL{currentParticipantIndice,1}=currentParticipant;
vecValues=cell2mat(outputALL(currentParticipantIndice,2:end)); %put everything into a vector

SummaryOutputALL{currentParticipantIndice,2}=mean(vecValues); %mean
SummaryOutputALL{currentParticipantIndice,3}=std(vecValues); %std
SummaryOutputALL{currentParticipantIndice,4}=median(vecValues); %median
SummaryOutputALL{currentParticipantIndice,5}=mad(vecValues,1)*1.4826; %mad
SummaryOutputALL{currentParticipantIndice,6}=computeRMSSD(vecValues); %compute RMSSD


%save output file
headerOutput=cell(1,1000); headerOutput{1,1}='filenames'; headerOutput{1,2}='Interpeak distance of the heart (in ms)';
headerSummary=cell(1,5);headerSummary{1,1}='filenames';headerSummary{1,2}='Mean';headerSummary{1,3}='Std';headerSummary{1,4}='Median';headerSummary{1,5}='MAD'; headerSummary{1,6}='RMSSD';

writecell([headerOutput;output],fullfile(outputPath,outputFile),'Sheet','All_data');
writecell([headerSummary;SummaryOutput],fullfile(outputPath,outputFile),'Sheet','Average values');

headerOutput=cell(1,4000); headerOutput{1,1}='filenames'; headerOutput{1,2}='Interpeak distance of the heart (in ms)';
writecell([headerOutput;outputALL],fullfile(outputPath,outputFile),'Sheet','All_data_per_participant');
writecell([headerSummary;SummaryOutputALL],fullfile(outputPath,outputFile),'Sheet','Average values_per_participant');
