function plot_temp_all(sol1,sol2,sol3)

% Extract freezing data
time1 = sol1.t; Temp1 = sol1.T; Tb1 = sol1.Tg;

% Extract primary drying data
time2 = sol2.t; Temp2 = sol2.T; Tp2 = mean(Temp2,2); Tb2 = sol2.Tb;

% Extract secondary drying data
time3 = sol3.t; Temp3 = sol3.T; Tp3 = mean(Temp3,2); Tb3 = sol3.Tb;

% Combine
time = [time1;time2;time3];
S = [sol1.S;sol2.S;sol3.S];
Temp = [Temp1;Tp2;Tp3];
Tb = [Tb2;Tb3];

plot(time,Temp,'Color',[0 0.7 0.17, 1],'linewidth',2,'displayname','Product'); hold on;
plot(time1,Tb1,'Color',[0 0 1, .5],'linewidth',1.5,'displayname','Cold gas'); hold on
plot(time2,Tb2,'Color',[1 0 0, .5],'linewidth',1.5,'displayname','Heating shelf')
% plot(time,[sol1.Tw;sol2.Tw;sol3.Tw],'-.','linewidth',.5,'displayname','Wall')
plot(time3,Tb3,'Color',[1 0 0, .5],'linewidth',1.5,'HandleVisibility','off')
xline(time1(end),'--','HandleVisibility','off')
xline(time2(end),'--','HandleVisibility','off')
xline(time3(end),'--','HandleVisibility','off')
xlim([0 time3(end)])
ylim([min(Tb1)-10 round(max(Temp,[],'all')+10,-1)]) 
xlabel('Time (h)'); ylabel('Temperature (K)')
h = legend('location','northwest'); h.ItemTokenSize(1) = 10;
graphics_setup('wide')

end