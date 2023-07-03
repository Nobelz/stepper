function seq = generateMSeq(interleaved)
% generateMSeq.m
% Rewrite for experiment, m-sequence, padded to 1000 in length.
%
% Inputs:
%   - interleaved: 1 - generate 3 7th order m-sequences, interleaved with
%                       zeros (default).
%                  0 - generate 3 8th order m-sequences, no interleave.
%
% Author: Nobel Zhou, Jessica Fox, and Mike Rauscher
% Date: 3 July 2023
% Version: 0.2
%
% VERSION CHANGELOG:
% - v0.1 (4/17/2023): Initial commit
% - v0.2 (7/3/2023): Added non-interleave option

    if nargin < 1
        interleaved = 1;
    end
    
    if interleaved
        temp = mseq(2, 7, round(rand * 127), round(rand * 18)); % Generate m-sequence, 7th order
    else
        temp = mseq(2, 8, round(rand * 255), round(rand * 18)); % Generate m-sequence, 8th order
    end
    
    temp = repmat(temp, [3 1]); % Repeat m-sequence 3 times

    seq = zeros(1, 1000);
    
    if interleaved
        for i = 1 : length(temp)
            seq(i * 2) = temp(i); % Interleave 0's between each m-sequence iteration
        end
    end
end

