function ppb = frequency_data(ppb)

% Do the frequency analysis on the trials
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

% Psd can be done on the trials
progBar = waitbar(0, 'Time-Frequency in progress ...');

field = ppb.process.TF.outdata;
markerId = ppb.process.TF.timeMarker;
dat = ppb.process.epochs.results.(field).(markerId).data;
NormalizeVar = ppb.process.normalizeTF;
beg = [];
if NormalizeVar
    % get the signal to normalize (test)
    beg = ppb.process.markers.onset_seconds(1);
    dataAll = ppb.process.outdata.(field);
end
%To write the results
data = struct();
data.label = dat.label;
data.fsample = dat.fsample;

nsamp = length(dat.time);
nchan = length(dat.label);
% Check the highest freq is relevant with the size window
hgval = ppb.process.TF.mapHg;
if hgval > nsamp || hgval > dat.fsample || hgval == 0
    nval = min([round(nsamp/2) round(dat.fsample/2)]);
    hgval = nval;
    msgbox(sprintf("The highest frequency has been changed to %d Hz, to fit the constraint of the signal.", ...
        hgval));
end

% Check the lowest frequency
minfreq = ppb.process.outdata.(field).filtervalue(1);
if isempty(minfreq) || minfreq == 0
    minfreq =1;
end
% determine the band size
nband = 5;
dif = mod((hgval - minfreq),nband);
if dif~=0
    nband = (hgval - minfreq)/dif;
end

   
if nsamp < 2
    errordlg('The length of the signal is too small!')
    close(progBar);
    return
end
if ppb.process.TF.psd
    waitbar(0.2, progBar, 'PSD in progress ...');
    if NormalizeVar
        %%% PSD implented by me with normalization by maximum
        [psdvalue, avg, fvalue] = psdNormalize(dat, hgval);
    else
        %%% PSD with pwelch %%%
        if nsamp > dat.fsample
            window = dat.fsample;
        else
            window = nsamp;
        end
        noverlap = window/2;
        ntrials = size(dat.trial,2);
        psdvalue = cell(1, ntrials);
        fvalue = cell(1, ntrials);
        avg = zeros(nchan, round(noverlap)+1);
        for i=1:ntrials
            % channels have to be columns
            [pxx, f] = pwelch(dat.trial{i}', window, noverlap, window, ...
                dat.fsample);
            % To get a sort of norm WRONG have to do it by trials not by
            % channels
            % maxval = max(pxx);
            % psdvalue{i} = (pxx./maxval)';
            fvalue{i} = f;
            psdvalue{i} = pxx';
            t = 1:size(pxx, 1);
            avg(:,t) = avg(:,t) + psdvalue{i};
        end
        avg = avg./ntrials;
    end
    
    
    data.avgPSD = avg;
    data.trialPSD = psdvalue;
    data.fPSD = fvalue;
    
end

if ppb.process.TF.map
    waitbar(0.6, progBar, 'TFmap in progress ...');

    % For fieldtrip, I have to exchange the xtime and time that I changed
    % for bst
    tmpdat = dat;
    tmpdat.time = dat.xtime;
    tmpdat.xtime = dat.time;
    cfg =[];
    cfg.method = 'hilbert';
    cfg.output = 'pow';
    cfg.foi= minfreq:nband:hgval;
    cfg.toi = 'all';
    cfg.bpfilttype = 'firws';
    TFmap = ft_freqanalysis(cfg, tmpdat);
    TFmap.xtime = tmpdat.xtime;

    if NormalizeVar & beg >= 20
        %%% NORMALIZATION WORKING but to verify %%%
        % % Take only 1 min to do the baseline
        if beg > 60
            beg = 60*dataAll.fsample;
        else
            beg = beg*dataAll.fsample;
        end
        dataBase = [];
        dataBase.label = dataAll.label;
        dataBase.fsample = dataAll.fsample;
        dataBase.trial = cell(1,1);
        dataBase.time = cell(1,1);
        dataBase.trial{1} = dataAll.trial{1}(:,1:beg);
        dataBase.time{1} = dataAll.time{1}(1,1:beg);
        cfg =[];
        cfg.method = 'hilbert';
        cfg.output = 'pow';
        cfg.foi= minfreq:nband:hgval;
        cfg.toi = 'all';
        cfg.bpfilttype = 'firws';
        TFmapBase = ft_freqanalysis(cfg, dataBase);
    
        powspctrm = zeros(size(TFmap.powspctrm));
        for i=1:length(dataBase.label)
            tfSZ = squeeze(TFmap.powspctrm(i,:,:));
            tfBG = squeeze(TFmapBase.powspctrm(i,:,:));
            tfNorm = zSOI_normalisation(tfSZ, tfBG);
            powspctrm(i,:,:) = tfNorm;
        end
        TFmap.powspctrm = powspctrm;
    end

    data.TFmap = TFmap;
end

% save
waitbar(0.8, progBar, 'Writing results ...');
ppb.process.TF.results.(field).(markerId).data = data;

[path, file, ~] = fileparts(ppb.process.outdata.(field).filename);
filename = strcat(file, '_timelock-', markerId, '_frequency.mat');
if ~isempty(ppb.emuDirPreprocessing)
    path = ppb.emuDirPreprocessing;
end
ppb.process.TF.results.(field).(markerId).filename = fullfile(path, filename);

if ~exist(ppb.process.TF.results.(field).(markerId).filename, 'file') || ...
            ppb.process.overwrite
    save(ppb.process.TF.results.(field).(markerId).filename , "data", '-v7.3');
else
    warndlg([filename " already exist. It won't be saved."], "Warning Files!");
end

waitbar(1, progBar, 'Done.');
close(progBar);
end

