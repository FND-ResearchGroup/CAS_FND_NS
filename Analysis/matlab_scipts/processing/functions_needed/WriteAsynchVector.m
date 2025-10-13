function WriteAsynchVector (events, MRKfilename)
    
    % save data
    MRKfid = fopen(MRKfilename,'w');
    for i=1:length(events)
        fprintf(MRKfid,'%d\r\n',events(i)); % use \r\n for notepad (not notepad++)
    end
    fclose(MRKfid);
    
end