function [ assignments ] = simpleCellSelectGUI(img,assignments )
% [ assignments ] = simpleCellSelectGUI(show_img,initial_assignments )
% a simple gui for select and removing cells in an image. takes an image
% (img) and a labelled img (just a bwlabel of a logical). It then displayed
% the image with a jet color map for inspection and another copy with
% the assigments colour coded and overlaid. The user can then click to
% change the assignment as followed:
%
% right click  =>  remove an area
%
% one left click followed by one right click => draws a single line which
% is used to separate two joined cells (i.e. all pixels under that line are
% set to zero)
%
% series of left clicks terminated with a right click => draws an area
% which is then added as a new area to the assignment image.
% 
% when the user is satisfied, press enter to terminate the process and
% obtain the assignment image.
%
% based on the getline function.

if nargin<2 || isempty(assignments)
    assignments = zeros(size(img));
end

img = double(img);
f_show = figure;
imshow(img,[]);
colormap('jet');
img = img-min(img(:));
img = img/max(img(:));
img = repmat(img,[1,1,3]);

f = figure('Menu','none');
show_img = makeShowImage(img,assignments);
imshow(show_img,[]);
f_position = get(f,'position');
keep_select = true;

while keep_select 
    figure(f);
    show_img = makeShowImage(img,assignments);
    imshow(show_img,[]);
    set(f,'position',f_position);
    selected_line = getline('closed');
    switch size(selected_line,1);
        case 0
            %pressed enter => end selection
            keep_select = false;
        case 2
            %just right click => remove a cell
            to_remove = assignments(round(selected_line(1,2)),round(selected_line(1,1)));
            if to_remove>0
                assignments(assignments==to_remove) = 0;
                assignments(assignments>to_remove) = assignments(assignments>to_remove) -1;
            end
        case 3
            % a line => set separate cells joined by the line           
            vec = [selected_line(2,1) - selected_line(1,1) selected_line(2,2) - selected_line(1,2)];
            vec_len = (sqrt(sum(vec.^2)));
            
            to_remove_x = round(linspace(floor(selected_line(1,1)),ceil(selected_line(2,1)),ceil(vec_len*5)));
            to_remove_y = round(linspace(floor(selected_line(1,2)),ceil(selected_line(2,2)),ceil(vec_len*5)));
            
            assignments(to_remove_y + ((to_remove_x-1)*size(assignments,1))) = 0;
            assignments = bwlabel(assignments>0,4);
            
        otherwise
            % line => add a cell
            area = areaFromPolygon(selected_line,size(assignments));
            % dilate to create a non contact border around new area
            se = strel('disk',1);
            assignments(imdilate(area,se,'same')) = 0;
            assignments(area) = max(assignments(:)) +1;       
    end
    f_position = get(f,'position');
end

close(f);
close(f_show);

end

function show_img = makeShowImage(img,assignment)

    show_img = 0.8*img + 0.2*(double(label2rgb(assignment,'jet','k','shuffle'))/255);

end