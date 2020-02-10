%% a script for setting a figures properties and then saving it as .png file 

%% for single plots

h = gcf;
a = gca;
LW = 2;
FS = 14;
width = 60;
height = 24;
set(h,'PaperUnits','centimeters',...
     'PaperPosition',[0 0 width height]) %[0 0 width height]
set(get(h,'children'),'FontSize',FS,'LineWidth',LW)
set(get(a,'children'),'LineWidth',LW)
%% for subplots
a = get(h,'children');

for i = 1:length(a);
    try
set(a(i),'LineWidth',LW)
set(a(i),'FontSize',FS)
    catch
    end
end

%% for bars

a = get(gca,'children');
for ai = 1:length(a)
    
    set(a(ai),'BarWidth',1.7)
    
end


%% for box plots
a = get(get(gca,'children'),'children');
for i=1:length(a); set(a(i),'LineWidth',LW);end;

%% set marker face colors to full

a = get(gca,'children');
for i=1:length(a); set(a(i),'MarkerFaceColor',get(a(i),'Color'));end
%%
hptemp = get(h,'Position');
hptemp(3) = (width/height)*hptemp(4);
set(h,'Position',hptemp);
fprintf('figutre position')
display(hptemp);
clear hptemp

%% for plots
set(h,'LooseInset',get(h,'TightInset'))

%% for images
set(gca,'position',[0 0 1 1],'units','normalized','LineWidth',10);
aspect_ratio = get(gca,'PlotBoxAspectRatio'); 
set(gcf,'PaperUnits','centimeters',...
     'PaperPosition',[0 0 (aspect_ratio(1)/aspect_ratio(2))*10 10]) %[0 0 width height]

%% make a shaded blue rectangle

r = rectangle('Position',[0,0,9.97,2e4],'FaceColor',[0 0 0.5 0.2]);


%% writeup

location = '~/Dropbox/ongoing_writeup/logbook_and_notebook_images/segmentation_and_active_contour/2014_10_07_diff_fluor_brightness.png';

%% facs locations

location = '~/Documents/FACS data/2014_07_02_ND(F)GFPstar_expression_check/Analysis/histogram';

%% by gui

dirrr = uigetdir('~/Documents');

nameeee = inputdlg('file name','name box',1,{'.png'});

nameeee = nameeee{1};
%% same dir

%nameeee = 'a.png'

location = fullfile(dirrr,nameeee)
  

saveas(gca,location,'png')


