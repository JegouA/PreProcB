function varargout = concatenate_data(SEEGfile, ppb)

% Concatenate the data according to the order given by the user
% Syntax:
%
% Inputs:
%       SEEGfile             - cell of SEEG files, if multiple concatenate
%       ppb                  - struct containing all the information for
%                              PreProcB to work
%
% Outputs:
%       - varargout - provide ppb updated
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
% January 2024

% Create small window to call to specify the order
% call the interface for the user to interact
myapp = concatenate(SEEGfile);
while myapp.done == 0
    pause(0.05)
end
if myapp.done == 2
    errordlg(["Concatenate window has been closed without change, " + ...
        "concatenation is aborted !!!"]);
    myapp.closeWindow;
    varargout{1} = ppb;
    return
end
% Get SEEG order
SEEGfile = myapp.SEEGfile;
myapp.closeWindow;
fbar = waitbar(0, 'Please wait ...');
% Do the concatenation, but have to check for the
% sampling rate and do it by channels
% Get the order of the files
orderSEEG = sortrows(SEEGfile, 4);
% Do 1st file as reference
hdrreference = ft_read_header(orderSEEG{1,1});
% Check if want a specific time
if orderSEEG{1, 5} == 0
    begsample = 1;
else
    begsample = orderSEEG{1, 5} * hdrreference.Fs;
    if begsample > hdrreference.nSamples || begsample < 1
        errordlg(["The selected Start for " orderSEEG{1,1} " is not correct"])
        ppb = concatenate_data(SEEGfile, ppb);
        varargout{1} = ppb;
        return
    end
end
if orderSEEG{1, 6} == 0
    endsample = hdrreference.nSamples;
else
    endsample = orderSEEG{1, 6} * hdrreference.Fs;
    if endsample > hdrreference.nSamples || endsample < begsample
        errordlg(["The selected End for " orderSEEG{1,1} " is not correct"])
        ppb = concatenate_data(SEEGfile, ppb);
        varargout{1} = ppb;
        return
    end
end
idnotTrig = (~strcmp(hdrreference.chantype, 'trigger'));
chanref = hdrreference.label(idnotTrig);
dat = ft_read_data(orderSEEG{1,1}, 'begsample', begsample, ...
    'endsample', endsample);
% Find the trigger ref
idTrigref = (strcmp(hdrreference.label, orderSEEG{1, 7}));
dattrigRef = dat(idTrigref, :);
datreference = dat(idnotTrig, :);
evtreference =  ft_read_event(orderSEEG{1,1});
evtreference = evtreference(:, [evtreference.sample] >=begsample & [evtreference.sample] <= endsample);
hdrreference.nSamples = size(datreference, 2);
% Update the fbar
nfiles = size(orderSEEG, 1);
ntim = 0.9/nfiles;
waitbar(ntim, fbar, 'First file has been processed.')

% Save differently the data because not the same channels
datCell = cell(nfiles, 2);
datCell{1,1} = datreference;
datCell{1,2} = chanref;
% Loop on the other files to add them
for f=2:nfiles
    lastSample = size(datreference, 2);
    hdr = ft_read_header(orderSEEG{f, 1});
    if hdr.Fs ~= hdrreference.Fs
        errordlg(["The file " orderSEEG{f, 1} ...
            " doesn't have the same sampling frequency that the first one."])
        varargout{1} = ppb;
        return
    end
    % get the data 
    if orderSEEG{f, 5} == 0
        begsample = 1;
    else
        begsample = orderSEEG{f, 5} * hdr.Fs;
        if begsample > hdr.nSamples || begsample < 1
            errordlg(["The selected Start for " orderSEEG{f,1} " is not correct."])
            ppb = concatenate_data(SEEGfile, ppb);
            varargout{1} = ppb;
            return
        end
    end
    if orderSEEG{f, 6} == 0
        endsample = hdr.nSamples;
    else
        endsample = orderSEEG{f, 6} * hdr.Fs;
        if endsample > hdr.nSamples || endsample < begsample
            errordlg(["The selected End for " orderSEEG{f,1} " is not correct."])
            ppb = concatenate_data(SEEGfile, ppb);
            varargout{1} = ppb;
            return
        end
    end
    dat = ft_read_data(orderSEEG{f,1}, 'begsample', begsample, ...
        'endsample', endsample);
    % No change take all the channels except trig and then I will take the
    % commom
    idchannel = (~strcmp(hdr.chantype, 'trigger'));
    datCell{f,1} = dat(idchannel, :);
    datCell{f,2} = hdr.label(idchannel);

    evt =  ft_read_event(orderSEEG{f,1});
    evt = evt(:, [evt.sample] >=begsample & [evt.sample] <= endsample);
    for i=1:length(evt)
        evt(i).sample = evt(i).sample + lastSample;
        evt(i).timestamp = evt(i).timestamp + lastSample/hdrreference.Fs;
    end
    evtreference = cat(2, evtreference, evt);
    idTrig = (strcmp(hdr.label, orderSEEG{f, 7}));
    dattrig = dat(idTrig, :);
    dattrigRef = cat(2, dattrigRef, dattrig);
    waitbar(ntim*f, fbar, sprintf('File %d  has been processed.', f))
end
% According to the channels
chanCom = intersect(datCell{:,2});
hdrft = hdrreference;
hdrft.nChans = size(chanCom, 1);
hdrft.chantype = repmat({'unknown'}, hdrft.nChans, 1);
hdrft.chanunit = repmat({'unknown'}, hdrft.nChans, 1);
% Get the final dtaa
datFinal = [];
for f=1:nfiles
    idchannel = cellfun(@(x) find(strcmp(x, datCell{f, 2})), chanCom, 'UniformOutput',false);
    idchannel = cell2mat(idchannel);
    datFinal = cat(2, datFinal, datCell{f, 1}(idchannel, :));
    if f == 1
        % Have to create the label for hdrft
        hdrft.label = datCell{f, 2}(idchannel);
    end
end
% Add the trigger to the data
datFinal(end+1, :) = dattrigRef;
hdrft.nChans = hdrft.nChans +1;
hdrft.label{end+1} = 'TRIG';
hdrft.chantype{end+1} = 'trigger';
hdrft.chanunit{end+1} = 'unknown';

nSamples = size(datFinal, 2);
hdrft.nSamples = nSamples;

% Remove some channels due to writing problem
Pmin = round(min(datFinal')');
Pmax = round(max(datFinal')');

% To write, Have to reove some channels
idsupinf = find(Pmax > 65535 | Pmin < -65535);
idequal = find(Pmax == Pmin);
Toremove = union(idsupinf, idequal);
if ~isempty(Toremove)
    chanToremove = hdrft.label(Toremove);
    datFinal(Toremove, :) = [];
    fieldsname =fields(hdrft);
    for s=1:length(fieldsname)
        if size(hdrft.(fieldsname{s}), 1) == hdrft.nChans && ~isempty(Toremove)
            hdrft.(fieldsname{s})(Toremove) = [];
        end
    end
    hdrft.nChans = hdrft.nChans - length(Toremove);
end

% Create Annotation for edf
evtTab = struct2table(evtreference);

% B naming
[~, file, ~] = fileparts(orderSEEG{1,1});

nameList = split(file, '_');
newname = fullfile(ppb.emuDirPreprocessing, strcat(nameList{1}, '_B1-', num2str(ppb.seeg.numBlock), '_', ...
    nameList{end}, '.edf'));
ppb.seeg.filename = newname;
ppb.seeg.eventsFilename = replace(newname, '.edf', '_events.csv');

ft_write_data(char(newname), datFinal, 'header', hdrft); % , 'event', evtreference
% Write events separately as it's not working with fieldtrip
writetable(evtTab, ppb.seeg.eventsFilename, 'Delimiter', ','); % As to check for the name
waitbar(1, fbar, 'Concatenation is done.')

ppb.seeg.trigChan = {'TRIG'};
ppb.seeg.hdr = hdrft;
ppb.seeg.data = datFinal;
ppb.seeg.events = evtreference;

close(fbar);
if ~isempty(Toremove)
    toWrite = join(cellstr(chanToremove), ', ');
    if iscell(toWrite)
        toWrite = toWrite{1};
    end
    warndlg(sprintf("The following channels %s have been deleted.", toWrite), 'Warning');
end
varargout{1} = ppb;
end









