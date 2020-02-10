
%% Define path

SAVE_PATH = 'F:\MA\data\Swain_lab\DISCO_result\str515_GFP_006'; 

%% Save DIM

for i = 1:num_traps
    img = nImageRescale(DIM(:,:,i), 0, 255, -5, 10);
    img = cast(img, 'uint8');
    FILE_NAME = strcat(SAVE_PATH, '\DIM\DIM_TP', nNum2Name(tp), '_', nNum2Name(i), '.png');
    imwrite(img, FILE_NAME, 'Mode', 'lossless');
end


%% Save Segmentation Result

for i = 1:num_traps
    img = nGenerateSegmentationResult(DIM(:,:,i), thresh2);
    img = cast(img, 'uint8');
    FILE_NAME = strcat(SAVE_PATH, '\res\res_TP', nNum2Name(tp), '_', nNum2Name(i), '.png');
    imwrite(img, FILE_NAME, 'Mode', 'lossless');
end

%% FOLLOWING CODES TAKE A WHILE!!!!!!
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Save MULTIPLE Images!!!!
mul_tp = [1, 6, 11, 21, 31, 41, 51, 61, 71, 81, 91, 101, 111, 121, 131];

for i = 1:length(mul_tp)
    % Set timepoint
    tp = mul_tp(i);
    
    % Recalculate DIM
    cTimelapse = cExpGUI.cExperiment.loadCurrentTimelapse(pos);
    cTimelapse.ACParams = cExpGUI.cExperiment.ActiveContourParameters;
    num_traps = length(cTimelapse.cTimepoint(tp).trapInfo);
    tic;
    DIM = cTimelapse.generateSegmentationImages(tp,1:num_traps);
    toc;
    
    for j = 1:num_traps
        % Save DIM
        img = nImageRescale(DIM(:,:,j), 0, 255, -5, 10);
        img = cast(img, 'uint8');
        FILE_NAME = strcat(SAVE_PATH, '\DIM\DIM_TP', nNum2Name(tp), '_', nNum2Name(j), '.png');
        imwrite(img, FILE_NAME, 'Mode', 'lossless');
        % Save Segmentation Result
        img = nGenerateSegmentationResult(DIM(:,:,i), thresh2);
        img = cast(img, 'uint8');
        FILE_NAME = strcat(SAVE_PATH, '\res\res_TP', nNum2Name(tp), '_', nNum2Name(i), '.png');
        imwrite(img, FILE_NAME, 'Mode', 'lossless');
    end

end
