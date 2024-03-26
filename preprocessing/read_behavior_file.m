function varargout = read_behavior_file(ppb)

% Read and convert in table the sheets form Behavior file
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
% February 2024

if ~exist(ppb.behavior.filename, 'file')
    errordlg("The behavior file doesn't exist", 'Error behavior data');
    varargout{1} = ppb;
    varargout{2} = 1;
    return
end

[~, ~, ext] = fileparts(ppb.behavior.filename);
switch ext
    case {'.xls', '.xlsx'}
        opts = detectImportOptions(ppb.behavior.filename, 'Sheet', 1);
        ppb.behavior.data = readtable(ppb.behavior.filename, opts, 'Sheet', 1);
    case '.csv'
        ppb.behavior.data = readtable(ppb.behavior.filename, 'Delimiter', ',');
    case '.tsv'
        ppb.behavior.data = readtable(ppb.behavior.filename, 'Delimiter', '\t');
end
ppb.behavior.header = ppb.behavior.data.Properties.VariableNames;

% Check if there is the required variables indicated in protocol
isIn = cellfun(@(x) ismember(x, ppb.behavior.header), ...
    ppb.protocol.Trial_Variables.value.variableName, 'un', 0);
varargout{1} = ppb;
isIn = cell2mat(isIn);
if ~all(isIn == 1)
    missingVariable = ppb.protocol.Trial_Variables.value.variableName(~isIn);
    toWrite = join(cellstr(missingVariable), ', ');
    if iscell(toWrite)
        toWrite = toWrite{1};
    end
    errordlg(sprintf(['The following variable %s are present as Trial ' ...
        'variables in your protocol but don"t appear in your behavior file.'], ...
        toWrite), 'Error behavior data');
    varargout{2} = 1;
    return
end
varargout{2} = 0;
end
