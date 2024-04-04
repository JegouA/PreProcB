function varargout = align_seeg_triggers(ppb, progBar)

% Align the triggers of SEEG files with behavior data and create the
% required markers
% Syntax:
%
% Inputs:
%       ppb                  - struct containing all the information for
%                              PreProcB to work
%
% Outputs:
%       - varargout 
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

if nargin < 1
    return
elseif nargin < 2
    progBar = [];
end

% Read behavior file
[ppb, error] = read_behavior_file(ppb);
if error
    varargout{1} = ppb;
    varargout{2} = 1;
    return
end

% Get the trigger value
if isempty(ppb.seeg.trigValue)
    trigVal = cellfun(@(x) split(x, '-'), ...
            ppb.protocol.Trigger_Events.value.value, 'un', 0);
    ppb.seeg.trigValue = cellfun(@str2num, unique(cat(1, trigVal{:})));
end

% Check what is the trigger chan an is data
if isempty(ppb.seeg.trigData)
    if isempty(ppb.seeg.trigChan)
        errordlg('Trigger channel name is missing.', 'Error trigger');
        varargout{1} = ppb;
        varargout{2} = 1;
        return
    else
        idxtrig = find(strcmp(ppb.seeg.hdr.label, ppb.seeg.trigChan));
        ppb.seeg.trigData = ppb.seeg.data(idxtrig, :);
    end
end

% get the type of trigger
triggerShape = unique(ppb.protocol.Trigger_Events.value.triggerShape);
if length(triggerShape) == 1
    type = triggerShape{1};
else
    type = 'multiple';
end

if ~isempty(progBar)
    waitbar(0.4, progBar, 'Reading the files ...');
end

switch type
    case 'square'
        % Have to test if multiple sqaure in one trial
        numTrigger = ppb.protocol.Summary.value.numTrigEvents;
        idxsquare = cell(numTrigger, 4);
        for i=1:numTrigger
            value = split(ppb.protocol.Trigger_Events.value.value(i), '-');
            value = str2double(value);
            [~, idx] = min(value);
            idxsquare{i, 1} = idx;
            idxsquare{i, 2} = max(value);
            idxsquare{i, 3} = ppb.protocol.Trigger_Events.value.triggerEventName(i);
            idxsquare{i, 4} = ppb.protocol.Trigger_Events.value.labelingExptCondition(i);
        end
        % Check the type of trigger and detect them
        % take the min peak height omitting 0
        [pks, loc] = findpeaks(ppb.seeg.trigData);
        numTrials = length(pks);
        blockName = ppb.protocol.Summary.value.blockVarName{1};
        numBlockBeh = unique(ppb.behavior.data.(blockName));
        % have to be careful with that car maybe not with spikes 
        if str2double(ppb.seeg.numBlock) == ppb.protocol.Summary.value.numBlocks && ...
            numTrials ~= ppb.protocol.Summary.value.numTrials
            errordlg("Don't have the right number of trials")
            varargout{1} = ppb;
            varargout{2} = 1;
            return
        elseif str2double(ppb.seeg.numBlock) ~= ppb.protocol.Summary.value.numBlocks && ...
            length(numBlockBeh) ~= str2double(ppb.seeg.numBlock)
            errordlg("Number of blocks in edf files is different of the number " + ...
                "of blocks in Behavior data.")
            varargout{1} = ppb;
            varargout{2} = 1;
            return
        end
        % Create trial with trigger only for now according to the protocols
        blocks = cell(ppb.protocol.Summary.value.numBlocks, 2);
        trials = zeros(ppb.protocol.Summary.value.trialsPerBlock, numTrigger);
        ptrialDur = ppb.protocol.Summary.value.trialLength * ppb.seeg.hdr.Fs;
        % Create the trigger type to read it
        % Think also about blocks so should take into account the distance between
        % pks
        nblock = 1;
        for n=1:numTrials
            idT = find(cell2mat(idxsquare(:,2)) == pks(n) & ...
                    cell2mat(idxsquare(:,1)) == 1);
            if isempty(blocks{nblock, 1})
                blocks{nblock, 1} = trials;
                blocks{nblock, 2} = nblock;
                ntrial = 1;
            else
                ntrial = find(blocks{nblock, 1}(:, idT) == 0);
                ntrial = ntrial(1);
            end
            % to write the stimulus at the upp of the square
            blocks{nblock, 1}(ntrial, idT) = loc(n);
            if n < numTrials
                trialDuration = loc(n):loc(n+1);
            else
                trialDuration = loc(n):ppb.seeg.hdr.nSamples;
            end
            % to write ate the down
            samp = find(ppb.seeg.trigData(1, trialDuration) == 0);
            sampFinal = trialDuration(samp(1));
            idTb = cell2mat(idxsquare(:,2)) == pks(n) & ...
                    cell2mat(idxsquare(:,1)) == 2;
            blocks{nblock, 1}(ntrial, idTb) = sampFinal;
            if length(trialDuration) > 2 *ptrialDur
                nblock = nblock +1 ;
            end
        end

        if ~isempty(progBar)
            waitbar(0.6, progBar, 'Creating the markers files ...');
        end
        % Create the Markers according to behavior file
        % Go throught all blocks
        interestHeader = setdiff(ppb.protocol.Trial_Variables.value.variableName, ...
           vertcat(idxsquare{:,4}));
        nrows = (numTrials*length(ppb.protocol.Trial_Variables.value.variableName)) + ...
        ppb.protocol.Summary.value.numBlocks;
        markerTable = table('Size', [nrows 5], 'VariableTypes', {'string', ...
            'double', 'double', 'double', 'double'}, 'VariableNames', {'name', ...
            'onset_sample', 'onset_seconds', 'duration_sample', 'duration_seconds'});
        % Add the block number has marker with duration, put the start 2s
        % before
        if length(numBlockBeh) < ppb.protocol.Summary.value.numBlocks
            % Warning or errors ??
            answer = questdlg(['The number of Blocks in the behavior file is different of the protocol.' ...
                'Do you want to continue?'], 'Continue', 'Yes', 'No', 'Cancel');
            if strcmp(answer, 'No')
                varargout{1} = ppb;
                varargout{2} = 1;
                return
            end
        end
        % Take the beginning of the block two seconds before the marker
        deb = 2 * ppb.seeg.hdr.Fs;
        indT = 1;
        for b=1:ppb.protocol.Summary.value.numBlocks
            blockTab = ppb.behavior.data(ppb.behavior.data.(blockName) == b, :);
            if isempty(blockTab)
                continue;
            end
            markerTable.name(indT) = strcat('block_', num2str(b));
            markerTable.onset_sample(indT) =  round(blocks{b, 1}(1,1) - deb);
            markerTable.duration_sample(indT) = (blocks{b, 1}(end,1) + ptrialDur) - markerTable.onset_sample(indT);
            indT = indT+1;
            for n=1:ppb.protocol.Summary.value.trialsPerBlock
                tmp = blocks{b, 1}(n, :);
                for m=1:length(tmp)
                    prefix = string(idxsquare{m, 3});
                    if ~strcmp(string(idxsquare{m, 4}), "")
                        suffix = string(blockTab.(string(idxsquare{m, 4}))(n));
                    else
                        suffix = [];
                    end
                    % Check if suffix is right level
                    % Put condition for Boolean because Matlab read it as
                    % logical and it's number
                    if islogical(suffix)
                        suffix = string(suffix);
                    end
                    markerTable.name(indT) = join([prefix, suffix], '_');
                    markerTable.onset_sample(indT) = tmp(m);
                    markerTable.duration_sample(indT) = 0;
                    indT = indT+1;
                end
                for cond=1:length(interestHeader)
                    % Check if Relative to trigger
                    rel = ppb.protocol.Trial_Variables.value.relativeToTrigger( ...
                        strcmp(ppb.protocol.Trial_Variables.value.variableName, ...
                        interestHeader{cond}));
                    lab = ppb.protocol.Trial_Variables.value.labelingCondition( ...
                        strcmp(ppb.protocol.Trial_Variables.value.variableName, ...
                        interestHeader{cond}));
                    % Find what index it is in the trials 
                    idrel = find(strcmp(vertcat(idxsquare{:,3}), rel));
                    if ~isempty(idrel)
                        try
                            tmpBehval = blockTab.(interestHeader{cond}){n};
                        catch
                            tmpBehval = blockTab.(interestHeader{cond})(n);
                        end
                        if isstring(tmpBehval) || ischar(tmpBehval)
                            tmpBehval = str2double(tmpBehval);
                        end
                        markerTable.name(indT) = interestHeader{cond};
                        if ~isempty(lab{1}) 
                            markerTable.name(indT) = strcat(markerTable.name(indT), ...
                                "_", blockTab.(lab{1}){n});
                        end
                        markerTable.onset_sample(indT) = round(tmp(idrel) + ...
                            tmpBehval*ppb.seeg.hdr.Fs);
                        markerTable.duration_sample(indT) = 0;
                        indT = indT+1;
                    end
                end
            end
        end
        markerTable(indT:end,:) = []; 
        markerTable.onset_seconds = markerTable.onset_sample / ppb.seeg.hdr.Fs;
        markerTable.duration_seconds = markerTable.duration_sample / ppb.seeg.hdr.Fs; 
        
        if ~isempty(progBar)
            waitbar(0.8, progBar, 'Saving the markers files ...');
        end
        % save the results
        ppb.seeg.markers = markerTable;
        % Should change the directory to save
        % Have to check with EmuDir
        [~, file, ~] = fileparts(ppb.seeg.filename);
        ppb.seeg.markersFilename = fullfile(ppb.emuDirPreprocessing, ...
            strcat(file, '_markers.csv'));
        writetable(ppb.seeg.markers, ppb.seeg.markersFilename);
        % Write in Anywave format and Bids to be able to import it
        anywaveFile = fullfile(ppb.emuDirPreprocessing, ...
            strcat(file, '_markers.mrk'));
        fidA = fopen(anywaveFile, 'w');
        fprintf(fidA, "// AnyWave Marker File\n");
        for n = 1:size(markerTable, 1)
            fprintf(fidA, '%s\t-1\t%f\t%f\n', markerTable.name(n), ...
                markerTable.onset_seconds(n), markerTable.duration_seconds(n));
        end
        fclose(fidA);
% have to implement other type 'spike' and 'multiple'
end

if ~isempty(progBar)
    waitbar(1, progBar, 'Alignement is done.');
    close(progBar);
end

varargout{1} = ppb;
varargout{2} = 0;
end