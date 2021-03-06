%% load image
url='http://blogs.mathworks.com/images/steve/166/labeled_regions_grayscale_01.jpg';
image = rgb2gray(imread(url));
imshow(image, 'InitialMagnification', 'fit');

%% subpixel detection
threshold = 25;
edges = subpixelEdges(image, threshold); 

%% show edges
visEdges(edges);
