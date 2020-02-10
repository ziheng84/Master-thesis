
%% Transfer "segments_cell" and "segments_trap" into standard form

res_cell = 2*(segments_cell ~= 0);
res_trap = (segments_trap ~= 0);

res_1 = res_cell + res_trap;

imagesc(res_1);
colorbar;

%% Remove noise

res = 128*(res_1 == 1) + 255*(res_1 == 2);

imagesc(res);
colorbar;

%% Define Name
PATH =  'F:\MA\tools\CellSerpent\segmentation\res\str515_229_raff2_to_gal2_various_exposures_4V_00_str515_GFP_006_tp000021_Brightfield_002_res.png';

%% Save img

 imwrite(cast(res, 'uint8'), PATH, 'Mode', 'lossless');
