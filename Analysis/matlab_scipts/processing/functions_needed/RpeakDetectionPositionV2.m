function [peakPositions, corrected, internalThreshold] = RpeakDetectionPositionV2(ecg,SamplingRate)
%   ECG PROCESSING DEMONSTRATION - R-PEAKS DETECTION
%   The package downloaded from http://www.librow.com
%   To contact the author of the sample write to Sergey Chernenko:
%   S.Chernenko@librow.com
%
%   The code is property of LIBROW
%   You can use it on your own
%   When utilizing credit LIBROW site
%
% Adaptation done by Michael Mouthon-16.04.2023
% output: 
% - peakPositions = vector which contains position of peaks
% - corrected = ECG signal high pass filtered which low frequency drift removed
%
% Modification to solve issue with filtred ECG signal amplitude - 31.08.2023
% In some recording, the ECG amplitude after filtering decrease over time.
% Then the variable position at line 44 don't contrains engouh values and
% the minimal distance between two peak will be too large (line65). It has
% for consequence to make crah the function ecgdemowinmax (line 69). To
% increase the chance to detect peak, I added an automatique exploration of
% the threshold with value between 4-1. A while loop test the thresholds and stop when it detected more than 10 peaks.  


%   Remove lower frequencies
fresult=fft(ecg);
fresult(1 : round(length(fresult)*5/SamplingRate))=0;
fresult(end - round(length(fresult)*5/SamplingRate) : end)=0;
corrected=real(ifft(fresult));

%% First pass for R peak detection (when heartbeat is unknown)
WinSize = floor(SamplingRate * 571 / 1000); %détermine la taille des EPOCH
if rem(WinSize,2)==0 %on veut que cette taille soit impair ! donc on corrige si cette valeur est pair
    WinSize = WinSize+1;
end
filtered1=ecgdemowinmax(corrected, WinSize);
%   Scale ecg
peaks1=filtered1/(max(filtered1)/7);
%   Filter by threshold filter
internalThreshold=5; %internalThreshold to test are 4,3,2,1 (4 is the default value proposed in LIBROW script)
positions=0;

while length(positions)<10 %special case where the filtred signal amplitude is not engouh big. Need to restart the detection with a smaller threshold
    internalThreshold=internalThreshold-1;
    peaks1b=peaks1;
    for k = 1:1:length(peaks1)
        if peaks1(k) < internalThreshold %original value was 4 but to conservative for some files. Need to decrease it. 
            peaks1b(k) = 0;
        else
            peaks1b(k)=1;
        end
    end
    positions=find(peaks1b); %vecteur qui contient la position des peak
end
peaks1=peaks1b;  
    

%% Deuxième partie-Optimisation du résultat en fonction du premier run.
distance=positions(2)-positions(1);
for k=1:1:length(positions)-1  %ICI il détermine quel est la plus petite distance entre deux peak (min de la distance entre deux peak
    if positions(k+1)-positions(k)<distance
        distance=positions(k+1)-positions(k);
    end
end

% Optimize filter window size
QRdistance=floor(0.04*SamplingRate);
if rem(QRdistance,2)==0 %modification pour que QRdistance soit impair
    QRdistance=QRdistance+1;
end
WinSize=2*distance-QRdistance;
% Filter - second pass
filtered2=ecgdemowinmax(corrected, WinSize);
peaks2=filtered2;
for k=1:1:length(peaks2)
    if peaks2(k)<internalThreshold %original value was 4 but to conservative for some files. Need to decrease it. 
        peaks2(k)=0;
    else
        peaks2(k)=1;
    end
end
peakPositions=find(peaks2); %position des peak pour la deuxième passe

    
end

