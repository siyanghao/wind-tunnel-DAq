function Out = Wallace_conv_20190417(dat)
global Wbias
% Calibration SI-660-60

Wallace_Cal = [-1.71970000000000,0.110400000000000,1.46025000000000,-69.8403800000000,3.68516000000000,68.1112200000000;0.513940000000000,84.1624800000000,-3.36146000000000,-40.0452000000000,1.85967000000000,-39.4923900000000;117.999280000000,1.50747000000000,120.040710000000,1.86535000000000,118.635110000000,2.37547000000000;-0.00699000000000000,1.93336000000000,-4.19985000000000,-0.992980000000000,4.13985000000000,-0.812730000000000;4.77798000000000,0.0674200000000000,-2.40357000000000,1.56279000000000,-2.45998000000000,-1.61599000000000;-0.0230500000000000,-2.79011000000000,0.0748600000000000,-2.66323000000000,-0.161410000000000,-2.59783000000000];

dat = dat-repmat(Wbias,numel(dat(:,1)),1);
Out = dat*Wallace_Cal';


% time = (0:numel(dat(:,1))-1)*0.001;
% plot(time,out(:,1))
% hold on
% plot(time,out(:,2))
% plot(time,out(:,3))
% hold off
% legend('Fx','Fy','Fz')
% ylabel('Force (N)')
% xlabel('time (s)')