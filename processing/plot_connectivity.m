function [r, nodesName, arrows, Axplot] = plot_connectivity(UIAxes, idx, label, data)
% Plot functional connectivity on specific axes
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
% May 2024

nchan = length(idx);
th = linspace(0,2*pi,nchan+1);
r = 10 + mod(nchan,10) * 10;
xunit = r * cos(th) + 0;
yunit = r * sin(th) + 0;
sz = 140;
drawArrow = @(target, x,y,varargin) quiver(target, x(1),y(1),x(2)-x(1),y(2)-y(1),0, ...
    varargin{:});

Axplot = scatter(UIAxes, xunit,yunit, sz, 'filled');
hold(UIAxes, 'on');

% Create map color for arrows
c = colormap(UIAxes, 'hot');
cinv = c(end:-1:1, :);
c = colormap(UIAxes, cinv);
tt = 1:256;
tt = tt/256;

nodesName = cell(nchan, 1);
arrows = {};
a=1;
for i = 1:nchan
    idxi = idx(i);
    for j= 1:nchan
        idxj = idx(j);
        if i==j
            continue
        end
        if isempty(nodesName{i})
            nodesName{i} = text(UIAxes, xunit(i), yunit(i), label{idxi}, ...
                'FontSize', 14, 'FontWeight', 'bold');
        end
        if isempty(nodesName{j})
            nodesName{j} = text(UIAxes, xunit(j), yunit(j), label{idxj}, ...
                'FontSize', 14, 'FontWeight', 'bold');
        end
        val1 = data(idxi, idxj);
        val2 = data(idxj, idxi);
        if (val1 == val2) && (val1 ~= 0)
            [~, t] = min(abs(tt - val1));
            arrows{a} = line(UIAxes,[xunit(i) xunit(j)], [yunit(i) yunit(j)], ...
                'color', cinv(t, :));
            a =a +1;
        elseif val1 ~= 0
            [~, t] = min(abs(tt - val1));
            arrows{a} = drawArrow(UIAxes,[xunit(i) xunit(j)], [yunit(i) yunit(j)], ...
                'color', cinv(t, :));
            a = a+1;
        elseif val2 ~= 0
            [~, t] = min(abs(tt - val2));
            arrows{a} = drawArrow(UIAxes,[xunit(j) xunit(i)], [yunit(j) yunit(i)], ...
                'color', cinv(t, :));
            a = a+1;
        end
    end
end
colorbar(UIAxes)
hold(UIAxes, 'off');
end

