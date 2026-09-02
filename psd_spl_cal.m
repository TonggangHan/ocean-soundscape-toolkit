
clear; close all;

%% Parameter Settings
sensitivity_dB = -170;           % Hydrophone sensitivity [dB re 1V/µPa]
gain_dB        = 26;             % System gain [dB]
V_fs           = 5;              % ADC full-scale peak to peak value [V]

% Linear conversion
M_lin = 10^(sensitivity_dB / 20);   % V/µPa
A_lin = 10^(gain_dB / 20);          % Voltage amplification factor

% Frequency upper limit (used for total sound pressure level calculation and plotting)
freq_limit = 64e3;               % Hz

%% Select the folder containing WAV files
folderPath = uigetdir(pwd, 'Select the folder to store WAV files');
if folderPath == 0
    error('No folder selected.');
end
fileList = dir(fullfile(folderPath, '*.wav'));
if isempty(fileList)
    error('There are no. wav files in the selected folder.');
end
fprintf('Found %d WAV files.\n', length(fileList));

%% Read the first file, obtain the sampling rate
[~, fs] = audioread(fullfile(folderPath, fileList(1).name));
clear testData;  

%% Welch method
nfft     = 8192;                       % FFT point(adjustable)
window   = hanning(nfft);              % Window vector
noverlap = round(0.5 * nfft);          % Overlapping points
step     = nfft - noverlap;            % Frame step size

% Normalization factor
winNorm = fs * sum(window.^2);

% Accumulator
pxxSum  = zeros(nfft/2 + 1, 1);        % Single side power spectrum accumulation
totalSegments = 0;                     % Total weighted number of segments

%% Process files one by one
for iFile = 1:length(fileList)
    fileName = fullfile(folderPath, fileList(iFile).name);
    fprintf('Process files %d/%d: %s\n', iFile, length(fileList), fileList(iFile).name);

    % Read the entire file (a single file can usually be read in at once; if it is still insufficient, use fread streaming for reading)
    try
        [data, fsCurr] = audioread(fileName);
    catch ME
        error('Failed to read file %s：%s', fileName, ME.message);
    end

    % Check the consistency of sampling rate
    if fsCurr ~= fs
        error('The sampling rate (%.0f Hz) of file %s is inconsistent with the first file (%.0f Hz).', ...
              fileName, fsCurr, fs);
    end

    % Normalized data
    V_adc = data * (V_fs / 2);
    V_adc = detrend(V_adc, 'constant');

    % Reverse deduce the sound pressure at the hydrophone end [µPa]
    p_muPa = V_adc / (A_lin * M_lin);
    clear V_adc data;   

    L = length(p_muPa);
    nSeg = fix((L - noverlap) / step);   
    if nSeg < 1
        warning('The file %s is not long enough to perform a Welch segmentation and has been skipped.', fileList(iFile).name);
        continue;
    end

    pxxLocal = zeros(nfft/2 + 1, 1);     
    idxStart = 1;
    for k = 1:nSeg
        idx = idxStart : idxStart + nfft - 1;
        seg = p_muPa(idx) .* window;
        X = fft(seg, nfft);
        P = abs(X(1:nfft/2+1)).^2;       
        P(2:end-1) = 2 * P(2:end-1);     
        pxxLocal = pxxLocal + P;
        idxStart = idxStart + step;
    end
    pxxLocal = pxxLocal / (nSeg * winNorm);  

    % Weighted accumulation based on the number of segments
    pxxSum = pxxSum + pxxLocal * nSeg;
    totalSegments = totalSegments + nSeg;
end

if totalSegments == 0
    error('The number of segments for all files is 0, so PSD cannot be calculated.');
end

% Weighted average PSD of all files
pxx = pxxSum / totalSegments;

% Frequency axis (unilateral)
f = (0:nfft/2)' * (fs / nfft);

pxx(pxx < 1e-20) = 1e-20;
pxx_dB = 10 * log10(pxx);

%% ---------- Total sound pressure level (only within the frequency range of ≤ 64 kHz) ----------
Only integrate the frequency points with f ≤ freq-limit
freq_idx = f <= freq_limit;     
df = f(2) - f(1);               
total_SPL = 10 * log10(sum(pxx(freq_idx)) * df);

%% ---------- Ploting ----------
figWidth  = 8.6;    % cm
figHeight = 6.0;    % cm
figure('Units', 'centimeters', 'Position', [5 5 figWidth figHeight]);

% Only plot the part with positive frequency and ≤ 64 kHz
idx_plot = (f > 0) & (f <= freq_limit);
f_plot = f(idx_plot);
pxx_plot = pxx_dB(idx_plot);

plot(f_plot, pxx_plot, 'k-', 'LineWidth', 1.5);
hold on;

ax = gca;
ax.FontName = 'Helvetica';
ax.FontSize = 8;
ax.LineWidth = 1;
ax.TickDir = 'out';
ax.TickLength = [0.02 0.025];
ax.Box = 'off';
ax.XColor = 'k';
ax.YColor = 'k';

grid on;
ax.GridAlpha = 0.3;
ax.GridLineStyle = '--';
ax.MinorGridAlpha = 0.1;

xlabel('Frequency (Hz)', 'FontName', 'Helvetica', 'FontSize', 9, ...
       'Interpreter', 'tex');
ylabel('PSD (dB re 1 \muPa^2/Hz)', 'FontName', 'Helvetica', 'FontSize', 9, ...
       'Interpreter', 'tex');

xlim([f_plot(1), min(fs/2, freq_limit)]);
ylim([min(pxx_plot)-5, max(pxx_plot)+5]);

text(0.02, 0.98, sprintf('Total SPL (≤64 kHz): %.1f dB re 1 µPa', total_SPL), ...
     'Units', 'normalized', 'VerticalAlignment', 'top', ...
     'FontName', 'Helvetica', 'FontSize', 8, 'Color', 'k');

%% Export
set(gcf, 'Renderer', 'painters');
exportgraphics(gcf, 'WaterSpectrum.pdf', ...
               'ContentType', 'vector', 'BackgroundColor', 'none');
exportgraphics(gcf, 'WaterSpectrum.png', ...
               'Resolution', 300, 'BackgroundColor', 'white');

fprintf('The graphic has been saved as WaterSpectrum.pdf 和 WaterSpectrum.png\n');
fprintf('Sound Pressure Level (≤64 kHz): %.2f dB re 1 µPa\n', total_SPL);