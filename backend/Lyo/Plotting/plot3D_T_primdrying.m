function plot3D_T_primdrying(ip,sol2)

tiledlayout(1,3,"TileSpacing","loose","Padding","compact");

i_fin = find(sol2.S>=ip.H2*100,1);
nall = floor(i_fin/3);
ind = [2; nall; 2*nall; 3*nall];

for i = 1:3 
% Body (frozen product)
nexttile(i)
off = .1;
R = ip.d*100/2;
r = R*ones(ip.nz2,1);
[X,Y,Z] = cylinder(r,100);
X = X + R + off;
Y = Y + R + off;
h = (ip.H2-sol2.S(ind(i))/100)*100;
Z = Z*h;
T1 = flip(sol2.T(ind(i),:)');

[m1,n1] = size(X);
C = T1.*ones(m1,n1);
surf(X,Y,Z,C,'linestyle','none','EdgeColor','flat')

hold on

% Top surface
M = 10 ;
N = 100 ;
R1 = 0 ; % inner radius 
R2 = R ;  % outer radius
nR = linspace(R1,R2,M) ;
nT = linspace(0,2*pi,N) ;
[rad, the] = meshgrid(nR,nT) ;
X2 = rad.*cos(the); 
Y2 = rad.*sin(the);
X2 = X2 + R + off;
Y2 = Y2 + R + off;
[m2,n2]=size(X2);
surf(X2,Y2,h*ones(m2,n2),T1(end)*ones(m2,n2),'linestyle','none')

Tbar = linspace(min(T1),max(T1),4);
Tbar = round(Tbar,2);


if i == 1 && ind(i) == 1
    Tbar = linspace(min(T1),min(T1)+1,4);
    Tbar = round(Tbar,2);
    clim([Tbar(1) Tbar(end)])
    cb = colorbar;
    cb.Ticks = Tbar;
else
    clim([Tbar(1) Tbar(end)])
    cb = colorbar;
    cb.Ticks = Tbar;
end
cb.Location = 'southoutside';

hold on


% Vial
R = ip.d*100/2+.1;
r = R;
[X,Y,Z] = cylinder(r,100);
X = X + R;
Y = Y + R;
h = ip.H2*100 + .3;
Z = Z*h;
[m1,n1] = size(X);
C = .5*ones(m1,n1,3);
zlim([0 h])

surf(X,Y,Z,C,'EdgeColor',[1 1 1],'FaceAlpha',.1,'linestyle','none')
set(gca,'XTickLabel',[],'YTickLabel',[],'XTick',[],'YTick',[]);
zlabel('Product height (cm)')

graphics_setup('1by3d')
% axis 'equal'
daspect([max(daspect)*[1 1] 1])
label_h = ylabel(cb,'Temperature (K)','Rotation',0,'FontSize',8);
label_h.Position(2) = -1.5;

annotation('textarrow',[0.05,.95],[.92,.92])
text(.77,.89,['{\itt} = ' num2str(round(sol2.t(ind(i)),1)) ' h'],'Units','normalized','FontSize', 10);

end
  
text(-.9,1.05,'Time (h)','Units','normalized','FontSize', 8);
end