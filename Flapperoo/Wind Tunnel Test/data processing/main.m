% Author: Ronan Gissler
% Last updated: October 2023
clear
close all
addpath 'process_trial'
addpath 'process_trial/functions'
addpath 'plotting'
addpath 'modeling'

raw_data_path = "../raw data/experiment data/";
processed_data_path = "../processed data/";

% If set to true, user is allowed to select their own file
userSelect = false;

% Decide which plots to show using this struct of booleans
bools.raw = false; % Plot the raw data readings?
bools.time_data = false; % Plot the data in time
bools.kinematics = false; % Plot the wingbeat kinematics?
bools.eff_wind = false; % Plot the effective wind and AoA?
bools.model = true; % Plot the modeled forces?
bools.COP = false; % Plot the movement of the Center-of-Pressure?
bools.movie = false; % Make a movie using all wingbeats?
bools.spectrum = false; % Plot a frequency spectrum?

subtraction_string = "no wings with tail";
nondimensional = false;

if userSelect
    % Ask the user to select a file to examine the data from
    [file,path] = uigetfile(data_path + '*.mat');
    if isequal(file,0)
       disp('User selected Cancel');
    else
       disp(['User selected ', fullfile(path,file)]);
    end
    file = convertCharsToStrings(file);
else
    type = "blue wings with tail";
    wind_speed = 4;
    wing_freq = 2;
    AoA = 4;
    file = type + " " + wind_speed + "m.s " + AoA + "deg " + wing_freq + "Hz";
end

plot_trial(file, raw_data_path, processed_data_path, bools, subtraction_string, nondimensional)