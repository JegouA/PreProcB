function [psdvalue, avg, fval] = psdNormalize(data, hgval)

winlen = round(hgval*2);

% Number of window

ntrials = length(data.trial);
nchan = length(data.label);
psdvalue = cellfun(@(x) zeros(nchan, hgval+1), cell(1, ntrials), 'UniformOutput',false);

% start_parallel_computing;
avg = zeros(nchan, hgval +1);

fval = {1:hgval+1};
for c=1:nchan
    %psdBas = doPSD(baseline(c, :), winlen);
    for i=1:ntrials
        dat =  data.trial{i}(c, :);
        psdvalue{i}(c, :) = doPSD(dat, winlen);
        avg(c, :) = avg(c, :) + psdvalue{i}(c, :);
    end
    avg(c, :) = avg(c, :) ./ ntrials;
end

end

function mypsd_v1 = doPSD(dat, winlen)

overlap = round(winlen/2);
w = hamming(winlen);
nsample = length(dat);
num = countWin(nsample,winlen,overlap);
mypsd = zeros(winlen, num);
for n = 0:num-1
    temp = dat(1 ,1+overlap*n:winlen+n*overlap)'.*w;
    temp = fft(temp);
    % step 4: calculate the "periodogram" by taking the absolute value squared
    temp = abs(temp).^2;
    % save the results in the storage variable
    mypsd(:, n+1) = temp;
end
maxpsd = max(mypsd, [], 2);
mypsd_v1 = mean(mypsd,2);
mypsd_v1 = mypsd_v1./maxpsd;
% throw away the 2nd half of mypsd
mypsd_v1 = mypsd_v1(1:overlap+1);
% normalizing factor (dB/Hz)
mypsd_v1 = mypsd_v1/(winlen*sum(w.^2));
% ignore the DC and Nyquist value
mypsd_v1(2:end-1) = mypsd_v1(2:end-1) * 2;
end