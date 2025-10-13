function WriteQualityCHeckMarker(peakDetected, RealpeakPositions, MRKfilename, startData2)
%Writing a marker file for the second selected file to check the
%performance of R peak detection for the real time
%marker=1 => For a real R-peak position detect by the Librow algorithm
%marker=2 => For a detect R-peak by the real time algorithm
%To look in Cartool, rename the file by removing the string
%'_qualityCheck'in the file name


%compute the correct position regarding the input file (correction due to
%the of the signal before the experiment start which is ignored
posReal=RealpeakPositions+ones(1,length(RealpeakPositions))*(startData2-1);
posDetected=peakDetected+ones(1,length(peakDetected))*(startData2-1);

markerReal=ones(length(RealpeakPositions),1);
markerDetect=ones(length(peakDetected),1)*2;

VectorPos=vertcat(posReal', posDetected');
VectorMarker=vertcat(markerReal, markerDetect);

%sort ascendant
[VectorPos, idx]=sort(VectorPos);
VectorMarker=VectorMarker(idx);

MRKtimeframe = VectorPos - 1; % '-1' because in Cartool, 1st time-frame is 0      
% save data
disp('writing marker file');
% MRKfilename = char(strcat(openfilename,'.mrk'));
MRKfid = fopen(MRKfilename,'w');
fprintf(MRKfid,'%s\r\n','TL02'); % use \r\n for notepad (not notepad++)
for i=1:length(MRKtimeframe)
    fprintf(MRKfid,'%d\t%d\t%d\r\n',horzcat(MRKtimeframe(i),MRKtimeframe(i),VectorMarker(i))); % use \r\n for notepad (not notepad++)
end
fclose(MRKfid);


end

