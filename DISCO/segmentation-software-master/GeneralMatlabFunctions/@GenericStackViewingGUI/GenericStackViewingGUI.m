classdef GenericStackViewingGUI <StackViewingGUI
    %GENERICSTACKVIEWINGGUI View an nxmxz stack in a small gui where you
    %can roll through the images. Subclass of the broader StackViewingGUI
    %(which has a button).
    
    properties
        stack
        stack_min
        stack_max
        type = 'simple-stack'; %'simple-stack','cell','tri-stack'
        normalisation = 1;
        title = 'generic stack gui' % either a string or a cell array of strings (1 for each slice)
    end
    
    methods
        
        function Self = GenericStackViewingGUI(stack,type,normalisation)
            % Self = GenericStackViewingGUI(stack,type,normalisation)
            % stack             - the stack of images
            % type              - type of stack
            %                     - 'simple-stack' if it is just an nxmxz
            %                        stack of images.
            %                     - 'cell' if it is a cell array with each
            %                        cell being an RGB image.
            %                     - 'tri-stack' if each 3 slices of the
            %                        stack makes an RGB image.
            % normalisation     - 'all' normalise all images using the
            %                     global max/min. 
            %                     if anything else use the default of
            %                     normalising each slice individually.
            if nargin<1
                stack = [];
            end
            
            if nargin<2 || isempty(type)
                type = 'simple-stack';
            end
            
            if nargin<3 || isempty(normalisation)
                normalisation = 'all';
            end
            
            Self = Self@StackViewingGUI();
            
            Self.type = type;
            Self.normalisation = normalisation;
            if nargin>0
                
                Self.stack = stack;
                Self.LaunchGUI;
                
            end
            
        end
        
        function  Self = LaunchGUI(Self)
            
            switch Self.type
                case 'simple-stack'
                    Self.stack_min = min(min(Self.stack,[],2),[],1);
                    
                    Self.stack_max = max(max(Self.stack,[],2),[],1);
                    
                    Self.MaxStackDepth = size(Self.stack,3);
                    
                    Self.StackDepth = 1;
                
                case 'tri-stack'
                
                    Self.MaxStackDepth = size(Self.stack,3)/3;
                    
                    for i=1:Self.MaxStackDepth
                        SmallStack = Self.stack(:,:,i*3 + [-2 -1 0]);
                        Self.stack_min(1,1,i) = min(SmallStack(:));
                        
                        Self.stack_max(1,1,i) = max(SmallStack(:));
                    end
                    Self.StackDepth = 1;
                
                case 'cell'
                    Self.MaxStackDepth = length(Self.stack);
                    
                    for i=1:Self.MaxStackDepth
                        SmallStack = Self.stack{i};
                        Self.stack_min(i) = min(SmallStack(:));
                        
                        Self.stack_max(i) = max(SmallStack(:));
                    end
                    Self.StackDepth = 1;
                   
            end
            
            switch Self.normalisation
                case 'all'
                    Self.stack_min(:) = min(Self.stack_min);
                    
                    Self.stack_max(:) = max(Self.stack_max);
                    
            end
           
            
            Self = LaunchGUI@StackViewingGUI(Self);
            Self.MainImageHandle = subimage(zeros(size(Self.stack,1),size(Self.stack,2)));
            set(Self.MainAxisHandle, 'xtick',[],'ytick',[]);
            Self.UpdateImages;
        
            
        end
        
        
        function StackViewer = UpdateImages(StackViewer)
            %StackViewer = UpdateImages(StackViewer) Updates the images in the GUI.
            %called whenever the scale bar is moved.
            switch StackViewer.type
                case 'simple-stack'
                    ProspectiveCData = repmat(0.95*(StackViewer.stack(:,:,StackViewer.StackDepth) - StackViewer.stack_min(StackViewer.StackDepth))/(StackViewer.stack_max(StackViewer.StackDepth) - StackViewer.stack_min(StackViewer.StackDepth)),[1 1 3]);
                case 'tri-stack'
                    ProspectiveCData = 0.95*((StackViewer.stack(:,:,StackViewer.StackDepth*3 + [-2 -1 0]) -StackViewer.stack_min(StackViewer.StackDepth))/(StackViewer.stack_max(StackViewer.StackDepth) - StackViewer.stack_min(StackViewer.StackDepth)));
                case 'cell'
                    ProspectiveCData = 0.95*((StackViewer.stack{StackViewer.StackDepth} - StackViewer.stack_min(StackViewer.StackDepth))/(StackViewer.stack_max(StackViewer.StackDepth) - StackViewer.stack_min(StackViewer.StackDepth)));
                
            end
                
                set(StackViewer.MainImageHandle,'CData',...
                    ProspectiveCData);
                
                %if your image is not 512 by 512 nees to set xlim and ylim of main axis
                %to be [0.5 (size of image +0.5)] with a line like:
                
                %set(StackViewer.MainAxisHandle,'ylim',[0.5 (size(ProspectiveCData,1) + 0.5)])
                %set(StackViewer.MainAxisHandle,'xlim',[0.5 (size(ProspectiveCData,2) + 0.5)])
                if isstr(StackViewer.title)
                    title(StackViewer.MainAxisHandle,sprintf('%s : slice %d',StackViewer.title,StackViewer.StackDepth),'Interpreter','none');
                elseif iscell(StackViewer.title)
                    title(StackViewer.MainAxisHandle,sprintf('%s',StackViewer.title{StackViewer.StackDepth}),'Interpreter','none');
                end
                %this example is for an image of size 12.
        
        end
    end
    
    
end
    


