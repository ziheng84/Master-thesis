function [ res ] = nGenerateSegmentationResult( DIM, threshold )
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

%res = DIM;
%[size_x, size_y] = size(DIM);

res_trap = 128 * (DIM == 10);
res_cell = 255 * (DIM < threshold);

res = res_trap + res_cell;

end

