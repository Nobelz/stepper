function predictStepperOnlyOld(kernelData, flyGenotype, flyNum)
% predictStepperOnly.m
% Using kernel information, predicts the fly head angle output, based off
% m-sequence input by generating a figure showing side-by-side comparisons.
% This works by using the conserved m-sequence.
%
% Inputs: 
%   - kernelData: the kernel to be used as the predictive model
%   - flyGenotype: the genotype of the fly (usually PCF)
%   - flyNum: the number of the fly
%
% Authors: Lauren Metz and Nobel Zhou
% Date: 9 June 2022
% Version: 1.0
%
% VERSION CHANGELOG:
% - v1.0: Initial commit

index = [];

for i = 1 : length(kernelData.data)
    if strcmp(kernelData.data(i).genotype , flyGenotype) && kernelData.data(i).num == flyNum && kernelData.data(i).trial == -1
        index = [index i];
    end
end

if length(index) ~= 1
    error('Error finding conserved fly trial.');
end

% kernelCount = 0;
% sumKernel = zeros(1, 256);
% for i = 1 : length(kernelData)
%     if kernelData(i).num == flyNum && strcmp(kernelData(i).genotype, flyGenotype) && kernelData(i).trial > 0
%         sumKernel = sumKernel + kernelData(i).kernel;
%         kernelCount = kernelCount + 1;
%     end
% end
% avgKernel = sumKernel / kernelCount;

index = index(1);
mSeq = kernelData.data(index).rawData.sequence;
avgKernel = computeAverageKernel(kernelData);
% ccirc = cconv(mSeq, avgKernel);

convolution = cconv(avgKernel, mSeq, length(mSeq));
% convolutionSized = convolution(1:2:length(convolution));

head = kernelData.data(index).rawData.head;
% convolution = convolution + (convolution(1) - head(1));
% convolution = convolution / max(convolution) * max(head) / 1.3;
% convolution = convolution - 2;
head = smooth(head)';

func = @(x) sseval(x, convolution, head);
startingValues = [10, 0];
fits = fminsearch(func, startingValues); 
disp(fits)

figure;
hold on
plot(convolution * fits(1) + fits(2));
plot(smooth(head));
xlabel('Samples')
ylabel('Head Angle')
legend('Predicted Response', 'Measured Response')
title('Fly')
hold off


% line = fitlm(smooth(kernelData(index).rawData.head), convolution);
% disp(num2str(line.Rsquared.Ordinary));
end

function sse = sseval(params, x, y)
% Function for the linear convolution fit

a = params(1);
b = params(2);

fitEquation = a * x + b;

sse = sum((y - fitEquation).^2); % Sum of squares
end
