function [experiments] = splitExperimentByPosName(cExperiment)
    %splitExperimentByPosName Separate a multi-chamber experiment into
    %   strains using the position names to infer grouping
    %   cExperiment: a compiled experiment to separate

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

    %% Parse position names to determine strain names and grouping
    % Positions are labelled according to strain and numbered according to 
    % position with the format, e.g., "strain1_name_001".
    
    % Strip off trailing digits
    strainrefs = regexp(cExperiment.dirs,'^(?<id>.*\D)\d+$','names');
    strainrefs = cellfun(@(x) x.id,strainrefs,'UniformOutput',false);
    % Replace all non-word characters with an underscore
    strainrefs = regexp(strainrefs,'[a-zA-Z0-9]+','match');
    strainrefs = cellfun(@(x) strjoin(x,'_'),strainrefs,'UniformOutput',false);
        
    % Calculate indices for each strain
    strains = unique(strainrefs);
    strainInd = cellfun(@(x) find(strcmp(strainrefs,x)),strains,'UniformOutput',false);

    %% Loop through strains and create a new experiment for each strain:
    for istrain=1:length(strains)
        % Loop through each channel and subset according to strain
        for ichannel=1:length(cExperiment.cellInf)
            mdims = size(cExperiment.cellInf(ichannel).posNum);
            mask = ismember(cExperiment.cellInf(ichannel).posNum,strainInd{istrain});
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