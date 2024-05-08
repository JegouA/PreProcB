function varargout = prepare_seeg_data(SEEGfile, ppb, method)

% Prepare the SEEG files according to the protocols and user. Select the
% right trigger channels and concatenate data if needed
% Syntax:
%
% Inputs:
%       SEEGfile             - cell of SEEG files, if multiple concatenate
%       ppb                  - struct containing all the information for
%                              PreProcB to work
%       method               - string value for different case
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

nfiles = length(SEEGfile);
ppb = create_results_dir(ppb, 'preprocessing', SEEGfile{1});
switch method
    case 'trigger'
        % Check if concatenation is needed
        if nfiles > 1
            if size(SEEGfile, 2) > size(SEEGfile, 1)
                SEEGfile =SEEGfile';
            end
            % Ask if the files should be concatenate
            answer = questdlg(['You have selected multiple SEEG files, do you want' ...
                ' to concatenate them?'], 'Concatenation', 'Yes', 'No', 'Cancel');
            switch answer
                case 'Yes'
                    for n=1:nfiles
                        hdr = ft_read_header(SEEGfile{n,1});
                        SEEGfile{n,2} = hdr.label(strcmp(hdr.chantype, 'trigger'));
                    end
                    ppb = concatenate_data(SEEGfile, ppb);
                    varargout{1} = ppb;
                    varargout{2} = ppb.seeg.trigChan;
                    return

                case 'No'
                    % User has to chose the right file
                    [indx,tf] = listdlg('PromptString',{'Select a file.',...
                        'Only one file can be used.',''},...
                        'SelectionMode','single','ListString',SEEGfile);
                    if tf ==1
                        SEEGfile = SEEGfile(indx);
                        [~, file, ~] = fileparts(SEEGfile);
                        newname = fullfile(ppb.emuDirPreprocessing, strcat(file, '.edf'));
                        ppb.seeg.filename = char(newname);
                        copyfile(SEEGfile{1}, newname);
            
                        % Read SEEG file header to get the channels
                        ppb.seeg.hdr = ft_read_header(ppb.seeg.filename);
            
                        % Select the trigger types
                        trigIdx = (strcmp(ppb.seeg.hdr.chantype, 'trigger'));
                        % Don't know why but doesn't accept the types from
                        % concatenate_data
                        if all(trigIdx == 0)
                             trigIdx = (startsWith(ppb.seeg.hdr.label, 'TRIG'));
                        end
                        trigChanPossibility = ppb.seeg.hdr.label(trigIdx);
                        varargout{1} = ppb;
                        varargout{2} = trigChanPossibility;
                        return
                    else
                        errordlg(['Preprocessing cannot be done on multiple ' ...
                            'files if no concatenation !!!']);
                        varargout{1} = ppb;
                        varargout{2} = [];
                        return
                    end
                case ''
                    errordlg('No decision was made !!!');
                    varargout{1} = ppb;
                    varargout{2} = [];
                    return
            end
        else
            [~, file, ~] = fileparts(SEEGfile{1});
            newname = fullfile(ppb.emuDirPreprocessing, strcat(file, '.edf'));
            ppb.seeg.filename = char(newname);
            try
                copyfile(SEEGfile{1}, newname);
            catch
                msgbox('File is already in SEEGprocessing');
            end

            % Read SEEG file header to get the channels
            ppb.seeg.hdr = ft_read_header(ppb.seeg.filename);

            % Select the trigger types
            trigIdx = (strcmp(ppb.seeg.hdr.chantype, 'trigger'));
            % Don't know why but doesn't accept the types from
            % concatenate_data
            if all(trigIdx == 0)
                 trigIdx = (startsWith(ppb.seeg.hdr.label, 'TRIG'));
            end
            trigChanPossibility = ppb.seeg.hdr.label(trigIdx);
            varargout{1} = ppb;
            varargout{2} = trigChanPossibility;
            return
        end

    case 'compare'
        %Read protocol
        shts=sheetnames(ppb.protocol.filename);
        c = setdiff(shts, cellstr(ppb.protocol.sheetname(:)));
        if ~isempty(c)
            errordlg('The selected protocol is not conform, please review it.')
            return
        end
        % Read the Trigger_events to get the value
        trigVal = cellfun(@(x) split(x, '-'), ...
            ppb.protocol.Trigger_Events.value.value, 'un', 0);
        ppb.seeg.trigValue = cellfun(@str2num, unique(cat(1, trigVal{:})));
        % Read SEEG to get the Trigger channels
        if ~isfield(ppb.seeg, 'hdr') || isempty(ppb.seeg.hdr)
            ppb.seeg.hdr = ft_read_header(ppb.seeg.filename);
        end
        if ~isfield(ppb.seeg, 'data') || isempty(ppb.seeg.data)
            ppb.seeg.data = ft_read_data(ppb.seeg.filename);
        end
        idxtrig = find(strcmp(ppb.seeg.hdr.label, ppb.seeg.trigChan));
        ppb.seeg.trigData = ppb.seeg.data(idxtrig, :);
        trigDat = unique(ppb.seeg.trigData);
        if ~all(ismember(trigDat, ppb.seeg.trigValue))
            errordlg(["The trigger channel selected " ppb.seeg.trigChan ...
                " doesn't contain the value from the Protocol. " + ...
                "Please select another one."]);
            varargout{1} = ppb;
            varargout{2} = 1;
            return
        end
        varargout{1} = ppb;
        varargout{2} = 0;
        return
    case 'read'
        if nfiles > 1
            errordlg(['There is more than one SEEG files, please align it before' ...
                'to do any preprocess.']);
            varargout{1} = ppb;
            varargout{2} = 1;
            return
        end
        ppb.seeg.filename = SEEGfile{1};
        % Read SEEG file header to get the channels
        ppb.seeg.hdr = ft_read_header(ppb.seeg.filename);
        ppb.seeg.data = ft_read_data(ppb.seeg.filename);
        varargout{1} = ppb;
        varargout{2} = 0;
        return
end

end
