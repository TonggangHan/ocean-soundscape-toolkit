%% Read data
filename = 'vel.xlsx';          
if ~isfile(filename)
error('File not found: %s', filename);
end
data = readtable(filename, 'VariableNamingRule', 'preserve');
depth = data{:, 1};             
speed = data{:, 2};             
%% Graphic parameter settings
figWidth  = 8.5;    % Width
figHeight = 8.5;    % Height
figure('Units', 'centimeters', 'Position', [5, 5, figWidth, figHeight], ...
'Color', 'white', 'DefaultAxesFontName', 'Times New Roman');
% Plot sound velocity profile
plot(speed, depth, '-', 'LineWidth', 1.5, 'Color', [0, 0.2, 0.55]);   
set(gca, 'YDir', 'reverse');      
set(gca, 'XAxisLocation', 'top'); %
% Coordinate axis labels and fonts
xlabel('Sound Speed (m/s)', 'FontSize', 9);
ylabel('Depth (m)', 'FontSize', 9);
set(gca, 'FontName', 'Times New Roman', 'FontSize', 8, ...   
'TickDir', 'out', 'LineWidth', 1, ...               
'box', 'on');
x_span = max(speed) - min(speed);
if x_span == 0, x_span = 1; end   
xlim([min(speed) - 0.05*x_span, max(speed) + 0.05*x_span]);
y_span = max(depth) - min(depth);
if y_span == 0, y_span = 1; end
ylim([max(depth) + 0.05*y_span, min(depth) - 0.05*y_span]);
set(gca, 'Position', [0.17, 0.15, 0.78, 0.78]);