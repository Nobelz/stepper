classdef StepperApp < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                    matlab.ui.Figure
        SetupArenaVoltagesCheckBox  matlab.ui.control.CheckBox
        ArenaOnlyOptionsLabel       matlab.ui.control.Label
        MsequenceOptionsLabel_2     matlab.ui.control.Label
        StepperHzSpinner            matlab.ui.control.Spinner
        StepperHzSpinnerLabel       matlab.ui.control.Label
        ArenaHzSpinner              matlab.ui.control.Spinner
        ArenaHzSpinnerLabel         matlab.ui.control.Label
        MsequenceOptionsLabel       matlab.ui.control.Label
        FlyOptionsLabel             matlab.ui.control.Label
        BimodalOptionsLabel         matlab.ui.control.Label
        StepperOnlyOptionsLabel     matlab.ui.control.Label
        DelayedCheckBox             matlab.ui.control.CheckBox
        DoubledCheckBox             matlab.ui.control.CheckBox
        BimodalOpposingButton       matlab.ui.control.Button
        BimodalCoherentButton       matlab.ui.control.Button
        BimodalRandomButton         matlab.ui.control.Button
        VisualOnlyButton            matlab.ui.control.Button
        StepperOnlyStripesButton    matlab.ui.control.Button
        StepperOnlyAllOnButton      matlab.ui.control.Button
        ConservedTrialCheckBox      matlab.ui.control.CheckBox
        FlyTrialSpinner             matlab.ui.control.Spinner
        FlyTrialSpinnerLabel        matlab.ui.control.Label
        FlyNumberSpinner            matlab.ui.control.Spinner
        FlyNumberSpinnerLabel       matlab.ui.control.Label
        HalterelessCheckBox         matlab.ui.control.CheckBox
    end

    
    methods (Access = private)
        
        function disableAll(app)
            app.ArenaHzSpinner.Enable = 'off';
            app.StepperHzSpinner.Enable = 'off';
            app.DelayedCheckBox.Enable = 'off';
            app.DoubledCheckBox.Enable = 'off';
            app.SetupArenaVoltagesCheckBox.Enable = 'off';
            app.BimodalOpposingButton.Enable = 'off';
            app.BimodalCoherentButton.Enable = 'off';
            app.BimodalRandomButton.Enable = 'off';
            app.VisualOnlyButton.Enable = 'off';
            app.StepperOnlyStripesButton.Enable = 'off';
            app.StepperOnlyAllOnButton.Enable = 'off';
            app.ConservedTrialCheckBox.Enable = 'off';
            app.FlyTrialSpinner.Enable = 'off';
            app.FlyNumberSpinner.Enable = 'off';
            app.HalterelessCheckBox.Enable = 'off';
        end

        function enableAll(app)
            app.ArenaHzSpinner.Enable = 'on';
            app.StepperHzSpinner.Enable = 'on';
            app.DelayedCheckBox.Enable = 'on';
            app.DoubledCheckBox.Enable = 'on';
            app.SetupArenaVoltagesCheckBox.Enable = 'on';
            app.BimodalOpposingButton.Enable = 'on';
            app.BimodalCoherentButton.Enable = 'on';
            app.BimodalRandomButton.Enable = 'on';
            app.VisualOnlyButton.Enable = 'on';
            app.StepperOnlyStripesButton.Enable = 'on';
            app.StepperOnlyAllOnButton.Enable = 'on';
            app.FlyTrialSpinner.Enable = 'on';
            app.FlyNumberSpinner.Enable = 'on';
            app.HalterelessCheckBox.Enable = 'on';
            app.ConservedTrialCheckBox.Enable = 'on';
            app.SetupArenaVoltagesCheckBox.Value = 0;
        end
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Value changed function: ConservedTrialCheckBox
        function ConservedTrialCheckBoxValueChanged(app, event)
            
            value = app.ConservedTrialCheckBox.Value;
            if value == 1
                app.DelayedCheckBox.Enable = 'off';
                app.DoubledCheckBox.Enable = 'off';
                app.FlyTrialSpinner.Enable = 'off';
            else
                app.DelayedCheckBox.Enable = 'on';
                app.DoubledCheckBox.Enable = 'on';
                app.FlyTrialSpinner.Enable = 'on';
            end
        end

        % Button pushed function: StepperOnlyAllOnButton
        function StepperOnlyAllOnButtonPushed(app, event)
            disableAll(app);
            experimentHandler(app.FlyNumberSpinner.Value, ...
                app.FlyTrialSpinner.Value, 'PCF', ...
                ~app.HalterelessCheckBox.Value, 'StepperOnlyAllOn', ...
                app.DoubledCheckBox.Value, app.DelayedCheckBox.Value, ...
                0, app.ArenaHzSpinner.Value, app.StepperHzSpinner.Value);
            enableAll(app);
        end

        % Button pushed function: StepperOnlyStripesButton
        function StepperOnlyStripesButtonPushed(app, event)
            disableAll(app);
            experimentHandler(app.FlyNumberSpinner.Value, ...
                app.FlyTrialSpinner.Value, 'PCF', ...
                ~app.HalterelessCheckBox.Value, 'StepperOnlyStripes', ...
                app.DoubledCheckBox.Value, app.DelayedCheckBox.Value, ...
                0, app.ArenaHzSpinner.Value, app.StepperHzSpinner.Value);
            enableAll(app);
        end

        % Button pushed function: VisualOnlyButton
        function VisualOnlyButtonPushed(app, event)
            disableAll(app);
            experimentHandler(app.FlyNumberSpinner.Value, ...
                app.FlyTrialSpinner.Value, 'PCF', ...
                ~app.HalterelessCheckBox.Value, 'ArenaOnly', ...
                app.DoubledCheckBox.Value, app.DelayedCheckBox.Value, ...
                app.SetupArenaVoltagesCheckBox.Value, ...
                app.ArenaHzSpinner.Value, app.StepperHzSpinner.Value);
            enableAll(app);
        end

        % Button pushed function: BimodalRandomButton
        function BimodalRandomButtonPushed(app, event)
            disableAll(app);
            experimentHandler(app.FlyNumberSpinner.Value, ...
                app.FlyTrialSpinner.Value, 'PCF', ...
                ~app.HalterelessCheckBox.Value, 'BimodalRandom', ...
                0, 0, app.SetupArenaVoltagesCheckBox.Value, ...
                app.ArenaHzSpinner.Value, app.StepperHzSpinner.Value);
            enableAll(app);
        end

        % Button pushed function: BimodalCoherentButton
        function BimodalCoherentButtonPushed(app, event)
            disableAll(app);
            experimentHandler(app.FlyNumberSpinner.Value, ...
                app.FlyTrialSpinner.Value, 'PCF', ...
                ~app.HalterelessCheckBox.Value, 'BimodalCoherent', ...
                0, 0, app.SetupArenaVoltagesCheckBox.Value, ...
                app.ArenaHzSpinner.Value, app.StepperHzSpinner.Value);
            enableAll(app);
        end

        % Button pushed function: BimodalOpposingButton
        function BimodalOpposingButtonPushed(app, event)
            disableAll(app);
            experimentHandler(app.FlyNumberSpinner.Value, ...
                app.FlyTrialSpinner.Value, 'PCF', ...
                ~app.HalterelessCheckBox.Value, 'BimodalOpposing', ...
                0, 0, app.SetupArenaVoltagesCheckBox.Value, ...
                app.ArenaHzSpinner.Value, app.StepperHzSpinner.Value);
            enableAll(app);
        end

        % Value changed function: FlyNumberSpinner
        function FlyNumberSpinnerValueChanged(app, event)
            app.FlyTrialSpinner.Value = 1;
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 378 420];
            app.UIFigure.Name = 'MATLAB App';

            % Create HalterelessCheckBox
            app.HalterelessCheckBox = uicheckbox(app.UIFigure);
            app.HalterelessCheckBox.Text = 'Haltereless';
            app.HalterelessCheckBox.Position = [252 279 85 26];

            % Create FlyNumberSpinnerLabel
            app.FlyNumberSpinnerLabel = uilabel(app.UIFigure);
            app.FlyNumberSpinnerLabel.HorizontalAlignment = 'right';
            app.FlyNumberSpinnerLabel.Position = [229 354 67 22];
            app.FlyNumberSpinnerLabel.Text = 'Fly Number';

            % Create FlyNumberSpinner
            app.FlyNumberSpinner = uispinner(app.UIFigure);
            app.FlyNumberSpinner.Limits = [1 Inf];
            app.FlyNumberSpinner.ValueChangedFcn = createCallbackFcn(app, @FlyNumberSpinnerValueChanged, true);
            app.FlyNumberSpinner.Position = [311 352 50 26];
            app.FlyNumberSpinner.Value = 1;

            % Create FlyTrialSpinnerLabel
            app.FlyTrialSpinnerLabel = uilabel(app.UIFigure);
            app.FlyTrialSpinnerLabel.HorizontalAlignment = 'right';
            app.FlyTrialSpinnerLabel.Position = [229 317 47 22];
            app.FlyTrialSpinnerLabel.Text = 'Fly Trial';

            % Create FlyTrialSpinner
            app.FlyTrialSpinner = uispinner(app.UIFigure);
            app.FlyTrialSpinner.Limits = [1 Inf];
            app.FlyTrialSpinner.Position = [311 315 50 26];
            app.FlyTrialSpinner.Value = 1;

            % Create ConservedTrialCheckBox
            app.ConservedTrialCheckBox = uicheckbox(app.UIFigure);
            app.ConservedTrialCheckBox.ValueChangedFcn = createCallbackFcn(app, @ConservedTrialCheckBoxValueChanged, true);
            app.ConservedTrialCheckBox.Text = 'Conserved Trial';
            app.ConservedTrialCheckBox.Position = [252 254 106 26];

            % Create StepperOnlyAllOnButton
            app.StepperOnlyAllOnButton = uibutton(app.UIFigure, 'push');
            app.StepperOnlyAllOnButton.ButtonPushedFcn = createCallbackFcn(app, @StepperOnlyAllOnButtonPushed, true);
            app.StepperOnlyAllOnButton.Position = [7 331 85 62];
            app.StepperOnlyAllOnButton.Text = {'Stepper Only'; 'All On'};

            % Create StepperOnlyStripesButton
            app.StepperOnlyStripesButton = uibutton(app.UIFigure, 'push');
            app.StepperOnlyStripesButton.ButtonPushedFcn = createCallbackFcn(app, @StepperOnlyStripesButtonPushed, true);
            app.StepperOnlyStripesButton.Position = [100 331 85 62];
            app.StepperOnlyStripesButton.Text = {'Stepper Only'; 'Stripes'};

            % Create VisualOnlyButton
            app.VisualOnlyButton = uibutton(app.UIFigure, 'push');
            app.VisualOnlyButton.ButtonPushedFcn = createCallbackFcn(app, @VisualOnlyButtonPushed, true);
            app.VisualOnlyButton.Position = [7 245 84 44];
            app.VisualOnlyButton.Text = 'Visual Only';

            % Create BimodalRandomButton
            app.BimodalRandomButton = uibutton(app.UIFigure, 'push');
            app.BimodalRandomButton.ButtonPushedFcn = createCallbackFcn(app, @BimodalRandomButtonPushed, true);
            app.BimodalRandomButton.Position = [7 153 177 62];
            app.BimodalRandomButton.Text = 'Bimodal, Random';

            % Create BimodalCoherentButton
            app.BimodalCoherentButton = uibutton(app.UIFigure, 'push');
            app.BimodalCoherentButton.ButtonPushedFcn = createCallbackFcn(app, @BimodalCoherentButtonPushed, true);
            app.BimodalCoherentButton.Position = [7 82 177 62];
            app.BimodalCoherentButton.Text = 'Bimodal, Coherent';

            % Create BimodalOpposingButton
            app.BimodalOpposingButton = uibutton(app.UIFigure, 'push');
            app.BimodalOpposingButton.ButtonPushedFcn = createCallbackFcn(app, @BimodalOpposingButtonPushed, true);
            app.BimodalOpposingButton.Position = [7 10 177 62];
            app.BimodalOpposingButton.Text = 'Bimodal, Opposing';

            % Create DoubledCheckBox
            app.DoubledCheckBox = uicheckbox(app.UIFigure);
            app.DoubledCheckBox.Text = 'Doubled';
            app.DoubledCheckBox.Position = [262 148 85 26];

            % Create DelayedCheckBox
            app.DelayedCheckBox = uicheckbox(app.UIFigure);
            app.DelayedCheckBox.Text = 'Delayed';
            app.DelayedCheckBox.Position = [262 123 106 26];

            % Create StepperOnlyOptionsLabel
            app.StepperOnlyOptionsLabel = uilabel(app.UIFigure);
            app.StepperOnlyOptionsLabel.HorizontalAlignment = 'center';
            app.StepperOnlyOptionsLabel.Position = [36 392 120 22];
            app.StepperOnlyOptionsLabel.Text = 'Stepper Only Options';

            % Create BimodalOptionsLabel
            app.BimodalOptionsLabel = uilabel(app.UIFigure);
            app.BimodalOptionsLabel.HorizontalAlignment = 'center';
            app.BimodalOptionsLabel.Position = [49 214 93 22];
            app.BimodalOptionsLabel.Text = 'Bimodal Options';

            % Create FlyOptionsLabel
            app.FlyOptionsLabel = uilabel(app.UIFigure);
            app.FlyOptionsLabel.HorizontalAlignment = 'center';
            app.FlyOptionsLabel.Position = [262 380 66 22];
            app.FlyOptionsLabel.Text = 'Fly Options';

            % Create MsequenceOptionsLabel
            app.MsequenceOptionsLabel = uilabel(app.UIFigure);
            app.MsequenceOptionsLabel.HorizontalAlignment = 'center';
            app.MsequenceOptionsLabel.Position = [237 173 116 22];
            app.MsequenceOptionsLabel.Text = 'M-sequence Options';

            % Create ArenaHzSpinnerLabel
            app.ArenaHzSpinnerLabel = uilabel(app.UIFigure);
            app.ArenaHzSpinnerLabel.HorizontalAlignment = 'right';
            app.ArenaHzSpinnerLabel.Position = [229 63 55 22];
            app.ArenaHzSpinnerLabel.Text = 'Arena Hz';

            % Create ArenaHzSpinner
            app.ArenaHzSpinner = uispinner(app.UIFigure);
            app.ArenaHzSpinner.Limits = [1 100];
            app.ArenaHzSpinner.RoundFractionalValues = 'on';
            app.ArenaHzSpinner.Position = [311 61 50 26];
            app.ArenaHzSpinner.Value = 50;

            % Create StepperHzSpinnerLabel
            app.StepperHzSpinnerLabel = uilabel(app.UIFigure);
            app.StepperHzSpinnerLabel.HorizontalAlignment = 'right';
            app.StepperHzSpinnerLabel.Position = [229 26 65 22];
            app.StepperHzSpinnerLabel.Text = 'Stepper Hz';

            % Create StepperHzSpinner
            app.StepperHzSpinner = uispinner(app.UIFigure);
            app.StepperHzSpinner.Limits = [1 100];
            app.StepperHzSpinner.RoundFractionalValues = 'on';
            app.StepperHzSpinner.Position = [311 24 50 26];
            app.StepperHzSpinner.Value = 50;

            % Create MsequenceOptionsLabel_2
            app.MsequenceOptionsLabel_2 = uilabel(app.UIFigure);
            app.MsequenceOptionsLabel_2.HorizontalAlignment = 'center';
            app.MsequenceOptionsLabel_2.Position = [237 88 116 22];
            app.MsequenceOptionsLabel_2.Text = 'M-sequence Options';

            % Create ArenaOnlyOptionsLabel
            app.ArenaOnlyOptionsLabel = uilabel(app.UIFigure);
            app.ArenaOnlyOptionsLabel.HorizontalAlignment = 'center';
            app.ArenaOnlyOptionsLabel.Position = [41 291 110 22];
            app.ArenaOnlyOptionsLabel.Text = 'Arena Only Options';

            % Create SetupArenaVoltagesCheckBox
            app.SetupArenaVoltagesCheckBox = uicheckbox(app.UIFigure);
            app.SetupArenaVoltagesCheckBox.Text = 'Setup Arena Voltages';
            app.SetupArenaVoltagesCheckBox.WordWrap = 'on';
            app.SetupArenaVoltagesCheckBox.Position = [101 254 84 26];

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