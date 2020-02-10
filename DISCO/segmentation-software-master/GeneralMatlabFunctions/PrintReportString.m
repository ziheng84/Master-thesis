function PrintReportString(iterant,newline)
% function PrintReportString(iterant,newline)
%
% print a report string which is a line of dots until it reaches newline,
% at whcih point is starts a new line of dots.

fprintf('.')
if mod(iterant,newline)==0
    fprintf('\n')
end
end