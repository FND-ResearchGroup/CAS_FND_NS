function WriteAsynchVectorLABVIEW (events, MRKfilename)
    
    % save data
    MRKfid = fopen(MRKfilename,'w');
    for i=1:length(events)
        fprintf(MRKfid,'%d\t%d\t%d\t%d\t%d\t%d\r\n',events(i,1), events(i,2),events(i,3),events(i,4),events(i,5),events(i,6)); % use \r\n for notepad (not notepad++)
    end
    fclose(MRKfid);
    
end