function ppb = epochs_data(ppb)

% Epoch data according to the user selection
% Syntax:
%
% Inputs:
%       ppb                  - struct containing all the information for
%                              PreProcB to work
%
% Outputs:
%       - ppb
%
% Copyright (C) 2024 Cortycal System Laboratory (CorsyLab)
%
% Author:
%       Aude Jegou
%
% License:
%     PreProcB is free software: you can redistribute it and/or modify
%     it under the terms of the GNU General Public License as published by
%     the Free Software Foundation, either version 3 of the License, or
%     (at your option) any later version.
%
%     PreProcB is distributed in the hope that it will be useful,
%     but WITHOUT ANY WARRANTY; without even the implied warranty of
%     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%     GNU General Public License for more details.
%
%     You should have received a copy of the GNU General Public License
%     along with this program.  If not, see <https://www.gnu.org/licenses/>.
%
% March 2024

progBar = waitbar(0, 'Epoching in progress ...');

field = ppb.process.epochs.outdata;
markerId = ppb.process.epochs.timeMarker;
before = ppb.process.epochs.timeBefore * 0.001;
after = ppb.process.epochs.timeAfter *0.001;
doAvg = ppb.process.epochs.average;

dat = ppb.process.outdata.(field).trial{1};
[nchan, nSamples] = size(dat);
Fs = ppb.process.outdata.(field).fsample;
% Do Normalization
if ppb.process.normalize == 1
    beg = round(ppb.process.markers.onset_seconds(1) * Fs);
    mu = mean(dat(:, 1:beg), 2);
    sigma = std (dat(:, 1:beg), [] ,2);
    dat = dat - mu;
    dat = bsxfun(@rdivide, dat, sigma);
end

% First Select the markers in the table
waitbar(0.2, progBar, 'Reading trials ...');
idMarkers = find(strcmp(ppb.process.markers.name, markerId));
ntrials = length(idMarkers);
trials = cell(1, ntrials);
times = cell(1, ntrials);
timesOnset = cell(1, ntrials);
timeSec = 1/Fs:1/Fs:nSamples/Fs;

% Go through all trials
a=1;
xtime = 0-before:1/Fs:0+after;
avg = zeros(nchan, length(xtime));
waitbar(0.4, progBar, 'Extracting trials ...');
for i=idMarkers'
    time = ppb.process.markers.onset_seconds(i);
    times{a} = time-before:1/Fs:time+after;
    [~, timesOnset{a}] = arrayfun(@(x) min(abs(timeSec - x)), times{a});
    trials{a} = dat(:, timesOnset{a});
    if doAvg
        avg = avg + trials{a};
    end
    a=a+1;
end
if doAvg
    waitbar(0.9, progBar, 'Averaging trials ...');
    avg = avg ./ ntrials;
end

data = struct();
data.label = ppb.process.outdata.(field).label;
data.fsample = Fs;
data.trial = trials;
data.time = times;
data.timeOnset = timesOnset;
data.xtime = xtime;
data.avg = avg;

ppb.process.epochs.results.(field).(markerId).data = data;
waitbar(0.95, progBar, 'Writing results ...');

[path, file, ~] = fileparts(ppb.process.outdata.(field).filename);
filename = strcat(file, '_timelock-', markerId, '_epochs.mat');
if ~isempty(ppb.emuDirPreprocessing)
    path = ppb.emuDirPreprocessing;
end
ppb.process.epochs.results.(field).(markerId).filename = fullfile(path, filename);
if ~exist(ppb.process.epochs.results.(field).(markerId).filename, 'file') || ...
            ppb.process.overwrite
    save(ppb.process.epochs.results.(field).(markerId).filename , "data", '-v7.3');
else
    warndlg([filename " already exist. It won't be saved."], "Warning Files!");
end

waitbar(1, progBar, 'Done.');
close(progBar);