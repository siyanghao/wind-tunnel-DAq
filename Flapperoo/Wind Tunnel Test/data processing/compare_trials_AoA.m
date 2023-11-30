% Author: Ronan Gissler
% Last updated: October 2023
clear
close all
addpath 'process trial'
addpath 'process trial/functions'
addpath 'plotting'

% -----------------------------------------------------------------
% ----The parameter combinations you want to see the data for------
% -----------------------------------------------------------------
% wing_freq_sel = [0];
% wind_speed_sel = [0,2,4,6];
% type_sel = ["tubespars v2"];
% AoA_sel = -16:2:16;

freq_speed_combos = [2, 4; 4, 4];

% 0,2,3,4,5  4; 0,3,4  6;

wing_freq_sel = [0,2,4];
wind_speed_sel = [4];
type_sel = ["no wings"];
AoA_sel = -16:2:16;
% AoA_sel = -2:2:2;

% With the experiments that were run on 10_12_2023 these are the options:
% wing_freq_sel - 0, 3, 5, 6
% wind_speed_sel - 0, 4, 8
% type_sel - "small blue", "small blue flap", "big blue"
% AoA_sel = [-10, -4, 0, 4, 10] or [-14, -10, -6, -2, 0, 2, 6, 10, 14]
% Note that not all combination of these variables were recorded, examine
% the raw data folder to see what data is actually available.

% To see the high speed static aerodynamics, try this:
% wing_freq_sel = [0];
% wind_speed_sel = [8];
% type_sel = ["small blue"];
% AoA_sel = [-14, -10, -6, -2, 0, 2, 6, 10, 14];

% path to folder where all processed data (.mat files) are stored
processed_data_path = "../processed data/";

% select_type_UI(processed_data_path)

bool.norm = true;
bool.body_sub = false;

% Put all our selected variables into a struct called selected_vars
selected_vars.AoA = AoA_sel;
selected_vars.freq = wing_freq_sel;
selected_vars.wind = wind_speed_sel;
selected_vars.type = type_sel;

forceIndex = 5;

[avg_forces, err_forces, names, sub_title] = get_data_AoA(selected_vars, processed_data_path, bool);

plot_forces_AoA(selected_vars, avg_forces, err_forces, names, sub_title, bool.norm, forceIndex);

% [avg_forces, err_forces, names, sub_title] = get_data_AoA_combo(freq_speed_combos,selected_vars, processed_data_path, bool);
% 
% plot_forces_AoA_combo(freq_speed_combos, selected_vars, avg_forces, err_forces, names, sub_title, bool.norm, forceIndex);