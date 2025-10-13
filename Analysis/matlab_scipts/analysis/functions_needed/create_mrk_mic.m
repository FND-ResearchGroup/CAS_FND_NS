function [MRKmatrix]=create_mrk_mic(savefilename,eventVectorUnique,firstindex)

% Update: 10.2022
% =========================================================================
%
% Creates a Cartool markers file ('.mrk')
%
% Cartool: https://sites.google.com/site/cartoolcommunity/
%
%
%
% INPUTS
% - full saving path and name
% - 'events' is a 2D or 3D array
%   - onsets of each event are in column 1 (used as offset for a 2D array)
%   - offsets of each event are in column 2 of a 3D array
%   - the code of each event are in the last column
% - (optional) 'firstindex' is the position index of the first time-frame
%   (0 or 1). Because Cartool counts time-frames starting from 0, if the
%   first index is 1, 1 will be removed from each event values. Any other
%   value will be refused, because it doesn't make any sense!
%   Default: 0
%
% OUTPUTS
% Two case: 
% - if you enter a output argument, the script will only return the MRKmatrix without saving it.
% - if you don't put a output argument, it will save the mrkfile. 
%
% Author: Michael De Pretto (Michael.DePretto@unifr.ch)
%
% =========================================================================


%% Check inputs

if nargin == 3
    if ~isempty(firstindex) && (firstindex ~= 0 && firstindex ~= 1)
        error(['This input argument must be either empty, 0 (default), or 1. First index value entered: ' num2str(firstindex)]);
    end
    if isempty(firstindex)
        firstindex = 0; % if firstindex not definded, do not correct
    end
else
    firstindex = 0; % if firstindex not definded, do not correct
end

%compute the position of the trigger
onsets = find(eventVectorUnique~=0);

%compute name trigger
names = zeros(length(onsets),1);
for i=1:length(onsets)
    names(i)=eventVectorUnique(onsets(i));
end

%correct the origin
if firstindex == 1
    onsets=onsets-1;
end

if nargout ==1
    %case only output the MRK matrix without saving file
    MRKmatrix=horzcat(onsets, onsets, names);
else 
    %write mrk
    WriteMRK_univeral (onsets, names, savefilename, firstindex);
end

end