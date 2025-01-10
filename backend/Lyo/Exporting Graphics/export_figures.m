% ==============================================================================
% This is a function for exporting the figures.
%
% Created by Prakitr Srisuma, 
% PhD, Braatz Group (ChemE) & 3D Optical Systems Group (MechE), MIT.
% ==============================================================================

function export_figures(figure,filename)

filename1 = fullfile('Figures',  [filename,'.png']);
exportgraphics(figure, filename1,'Resolution',600)
filename2 = fullfile('Figures',  [filename,'.pdf']);
exportgraphics(figure, filename2,'Resolution',1000)
filename3 = fullfile('Figures',  [filename,'.emf']);
exportgraphics(figure, filename3,'Resolution',1000)

return