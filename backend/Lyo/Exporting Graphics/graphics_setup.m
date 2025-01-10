function graphics_setup(plot_type)

switch plot_type
case '1by1'
set(gcf, 'units', 'centimeters', 'Position',  [12, 3, 7, 5.5]);
set(gca,'fontsize',7)

case '1by1.5'
set(gcf, 'units', 'centimeters', 'Position',  [10, 6, 8.3, 5.3]);
set(gca,'fontsize',7)

case 'wide'
set(gcf, 'units', 'centimeters', 'Position',  [10, 6, 15, 5.3]);
set(gca,'fontsize',7)

case 'wide_all'
set(gcf, 'units', 'centimeters', 'Position',  [10, -5, 18, 23]);
set(gca,'fontsize',7,'XMinorTick','on','YMinorTick','on')

case '1by2'
set(gcf, 'units', 'centimeters', 'Position',  [10, 6, 13, 5.5]);
set(gca,'fontsize',7,'XMinorTick','on','YMinorTick','on')

case '1by2s'
set(gcf, 'units', 'centimeters', 'Position',  [10, 6, 13, 5.7]);
set(gca,'fontsize',7,'XMinorTick','on','YMinorTick','on')

case '1by2.5'
set(gcf, 'units', 'centimeters', 'Position',  [10, 6, 18, 5.5]);
set(gca,'fontsize',7,'XMinorTick','on','YMinorTick','on')

case '1by3'
set(gcf, 'units', 'centimeters', 'Position',  [3, 3, 18, 5.25]);
set(gca,'fontsize',7,'XMinorTick','on','YMinorTick','on')

case '1by3d'
set(gcf, 'units', 'centimeters', 'Position',  [3, 3, 18, 7.5]);
set(gca,'fontsize',7)

case '1by3s'
set(gcf, 'units', 'centimeters', 'Position',  [3, 3, 18, 6.5]);
set(gca,'fontsize',7,'XMinorTick','on','YMinorTick','on')

case '2by3'
set(gcf, 'units', 'centimeters', 'Position',  [3, 3, 17, 12]);
set(gca,'fontsize',7)

case '2by4'
set(gcf, 'units', 'centimeters', 'Position',  [3, 3, 17, 12]);
set(gca,'fontsize',7)

case '2by2'
set(gcf, 'units', 'centimeters', 'Position',  [12, 3, 13, 12]);
set(gca,'fontsize',7)

case '4by2'
set(gcf, 'units', 'centimeters', 'Position',  [3, -10, 13, 28]);
set(gca,'fontsize',7)

case '3by3'
set(gcf, 'units', 'centimeters', 'Position',  [3, 0, 17, 18]);
set(gca,'fontsize',7)

case '3by4'
set(gcf, 'units', 'centimeters', 'Position',  [3, -5, 24, 24]);
set(gca,'fontsize',8)

case '1by4'
set(gcf, 'units', 'centimeters', 'Position',  [3, 3, 25, 5]);
set(gca,'fontsize',7)

case '1by4_2'
set(gcf, 'units', 'centimeters', 'Position',  [3, 3, 18, 10]);
set(gca,'fontsize',5)

end

return