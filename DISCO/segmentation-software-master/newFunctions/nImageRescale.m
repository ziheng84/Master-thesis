function [ output_img ] = nImageRescale( input_img, L, U, min, max)
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here

if nargin>3
    MAX = max;
    MIN = min;
else
    MAX = max(max(input_img));
    MIN = min(min(input_img));
end

%disp(MAX)

% p_old - MIN / MAX - MIN = p_new - l / u - l

output_img = ((input_img - MIN) * (U - L) / (MAX - MIN)) + L;

end

