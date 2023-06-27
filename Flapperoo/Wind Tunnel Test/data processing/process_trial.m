clear
close all

% Ronan Gissler June 2023

% This file is used to plot the raw force transducer data from a
% single trial, giving a quick view of what that trial looked like.

[file,path] = uigetfile('C:\Users\rgissler\Desktop\Ronan Lab Documents\Stability Test Data\06_17_23\experiment data\*.csv');
if isequal(file,0)
   disp('User selected Cancel');
else
   disp(['User selected ', fullfile(path,file)]);
end

file = convertCharsToStrings(file);

frame_rate = 9000; % Hz
num_wingbeats = 180;

% Get case name from file name
case_name = erase(file, ["_experiment_061723.csv", "_experiment_061823.csv"]);
case_name = strrep(case_name,'_',' ');

case_parts = strtrim(split(case_name));
wing_freq = -1;
AoA = -1;
for j=1:length(case_parts)
    if (contains(case_parts(j), "Hz"))
        wing_freq = str2double(erase(case_parts(j), "Hz"));
    elseif (contains(case_parts(j), "deg"))
        AoA = str2double(erase(case_parts(j), "deg"));
    elseif (contains(case_parts(j), "m.s"))
        wind_speed = str2double(erase(case_parts(j), "m.s"));
    end
end

% Get data from file
data = readmatrix(path + file);

raw_data = data(:,1:7);
raw_trigger = data(:,8);

trimmed_results = trim_data(raw_data, raw_trigger);

if (length(raw_data) == length(trimmed_results))
    disp("Data was not trimmed.")
end

time_data = trimmed_results(:,1);
force_data = trimmed_results(:,2:7);

results_lab = coordinate_transformation(force_data, AoA);
x_label = "Time (s)";
y_label_F = "Force (N)";
y_label_M = "Moment (N*m)";
subtitle = "Trimmed, Rotated";
axes_labels = [x_label, y_label_F, y_label_M];
plot_forces(time_data, results_lab, case_name, subtitle, axes_labels);

norm_data = non_dimensionalize_data(results_lab, wing_freq, wind_speed);
x_label = "Time (s)";
y_label_F = "Force Coefficient";
y_label_M = "Moment Coefficient";
subtitle = "Trimmed, Rotated, Non-dimensionalized";
axes_labels = [x_label, y_label_F, y_label_M];
plot_forces(time_data, norm_data, case_name, subtitle, axes_labels);

filtered_data = filter_data(norm_data, frame_rate);
x_label = "Time (s)";
y_label_F = "Force Coefficient";
y_label_M = "Moment Coefficient";
subtitle = "Trimmed, Rotated, Non-dimensionalized, Filtered";
axes_labels = [x_label, y_label_F, y_label_M];
plot_forces(time_data, filtered_data, case_name, subtitle, axes_labels);

freq_spectrum(filtered_data, frame_rate, case_name);

wingbeats = linspace(0, num_wingbeats, length(trimmed_results));

[wingbeat_forces, frames, wingbeat_avg_forces, wingbeat_rmse_forces] = wingbeat_transformation(num_wingbeats, norm_data);
x_label = "Wingbeat Period (t/T)";
y_label_F = "Force Coefficient";
y_label_M = "Moment Coefficient";
axes_labels = [x_label, y_label_F, y_label_M];
subtitle = "Trimmed, Rotated, Non-dimensionalized, Filtered, Wingbeat Averaged";
plot_forces(frames, wingbeat_avg_forces, case_name, subtitle, axes_labels);

x_label = "Wingbeat Period (t/T)";
y_label_F = "RMS";
y_label_M = "RMS";
axes_labels = [x_label, y_label_F, y_label_M];
subtitle = "Trimmed, Rotated, Non-dimensionalized, Filtered, Wingbeat RMS'd";
plot_forces(frames, wingbeat_rmse_forces, case_name, subtitle, axes_labels);