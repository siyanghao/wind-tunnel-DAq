dcm = angle2dcm(0, 0, 0);
F_body =(dcm * Save_avg(:,1:3)')';  
hold on
% plot(Save_avg(:,7),F_body(:,1),'+k');
% plot(Save_avg(:,7),F_body(:,2),'ob');
plot(Save_avg(:,7),F_body(:,3),'*r');