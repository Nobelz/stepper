% statKernelsStepperOnly.m
% Performs statistical analysis on the parameters of the kernels for all 4 experiments.
%
% Author: Nobel Zhou
% Date: 28 February 2023
% Version: 0.1
%
% VERSION CHANGELOG:
% - v0.1 (2/27/2023): Initial commit
% - v0.2 (2/28/2023): Add plots for fitting parameters

%% Load Data
load('./Kernels/allOnKernels.mat');
load('./Kernels/allOnHLKernels.mat');
load('./Kernels/stripesKernels.mat');
load('./Kernels/stripesHLKernels.mat');

%% Statistical Analysis on Parameters and Stats
% Create stat matrix
% Columns:
%   1: AllOn (0) vs. Stripes (1)
%   2: Haltereless (0) vs. Intact (1)
%   3: Goodness
%   3: tauRise
%   4: tauDecay
%   5: tauDC
%   6: AAC
%   7: ADC
%   8: tOnset
%   9: tDC
%  10: Peak Amplitude
%  11: Amplitude Time
%  12: Width at Half Peak
%  13: Decay Time
paramData = zeros(length(allOnKernels.data) + length(allOnHLKernels.data) + ...
    length(stripesKernels.data) + length(stripesHLKernels.data), 9);

% Find Individual Kernel Fit Data
allOnFits = [allOnKernels.data.fits];
allOnHLFits = [allOnHLKernels.data.fits];
stripesFits = [stripesKernels.data.fits];
stripesHLFits = [stripesHLKernels.data.fits];

% Find Individual Kernel Stats Data
allOnStats = [allOnKernels.data.stats];
allOnHLStats = [allOnHLKernels.data.stats];
stripesStats = [stripesKernels.data.stats];
stripesHLStats = [stripesHLKernels.data.stats];

%% Extract parameter data
j = 1; % Index param matrix

% All On Kernels
for i = 1 : length(allOnFits)
    paramData(j, 1) = 0;
    paramData(j, 2) = 1;
    paramData(j, 3) = allOnKernels.data(i).goodness;
    paramData(j, 4) = allOnFits(i).params.tauRise;
    paramData(j, 5) = allOnFits(i).params.tauDecay;
    paramData(j, 6) = allOnFits(i).params.tauDC;
    paramData(j, 7) = allOnFits(i).params.AAC;
    paramData(j, 8) = allOnFits(i).params.ADC;
    paramData(j, 9) = allOnFits(i).params.tOnset;
    paramData(j, 10) = allOnFits(i).params.tDC;
    paramData(j, 11) = allOnStats(i).ampPeak;
    paramData(j, 12) = allOnStats(i).timePeak;
    paramData(j, 13) = allOnStats(i).widthHalfPeak;
    paramData(j, 14) = allOnStats(i).timeDecay;
    paramData(j, 15) = allOnKernels.data(i).fits.gof.rsquare;
    j = j + 1;
end

% All On Haltereless Kernels
for i = 1 : length(allOnHLFits)
    paramData(j, 1) = 0;
    paramData(j, 2) = 0;
    paramData(j, 3) = allOnHLKernels.data(i).goodness;
    paramData(j, 4) = allOnHLFits(i).params.tauRise;
    paramData(j, 5) = allOnHLFits(i).params.tauDecay;
    paramData(j, 6) = allOnHLFits(i).params.tauDC;
    paramData(j, 7) = allOnHLFits(i).params.AAC;
    paramData(j, 8) = allOnHLFits(i).params.ADC;
    paramData(j, 9) = allOnHLFits(i).params.tOnset;
    paramData(j, 10) = allOnHLFits(i).params.tDC;
    paramData(j, 11) = allOnHLStats(i).ampPeak;
    paramData(j, 12) = allOnHLStats(i).timePeak;
    paramData(j, 13) = allOnHLStats(i).widthHalfPeak;
    paramData(j, 14) = allOnHLStats(i).timeDecay;
    paramData(j, 15) = allOnHLKernels.data(i).fits.gof.rsquare;
    j = j + 1;
end

% Stripes Kernels
for i = 1 : length(stripesFits)
    paramData(j, 1) = 1;
    paramData(j, 2) = 1;
    paramData(j, 3) = stripesKernels.data(i).goodness;
    paramData(j, 4) = stripesFits(i).params.tauRise;
    paramData(j, 5) = stripesFits(i).params.tauDecay;
    paramData(j, 6) = stripesFits(i).params.tauDC;
    paramData(j, 7) = stripesFits(i).params.AAC;
    paramData(j, 8) = stripesFits(i).params.ADC;
    paramData(j, 9) = stripesFits(i).params.tOnset;
    paramData(j, 10) = stripesFits(i).params.tDC;
    paramData(j, 11) = stripesStats(i).ampPeak;
    paramData(j, 12) = stripesStats(i).timePeak;
    paramData(j, 13) = stripesStats(i).widthHalfPeak;
    paramData(j, 14) = stripesStats(i).timeDecay;
    paramData(j, 15) = stripesKernels.data(i).fits.gof.rsquare;
    j = j + 1;
end

% Stripes Haltereless Kernels
for i = 1 : length(stripesHLFits)
    paramData(j, 1) = 1;
    paramData(j, 2) = 0;
    paramData(j, 3) = stripesHLKernels.data(i).goodness;
    paramData(j, 4) = stripesHLFits(i).params.tauRise;
    paramData(j, 5) = stripesHLFits(i).params.tauDecay;
    paramData(j, 6) = stripesHLFits(i).params.tauDC;
    paramData(j, 7) = stripesHLFits(i).params.AAC;
    paramData(j, 8) = stripesHLFits(i).params.ADC;
    paramData(j, 9) = stripesHLFits(i).params.tOnset;
    paramData(j, 10) = stripesHLFits(i).params.tDC;
    paramData(j, 11) = stripesHLStats(i).ampPeak;
    paramData(j, 12) = stripesHLStats(i).timePeak;
    paramData(j, 13) = stripesHLStats(i).widthHalfPeak;
    paramData(j, 14) = stripesHLStats(i).timeDecay;
    paramData(j, 15) = stripesHLKernels.data(i).fits.gof.rsquare;
    j = j + 1;
end

%% Perform Ranksum Analysis
% Store ranksum p value data
% Columns:
%   1: tauRise
%   2: tauDecay
%   3: tauDC
%   4: AAC
%   5: ADC
%   6: tOnset
%   7: tDC
%   8: Peak Amplitude
%   9: Amplitude Time
%  10: Width at Half Peak
%  11: Decay Time
% Rows:
%   1: AllOn (0) vs. Stripes (1)
%   2: Haltereless (0) vs. Intact (1)
ranksums = zeros(2, 11);

% Loop for each parameter
for i = 1 : 2
    for j = 4 : 14
        group1 = paramData(paramData(:, i) == 0, :);
        group2 = paramData(paramData(:, i) == 1, :);

        ranksums(i, j - 3) = ranksum(group1(:, j), group2(:, j));
    end
end


%% Plot Parameters
% Make categorical array
paramCats = strings(size(paramData, 1), 1);
for i = 1 : size(paramData, 1)
    if paramData(i, 1) == 0 && paramData(i, 2) == 0
        paramCats(i) = 'All On Haltereless';
    elseif paramData(i, 1) == 0 && paramData(i, 2) == 1
        paramCats(i) = 'All On Intact';
    elseif paramData(i, 1) == 1 && paramData(i, 2) == 0
        paramCats(i) = 'Stripes Haltereless';
    else
        paramCats(i) = 'Stripes Intact';
    end
end

% Change into categorical array
paramCats = categorical(paramCats, {'All On Intact', 'All On Haltereless', ...
    'Stripes Intact', 'Stripes Haltereless'}, 'Ordinal', true);

% Plot figure for each parameter
paramNames = {'Tau Rise', 'Tau Decay', 'Tau DC', 'AAC', 'ADC', ...
    'Time Onset', 'Time DC', 'Peak Amplitude', 'Amplitude Time', ...
    'Width at Half Peak', 'Decay Time', 'R-squared'};
for i = 1 : 12
    figure;
    swarmchart(paramCats, paramData(:, i + 3));
    title(paramNames{i});
    xlabel('Experimental Condition');
    ylabel('Parameter Value');
end

%% Plot Significance
% Make categorical arrays
visualCats = strings(size(paramData, 1), 1);
for i = 1 : size(paramData, 1)
    if paramData(i, 1) == 0
        visualCats(i) = 'All On';
    else
        visualCats(i) = 'Stripes';
    end
end
visualCats = categorical(visualCats, {'All On', 'Stripes'}, 'Ordinal', true);

haltereCats = strings(size(paramData, 1), 1);
for i = 1 : size(paramData, 1)
    if paramData(i, 2) == 0
        haltereCats(i) = 'Intact';
    else
        haltereCats(i) = 'Haltereless';
    end
end
haltereCats = categorical(haltereCats, {'Intact', 'Haltereless'}, 'Ordinal', true);

% Plot All On vs. Stripes tauRise
figure;
swarmchart(visualCats, paramData(:, 4));
title('AllOn vs. Stripes Tau Rise');
xlabel('Experimental Condition');
ylabel('Value');

% Plot Intact vs. Haltereless tauDecay
figure;
swarmchart(haltereCats, paramData(:, 5));
title('Intact vs. Haltereless Tau Decay');
xlabel('Experimental Condition');
ylabel('Value');

% Plot All On vs. Stripes tauDC
figure;
swarmchart(visualCats, paramData(:, 5));
title('AllOn vs. Stripes Tau DC');
xlabel('Experimental Condition');
ylabel('Value');

% Plot Intact vs. Haltereless tOnset
figure;
swarmchart(haltereCats, paramData(:, 9));
title('Intact vs. Haltereless Onset Time');
xlabel('Experimental Condition');
ylabel('Value');

% Plot All On vs. Stripes Peak Amplitude
figure;
swarmchart(visualCats, paramData(:, 11));
title('AllOn vs. Stripes Peak Amplitude');
xlabel('Experimental Condition');
ylabel('Value');

% Plot Intact vs. Haltereless Peak Amplitude
figure;
swarmchart(haltereCats, paramData(:, 11));
title('Intact vs. Haltereless Peak Amplitude');
xlabel('Experimental Condition');
ylabel('Value');

% Plot Intact vs. Haltereless Amplitude Time
figure;
swarmchart(haltereCats, paramData(:, 12));
title('Intact vs. Haltereless Amplitude Time');
xlabel('Experimental Condition');
ylabel('Value');

% Plot Intact vs. Haltereless Width at Half Peak
figure;
swarmchart(haltereCats, paramData(:, 13));
title('Intact vs. Haltereless Width at Half Peak');
xlabel('Experimental Condition');
ylabel('Value');

% Plot All On vs. Stripes Decay Time
figure;
swarmchart(visualCats, paramData(:, 14));
title('Intact vs. Haltereless Decay Time');
xlabel('Experimental Condition');
ylabel('Value');