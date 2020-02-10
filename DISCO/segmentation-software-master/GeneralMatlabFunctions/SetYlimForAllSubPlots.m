function [ylim] = SetYlimForAllSubPlots(figh)
% function [ylim] = SetYlimForAllSubPlots(figh)
% set ylim to be the same for all subplots of a figure with figure handle
% figh.

kids = get(figh,'children');
ylim = [Inf -Inf];
for kidi= 1:length(kids)
    kid = kids(kidi);
    ylim_temp = get(kid,'Ylim');
    ylim(1) = min(ylim(1), ylim_temp(1));
    ylim(2) = max(ylim(2), ylim_temp(2));
    
end

for kidi= 1:length(kids)
    kid = kids(kidi);
    set(kid,'Ylim',ylim) 
end

end