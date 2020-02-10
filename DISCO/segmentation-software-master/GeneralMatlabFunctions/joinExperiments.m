function [experiments] = joinExperiments(varargin)
    %joinExperiments Join named experiment structures returned by the
    %   "splitExperiment" functions. Repeated names are kept unique by
    %   appending an increasing letter. NB: DO NOT join experiments that
    %   have already been joined unless you don't mind a growing chain of
    %   unique subscripts.
    
    % Define letters to be appended to repeated experiments
    letters = 'abcdefghijklmnop';
    
    % Keep a track of the names that have already been appended
    existing_names = containers.Map('KeyType','char','ValueType','int32');

    % Loop through the arguments and concatenate
    pairs = [];
    for arg=varargin
        expt = arg{1};
        names = fieldnames(expt);
        unique_names = names;
        
        % Redefine the names by appending an alphabetic counter
        for n=1:length(names)
            name = names{n};
            if isKey(existing_names,name)
                existing_names(name) = existing_names(name)+1;
            else
                existing_names(name) = 1;
            end
            unique_names{n} = [name,'_',letters(existing_names(name))];
        end
        
        pairs = [pairs; unique_names,struct2cell(expt)];
    end
    
    % Finally, create a new experiments structure out of the concatenated array
    pairs = pairs.';
    experiments = struct(pairs{:});
end