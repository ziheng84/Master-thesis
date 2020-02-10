function area = areaFromPolygon( coords,img_area )
% area = areaFromPolygon( coords,img_area )
% makes a logical of size img_area where the polygon specified by the
% coordinates is filled in.
% coords is x,y pairs - assumed looped
%
% built to work with the output from getline('closed')
%
% example:
% > imshow(img)
% > line = getline('closed')
% > outlined_area = areaFromPolygon(line,size(img))

area = false(img_area);

test = false;

if size(coords,1) <2
    return
end

coords(end+1,:) = coords(1,:);
coords(coords<0) = 1;
coords(coords(:,1)>img_area(2),1) = img_area(2);
coords(coords(:,2)>img_area(2),1) = img_area(1);


xs = repmat(1:img_area(2),img_area(1),1);
ys = repmat((1:img_area(1))',1,img_area(2));
%record = zeros(size(area));
if test
    f = figure;
end

% just makes the code happend twice if the area is zero because the points
% were selected in the opposite order.
for j=1:2
    area = true(img_area);
    
    for i = 1:(size(coords,1) -1 )
        
        dot_product = ([-(coords(i+1,2)-coords(i,2)) coords(i+1,1)-coords(i,1)])* [xs(:)' - coords(i,1) ; ys(:)' - coords(i,2) ];
        area(dot_product<0) = false;
        
        if test
            imshow(area,[]);
            hold on
            plot(coords(:,1),coords(:,2),'or')
            pause
        end
        
    end
    if sum(area(:)) ~= 0
        break
    else
        coords = flipud(coords);
    end
end

if test
    close(f);
end
%area = mod(2,record)>0;

end

