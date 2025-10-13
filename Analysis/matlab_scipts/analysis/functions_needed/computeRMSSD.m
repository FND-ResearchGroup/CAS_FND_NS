function rmssd = computeRMSSD(rr_intervals)
    % computeRMSSD computes the Root Mean Square of Successive Differences (RMSSD)
    % from a vector of RR intervals.
    %
    % Input:
    %   rr_intervals - A vector containing RR intervals (in milliseconds or seconds)
    %
    % Output:
    %   rmssd - The computed RMSSD value

    % Ensure the input is a column vector
    rr_intervals = rr_intervals(:);
    
    % Compute the successive differences between adjacent RR intervals
    successive_differences = diff(rr_intervals);
    
    % Square these differences
    squared_differences = successive_differences.^2;
    
    % Compute the mean of squared differences
    mean_squared_differences = mean(squared_differences);
    
    % Compute the square root of the mean
    rmssd = sqrt(mean_squared_differences);
end