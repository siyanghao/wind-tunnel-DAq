clear
close all

% Ronan Gissler February 2023

% This file is used to analyze the data from the experiments Sakthi
% and I ran with the 1 DOF flapper robot without wings, with
% Polydimethylsiloxane (PDMS) wings, and with Carbon Black (CB) wings
% on February 2nd 2023. We test flapping speeds between 1 Hz and 3 Hz
% with no wings attached, 6 Hz had been the failure point before. We
% tested flapping speeds between 1 Hz and 4 Hz with the PDMS wings, at
% 4 Hz the gears started to skip and the wings moved erratically so we
% ended the test abruptly. We tested flapping speeds between 1 Hz and
% 3 Hz with the CB wings, at 3 Hz the gears started to skip and the
% wings moved erratically so we ended the test abruptly.

% Changes made since the test on January 19th:
% - Galil sends a digital output when motors have finished
%   accelerating at the beginning of a wingbeat period and just before
%   motors begin decelerating at the beginning of a wingbeat period
% - New 3D printed base holds flapper more snugly to table 
% - Recording at a framerate that is a factor of the number of ticks
%   per revolution so that each wingbeat has a consistent number of
%   frames

% Adjustments to make for next test:
% - Use frame rate that's divisible by each speed, here we
% have the issue: 
% ((100 cycles) / (3 cycles / sec)) * (1280 frames / sec) = 42666.666

% - Why are there extra frames recorded?
% ((100 cycles) / (1 cycles / sec)) * (1280 frames / sec) = 128000
% while instead we got 128018, 128018, 128019
% Is it possible that the Galil misses counting some ticks increasing
% the measurement period as its still try to reach the prescribed
% number of ticks?
% On page 110 of the manual, they state: "The accuracy of the
% trippoint is the speed multiplied by the sample period."
% Not sure what units are to be used here for speed and sample period

% - Figure out how to set stepper motor so that when that it begins
% moving at the bottom or top of motion rather than somewhere
% arbitrary

% - Record many more wingbeat periods (maybe 300 periods) to increase
% smoothing effect due to averaging across trials

% - Extend delay after acceleration and before acceleration for
% trigger

%%

% ----------------------------------------------------------------
% ------------------------Plot All Data---------------------------
% ----------------------------------------------------------------

files = ["..\Experiment Data\1Hz_body_experiment_020223.csv"
         "..\Experiment Data\2Hz_body_experiment_020223.csv"
         "..\Experiment Data\3Hz_body_experiment_020223.csv"
         "..\Experiment Data\1Hz_PDMS_experiment_020223.csv"
         "..\Experiment Data\2Hz_PDMS_experiment_020223.csv"
         "..\Experiment Data\3Hz_PDMS_experiment_020223.csv"
         "..\Experiment Data\1Hz_CB_experiment_020223.csv"
         "..\Experiment Data\2Hz_CB_experiment_020223.csv"];

for i = 1:length(files)
    % Get case name from file name
    case_name = erase(files(i), ["_experiment_020223.csv", "..\Experiment Data\"]);
    case_name = strrep(case_name,'_',' ');
    case_name_chars = char(case_name);
    speed = str2double(case_name_chars(1));
    
    % Get data from file
    data = readmatrix(files(i));
    

    these_trigs = data(:, 8);
    these_low_trigs_indices = find(these_trigs < 2);
    trigger_start_frame = these_low_trigs_indices(1);
    trigger_end_frame = these_low_trigs_indices(end);

    trimmed_data = data(trigger_start_frame:trigger_end_frame, :);

    expected_length = (100 / speed) * 1280;
    trigger_error = length(trimmed_data) - expected_length;
    trigger_error_percent = round(trigger_error / expected_length, 4);

    % assuming it counts the exact amount of ticks before sending the
    % next output, the trigger error observed is entirely due to the
    % time taken to execute the last AD command. We assume here the
    % first and last AD command take the same time to run and result
    % in the same trigger error
    % Whether or not I shift all the data back by trigger_error has no
    % clear effect on the wingbeat averaged lift data.
    trimmed_data = data(trigger_start_frame - round(0):...
        trigger_end_frame - round(trigger_error), :);

    trimmed_time = trimmed_data(:,1) - trimmed_data(1,1);

    times = data(1:end,1);
    force_vals = data(1:end,2:7);

    force_means = round(mean(force_vals), 3);
    force_SDs = round(std(force_vals), 3);
    
     % Open a new figure.
    f = figure;
    f.Position = [200 50 900 560];
    tcl = tiledlayout(2,3);
    
    % Create three subplots to show the force time histories. 
    nexttile(tcl)
    hold on
    raw_line = plot(data(:, 1), data(:, 2), 'DisplayName', 'raw');
    trigger_line = plot(trimmed_data(:,1), trimmed_data(:, 2), ...
        'DisplayName', 'trigger');
    title(["F_x" ("avg: " + force_means(1) + " SD: " + force_SDs(1))]);
    xlabel("Time (s)");
    ylabel("Force (N)");
    
    nexttile(tcl)
    hold on
    plot(data(:, 1), data(:, 3));
    plot(trimmed_data(:,1), trimmed_data(:, 3));
    title(["F_y" ("avg: " + force_means(2) + " SD: " + force_SDs(2))]);
    xlabel("Time (s)");
    ylabel("Force (N)");
    
    nexttile(tcl)
    hold on
    plot(data(:, 1), data(:, 4));
    plot(trimmed_data(:,1), trimmed_data(:, 4));
    title(["F_z" ("avg: " + force_means(3) + " SD: " + force_SDs(3))]);
    xlabel("Time (s)");
    ylabel("Force (N)");

    % Create three subplots to show the moment time histories.
    nexttile(tcl)
    hold on
    plot(data(:, 1), data(:, 5));
    plot(trimmed_data(:,1), trimmed_data(:, 5));
    title(["M_x" ("avg: " + force_means(4) + " SD: " + force_SDs(4))]);
    xlabel("Time (s)");
    ylabel("Torque (N m)");
    
    nexttile(tcl)
    hold on
    plot(data(:, 1), data(:, 6));
    plot(trimmed_data(:,1), trimmed_data(:, 6));
    title(["M_y" ("avg: " + force_means(5) + " SD: " + force_SDs(5))]);
    xlabel("Time (s)");
    ylabel("Torque (N m)");
    
    nexttile(tcl)
    hold on
    plot(data(:, 1), data(:, 7));
    plot(trimmed_data(:,1), trimmed_data(:, 7));
    title(["M_z" ("avg: " + force_means(6) + " SD: " + force_SDs(6))]);
    xlabel("Time (s)");
    ylabel("Torque (N m)");

    hL = legend([raw_line, trigger_line]);
    % Move the legend to the right side of the figure
    hL.Layout.Tile = 'East';
    
    % Label the whole figure.
    sgtitle({"Force Transducer Measurement for " + case_name ...
             "Trigger Error: " + trigger_error + " frames " + trigger_error_percent + "%"});
    
    case_parts = strtrim(split(case_name));
    save([char(case_parts(1)),'_',char(case_parts(2)),'.mat'], 'data','trimmed_data','trimmed_time')
end

%%

% ----------------------------------------------------------------
% ---------Plot Characteristic Figure Showing Trigger-------------
% ----------------------------------------------------------------
% Open a new figure.
f = figure;
f.Position = [200 50 900 560];
title("Lift Force (z-direction) - PDMS Wings at 2Hz");
xlabel("Time (s)");
ylabel("Force (N)");
hold on

% Load data
mat_name = "2Hz_PDMS.mat";
load(mat_name);

% Plot lift force
plot(data(:,1), data(:, 4), 'DisplayName', 'Raw', "LineWidth",2, 'Color',[0.6350, 0.0780, 0.1840]);
plot(trimmed_data(:,1), trimmed_data(:, 4), 'DisplayName', 'Trigger', "LineWidth",2, 'Color',[0.3010, 0.7450, 0.9330]);

legend("Location","Southwest");
xlim([0 61]);
%%

% ----------------------------------------------------------------
% -------------------------Plot PDMS Data-------------------------
% ----------------------------------------------------------------
     
cases = ["1Hz_PDMS", "2Hz_PDMS", "3Hz_PDMS"];

% Open a new figure.
f = figure;
f.Position = [200 50 900 560];
title("Lift Force (z-direction) - PDMS Wings");
xlabel("Time (s)");
ylabel("Force (N)");
hold on

for i = 1:length(cases)
    % Load data
    mat_name = cases(i) + ".mat";
    load(mat_name);
    
    case_name = strrep(cases(i),'_',' ');
    
    % Plot lift force
    plot(trimmed_time, trimmed_data(:, 4), 'DisplayName', case_name, "LineWidth",2);
end
legend("Location","Southwest");
ax1 = axes('Position',[0.35 0.2 0.2 0.2]);
hold on
for i = 1:length(cases)
    % Load data
    mat_name = cases(i) + ".mat";
    load(mat_name);
    
    case_name = strrep(cases(i),'_',' ');
    
    % Plot lift force
    plot(ax1, trimmed_time, trimmed_data(:, 4))
    line(xlim, [0 0], 'Color','black'); % x-axis
end
xlim([30, 36])
ylim([-14, 14])
box on
annotation('arrow',[0.45 0.39], [0.4 0.52])

%%

% ----------------------------------------------------------------
% ----------------------Plot Wingless Data------------------------
% ----------------------------------------------------------------
     
cases = ["1Hz_Body", "2Hz_Body", "3Hz_Body"];

% Open a new figure.
f = figure;
f.Position = [200 50 900 560];
title("Lift Force (z-direction) - Wingless");
xlabel("Time (s)");
ylabel("Force (N)");
hold on

for i = 1:length(cases)
    % Load data
    mat_name = cases(i) + ".mat";
    load(mat_name);
    
    case_name = strrep(cases(i),'_',' ');
    
    % Plot lift force
    plot(trimmed_time, trimmed_data(:, 4), 'DisplayName', case_name, "LineWidth",2);
end
legend("Location","Southwest");
ax1 = axes('Position',[0.35 0.2 0.2 0.2]);
hold on
for i = 1:length(cases)
    % Load data
    mat_name = cases(i) + ".mat";
    load(mat_name);
    
    case_name = strrep(cases(i),'_',' ');
    
    % Plot lift force
    plot(ax1, trimmed_time, trimmed_data(:, 4))
    line(xlim, [0 0], 'Color','black'); % x-axis
end
xlim([30, 36])
ylim([-14, 14])
box on
annotation('arrow',[0.45 0.39], [0.4 0.52])

%%

% ----------------------------------------------------------------
% --------Plot PDMS Data normalized by wingbeat cycles------------
% ----------------------------------------------------------------
     
cases = ["1Hz_PDMS", "2Hz_PDMS"];
colors = [[0 0.4470 0.7410]; [0.8500 0.3250 0.0980]; [0.9290 0.6940 0.1250]];

% Open a new figure.
f = figure;
f.Position = [200 50 900 560];
title("Lift Force (z-direction) - PDMS Wings");
xlabel("Wingbeat Number");
ylabel("Force (N)");
hold on

for i = 1:length(cases)
    % Load data
    mat_name = cases(i) + ".mat";
    load(mat_name);
    
    case_name = strrep(cases(i),'_',' ');
    case_name_chars = char(case_name);
    speed = str2double(case_name_chars(1));

    num_wingbeats = 100;
    frames_per_beat = (1280 / speed);

    wingbeats = linspace(0, num_wingbeats, frames_per_beat*num_wingbeats);
    
    % Plot lift force
    plot(wingbeats, trimmed_data(:, 4), 'DisplayName', case_name, "LineWidth", 2, 'Color', colors(speed,:));
    save(cases(i) + ".mat", 'data','trimmed_data','trimmed_time','wingbeats');
end
legend("Location","Southwest");
ax1 = axes('Position',[0.35 0.2 0.2 0.2]);
hold on
for i = 1:length(cases)
    % Load data
    mat_name = cases(i) + ".mat";
    load(mat_name);
    
    case_name = strrep(cases(i),'_',' ');
    case_name_chars = char(case_name);
    speed = str2double(case_name_chars(1));
    
    % Plot lift force
    plot(ax1, wingbeats, trimmed_data(:, 4), 'Color', colors(speed,:))
    line(xlim, [0 0], 'Color','black'); % x-axis
end
xlim([32, 34])
ylim([-14, 14])
box on
annotation('arrow',[0.45 0.39], [0.4 0.52])

%%

% ----------------------------------------------------------------
% --------Plot Wingless Data normalized by wingbeat cycles------------
% ----------------------------------------------------------------
     
cases = ["1Hz_Body", "2Hz_Body"];
colors = [[0 0.4470 0.7410]; [0.8500 0.3250 0.0980]; [0.9290 0.6940 0.1250]];

% Open a new figure.
f = figure;
f.Position = [200 50 900 560];
title("Lift Force (z-direction) - Wingless");
xlabel("Wingbeat Number");
ylabel("Force (N)");
hold on

for i = 1:length(cases)
    % Load data
    mat_name = cases(i) + ".mat";
    load(mat_name);
    
    case_name = strrep(cases(i),'_',' ');
    case_name_chars = char(case_name);
    speed = str2double(case_name_chars(1));

    num_wingbeats = 100;
    frames_per_beat = (1280 / speed);

    wingbeats = linspace(0, num_wingbeats, frames_per_beat*num_wingbeats);
    
    % Plot lift force
    plot(wingbeats, trimmed_data(:, 4), 'DisplayName', case_name, "LineWidth", 2, 'Color', colors(speed,:));
    save(cases(i) + ".mat", 'data','trimmed_data','trimmed_time','wingbeats');
end
legend("Location","Southwest");
ax1 = axes('Position',[0.35 0.2 0.2 0.2]);
hold on
for i = 1:length(cases)
    % Load data
    mat_name = cases(i) + ".mat";
    load(mat_name);
    
    case_name = strrep(cases(i),'_',' ');
    case_name_chars = char(case_name);
    speed = str2double(case_name_chars(1));
    
    % Plot lift force
    plot(ax1, wingbeats, trimmed_data(:, 4), 'Color', colors(speed,:))
    line(xlim, [0 0], 'Color','black'); % x-axis
end
xlim([32, 34])
ylim([-14, 14])
box on
annotation('arrow',[0.45 0.39], [0.4 0.52])

%%

% ----------------------------------------------------------------
% --------Plot PDMS Data normalized by wingbeat cycles------------
% --------------animation of each wingbeat at a time--------------
% ----------------------------------------------------------------
make_movie = false;
if (make_movie) 
cases = ["1Hz_PDMS", "2Hz_PDMS"];
colors = [[0 0.4470 0.7410]; [0.8500 0.3250 0.0980]; [0.9290 0.6940 0.1250]];

num_wingbeats = 100;
wingbeats_animation = struct('cdata', cell(1,num_wingbeats), 'colormap', cell(1,num_wingbeats));

for n = 1:num_wingbeats
    % Open a new figure.
    f = figure;
    f.Visible = "off";
    f.Position = [200 50 900 560];
    title({"Lift Force (z-direction) - PDMS Wings" "Wingbeat Number: " + n});
    xlabel("Wingbeat Number");
    ylabel("Force (N)");
    ylim([-20 20]);
    hold on
for i = 1:length(cases)
    % Load data
    mat_name = cases(i) + ".mat";
    load(mat_name);
    
    case_name = strrep(cases(i),'_',' ');
    case_name_chars = char(case_name);
    speed = str2double(case_name_chars(1));

    frames_per_beat = (1280 / speed);
    
    wingbeat_lifts = zeros(num_wingbeats, frames_per_beat);
    for j = 1:num_wingbeats
        for k = 1:frames_per_beat
            wingbeat_lifts(j,k) = trimmed_data(k + (frames_per_beat*(j-1)), 4);
        end
    end

    frames = linspace(0,1,frames_per_beat);
    
    % Plot lift force
    plot(frames, wingbeat_lifts(n,:), 'DisplayName', case_name, "LineWidth", 2, 'Color', colors(speed,:));
end
legend("Location","Southwest");

% Save plot along with axes labels and titles
ax = gca;
ax.Units = 'pixels';
pos = ax.Position;
ti = ax.TightInset;
rect = [-ti(1), -ti(2), pos(3)+ti(1)+ti(3), pos(4)+ti(2)+ti(4)];
F = getframe(ax,rect);

% Add plot to array of plots to serve animation
wingbeats_animation(n) = F;
end

% Play movie
% h = figure;
% h.Position = [200 50 900 560];
% movie(h,wingbeats_animation,5,5);

% Save movie
video_name = 'PDMS.mp4';
v = VideoWriter(video_name, 'MPEG-4');
v.FrameRate = 5; % fps
v.Quality = 100; % [0 - 100]
open(v);
writeVideo(v,wingbeats_animation);
close(v);

% From beginning to end, it looks like the data for each wingbeat is
% slowly shifting right. This would indicate that the assumed wingbeat
% period is a little shorter than the true wingbeat period or we are
% not quite looking at a full 100 wingbeats
end

%%

% ----------------------------------------------------------------
% --------Plot PDMS Data normalized by wingbeat cycles------------
% ----------------and then wingbeat cycle averaged----------------
% ----------------------------------------------------------------
     
cases = ["1Hz_PDMS", "2Hz_PDMS"];
colors = [[0 0.4470 0.7410]; [0.8500 0.3250 0.0980]; [0.9290 0.6940 0.1250]];

% Open a new figure.
f = figure;
f.Position = [200 50 900 560];
title("Lift Force (z-direction) - PDMS Wings");
xlabel("Wingbeat Number");
ylabel("Force (N)");
hold on

for i = 1:length(cases)
    % Load data
    mat_name = cases(i) + ".mat";
    load(mat_name);
    
    case_name = strrep(cases(i),'_',' ');
    case_name_chars = char(case_name);
    speed = str2double(case_name_chars(1));

    num_wingbeats = 100;
    frames_per_beat = (1280 / speed);
    
    wingbeat_lifts = zeros(num_wingbeats, frames_per_beat);
    for j = 1:num_wingbeats
        for k = 1:frames_per_beat
            wingbeat_lifts(j,k) = trimmed_data(k + (frames_per_beat*(j-1)), 4);
        end
    end

    wingbeat_avg_lift = zeros(1,frames_per_beat);
    for k = 1:frames_per_beat
        wingbeat_avg_lift(k) = mean(wingbeat_lifts(:,k));
    end

    frames = linspace(0,1,frames_per_beat);
    
    % Plot lift force
    plot(frames, wingbeat_avg_lift, 'DisplayName', case_name, "LineWidth", 2, 'Color', colors(speed,:));
    save(cases(i) + ".mat", 'data','trimmed_data','trimmed_time','wingbeats', 'frames', 'wingbeat_avg_lift');
end
legend("Location","Southwest");

% ----------------------------------------------------------------
% -------Plot Wingless Data normalized by wingbeat cycles---------
% ----------------and then wingbeat cycle averaged----------------
% ----------------------------------------------------------------

cases = ["1Hz_body", "2Hz_body"];
colors = [[0 0.4470 0.7410]; [0.8500 0.3250 0.0980]; [0.9290 0.6940 0.1250]];

% Open a new figure.
f = figure;
f.Position = [200 50 900 560];
title("Lift Force (z-direction) - Wingless");
xlabel("Wingbeat Number");
ylabel("Force (N)");
hold on

for i = 1:length(cases)
    % Load data
    mat_name = cases(i) + ".mat";
    load(mat_name);
    
    case_name = strrep(cases(i),'_',' ');
    case_name_chars = char(case_name);
    speed = str2double(case_name_chars(1));

    num_wingbeats = 100;
    frames_per_beat = (1280 / speed);
    
    wingbeat_lifts = zeros(num_wingbeats, frames_per_beat);
    for j = 1:num_wingbeats
        for k = 1:frames_per_beat
            wingbeat_lifts(j,k) = trimmed_data(k + (frames_per_beat*(j-1)), 4);
        end
    end

    wingbeat_avg_lift = zeros(1,frames_per_beat);
    for k = 1:frames_per_beat
        wingbeat_avg_lift(k) = mean(wingbeat_lifts(:,k));
    end

    frames = linspace(0,1,frames_per_beat);
    
    % Plot lift force
    plot(frames, wingbeat_avg_lift, 'DisplayName', case_name, "LineWidth", 2, 'Color', colors(speed,:));
    save(cases(i) + ".mat", 'data','trimmed_data','trimmed_time','wingbeats', 'frames', 'wingbeat_avg_lift');
end
legend("Location","Southwest");

%%

% ----------------------------------------------------------------
% -------Plot Wingless Data Subtracted from PDMS Data-------------
% ---------------------at 1 Hz, 2 Hz, and 3 Hz--------------------
% ----------------------------------------------------------------

body_cases = ["1Hz_body", "2Hz_body"];
wing_cases = ["1Hz_PDMS", "2Hz_PDMS"];

% Open a new figure.
f = figure;
f.Position = [200 50 900 560];
title(["Aerodynamic Force Production" "(Subtracting Force without Wings from Force with Wings)"]);
xlabel("Wingbeat Number");
ylabel("Force (N)");
hold on
for i = 1:2
    case_name_chars = char(body_cases(i));
    speed = case_name_chars(1:3);
    
    % Load body data
    mat_name = body_cases(i) + ".mat";
    load(mat_name, 'wingbeat_avg_lift');
    lift_body = wingbeat_avg_lift;
    
    % Load wing data
    mat_name = wing_cases(i) + ".mat";
    load(mat_name,'wingbeat_avg_lift','frames');
    lift_PDMS = wingbeat_avg_lift;

    lift_sub = lift_PDMS - lift_body;
    
    % Plot lift force
    plot(frames, lift_sub, 'DisplayName', speed, "LineWidth",2);
end
legend("Location","Southwest");

%%

% ----------------------------------------------------------------
% --------Plot PDMS Data normalized by wingbeat cycles------------
% -------Filtered with Butterworth using Cutoff of 100 Hz---------
% ----------------------------------------------------------------
     
cases = ["2Hz_PDMS", "1Hz_PDMS"];
colors = [[0 0.4470 0.7410]; [0.8500 0.3250 0.0980]; [0.9290 0.6940 0.1250]];

% Open a new figure.
f = figure;
f.Position = [200 50 900 560];
title(["Filtered Lift Force (z-direction) - PDMS Wings" "Butterworth Filter (Cutoff: 100 Hz)"]);
xlabel("Wingbeat Number");
ylabel("Force (N)");
hold on

for i = 1:length(cases)
    % Load data
    mat_name = cases(i) + ".mat";
    load(mat_name);
    
    case_name = strrep(cases(i),'_',' ');
    case_name_chars = char(case_name);
    speed = str2double(case_name_chars(1));

    num_wingbeats = 100;
    frames_per_beat = (1280 / speed);

    wingbeats = linspace(0, num_wingbeats, frames_per_beat*num_wingbeats);

    fc = 100;
    fs = 1280;
    [b,a] = butter(6,fc/(fs/2));
    filtered_data = filter(b,a,trimmed_data(:, 4));
    
    % Plot lift force
    plot(wingbeats, filtered_data, 'DisplayName', case_name, "LineWidth", 2, 'Color', colors(speed,:));
end
legend("Location","Southwest");
ax1 = axes('Position',[0.35 0.2 0.2 0.2]);
hold on
for i = 1:length(cases)
    % Load data
    mat_name = cases(i) + ".mat";
    load(mat_name);
    
    case_name = strrep(cases(i),'_',' ');
    case_name_chars = char(case_name);
    speed = str2double(case_name_chars(1));

    fc = 100;
    fs = 1280;
    [b,a] = butter(6,fc/(fs/2));
    filtered_data = filter(b,a,trimmed_data(:, 4));
    
    % Plot lift force
    plot(ax1, wingbeats, filtered_data, 'Color', colors(speed,:))
    line(xlim, [0 0], 'Color','black'); % x-axis
end
xlim([32, 34])
ylim([-4, 4])
box on
annotation('arrow',[0.45 0.39], [0.4 0.52])

%%

% ----------------------------------------------------------------
% --------Plot PDMS Data normalized by wingbeat cycles------------
% ----------------and then wingbeat cycle averaged----------------
% -------Filtered with Butterworth using Cutoff of 100 Hz---------
% ----------------------------------------------------------------
     
cases = ["1Hz_PDMS", "2Hz_PDMS"];

% Open a new figure.
f = figure;
f.Position = [200 50 900 560];
title({"Lift Force (z-direction) - PDMS Wings" "Butterworth Filter (Cutoff: 100 Hz)"});
xlabel("Wingbeat Number");
ylabel("Force (N)");
hold on

for i = 1:length(cases)
    % Load data
    mat_name = cases(i) + ".mat";
    load(mat_name);
    
    case_name = strrep(cases(i),'_',' ');
    case_name_chars = char(case_name);
    speed = str2double(case_name_chars(1));
    
    fc = 100;
    fs = 1280;
    [b,a] = butter(6,fc/(fs/2));
    filtered_data = filter(b,a,wingbeat_avg_lift);
    
    % Plot lift force
    plot(frames, filtered_data, 'DisplayName', case_name, "LineWidth", 2);
end
legend("Location","Southwest");
    
%%

% ----------------------------------------------------------------
% --------Plot PDMS Data normalized by wingbeat cycles------------
% ----------------and then wingbeat cycle averaged----------------
% ------------Moving Average Filter Window (100 ms)---------------
% ----------------------------------------------------------------
     
cases = ["1Hz_PDMS", "2Hz_PDMS"];

% Open a new figure.
f = figure;
f.Position = [200 50 900 560];
title({"Lift Force (z-direction) - PDMS Wings" "Moving Average Filter Window (100 ms)"});
xlabel("Wingbeat Number");
ylabel("Force (N)");
hold on

for i = 1:length(cases)
    % Load data
    mat_name = cases(i) + ".mat";
    load(mat_name);
    
    case_name = strrep(cases(i),'_',' ');
    case_name_chars = char(case_name);
    speed = str2double(case_name_chars(1));
    
    % Filtering force data with moving average filter
    window = 100;
    b = 1 / window*ones(window,1);
    filtered_data = filter(b, 1, wingbeat_avg_lift);
    
    % Plot lift force
    plot(frames, filtered_data, 'DisplayName', case_name, "LineWidth", 2);
end
legend("Location","Southwest");

%%

% ----------------------------------------------------------------
% ------Plot PDMS and CB Data normalized by wingbeat cycles-------
% ----------------and then wingbeat cycle averaged----------------
% ----------------------------------------------------------------
% Open a new figure.
f = figure;
f.Position = [200 50 900 560];
tcl = tiledlayout(2,1);

cases = ["1Hz_PDMS", "2Hz_PDMS"];
colors = [[0 0.4470 0.7410]; [0.8500 0.3250 0.0980]; [0.9290 0.6940 0.1250]];

% First subplot for PDMS
nexttile(tcl)
hold on

for i = 1:length(cases)
    % Load data
    mat_name = cases(i) + ".mat";
    load(mat_name);
    
    case_name = strrep(cases(i),'_',' ');
    case_name_chars = char(case_name);
    speed = str2double(case_name_chars(1));

    num_wingbeats = 100;
    frames_per_beat = (1280 / speed);
    
    wingbeat_lifts = zeros(num_wingbeats, frames_per_beat);
    for j = 1:num_wingbeats
        for k = 1:frames_per_beat
            wingbeat_lifts(j,k) = trimmed_data(k + (frames_per_beat*(j-1)), 4);
        end
    end

    wingbeat_avg_lift = zeros(1,frames_per_beat);
    for k = 1:frames_per_beat
        wingbeat_avg_lift(k) = mean(wingbeat_lifts(:,k));
    end

    frames = linspace(0,1,frames_per_beat);
    
    % Plot lift force
    plot(frames, wingbeat_avg_lift, 'DisplayName', case_name, "LineWidth", 2, 'Color', colors(speed,:));
    save(cases(i) + ".mat", 'data','trimmed_data','trimmed_time','wingbeats', 'frames', 'wingbeat_avg_lift');
end
title("Lift Force (z-direction) - PDMS Wings");
xlabel("Wingbeat Number");
ylabel("Force (N)");
legend("Location","Northeast");
ylim([-4 4]);

cases = ["1Hz_CB", "2Hz_CB"];
colors = [[0 0.4470 0.7410]; [0.8500 0.3250 0.0980]; [0.9290 0.6940 0.1250]];

% First subplot for PDMS
nexttile(tcl)
hold on

for i = 1:length(cases)
    % Load data
    mat_name = cases(i) + ".mat";
    load(mat_name);
    
    case_name = strrep(cases(i),'_',' ');
    case_name_chars = char(case_name);
    speed = str2double(case_name_chars(1));

    num_wingbeats = 100;
    frames_per_beat = (1280 / speed);
    
    wingbeat_lifts = zeros(num_wingbeats, frames_per_beat);
    for j = 1:num_wingbeats
        for k = 1:frames_per_beat
            wingbeat_lifts(j,k) = trimmed_data(k + (frames_per_beat*(j-1)), 4);
        end
    end

    wingbeat_avg_lift = zeros(1,frames_per_beat);
    for k = 1:frames_per_beat
        wingbeat_avg_lift(k) = mean(wingbeat_lifts(:,k));
    end

    frames = linspace(0,1,frames_per_beat);
    
    % Plot lift force
    plot(frames, wingbeat_avg_lift, 'DisplayName', case_name, "LineWidth", 2, 'Color', colors(speed,:));
    save(cases(i) + ".mat", 'data','trimmed_data','trimmed_time','wingbeats', 'frames', 'wingbeat_avg_lift');
end
title("Lift Force (z-direction) - CB Wings");
xlabel("Wingbeat Number");
ylabel("Force (N)");
legend("Location","Northeast");
ylim([-4 4]);

% Label the whole figure.
sgtitle("Comparing Wingbeat Averaged Lift for PDMS and CB Wings");