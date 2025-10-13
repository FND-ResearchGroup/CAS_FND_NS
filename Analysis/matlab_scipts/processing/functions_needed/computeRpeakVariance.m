function [meanVariance] = computeRpeakVariance(ECG,peakPositions,SamplingRate)
%compute the mean of the variance inside -50ms before R peaks. 
%Input:
% - ECG: raw ECG signal (don't need to be high-pass filtred because the slow drift won't impact so much the variance inside of 50 ms bin
% - peakPositions: Position of the R-peak detected by RpeakDetectionPosition.m script
% - SamplingRate : Sampling rate of the ECG signal
%
%Output:
% - meanVariance
%
% Script Developped by Michaël Mouthon - 18.04.2023


TF=round(0.05/(1/SamplingRate)); %number of timframe for 50 ms
varbefore=zeros(length(peakPositions)-2,1); %portion QR

for i=2:length(peakPositions)-1 %first and last R peak ignored 
    varbefore(i-1)=var(ECG(peakPositions(i)-TF:peakPositions(i)));
end

varbeforeNEW=cleanOutliersWithMAD(varbefore,2); %clean outlier median +/- 2*MAD

meanVariance=mean(varbeforeNEW);

