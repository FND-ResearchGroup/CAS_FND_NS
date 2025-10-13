% Create MRK files from BDF files
% Programmed by Michael Mouthon

% Update: 04.2019
% =========================================================================
%
% createMRKfromBDF.m
%
% INPUTS
% - Folder containing the BDF files
%
% OUTPUTS
% - A Cartool MRK file for each BDF file.
%
% FUNCTION CALLED
% - open_bdf.m
%
% As simple as that...
%
%Modified by Michaël Mouthon in 2020 to be used with the BehaviourGNG_NPS.m
%script
%
% =========================================================================


%% Select files
% file are already in the workspace through variable filenameEEG and pathname




%% RETRIEVE EVENTS INFORMATION
    
MRKtimeframe = eventVector(:,1) - 1; % '-1' because in Cartool, 1st time-frame is 0
MRKname = eventVector(:,2);

% save data
disp(['writing marker file for ' openfilename]);
MRKfilename = char(strcat(openfilename,'.mrk'));
MRKfid = fopen(MRKfilename,'w');
fprintf(MRKfid,'%s\r\n','TL02'); % use \r\n for notepad (not notepad++)
fprintf(MRKfid,'%d\t%d\t%d\r\n',horzcat(MRKtimeframe,MRKtimeframe,MRKname)'); % use \r\n for notepad (not notepad++)
fclose(MRKfid);


