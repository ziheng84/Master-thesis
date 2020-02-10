function mesg(debug, str)
    % mesg.m - displays output messages
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

    % do not print empty string
    if (isempty(str))
        return;
    end
    if (debug) 
        if (isempty(gcbf))
            % remove carriage return if necessary
            if (str(1) == 13)
                    str = str(2:end);
            end
            disp(str);
        else
            hwnd = gcbf();
            status = findobj(hwnd,'Tag','outputtext');
            
            text = get(status, 'String');
            
            % if first character is carriage return, then replace line
            if (str(1) == 13)
                text{end} = str;
            else
                if (length(text) >= 500)
                    text = text(2:500);
                end
                text = cat(1, text, {str});
            end
            set(status, 'String', text);
            set(status, 'Value', length(text));
            drawnow;
  
            % check for terminate request
            data = guidata(gcbo);
            if (isfield(data,'abort'))
                data = rmfield(data, 'abort');
                guidata(gcbo, data);
                
                throw(MException('User:Abort', 'User terminated execution'));
            end
        end
    end
end