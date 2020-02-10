function [ str ] = nNum2Name( num )
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here

if num < 0
    error('Number cannot be smaller as 0!');
end

if num < 10
    str = strcat('0', num2str(num));
else
    str = num2str(num);
end
    
end

