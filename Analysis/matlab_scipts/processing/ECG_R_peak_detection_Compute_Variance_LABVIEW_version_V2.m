% Prepare the required files for the CAS experiment based on the HEP recording (R-peak detection threshold, experimental sucession) + Determine R-peak position to use in the HEP processing
% INPUT: 
% - Need recording file (*.bdf) of the HEP experiment (perform systematicaly before the CAS task). There is serveral requirements: 
% 	-> The first ECG channel must be on the electrodes EXG1 and EXG2. During the recording, the operator has to ensure that the R-peak signal EXG1-EXG2 is positive. 
% 	-> The second ECG channel must be on the electrodes EXG3 and EXG4. During the recording, the operator has to ensure that the R-peak signal EXG3-EXG4 is positive.
% 	-> The file contain the tiggers 5 (start heart block), 11 (middle of the recording), 12 (end of recording). These triggers will be used to split the recording in two part (first half learning phase, second half training phase). 
% - Enter the participant code which will be used for name the output file
% - A dialog box ask you if you want to save the marker file of the estimated position after training of the algo on the second half of the signal. This is not mandatory but only a quality check
% In addition, to be exectuded, the folder 'functions_needed' must be in the same path than the script.
% At the beginning of the code, you can change the number of stimulation expected for each CAS block (variable nbstim)
% 
% OUTPUT: In the same folder as the input '*.bdf' file, you will find these files:
% - 'logfile_*.txt' (* will be replace by the subject code you have choosen in second input): This file contain :
%  line2 -> the custom threshold to detect an R-peak. This value is used to detect R-peak in real time by the LABVIEW program "ActiView_InteroceptionProject_Task3.exe".
%  line3 -> the custom scaling compute during the training part of this script
%  line4 -> What is the best ECG channel between ECG1 or ECG2 based on R-peak amplitude
%  line 6-8 -> Mean Heart beat rate
%  line 9 -> internal threshold used for R-peak detection in the LIBROW script
% - 'CardioSynchExperimental_*.txt' (* will be replace by the subject code you have choosen in second input)
% This file define the experimental sucession for each trial. It will be loaded by the LABVIEW program "ActiView_InteroceptionProject_Task3.exe"
% The 4 first coloums are the randomize experimental succesion for the 4 blocks (20% nosound/80% sound). 
% The 2 last columns are the randomise inter R-peak interval of the participant used in the Asynch condition 
% - the Cartool marker file '*.mrk' (* is replace by the input bdf file name) which will permit the processing of the HEP data: 
% 	1: R-peak during heart beat block
% 	2: R-peak during sound block
% 	3: R-peak during Inter-stimulus rest period 
% 	4: R-peak during all other period (questions, evaluation, instruction)
% - the Cartool marker file '*_qualityCheckDetectionPart2.mrk' (* is replace by the input bdf file name). Generated only if you respond 'Yes' for the third input. 
% Permit to check the performance of realtime R-peak detection with best threshold. 
% 	1: R-peak detect by LIBROW script (ideal position)
% 	2: R-peak detect by the realtime detection (simulation during learning phase). 
%
% Author: Michael Mouthon, FND lab, University of Fribourg

% Versioning : modification pour généré la randomisation des conditions qui sera lu par
% 1.0: Full Matlab version (discontinued because timing issus)
% 2.0 : Labview/Actiview version
% 2.1 : Detection of R-peak on the full HEP length instead by splitting in
% two + Automatic adjustment of the internal threshold in the LIBROW script
% (detection R-peak), 31.08.2023


%% Initialization
clear all
% Mapping the folder with the function used by this script
addpath(genpath('functions_needed')); %add path with sub-directories

%number of stim required
nbstim=300; %nb de stim of one experimental bloc 300 by default

%input EEG files
[file,path]=uigetfile('*.bdf', 'Select the EEG/ECG recording file of one participant','MultiSelect','off','C:\EEG_data\FND_lab\Project_Interoception_2023\Interoception_HEP*.bdf');

participantCode=inputdlg('Enter the participant code','Participant code');%participant code for the output file name

answerQualityCheck = questdlg('Do you want to save a marker file with the estimated position for the second file (just for quality check)', ...
	'Quality check of R peak detection', ...
	'Yes','No','No');


%add the 29.08.2023 to take in count error due to recordings ECG recording
%with too small amplitude 
% InternalRthreshold=inputdlg('Internal threshold R-peak discrimination (1-4)','DONT CHANGE! Only if error message with the default',[1,80],{'4'}); 
% InternalRthreshold=str2num(InternalRthreshold{1});

[data,NumChan,ChanLabels,SamplingRate,~,trigger]=open_bdf(strcat(path, file)); %open the recording file

%NOT NEED ANYMORE
%Adjust value to have the same scaling as the data transmit to Matlab
%(factor determine during pilot, see comparaison_singal_Actiview_Matlab
%folder)
%data=data.*8192;
%

%set the begining of the experiment to ignore the signal before the
%experiment start (part of signal where the patient is suceptible to move)
temp=find(trigger==5); %first trigger 5 is the beginning of the experiment
startData=temp(1);
endData=find(trigger==11); %pause
startData2=temp(6);
endData2=find(trigger==12); %end recording

%Public variable
BestECGchannel=1;

%% Detection of the R peak for over all data 

%Extraction of each ECG channel
EXG1=data(:,find(strcmp(ChanLabels, 'EXG1')==1))';
EXG2=data(:,find(strcmp(ChanLabels, 'EXG2')==1))';
EXG3=data(:,find(strcmp(ChanLabels, 'EXG3')==1))';
EXG4=data(:,find(strcmp(ChanLabels, 'EXG4')==1))';

ecg1=EXG1-EXG2;
ecg2=EXG3-EXG4;

%detection of the R peaks for all           
[peakPositionsECG1, ecg1Filtered,internalThreshold1]=RpeakDetectionPositionV2(ecg1,SamplingRate);
[peakPositionsECG2, ecg2Filtered,internalThreshold2]=RpeakDetectionPositionV2(ecg2,SamplingRate);

%store the Rpeak amplitude (number of peak can be different between ecg1 and ecg2)
for i=1:length(peakPositionsECG1)
    peakAmplitudeECG1(i)=ecg1Filtered(peakPositionsECG1(i));
end
for i=1:length(peakPositionsECG2)
    peakAmplitudeECG2(i)=ecg2Filtered(peakPositionsECG2(i));
end

   
%% Determine which is the best ECG channel between the Channel1 or Channel2

% To determine which of the ECG channel is the best, we are going to look at
% which of channel 1 or 2 give the mean highest amplitude for the R-peak. 
% We first need to clean the amplitudes value by two different way:
% First, the amplitude are compute on the high-pass filtred ecg signal to
% remove the drift in the signal
% Second, outlier values are detected by computing the Median Absolute
% Deviation (MAD). Values outside of the confidance interval median +/-
% 2*MAD are removed from the final mean. 
AmplitudesChannel1NEW=cleanOutliersWithMAD(peakAmplitudeECG1,2);
AmplitudesChannel2NEW=cleanOutliersWithMAD(peakAmplitudeECG2,2);

%Determination of the best ECG channel
if mean(AmplitudesChannel1NEW)>=mean(AmplitudesChannel2NEW)
    BestECGchannel=1; %Best channels is EXG1-EXG2
else 
    BestECGchannel=2; %Best channels is EXG3-EXG4
end

%% Writing markers files for the best ECG channel
% Writing the position of R-peak detected for the best ECG channel. Will be
% used in the data processing of the HEP task

%correction of the position because we ignore the signal before the
%start of the experiment
if BestECGchannel==1
    mask=(peakPositionsECG1>startData)&(peakPositionsECG1<endData2); %extract indices between the begining and the end of the recording  
    pos=peakPositionsECG1(mask);
else
    mask=(peakPositionsECG2>startData)&(peakPositionsECG2<endData2); %extract indices between the begining and the end of the recording  
    pos=peakPositionsECG2(mask);
end

% Write peak position into MRK file for the original files
% I remove the first and last peak  because detection on boarder by filtering
% (as used in the script) are sometime wrong
outputfile=strcat(path,file,'.mrk');
WriteMRK_HEPtask(pos(2:end-1),trigger,outputfile); %on supprime le premier et dernier R-peak pour pas avoir de problème d'EPOCH


%% Write the task cardio-audio synch task Experimental sucession and asynch timing
%To ease the load of the parameters in Labview, I contatenate the Sucession
%file and asynch file in one. The four first colones are the sucessions
%(sound/slient) vector generate by Matlab
% Colones 5-6 are the random interpeak distance use in asynch condition


%step1: generate the sucession of each bloc
sucession=ones(nbstim,4);
for u=1:4
    sucession(:,u)=experimentalConditionsRandomization(nbstim);
end
    
%step2: compute the asych timing
if length(pos)>=nbstim
    kk=0;
    for k=2:length(pos) % compute the InterPeak distance
        kk=kk+1;
        InterPeakDistance(kk)=pos(k)-pos(k-1);
    end
    InterPeakDistance=InterPeakDistance(randperm(length(InterPeakDistance))); %shuffle the interpeak distance a first time
    asychVect1=InterPeakDistance(1:nbstim);
    InterPeakDistance=InterPeakDistance(randperm(length(InterPeakDistance))); %shuffle the interpeak distance a second time
    asychVect2=InterPeakDistance(1:nbstim);
else
    errordlg(strcat('There is not engough R-peak detected for asynch condition of the cardio-audio synch task (less than ',num2str(nbstim),')'),'Error for the asynch condition');
end
    
%step3: concatenate result and save the file
CardioSynchExperimental=horzcat(sucession,asychVect1', asychVect2');
WriteAsynchVectorLABVIEW(CardioSynchExperimental,strcat(path,'CardioSynchExperimental_',participantCode{1},'.txt'));


%% Learning: Compute de mean variance before R peaks

%initialisation of variable for learning (on first half of the ecg signal == part1)
if BestECGchannel==1
    ECG_part1=ecg1(startData:endData);
    mask=(peakPositionsECG1>startData)&(peakPositionsECG1<endData);
    peakPositions_part1=peakPositionsECG1(mask)-(startData-1); %peak relative to current interval
else
    ECG_part1=ecg2(startData:endData);
    mask=(peakPositionsECG2>startData)&(peakPositionsECG2<endData);
    peakPositions_part1=peakPositionsECG2(mask)-(startData-1); %peak relative to current interval
end

meanVariance=computeRpeakVariance(ECG_part1,peakPositions_part1,SamplingRate);
    
%% Training: compute the optimal threshold to detect the R-peaks (for real time detection)

%initialisation of variable for learning (on second half of the ecg signal == part2)
if BestECGchannel==1
    ECG_part2=ecg1(startData2:endData2);
    mask=(peakPositionsECG1>startData2)&(peakPositionsECG1<endData2);
    peakPositions_part2=peakPositionsECG1(mask)-(startData2-1); %peak relative to current interval
else
    ECG_part2=ecg2(startData2:endData2);
    mask=(peakPositionsECG2>startData2)&(peakPositionsECG2<endData2);
    peakPositions_part2=peakPositionsECG2(mask)-(startData2-1); %peak relative to current interval
end

%find the optimal threshold parameter to detect R-peak
[thresholdR,bestparameter,peakDetected]=trainingThresholdRpeak(meanVariance,ECG_part2,peakPositions_part2,SamplingRate);


if strcmp(answerQualityCheck,'Yes')
    outputQaulityCheck=strcat(path,file,'_qualityCheckDetectionPart2.mrk');
    WriteQualityCHeckMarker (peakDetected,peakPositions_part2,outputQaulityCheck, startData2);
end

%% Writing results of the machine learning in a text file
% The optimal R-peak detection threshold compute with this script will be
% store into a text file which will be loaded by the realtime detection
% task
% outputFinalfile=strcat(path,'Detection_threshold_',participantCode{1},'.txt');
% output = fopen(outputFinalfile,'w');
% fprintf(output,'%f',thresholdR);
% fclose(output);

%compute the mean hearbeat
rpmPart1=round((length(peakPositions_part1)/((endData-startData)*(1/SamplingRate)))*60);
rpmPart2=round((length(peakPositions_part2)/((endData2-startData2)*(1/SamplingRate)))*60);

%save log info for user
outputFinalfile=strcat(path,'logfile_',participantCode{1},'.txt');
output2 = fopen(outputFinalfile,'w');
fprintf(output2,'%s\t\t%s\r\n','Participant code:',participantCode{1}); %Participant code
fprintf(output2,'%s\t%f\r\n','R-peak detection threshold:',round(thresholdR)); %threshold
fprintf(output2,'%s\t%0.1f\r\n','Optimal % of the mean variance inside of 50ms pre-R peak interval:',bestparameter); %optimal threshold paramter
fprintf(output2,'%s\t%i\r\n','Best ECG channel used for the detection:',BestECGchannel); 
fprintf(output2,'%s\t%i\r\n','HeartBeat rate per minute(part1):',rpmPart1);
fprintf(output2,'%s\t%i\r\n','HeartBeat rate per minute(part2):',rpmPart2);
fprintf(output2,'%s\t%i\r\n','HeartBeat rate per minute(mean):',mean(rpmPart1,rpmPart2));
fprintf(output2,'%s\t%i\r\n','Internal Threshold used in LIBROW R-peak detection script for ECG channel 1:',internalThreshold1);
fprintf(output2,'%s\t%i\r\n','Internal Threshold used in LIBROW R-peak detection script for ECG channel 2:',internalThreshold2);
fprintf(output2,'%s\t\t%s\r\n','Date of the processing:',string(datetime("now")));

fclose(output2);

