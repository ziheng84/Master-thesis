
function filt_feat=createImFilterSetCellTrapStackDIC(cCellSVM,image)
% This function creates a set of image filters used for identifying the
% center of the cells located in the traps. It recieves a cropped image of
% the timepoint containing just the image of the trap. This image has
% the same dimensions as the cPCATrap. The cPCATrap is used to try to
% subtract the trap, and remove it from the image to improve image
% processing, and focus on the cells themselves.
 
% The raw image isn't used as a
 
% cPCATrap.pc_trap1= the first principle component trap
% cPCATrap.pc_trap2= the second principle component trap
 
%image= an image containing the trap and ideally some cells

% cCellSVM - now needs to have the locations of the individual traps
 
%% Normalize the image and traps
n_filt=3;
nHough=2*1;
nHoughIm=0;
nBW=1;
nSym=4;
if isempty(cCellSVM.se)
    cCellSVM.se.se3=strel('disk',3);
    cCellSVM.se.se2=strel('disk',2);
    cCellSVM.se.se1=strel('disk',1);
end
 
se1=cCellSVM.se.se1;
se2=cCellSVM.se.se2;
se3=cCellSVM.se.se3;
 
 
if ~isfield(cCellSVM.se,'trap')||isempty(cCellSVM.se.trap)
     
    cCellSVM.se.trap.f1=fspecial('gaussian',8,5);
    cCellSVM.se.trap.f2=fspecial('gaussian',8,2);
     
    cCellSVM.se.trap.trapEdge=cCellSVM.cTrap.contour;
    cCellSVM.se.trap.trapEdge=imdilate(cCellSVM.se.trap.trapEdge,se1);   
    cCellSVM.se.trap.trapG=imfilter(cCellSVM.se.trap.trapEdge,cCellSVM.se.trap.f1);
    cCellSVM.se.trap.trapG=cCellSVM.se.trap.trapG/max(cCellSVM.se.trap.trapG(:));
    cCellSVM.se.trap.trapG2=imfilter(double((cCellSVM.cTrap.trapOutline)),cCellSVM.se.trap.f2);
 
end
 
f2=cCellSVM.se.trap.f2;
 
imScale=1000;
for slicei = 1:size(image,3)
    tempim = image(:,:,slicei);
    tempim=tempim*imScale/median(tempim(:));
    image(:,:,slicei)=tempim;
end

minim = min(image,[],3);
maxim = max(image,[],3);
rangeim=maxim-minim;
image = cat(3,image,minim,maxim,rangeim);

%normalize over range
im=zeros(size(image));
for slicei = 1:size(image,3)
    
    tempim = image(:,:,slicei);
    tempim=tempim*imScale/median(tempim(:));
    
    im(:,:,slicei)=tempim;
end
 
filt_feat=zeros(size(im,1)*size(im,2),(size(im,3)*n_filt)*nHough + (nHoughIm+1)*(size(im,3)*n_filt)*nBW + size(im,3)*n_filt + nSym,'double');
filt_im=zeros(size(im,1),size(im,2),(size(im,3)*n_filt),'double');
filt_im2=zeros(size(im,1),size(im,2),(size(im,3)*n_filt*nHoughIm),'double');
 
sigma=.5;
h(:,:,1) = fspecial('gaussian', 6, sigma);
h(:,:,2) = fspecial('gaussian', 6, 7*sigma);
 
%% The general pixel based features
for i=1:size(im,3)
    im_slice=im(:,:,i);

    n=true(5);
    temp_im=stdfilt(im_slice,n);
    filt_feat(:,(i-1)*n_filt+1)=temp_im(:);
    filt_im(:,:,(i-1)*n_filt+1)=temp_im;
     
    temp_im=imfilter(temp_im,fspecial('gaussian',6,3),'replicate');
    filt_feat(:,(i-1)*n_filt+2)=temp_im(:);
    filt_im(:,:,(i-1)*n_filt+2)=temp_im;
     
    filt_feat(:,(i-1)*n_filt+3)=im_slice(:);
    filt_im(:,:,(i-1)*n_filt+3)=im_slice;
end
% temp_index=(i-1)*n_filt+temp_index;
 temp_index=(i)*n_filt;

%% The circular hough filters based on the first image set
if ~isfield(cCellSVM.se,'fltr4accum')||isempty(cCellSVM.se.fltr4accum)
    fltr4accum = ones(5,5);
    fltr4accum(2:4,2:4) = 2;
    fltr4accum(3,3) = 6;
    fltr4accum = fltr4accum / sum(fltr4accum(:));
    fltr4accum=imresize(fltr4accum,.9);
    cCellSVM.se.fltr4accum=fltr4accum;
end
fltr4accum=cCellSVM.se.fltr4accum;
fltr4accum2=imresize(fltr4accum,1.5);

for i=1:size(filt_im,3)
    [accum] =  CircularHough_Grd(filt_im(:,:,i), [cCellSVM.radiusSmall floor((cCellSVM.radiusLarge-cCellSVM.radiusSmall)*.5)+cCellSVM.radiusSmall],max(max(filt_im(:,:,i)))*.01,6,fltr4accum);
    temp_index=temp_index+1;
    temp_im=accum;
    filt_im2(:,:,(i-1)*nHough+1)=temp_im;
    filt_feat(:,temp_index)=temp_im(:);    
    
    [accum] =  CircularHough_Grd(filt_im(:,:,i), [ceil((cCellSVM.radiusLarge-cCellSVM.radiusSmall)*.4)+cCellSVM.radiusSmall cCellSVM.radiusLarge],max(max(filt_im(:,:,i)))*.01,11,fltr4accum2);
    temp_im = imfilter((accum),f2,'replicate');
    temp_index=temp_index+1;
    filt_feat(:,temp_index)=temp_im(:);
    filt_im2(:,:,(i-1)*nHough+2)=temp_im;
end
 
%% Filters based on thresholding and distance transforms of the previous filters
n=true(7);
for i=1:size(filt_im,3)%+(size(filt_im2,3)))
    if i-1<size(filt_im,3)
        if rem(i,n_filt)>3 || rem(i,n_filt)==0
            es_im=stdfilt(filt_im(:,:,i),n);
        else
            es_im=filt_im(:,:,i); 
        end
    else
        es_im=filt_im2(:,:,i-size(filt_im,3));
    end
    es_im=es_im/max(es_im(:));
    r=size(es_im,2)/4;c=size(es_im,1)/4;
    for j=1:1
        temp_im=es_im(:,:,j);
        %         temp_im(cCellSVM.cTrap.trapOutline>0)=median(temp_im(:));
        %             thresh=graythresh(temp_im)*.8;
        thresh=.8*graythresh(temp_im(round(r-r*2/3:r+r*2/3),round(c-c*2/3:c+c*2/3)));

        if thresh>.9
            thresh=.9;
        end
        temp_im=im2bw(temp_im,thresh);
        imbw=imdilate(temp_im,se1);
        b_edge=4;
        imbw(1:b_edge,:)=0;
        imbw(:,end-b_edge:end)=0;
        imbw(:,1:b_edge)=0;
        imbw(end-b_edge:end,:)=0;
            im_fill=imfill(imbw,'holes');
        im_fill_notrap=im_fill;
        im_fill_notrap(cCellSVM.cTrap.trapOutline)=0;
                  
        temp_im=bwdist(~im_fill_notrap);
        temp_index=temp_index+1;
        filt_feat(:,temp_index)=temp_im(:);
    end
end
 
%% Add additional features based on symmetry of the trap, and predicted location of the cells
%
mcol=floor(size(im,2)/2);
mrow=floor(size(im,1)/2);
 
temp_im=zeros(size(im,1),size(im,2));
temp_im(:,mcol)=1;
temp_im=bwdist(temp_im);
temp_index=temp_index+1;
filt_feat(:,temp_index)=temp_im(:);
%
temp_im=zeros(size(im,1),size(im,2));
temp_im(mrow,:)=1;
temp_im=bwdist(temp_im);
temp_index=temp_index+1;
filt_feat(:,temp_index)=temp_im(:);
 
temp_im=zeros(size(im,1),size(im,2));
temp_im(mrow,mcol)=1;
temp_im=bwdist(temp_im);
temp_index=temp_index+1;
filt_feat(:,temp_index)=temp_im(:);
%
temp_im=zeros(size(im,1),size(im,2));
temp_im(:,1)=1;temp_im(:,end)=1;
temp_im(1,:)=1;temp_im(end,:)=1;
temp_im(cCellSVM.cTrap.trapOutline)=1;
temp_im=bwdist(temp_im);
temp_index=temp_index+1;
filt_feat(:,temp_index)=temp_im(:);
 
 
 
 
 
 
%%
function [accum, varargout] = CircularHough_Grd(img, radrange, varargin)
 
 
%%%%%%%% Arguments and parameters %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 
% Validation of arguments
if ndims(img) ~= 2 || ~isnumeric(img),
    error('CircularHough_Grd: ''img'' has to be 2 dimensional');
end
if ~all(size(img) >= 32),
    error('CircularHough_Grd: ''img'' has to be larger than 32-by-32');
end
 
if numel(radrange) ~= 2 || ~isnumeric(radrange),
    error(['CircularHough_Grd: ''radrange'' has to be ', ...
        'a two-element vector']);
end
prm_r_range = sort(max( [0,0;radrange(1),radrange(2)] ));
 
% Parameters (default values)
prm_grdthres = 10;
prm_fltrLM_R = 8;
prm_multirad = 0.5;
func_compu_cen = true;
func_compu_radii = true;
 
% Validation of arguments
vap_grdthres = 1;
if nargin > (1 + vap_grdthres),
    if isnumeric(varargin{vap_grdthres}) && ...
            varargin{vap_grdthres}(1) >= 0,
        prm_grdthres = varargin{vap_grdthres}(1);
    else
        error(['CircularHough_Grd: ''grdthres'' has to be ', ...
            'a non-negative number']);
    end
end
 
vap_fltr4LM = 2;    % filter for the search of local maxima
if nargin > (1 + vap_fltr4LM),
    if isnumeric(varargin{vap_fltr4LM}) && varargin{vap_fltr4LM}(1) >= 3,
        prm_fltrLM_R = varargin{vap_fltr4LM}(1);
    else
        error(['CircularHough_Grd: ''fltr4LM_R'' has to be ', ...
            'larger than or equal to 3']);
    end
end
%
% vap_multirad = 3;
% if nargin > (1 + vap_multirad),
%     if isnumeric(varargin{vap_multirad}) && ...
%         varargin{vap_multirad}(1) >= 0.1 && ...
%         varargin{vap_multirad}(1) <= 1,
%     prm_multirad = varargin{vap_multirad}(1);
%     else
%         error(['CircularHough_Grd: ''multirad'' has to be ', ...
%             'within the range [0.1, 1]']);
%     end
% end
 
vap_fltr4accum = 4; % filter for smoothing the accumulation array
% Default filter (5-by-5)
fltr4accum=varargin{end};
% fltr4accum = ones(5,5);
% fltr4accum(2:4,2:4) = 2;
% fltr4accum(3,3) = 6;
% fltr4accum = fltr4accum / sum(fltr4accum(:));
% fltr4accum=imresize(fltr4accum,.6);
 
 
func_compu_cen = ( nargout > 1 );
func_compu_radii = ( nargout > 2 );
 
% Reserved parameters
dbg_on = false;      % debug information
dbg_bfigno = 4;
if nargout > 3,  dbg_on = true;  end
 
 
%%%%%%%% Building accumulation array %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 
% Convert the image to single if it is not of
% class float (single or double)
img_is_double = isa(img, 'double');
if ~(img_is_double || isa(img, 'single')),
    imgf = single(img);
end
 
% Compute the gradient and the magnitude of gradient
if img_is_double,
    [grdx, grdy] = gradient(img);
else
    [grdx, grdy] = gradient(imgf);
end
grdmag = sqrt(grdx.^2 + grdy.^2);
 
% Get the linear indices, as well as the subscripts, of the pixels
% whose gradient magnitudes are larger than the given threshold
grdmasklin = find(grdmag > prm_grdthres);
[grdmask_IdxI, grdmask_IdxJ] = ind2sub(size(grdmag), grdmasklin);
 
rr_4linaccum = double( prm_r_range );
linaccum_dr = [ (-rr_4linaccum(2) + 0.5) : -rr_4linaccum(1) , ...
    (rr_4linaccum(1) + 0.5) : rr_4linaccum(2) ];
 
lin2accum_aJ = floor( ...
    double(grdx(grdmasklin)./grdmag(grdmasklin)) * linaccum_dr + ...
    repmat( double(grdmask_IdxJ)+0.5 , [1,length(linaccum_dr)] ) ...
    );
lin2accum_aI = floor( ...
    double(grdy(grdmasklin)./grdmag(grdmasklin)) * linaccum_dr + ...
    repmat( double(grdmask_IdxI)+0.5 , [1,length(linaccum_dr)] ) ...
    );
 
% Clip the votings that are out of the accumulation array
mask_valid_aJaI = ...
    lin2accum_aJ > 0 & lin2accum_aJ < (size(grdmag,2) + 1) & ...
    lin2accum_aI > 0 & lin2accum_aI < (size(grdmag,1) + 1);
 
mask_valid_aJaI_reverse = ~ mask_valid_aJaI;
lin2accum_aJ = lin2accum_aJ .* mask_valid_aJaI + mask_valid_aJaI_reverse;
lin2accum_aI = lin2accum_aI .* mask_valid_aJaI + mask_valid_aJaI_reverse;
clear mask_valid_aJaI_reverse;
 
% Linear indices (of the votings) into the accumulation array
lin2accum = sub2ind( size(grdmag), lin2accum_aI, lin2accum_aJ );
 
lin2accum_size = size( lin2accum );
lin2accum = reshape( lin2accum, [numel(lin2accum),1] );
clear lin2accum_aI lin2accum_aJ;
 
% Weights of the votings, currently using the gradient maginitudes
% but in fact any scheme can be used (application dependent)
weight4accum = ...
    repmat( double(grdmag(grdmasklin)) , [lin2accum_size(2),1] ) .* ...
    mask_valid_aJaI(:);
clear mask_valid_aJaI;
 
% Build the accumulation array using Matlab function 'accumarray'
accum = accumarray( lin2accum , weight4accum );
accum = [ accum ; zeros( numel(grdmag) - numel(accum) , 1 ) ];
accum = reshape( accum, size(grdmag) );
 
%%%%%%%% Locating local maxima in the accumulation array %%%%%%%%%%%%
% Smooth the accumulation array
accum = filter2( fltr4accum, accum );
