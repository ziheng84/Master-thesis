classdef ErrorModelpp < ErrorModel
    %fits error model to mean and variance data using the interp1 function
   
    properties
        
        PPobject = []
        linearFit = []
        FittingMean = []
        FittingVariance = [];
        valueMax = 0;
        valueMin = 0;
        Comment = ''
           
    end     
    
    
    methods
        
        function fitErrorModel(self,fitting_mean,fitting_variance)
            
            self.FittingMean = fitting_mean;
            
            self.FittingVariance = fitting_variance;
            
            self.FitFromData;
            
            self.valueMax = max(self.FittingMean(:));
            
            self.valueMin = min(self.FittingMean(:));
            
        end
        
        function FitFromData(self)
            
            self.PPobject = interp1(self.FittingMean,self.FittingVariance,'linear','pp');
            % when interp1 doesn't work anymore:
            %self.PPobject = griddedInterpolantself.FittingMean,self.FittingVariance);
            self.linearFit = polyfit(self.FittingMean,self.FittingVariance,1);
            
        end
        
        
        function [pixelVariance,expectedValue] = evaluateError(self,pixel_value,pixel_x,pixel_y,varargin)
            %should be a function present in all error models
           
            if nargin>4 && ~isempty(varargin{1})
                
                supress_warning = varargin{1};
            else
                supress_warning = true;
                
            end
            
            
            expectedValue = pixel_value;
            pixelVariance = expectedValue;
            pixelVariance(expectedValue<=self.valueMax) = ppval(self.PPobject,pixel_value(expectedValue<=self.valueMax));
            pixelVariance(expectedValue>self.valueMax) = self.linearFit(2) + self.linearFit(1)*pixel_value(expectedValue>self.valueMax);
            pixelVariance(pixel_value<self.valueMin) = ppval(self.PPobject,self.valueMin);
            % try and make sure those outside the bound do not give crazy
            % results
            
            
            % when interp1 doesn't work anymore:
            % pixelVariance = self.PPobject(pixel_value);
            if ~supress_warning  && (any(pixel_value> self.valueMax) || any(pixel_value< self.valueMin ) )
                
                fprintf('\n\nwarning, some values submitted are outside the range of the error model\n\n')
                
                
            end
            
        end
        
    end
    
    
end