function WriteMRK_HEPtask (events, trigger, MRKfilename)
    % write markers of the R-peak specifically for HEP analyses
    % Input: 
    % - events: Column Vector with the detected R-peak positions. Values in TF
    % - trigger: Column Vector of the size of the ECG with 0 or numerical
    % value send by the experimental computer during the recording. Details
    % about the signification of each value can by found below
    % - MRKfilename: String with the exact path and filename where to save
    % the .mrk file
    %
    % Output:
    % MRKfilename.mrk file with 
    % marker = 1 ==> heart condition R-peaks (between trigger 5 and 6)
    % marker = 2 ==> sound condition R-peaks (between trigger 7 and 8)
    % marker = 3 ==> ISI condition R-peaks (between trigger 9 and 10)
    % marker = 4 ==> R-peaks outside of these periods of interest
    %
    % Script Developped by Michaël Mouthon - 18.04.2023
    
               
    StartHeart=find(trigger==5);
    EndHeart=find(trigger==6);
    StartSound=find(trigger==7);
    EndSound=find(trigger==8);
    StartISI=find(trigger==9);
    EndISI=find(trigger==10);
    
    marker=zeros(length(events));
    
    if ~isempty(EndISI) %To be removed specific case of a Pilot1 file (could be remove for real data)
        
    if length(StartHeart)==10
        for i=1:length(events)
            e=events(i);
            if discretize(e,[StartHeart(1),EndHeart(1)])==1|discretize(e,[StartHeart(2),EndHeart(2)])==1| discretize(e,[StartHeart(3),EndHeart(3)])==1| discretize(e,[StartHeart(4),EndHeart(4)])==1| discretize(e,[StartHeart(5),EndHeart(5)])==1| discretize(e,[StartHeart(6),EndHeart(6)])==1|discretize(e,[StartHeart(7),EndHeart(7)])==1| discretize(e,[StartHeart(8),EndHeart(8)])==1| discretize(e,[StartHeart(9),EndHeart(9)])==1| discretize(e,[StartHeart(10),EndHeart(10)])==1
                marker(i)=1;
            elseif discretize(e,[StartSound(1),EndSound(1)])==1|discretize(e,[StartSound(2),EndSound(2)])==1| discretize(e,[StartSound(3),EndSound(3)])==1| discretize(e,[StartSound(4),EndSound(4)])==1| discretize(e,[StartSound(5),EndSound(5)])==1| discretize(e,[StartSound(6),EndSound(6)])==1|discretize(e,[StartSound(7),EndSound(7)])==1| discretize(e,[StartSound(8),EndSound(8)])==1| discretize(e,[StartSound(9),EndSound(9)])==1| discretize(e,[StartSound(10),EndSound(10)])==1
                marker(i)=2;
            elseif discretize(e,[StartISI(1),EndISI(1)])==1|discretize(e,[StartISI(2),EndISI(2)])==1| discretize(e,[StartISI(3),EndISI(3)])==1| discretize(e,[StartISI(4),EndISI(4)])==1| discretize(e,[StartISI(5),EndISI(5)])==1| discretize(e,[StartISI(6),EndISI(6)])==1|discretize(e,[StartISI(7),EndISI(7)])==1| discretize(e,[StartISI(8),EndISI(8)])==1| discretize(e,[StartISI(9),EndISI(9)])==1| discretize(e,[StartISI(10),EndISI(10)])==1|discretize(e,[StartISI(11),EndISI(11)])==1|discretize(e,[StartISI(12),EndISI(12)])==1|discretize(e,[StartISI(13),EndISI(13)])==1|discretize(e,[StartISI(14),EndISI(14)])==1|discretize(e,[StartISI(15),EndISI(15)])==1|discretize(e,[StartISI(16),EndISI(16)])==1|discretize(e,[StartISI(17),EndISI(17)])==1| discretize(e,[StartISI(18),EndISI(18)])==1|discretize(e,[StartISI(19),EndISI(19)])==1|discretize(e,[StartISI(20),EndISI(20)])==1
                marker(i)=3;
            else
                marker(i)=4;
            end        
        end
        
    else
        for i=1:length(events)
            e=events(i);
            if discretize(e,[StartHeart(1),EndHeart(1)])==1|discretize(e,[StartHeart(2),EndHeart(2)])==1| discretize(e,[StartHeart(3),EndHeart(3)])==1| discretize(e,[StartHeart(4),EndHeart(4)])==1| discretize(e,[StartHeart(5),EndHeart(5)])==1
                marker(i)=1;
            elseif discretize(e,[StartSound(1),EndSound(1)])==1|discretize(e,[StartSound(2),EndSound(2)])==1| discretize(e,[StartSound(3),EndSound(3)])==1| discretize(e,[StartSound(4),EndSound(4)])==1| discretize(e,[StartSound(5),EndSound(5)])==1
                marker(i)=2;
            elseif discretize(e,[StartISI(1),EndISI(1)])==1|discretize(e,[StartISI(2),EndISI(2)])==1| discretize(e,[StartISI(3),EndISI(3)])==1| discretize(e,[StartISI(4),EndISI(4)])==1| discretize(e,[StartISI(5),EndISI(5)])==1| discretize(e,[StartISI(6),EndISI(6)])==1|discretize(e,[StartISI(7),EndISI(7)])==1| discretize(e,[StartISI(8),EndISI(8)])==1| discretize(e,[StartISI(9),EndISI(9)])==1| discretize(e,[StartISI(10),EndISI(10)])==1
                marker(i)=3;
            else
                marker(i)=4;
            end        
        end
    end
    
    %write the marker
    MRKtimeframe = events - 1; % '-1' because in Cartool, 1st time-frame is 0      
    % save data
    disp('writing marker file');
    MRKfid = fopen(MRKfilename,'w');
    fprintf(MRKfid,'%s\r\n','TL02'); % use \r\n for notepad (not notepad++)
    for i=1:length(MRKtimeframe)
        fprintf(MRKfid,'%d\t%d\t%d\r\n',horzcat(MRKtimeframe(i),MRKtimeframe(i),marker(i))); % use \r\n for notepad (not notepad++)
    end
    fclose(MRKfid);
   
    
        
    else %specific case of a Pilot1 file (could be remove for real data)  
        MRKtimeframe = events - 1; % '-1' because in Cartool, 1st time-frame is 0      
        % save data
        disp('writing marker file');
        MRKfid = fopen(MRKfilename,'w');
        fprintf(MRKfid,'%s\r\n','TL02'); % use \r\n for notepad (not notepad++)
        for i=1:length(MRKtimeframe)
            fprintf(MRKfid,'%d\t%d\t%d\r\n',horzcat(MRKtimeframe(i),MRKtimeframe(i),i)); % use \r\n for notepad (not notepad++)
        end
        fclose(MRKfid);
    
end