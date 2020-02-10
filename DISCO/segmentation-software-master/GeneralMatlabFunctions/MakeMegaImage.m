function mega_image = MakeMegaImage(image_stack,mega_image_size)
% mega_image = MakeMegaImage(image_stack,mega_image_size)
% 
% take an image stack and tile them together into a big image.


if nargin<2 || isempty(mega_image_size)
    mega_image_size = ceil(sqrt(size(image_stack,3)));
    mega_image_size(2) = ceil(size(image_stack,3)/mega_image_size);
end

image_stack(:,:,(end+1):(prod(mega_image_size))) = min(image_stack(:));

mega_image = [];

n = 1;
for i=1:mega_image_size(1)
    temp_col = [];
    
    for j=1:mega_image_size(2)
        temp_col = [temp_col;image_stack(:,:,n)];
       
        n = n+1;
    end
    mega_image = [mega_image temp_col];

end

end