function save_as_edf(hdr, dat, filename, varargin)

% Fuction to save the data as edf
% Syntax:
%
% Inputs:
%       hdr                  - struct with the header of edf 
%       dat                  - NxM matrix containing the signal
%       filename             - string with the name of edf file
%       varargin             - include badChannels and events
%
% Outputs:
%       - Write edf files in appropriate folder
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

%%%Check the varargin to have badChannels and events%%%%
% Wanted to add the evnts but it's not supported by fieldtrip
badChannels = []; 
if nargin > 3
    badChannels = varargin{1};
end

if ~isempty(badChannels)
    idx = cellfun(@(x) find(strcmp(x, hdr.label)), badChannels, 'un', 0);
    idx = cell2mat(idx);
    dat(idx, :) = [];
    hdr.label(idx) = [];
    hdr.chantype(idx) = [];
    hdr.chanunit(idx) = [];
    hdr.nChans = hdr.nChans - length(idx);
end

ft_write_data(char(filename), dat, 'header', hdr);


end