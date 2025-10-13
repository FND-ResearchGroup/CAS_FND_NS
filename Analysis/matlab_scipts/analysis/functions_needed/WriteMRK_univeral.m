function WriteMRK_universal (onsets, events, MRKfilename, firstindex)
% INPUTS
% - 'onsets' is a vector which contain the onsets of each event
% - 'events' event or trigger code (must by a nummerical value
% - 'MRKfilename' is full saving path and name
% - (optional) 'firstindex' is the position index of the first time-frame
%   (0 or 1). Because Cartool counts time-frames starting from 0, if the
%   first index is 1, 1 will be removed from each event values. Any other
%   value will be refused, because it doesn't make any sense!
%   Default: 0
   
%% Check inputs
    if nargin == 4
        if ~isempty(firstindex) && (firstindex ~= 0 && firstindex ~= 1)
            error(['This input argument must be either empty, 0 (default), or 1. First index value entered: ' num2str(firstindex)]);
        end
        if isempty(firstindex)
            firstindex = 0; % if firstindex not definded, do not correct
        end
    else
        firstindex = 0; % if firstindex not definded, do not correct
    end

    if firstindex == 1
        MRKtimeframe = onsets - 1; % '-1' because in Cartool, 1st time-frame is 0 
    else 
        MRKtimeframe = onsets;
    end

    
    % save data
    disp('writing marker file');

    MRKfid = fopen(MRKfilename,'w');
    fprintf(MRKfid,'%s\r\n','TL02'); % use \r\n for notepad (not notepad++)
    for i=1:length(MRKtimeframe)
        fprintf(MRKfid,'%d\t%d\t%d\r\n',horzcat(MRKtimeframe(i),MRKtimeframe(i),events(i))); % use \r\n for notepad (not notepad++)
    end
    fclose(MRKfid);
    
end