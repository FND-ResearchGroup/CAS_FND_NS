function [outputVector] = cleanOutliersWithMAD(inputVector, confidanceIntervalBorderFactor)
% The purpose of this script is to remove outliers from a vector of values.
% To perform this task, the value outside of the confidence interval
% [median-confidanceIntervalBorderFactor*MAD,median+confidanceIntervalBorderFactor*MAD].
% MAD is the Median absolute Deviation. It computation is based on the
%following article: https://www.sciencedirect.com/science/article/pii/S0022103113000668
%This indice is to be better than the standard deviation because it is
%less sensible to outlier. The script assume that the data approximatively normaly distribute. 
%
% Input: a numerical single dimension vector
% Output: input vector cleaned with outlier removed

%% compute MAD
k=1.4826; %assumption to have a normal distribution

MedianData=median(inputVector);
sizedata=length(inputVector);

diffMed=zeros(sizedata,1);

for i=1:sizedata
    diffMed(i)=abs(inputVector(i)-MedianData);
end

mad=k*median(diffMed);


%% Compute borders of the confidance interval
uplimit=MedianData+confidanceIntervalBorderFactor*mad; %for exemple medan+/-2*mad
downlimit=MedianData-confidanceIntervalBorderFactor*mad;

%% Outlier removal
outputVector=0;
nb=0;
for i=1:length(inputVector)
    if and(inputVector(i)<uplimit, inputVector(i)>downlimit)
        nb=nb+1;
        outputVector(nb)=inputVector(i);
    end    
end

