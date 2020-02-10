function cmap2 = makeColormapFromPortionOfColormap(cmap,range)
% cmap2 = makeColormapFromPortionOfColormap(cmap)
% makes a colormap from a portion of another color map (e.g. just uses the
% upper half. 
% cmap      -    a colormap or string indicating a colormap
% portion   -    an array like [0.2 1] specifying the fractional range of
%                the colormap to use.
%
% mostly written is I would remember how to play with colormaps.

if ischar(cmap)
    cmap = colormap(cmap);
end

cmap2 = cmap(round(64*linspace(range(1),range(2),64)),:);


end