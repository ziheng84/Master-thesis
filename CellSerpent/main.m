function main(varargin)
    % main.m - main graphical user interface for cell segmentation tool
    %
    % Copyright (C) 2008-2011 Kristian Bredies (kristian.bredies@uni-graz.at),
    %               2010-2011 Florian Leitner (florian.leitner@student.tugraz.at)
    %
    %   This program is free software; you can redistribute it and/or modify
    %   it under the terms of the GNU General Public License as published by
    %   the Free Software Foundation; either version 2, or (at your option)
    %   any later version.
    %
    %   This program is distributed in the hope that it will be useful,
    %   but WITHOUT ANY WARRANTY; without even the implied warranty of
    %   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    %   GNU General Public License for more details.
    %
    %   You should have received a copy of the GNU General Public License
    %   along with this program; if not, write to the Free Software
    %   Foundation, Inc., 51 Franklin Street - Fifth Floor, Boston, MA
    %   02110-1301, USA.
    
    % initialize
    param.action = 'default';
    param.files = {};
    param.debug = 1;
    param = process(param);
    
    % load GUI
    hwnd = openfig('main_ui.fig');
    figure(hwnd);
    gui = get_gui_handles();
    set(gui.status, 'String', {'Ready.'}); 
    initialize_callbacks();
    update_gui_elements();
    
    % check for call with 'quit'
    quit_on_close = 0;
    if (nargin == 1)
        if (strcmp(varargin{1}, 'quit'))
            quit_on_close = 1;
        end
    end

    %%%%%%%%%%%%%%%%%%%%
    % callback functions
    
    % segmentation
    function do_segmentation(obj, event)
        data = guidata(gcbo);
        
        if (isfield(data, 'exe'))
            % give signal to terminate
            mesg(1,'Sending termination request...');
            
            data.abort = 1;
            guidata(gcbo,data);
        else
            % perform action
            param.action = 'do';
        
            oldstr = get(gui.seg.do, 'String');
            set(gui.seg.do, 'String', 'Abort');
            data.exe = 1;
            guidata(gcbo, data);
            
            try
                param_discard = process(param);
            catch
                ME = lasterror;
                message = regexprep(ME.message, '<(.*?)>', ' ');
                
                mesg(1, sprintf('Exception (%s)', ME.identifier));
                mesg(1, message);
                
                stack = 'Stack: ';
                for i=1:length(ME.stack)
                    stack = [stack  sprintf('%d@%s; ', ...
                        ME.stack(i).line, ME.stack(i).name)];
                end
                mesg(1, stack);
            end  
            
            data = guidata(gcbo);
            data = rmfield(data,'exe');
            guidata(gcbo, data);
            set(gui.seg.do, 'String', oldstr);
        end
    end

    function segmentation_conf(obj, event)
        param.action = 'configure';
        param = process(param);
    end

    % report
    function generate_report(obj, event)
        % check if a file is selected
        if (~isfield(param,'files'))
            mesg(1, 'No files to process specified.');
            return;
        end
        numfiles = length(param.files);
        if (numfiles == 0)
            mesg(1, 'No files to process specified.');
            return;
        end
        
        %get selected file and save it to param (is needed i.e. for output
        %of result file
        index_selected = get(gui.files,'Value');
        if (isempty(index_selected))
            index_selected = 1;
        end
        param.selectedFile = index_selected;
        param.action = 'generate';
        param = report(param);
    end

    % populate list in the data_selector_ui.fig with parameters to explore
    function populate_list_with_names(names, gui_explore_data)     
        N = length(names);
        set(gui_explore_data.lists_to_explore,'String',names);
        set(gui_explore_data.lists_to_explore,'Value',1);
    end

    % open data_selector_ui.fig and present the ui
    function do_explore_report(obj, event)          
        isdebug = isfield(param,'debug');
         % check if a file is selected
        if (~isfield(param,'files'))
            mesg(1, 'No files to process specified.');
            return;
        end
        numfiles = length(param.files);
        if (numfiles == 0)
            mesg(1, 'No files to process specified.');
            return;
        end
        % get selected files
        index_selected = get(gui.files,'Value');
        % select first one if none is selected
        if (isempty(index_selected)) 
            index_selected = 1;
        end
        
        mesg(isdebug, 'Invoking exploration dialog.');
        hdlg = openfig('data_selector_ui.fig');
        gui_explore_data = get_gui_handles();
        initialize_callbacks();
        explore_data = 0;
        
        % get the first selected file
        curfile = param.files{index_selected(1)};
        [pathstr, name, ext] = fileparts(curfile);
        resfile = fullfile(pathstr, [name '_res.mat']);
        if (exist(resfile, 'file'))
            % get the calculated parameters
            load(resfile, 'cell_char', 'cell_annot', 'fluor_char', 'fluor_annot');
        end
        populate_list_with_names(cat(2, cell_annot, fluor_annot),gui_explore_data);
        waitfor(hdlg);
        
        if (explore_data == 1)
            param.action = 'explore';
            param = report(param);
        end
    
        function cancel_button(obj, event)
            close(hdlg);
        end
    
        % ok button in the data_selector_ui.fig
        function okay_button(obj, event)
            param.explore.index = index_selected; 
            param.explore.allinoneplot = get(gui_explore_data.allinoneplot,'Value');
            % special case: one file selected and all in one plot -> select
            % all files
            if ((param.explore.allinoneplot == 1) && (length(index_selected) == 1))
                param.explore.index = 1:length(param.files);
            end
            param.explore.numberstoexplore = get(gui_explore_data.lists_to_explore,'Value');
            param.explore.renamexaxis = get(gui_explore_data.rename_x_axis,'Value');
            explore_data = 1;         
            close(gcbf);
        end
    
        function initialize_callbacks()
            % pushbutton callbacks
            set(gui_explore_data.cancel, 'Callback', @cancel_button);
            set(gui_explore_data.okay, 'Callback', @okay_button);   
            set(gui_explore_data.column_number, 'Callback', @check_bounds);           
        end
    
        function gui_explore_data = get_gui_handles()        
            gui_explore_data.cancel = findobj(hdlg,'Tag','cancel');
            gui_explore_data.okay = findobj(hdlg,'Tag','okay');  
            gui_explore_data.column_number = findobj(hdlg,'Tag','column_number'); 
            gui_explore_data.allinoneplot = findobj(hdlg,'Tag','allinoneplot');
            gui_explore_data.rename_x_axis = findobj(hdlg,'Tag','rename_x_axis');
            gui_explore_data.lists_to_explore = findobj(hdlg,'Tag','lists_to_explore'); 
        end
    end

	% open cell_cleaner_ui.fig and present the ui to erase detected cells
    function clean_cells(obj, event)
         % check if a file is selected
        if (~isfield(param,'files'))
            mesg(1, 'No files to process specified.');
            return;
        end
        numfiles = length(param.files);
        if (numfiles == 0)
            mesg(1, 'No files to process specified.');
            return;
        end
        clean_cells = 0;
        mesg(1, 'Invoking cleaning dialog.');
        hdlg = openfig('cell_cleaner_ui.fig');
        gui_cell_cleaner_data = get_gui_handles();
        initialize_callbacks();
        % get selected file
        index_selected = get(gui.files,'Value');
        param.selectedFile = index_selected;
        if (isempty(index_selected))
            index_selected = 1;
        end
        curfile = param.files{index_selected(1)};
        waitfor(hdlg);
        
        if(clean_cells == 1)
            % create a backup of the current _res.mat and _seg.mat file
            create_backup();
            % erase the given cells
            erase_cells();
            % re-number seg file 
            renumber_seg_file();
            % if user selected to update seg image...
            if(param.seg.update_image)
                % ...save the old parameters, perform the operation
                % and resave the user parameters
                user_input_seg_preprocess = param.seg.preprocess;
                user_input_seg_process = param.seg.process;
                user_input_seg_postprocess = param.seg.postprocess;
                param.seg.preprocess = false;
                param.seg.process = false;
                param.seg.postprocess = true;
                % only process the selected file
                param.seg.only_selected_file = true;
                param.action = 'do';
                param = process(param);
                % re-apply user parameters
                param.seg.only_selected_file = false;
                param.seg.preprocess = user_input_seg_preprocess;
                param.seg.process = user_input_seg_process;
                param.seg.postprocess = user_input_seg_postprocess;                
            end
        end
           
        function cancel_button(obj, event)
            close(hdlg);
        end
        
        function clean_button(obj, event)  
            param.clean.cell_numbers = get(gui_cell_cleaner_data.cell_numbers,'String');
            param.seg.update_image = get(gui_cell_cleaner_data.update_seg_image,'Value');
            clean_cells = 1;
            close(gcbf);
        end
    
        function initialize_callbacks()
            % pushbutton callbacks
            set(gui_cell_cleaner_data.cancel_button, 'Callback', @cancel_button);
            set(gui_cell_cleaner_data.clean_button, 'Callback', @clean_button);             
        end
    
        function gui_cell_cleaner_data = get_gui_handles()        
            gui_cell_cleaner_data.cancel_button = findobj(hdlg,'Tag','cancel_button');
            gui_cell_cleaner_data.clean_button = findobj(hdlg,'Tag','clean_button');  
            gui_cell_cleaner_data.cell_numbers = findobj(hdlg,'Tag','cell_numbers'); 
            gui_cell_cleaner_data.update_seg_image = findobj(hdlg,'Tag','update_seg_image');
        end
    end

    % create a backup of the current _res.mat and _seg.mat file
    function create_backup()
        create_backup_res();
        create_backup_seg();
    end

	% create a backup of the _res.mat file with the name _res_backup.mat
    function create_backup_res()
        % get the data from the selected file
        index_selected = param.selectedFile;
        curfile = param.files{index_selected};
        [pathstr, name, ext] = fileparts(curfile);
        resfile = fullfile(pathstr, [name '_res.mat']);
        resfile_backup = fullfile(pathstr, [name '_res_backup.mat']);
        if (exist(resfile, 'file'))
          mesg(1, 'Creating backup of _res file.');
          load(resfile, 'cell_char', 'cell_annot', 'fluor_char', 'fluor_annot');
          save(resfile_backup, 'cell_char', 'cell_annot', 'fluor_char', 'fluor_annot');
        end
    end

	% create a backup of the _seg.mat file with the name _seg_backup.mat
    function create_backup_seg()
        % get the data from the selected file
        index_selected = param.selectedFile;
        curfile = param.files{index_selected};
        [pathstr, name, ext] = fileparts(curfile);
        segfile = fullfile(pathstr, [name '_seg.mat']);
        segfile_backup = fullfile(pathstr, [name '_seg_backup.mat']);
        if (exist(segfile, 'file'))
          mesg(1, 'Creating backup of _seg file.');
          load(segfile, 'im', 'segments', 'snakes', 'Fsnake');
          save(segfile_backup, 'im', 'segments', 'snakes', 'Fsnake');
        end
    end

    % erase the given cells in the current _res.mat and _seg.mat file
    function erase_cells()
        erase_cells_res();
        erase_cells_seg();
    end

    % erase cells for the *_res.mat file and save it
    function erase_cells_res()
        % get the data from the selected file
        index_selected = param.selectedFile;
        % get the user input
        cell_numbers_to_clean = param.clean.cell_numbers;
        cell_number_int = unique(str2num(cell_numbers_to_clean));
        curfile = param.files{index_selected};
        [pathstr, name, ext] = fileparts(curfile);
        resfile = fullfile(pathstr, [name '_res.mat']);
        if (exist(resfile, 'file'))
          load(resfile, 'cell_char', 'cell_annot', 'fluor_char', 'fluor_annot');
          %get the user input and delete the rows, than save it
          cell_char([cell_number_int],:) = [];
          fluor_char([cell_number_int],:) = [];
          save(resfile, 'cell_char', 'cell_annot', 'fluor_char', 'fluor_annot');
          mesg(1, '_res data cleanded and saved.');
        end        
    end
    
    % checks if a given value exceeds the given matrix dimensions
    function in_dimension = check_if_in_dimensions(matrix,number)
        max_dimension = max(matrix(:));
        if(number <= max_dimension)
            in_dimension = true;
        else
            in_dimension = false;
        end
    end

    % erase cells for the *_seg.mat file and save it
    function erase_cells_seg()
        % get the data from the selected file
        index_selected = param.selectedFile;
        % get the user input
        cell_numbers_to_clean = param.clean.cell_numbers;
        cell_number_int = unique(str2num(cell_numbers_to_clean));
        curfile = param.files{index_selected};
        [pathstr, name, ext] = fileparts(curfile);
        segfile = fullfile(pathstr, [name '_seg.mat']);
        if (exist(segfile, 'file'))
          load(segfile, 'im', 'segments', 'snakes', 'Fsnake');
          % first set the cells to erase to 0
          N = length(cell_number_int);
          for i=1:N
            cell_number = cell_number_int(i);
            if(check_if_in_dimensions(segments,cell_number))
                mesg(1, sprintf('Erase cell number %d',cell_number));
                segments(segments(:,:) == cell_number) = 0;
            end
          end
        save(segfile, 'im', 'segments', 'snakes', 'Fsnake');
        mesg(1, '_seg data cleanded and saved.');
        end
    end

    % re-number seg file 
    function renumber_seg_file()
        index_selected = param.selectedFile;
        curfile = param.files{index_selected};
        [pathstr, name, ext] = fileparts(curfile);
        segfile = fullfile(pathstr, [name '_seg.mat']);
        if (exist(segfile, 'file'))
            load(segfile, 'im', 'segments', 'snakes', 'Fsnake');
            N = max(segments(:));
            for i=0:N
               %find the minimun
               min_value = min(segments(segments>=i));
               %if the minimum is not the correct value, change it
                if(min_value ~= i)
                    segments(segments(:,:) == min_value) = i;
                end
            end
            save(segfile, 'im', 'segments', 'snakes', 'Fsnake');
            mesg(1, '_seg data re-numbered.');
        end
    end
    
    % menu routines
    function menu_load(obj, event)
        [name, path] = uigetfile('*.mat','Load job');
        if (ischar(name))
            contents = load([path name], 'param');
            param = contents.param;
            
            % add path of the job file if necessary
            if (isfield(param, 'files'))
                for i=1:length(param.files)
                    [pathstr, name, ext] = fileparts(param.files{i});
                    if (isempty(pathstr))
                        param.files{i} = [path name ext];
                    end
                end
            end
            
            update_gui_elements();
        end
    end
    
    function menu_save(obj, event)
        [name, path] = uiputfile('*.mat','Save job as');
        if (ischar(name))
            save([path name], 'param');
        end
    end
    
    function menu_quit(obj, event)
        if (strcmp(questdlg('Really quit?','CellSerpent'),'Yes'))
            delete(gcbf);
            if (quit_on_close)
                exit;
            end
        end
    end

    function menu_about(obj, event)
        hdlg = openfig('about_ui.fig');
        waitfor(hdlg);
    end

    function menu_help(obj, event)
        web('doc/short_instructions.html');
    end

    % file selection stuff
    function files_add(obj, event) 
        [name, path] = uigetfile({'*.bmp;*.gif;*.jpg;*.jpeg;*.png;*.tif;*.tiff;*.mat', ...
            'All image formats'; ...
            '*.bmp', 'Windows bitmap (*.bmp)'; ...
            '*.gif', 'Graphics interchange format (*.gif)'; ...
            '*.jpg;*.jpeg', 'Joint photographic experts group (*.jpg, *.jpeg)'; ...
            '*.png', 'Portable network graphics (*.png)'; ...
            '*.tif;*.tiff', 'Tagged image file format (*.tif, *.tiff)'; ...
            '*.mat', 'AMIRA Matlab export format (*.mat)'}, ...
            'Select image files', 'Multiselect', 'on');
        
        if (ischar(name) || iscell(name))
            % get index to insert
            firstindex = get(gui.files, 'Value');
            if (isempty(firstindex))
                firstindex = 1;
            else
                firstindex = min(firstindex) + 1;
            end
            
            % deal with inconsistent uigetfile output
            if (iscell(name))
                for i=1:length(name)
                    name{i} = [path name{i}]; 
                end
            else
                name = {[path name]};
            end
            
            param.files = [param.files{1:firstindex-1} ...
                name param.files{firstindex:end}];
            selected = firstindex:(firstindex+length(name)-1);
            
            update_file_box(selected);            
        end
    end

    function files_del(obj, event)
        sel = get(gui.files,'Value');
        
        if (~isempty(sel))
            mask =  ~ismember(1:length(param.files), sel);
            param.files = param.files(mask);
            update_file_box([]);
        end
    end

    function files_move_up(obj, event)
        sel = sort(get(gui.files,'Value'));
        
        N = length(param.files);
        % insert dummy (0)
        perm = 0:N;
        % permute according to selection
        for i=1:length(sel)
            j = sel(i);
            if (j <= N)
                swap = perm(j+1);
                perm(j+1) = perm(j);
                perm(j) = swap;
            end
        end
        % remove dummy
        perm = perm(perm ~= 0);
        
        % compute inverse permutation
        invperm = zeros(N,1);
        invperm(perm) = 1:N;
        
        % apply permutation und update
        files = cell(N,1);
        for i = 1:N
            files{i} = param.files{perm(i)};
        end
        param.files = files;
        newsel = invperm(sel); 
        
        update_file_box(newsel);
    end

    function files_move_down(obj, event)
        sel = sort(get(gui.files,'Value'),2,'descend');
        
        N = length(param.files);
        % insert dummy (0)
        perm = [1:N 0];
        % permute according to selection
        for i=1:length(sel)
            j = sel(i);
            if (j <= N)
                swap = perm(j+1);
                perm(j+1) = perm(j);
                perm(j) = swap;
            end
        end
        % remove dummy
        perm = perm(perm ~= 0);
        
        % compute inverse permutation
        invperm = zeros(N,1);
        invperm(perm) = 1:N;
        
        % apply permutation und update
        files = cell(N,1);
        for i = 1:N
            files{i} = param.files{perm(i)};
        end
        param.files = files;
        newsel = invperm(sel); 
        
        update_file_box(newsel);
    end

    % replacement rule stuff
    function file_pat_changed(obj, event)
        str = get(gui.file.fluor_pat, 'String');
        param.seg.post_fluor_pat = str;
    end

    function file_rep_changed(obj, event)
        str = get(gui.file.fluor_rep, 'String');
        param.seg.post_fluor_rep = str;
    end
        
    %%%%%%%%%%%%%
    % gui stuff
    function update_file_box(sel)
        str = cell(length(param.files),1);
        for i=1:length(param.files)
            [path,name,ext] = fileparts(param.files{i});
            str{i} = [name ext];
        end
        set(gui.files, 'ListboxTop', min(max(1,length(param.files)), ...
            max(1, get(gui.files, 'ListboxTop'))));
        set(gui.files,'String',str);
        set(gui.files, 'Value', sel);        
    end

    function update_gui_elements()
        % sets the adjustable elements according to param

        update_file_box([]);
        set(gui.files, 'Value', []);
        
        set(gui.file.fluor_pat, 'String', param.seg.post_fluor_pat);
        set(gui.file.fluor_rep, 'String', param.seg.post_fluor_rep);
    end
    
    function initialize_callbacks()
        % set all callback functions
        set(hwnd, 'CloseRequestFcn', @menu_quit);
        
        % menu 
        set(gui.menu.load, 'Callback', @menu_load);
        set(gui.menu.save, 'Callback', @menu_save);
        set(gui.menu.quit, 'Callback', @menu_quit);
        set(gui.menu.about, 'Callback', @menu_about);
        set(gui.menu.help, 'Callback', @menu_help);
        
        % files selection
        set(gui.file.add, 'Callback', @files_add);
        set(gui.file.del, 'Callback', @files_del);
        set(gui.file.up, 'Callback', @files_move_up);
        set(gui.file.down, 'Callback', @files_move_down);
        
        % replacement rule
        set(gui.file.fluor_pat, 'Callback', @file_pat_changed);
        set(gui.file.fluor_rep, 'Callback', @file_rep_changed);
        
        % segmentation buttons
        set(gui.seg.do, 'Callback', @do_segmentation);
        set(gui.seg.conf, 'Callback', @segmentation_conf);
        
        % report buttons
        set(gui.report.do, 'Callback', @generate_report);
        set(gui.report.expl, 'Callback', @do_explore_report);
        set(gui.report.clean, 'Callback', @clean_cells);
    end
    
    function gui = get_gui_handles()
        % output elements
        gui.axes = findobj(hwnd,'Tag','outputwindow');
        gui.status = findobj(hwnd,'Tag','outputtext');
        
        % menu
        gui.menu.load = findobj(hwnd,'Tag','load');
        gui.menu.save = findobj(hwnd,'Tag','save');
        gui.menu.quit = findobj(hwnd,'Tag','quit');
        gui.menu.help = findobj(hwnd,'Tag','instructions');
        gui.menu.about = findobj(hwnd,'Tag','about');
        
        % file dialog
        gui.files = findobj(hwnd,'Tag','files');
        gui.file.add = findobj(hwnd,'Tag','files_add');
        gui.file.del = findobj(hwnd,'Tag','files_remove');
        gui.file.up = findobj(hwnd,'Tag','files_move_up');
        gui.file.down = findobj(hwnd,'Tag','files_move_down');
        gui.file.fluor_pat = findobj(hwnd,'Tag','fluor_pat');
        gui.file.fluor_rep = findobj(hwnd,'Tag','fluor_rep');
        
        % segmentation dialog
        gui.seg.do = findobj(hwnd,'Tag','segmentation_do');
        gui.seg.conf = findobj(hwnd,'Tag','segmentation_configure');
        
        % report dialog
        gui.report.do = findobj(hwnd,'Tag','report_do');
        gui.report.expl = findobj(hwnd,'Tag','report_explore');
        gui.report.clean = findobj(hwnd,'Tag','report_clean');
    end
end
