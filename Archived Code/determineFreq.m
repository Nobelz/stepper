function [arenaFreq, stepperFreq] = determineFreq(data)
% determineFreq.m
% Determines the actual frequency of the stepper and LED arena.
% This outputs 2 values, the first being the frequency of the LED arena,
% and the second being the frequency of the stepper.
%
% Inputs:
%   - exp: the DAQ data
%
% Author: Nobel Zhou
% Date: 12 June 2023
% Version: 0.1
%
% VERSION CHANGELOG:
% - v0.1 (6/12/2023): Initial commit

DAQ_FREQ = 10000;

% Get relevant data
arena = data.("Dev1_ai4");
stepper = data.("Dev1_ai6");

arenaIdx = find(diff(abs(arena)) > 0.03);
stepperIdx = find(diff(stepper) > 2);

arenaPeriod = mean(diff(arenaIdx));
stepperPeriod = mean(diff(stepperIdx));

arenaFreq = DAQ_FREQ / arenaPeriod;
stepperFreq = DAQ_FREQ / stepperPeriod;

end