function plot3D_freezing(ip,sol3)

tiledlayout(1,3,"TileSpacing","loose","Padding","compact");

i_fin = length(sol3.t_rl);
nall = floor(i_fin/3);
ind = [1 ;2*nall; 3*nall];

for i = 1:3 
% Body (frozen product)
nexttile(i)
H = sol3.H(i);
off = .1;
R = ip.d*100/2;
r = R*ones(ip.nz3,1);
[X,Y,Z] = cylinder(r,100);
X = X + R + off;
Y = Y + R + off;
h = H*100;
Z = Z*h;
cblue = [0 20 255]/255';

surf(X,Y,Z,'linestyle','none','EdgeColor','flat','FaceColor',cblue,'FaceAlpha',.2)
graphics_setup('1by3d')

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
surf(X2,Y2,h*ones(m2,n2),'linestyle','none','EdgeColor','flat','FaceColor',[1,1,1],'FaceAlpha',.1)
hold on
surf(X2,Y2,0*ones(m2,n2),'linestyle','none','EdgeColor','flat','FaceColor',cblue,'FaceAlpha',.25)

hold on

% water
cblue2 = [80 231 235]/255;
off = .1+(ip.d/2-sol3.r(ind(i)))*100;
R = sol3.r(ind(i))*100;
r = R*ones(ip.nz3,1);
[X,Y,Z] = cylinder(r,100);
X = X + R + off;
Y = Y + R + off;
h = (H-sol3.l(ind(i)))*100;
Z = Z*h + sol3.l(ind(i))*100 - 1e-6;
surf(X,Y,Z,'linestyle','none','EdgeColor','flat','FaceColor',[80 231 235]/255,'FaceAlpha',.8)
graphics_setup('1by3d')
hold on

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
surf(X2,Y2,(h+sol3.l(ind(i))*100-.01)*ones(m2,n2),'linestyle','none','EdgeColor','flat','FaceColor',[1,1,1],'FaceAlpha',.2)
hold on
surf(X2,Y2,sol3.l(ind(i))*100*ones(m2,n2),'linestyle','none','EdgeColor','flat','FaceColor',cblue2,'FaceAlpha',1)
hold on

% Vial
R = ip.d*100/2+.1;
r = R;
[X,Y,Z] = cylinder(r,100);
X = X + R;
Y = Y + R;
h = H*100 + .3;
Z = Z*h;
zlim([0 h])

surf(X,Y,Z,'EdgeColor',[1 1 1],'FaceAlpha',.1,'linestyle','none')
set(gca,'XTickLabel',[],'YTickLabel',[],'XTick',[],'YTick',[]);
zlabel('Product height (cm)'); hold on

if i == 2
L(1) = plot(nan, nan, 'linewidth',12, 'color', [0,0,1,.3]);
L(2) = plot(nan, nan,'linewidth',12, 'color', cblue2);
h =  legend(L, {'ice', 'water'},'location','southoutside','Orientation','horizontal','fontsize',8);
h.ItemTokenSize(1) = 15;
end

graphics_setup('1by3d')
% axis 'equal'
daspect([max(daspect)*[1 1] .9])
% 
annotation('textarrow',[0.05,.95],[.93,.93])
text(.77,.89,['{\itt} = ' num2str(round(sol3.t(ind(i)),1)) ' h'],'Units','normalized','FontSize', 10);

end
  
text(-.9,1.08,'Time (h)','Units','normalized','FontSize', 8);

end