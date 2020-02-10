function [birthKymo, croppedKymo]=birthEventsKymo(data)

%Generates and plots a kymograph showing birth events vs time for single
%cells in a dataset. Requires the 'data' structure generated by the function
%compileBirthsForPlot
%data=cExperiment.lineageInfo.dataForPlot;

birthKymo=sparse(zeros(size(data.bTime,1),196));
for n=1:size(data.bTime,1)
    times=data.bTime(n,:);
    times(times==0)=[];
    birthKymo(n,times)=true;
end

%Add a bar at the bottom showing the application of drug (or other condition)

birthKymo(end+1:end+10,:)=sparse(zeros);
birthKymo(end-10:end,60:180)=0.5;
figure;imshow(full(birthKymo));





% To make a coloured kymograph showing the time of the drug application eg:
% colKymo=zeros(size(birthKymo,1),size(birthKymo,2),3);%
% colKymo(:,60:180,1)=.2;%(tps 60-180 shaded red, for eg times 5-15h)
% colKymo(:,:,1)=birthKymo;
% colKymo(:,:,2)=birthKymo;
% colKymo(:,:,3)=birthKymo;%Birth events now white
% imshow(colKymo);figure(gcf)




%To order the kymograph according to median GFP expression at a given
%timepoint
%This assumes that GFP (or whatever channel you want to measure) is the 2nd
%channel (cExperiment.cellInf(2)); Change to 1 if it's channel 1
%Loop through the cells
birthKymo=sparse(zeros(size(data.bTime,1),237));
refTimepoint=1;%eg end of drug application - 180=15hrs after start of expt
%loop through the mother cells, collecting median GFP levels
%for n=1:size(data.bTime,1)

for c=1:size(data.bTime,1)

    data.median(c)=cExperiment.cellInf(1).median(data.motherIndices(c),refTimepoint);
    data.mean(c)=cExperiment.cellInf(1).mean(data.motherIndices(c),refTimepoint);

end

%Sort motherIndices based on mean GFP values
[sorted sortIndices]=sort(data.median);


%for n=1:size(data.bTime,1)
for n=1:size(data.bTime,1)

times=data.bTime(sortIndices(n),:);
    times(times==0)=[];
    birthKymo(n,times)=1;
end




%Add a bar at the right showing the range of median GFP values
medianValuesImage=sparse(zeros(size(birthKymo,1),10));
%for n=1:size(data.bTime,1)

for n=1:size(data.bTime,1)
    medianValuesImage(n,:)=cExperiment.cellInf(1).median(data.motherIndices(sortIndices(n)),refTimepoint);
end
%Scale the median values between 0 and 1
maxMedian=max(max(medianValuesImage));
medianValuesImage=medianValuesImage./maxMedian;
birthKymo(:,size(birthKymo,2)+1:size(birthKymo,2)+10)=medianValuesImage;

%Add a bar at the bottom showing the application of drug (or other condition)

birthKymo(end+1:end+10,:)=sparse(ones);
birthKymo(end-10:end,60:180)=0.5;
figure;imshow(full(birthKymo));


%Plot the number of births after a specific time point vs the expression level at
%the ref point
croppedKymo=birthKymo(1:end-11,120+1:end-10);
numDivs=sum(croppedKymo');
meanOfMedians=[];
for n=0:max(numDivs)
    thisNumBirths=numDivs==n;
    meanOfMedians(n+1)=mean(data.median(thisNumBirths));
end


