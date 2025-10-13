function [stim] = experimentalConditionsRandomization(nbstim)
% Function to generate new randomisation of conditions
% Input: 
% - nbstim: Number of stimulation per experimental block
% Output:
% - stim : vector of n trials which define the random sucession of the
% condition between sound on (=1) or off (=0). 
%
% Author: Michael Mouthon, FND lab, University of Fribourg

nb0=round(0.2*nbstim); %20% os stim are no sound
nb1=nbstim-nb0; %80% os stim are no sound

stim=[zeros(1,nb0) ones(1,nb1)]; %vector of 500 stimuli with 20% no sound and 80% sound



%bloc of code randomise the condition and check if there is no consecutive
%0 in the randomisation as well as at first and last position
cond=true;
while cond
    stim=stim(randperm(length(stim))); %new randomization of the positions
    if stim(1)==0 & stim(2)==1 %change for the first one
        stim(1)=1;stim(2)=0;
    end
    if stim(end)==0 & stim(end-1)==1 %change for the last one
        stim(end)=1;stim(end-1)=0;
    end

    cond=false; 
    % check if there is three zeroes (0 0 0) consecutive. If it is the
    % case, redo a normalisation
    for i=2:length(stim)-1
        if stim(i-1)==0 & stim(i)==0 & stim(i+1)==0
            cond=true;
        end
    end
end

% When there is no more (0 0 0) this code permit to correct the (0 0) case
% in order to never have to consecutive 0
for i=2:length(stim)-1
    if stim(i-1)==0 & stim(i)==0
        temp=stim(i+1);stim(i+1)=stim(i);stim(i)=temp;
    end
end

  
    
    

    