function if_equal = report_differences(obj1,obj2,name1,name2,pre_spacer)
%function report_differences(obj1,obj2,name1,name2,pre_spacer)
% reports the differences recursively between two objects, working down the
% structures/fields.
%
% if_equal   -  boolean result of initial isequal call
%
% uses isequaln, so NaN's are considered equal.
% names are used in naming the outputs on objects. prespacer should be left
% blank and is for pretty output with recursive use of function.


if nargin<4
    name1 = 'a';
    name2 = 'b';
end

if nargin<5
    pre_spacer = '';
end


if ~isequaln(obj1,obj2)
    if_equal = false;
    fprintf('%s%s and %s not equal\n',pre_spacer,name1,name2)
    
    if (isstruct(obj1) && isstruct(obj2)) || (isobject(obj1) && isobject(obj2))
        
        fields1 = fields(obj1);
        fields2 = fields(obj2);
        
        non_occurring_fields_1 = fields1(~ismember(fields1,fields2));
        for fieldii = 1:length(non_occurring_fields_1)
            fprintf('%s%s is not a field in %s\n',pre_spacer,non_occurring_fields_1{fieldii},name2)
        end
        
        
        non_occurring_fields_2 = fields2(~ismember(fields2,fields1));
        for fieldii = 1:length(non_occurring_fields_2)
            fprintf('%s%s is not a field in %s\n',pre_spacer,non_occurring_fields_2{fieldii},name1)
        end
        
        co_occurring_fields = fields1(ismember(fields1,fields2));
        for fieldii = 1:length(co_occurring_fields)
            fieldi = co_occurring_fields{fieldii};
            if length(obj1)~=length(obj2)
                fprintf('%s%s and %s are of different lengths\n',pre_spacer,name1,name2)
            else
            for insti = 1:length(obj1)
            report_differences(obj1(insti).(fieldi),obj2(insti).(fieldi),[name1 '(' num2str(insti) ').' fieldi],[name2 '(' num2str(insti) ').' fieldi],[pre_spacer '  ']);
            end
            end
        end
        
    end
else
    if_equal = true;
end

end