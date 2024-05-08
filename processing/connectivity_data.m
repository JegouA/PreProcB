function ppb = connectivity_data(ppb)
% Compute functional connectivity on trials
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
% May 2024

progBar = waitbar(0, 'Functional connectivity in progress ...');

field = ppb.process.connectivity.outdata;
markerId = ppb.process.connectivity.timeMarker;
dat = ppb.process.epochs.results.(field).(markerId).data;
method = ppb.process.connectivity.method;

pat = lettersPattern;
switch method
    case 'cross-correlation'
        waitbar(0.1, progBar, 'please wait ...');
        nbrTrial = length(dat.trial);
        nbrChan = length(dat.label);
        connMat = cell(1, nbrTrial);
        avg = zeros(nbrChan, nbrChan);
        adv = 0.8/nbrTrial;
        for t=1:nbrTrial
            res = zeros(nbrChan, nbrChan);
            for i=1:nbrChan
                iElec = unique(extract(dat.label{i}, pat));
                for j= 1:nbrChan
                    jElec = unique(extract(dat.label{j}, pat));
                    if strcmp(iElec, jElec)
                        continue
                    end
                    [corr_coeff, lags] = xcorr(dat.trial{t}(i, :), dat.trial{t}(j, :), 'normalized');
                    [val, idx] = max(corr_coeff);
                    if lags(idx) == 0
                        res(i,j) = val;
                        res(j,i) = val;
                    elseif lags(idx) > 0
                        res(i,j) =  val;
                    elseif lags(idx) < 0
                        res(j,i) = val;
                    end
                end
            end
            connMat{t} = res;
            avg = avg + res;
            waitbar(0.1+ t*adv, progBar, 'please wait ...');
        end
        avg = avg ./ nbrTrial;
end
% Save data
data = struct();
data.label = dat.label';
data.avg = avg;
data.trial = connMat;

ppb.process.connectivity.results.(field).(markerId).data = data;
[path, file, ~] = fileparts(ppb.process.outdata.(field).filename);
filename = strcat(file, '_timelock-', markerId, '_connectivity.mat');
if ~isempty(ppb.emuDirPreprocessing)
    path = ppb.emuDirPreprocessing;
end
ppb.process.connectivity.results.(field).(markerId).filename = fullfile(path, filename);

if ~exist(ppb.process.connectivity.results.(field).(markerId).filename, 'file') || ...
            ppb.process.overwrite
    save(ppb.process.connectivity.results.(field).(markerId).filename , "data", '-v7.3');
else
    warndlg([filename " already exist. It won't be saved."], "Warning Files!");
end

waitbar(1, progBar, 'Done.');
close(progBar);
end
