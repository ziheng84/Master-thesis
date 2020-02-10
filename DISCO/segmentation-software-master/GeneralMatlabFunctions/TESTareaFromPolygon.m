%% little test script for function of the same name


while true
figure(1);
img = double(img);
imshow(img,[])
line = getline('closed');
area = areaFromPolygon(line,size(img));
imshow(double(img)+max(img(:))*area,[]);
hold on
plot(line(:,1),line(:,2),'or')
pause
end