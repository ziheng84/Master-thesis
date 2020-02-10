function [experiments] = splitExperiment(cExperiment,npos,strains)
    %splitExperiment Separate a multi-chamber experiment into strains
    %   cExperiment: a compiled experiment to separate
    %   npos: an array of integers specifying the number of positions taken
    %         by each strain
    %   strains: a cell array of strain names (defaults to {'strain1',...})

    %% Save the variable name and/or file location of the cExperiment
    % Check the class of the cExperiment object and decide where to obtain
    % the experimentTracking object from:
    if isa(cExperiment,'char')
        workspaceExperimentVar = cExperiment;
        cExperiment = evalin('base',workspaceExperimentVar);
    else
        workspaceExperimentVar = 'cExperiment'; % Save this as default
    end

    if ~isa(cExperiment,'experimentTracking')
        % The first argument is of the wrong type
        error('The cExperiment argument must be either an experimentTracking object or a string');
    end

    % Save the file system location of the original cExperiment object:
    savedExperimentDir = cExperiment.saveFolder;

    %% Map position indices to directory name indices
    % Positions are indexed according to cExperiment.dirs, but the order of
    % each position in the microscope protocol is enumerated by filename
    posStr = regexp(cExperiment.dirs,'\d+$','match');
    if any(cellfun(@length,posStr)<1)
        error('Cannot parse the position indices.');
    end
    % Flatten the output of the regexp
    posStr = cellfun(@(x) x{:},posStr,'UniformOutput',false);
    posNum = str2double(posStr);
    [~,posInd] = sort(posNum);
    
    % If the strains argument hasn't been supplied, set default names:
    if nargin<3
        strains = strcat('strain',arrayfun(@num2str,1:length(npos),'UniformOutput',false));
    end

    % Calculate indices for each strain
    indEnd = cumsum(npos);
    indBegin = 1;
    if(length(npos)>1)
        indBegin = cumsum([1,npos(2:end)]);
    end
    strainInd = arrayfun(@(b,e) b:e,indBegin,indEnd,'UniformOutput',false);
    
    % Reorder according to the position index
    posInd = cellfun(@(x) posInd(x),strainInd,'UniformOutput',false);
    
    %% Loop through strains and create a new experiment for each strain:
    for istrain=1:length(strainInd)
        % Loop through each channel and subset according to strain
        for ichannel=1:length(cExperiment.cellInf)
            mdims = size(cExperiment.cellInf(ichannel).posNum);
            mask = ismember(cExperiment.cellInf(ichannel).posNum,posInd{istrain});
            for ifield=fieldnames(cExperiment.cellInf)'
                ifield = ifield{1};

                % First save details of the experimentTracking object:
                experiments.(strains{istrain}).workspaceExperimentVar = ...
                    workspaceExperimentVar;
                experiments.(strains{istrain}).savedExperimentDir = ...
                    savedExperimentDir;

                % Then split the extracted cellInf structure up:
                fdims = size(cExperiment.cellInf(ichannel).(ifield));
                if all(fdims==mdims)
                    % If the dimensions are the same as for posNum, then
                    % subset according to the posNum mask
                    experiments.(strains{istrain}).cellInf(ichannel).(ifield) = ...
                        cExperiment.cellInf(ichannel).(ifield)(:,mask);
                elseif fdims(1)==mdims(2)
                    % If the row dimension is the same as the length of
                    % posNum, then subset only on rows
                    experiments.(strains{istrain}).cellInf(ichannel).(ifield) = ...
                        cExperiment.cellInf(ichannel).(ifield)(mask,:);
                else
                    % Otherwise just copy the element
                    experiments.(strains{istrain}).cellInf(ichannel).(ifield) = ...
                        cExperiment.cellInf(ichannel).(ifield);
                end
            end
        end
    end
end