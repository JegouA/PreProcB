function ppb = ppb_defaults(emuDir)

% Check the needed toolbox and create the default values
% Syntax:
%
% Outputs:
%       ppb        - struct containing the requirements
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

% Make ppb Global
ppb = struct();
% if ismac
%     ppb.emuDir = "smb//cortex.neurosurgery.pitt.edu";
% elseif ispc
%     ppb.emuDir = "\\cortex.neurosurgery.pitt.edu";
% end
ppb.emuDir = emuDir;
ppb.emuDirResearch = fullfile(ppb.emuDir, "EMU research data");
ppb.emuDirPreproName = "SEEGpreprocessing";
ppb.emuDirPreprocessing = [];
ppb.emuID = [];

% Requirement Protocols
ppb.protocol = struct();
if ~isempty(emuDir)
    ppb.protocol.directory = fullfile(ppb.emuDir, "Protocols & Information", ...
        "Experimental Protocols");
end
ppb.protocol.filename = [];
ppb.protocol.sheetname = {"Summary", "Trigger_Events", "Trial_Variables", ...
    "Notes"}; 
ppb.protocol.Summary.header = {"exptTriggerValue", "numBlocks",	...
    "blockVarName", "trialsPerBlock", "numTrials", ...
    "trialLengthType", "trialLength", "numTrigEvents", "numTrialVars"};
ppb.protocol.Trigger_Events.header = {"triggerEventName", "triggerShape", ...
    "timestamp", "value", "labelingExptCondition"};
ppb.protocol.Trial_Variables.header = {"variableName", "type", "numLevels", ...
    "levelLabels", "levelTriggerValues", "relativeToTrigger", "labelingCondition"};
ppb.protocol.Notes.header = {""};

% Requirement SEEG
ppb.seeg = struct();
ppb.seeg.trigChan = [];
ppb.seeg.numBlock = [];
ppb.seeg.filename = [];
ppb.seeg.eventsFilename = [];
ppb.seeg.events = [];
ppb.seeg.trigValue = [];
ppb.seeg.trigData = [];
ppb.seeg.markers = [];
ppb.seeg.markersFilename = [];
ppb.seeg.hdr = [];
ppb.seeg.data = [];

% Requirement Behavior
ppb.behavior = struct();
ppb.behavior.filename = [];
ppb.behavior.header = [];
ppb.behavior.data = [];

% Requirement Preprocess
ppb.preprocess = struct();
ppb.preprocess.HF = 0;
ppb.preprocess.HFvalue = [];
ppb.preprocess.NF = 0;
ppb.preprocess.NFvalue = [];
ppb.preprocess.badChannels = [];
ppb.preprocess.badChannelsFilename = [];
ppb.preprocess.data = [];
ppb.preprocess.hdr = [];
ppb.preprocess.filename = [];

% Requirement Process
ppb.process = struct();
ppb.process.data = [];
ppb.process.hdr = [];
ppb.process.markers = [];
ppb.process.filename = [];
ppb.process.montage = [];
ppb.process.downsample = [];
ppb.process.normalize = [];
ppb.process.normalizeTF = [];
ppb.process.filter = struct();
ppb.process.filter.Broadband = zeros(1,2);
ppb.process.overwrite = 0;

% Save separatly the data from process to use it as epoch or TF
ppb.process.outdata = [];

% Epochs the data
ppb.process.epochs = struct();
ppb.process.epochs.outdata = [];
ppb.process.epochs.timeMarker = [];
ppb.process.epochs.average = [];
ppb.process.epochs.timeBefore = [];
ppb.process.epochs.timeAfter = [];
ppb.process.epochs.results = struct();

% TF the data
ppb.process.TF = struct();
ppb.process.TF.psd = [];
ppb.process.TF.map = [];
ppb.process.TF.mapHg = 0;
ppb.process.TF.timeMarker = [];
ppb.process.TF.outdata = [];
ppb.process.TF.results = struct();

end