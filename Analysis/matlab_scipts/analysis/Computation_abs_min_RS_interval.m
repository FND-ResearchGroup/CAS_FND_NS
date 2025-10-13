% Script to look min RS distance in the sound trial = distance R-peak
% before a SOUND which could be before or after
% 
% INPUT:  
% - Need recording an file (*.bdf) 
% 	-> The first ECG channel must be on the electrodes EXG1 and EXG2. During the recording, the operator has to ensure that the R-peak signal EXG1-EXG2 is positive. 
% 
% OUTPUT
% - Excel file with one sheet for individual values and one sheet with the
% summary values per files (mean, std, median, 1.4826*mad)
% Cleaning R-peak overdetection (shorter than 453 ms)
%
% Michaël Mouthon - 27.01.2025

%% Initialization
clear all
% Mapping the folder with the function used by this script
addpath(genpath('functions_needed')); %add path with sub-directories


%input EEG folder
path=uigetdir('D:\AYBEK_DATA\projet_EEG\Interoception_Project_NS_2023\data\CAS\raw_data\', 'Select folder which contains the raw bdf files');

%outputpile
[outputFile, outputPath] = uiputfile(strcat(path,'\min_abs_RS_sound_intervals.xlsx'),'Select the output file');

%look for files
files=dir(strcat(path,'\*\*.bdf'));

%initialisation
output=cell(size(files,1),1000); %on fait une matrice avec une toutes les valeur sur une ligne
SummaryOutput=cell(size(files,1),5); %on fait un feuille avec le résumé de cette variabilité: mean, std, median, MAD

summaryCount=0;
vecValues=[];

for i=166:size(files,1)
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
    % EXG3=data(startData:endData,find(strcmp(ChanLabels, 'EXG3')==1))';
    % EXG4=data(startData:endData,find(strcmp(ChanLabels, 'EXG4')==1))';

    
    ecg=EXG1-EXG2; 


    %% R-peak detection

    %detection of the R peaks            
    [peakPositionsECG, ecg1Filtered]=RpeakDetectionPositionV2(ecg,SamplingRate);

    %cleaning of R-peak overdetection (smaller than 453 ms = 928 TF)
    countclean=0;
    for z=2:length(peakPositionsECG)
        if peakPositionsECG(z)-peakPositionsECG(z-1) >= 928
            countclean=countclean+1;
            peakPositionsECGclean(countclean)=peakPositionsECG(z);
        end
    end

    
    %% Create the mrk which combine the eeg file trigger and R-peak marker (=1)
    savefilename=strcat(file,'.mrk');

    %generate marker matrix with the trigger file
    [MRKbdf]=create_mrk_mic(savefilename,eventVectorUnique,0); %not correct the position now

    %generate marker matrix for R-peak detection
    MRKr_peak=horzcat(peakPositionsECGclean',peakPositionsECGclean',ones(length(peakPositionsECGclean),1));

    %concatenate both marker
    MRKtot=vertcat(MRKbdf, MRKr_peak);

    %sort this MRKtot
    MRKtot=sortrows(MRKtot,1);

    %% Compute the distance between R-peak and Sound
    
    count=1;
    output{i,1}=files(i).name;
    
    for k=1:size(MRKtot,1)-1        
            if or(MRKtot(k,3)==5,MRKtot(k,3)==7) %sound                
                count=count+1; 
                nextR=k+1; %look at next R               
                while MRKtot(nextR,3)~=1 %look for the R-peak before stim
                    nextR=nextR+1;
                    if nextR==size(MRKtot,1) %safety for the end of the file                    
                        break
                    end                    
                end
                previousR=k-1; %look at previous R
                while MRKtot(previousR,3)~=1 %look for the R-peak before stim
                    previousR=previousR-1;
                    if previousR==1 %safety for the end of the file                    
                        break
                    end                    
                end
                currentValue=min(abs(MRKtot(nextR,1)-MRKtot(k,1)), abs(MRKtot(k,1)-MRKtot(previousR,1)));
                output{i,count}= currentValue*(1000/SamplingRate); %compute the distance between stim and previousR R-peak, and convert in ms 
            end             
    end
    
    %compute summary
    if mod(i,2)==0 %concatenation per participant and conditions
        summaryCount=summaryCount+1;
    
        SummaryOutput{summaryCount,1}=files(i).name;
        vecValues=[vecValues,cell2mat(output(i,2:end))]; %put everything into a vector
        
        SummaryOutput{summaryCount,2}=mean(vecValues); %mean
        SummaryOutput{summaryCount,3}=std(vecValues); %std
        SummaryOutput{summaryCount,4}=median(vecValues); %median
        SummaryOutput{summaryCount,5}=1.4826*mad(vecValues,1); %mad
    else
        vecValues=cell2mat(output(i,2:end));
    end
    

end

%save output file
headerOutput=cell(1,size(output,2)); headerOutput{1,1}='filenames'; headerOutput{1,2}='SR-interval = first R-peak in the omission period (=distance between omission and the following R-peak) (in ms)';
headerSummary=cell(1,5);headerSummary{1,1}='filenames';headerSummary{1,2}='Mean';headerSummary{1,3}='Std';headerSummary{1,4}='Median';headerSummary{1,5}='MAD';

writecell([headerOutput;output],fullfile(outputPath,outputFile),'Sheet','All_data');
writecell([headerSummary;SummaryOutput],fullfile(outputPath,outputFile),'Sheet','Average values');
