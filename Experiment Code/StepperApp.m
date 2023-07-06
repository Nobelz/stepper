classdef StepperApp < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                     matlab.ui.Figure
        StartButton                  matlab.ui.control.Button
        ConservedButtonGroup         matlab.ui.container.ButtonGroup
        Conserved2Button             matlab.ui.control.RadioButton
        Conserved1Button             matlab.ui.control.RadioButton
        ArenaHzSpinner               matlab.ui.control.Spinner
        ArenaHzSpinnerLabel          matlab.ui.control.Label
        ExperimentModeDropDown       matlab.ui.control.DropDown
        ExperimentModeDropDownLabel  matlab.ui.control.Label
        StepperHzSpinner             matlab.ui.control.Spinner
        StepperHzSpinnerLabel        matlab.ui.control.Label
        FrequencyOptionsLabel        matlab.ui.control.Label
        MsequenceOptionsLabel        matlab.ui.control.Label
        FlyOptionsLabel              matlab.ui.control.Label
        DelayedCheckBox              matlab.ui.control.CheckBox
        DoubledCheckBox              matlab.ui.control.CheckBox
        ConservedTrialCheckBox       matlab.ui.control.CheckBox
        TrialNumberSpinner           matlab.ui.control.Spinner
        TrialNumberSpinnerLabel      matlab.ui.control.Label
        FlyNumberSpinner             matlab.ui.control.Spinner
        FlyNumberSpinnerLabel        matlab.ui.control.Label
        HalterelessCheckBox          matlab.ui.control.CheckBox
    end

    
    methods (Access = private)
        
        function disableAll(app)
            reset(app);
            app.ExperimentModeDropDown.Value = 'Select...';
            app.ExperimentModeDropDown.Enable = 'off';
        end

        function enableAll(app)
            app.ExperimentModeDropDown.Enable = 'on';
            checkExperiment(app);
        end

        function reset(app)
            app.FlyNumberSpinner.Enable = 'off';
            app.FlyNumberSpinnerLabel.Enable = 'off';
            app.TrialNumberSpinner.Enable = 'off';
            app.TrialNumberSpinnerLabel.Enable = 'off';
            app.ConservedTrialCheckBox.Enable = 'off';
            app.ConservedButtonGroup.Enable = 'off';
            app.HalterelessCheckBox.Enable = 'off';
            app.DoubledCheckBox.Enable = 'off';
            app.DelayedCheckBox.Enable = 'off';
            app.ArenaHzSpinner.Enable = 'off';
            app.ArenaHzSpinnerLabel.Enable = 'off';
            app.StepperHzSpinner.Enable = 'off';
            app.StepperHzSpinnerLabel.Enable = 'off';
            app.StartButton.Enable = 'off';
        end

        function checkConserved(app)
            if app.ConservedTrialCheckBox.Value
                app.DelayedCheckBox.Enable = 'off';
                app.DoubledCheckBox.Enable = 'off';
                app.TrialNumberSpinner.Enable = 'off';
                app.TrialNumberSpinnerLabel.Enable = 'off';

                if strcmp(app.ExperimentModeDropDown.Value, 'BimodalRandom')
                    app.ConservedButtonGroup.Enable = 'on';
                    app.Conserved1Button.Enable = 'on';
                    app.Conserved2Button.Enable = 'on';
                else
                    app.ConservedButtonGroup.Enable = 'off';
                    app.Conserved1Button.Enable = 'off';
                    app.Conserved2Button.Enable = 'off';
                end
            else
                if ~strncmpi(app.ExperimentModeDropDown.Value, 'Bimodal', 7)
                    app.DelayedCheckBox.Enable = 'on';
                    app.DoubledCheckBox.Enable = 'on';
                end

                app.TrialNumberSpinner.Enable = 'on';
                app.TrialNumberSpinnerLabel.Enable = 'on';
                app.ConservedButtonGroup.Enable = 'off';
                app.Conserved1Button.Enable = 'off';
                app.Conserved2Button.Enable = 'off';
            end
        end

        function checkExperiment(app)
            value = app.ExperimentModeDropDown.Value;
            
            if strcmp(value, 'Select...')
                reset(app);
            else
                app.StartButton.Enable = 'on';
                app.HalterelessCheckBox.Enable = 'on';
                app.FlyNumberSpinner.Enable = 'on';
                app.FlyNumberSpinnerLabel.Enable = 'on';
                app.ConservedTrialCheckBox.Enable = 'on';
                checkConserved(app);

                if strcmp(value, 'ArenaOnly')
                    app.StepperHzSpinner.Enable = 'off';
                    app.StepperHzSpinnerLabel.Enable = 'off';
                    app.ArenaHzSpinner.Enable = 'on';
                    app.ArenaHzSpinnerLabel.Enable = 'on';
                    app.DoubledCheckBox.Enable = 'on';
                    app.DelayedCheckBox.Enable = 'on';
                elseif strncmpi(value, 'Stepper', 7)
                    app.ArenaHzSpinner.Enable = 'off';
                    app.ArenaHzSpinnerLabel.Enable = 'off';
                    app.StepperHzSpinner.Enable = 'on';
                    app.StepperHzSpinnerLabel.Enable = 'on';
                    app.DoubledCheckBox.Enable = 'on';
                    app.DelayedCheckBox.Enable = 'on';
                else
                    app.ArenaHzSpinner.Enable = 'on';
                    app.ArenaHzSpinnerLabel.Enable = 'on';
                    app.ArenaHzSpinner.Limits = [25 50];
                    app.StepperHzSpinner.Enable = 'off';
                    app.StepperHzSpinnerLabel.Enable = 'off';
                    app.DoubledCheckBox.Enable = 'off';
                    app.DelayedCheckBox.Enable = 'off';
                end

                if ~strncmpi(value, 'Bimodal', 7)
                    app.ArenaHzSpinner.Limits = [0 50];
                    app.StepperHzSpinner.Enable = 'on';
                    app.StepperHzSpinnerLabel.Enable = 'on';
                end
            end

            checkConserved(app);
        end
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Value changed function: ConservedTrialCheckBox
        function ConservedTrialCheckBoxValueChanged(app, event)
            checkConserved(app);                
        end

        % Value changed function: FlyNumberSpinner
        function FlyNumberSpinnerValueChanged(app, event)
            app.TrialNumberSpinner.Value = 1;
            app.ConservedTrialCheckBox.Value = 0;
            checkConserved(app);
        end

        % Button pushed function: StartButton
        function StartButtonPushed(app, event)
            disableAll(app);
            
            if app.ConservedTrialCheckBox.Value
                if strcmp(app.ExperimentModeDropDown.Value, 'BimodalRandom')
                    if app.Conserved1Button.Value
                        trial = 'con1';
                    else
                        trial = 'con2';
                    end
                else
                    trial = 'con';
                end
            else
                trial = app.TrialNumberSpinner.Value;
                app.TrialNumberSpinner.Value = trial + 1;
            end

            if strncmpi(app.ExperimentModeDropDown.Value, 'Bimodal', 7)
                doubled = 0;
                delayed = 0;
            else
                doubled = app.DoubledCheckBox.Value;
                delayed = app.DelayedCheckBox.Value;
            end

            if strncmpi(app.ExperimentModeDropDown.Value, 'Stepper', 7)
                arenaHz = 0;
                stepperHz = app.StepperHzSpinner.Value;
            else
                arenaHz = app.ArenaHzSpinner.Value;
                stepperHz = arenaHz;
            end
            
            while (experimentHandler(app.FlyNumberSpinner.Value, ...
                trial, 'PCF', ~app.HalterelessCheckBox.Value, ...
                app.ExperimentModeDropDown.Value, doubled, delayed, ...
                arenaHz, stepperHz))
            end
        
            enableAll(app);
        end

        % Value changed function: ExperimentModeDropDown
        function ExperimentModeDropDownValueChanged(app, event)
            checkExperiment(app);
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 377 343];
            app.UIFigure.Name = 'MATLAB App';

            % Create HalterelessCheckBox
            app.HalterelessCheckBox = uicheckbox(app.UIFigure);
            app.HalterelessCheckBox.Enable = 'off';
            app.HalterelessCheckBox.Text = 'Haltereless';
            app.HalterelessCheckBox.Position = [43 93 85 26];

            % Create FlyNumberSpinnerLabel
            app.FlyNumberSpinnerLabel = uilabel(app.UIFigure);
            app.FlyNumberSpinnerLabel.HorizontalAlignment = 'right';
            app.FlyNumberSpinnerLabel.Enable = 'off';
            app.FlyNumberSpinnerLabel.Position = [30 232 67 22];
            app.FlyNumberSpinnerLabel.Text = 'Fly Number';

            % Create FlyNumberSpinner
            app.FlyNumberSpinner = uispinner(app.UIFigure);
            app.FlyNumberSpinner.Limits = [1 Inf];
            app.FlyNumberSpinner.ValueChangedFcn = createCallbackFcn(app, @FlyNumberSpinnerValueChanged, true);
            app.FlyNumberSpinner.Enable = 'off';
            app.FlyNumberSpinner.Position = [112 230 50 26];
            app.FlyNumberSpinner.Value = 1;

            % Create TrialNumberSpinnerLabel
            app.TrialNumberSpinnerLabel = uilabel(app.UIFigure);
            app.TrialNumberSpinnerLabel.HorizontalAlignment = 'right';
            app.TrialNumberSpinnerLabel.Enable = 'off';
            app.TrialNumberSpinnerLabel.Position = [23 199 74 22];
            app.TrialNumberSpinnerLabel.Text = 'Trial Number';

            % Create TrialNumberSpinner
            app.TrialNumberSpinner = uispinner(app.UIFigure);
            app.TrialNumberSpinner.Limits = [1 Inf];
            app.TrialNumberSpinner.Enable = 'off';
            app.TrialNumberSpinner.Position = [112 197 50 26];
            app.TrialNumberSpinner.Value = 1;

            % Create ConservedTrialCheckBox
            app.ConservedTrialCheckBox = uicheckbox(app.UIFigure);
            app.ConservedTrialCheckBox.ValueChangedFcn = createCallbackFcn(app, @ConservedTrialCheckBoxValueChanged, true);
            app.ConservedTrialCheckBox.Enable = 'off';
            app.ConservedTrialCheckBox.Text = 'Conserved Trial';
            app.ConservedTrialCheckBox.Position = [43 170 106 26];

            % Create DoubledCheckBox
            app.DoubledCheckBox = uicheckbox(app.UIFigure);
            app.DoubledCheckBox.Enable = 'off';
            app.DoubledCheckBox.Text = 'Doubled';
            app.DoubledCheckBox.Position = [242 230 85 26];

            % Create DelayedCheckBox
            app.DelayedCheckBox = uicheckbox(app.UIFigure);
            app.DelayedCheckBox.Enable = 'off';
            app.DelayedCheckBox.Text = 'Delayed';
            app.DelayedCheckBox.Position = [242 205 106 26];

            % Create FlyOptionsLabel
            app.FlyOptionsLabel = uilabel(app.UIFigure);
            app.FlyOptionsLabel.HorizontalAlignment = 'center';
            app.FlyOptionsLabel.Position = [63 254 66 22];
            app.FlyOptionsLabel.Text = 'Fly Options';

            % Create MsequenceOptionsLabel
            app.MsequenceOptionsLabel = uilabel(app.UIFigure);
            app.MsequenceOptionsLabel.HorizontalAlignment = 'center';
            app.MsequenceOptionsLabel.Position = [227 254 116 22];
            app.MsequenceOptionsLabel.Text = 'M-sequence Options';

            % Create FrequencyOptionsLabel
            app.FrequencyOptionsLabel = uilabel(app.UIFigure);
            app.FrequencyOptionsLabel.HorizontalAlignment = 'center';
            app.FrequencyOptionsLabel.Position = [232 174 106 22];
            app.FrequencyOptionsLabel.Text = 'Frequency Options';

            % Create StepperHzSpinnerLabel
            app.StepperHzSpinnerLabel = uilabel(app.UIFigure);
            app.StepperHzSpinnerLabel.HorizontalAlignment = 'right';
            app.StepperHzSpinnerLabel.Enable = 'off';
            app.StepperHzSpinnerLabel.Position = [232 120 65 22];
            app.StepperHzSpinnerLabel.Text = 'Stepper Hz';

            % Create StepperHzSpinner
            app.StepperHzSpinner = uispinner(app.UIFigure);
            app.StepperHzSpinner.Limits = [1 100];
            app.StepperHzSpinner.RoundFractionalValues = 'on';
            app.StepperHzSpinner.Enable = 'off';
            app.StepperHzSpinner.Position = [301 118 50 26];
            app.StepperHzSpinner.Value = 50;

            % Create ExperimentModeDropDownLabel
            app.ExperimentModeDropDownLabel = uilabel(app.UIFigure);
            app.ExperimentModeDropDownLabel.HorizontalAlignment = 'right';
            app.ExperimentModeDropDownLabel.Position = [-20 294 128 22];
            app.ExperimentModeDropDownLabel.Text = 'Experiment Mode';

            % Create ExperimentModeDropDown
            app.ExperimentModeDropDown = uidropdown(app.UIFigure);
            app.ExperimentModeDropDown.Items = {'Select...', 'ArenaOnly', 'StepperOnlyStripes', 'StepperOnlyAllOn', 'BimodalCoherent', 'BimodalRandom', 'BimodalOpposing'};
            app.ExperimentModeDropDown.ValueChangedFcn = createCallbackFcn(app, @ExperimentModeDropDownValueChanged, true);
            app.ExperimentModeDropDown.Position = [127 294 234 22];
            app.ExperimentModeDropDown.Value = 'Select...';

            % Create ArenaHzSpinnerLabel
            app.ArenaHzSpinnerLabel = uilabel(app.UIFigure);
            app.ArenaHzSpinnerLabel.HorizontalAlignment = 'right';
            app.ArenaHzSpinnerLabel.Enable = 'off';
            app.ArenaHzSpinnerLabel.Position = [242 148 55 22];
            app.ArenaHzSpinnerLabel.Text = 'Arena Hz';

            % Create ArenaHzSpinner
            app.ArenaHzSpinner = uispinner(app.UIFigure);
            app.ArenaHzSpinner.Step = 25;
            app.ArenaHzSpinner.Limits = [0 50];
            app.ArenaHzSpinner.RoundFractionalValues = 'on';
            app.ArenaHzSpinner.Enable = 'off';
            app.ArenaHzSpinner.Position = [301 146 50 26];
            app.ArenaHzSpinner.Value = 50;

            % Create ConservedButtonGroup
            app.ConservedButtonGroup = uibuttongroup(app.UIFigure);
            app.ConservedButtonGroup.Enable = 'off';
            app.ConservedButtonGroup.BorderWidth = 0;
            app.ConservedButtonGroup.Position = [50 120 115 50];

            % Create Conserved1Button
            app.Conserved1Button = uiradiobutton(app.ConservedButtonGroup);
            app.Conserved1Button.Enable = 'off';
            app.Conserved1Button.Text = 'Conserved 1';
            app.Conserved1Button.Position = [11 29 90 22];
            app.Conserved1Button.Value = true;

            % Create Conserved2Button
            app.Conserved2Button = uiradiobutton(app.ConservedButtonGroup);
            app.Conserved2Button.Enable = 'off';
            app.Conserved2Button.Text = 'Conserved 2';
            app.Conserved2Button.Position = [11 8 90 22];

            % Create StartButton
            app.StartButton = uibutton(app.UIFigure, 'push');
            app.StartButton.ButtonPushedFcn = createCallbackFcn(app, @StartButtonPushed, true);
            app.StartButton.Enable = 'off';
            app.StartButton.Position = [72 19 237 65];
            app.StartButton.Text = 'Start';

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = StepperApp

            runningApp = getRunningApp(app);

            % Check for running singleton app
            if isempty(runningApp)

                % Create UIFigure and components
                createComponents(app)

                % Register the app with App Designer
                registerApp(app, app.UIFigure)
            else

                % Focus the running singleton app
                figure(runningApp.UIFigure)

                app = runningApp;
            end

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end