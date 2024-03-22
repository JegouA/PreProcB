function ppb = process_seeg(ppb, progBar)

% Process the SEEG according to user decision, it includes filtering,
% downsampling and creation of the montage
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

% Create the directory to save output
ppb = create_results_dir(ppb, 'preprocessing', ppb.process.filename);

% Do the filtering part and save mat file for each, what happen if there is
% not filter dselected ???/
filterFields = fieldnames(ppb.process.filter);
nbr = length(filterFields);
if nbr == 0
    filterFields{end+1} = 'NoFilter';
    ppb.process.filter.NoFilter = [0,0];
    nbr=1;
end

wt=0;
if  nargin > 1
    waitbar(0.4, progBar, 'Processing ...');
    val = 0.6/nbr;
    wt =1;
end

for f=1:nbr
    rangeFreq = sort(ppb.process.filter.(filterFields{f}));
    if all(rangeFreq ~= 0)
        suffix = {strcat(lower(filterFields{f}), '-', num2str(rangeFreq(1)), ...
             '-', num2str(rangeFreq(2)))};
        try
            dat = ft_preproc_bandpassfilter(ppb.process.data, ppb.process.hdr.Fs, ...
                rangeFreq);
        catch
            dat = ft_preproc_bandpassfilter(ppb.process.data, ppb.process.hdr.Fs, ...
                rangeFreq, [], 'firws');
        end
    elseif strcmp(filterFields{f}, 'NoFilter')
        dat = ppb.process.data;
        suffix = {};
    else
        continue
    end

    % do the downsampling
    Fs = ppb.process.hdr.Fs;
    time = 1:ppb.process.hdr.nSamples;
    markers = ppb.process.markers;
    if ~isempty(ppb.process.downsample) && ppb.process.downsample < ppb.process.hdr.Fs
        Fs = ppb.process.downsample;
        [dat, ~, ~] = ft_preproc_resample(dat, ppb.process.hdr.Fs, ...
            ppb.process.downsample, 'downsample');
        time = 1:size(dat, 2);
        suffix{end+1} = strcat('downsample-', num2str(Fs));

        % Should rewrite the markers with the new downsample only
        modFs = ppb.process.hdr.Fs/ppb.process.downsample;
        markers.onset_sample = round(markers.onset_sample/modFs);
        markers.duration_sample = round(markers.duration_sample/modFs);

    end

    % Create the montage
    labels = ppb.process.hdr.label;
    if ~isempty(ppb.process.montage)
        [dat, labels] = create_montage(labels, dat, ppb.process.montage);
        suffix{end+1} = strcat('montage-', char(ppb.process.montage));
    end

    data = struct();
    data.label = labels;
    data.fsample = Fs;
    data.trial = {dat};
    % Put the time in sec
    if time(end) == length(time)
        time = time./Fs;
    end
    data.time = {time};

    % Write mat file, waiting for Steve to have the nomenclature
    [path, file, ~] = fileparts(ppb.process.filename);
    filename = strcat(file, '_', join(suffix, '_'), '.mat');
    if ~isempty(ppb.emuDirPreprocessing)
        path = ppb.emuDirPreprocessing;
    end
    
    ppb.process.outdata.(filterFields{f}) = data;
    ppb.process.outdata.(filterFields{f}).markers = markers;
    ppb.process.outdata.(filterFields{f}).filename = fullfile(path, filename{1});
    if ~exist(ppb.process.outdata.(filterFields{f}).filename, 'file') || ...
            ppb.process.overwrite
        save(ppb.process.outdata.(filterFields{f}).filename, "data", '-v7.3');
        % Save the markers
        markfile = replace(filename{1}, '.mat', '_markers.csv');
        writetable(ppb.process.outdata.(filterFields{f}).markers, ...
            fullfile(path, markfile));
    else
        warndlg([filename{1} " already exist. It won't be saved."], "Warning Files!");
    end

    if wt
        waitbar((0.4+val*f), progBar, 'Processing ...');
    end

end
if wt
    close(progBar);
end
end
