function plot_all(sol1,sol2,sol3,ip)

% Extract freezing data
time1 = sol1.t; Temp1 = sol1.T; Tb1 = sol1.Tg;

% Extract primary drying data
time2 = sol2.t; Temp2 = sol2.T; Tp2 = mean(Temp2,2); Tb2 = sol2.Tb;

% Extract secondary drying data
time3 = sol3.t; Temp3 = sol3.T; Tp3 = mean(Temp3,2); Tb3 = sol3.Tb; cw = mean(sol3.cw,2);

% Combine
time = [time1;time2;time3];
S = [sol1.S;sol2.S;sol3.S];
Temp = [Temp1;Tp2;Tp3];
Tb = [Tb2;Tb3];
cw = [sol1.cw;sol2.cw;cw];
P = [sol1.P;sol2.P;sol3.P];

% Mass of ice
mi1 = sol1.mi;
mi2 = cal_mi(sol2.S,mi1(end),ip.H2);
mi3 = zeros(length(time3),1);
mi = [mi1;mi2;mi3];

tiledlayout(5,1,"TileSpacing","loose","Padding","compact")
nexttile(1)
annotation('doublearrow',[.08 .269],[.97 .97])
annotation('doublearrow',[.275 .657],[.97 .97])
annotation('doublearrow',[.663 .94],[.97 .97])

plot(time,Temp,'-','Color',[0 0.7 0.17, 1],'linewidth',1.5); hold on
xline(time1(end),'--','linewidth',1,'HandleVisibility','off')
xline(time2(end),'--','linewidth',1,'HandleVisibility','off')
xline(time3(end),'--','linewidth',1,'HandleVisibility','off')
ylim([220 300]) 
xlabel('Time (h)'); ylabel('Product mperature (K)')
% h = legend('location','northwest'); h.ItemTokenSize(1) = 10;
graphics_setup('wide_all')
text(.072,1.15,'Freezing','Units','normalized','FontSize', 8);
text(.39,1.15,'Primary Drying','Units','normalized','FontSize', 8);
text(.76,1.15,'Secondary Drying','Units','normalized','FontSize', 8);
text(.02,.2,'(A)','Units','normalized','FontSize', 10,'fontweight', 'bold');

nexttile(2)
plot(time,mi,'Color','b','linewidth',1.5)
xline(time1(end),'--','linewidth',1,'HandleVisibility','off')
xline(time2(end),'--','linewidth',1,'HandleVisibility','off')
xline(time3(end),'--','linewidth',1,'HandleVisibility','off')
% xlim([0 round(time3(end),-1)])
% ylim([min(Tb1)-10 round(max(Temp,[],'all')+10,-1)]) 
xlabel('Time (h)'); ylabel('Mass of ice (kg)')
% h = legend('location','northwest'); h.ItemTokenSize(1) = 10;
graphics_setup('wide_all')
text(.02,.2,'(B)','Units','normalized','FontSize', 10,'fontweight', 'bold');

nexttile(3)
plot(time,cw,'Color','r','linewidth',1.5)
xline(time1(end),'--','linewidth',1,'HandleVisibility','off')
xline(time2(end),'--','linewidth',1,'HandleVisibility','off')
xline(time3(end),'--','linewidth',1,'HandleVisibility','off')
% xlim([0 round(time3(end),-1)])
% ylim([min(Tb1)-10 round(max(Temp,[],'all')+10,-1)]) 
xlabel('Time (h)'); ylabel([{'Bound water concentration'};{'(kg water/kg solid)'}])
% h = legend('location','northwest'); h.ItemTokenSize(1) = 10;
graphics_setup('wide_all')
text(.02,.2,'(C)','Units','normalized','FontSize', 10,'fontweight', 'bold');

nexttile(4)
plot(time,P,'Color','m','linewidth',1.5,'Displayname','Pressure')
xline(time1(end),'--','linewidth',1,'HandleVisibility','off')
xline(time2(end),'--','linewidth',1,'HandleVisibility','off')
xline(time3(end),'--','linewidth',1,'HandleVisibility','off')
% xlim([0 round(time3(end),-1)])
ylim([0 1.2e5])
% ylim([min(Tb1)-10 round(max(Temp,[],'all')+10,-1)]) 
xlabel('Time (h)'); ylabel('Operating pressure (Pa)');
% h = legend('location','northwest'); h.ItemTokenSize(1) = 10;
graphics_setup('wide_all')
text(.02,.2,'(D)','Units','normalized','FontSize', 10,'fontweight', 'bold');

nexttile(5)
plot(time1,Tb1,'-','Color',[0.3010 0.7450 0.9330, 1],'linewidth',1.5,'displayname','Cold gas'); hold on
plot(time2,Tb2,'-','Color',[0.8500 0.3250 0.0980, 1],'linewidth',1.5,'displayname','Heating shelf'); hold on
plot(time3,Tb3,'-','Color',[0.8500 0.3250 0.0980, 1],'linewidth',1.5,'HandleVisibility','off')
xline(time1(end),'--','linewidth',1,'HandleVisibility','off')
xline(time2(end),'--','linewidth',1,'HandleVisibility','off')
xline(time3(end),'--','linewidth',1,'HandleVisibility','off')
ylim([min(Tb1)-10 round(max(Temp,[],'all')+20,-1)]) 
xlabel('Time (h)'); ylabel('Operating temperature (K)')
h = legend('location','best'); h.ItemTokenSize(1) = 10;
graphics_setup('wide_all')
text(.02,.2,'(E)','Units','normalized','FontSize', 10,'fontweight', 'bold');

end