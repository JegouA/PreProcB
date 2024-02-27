function varargout = read_protocol_file(ppb, Protocol)

% Read and convert in table the sheets form Protocols
% Syntax:
%
% Inputs:
%       ppb                  - struct containing all the information for
%                              PreProcB to work
%       Protocol             - string of Protocol file (path or just name
%       if in EMU)
%
% Outputs:
%       - varargout - provide option if no input
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

if nargin > 1 && ~isempty(Protocol)
    [path, ~, ~ ] = fileparts(Protocol);
    if isempty(path)
        ppb.protocol.filename = fullfile(ppb.protocol.directory, Protocol);
    else
        ppb.protocol.filename = Protocol;
    end
end

doesexist = exist(ppb.protocol.filename, 'file');
if doesexist == 0
    errordlg(["Protocol " ppb.protocol.filename "doesn't exist."])
    varargout{1} = ppb;
    varargout{2} = 1;
    return
else
    for p = ppb.protocol.sheetname
        opts = detectImportOptions(ppb.protocol.filename, 'Sheet', p{1});
        ppb.protocol.(p{1}).value = readtable(ppb.protocol.filename, opts, 'Sheet', p{1});
        checkHeader = cellfun(@(x) find(strcmp(ppb.protocol.(p{1}).value.Properties.VariableNames, x)), ...
            ppb.protocol.(p{1}).header, 'UniformOutput',false);
        if any(isempty(checkHeader))
            errordlg(["Protocol is not conform, review " p{1}])
            varargout{1} = ppb;
            varargout{2} = 1;
            return
        end
    end
end
varargout{1} = ppb;
varargout{2} = 0;

end
