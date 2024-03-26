function ppb = preprocess_seeg(ppb, saveWithoutBad)

% Preprocess the SEEG according to user decision, it includes High Pass
% filtering, Notch filter and bad channels
% Syntax:
%
% Inputs:
%       ppb                  - struct containing all the information for
%                              PreProcB to work
%       saveWithoutBad       - string, 'Yes' or 'No'
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
% February 2024

progBar = waitbar(0, 'Filtering in progress ...');
% Do the filtering
suffix = {};
seegData = ppb.seeg.data;
if ppb.preprocess.NF
    ppb.preprocess.data = ft_preproc_dftfilter(seegData, ppb.seeg.hdr.Fs, ppb.preprocess.NFvalue);
    seegData = ppb.preprocess.data;
    waitbar(0.3, progBar, 'Notch filtering is done.');
    suffix{end+1} = strcat('nf', num2str(ppb.preprocess.NFvalue));
end
if ppb.preprocess.HF
    ppb.preprocess.data =  ft_preproc_highpassfilter(seegData, ...
        ppb.seeg.hdr.Fs,  ppb.preprocess.HFvalue, [], 'firws');
    waitbar(0.6, progBar, 'High Pass filtering is done.');
    suffix{end+1} = strcat('hf', replace(num2str(ppb.preprocess.HFvalue), '.', ''));
end

% Save Bad Channels as txt file
[~, filename, ~] = fileparts(ppb.seeg.filename);
ppb.preprocess.badChannelsFilename = fullfile(ppb.emuDirPreprocessing, strcat(filename, '_badChannels.txt'));
if ~isempty(ppb.preprocess.badChannels)
    waitbar(0.8, progBar, 'Saving Bad Channels file ...');
    fid = fopen(ppb.preprocess.badChannelsFilename, 'w');
    for i = 1:length(ppb.preprocess.badChannels)
        fprintf(fid, '%s\n', ppb.preprocess.badChannels{i});
    end
    fclose(fid);
end

if isempty(ppb.preprocess.data)
    ppb.preprocess.data = ppb.seeg.data;
end

% New name of the edf file
if ~isempty(suffix)
    suffix = join(suffix, '_');
    ppb.preprocess.filename = fullfile(ppb.emuDirPreprocessing, ...
        strcat(filename, '_', suffix{1}, '.edf'));
else
    ppb.preprocess.filename = fullfile(ppb.emuDirPreprocessing, ...
        strcat(filename, '.edf'));
end

switch saveWithoutBad
    case 'Yes'
        [ppb.preprocess.hdr, ppb.preprocess.data] = save_as_edf(ppb.seeg.hdr, ppb.preprocess.data, ...
            ppb.preprocess.filename, ppb.preprocess.badChannels);
    case {'No', '', ' '}
        [ppb.preprocess.hdr, ppb.preprocess.data] = save_as_edf(ppb.seeg.hdr, ppb.preprocess.data, ...
            ppb.preprocess.filename);
end
waitbar(1, progBar, 'Preprocess is done.');
close(progBar);
end

