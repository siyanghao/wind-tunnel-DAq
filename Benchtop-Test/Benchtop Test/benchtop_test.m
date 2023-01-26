clear
close all
% This program runs the motor and collects data from the force transducer
% for a single benchtop test.

% Load Cell: ATI Gamma IP65
% DAQ: NI USB-6341
% DMC: Galil DMC-4143
% Motor: VEXTA PH266-E1.2 stepper motor

% Modified by: Ronan Gissler November 2022
% Original by: Cameron Urban July 2022

%% Initalize the experiment
clc;
clear variables;
close all;

% -----------------------------------------------------------------------
% ----------Parameters to Adjust for Your Specific Experiment------------
% -----------------------------------------------------------------------
% Data Logging Parameters
case_name = "2Hz_body";

% Stepper Motor Parameters
galil_address = "192.168.1.20";
dmc_file_name = "benchtop_test_commented.dmc";
rev_ticks = 51200; % ticks per rev, should be 3200 instead
acc = 3*rev_ticks; % ticks / sec^2
vel = 2*rev_ticks; % ticks / sec
measure_revs = 100;
padding_revs = 10; % dropped from front and back during data processing
wait_time = 5000; % 5 seconds
distance = 0; % ticks

% Force Transducer Parameters
rate = 1000; % DAQ recording frequency (Hz)
offset_duration = 2; % Taring/Offset/Zeroing Time
session_duration = 0; % Measurement Time

estimate_params = {rev_ticks acc vel measure_revs padding_revs wait_time};
[distance, session_duration] = estimate_duration(estimate_params{:});

%% Setup the Galil DMC

% Create the carraige return and linefeed variable from the .dmc file.
dmc = fileread(dmc_file_name);
dmc = string(dmc);

% Replace the place holders in the .dmc file with the values specified
% here. Other parameters can be changed directly in .dmc file.
dmc = strrep(dmc, "accel_placeholder", num2str(acc));
dmc = strrep(dmc, "speed_placeholder", num2str(vel));
dmc = strrep(dmc, "distance_placeholder", num2str(distance));
dmc = strrep(dmc, "wait_time_placeholder", num2str(wait_time + 3000));
% later added extra 3 seconds in galil waiting time to account for
% extra time spent executing operations

% Connect to the Galil device.
galil = actxserver("galil");

% Set the Galil's address.
galil.address = galil_address;

% Load the program described by the .dmc file to the Galil device.
galil.programDownload(dmc);

%% Get offset data before flapping
FT_obj = ForceTransducer;
% Get the offsets at this angle.
offsets = FT_obj.get_force_offsets(case_name + "_before", rate, offset_duration);
offsets = offsets(1,:); % just taking means, no SDs

disp("Initial offset data has been gathered");
beep2;

%% Set up the DAQ
% Command the galil to execute the program
galil.command("XQ");

results = FT_obj.measure_force(case_name, rate, session_duration, offsets);

disp("Experiment data has been gathered");
beep2; 

%% Get offset data after flapping
FT_obj = ForceTransducer;
% Get the offsets at this angle.
offsets = FT_obj.get_force_offsets(case_name + "_after", rate, offset_duration);
offsets = offsets(1,:); % just taking means, no SDs

disp("Final offset data has been gathered");
beep2;

%% Clean up
delete(galil);

%% Display preliminary data
FT_obj.plot_results(results);