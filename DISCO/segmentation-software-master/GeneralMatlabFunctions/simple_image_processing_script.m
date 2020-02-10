%% general image processing script. 

% here I (Elco) have collected a few useful image processing techniques for
% general images.
% the different modules can be tried in different sequences with changes of
% parameter to get a rough image processing
%
% parameters are roughly chosen for 60x 512 by 512 images and the
% segmentation of fluorescent images

%% load image as img

[file,path] = uigetfile('*.*','please select and image file that can be read by matlab');
img = imread([path file]);
figure(1);
title('raw image')
imshow(img,[])

%% processing for segmentation is perfomred on Img_mod
img_mod = double(img);



%% log

% brings images to a more reasonably scale

img_mod = log(img_mod+1);

%% minfilt

% good for noise/peak removal.

img_mod = minfilt2(img_mod,[5 5],'same');

%% subtract medfilt

% good to remove background trend and reduce the intensity of edges between
% bright objects

img_mod = img_mod - medfilt2(img_mod,[20 20]);

%%

% same but the average rather htan median

f = fspecial('disk',20);
img_mod = img_mod - imfilter(img_mod,f,'symmetric','same');

%%

% often useful to run after the above two blocks.
img_mod(img_mod<0) = 0;


%% smooth

% smooth image with a disk.

f = fspecial('disk',5);
img_mod = imfilter(img_mod,f,'same');


%% show modified image for inspection


figure(2);
title('modified image')
imshow(img_mod,[])
colormap('jet')
%imshow(img_mod>mean(img_mod(:)),[])


%% look at values
imtool(img_mod,[])

%% run a chan vese algorithm to group bright/dim objects

% pretty good for giving a relatively smoother outline


iterations = 100;
u = demo_acwe_mod(img_mod,iterations);

%% as above but without showing output.

% lambda 1/2 are good to play with for smoother/less smooth outlines.

mu=1;
lambda1=1; lambda2=1;
timestep = .1; v=1; epsilon=1;


c0=2;
loc = img_mod>=prctile(img_mod(:),95);
u = zeros(size(img));
u(loc) = c0;
u(~loc) = -c0;

u = acwe(u, img_mod,  timestep,...
             mu, v, lambda1, lambda2, 1, epsilon, 1);

%% threshold result and fill in holes
loc = imfill(u>0,'holes');

%%
cell_label = bwlabel(loc);

%% watershed

% gives separated parts different labels and uses watershed to break up
% convex shapes (like two round cells confused as one lump)
% min filt removes little line breaks, ensures only big sections separated.
cell_identity = watershed(minfilt2(-bwdist(~loc),[3 3],'same'));
%cell_identity = watershed(-bwdist(~loc));
cell_label = zeros(size(loc));
cell_label(loc) = cell_identity(loc);

imshow(cell_label,[])

%% small viewing and editing gui

help simpleCellSelectGUI;

cell_label = simpleCellSelectGUI(double(img),cell_label);


%% analysis

%% load stack of images images
% assumes to stacks of images exported by fiji into the same directory and
% loads them in as ch1_stack and ch2_stack.
% user selects a single image from the stack.
% will get confused if there are numerous timepoints.

% load GFP image
[file,path] = uigetfile('*.*','please select and image from the folder containing the stack you wish to analyse');

% get images andput in stacks
ch1_filename_cell = getFiles(path,['^' file(1:(end-14)) '.*c001\.tif$'],true,true);

ch2_filename_cell = getFiles(path,['^' file(1:(end-14)) '.*c002\.tif$'],true,true);

ch1_stack = imread([path ch1_filename_cell{1}]);

ch2_stack = imread([path ch2_filename_cell{1}]);

num_slices = length(ch1_filename_cell);

for zi = 2:num_slices
    im1 = imread([path ch1_filename_cell{zi}]);
    ch1_stack = cat(3,ch1_stack,im1);
    im2 = imread([path ch2_filename_cell{zi}]);
    ch2_stack = cat(3,ch2_stack,im2);
end

ch1_stack_double = double(ch1_stack);
ch2_stack_double = double(ch2_stack);

%
gui = GenericStackViewingGUI(cat(2,ch1_stack_double/max(ch1_stack_double(:)), ch2_stack_double/max(ch2_stack_double(:))));

%% calculate cross correlation
% specific to Nina's needs. Calcualte cross correlation between pixels in
% the two channels assigned to each cell in cellLabel.
% save the result in the corr_mat matrix.

fprintf('\ncalculating cross correlations . . \n')
num_cells = max(cell_labels(:));

cell_indexes = unique(cell_labels);
cell_indexes(cell_indexes==0) = [];


corr_mat = zeros([num_cells, num_slices+2]);

for ci = 1:num_cells
    indexi = cell_indexes(ci);
    cell_logical = cell_labels==indexi;
    ch1_pix_total = [];
    ch2_pix_total = [];
    
    for zi = 1:num_slices;
        ch1_im = ch1_stack_double(:,:,zi);
        ch2_im = ch2_stack_double(:,:,zi);
        ch1_pix = ch1_im(cell_logical);
        ch2_pix = ch2_im(cell_logical);
        ch1_pix_total = cat(1,ch1_pix_total(:),ch1_pix(:));
        ch2_pix_total = cat(1,ch2_pix_total(:),ch2_pix(:));
        corr_mat(ci,zi) = corr(ch1_pix,ch2_pix);
    end
    corr_mat(ci,num_slices+1) = corr(ch1_pix_total,ch2_pix_total);
    corr_mat(ci,num_slices+2) = sum(cell_logical(:));
end

%% write data to excel
% user selects a location and file name and data is written to an excel
% spreadsheet there. 
% rather slow, probably writing a .csv with print would be quicker.


[save_file, save_path] = uiputfile('data.xls', 'please select a location to save the data');


fprintf('\nwriting . . \n')

if ~isequal(save_file,0) || isequal(save_path,0)
    save_location = [save_path save_file];
    if exist(save_location,'file')
        delete(save_location)
    end
    xlswrite(save_location,{[path file]} ,1,'A1')
    
    for zi = 1:num_slices;
        xlswrite(save_location,{sprintf('slice %d',zi)},1,sprintf('%s3',char(zi+'B'-1)))
    end
    
    xlswrite(save_location,{'whole stack'},1,sprintf('%s3',char(zi+'B')))
    
    xlswrite(save_location,{'cell size (pixels)'},1,sprintf('%s3',char(zi+'B'+1)))
    
    
    for ci = 1:num_cells;
        indexi = cell_indexes(ci);
        xlswrite(save_location,{sprintf('cell %d',indexi)},1,sprintf('A%d',(ci+3)))
    end
    
    
    xlswrite(save_location,corr_mat,1,'B4')
end

fprintf('\n\n finished\n')
