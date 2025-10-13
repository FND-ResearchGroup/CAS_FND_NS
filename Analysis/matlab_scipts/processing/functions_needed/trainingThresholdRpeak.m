function [thresholdR,bestparameter,peakDetected] = trainingThresholdRpeak(MeanVarianceQRS,ECG,RealpeakPositions,SamplingRate)
% ECG Realtime - R-PEAKS DETECTION
%
% This script simulate the R-peak real time detection based on the method from the paper: https://pubmed.ncbi.nlm.nih.gov/29093486/
% Then it compare the result with the real R-peak (determine by
% www.librow.com algorithm -script RpeakDetectionPosition.m) to determine
% the optimal threshold to minimize the distance between real peak and
% detected peak. 
% Input: 
% - MeanVarianceQRS : Mean variance in 50ms bin before real R-peak (value
% compute by the script computeRpeakVariance.m)
% - ECG: ECG signal for R-peak detection (should not by the same portion as used
% in computeRpeakVariance.m script)
% - RealpeakPositions: position of the R-peak detected by
% RpeakDetectionPosition.m for this portion of ECG 
% - SamplingRate: Sampling rate of the ECG signal
%
% Ouput:
% - thresholdR: The optimal value to be used as threshold in the real time
% R-peak detection.
% - bestparameter: the % of the MeanVarianceQRS used as optimal threshold
% - peakDetected: Vector of the R-peak detected with the optimal threshold
%
% Notes:
% No High-pass filter is applied for the realtime detection because it is
% beased on 50ms bin. It is a very sort period of time and slow frequency
% drift do not impact the result of the variance caculation inside of the
% bin. 
%
% Script Developped by Michaël Mouthon - 18.04.2023

%Initialisation
[~,TFmax]=size(ECG);
cooldownPeriod=round(0.2/(1/SamplingRate));%cooldown of 200ms after peak detection to avoid a new detection of the same peak (correspond to a maximal heartbeat of 300 per minute)  
WinSize=round(0.05/(1/SamplingRate)); %The windows size of 50ms according the article Pfeiffer & De Lucia (2017)
ValuesToTest=[0.3,0.4,0.5,0.6,0.7,0.8,0.9,1];
diff=[0,0,0,0,0,0,0,0];
ShitHappened=[0,0,0,0,0,0,0,0];
if RealpeakPositions(1)<WinSize+1 %remove the first peak if smaller than the windows detection size (otherwise it could conduct to a missmatch between RealpeakPositions and peakDetected) !
    RealpeakPositions=RealpeakPositions(2:end);
end
if RealpeakPositions(end)>TFmax-50 %remove the last peak if bigger than the windows detection size (otherwise it could conduct to a missmatch between RealpeakPositions and peakDetected) !
    RealpeakPositions=RealpeakPositions(1:end-1);
end

%% Compute the best Threshold parameter for R-peak detection
for k=1:length(ValuesToTest)
    threshold=MeanVarianceQRS*ValuesToTest(k);
    lastPeak=-cooldownPeriod; %permits the detection in the first 50-200ms
    n=0;
    peakDetected=0;
    
    %R-peak detection
    for i=1:8:TFmax %temporal jump of 8 TF to simulate the realTime arrival of data by packages of 8 TF every 7.84ms
        if i>WinSize+1 & i>lastPeak+cooldownPeriod & i<TFmax-WinSize  %i = indice in TF should be in the interval [WinSize,end-WinSize] and not consider 200ms after a peak detection
            % Clear our variables (more fast than use the clear function because don't need memory reallocation)
            ecgBin=zeros(1,WinSize);

            %Extraction of the 50ms bin
            ecgBin=ECG(i-WinSize:i); %Compute ECG       

            %detection of R peak
            if var(ecgBin)>threshold
                 lastPeak=i;
                 n=n+1;
                 peakDetected(n)=i;
            end
        end
    end
    %compute the difference between detected peak and real R peak position
    if n==length(RealpeakPositions)
        diff(k)=mean(abs(RealpeakPositions-peakDetected)); %compute the mean distance between the real peak and the detected peak
    else
        %The case of unequal number of peakDetected and RealpeakPositions is very tricky.
        %I write a code to match the elements. I look at the corresponding position of peakDetected to the RealpeakPositions 
        %by searching the minimal distance of each elements of these two vectors. 
        % However, I hope that it would not needed.
        % n=number of peak detected    
        diffDetectReal=0;
        for y=1:n
            diffTemp=0; %look at the minimal distance for every elements to guess its position
            for z=1:length(RealpeakPositions)
                diffTemp(z)=abs(peakDetected(y)-RealpeakPositions(z));
            end
            diffDetectReal(y)=min(diffTemp);
        end
        diff(k)=mean(diffDetectReal);
        ShitHappened(k)=1;
    end
    
end

%save the optimal result
bestparameterIndice=find(diff==min(diff));
bestparameter=ValuesToTest(bestparameterIndice);
thresholdR=MeanVarianceQRS*bestparameter;

if ShitHappened(bestparameterIndice)==1
    f = errordlg('The optimal parameter has been found in a situation where there were not the same number of peak detected by the machine in comparision to real peak (detection with Librow algorithm). The script has to guess the correspondance position btween the two vectors. Look carfully to the results of the real time R-peak detection with this threshold because it might be wrong.');
end


%% Re-compute the best peak positions (usefull for quality check but not necessary for the machine learning training) 
lastPeak=-cooldownPeriod; %permits the detection in the first 50-200ms;
n=0;
peakDetected=0; 
for i=1:8:TFmax %temporal jump of 8 TF to simulate the realTime arrival of data by packages of 8 TF every 7.84ms
    if and(i>WinSize+1,i>lastPeak+cooldownPeriod)  
        % Clear our variables (more fast than use the clear function because don't need memory reallocation)
        ecgBin=zeros(1,WinSize);

        %Extraction of the 50ms bin
        ecgBin=ECG(i-WinSize:i); %Compute ECG       

        %detection of R peak
        if var(ecgBin)>thresholdR
             lastPeak=i;
             n=n+1;
             peakDetected(n)=i;
        end
    end
end
   


end
    

