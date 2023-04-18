function seq = generateMSeq()
% generateMSeq.m
% Rewrite for experiment, generates 3 iterations of 7th order random 
% m-sequence, padded to 1000 in length, interleaved with zeros.
%
% Author: Nobel Zhou
% Date: 17 April 2023
% Version: 0.1
%
% VERSION CHANGELOG:
% - v0.1 (4/17/2023): Initial commit

temp = mseq(2, 7, round(rand*127), round(rand*18)); % Generate m-sequence
temp = repmat(temp, [3 1]); % Repeat m-sequence 3 times
seq = zeros(1, 1000);
for i = 1 : length(temp)
    seq(i * 2) = temp(i); % Interleave 0's between each m-sequence iteration
end
end

