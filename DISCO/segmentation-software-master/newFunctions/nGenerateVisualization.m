
%% Generate image seperately

for i = 1:5 
    figure;
    subplot(2,2,1),
    imshow(trapImage(:,:,i), []);
    title('Trap Image')
    
    subplot(2,2,3),
    imshow(DIM(:,:,i), []);
    colorbar
    title('Decision Image');
    
    subplot(2,2,2),
    imshow(OverlapGreyRed(trapImage(:,:,i),DIM(:,:,i)<thresh1,[],DIM(:,:,i)<thresh2,true));
    title('Segmentation Result')
end

