function [bip_data, bip_elec_labels] = create_montage(labels, dat, type)

% Create bipolar or average montage
% Syntax:
%
% Inputs:
%       hdr                 - struct, header containing the labels and Fs
%       dat                 - [NxM] Matrix cotaining data
%       type                - string, method used 'bipolar' or 'average'
%
% Outputs:
%       - varargout - writing matlab file
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
 
switch type
    case 'bipolar'
        group = cellfun(@(str) str(~isstrprop(str,'digit')), labels, 'UniformOutput', 0);
        index = cellfun(@(str) str2double(str(isstrprop(str,'digit'))), labels);
        
        unique_elec_label = unique(group, 'stable');
        N_elec = length(unique_elec_label);
        
        bip_elec_labels = cell(size(labels));
        bip_data = NaN(size(dat));
        correct_cnt = false(size(labels));
        
        for n_el = 1:N_elec
            contact_idx = find(strcmp(group, unique_elec_label{n_el}));
            if contact_idx < 4 % remove channel that are likely not to be SEEG
                continue
            end
            % store the data of a given electrode temporary
            tmp_data = dat(contact_idx,:);
            tmp_idx = index(contact_idx);
            tmp_lbls = labels(contact_idx);
            % reorder the channels in ascending order (default)
            [tmp_idx, chg_ind] = sort(tmp_idx);
            tmp_data = tmp_data(chg_ind, :);
            tmp_lbls = tmp_lbls(chg_ind);
            contact_idx = contact_idx(chg_ind);
            
            bip_elec_labels(contact_idx(1:end-1)) = cellfun(@(str1,str2) [str1 '-' str2], tmp_lbls(1:end-1),...
                tmp_lbls(2:end),'UniformOutput', false);
            bip_data(contact_idx(1:end-1),:) = -diff(tmp_data, [], 1);
            correct_cnt(contact_idx(1:end-1)) = diff(tmp_idx, [], 1) == 1;
        end

        bip_elec_labels(~correct_cnt) = [];
        bip_data(~correct_cnt,:) = [];
    case 'average'
        % Should have only SEEG chanels so check the type
        otherType = ["EKG", "TRIG", "OSAT", "PR", "Pleth"];
        idx = cellfun(@(x) ~contains(x, otherType), labels, 'UniformOutput',false);
        idx = cell2mat(idx);
        avgDat = mean(dat(idx, :));
        bip_data = dat(idx, :);
        bip_elec_labels = labels(idx);
        % Do the diff
        bip_data = bip_data - avgDat;
end


end