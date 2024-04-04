function ppb = create_results_dir(ppb, type, seegfile)

% Create the directory to save results
% Syntax:
%
% Inputs:
%       ppb                  - struct containing all the information for
%                              PreProcB to work
%       type                 - string 'preprocessing' or 'processing'
%       seegfile             - string seeg filename
% Outputs
%       ppb
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

if nargin > 2
    filename = seegfile;
elseif ~isempty(ppb.seeg.filename)
    filename = ppb.seeg.filename;
else
    errordlg('Results directory cannot be created because seeg file is missing.')
    return
end

if isempty(ppb.emuID)
    me = MException('MATLAB:notEnoughInputs','EMU ID not present.');
    throw(me)
end


switch type
    case 'preprocessing'
        % Check the path
        [path, ~, ~] = fileparts(filename);
        if contains(path, ppb.emuDirResearch)
            dirname = fullfile(ppb.emuDirResearch, strcat('EMU', ppb.emuID), ...
                ppb.emuDirPreproName);
        elseif contains(path, ppb.emuDirPreproName)
            listing = split(path, filesep);
            idc = find(strcmp(listing, ppb.emuDirPreproName));
            dirname = join(listing(1:idc), filesep);
            dirname = dirname{1};
        else
            dirname = fullfile(path, ppb.emuDirPreproName);
        end
        if ~exist(dirname, 'dir')
            mkdir(dirname)
        end
        ppb.emuDirPreprocessing = dirname;
end