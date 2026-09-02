
clear; close all;

%% 1. Parameter Settings
sensitivity_dB  = -170;          % dB re 1V/µPa
system_gain_dB  = 26;            % dB
ADC_Vpp         = 5;             % peak value, V

% Spectral analysis parameters
overlap_percent = 0.5;           % Overlap percentage
freq_lim        = [0, inf];      % Frequency display range (Hz), nf represents Nyquist
dyn_range       = 60;            % Dynamic display range (dB)

%% 2. Read WAV files
[filename, pathname] = uigetfile('*.wav', 'Select ocean noise WAV file');
if isequal(filename, 0)
    error('No file selected');
end
filepath = fullfile(pathname, filename);
fprintf('Reading file: %s\n', filename);
% Read audio data
[y_norm, fs] = audioread(filepath);
% Obtain audio information
info = audioinfo(filepath);
fprintf('sampling frequency: %d Hz\n', fs);
fprintf('Audio duration: %.2f second\n', info.Duration);
fprintf('Channels : %d\n', info.NumChannels);
fprintf('Digit: %d\n', info.BitsPerSample);

if size(y_norm,2) > 1
    y_norm = y_norm(:,1);
end
N = length(y_norm);
t_total = N / fs;

%% 3. Calibration
V_adc = y_norm * (ADC_Vpp / 2);

gain_linear = 10^(system_gain_dB / 20);
V_hydro = V_adc / gain_linear;

% Convert to sound pressure (µPa)
M = 10^(sensitivity_dB / 20);
p_uPa = V_hydro / M;               % µPa

% Convert to sound pressure level (dB re 1 µ Pa) to avoid log (0)
p_ref = 1; % µPa
Lp = 20 * log10(abs(p_uPa) + eps(p_ref));

%% 4. Spectrogram
nfft     = 8192;                            % FFT points
win_samples   = hanning(nfft);              % Window vector
noverlap = round(overlap_percent * nfft);   % Overlap points

[S, F, T, Pxx] = spectrogram(p_uPa, win_samples, noverlap, nfft, fs, 'psd');
Pxx_dB = 10 * log10(Pxx + eps);

%% 5. Plotting
% Set graphic size, font, line width, etc
figure('Color','white','Position',[0 200 2700 600]);

if isinf(freq_lim(2))
    freq_lim(2) = fs/2;
end
f_idx = F >= freq_lim(1) & F <= freq_lim(2);
F_plot = F(f_idx);
P_plot = Pxx_dB(f_idx, :);

ax = axes;
imagesc(T, F_plot/1000, P_plot);  
axis xy;

% Dynamic range clipping
% c_max = max(P_plot(:));
% c_min = c_max - dyn_range;
c_min = 00;
c_max = 60;
clim([c_min, c_max]);
% xlim([0 10]);
ylim([0 60]);

colormap(nclCM("cmocean_deep"));  
cb = colorbar;
ylabel(cb, 'PSD(dB re 1 µPa^2/Hz)', 'FontSize', 12, 'FontWeight', 'bold');

% Tags and titles
xlabel('Time (s)', 'FontSize', 13, 'FontWeight', 'bold');
ylabel('Frequency (kHz)', 'FontSize', 13, 'FontWeight', 'bold');
title('Hydrophone Spectrogram', 'FontSize', 14, 'FontWeight', 'bold');

set(ax, 'FontSize', 12, 'LineWidth', 1.2);
box on;

axy = gca; axy.XAxis.TickDirection = 'out';
axy.YAxis.TickDirection = 'out';

c = colorbar;
set(c, 'tickdir', 'out');

% [~, name, ~] = fileparts(wav_file);
% print(gcf, [name '_spectrogram'], '-dpng', '-r300');  % 300 dpi PNG
% fprintf('The time-frequency spectrum has been saved as %s_spectrogram.png\n', name);
