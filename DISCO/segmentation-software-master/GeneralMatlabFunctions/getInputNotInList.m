function input = getInputNotInList(prompt,title,list,second_prompt)
% input = getInputNotInList(prompt,title,list,second_prompt)
% small function to get an input by user interface which isn't in a list.
% Useful for asking for a unique name.

if nargin<4
    
    second_prompt = prompt;
    
end

get_name = true;
while get_name
    input = inputdlg(prompt,title);
    
    %cancel pressed
    if isempty(input)
        return
    end
    input = input{1};
    
    %name already in list
    if ismember(input,list)
        prompt = second_prompt;
    else
        get_name = false;
    end
end


end