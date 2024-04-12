function num_windows = countWin(nsample,winlen,overlap)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% FUNCTION: countWin
% AUTHOR: Stephen Faul
% DATE: 30th April 2004
%
% DESCRIPTION: Returns the number of windows that will result
%             from windowing a data length with a window of a
%             particular size and overlap.
%
%         num_windows=number_of_windows(data_len,window_size,overlap)
%           
% INPUTS: nsample: length of input data
%         winlen: length of the window
%         overlap: how many samples one window overlaps the next by
%
% OUPUTS: num_windows: the number of windows that will result from the data and window
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
end_point=winlen;
start_point=1;
num_windows=0;
while end_point<=nsample
    num_windows=num_windows+1;
    start_point=start_point+(winlen-overlap);
    end_point=start_point+winlen-1;
end
    