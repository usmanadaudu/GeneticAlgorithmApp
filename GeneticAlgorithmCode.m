classdef GeneticAlgorithm < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        GeneticAlgorithmUIFigure       matlab.ui.Figure
        OutputFilenameEditFieldLabel   matlab.ui.control.Label
        OutputFilenameEditField        matlab.ui.control.EditField
        OutputFileLocationLabel        matlab.ui.control.Label
        OutputFileLocationEditField    matlab.ui.control.EditField
        GeneticAlgorithmLabel          matlab.ui.control.Label
        GenerateButton                 matlab.ui.control.Button
        BrowseButton                   matlab.ui.control.Button
        NumberofChromosomesLabel       matlab.ui.control.Label
        NumberofChromosomesEditField   matlab.ui.control.NumericEditField
        StringsPerChromosomeLabel      matlab.ui.control.Label
        StringsPerChromosomeEditField  matlab.ui.control.NumericEditField
        BitsPerStringEditFieldLabel    matlab.ui.control.Label
        BitsPerStringEditField         matlab.ui.control.NumericEditField
        FunctionEditFieldLabel         matlab.ui.control.Label
        FunctionEditField              matlab.ui.control.EditField
        TypeofValuesDropDownLabel      matlab.ui.control.Label
        TypeofValuesDropDown           matlab.ui.control.DropDown
        MinMaxLabel                    matlab.ui.control.Label
        MinMaxDropDown                 matlab.ui.control.DropDown
        EvaluationLabel                matlab.ui.control.Label
        PopulationGenerationLabel      matlab.ui.control.Label
        OutputFileLabel                matlab.ui.control.Label
        UseRandomInitialPopulationButton  matlab.ui.control.StateButton
        SetinitialPopulationButton     matlab.ui.control.Button
        DecimalPlacesEditFieldLabel    matlab.ui.control.Label
        DecimalPlacesEditField         matlab.ui.control.NumericEditField
        CrossOverLabel                 matlab.ui.control.Label
        ButtonGroup                    matlab.ui.container.ButtonGroup
        PointButton                    matlab.ui.control.RadioButton
        PointsButton                   matlab.ui.control.RadioButton
        SetRangesDefault010Button      matlab.ui.control.Button
        GenerationLabel                matlab.ui.control.Label
        StopatGenerationLabel          matlab.ui.control.Label
        StopatGenerationEditField      matlab.ui.control.NumericEditField
    end

    properties (Access = private)
        Err =  [0 0 0 1]; % variable for tracking errors
        ChromNumErr = 1;  % index of Err corresponding to no of chromosomes error
        FuncErr = 2;      % index of Err corresponding to function error
        FlNmErr = 3;      % index of Err corresponding to filename error
        FlLcErr = 4;      % index of Err corresponding to file location error
        Rng               % ranges for strings
        LastRng           % last valid user input for ranges 
    end

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)
            
            % Hide the figure while startupFcn executes
            app.GeneticAlgorithmUIFigure.Visible = 'off';
            
            % Track dropdown value with itemsdata
            app.TypeofValuesDropDown.ItemsData =  [1 2];
            
            % Set upper limit of decimal places to number of bits
            bits = app.BitsPerStringEditField.Value;
            app.DecimalPlacesEditField.Limits = [0 bits];
            
            % Set ranges to default 1-10 values
            app.Rng = repmat([0 10],app.StringsPerChromosomeEditField.Value,1);
            
            % Disable setting initial population if population is set to
            % random otherwise enable
            randInitPop = app.UseRandomInitialPopulationButton.Value;
            if randInitPop 
                app.SetinitialPopulationButton.Enable = 0;
            else
                app.SetinitialPopulationButton.Enable = 1;
            end
            
            % Enable setting decimal place if dropdown value is 2 (real)
            % otherwise disable
            if (app.TypeofValuesDropDown.Value == 2)
                app.DecimalPlacesEditField.Enable = 1;
            else
                app.DecimalPlacesEditField.Enable = 0;
            end
            
            % Errorcheck OutputFileLocationEditField
            app.Err(app.FlLcErr) = isempty(app.OutputFileLocationEditField.Value);
            
            %Check for any errors
            if any(app.Err)
                %Disable Generate Button
                app.GenerateButton.Enable = 0;
            else
                %Enable Generate Button
                app.GenerateButton.Enable = 1;
            end
            
            % Center GUI
            movegui(app.GeneticAlgorithmUIFigure,'center')
            
            % Show the figure
            app.GeneticAlgorithmUIFigure.Visible = 'on';
        end

        % Value changed function: NumberofChromosomesEditField
        function NumberofChromosomesEditFieldValueChanged(app, event)
            value = app.NumberofChromosomesEditField.Value;
            
            % If Number of Chromosomes is even raise error otherwise do not
            % raise error
            if mod(value,2) ~= 0
                app.NumberofChromosomesEditField.BackgroundColor = '#EDB120';
                app.Err(app.ChromNumErr) = 1;
            else
                app.NumberofChromosomesEditField.BackgroundColor = '#FFFFFF';
                app.Err(app.ChromNumErr) = 0;
            end
            
            % Disable Generate button if any error was raised
            verifyVals(app, event);
        end

        % Value changed function: BitsPerStringEditField
        function BitsPerStringCheck(app, event)
            value = app.BitsPerStringEditField.Value;
            
            % Set upper limit of decimal places to number of bits
            app.DecimalPlacesEditField.Limits = [0 value];
        end

        % Value changed function: UseRandomInitialPopulationButton
        function UseRandomInitialPopulationButtonCheck(app, event)
            value = app.UseRandomInitialPopulationButton.Value;
            
            % Disable setting initial population if population is set to
            % random otherwise enable
            if value
                app.SetinitialPopulationButton.Enable = 0;
            else
                app.SetinitialPopulationButton.Enable = 1;
            end
        end

        % Value changing function: OutputFilenameEditField
        function OutputFilenameEditFieldValueChanging(app, event)
            changingValue = app.OutputFilenameEditField.Value;
            
            % Get output file location
            loc = app.OutputFileLocationEditField.Value;
            
            % Erroecheck filename
            if (isempty(changingValue))
                app.OutputFilenameEditField.BackgroundColor = '#EDB120';
                app.Err(app.FlNmErr) = 1;
                app.OutputFilenameEditField.Tooltip = 'Filename cannot be empty';
            elseif isfile([loc '\' changingValue '.txt'])     % Check if a file with given name exists in the specified directory
                app.OutputFilenameEditField.BackgroundColor = '#EDB120';
                app.Err(app.FlNmErr) = 1;
                app.OutputFilenameEditField.Tooltip = 'Text file with same name exists in the specified folder';
            else
                app.OutputFilenameEditField.BackgroundColor = '#FFFFFF';
                app.Err(app.FlNmErr) = 0;
                app.OutputFilenameEditField.Tooltip = '';
            end
            
            % Disable Generate button if any error was raised
            verifyVals(app, event);
        end

        % Value changing function: OutputFileLocationEditField
        function OutputFileLocationEditFieldValueChanging(app, event)
            
            % Errorcheck file location
            OutputFileLocationEditFieldValueChanged(app, event);
        end

        % Value changed function: OutputFileLocationEditField
        function OutputFileLocationEditFieldValueChanged(app, event)
            value = app.OutputFileLocationEditField.Value;
            
            % Errorcheck file location
            if isempty(value)
                app.OutputFileLocationEditField.BackgroundColor = '#EDB120';
                app.Err(app.FlLcErr) = 1;
                app.OutputFileLocationEditField.Tooltip = 'File location cannot be empty';
            elseif ~isfolder(value)            % Check if specified location is a valid directory
                app.OutputFileLocationEditField.BackgroundColor = '#EDB120';
                app.Err(app.FlLcErr) = 1;
                app.OutputFileLocationEditField.Tooltip = 'Specified directory could not be found';
            else
                app.OutputFileLocationEditField.BackgroundColor = '#FFFFFF';
                app.Err(app.FlLcErr) = 0;
                app.OutputFileLocationEditField.Tooltip = '';
            end
            
            % Errorcheck output filename
            OutputFilenameEditFieldValueChanging(app, event);
            
            % Disable Generate button if any error was raised
            verifyVals(app, event);
        end

        % Button pushed function: BrowseButton
        function BrowseButtonPushed(app, event)
            
            % displays UI to set directory
            dir = uigetdir('C:\','Select Ouput File Location');
            
            % Set file location to directory if it is not empty
            if dir
                app.OutputFileLocationEditField.Value = dir;
            end
            
            % Errorcheck output filename
            OutputFileLocationEditFieldValueChanged(app, event);
            
            % Errorcheck output file location
            OutputFileLocationEditFieldValueChanged(app, event);
            
            % Disable Generate button if any error was raised
            verifyVals(app, event);
        end

        % Button pushed function: GenerateButton
        function GenerateButtonPushed(app, event)
                        
        end

        % Callback function: GeneticAlgorithmUIFigure, 
        % GeneticAlgorithmUIFigure, GeneticAlgorithmUIFigure
        function verifyVals(app, event)
            
            % Check for errors
            if any(app.Err)
                % Disable Generate Button
                app.GenerateButton.Enable = 0;
            else
                % Enable Generate Button
                app.GenerateButton.Enable = 1;
            end
        end

        % Value changed function: TypeofValuesDropDown
        function TypeofValuesDropDownValueChanged(app, event)
            value = app.TypeofValuesDropDown.Value;
            
            % Enable setting decimal place if dropdown value is 2 (real)
            % otherwise disable
            if (value == 2)
                app.DecimalPlacesEditField.Enable = 1;
            else
                app.DecimalPlacesEditField.Enable = 0;
            end
        end

        % Button pushed function: SetRangesDefault010Button
        function SetRangesDefault010ButtonPushed(app, event)
            
            % Get number of strings
            strNum = app.StringsPerChromosomeEditField.Value;
            
            % If ranges is not set use default values
            if isempty(app.Rng)
                app.Rng = repmat([1 10],strNum,1);
            end
            
            % If there are no last valid values use default values
            if isempty(app.LastRng)
                app.LastRng = repmat([1 10],strNum,1);
            end
            
            % Variable for tracking error in this function
            valErr = 0;
            
            % create UI figure (uf) to set ranges but do not show till setup finishes
            uf = uifigure('Name','Ranges','Position',[100 100 560 420], ...
                'Scrollable','on','DeleteFcn',@(uf,event) ufDeleteFcn(), ...
                'CloseRequestFcn',@(uf,event) ufCloseFcn(),'Visible','off');
            
            % Set each line (range) in ranges as a string in cell array cellA
            cellA = ACell();
            
            % Input instruction
            labelmsg = sprintf("Input values in each row for the respective strings."+...
                "\nFormat: min max");
            uilabel(uf,'Position',[56 356 448 28],'Text',labelmsg);
            
            % User input values area
            input = uitextarea(uf,'Position',[56 42 224 294],...
                'Value',cellA);
            
            % Default Values button
            uibutton(uf,'push','Text','Use Default Values',....
                'Position',[336 272 168 22],...
                'ButtonPushedFcn',@(btn,event) ResetVal(1));
            
            % Use Last Valid Values button
            uibutton(uf,'push','Text','Use Last Valid Values',...
                'Position',[336 178 168 22],...
                'ButtonPushedFcn',@(btn,event) ResetVal(2));
            
            % Set Current Values button
            uibutton(uf,'push','Text','Set Current Values',...
                'Position',[336 84 168 22],'BackgroundColor','#4DBEEE',...
                'ButtonPushedFcn',@(btn,event) checkVal());
            
            % Center GUI for setting ranges
            movegui(uf,'center')
            
            % Hide base GUI
            % When I get a later version of MATLAB using modal should be
            % better than hiding the figure
            app.GeneticAlgorithmUIFigure.Visible = 'off';
            
            % Show GUI for setting ranges
            uf.Visible = 'on';
            
            function cellA = ACell
                %This function stores each set of ranges in app.Rng as a
                %string in the output cell array (cellA)
                cellA = cell(size(app.Rng,1),1);
                for row = 1:length(cellA)
                    cellA{row} = num2str(app.Rng(row,:));
                end
            end
            
            function ufDeleteFcn()
                % This function shows the base GUI when the GUI for ranges
                % is being deleted
                
                % Using modal for this second uifigure should be better but
                % modal is not available in MATLAB R2019b. I want to update
                % this part when I get a later version of MATLAB
                app.GeneticAlgorithmUIFigure.Visible = 'on';
            end
            
            function ufCloseFcn()
                % This function shows the base GUI when the GUI for ranges
                % has been deleted
                
                % Using modal for this second uifigure should be better but
                % modal is not available in MATLAB R2019b. I want to update
                % this part when I get a later version of MATLAB
                delete(uf);
                app.GeneticAlgorithmUIFigure.Visible = 'on';
            end
            
            function ResetVal(val)
                % This function sets the values of the ranges as the
                % default value if val is 1 or to the last valid values
                % if val is 2
                value = app.StringsPerChromosomeEditField.Value;
                if val == 1
                    app.Rng = repmat([0 10],strNum,1);
                elseif val == 2
                    if size(app.LastRng,1) < value
                        app.Rng = [app.LastRng; repmat([0 10],value-size(app.LastRng,1),1)];
                    elseif size(app.LastRng,1) > value
                        app.Rng = app.LastRng(1:value,:);
                    else
                        app.Rng = app.LastRng;
                    end
                end
                
                % Save the ranges in a cell array
                cellA = ACell();
                
                % Output the ranges in the GUI for ranges
                input.Value = cellA;
                input.BackgroundColor = '#fff';
            end
            
            function checkVal
                
                % If number of rows in input is not equal to number of strings
                % raise error otherwise continue to else
                if size(input.Value,1) ~= strNum
                    uialert(uf,'There are '+string(size(input.Value,1))+...
                        ' sets of values. There should be '+string(strNum)+...
                        ' sets of ranges','Error')
                    input.BackgroundColor = '#EDB120';
                else
                    % Empty 2-column cell array with rows equal to length
                    % of input values
                    cellAScan = cell(size(input.Value,1),2);
                    
                    % Error check each line of input. If any error track
                    % with valErr
                    for i = 1:size(input.Value,1)
                        % expr is a regular expression to check if each
                        % line of input contains exactly two numbers
                        % separated by one or more space characters
                        expr = '([-]*[\d]+\.[\d]*|(?:[-]*[\d]*)?[.]?[\d]+)[ ]+([-]*[\d]+\.[\d]*|(?:[-]*[\d]*)?[.]?[\d]+)';
                        
                        % Remove leading and trailing spaces then check if current line matches expr
                        [start,last] = regexp(strip(input.Value{i}),expr);
                        
                        if isempty(start) && isempty(last)        % current line does not match expr
                            alertmsg{2,1} = 'min and max should be integers separated by space';
                            alertmsg{1,1} = 'Input format: min max';
                            uialert(uf,alertmsg,'Error')
                            valErr = 1;
                            input.BackgroundColor = '#EDB120';
                            break
                        elseif (start == 1 && last == length(strip(input.Value{i})))        % current line matches expr exactly
                            % capture the two numbers into respective columns in cellAScan
                            cellAScan(i,:) = textscan(input.Value{i},'%f %f');
                            
                            if ~(cellAScan{i,1} <= cellAScan{i,2}) % first number (min) is greater than the second number (max)
                                alertmsg = 'Each min should not be greater than the respective max';
                                uialert(uf,alertmsg,'Error')
                                valErr = 1;
                                input.BackgroundColor = '#EDB120';
                                break
                            else % first number (min) is lesser than or equal to the second number (max)
                                valErr = 0;
                                input.BackgroundColor = '#fff';
                            end
                        else % current line matches expr partly
                            alertmsg{2,1} = 'min and max should be two integers separated by space';
                            alertmsg{1,1} = 'Input format: min max';
                            uialert(uf,alertmsg,'Error')
                            valErr = 1;
                            input.BackgroundColor = '#EDB120';
                            break
                        end
                    end
                    
                    if ~valErr % if no error occurs
                        app.Rng = cell2mat(cellAScan); % update the values of the ranges (app.Rng)
                        final();
                    end
                end
            end
            function final
                input.BackgroundColor = '#fff';
                
                % If current value for ranges is not the default values
                % update app.LastRng to the current values of ranges
                if ~isequal(app.Rng,repmat([0 10],strNum,1))
                    app.LastRng = app.Rng;
                end
                
                % Close figure for setting ranges
                close(uf);
            end
        end

        % Value changed function: StringsPerChromosomeEditField
        function StringsPerChromosomeEditFieldValueChanged(app, event)
            value = app.StringsPerChromosomeEditField.Value;
            
            % If set of ranges is lesser than number of strings pad app.Rng with default values to the length (rows) equal to number of strings
            % else if set of ranges is greater than number of strings trim app.Rng to make length (rows) equal to number of strings
            if size(app.Rng,1) < value
                app.Rng = [app.Rng; repmat([1 10],value-size(app.Rng,1),1)];
            elseif size(app.Rng,1) > value 
                app.Rng = app.Rng(1:value,:);
            end
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create GeneticAlgorithmUIFigure and hide until all components are created
            app.GeneticAlgorithmUIFigure = uifigure('Visible', 'off');
            app.GeneticAlgorithmUIFigure.Position = [100 100 640 590];
            app.GeneticAlgorithmUIFigure.Name = 'Genetic Algorithm';
            app.GeneticAlgorithmUIFigure.WindowButtonUpFcn = createCallbackFcn(app, @verifyVals, true);
            app.GeneticAlgorithmUIFigure.WindowButtonMotionFcn = createCallbackFcn(app, @verifyVals, true);
            app.GeneticAlgorithmUIFigure.KeyReleaseFcn = createCallbackFcn(app, @verifyVals, true);
            app.GeneticAlgorithmUIFigure.Scrollable = 'on';

            % Create OutputFilenameEditFieldLabel
            app.OutputFilenameEditFieldLabel = uilabel(app.GeneticAlgorithmUIFigure);
            app.OutputFilenameEditFieldLabel.Position = [44 104 124 22];
            app.OutputFilenameEditFieldLabel.Text = 'Output Filename:';

            % Create OutputFilenameEditField
            app.OutputFilenameEditField = uieditfield(app.GeneticAlgorithmUIFigure, 'text');
            app.OutputFilenameEditField.ValueChangingFcn = createCallbackFcn(app, @OutputFilenameEditFieldValueChanging, true);
            app.OutputFilenameEditField.Position = [181 104 303 22];
            app.OutputFilenameEditField.Value = 'GeneticAlgorithm';

            % Create OutputFileLocationLabel
            app.OutputFileLocationLabel = uilabel(app.GeneticAlgorithmUIFigure);
            app.OutputFileLocationLabel.Position = [44 74 124 22];
            app.OutputFileLocationLabel.Text = 'Output File Location:';

            % Create OutputFileLocationEditField
            app.OutputFileLocationEditField = uieditfield(app.GeneticAlgorithmUIFigure, 'text');
            app.OutputFileLocationEditField.ValueChangedFcn = createCallbackFcn(app, @OutputFileLocationEditFieldValueChanged, true);
            app.OutputFileLocationEditField.ValueChangingFcn = createCallbackFcn(app, @OutputFileLocationEditFieldValueChanging, true);
            app.OutputFileLocationEditField.Tooltip = {''};
            app.OutputFileLocationEditField.Position = [181 74 303 22];

            % Create GeneticAlgorithmLabel
            app.GeneticAlgorithmLabel = uilabel(app.GeneticAlgorithmUIFigure);
            app.GeneticAlgorithmLabel.HorizontalAlignment = 'center';
            app.GeneticAlgorithmLabel.FontName = 'Agency FB';
            app.GeneticAlgorithmLabel.FontSize = 20;
            app.GeneticAlgorithmLabel.FontWeight = 'bold';
            app.GeneticAlgorithmLabel.Position = [1 559 640 27];
            app.GeneticAlgorithmLabel.Text = 'Genetic Algorithm';

            % Create GenerateButton
            app.GenerateButton = uibutton(app.GeneticAlgorithmUIFigure, 'push');
            app.GenerateButton.ButtonPushedFcn = createCallbackFcn(app, @GenerateButtonPushed, true);
            app.GenerateButton.BackgroundColor = [0.302 0.7451 0.9333];
            app.GenerateButton.FontColor = [0.9412 0.9412 0.9412];
            app.GenerateButton.Position = [497 19 100 22];
            app.GenerateButton.Text = 'Generate';

            % Create BrowseButton
            app.BrowseButton = uibutton(app.GeneticAlgorithmUIFigure, 'push');
            app.BrowseButton.ButtonPushedFcn = createCallbackFcn(app, @BrowseButtonPushed, true);
            app.BrowseButton.Position = [497 74 100 22];
            app.BrowseButton.Text = 'Browse...';

            % Create NumberofChromosomesLabel
            app.NumberofChromosomesLabel = uilabel(app.GeneticAlgorithmUIFigure);
            app.NumberofChromosomesLabel.Position = [378 494 151 22];
            app.NumberofChromosomesLabel.Text = 'Number of Chromosomes:';

            % Create NumberofChromosomesEditField
            app.NumberofChromosomesEditField = uieditfield(app.GeneticAlgorithmUIFigure, 'numeric');
            app.NumberofChromosomesEditField.LowerLimitInclusive = 'off';
            app.NumberofChromosomesEditField.UpperLimitInclusive = 'off';
            app.NumberofChromosomesEditField.Limits = [0 Inf];
            app.NumberofChromosomesEditField.RoundFractionalValues = 'on';
            app.NumberofChromosomesEditField.ValueDisplayFormat = '%.0f';
            app.NumberofChromosomesEditField.ValueChangedFcn = createCallbackFcn(app, @NumberofChromosomesEditFieldValueChanged, true);
            app.NumberofChromosomesEditField.Tooltip = {'Value must be an even number'};
            app.NumberofChromosomesEditField.Position = [539 494 43 22];
            app.NumberofChromosomesEditField.Value = 10;

            % Create StringsPerChromosomeLabel
            app.StringsPerChromosomeLabel = uilabel(app.GeneticAlgorithmUIFigure);
            app.StringsPerChromosomeLabel.Position = [44 448 150 22];
            app.StringsPerChromosomeLabel.Text = 'Strings Per Chromosome:';

            % Create StringsPerChromosomeEditField
            app.StringsPerChromosomeEditField = uieditfield(app.GeneticAlgorithmUIFigure, 'numeric');
            app.StringsPerChromosomeEditField.LowerLimitInclusive = 'off';
            app.StringsPerChromosomeEditField.UpperLimitInclusive = 'off';
            app.StringsPerChromosomeEditField.Limits = [0 Inf];
            app.StringsPerChromosomeEditField.RoundFractionalValues = 'on';
            app.StringsPerChromosomeEditField.ValueDisplayFormat = '%.0f';
            app.StringsPerChromosomeEditField.ValueChangedFcn = createCallbackFcn(app, @StringsPerChromosomeEditFieldValueChanged, true);
            app.StringsPerChromosomeEditField.Tooltip = {'New ranges would be added or excess ranges removed if the current set of ranges is less or more than this value'};
            app.StringsPerChromosomeEditField.Position = [203 448 60 22];
            app.StringsPerChromosomeEditField.Value = 5;

            % Create BitsPerStringEditFieldLabel
            app.BitsPerStringEditFieldLabel = uilabel(app.GeneticAlgorithmUIFigure);
            app.BitsPerStringEditFieldLabel.Position = [378 448 151 22];
            app.BitsPerStringEditFieldLabel.Text = 'Bits Per String:';

            % Create BitsPerStringEditField
            app.BitsPerStringEditField = uieditfield(app.GeneticAlgorithmUIFigure, 'numeric');
            app.BitsPerStringEditField.LowerLimitInclusive = 'off';
            app.BitsPerStringEditField.UpperLimitInclusive = 'off';
            app.BitsPerStringEditField.Limits = [0 Inf];
            app.BitsPerStringEditField.RoundFractionalValues = 'on';
            app.BitsPerStringEditField.ValueDisplayFormat = '%.0f';
            app.BitsPerStringEditField.ValueChangedFcn = createCallbackFcn(app, @BitsPerStringCheck, true);
            app.BitsPerStringEditField.Position = [539 448 43 22];
            app.BitsPerStringEditField.Value = 7;

            % Create FunctionEditFieldLabel
            app.FunctionEditFieldLabel = uilabel(app.GeneticAlgorithmUIFigure);
            app.FunctionEditFieldLabel.HorizontalAlignment = 'right';
            app.FunctionEditFieldLabel.Position = [219 281 60 22];
            app.FunctionEditFieldLabel.Text = 'Function:';

            % Create FunctionEditField
            app.FunctionEditField = uieditfield(app.GeneticAlgorithmUIFigure, 'text');
            app.FunctionEditField.Position = [293 281 289 22];

            % Create TypeofValuesDropDownLabel
            app.TypeofValuesDropDownLabel = uilabel(app.GeneticAlgorithmUIFigure);
            app.TypeofValuesDropDownLabel.Position = [44 494 84 22];
            app.TypeofValuesDropDownLabel.Text = 'Type of Values';

            % Create TypeofValuesDropDown
            app.TypeofValuesDropDown = uidropdown(app.GeneticAlgorithmUIFigure);
            app.TypeofValuesDropDown.Items = {'Binary', 'Real'};
            app.TypeofValuesDropDown.ValueChangedFcn = createCallbackFcn(app, @TypeofValuesDropDownValueChanged, true);
            app.TypeofValuesDropDown.BackgroundColor = [1 1 1];
            app.TypeofValuesDropDown.Position = [133 494 130 22];
            app.TypeofValuesDropDown.Value = 'Binary';

            % Create MinMaxLabel
            app.MinMaxLabel = uilabel(app.GeneticAlgorithmUIFigure);
            app.MinMaxLabel.Position = [44 281 54 22];
            app.MinMaxLabel.Text = 'Min/Max:';

            % Create MinMaxDropDown
            app.MinMaxDropDown = uidropdown(app.GeneticAlgorithmUIFigure);
            app.MinMaxDropDown.Items = {'Min', 'Max'};
            app.MinMaxDropDown.BackgroundColor = [1 1 1];
            app.MinMaxDropDown.Position = [109 281 67 22];
            app.MinMaxDropDown.Value = 'Min';

            % Create EvaluationLabel
            app.EvaluationLabel = uilabel(app.GeneticAlgorithmUIFigure);
            app.EvaluationLabel.HorizontalAlignment = 'center';
            app.EvaluationLabel.Position = [1 313 640 22];
            app.EvaluationLabel.Text = 'Evaluation';

            % Create PopulationGenerationLabel
            app.PopulationGenerationLabel = uilabel(app.GeneticAlgorithmUIFigure);
            app.PopulationGenerationLabel.HorizontalAlignment = 'center';
            app.PopulationGenerationLabel.Position = [1 525 640 22];
            app.PopulationGenerationLabel.Text = 'Population Generation';

            % Create OutputFileLabel
            app.OutputFileLabel = uilabel(app.GeneticAlgorithmUIFigure);
            app.OutputFileLabel.HorizontalAlignment = 'center';
            app.OutputFileLabel.Position = [1 131 640 22];
            app.OutputFileLabel.Text = 'Output File';

            % Create UseRandomInitialPopulationButton
            app.UseRandomInitialPopulationButton = uibutton(app.GeneticAlgorithmUIFigure, 'state');
            app.UseRandomInitialPopulationButton.ValueChangedFcn = createCallbackFcn(app, @UseRandomInitialPopulationButtonCheck, true);
            app.UseRandomInitialPopulationButton.Text = 'Use Random Initial Population';
            app.UseRandomInitialPopulationButton.Position = [378 354 204 22];
            app.UseRandomInitialPopulationButton.Value = true;

            % Create SetinitialPopulationButton
            app.SetinitialPopulationButton = uibutton(app.GeneticAlgorithmUIFigure, 'push');
            app.SetinitialPopulationButton.BackgroundColor = [1 1 1];
            app.SetinitialPopulationButton.Position = [44 354 219 22];
            app.SetinitialPopulationButton.Text = 'Set initial Population';

            % Create DecimalPlacesEditFieldLabel
            app.DecimalPlacesEditFieldLabel = uilabel(app.GeneticAlgorithmUIFigure);
            app.DecimalPlacesEditFieldLabel.Position = [378 399 151 22];
            app.DecimalPlacesEditFieldLabel.Text = 'Decimal Places:';

            % Create DecimalPlacesEditField
            app.DecimalPlacesEditField = uieditfield(app.GeneticAlgorithmUIFigure, 'numeric');
            app.DecimalPlacesEditField.Limits = [0 Inf];
            app.DecimalPlacesEditField.RoundFractionalValues = 'on';
            app.DecimalPlacesEditField.ValueDisplayFormat = '%.0f';
            app.DecimalPlacesEditField.Tooltip = {'Value must not be more than bits per string'};
            app.DecimalPlacesEditField.Position = [539 399 43 22];

            % Create CrossOverLabel
            app.CrossOverLabel = uilabel(app.GeneticAlgorithmUIFigure);
            app.CrossOverLabel.HorizontalAlignment = 'center';
            app.CrossOverLabel.Position = [1 238 640 22];
            app.CrossOverLabel.Text = 'Cross-Over';

            % Create ButtonGroup
            app.ButtonGroup = uibuttongroup(app.GeneticAlgorithmUIFigure);
            app.ButtonGroup.BorderType = 'none';
            app.ButtonGroup.TitlePosition = 'centertop';
            app.ButtonGroup.Position = [1 209 640 30];

            % Create PointButton
            app.PointButton = uiradiobutton(app.ButtonGroup);
            app.PointButton.Text = '1 Point';
            app.PointButton.Position = [200 9 60 22];
            app.PointButton.Value = true;

            % Create PointsButton
            app.PointsButton = uiradiobutton(app.ButtonGroup);
            app.PointsButton.Text = '2 Points';
            app.PointsButton.Position = [375 9 66 22];

            % Create SetRangesDefault010Button
            app.SetRangesDefault010Button = uibutton(app.GeneticAlgorithmUIFigure, 'push');
            app.SetRangesDefault010Button.ButtonPushedFcn = createCallbackFcn(app, @SetRangesDefault010ButtonPushed, true);
            app.SetRangesDefault010Button.BackgroundColor = [1 1 1];
            app.SetRangesDefault010Button.Position = [44 399 219 22];
            app.SetRangesDefault010Button.Text = 'Set Ranges (Default 0-10)';

            % Create GenerationLabel
            app.GenerationLabel = uilabel(app.GeneticAlgorithmUIFigure);
            app.GenerationLabel.HorizontalAlignment = 'center';
            app.GenerationLabel.Position = [1 184 640 22];
            app.GenerationLabel.Text = 'Generation';

            % Create StopatGenerationLabel
            app.StopatGenerationLabel = uilabel(app.GeneticAlgorithmUIFigure);
            app.StopatGenerationLabel.Position = [44 163 150 22];
            app.StopatGenerationLabel.Text = 'Stop at Generation:';

            % Create StopatGenerationEditField
            app.StopatGenerationEditField = uieditfield(app.GeneticAlgorithmUIFigure, 'numeric');
            app.StopatGenerationEditField.UpperLimitInclusive = 'off';
            app.StopatGenerationEditField.Limits = [0 Inf];
            app.StopatGenerationEditField.RoundFractionalValues = 'on';
            app.StopatGenerationEditField.ValueDisplayFormat = '%.0f';
            app.StopatGenerationEditField.Position = [203 163 60 22];
            app.StopatGenerationEditField.Value = 10;

            % Show the figure after all components are created
            app.GeneticAlgorithmUIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = GeneticAlgorithm

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.GeneticAlgorithmUIFigure)

            % Execute the startup function
            runStartupFcn(app, @startupFcn)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.GeneticAlgorithmUIFigure)
        end
    end
end