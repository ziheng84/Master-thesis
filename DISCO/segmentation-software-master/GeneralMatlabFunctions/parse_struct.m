function output_struct = parse_struct(input_struct,default_struct)
% output_struct = parse_struct(input_struct,default_struct)
%
% replaces any field in default_struct with the one present in input_struct
% and then returns the modified default_struct.
%
% if the field is itself a structure, and the correpsonding field in
% defeault_struct is a struct it calls parse_struct on these fields.
output_struct = default_struct;
fields = fieldnames(input_struct);
for fi = 1:length(fields)
    if isstruct(input_struct.(fields{fi})) ...
            && isfield(output_struct,fields{fi})...
            && isstruct(output_struct.(fields{fi}))
        output_struct.(fields{fi}) = ...
            parse_struct(input_struct.(fields{fi}),output_struct.(fields{fi}));
    else
        output_struct.(fields{fi}) = input_struct.(fields{fi});
    end
end

end

function test()
%% to test

s_d =struct('a',3,'b',4);
s_i = struct('b',6,'c',5);
parse_struct(s_i,s_d)
end
