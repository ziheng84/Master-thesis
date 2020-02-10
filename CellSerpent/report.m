function param = report(param)
    % report.m - report generation module
    % -----------------------------------
    %
    % - generates basic reports
    % - provides a data exploration gui
    % 
    % param: parameter structure - fields:  
    % 
    % action - 'generate' generates report after asking user
    %          'explore' invokes data exploration dialog
    %
    % files - list of images to process
    %
    % debug - if set, debug output will be produced
    %
    %
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
    
    
    % check for action
    if (~isfield(param,'action'))
        mesg(1, 'Could not determine what to do.');
        return;
    end
    
    isdebug = isfield(param,'debug');
    
    action = 0;
        
    if (strcmp(param.action,'generate'))
        % configuration
        action = 1;
        
        % check for file list
        if (~isfield(param,'files'))
            mesg(1, 'No files to process specified.');
            return;
        end
        
        numfiles = length(param.files);
        if (numfiles == 0)
            mesg(1, 'No files to process specified.');
            return;
        end
        
        % first ask for filename etc.
        mesg(isdebug, 'Invoking export dialog.');
        [param, okay] = configure_report(param);
        
        if (okay)
            mesg(isdebug, 'Generating report...');
            param = generate_report(param);
        else
            mesg(isdebug, 'Report generation canceled.');
        end
    end
    
    
    if (strcmp(param.action,'explore'))
        % batch processing
        action = 1;
      
        mesg(isdebug, 'Exploring data...');
        param = explore_data(param);
    end
    
    if (action == 0)
        mesg(1, sprintf('Action ''%s'' not implemented.', param.action));
    end 
end

%%%%%%%%%%%%%%%%%%%%%%%
% report configuration
function [param, save_settings] = configure_report(param)
    param_old = param;

    hdlg = openfig('rep_gen_ui.fig');
    
    if (~isfield(param,'report'))
        % initialize with default values
        % get selected filename with param.selectedFile
        outputfile = param.files{param.selectedFile(1)};
        [pathstr, name, ext] = fileparts(outputfile);
        outputfile = fullfile(pathstr, [name '_report_detailed.csv']);
%        outputfile = 'report.csv';
        param.report.outputfile = outputfile;
        param.report.type = 'csv_detailed';
    end
    
    gui = get_gui_handles();
    initialize_values();
    initialize_callbacks();
    
    save_settings = 0;
    waitfor(hdlg);
    if (~save_settings)
        param = param_old;
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%
    % callbacks
    function okay_button(obj, event)
        save_values();
        save_settings = 1;
        close(gcbf);
    end

    function cancel_button(obj, event)
        close(gcbf);
    end

    function type_csv_det(obj, event)
        outputfile = param.files{param.selectedFile(1)};
        [pathstr, name, ext] = fileparts(outputfile);        
        outputfile = fullfile(pathstr, [name '_report_detailed.csv']);
        param.report.outputfile = outputfile; 
        set(gui.filename, 'String', param.report.outputfile);
    end

    function type_csv_agg(obj, event)
        outputfile = param.files{param.selectedFile(1)};
        [pathstr, name, ext] = fileparts(outputfile);                                                                                                     
        outputfile = fullfile(pathstr, [name '_report_aggegrated.csv']);
        param.report.outputfile = outputfile;
        set(gui.filename, 'String', param.report.outputfile);
    end


    function filename_select(obj, event)
        [name, path] = uiputfile({'*.csv', ...
            'Comma separated values (*.csv)'}, 'Save report as');
        if (ischar(name))
            param.report.outputfile = [path name];
            set(gui.filename, 'String',param.report.outputfile);
        end
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % initalization and save routines
    function initialize_callbacks()
        % pushbutton callbacks
        set(gui.okay, 'Callback', @okay_button);
        set(gui.cancel, 'Callback', @cancel_button); 
        
        % filename selection callback
        set(gui.filename_sel,'Callback', @filename_select);
        
        % filetype selection callbacks
        set(gui.type.csv_det, 'Callback', @type_csv_det);
        set(gui.type.csv_agg, 'Callback', @type_csv_agg);
        
    end
    
    function save_values()
        param.report.outputfile = get(gui.filename,'String');
        
        if (get(gui.type.csv_agg, 'Value'))
            param.report.type = 'csv_aggegrated';
        end
        if (get(gui.type.csv_det, 'Value'))
            param.report.type = 'csv_detailed';           
        end
    end
    
    function initialize_values()
        set(gui.filename, 'String', param.report.outputfile);
        set(gui.type.csv_agg, 'Value', strcmp(param.report.type, 'csv_aggegrated'));
        set(gui.type.csv_det, 'Value', strcmp(param.report.type, 'csv_detailed'));
    end
    
    function gui = get_gui_handles()        
        gui.okay = findobj(hdlg,'Tag','okay');
        gui.cancel = findobj(hdlg,'Tag','cancel');
        
        gui.filename = findobj(hdlg,'Tag','filename');
        gui.filename_sel = findobj(hdlg,'Tag','filename_select');

        gui.type.csv_agg = findobj(hdlg,'Tag','type_csv_agg');
        gui.type.csv_det = findobj(hdlg,'Tag','type_csv_det');
    end
end

%%%%%%%%%%%%%%%%%%%%%
% report generation
function param = explore_data(param)
        isdebug = isfield(param, 'debug');
        
        % test for statistics toolbox
        have_statistics_toolbox = 0;
        mver = ver();
        for i=1:length(mver)
            if (strcmp(mver(i).Name, 'Statistics Toolbox'))
                have_statistics_toolbox = 1;
            end
        end
        
        N = length(param.files(param.explore.index));
        numbers_to_explore = length(param.explore.numberstoexplore);
        exploredatafromrow = param.explore.numberstoexplore;
        allinoneplot = param.explore.allinoneplot;
        rename_x_axis = param.explore.renamexaxis;
        
        %go through each file
        for i=1:N
            
            % get _res.mat filename
            curfile = param.files{param.explore.index(i)};
            [pathstr, name, ext] = fileparts(curfile);
            resfile = fullfile(pathstr, [name '_res.mat']);
            
            % process results
            if (exist(resfile, 'file'))
                load(resfile, 'cell_char', 'cell_annot', 'fluor_char', 'fluor_annot');
                output_firstline = cat(2, cell_annot, fluor_annot);
                mesg(isdebug, sprintf('Result file ''%s'' loaded.', resfile));
                
                clear data;
                clear numberofentries;
                clear numberofentriesarray;
                data = cat(2,cell_char, fluor_char);
                numberofentries = size(data,1);
                numberofentriesarray(:,1) = 1:numberofentries;
                
                if((allinoneplot == 1) && (i < 2))
                  statisticpicture = figure;
                end
                
                % one plot for each file and only one parameter to plot
                if((allinoneplot == 0) && (numbers_to_explore == 1))
                  statisticpicture = figure;
                  % only one plot in a figure -> only one color needed
                  plotcolor = [0 0 1];
                  legendname = output_firstline(exploredatafromrow);
                end 
                
                % one plot for each file and more parameters to plot
                if((allinoneplot == 0) && (numbers_to_explore > 1))
                  statisticpicture = figure;
                  % more than on plot in a figure -> each plot needs his 
                  % own color
                  plotcolor = [      0         0    1.0000
                                     0    0.5000         0
                                1.0000         0         0
                                     0    0.7500    0.7500
                                0.7500         0    0.7500
                                0.7500    0.7500         0
                                0.2500    0.2500    0.2500];
                  legendname = output_firstline(exploredatafromrow);
                end
                
                % all selected parameters and all files in one plot
                if(allinoneplot == 1)
                    plotcolor = rand(1,3)*0.8;
                    legendname(i) = {name};
                end
                
                figure(statisticpicture);
                mesg(isdebug, sprintf('Creating plot...'));
                hold('on');
                
                % display title
                if (allinoneplot == 1)
                    titlename = output_firstline(exploredatafromrow);
                else
                    titlename = name;
                end
                title(titlename);
                
                plotstyle = '--+';
                
                % method to rename the x axis with the corresponding entry number
                % add a new column and number all entries
                [m,n] = size(data);
                data(:,n) = [1:m];
                [m,n] = size(data);
                % sort the entries with the selected option
                data = sortrows(data,-exploredatafromrow);
                % create plot
                set(gca,'ColorOrder', plotcolor);
                plot(numberofentriesarray(:,1), data(:,exploredatafromrow), plotstyle);
                if(rename_x_axis)
                    % set XTick that all values are used
                    set(gca,'XTick',1:max(data(:,n)));
                    % rename the x axis with the corresponding entry number                
                    set(gca,'XTickLabel',data(:,n));
                end
                legend(legendname);

                % if one plot for each file and only one parameter to plot
                % also calculate and print some stuff to the plot
                if((allinoneplot == 0) && (numbers_to_explore == 1))
                    achsen = axis(); 
                    textpos_x = (achsen(1) + achsen(2))/10; 
                    textpos_y = (achsen(3) + achsen(4)/1.1); 
                    %mean
                    meanvalue = mean(data(:,exploredatafromrow));
                    %standard deviation
                    standarddeviationvalue = std(data(:,exploredatafromrow));
                    %median
                    medianvalue = median(data(:,exploredatafromrow));
                    
                    statistic_data(1) = {sprintf('Mean: %i', meanvalue)};
                    statistic_data(2) = {sprintf('Standard Deviation: %i', standarddeviationvalue)};
                    statistic_data(3) = {sprintf('Median: %i', medianvalue)};
                    
                    %T-Test/Kolmogorov Smirnov test;
                    if (have_statistics_toolbox)
                        [h,p,ci,stats] = ttest(data(:,exploredatafromrow));
                        statistic_data(4) = {sprintf('T-Test: %i', p)};                
                    end
                    
                    text(textpos_x, textpos_y, statistic_data);
                    titlename_without_special_characters =  regexprep(legendname{1}, '[\W]', '_');
                    filename_with_identifier = ['_statistic_' titlename_without_special_characters '.jpg'];
                    savefile = fullfile(pathstr, [name filename_with_identifier]);
                    saveas(statisticpicture,savefile);
                    mesg(isdebug, sprintf('Plot saved in ''%s''.', savefile));
                end
                
                if(allinoneplot == 0)
                  hold('off');    
                end
                
                if(numbers_to_explore > 1)
                  savefile = fullfile(pathstr, [name '_statistic_several.jpg']);
                  saveas(statisticpicture,savefile);
                  mesg(isdebug, sprintf('Plot saved in ''%s''.', savefile));                    
                end
            end
        end
        
        if(allinoneplot == 1)
          hold('off');           
          name = 'total';
          savefile = fullfile(pathstr, [name '_statistic.jpg']);
          saveas(statisticpicture,savefile);
          mesg(isdebug, sprintf('Plot saved in ''%s''.', savefile));
        end
end

%%%%%%%%%%%%%%%%%%%%%
% report generation
function param = generate_report(param)
    % generates report according to param.report
    %
    % valid param.report.types:
    % csv_aggegrated - aggegrated list
    % csv_detailed - detailed list
    
    
    isdebug = isfield(param, 'debug');
    type = param.report.type;
    file = fopen(param.report.outputfile, 'w');
    
    % csv output types
    if (strcmp(type,'csv_aggegrated') ...
            || strcmp(type,'csv_detailed'))
        
        firstline = 0;
        entrynum = 0;
        
        N = length(param.files);
        for i=1:N
            % get results filename
            curfile = param.files{i};
            [pathstr, name, ext] = fileparts(curfile);
            resfile = fullfile(pathstr, [name '_res.mat']);
            
            % process results
            if (exist(resfile, 'file'))
                load(resfile, 'cell_char', 'cell_annot', 'fluor_char', 'fluor_annot');
                mesg(isdebug, sprintf('Result file ''%s'' loaded.', resfile));
                
                % output first line if necessary
                if (~firstline)
                    entrynum = length(cell_annot)+length(fluor_annot);
                    csv_output_firstline(file, cat(2, {'filename', 'cell number'}, ...
                        cell_annot, fluor_annot));
                    firstline = 1;
                end
                
                data = cat(2,cell_char,fluor_char);
                if (size(data,2) == entrynum)
                    csv_output_data(file, curfile, data, strcmp(type, 'csv_aggegrated'));               
                    mesg(isdebug, sprintf('Output generated to ''%s''.', param.report.outputfile));
                else
                    mesg(1,'Description and data sizes do not match. Skipping.');
                end
            else
                mesg(1,sprintf('Result file ''%s'' does not exist. Skipping.', resfile));
            end
            
        end
    end
    
    fclose(file);
end


% support functions
function csv_output_firstline(file, names)
    % write first line which contains the names of the entries
    str = '';
    N = length(names);
    for i=1:N
        str = [str strrep(names{i},' ', '_')];
        if (i < N)
            str = [str ','];
        end
    end
    str = [str '\n'];
    fprintf(file, str);
end

function csv_output_data(file, filename, data, ag)
    % output data set

    [pathstr, name, ext] = fileparts(filename);
    filename = [name ext];
    
    if (ag)
        cell_ofs = size(data,1)-1;
        data = mean(data,1);
    else
        cell_ofs = 0;
    end
    
    N = size(data,1);
    for i=1:N
        str = sprintf('%s,%d',filename,i+cell_ofs);
        str2 = sprintf(',%f', data(i,:));
        fprintf(file, [str str2 '\n']);
    end
end