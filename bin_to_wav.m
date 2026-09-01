
binFile = '3669_260513120345_128000_0_00357.bin';
wavFile = '3669_260513120345_128000_0_00357.wav';
fs = 128000;  % sampling rate
ncha = 1;     % channel

fid = fopen(binFile, 'r');
data = fread(fid, inf, 'bit24', 'b');
fclose(fid);

nbits = 24;
ratio = 1/2^(nbits-1)*2.5;
data = data * ratio;
data = reshape(data, ncha, []).';

audiowrite(wavFile, data, fs);
