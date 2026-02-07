%-----------------------------------
% Step 1
%-----------------------------------

low_pass = im2double(rgb2gray(imread('LP.png')));
high_pass = im2double(rgb2gray(imread('HP.png')));

%-----------------------------------
% Step 2
%-----------------------------------
step2_low_fourier = fft2(low_pass);
step2_high_fourier = fft2(high_pass);

step2_freq_high = fftshift(abs(step2_high_fourier)) / 200;
step2_freq_low = fftshift(abs(step2_low_fourier)) / 200;

imwrite(step2_freq_high, 'HP-freq.png');
imwrite(step2_freq_low, 'LP-freq.png');

%-----------------------------------
% Step 3
%-----------------------------------

step3_sobel_kernel = fspecial('sobel');

step3_sigma = 2.5;
step3_gaussian_kernel = fspecial('gaussian', 2 * ceil(3 * step3_sigma) + 1, step3_sigma);

step3_dog_kernel = conv2(step3_gaussian_kernel, step3_sobel_kernel);

figure;
surf(step3_gaussian_kernel);
title('Gaussian Kernel');
saveas(gcf, 'gaus-surf.png');

figure;
surf(step3_dog_kernel);
title('DoG Kernel');
saveas(gcf, 'dog-surf.png');

%-----------------------------------
% Step 3.1
%-----------------------------------

% Apply the Gaussian filter in the spatial domain
step31_HP_filter = imfilter(high_pass, step3_gaussian_kernel);
step31_LP_filter = imfilter(low_pass, step3_gaussian_kernel);

% Save the filtered images
imwrite(step31_HP_filter, 'HP-filt.png');
imwrite(step31_LP_filter, 'LP-filt.png');

% Compute the frequency domain representation of the filtered images
step31_HP_filter_freq = fftshift(abs(fft2(step31_HP_filter))) / 2;
step31_LP_filter_freq = fftshift(abs(fft2(step31_LP_filter))) / 2;

% Save the frequency domain versions of the filtered images
imwrite(step31_HP_filter_freq, 'HP-filt-freq.png');
imwrite(step31_LP_filter_freq, 'LP-filt-freq.png');

%-----------------------------------
% Step 3.2
%-----------------------------------

% Pad the DoG kernel to 500x500 and compute its Fourier transform
step32_dog_kernel_padded = fft2(step3_dog_kernel, 500, 500);

% Apply the DoG filter in the frequency domain
step32_HP_dog_filter_freq = step32_dog_kernel_padded .* step2_high_fourier;
step32_LP_dog_filter_freq = step32_dog_kernel_padded .* step2_low_fourier;

% Save the frequency domain versions (adjust brightness with log scaling)
imwrite(abs(fftshift(step32_HP_dog_filter_freq)), 'HP-dogfilt-freq.png');
imwrite(abs(fftshift(step32_LP_dog_filter_freq)), 'LP-dogfilt-freq.png');

% Convert back to the spatial domain
step32_HP_dog_filter = ifft2(step32_HP_dog_filter_freq) * 2;
step32_LP_dog_filter = ifft2(step32_LP_dog_filter_freq) * 2;

% Save the filtered images (spatial domain)
imwrite(step32_HP_dog_filter, 'HP-dogfilt.png');
imwrite(step32_LP_dog_filter, 'LP-dogfilt.png');

%-----------------------------------
% Step 4
%-----------------------------------

% Shift the zero-frequency component to the center
step4_high_fourier_shifted = fftshift(fft2(high_pass));
step4_low_fourier_shifted = fftshift(fft2(low_pass));

% Subsample images by taking every second pixel (1:2:end)
step4_subsample_high_2 = high_pass(1:2:end, 1:2:end);
step4_subsample_low_2 = low_pass(1:2:end, 1:2:end);

% Save the subsampled images and their frequency domain versions
imwrite(step4_subsample_low_2, 'LP-sub2.png');
imwrite(step4_subsample_high_2, 'HP-sub2.png');

% Save frequency domain representations (magnitude)
imwrite(abs(fftshift(fft2(step4_subsample_low_2, 500, 500))) / 80, 'LP-sub2-freq.png'); 
imwrite(abs(fftshift(fft2(step4_subsample_high_2, 500, 500))) / 80, 'HP-sub2-freq.png');

% Subsample images by taking every second pixel (1:4:end)
step4_subsample_high_4 = high_pass(1:4:end, 1:4:end);
step4_subsample_low_4 = low_pass(1:4:end, 1:4:end);

% Save the subsampled images and their frequency domain versions
imwrite(step4_subsample_low_4, 'LP-sub4.png');
imwrite(step4_subsample_high_4, 'HP-sub4.png');

% Save frequency domain representations (magnitude)
imwrite(abs(fftshift(fft2(step4_subsample_low_4, 500, 500))) / 80, 'LP-sub4-freq.png'); 
imwrite(abs(fftshift(fft2(step4_subsample_high_4, 500, 500))) / 80, 'HP-sub4-freq.png');

%-----------------------------------
% Step 4.1
%-----------------------------------

step41_sigma_two = 0.65;
step41_gaussian_kernel_two = fspecial('gaussian', 2 * ceil(2 * step41_sigma_two) + 1, step41_sigma_two);

step41_sigma_four = 0.57;
step41_gaussian_kernel_four = fspecial('gaussian', 2 * ceil(2 * step41_sigma_four) + 1, step41_sigma_four);

step41_high_filter_two = imfilter(step4_subsample_high_2, step41_gaussian_kernel_two);
step41_high_filter_four = imfilter(step4_subsample_high_4, step41_gaussian_kernel_four);

% Save the anti-aliased subsampled images
imwrite(step41_high_filter_two, 'HP-sub2-aa.png');
imwrite(step41_high_filter_four, 'HP-sub4-aa.png');

% Save frequency domain images
imwrite(abs(fftshift(fft2(step41_high_filter_two, 500, 500))) / 50, 'HP-sub2-aa-freq.png');
imwrite(abs(fftshift(fft2(step41_high_filter_four, 500, 500))) / 50, 'HP-sub4-aa-freq.png');

%-----------------------------------
% Step 5
%-----------------------------------

thresholds_hp = [
     0.1, 0.3;   % Optimal
    0.15, 0.3;  % lower low
    0.15, 0.3;  % Higher low
     0.1, 0.2;  % Lower high
     0.1, 0.5;  % Higher high
];

hp_image_names = {
    'HP-canny-optimal.png',
    'HP-canny-lowlow.png',
    'HP-canny-highlow.png',
    'HP-canny-lowhigh.png',
    'HP-canny-highhigh.png'
};

% Canny Edge Detection for HP
for i = 1:size(thresholds_hp, 1)
    low_thresh = thresholds_hp(i, 1);
    high_thresh = thresholds_hp(i, 2);
    edges_hp = edge(high_pass, 'Canny', [low_thresh, high_thresh]);
    imwrite(edges_hp, hp_image_names{i});
end

thresholds_lp = [
    0.05, 0.15;  % Optimal
    0.01, 0.15;  % lower low
     0.1, 0.15;  % Higher low
    0.05, 0.1;   % Lower high
    0.05, 0.25;  % Higher high
];

lp_image_names = {
    'LP-canny-optimal.png',
    'LP-canny-lowlow.png',
    'LP-canny-highlow.png',
    'LP-canny-lowhigh.png',
    'LP-canny-highhigh.png'
};

% Canny Edge Detection for LP
for i = 1:size(thresholds_lp, 1)
    low_thresh = thresholds_lp(i, 1);
    high_thresh = thresholds_lp(i, 2);
    edges_lp = edge(low_pass, 'Canny', [low_thresh, high_thresh]);
    imwrite(edges_lp, lp_image_names{i});
end
