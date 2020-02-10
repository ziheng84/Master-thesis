classdef ErrorModel < handle
    %an umbrella class for error models, which could fit and estimate errors in a variety if ways.
   
    
    methods
        
        function [expectedValue,pixelVariance] = evaluateError(self,pixel_value,pixel_x,pixel_y,varargin)
            %should be a function present in all error models
            %all these variables should be submitable as column vectors
           
            fprintf('\n\n no evaluateError method defined for this error model \n\n')
            
            expectedValue = 0;
            pixelVariance = 0;
            
        end
        
    end
    
    
end