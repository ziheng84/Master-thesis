function flipExperimentImages(flipChannel,refChannel,cExperiment,timepoint,refpos, poses)
%%modified version by Luis Montano 20161005. modification makes it start from a cExperiment to obtain the root folder.
%%this allows to select the positions we want to flip
%flipExperimentImages Correct for vertically flipped channels
%   flipExperimentImages(flipChannel,refChannel,exptFolder) Correct for a
%   bug in microscope acquisition software where some channels are
%   vertically flipped with respect to others. The function first displays
%   an overlay image showing the result of the flip and confirms whether
%   the user really wants to flip all images.
%       flipChannel: the channel to be flipped (default 'cy5')
%       refChannel: a channel to display as a reference image (default
%       'DIC_003')
%       exptFolder: base folder for an experiment -- all sub folders will
%       be iterated through. Defaults to selecting folder in dialog box.

if nargin<1 || isempty(flipChannel)
    flipChannel = 'cy5';
end

if nargin<2 || isempty(refChannel)
    refChannel = 'DIC_003';
end

if nargin<3 || isempty(cExperiment)
    exptFolder = uigetdir;
else
    exptFolder=cExperiment.rootFolder;
end

if nargin<4 || isempty(timepoint)
    timepoint = 1;
end

if nargin<5 || isempty(refpos)
    refpos = 1;
end


% Determine the position directories containing the images
exptContents = dir(exptFolder);
posdirs = {exptContents.name};
nothidden = cellfun(@(d) isempty(regexp(d,'^\.','once')),posdirs);
posdirs = posdirs([exptContents.isdir] & nothidden);
posdirs = cellfun(@(x) [exptFolder,filesep,x,filesep],posdirs,'UniformOutput',false);

if nargin<6 || isempty(poses) || numel(poses)>numel(posdirs) %had to wait to obtain posdirs for this. it assigns poses to be the total length of posdirs
    poses=1:numel(posdirs);
end

posdirs= posdirs(poses) %making sure that the positions selected are the ones flipped.
% Define wildcard search strings for flip and reference channels:
wild_card = [posdirs{refpos},'*',flipChannel,'*.png'];
refWC = [posdirs{refpos},'*',refChannel,'*.png'];

% First check with user if the images in this folder need to be flipped:
flipContents = dir(wild_card);
refContents = dir(refWC);

if isempty(flipContents)
    error('Experiment does not have "%s" channel.',flipChannel);
end
if isempty(refContents)
    error('Experiment does not have "%s" channel.',refChannel);
end

posFileNames = sort({flipContents.name});
%temp
%posFileNames=posFileNames(3:end)
refFileNames = sort({refContents.name});
%refFileNames=refFileNames(3:end)
% Load and normalise the images:
posImFirst = normalise(imread([posdirs{refpos},posFileNames{timepoint}]));
posImLast = normalise(imread([posdirs{refpos},posFileNames{end}]));
refImFirst = normalise(imread([posdirs{refpos},refFileNames{timepoint}]));
refImLast = normalise(imread([posdirs{refpos},refFileNames{end}]));

% Plot the images for comparison:
fig = figure;
subplot(2,2,1); overlayPlot(posImFirst,refImFirst); title('First without flip');
subplot(2,2,2); overlayPlot(posImFirst(end:-1:1,:),refImFirst); title('First with flip');
subplot(2,2,3); overlayPlot(posImLast,refImLast); title('Last without flip');
subplot(2,2,4); overlayPlot(posImLast(end:-1:1,:),refImLast); title('Last with flip');

confirmation = questdlg('Do you want to proceed with flipping?');
close(fig)
if ~strcmp(confirmation,'Yes')
    return
end

% Initialise a progress bar
progress_bar = Progress();
% Centre the dialog box
progress_bar.frame.setLocationRelativeTo([]);
% Set the progress bar title
progress_bar.frame.setTitle('Flipping images...');

% Begin progress loop over each directory:
progress_bar.push_bar('Directory',1,length(posdirs));

% Open a file to log the changes to:
file_handle = fopen([exptFolder,filesep,'flip_log_.txt'],'at');

% Iterate through the dirs and flip relevant images
for idir = 1:length(posdirs)
    progress_bar.set_val(idir);
    
    wild_card = [posdirs{idir},'*',flipChannel,'*.png'];
    flipContents = dir(wild_card);
    posFileNames = {flipContents.name};
    
    % Begin progress loop over each image:
    progress_bar.push_bar('Image',1,length(posFileNames));
    for ifile=1:length(posFileNames)
        progress_bar.set_val(ifile);
        filename = [posdirs{idir},posFileNames{ifile}];
        %try
        im = imread(filename);
        im = im(end:-1:1,:);
        imwrite(im,filename);
        fprintf(file_handle,'Flipped %s\n',filename);
        %catch err
        %    sprintf('problem with file %s', filename)
        %    errorFiles={errorFiles, filename}
    end
    progress_bar.pop_bar; % finished all images
end

fclose(file_handle);

% Clean up progress bar:
progress_bar.pop_bar; % finished all directories
progress_bar.frame.dispose;

end

function out = normalise(im)
im = double(im);
imMin = min(im(:));
imMax = max(im(:));

out = (im-imMin)/(imMax-imMin);
end

function overlayPlot(im1,im2)
image(cat(3,im1,im2,zeros(size(im1))));
end