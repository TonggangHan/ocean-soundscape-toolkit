%% Turbidity time-series plotting
% File: Turbidity_data.xlsx

clear; clc; close all;

%% 1. Read data
fileName = 'Turbidity_data.xlsx';

T = readtable(fileName, ...
    'VariableNamingRule','preserve');

timeRaw = T{:,1};
turbidity = T{:,2};

%% 2. Convert time column to datetime
if ~isdatetime(timeRaw)
    time = datetime(timeRaw, ...
        'InputFormat','yyyy-MM-dd HH:mm:ss');
else
    time = timeRaw;
end

%% 3. Remove missing or invalid data
validIdx = ~isnat(time) & ~isnan(turbidity);
time = time(validIdx);
turbidity = turbidity(validIdx);

%% 4. Create figure
fig = figure('Color','w', ...
    'Units','centimeters', ...
    'Position',[5 5 25 6]);
% fig = figure('Color','w', 'Position',[0 200 2500 600]);


ax = axes(fig);
hold(ax,'on');

%% 5. Plot turbidity curve
plot(time, turbidity, ...
    'LineWidth',1.4, ...
    'Color',[0.00 0.28 0.67]);   

%% 6. Axis labels
xlabel('Time', ...
    'FontName','Arial', ...
    'FontSize',12);

ylabel('Turbidity', ...
    'FontName','Arial', ...
    'FontSize',12);

%% 7. Axis style
set(ax, ...
    'FontName','Arial', ...
    'FontSize',11, ...
    'LineWidth',1.0, ...
    'Box','on', ...
    'TickDir','out', ...
    'TickLength',[0.015 0.015], ...
    'XMinorTick','on', ...
    'YMinorTick','on', ...
    'Layer','top');

grid(ax,'on');
ax.GridLineStyle = '-';
ax.GridAlpha = 0.18;
ax.MinorGridAlpha = 0.08;

%% 8. Time axis formatting
xlim([min(time) max(time)]);

durationTotal = max(time) - min(time);

if durationTotal < hours(6)
    xtickformat('HH:mm');
elseif durationTotal < days(2)
    xtickformat('MM-dd HH:mm');
else
    xtickformat('yyyy-MM-dd');
end

%% 9. Y-axis range
yMin = min(turbidity);
yMax = max(turbidity);
yPadding = 0.08 * (yMax - yMin);

ylim([yMin - yPadding, yMax + yPadding]);

%% 10. Optional title
% title('Turbidity variation with time', ...
%     'FontName','Arial', ...
%     'FontSize',12, ...
%     'FontWeight','normal');

%% 11. Improve layout
set(gca,'LooseInset',max(get(gca,'TightInset'),0.02));

%% 12. Export high-resolution figures
% exportgraphics(fig, 'Turbidity_time_series.tif', ...
%     'Resolution',600);
% 
% exportgraphics(fig, 'Turbidity_time_series.pdf', ...
%     'ContentType','vector');