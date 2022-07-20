classdef GeneticAlgorithmCode < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        GeneticAlgorithmUIFigure       matlab.ui.Figure
        GeneticAlgorithmLabel          matlab.ui.control.Label
        GenerateButton                 matlab.ui.control.Button
        PopulationSizeLabel            matlab.ui.control.Label
        PopulationSizeEditField        matlab.ui.control.NumericEditField
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
        SetinitialPopulationButton     matlab.ui.control.Button
        DecimalPlacesEditFieldLabel    matlab.ui.control.Label
        DecimalPlacesEditField         matlab.ui.control.NumericEditField
        CrossOverLabel                 matlab.ui.control.Label
        ButtonGroup                    matlab.ui.container.ButtonGroup
        PointButton                    matlab.ui.control.RadioButton
        PointsButton                   matlab.ui.control.RadioButton
        SetRangesButton                matlab.ui.control.Button
        GenerationLabel                matlab.ui.control.Label
        StopatGenerationLabel          matlab.ui.control.Label
        StopatGenerationEditField      matlab.ui.control.NumericEditField
        SelectionLabel                 matlab.ui.control.Label
        ButtonGroup_2                  matlab.ui.container.ButtonGroup
        RolletteWheelButton            matlab.ui.control.RadioButton
        ElitismButton                  matlab.ui.control.RadioButton
        GeneralProbabilitiesLabel      matlab.ui.control.Label
        CrossOverProbabilityEditFieldLabel  matlab.ui.control.Label
        CrossOverProbabilityEditField  matlab.ui.control.NumericEditField
        MutationProbabilityEditFieldLabel  matlab.ui.control.Label
        MutationProbabilityEditField   matlab.ui.control.NumericEditField
    end

    properties (Access = private)
        Err =  [0 1 1 1]; % Variable for tracking errors
        ChromNumErr = 1;  % Index of Err corresponding to no of chromosomes error
        RngErr = 2;       % Index of Err corresponding to Range error
        PopErr = 3;       % Index of Err corresponding to Population error
        FuncErr = 4;      % Index of Err corresponding to function error
        Rng               % Ranges for strings
        LastRng           % Last valid user input for ranges 
        Pop = "";         % Population
        LastPop = "";     % Last valid population
    end
    
    methods (Access = private)
        
        function cellA = ACell(app)
            %This function stores each set of ranges in app.Rng as a
            %string in the output cell array (cellA)
            cellA = cell(size(app.Rng,1),1);
            for row = 1:length(cellA)
                cellA{row} = num2str(app.Rng(row,:));
            end
        end
        
        function ResetRngVal(app,val,input)
            % This function sets the values of the ranges as the
            % default value if val is 1 or to the last valid values
            % if val is 2
            value = app.StringsPerChromosomeEditField.Value;
            if val == 1
                if (app.TypeofValuesDropDown.Value == 1)
                    app.Rng = repmat([0 10],strNum,1);
                else
                    app.Rng = repmat([0 (10^app.BitsPerStringEditField.Value-1)*10^-app.DecimalPlacesEditField.Value],...
                        strNum,1);
                end
            elseif val == 2
                if size(app.LastRng,1) < value
                    if (app.TypeofValuesDropDown.Value == 1)
                        app.Rng = [app.LastRng; repmat([0 10],value-size(app.LastRng,1),1)];
                    else
                        app.Rng = [app.LastRng; repmat([0 (10^app.BitsPerStringEditField.Value-1)*...
                        10^-app.DecimalPlacesEditField.Value],value-size(app.LastRng,1),1)];
                    end
                elseif size(app.LastRng,1) > value
                    app.Rng = app.LastRng(1:value,:);
                else
                    app.Rng = app.LastRng;
                end
            end
            
            % Save the ranges in a cell array
            cellA = app.ACell();
            
            % Output the ranges in the GUI for ranges and make
            % background white
            input.Value = cellA;
            input.BackgroundColor = '#fff';
        end
        
        function checkRngVal(app,input)
            
            strNum = app.StringsPerChromosomeEditField.Value;
                
            % If input is empty or number of rows is not equal to
            % number of strings raise error otherwise continue to else
            if string(input.Value) == ""
                uialert(uf,'There are no values. There should be '+...
                    string(strNum)+' sets of ranges','Error')
                input.BackgroundColor = '#EDB120';
            elseif size(input.Value,1) ~= strNum
                uialert(uf,'There are '+string(size(input.Value,1))+...
                    ' sets of values. There should be '+string(strNum)+...
                    ' sets of ranges','Error')
                input.BackgroundColor = '#EDB120';
            else
                % Empty 2-column cell array with rows equal to length
                % of input values
                cellAScan = cell(size(input.Value,1),2);
                
                % expr is a regular expression to check if each line of
                % input contains exactly two numbers separated by one
                % or more space characters
                expr = '([-]*[\d]+\.[\d]*|(?:[-]*[\d]*)?[.]?[\d]+)[ ]+([-]*[\d]+\.[\d]*|(?:[-]*[\d]*)?[.]?[\d]+)';
                
                % Error check each line of input. If any error track
                % with valErr
                for i = 1:size(input.Value,1)
                                            
                    % Remove leading and trailing spaces then check if current line matches expr
                    [start,last] = regexp(strip(input.Value{i}),expr,'once');
                    
                    if isempty(start) && isempty(last)        % current line does not match expr
                        alertmsg{2,1} = 'min and max should be integers separated by space';
                        alertmsg{1,1} = 'Input format: min max';
                        uialert(uf,alertmsg,'Error')
                        valErr = 1;
                        input.BackgroundColor = '#EDB120';
                        break
                    elseif (start(1) == 1 && last(end) == length(strip(input.Value{i})))        % current line matches expr exactly
                        % capture the two numbers into respective columns in cellAScan
                        cellAScan(i,:) = textscan(input.Value{i},'%f %f');
                        
                        if ~(cellAScan{i,1} <= cellAScan{i,2}) % first number (min) is greater than the second number (max)
                            alertmsg = 'Each min should not be greater than the respective max';
                            uialert(uf,alertmsg,'Error')
                            valErr = 1;
                            input.BackgroundColor = '#EDB120';
                            break
                        elseif (app.TypeofValuesDropDown.Value == 2 && cellAScan{i,1}<0)
                            format long
                            alertmsg = 'Each min should not be lesser than zero';
                            uialert(uf,alertmsg,'Error')
                            valErr = 1;
                            input.BackgroundColor = '#EDB120';
                            break
                        elseif (app.TypeofValuesDropDown.Value == 2 ...
                                && cellAScan{i,2}>(10^app.BitsPerStringEditField.Value-1)*10^-app.DecimalPlacesEditField.Value)
                            format long
                            alertmsg = "Each max should not be greater than "+string((10^app.BitsPerStringEditField.Value-1)*10^-app.DecimalPlacesEditField.Value);
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
                    % update the values of the ranges (app.Rng)
                    app.Rng = cell2mat(cellAScan);
                    
                    % change the button background to white
                    app.SetRangesButton.BackgroundColor = '#fff';
                    
                    % discard Range Error if raised
                    app.Err(app.RngErr) = 0;
                    
                    input.BackgroundColor = '#fff';
                
                    % If current value for ranges is not the default values
                    % update app.LastRng to the current values of ranges
                    if ~isequal(app.Rng,repmat([0 10],strNum,1))
                        app.LastRng = app.Rng;
                    end
                    
                    %Check for any errors if any disable Generate button
                    app.checkErr();
                    
                    % Remove the * in the button text
                    app.SetRangesButton.Text = "Set Ranges";
                    
                    % Close figure for setting ranges
                    close(uf);
                end
            end
        end
        
        function rngUfDeleteFcn(app)
            % This function shows the base GUI when the GUI for ranges
            % is being deleted
            
            % Using modal for this second uifigure should be better but
            % modal is not available in MATLAB R2019b. I want to update
            % this part when I get a later version of MATLAB
            app.GeneticAlgorithmUIFigure.Visible = 'on';
        end
        
        function rngUfCloseFcn(app,uf)
            % This function shows the base GUI when the GUI for ranges
            % has been deleted
            
            % Using modal for this second uifigure should be better but
            % modal is not available in MATLAB R2019b. I want to update
            % this part when I get a later version of MATLAB
            delete(uf);
            app.GeneticAlgorithmUIFigure.Visible = 'on';
        end
        
        function RngPopErr(app)
            
            % Raise error for Range
            app.SetRangesButton.BackgroundColor = '#EDB120';
            app.Err(app.RngErr) = 1;
            
            % Raise error for Population
            app.SetinitialPopulationButton.BackgroundColor = '#EDB120';
            app.Err(app.PopErr) = 1;
        end
        
        function checkErr(app)
            
            % Check for errors
            if any(app.Err)
                % Disable Generate Button
                app.GenerateButton.Enable = 0;
            else
                % Enable Generate Button
                app.GenerateButton.Enable = 1;
            end
        end
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
            
            % Enable setting decimal place if dropdown value is 2 (real)
            % otherwise disable
            if (app.TypeofValuesDropDown.Value == 2)
                app.DecimalPlacesEditField.Enable = 1;
            else
                app.DecimalPlacesEditField.Enable = 0;
            end
            
            % Set ranges to default 0-10 values
            if (app.TypeofValuesDropDown.Value == 1)
                app.Rng = repmat([0 10],app.StringsPerChromosomeEditField.Value,1);
            else
                app.Rng = repmat([0 (10^app.BitsPerStringEditField.Value-1)*10^-app.DecimalPlacesEditField.Value],...
                    app.StringsPerChromosomeEditField.Value,1);
            end
            
            % Raise error for Range and Population so that user will have
            % to set it
            % app.RngPopErr();
            
            % Track minMax value with itemsdata
            app.MinMaxDropDown.ItemsData =  [1 2];
            
            % Set tooltip for function
            app.FunctionEditField.Tooltip = "Variables: x1-x"+...
                string(app.StringsPerChromosomeEditField.Value)+". Operators:  +-*/^";
            
            %Check for any errors if any disable Generate button
            app.checkErr();
            
            % Center GUI
            movegui(app.GeneticAlgorithmUIFigure,'center');
            
            % Show the figure
            app.GeneticAlgorithmUIFigure.Visible = 'on';
        end

        % Callback function
        function GeneticAlgorithmUIFigureSizeChanged(app, event)
            position = app.GeneticAlgorithmUIFigure.Position;
            if position(3) > 640
                for i = 1:length(app.Right)
                    app.Right(i).Position(3) = app.RightHorPos(i,2)*position(3)/640;
                end
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
            
            % Erase Ranges
            app.Rng = [];
            
            % Erase Population
            app.Pop = string;
            
            % Raise error for Range and Population so that user will have
            % to set or cross-check it
            RngPopErr(app);
            
            % Disable Generate button if any error was raised
            app.checkErr();
        end

        % Value changed function: PopulationSizeEditField
        function PopulationSizeEditFieldValueChanged(app, event)
            value = app.PopulationSizeEditField.Value;
            
            % If Number of Chromosomes is even raise error otherwise do not
            % raise error
            if mod(value,2) ~= 0
                app.PopulationSizeEditField.BackgroundColor = '#EDB120';
                app.Err(app.ChromNumErr) = 1;
            else
                app.PopulationSizeEditField.BackgroundColor = '#FFFFFF';
                app.Err(app.ChromNumErr) = 0;
            end
            
            % Erase Population
            app.Pop = string;
            
            % Raise error for Population so that user will have to set or
            % cross-check it
            app.SetinitialPopulationButton.BackgroundColor = '#EDB120';
            app.Err(app.PopErr) = 1;
            
            % Disable Generate button if any error was raised
            app.checkErr();
        end

        % Value changed function: StringsPerChromosomeEditField
        function StringsPerChromosomeEditFieldValueChanged(app, event)
            value = app.StringsPerChromosomeEditField.Value;
            
            % If set of ranges is lesser than number of strings pad app.Rng
            % with default values to the length (rows) equal to number of strings
            % else if set of ranges is greater than number of strings trim
            % app.Rng to make length (rows) equal to number of strings
            if size(app.Rng,1) < value
                app.Rng = [app.Rng; repmat([0 10],value-size(app.Rng,1),1)];
            elseif size(app.Rng,1) > value 
                app.Rng = app.Rng(1:value,:);
            end
            
            % Erase Ranges
            app.Rng = [];
            
            % Erase Population
            app.Pop = string;
            
            % Raise error for Range and Population so that user will have
            % to set or cross-check it
            app.RngPopErr();
            
            % Set tooltip for function
            app.FunctionEditField.Tooltip = "Variables: x1-x"+...
                string(app.StringsPerChromosomeEditField.Value)+". Operators:  +-*/^";
            
            % Error-check the function
            FunctionEditFieldValueChanged(app, event);
            
            % Disable Generate button if any error was raised
            app.checkErr();
        end

        % Value changed function: BitsPerStringEditField
        function BitsPerStringCheck(app, event)
            value = app.BitsPerStringEditField.Value;
            
            % Set upper limit of decimal places to number of bits
            app.DecimalPlacesEditField.Limits = [0 value];
            
            % Erase Population
            app.Pop = string;
            
            % Raise error for Population so that user will have to set or
            % cross-check it
            app.SetinitialPopulationButton.BackgroundColor = '#EDB120';
            app.Err(app.PopErr) = 1;
            
            % Disable Generate button if any error was raised
            app.checkErr();
        end

        % Value changed function: DecimalPlacesEditField
        function DecimalPlacesEditFieldValueChanged(app, event)
            % Raise error for Range and Population so that user will have
            % to set or cross-check it
            app.RngPopErr();
        end

        % Button pushed function: SetRangesButton
        function SetRangesButtonPushed(app, event)
            
            % Get number of strings
            strNum = app.StringsPerChromosomeEditField.Value;
            
            % If ranges is not set use default values
            if isempty(app.Rng)
                if (app.TypeofValuesDropDown.Value == 1)
                    app.Rng = repmat([0 10],strNum,1);
                else
                    app.Rng = repmat([0 (10^app.BitsPerStringEditField.Value-1)*10^-app.DecimalPlacesEditField.Value],...
                        strNum,1);
                end
            end
            
            % If there are no last valid values use default values
            if isempty(app.LastRng)
                if (app.TypeofValuesDropDown.Value == 1)
                    app.LastRng = repmat([0 10],strNum,1);
                else
                    app.LastRng = repmat([0 (10^app.BitsPerStringEditField.Value-1)*10^-app.DecimalPlacesEditField.Value],...
                        strNum,1);
                end
            end
            
            % Variable for tracking error in this function
            %valErr = 0;
            
            % create UI figure (uf) to set ranges but do not show till setup finishes
            uf = uifigure('Name','Ranges','Position',[100 100 560 420], ...
                'Scrollable','on','DeleteFcn',@(uf,event) app.rngUfDeleteFcn(), ...
                'CloseRequestFcn',@(uf,event) app.rngUfCloseFcn(uf),'Visible','off');
            
            % Set each line (range) in ranges as a string in cell array cellA
            cellA = app.ACell();
            
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
                'ButtonPushedFcn',@(btn,event) app.ResetRngVal(1,input));
            
            % Use Last Valid Values button
            uibutton(uf,'push','Text','Use Last Valid Values',...
                'Position',[336 178 168 22],...
                'ButtonPushedFcn',@(btn,event) app.ResetRngVal(2,input));
            
            % Set Current Values button
            uibutton(uf,'push','Text','Set Current Values',...
                'Position',[336 84 168 22],'BackgroundColor','#4DBEEE',...
                'ButtonPushedFcn',@(btn,event) app.checkRngVal(input));
            
            % Center GUI for setting ranges
            movegui(uf,'center')
            
            % Hide base GUI
            % When I get a later version of MATLAB using modal should be
            % better than hiding the figure
            app.GeneticAlgorithmUIFigure.Visible = 'off';
            
            % Show GUI for setting ranges
            uf.Visible = 'on';
        end

        % Button pushed function: SetinitialPopulationButton
        function SetinitialPopulationButtonPushed(app, event)
            % Get the dropdown value 1 (binary) or 2 (real)
            type = app.TypeofValuesDropDown.Value;
            
            % Get the number of chromosomes
            chromNum = app.PopulationSizeEditField.Value;
            
            % Get number of strings
            strNum = app.StringsPerChromosomeEditField.Value;
            
            % Get the number of bits per string
            bitNum = app.BitsPerStringEditField.Value;
            
            % Get the number of decimal places
            app.DecimalPlacesEditField.Value = app.DecimalPlacesEditField.Value;
            
            % If Population is empty make cellPopOut empty otherwise save
            % each line of the Population as an element in cellPopOut
            if app.Pop == ""
                cellPopOut = '';
            else
                cellPopOut = PopLines();
            end
            
            % If last valid Population is empty make it equal to cellPopOut
            if app.LastPop == ""
                app.LastPop = cellPopOut;
            end

            % Create UI figure (uf) to set set initial population but do
            % not show till setup finishes
            uf = uifigure('Name','Initial Population','Position',...
                [100 100 616 420],'Scrollable','on','DeleteFcn',...
                @(uf,event) ufDeleteFcn(),'CloseRequestFcn',...
                @(uf,event) ufCloseFcn(),'Visible','off');

            % Set last part of instruction according to the type (binary or
            % real)
            if type == 1
                labelend = ' of 1s and 0s';
            else
                labelend = '';
            end
            
            % Input instruction
            labelmsg{1,2} = sprintf('Format: %d %d-digit numbers%s',...
                strNum,bitNum,labelend);  
            labelmsg{1,1} = 'Input values in each row for the respective chromosomes.';

            uilabel(uf,'Position',[56 356 448 33],'Text',labelmsg);
            
            % User input values area
            input = uitextarea(uf,'Position',[56 42 336 294],...
                'Value',cellPopOut);
            
            % Random Populatio button
            uibutton(uf,'push','Text','Random Pop.',....
                'Position',[448 272 112 22],...
                'ButtonPushedFcn',@(btn,event) app.ResetVal(1));
            
            % Last valid Population button
            uibutton(uf,'push','Text','Last Valid Pop.',...
                'Position',[448 178 112 22],...
                'ButtonPushedFcn',@(btn,event) ResetVal(2));
            
            % Set button
            uibutton(uf,'push','Text','Set',...
                'Position',[448 84 112 22],'BackgroundColor','#4DBEEE',...
                'ButtonPushedFcn',@(btn,event) set());
            
            % Center GUI for setting Population
            movegui(uf,'center')
            
            % Hide base GUI
            % When I get a later version of MATLAB using modal should be
            % better than hiding the figure
            app.GeneticAlgorithmUIFigure.Visible = 'off';
            
            % Show GUI for setting ranges
            uf.Visible = 'on';

            function cellPop = PopLines()
                %This function stores each row of Populaion in app.Pop as
                % a string in the output cell array (cellPop)
                if app.Pop ~= ""
                    cellPop = strings(size(app.Pop,1),1);
                    for i = 1:length(cellPop)
                        cellPop(i) = strjoin(app.Pop(i,:));
                    end
                else
                  cellPop = '';
                end
            end
            
            function ResetVal(val)
                % This function sets the values of the Population as
                % random values if val is 1 or to the last valid values
                % if val is 2
                if val == 1
                    if type == 1
                        randInts = randi([0 2^bitNum-1],chromNum,strNum);
                    else
                        randInts = zeros(chromNum,strNum);
                        for i = 1:strNum
                            if (10^bitNum-1) <= round(app.Rng(i,2)*10^app.DecimalPlacesEditField.Value)
                                upLim = 10^bitNum-1;
                            else
                                upLim = round(app.Rng(i,2)*10^app.DecimalPlacesEditField.Value);
                            end
                            randInts(:,i) = randi([0 upLim],chromNum,1);
                        end
                    end
                    app.Pop = strings(chromNum,strNum);
                    if type == 1
                        for i=1:strNum
                            app.Pop(:,i) = string(dec2bin(randInts(:,i),bitNum));
                        end
                    elseif type == 2
                        for i=1:chromNum
                            for j=1:strNum
                                app.Pop(i,j) = sprintf("%0"+...
                                    string(bitNum)+"d",randInts(i,j));
                            end
                        end
                    end
                elseif val ==2
                    % If no last valid values raise error else make
                    % Population equal to last valid values
                    if app.LastPop == ""
                        alertmsg{2,1} = 'You can use random population instead';
                        alertmsg{1,1} = 'No population has been set yet';
                        uialert(uf,alertmsg,'Error');
                    else
                        app.Pop = app.LastPop;
                    end
                end
                
                % Save Population in a cell array
                cellPopOut = PopLines();
                
                % Output the Population in the GUI for Population
                input.Value = cellPopOut;
                input.BackgroundColor = '#fff';
            end
            function set
                
                % If input is empty or number of rows is not equal to
                % number of strings raise error otherwise continue to else
                if string(input.Value) == ""
                    uialert(uf,'There are no values. There should be '+...
                        string(chromNum)+' chromosome populations','Error')
                    input.BackgroundColor = '#EDB120';
                elseif size(input.Value,1) ~= chromNum
                    uialert(uf,'There are '+string(size(input.Value,1))+...
                        ' values. There should be '+string(chromNum)+...
                        ' chromosome Populations','Error')
                    input.BackgroundColor = '#EDB120';
                else
                    
                    % Empty 2-column cell array with rows equal to length
                    % of input values
                    cellPopScan = cell(size(input.Value,1),strNum);
                    
                    % Set the type and number of digits required according
                    % to type (binary or real) and number of bits
                    if type == 1
                        digits = "[0-1]{"+string(bitNum)+"}";
                    elseif type == 2
                        digits = "\d{"+string(bitNum)+"}";
                    end
                    
                    % expr is a regular expression for checking the inputs
                    expr = strjoin(repmat(digits,1,strNum),'[ ]+');
                    
                    % Error check each line of input. If any error track
                    % with valErr
                    for i = 1:size(input.Value,1)
                        % Remove leading and trailing spaces then check if
                        % current line matches expr
                        [start,last] = regexp(strip(input.Value{i}),expr,'once');
                        
                        if isempty(start) && isempty(last)        % current line does not match expr
                            alertmsg = sprintf("Format: Input %d %d-digit numbers"+...
                                "%s\nfor each chromosome (row)",strNum,bitNum,labelend);
                            uialert(uf,alertmsg,'Error')
                            valErr = 1;
                            input.BackgroundColor = '#EDB120';
                            break
                        elseif (start(1) == 1 && last(end) == length(strip(input.Value{i}))) % current line matches expr exactly
                            scanformat = strjoin(repmat("%s",1,strNum));
                            cellPopScan(i,:) = textscan(input.Value{i},scanformat);
                            if type == 1
                                valErr = 0;
                                input.BackgroundColor = '#fff';
                            elseif type == 2
                                for j = 1:size(cellPopScan(i,:),2)
                                    if str2double(cellPopScan{i,j})*10^-app.DecimalPlacesEditField.Value < app.Rng(j,1)
                                        alertmsg = sprintf("Each value should not be lesser than %d",...
                                            app.Rng(j,1)*10^-app.DecimalPlacesEditField.Value);
                                        uialert(uf,alertmsg,'Error')
                                        valErr = 1;
                                        input.BackgroundColor = '#EDB120';
                                        break
                                    elseif str2double(cellPopScan{i,j})*10^-app.DecimalPlacesEditField.Value > app.Rng(j,2)
                                        alertmsg = sprintf("Each value should not be more than %d",...
                                            app.Rng(j,2)*10^-app.DecimalPlacesEditField.Value);
                                        uialert(uf,alertmsg,'Error')
                                        valErr = 1;
                                        input.BackgroundColor = '#EDB120';
                                        break
                                    else
                                        valErr = 0;
                                        input.BackgroundColor = '#fff';
                                    end
                                end
                            end
                            if valErr
                                break
                            end
                        else    % current line matches expr partly
                            alertmsg = sprintf("Format: Input %d %d-digit numbers"+...
                                "%s\nfor each chromosome (row)",strNum,bitNum,labelend);
                            uialert(uf,alertmsg,'Error')
                            valErr = 1;
                            input.BackgroundColor = '#EDB120';
                            break
                        end
                    end
                    if ~valErr % if no error occurs
                        % Update the values of the Population (app.Pop)
                        app.Pop = strings(chromNum,strNum);
                        for i = 1:size(cellPopScan,1)
                            for j = 1:size(cellPopScan,2)
                                app.Pop(i,j) = string(cellPopScan{i,j});
                            end
                        end
                        
                        % Set input background to white
                        input.BackgroundColor = '#fff';
                        
                        % Update Last Valid Population (app.LastPop)
                        app.LastPop = app.Pop;
                        
                        % Set button background to white
                        app.SetinitialPopulationButton.BackgroundColor = '#fff';
                        
                        % discard Range Error if raised
                        app.Err(app.PopErr) = 0;
                        
                        %Check for any errors if any disable Generate button
                        app.checkErr();
                        
                        % Remove the * in the button text
                        app.SetinitialPopulationButton.Text = "Set Initial Population";
                        
                        % Close the figure
                        close(uf)
                    end
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
        end

        % Value changed function: FunctionEditField
        function FunctionEditFieldValueChanged(app, event)
            value = regexprep(app.FunctionEditField.Value,'\s','');
            
            value = regexprep(value,'X','x');
            
            app.FunctionEditField.Value = value;
            
            % Get number of strings
            strNum = app.StringsPerChromosomeEditField.Value;
            
            % expr is a regular expression to check the function
            expr = "[-+]?(?:x["+strjoin(string(1:strNum),'')+"])(?:[+*/^-]x["+strjoin(string(1:strNum),'')+"])*";
            
            % Check if function matches expr
            [start,last] = regexp(value,expr,'once');
            
            if isempty(start) || isempty(last)  % Function does not match expr
                app.FunctionEditField.BackgroundColor = '#EDB120';
                app.Err(app.FuncErr) = 1;
            elseif start(1) == 1 && last(end) == length(value)  % function matches expr exactly
                app.FunctionEditField.BackgroundColor = '#fff';
                app.Err(app.FuncErr) = 0;
            else    % current line matches expr partly
                app.FunctionEditField.BackgroundColor = '#EDB120';
                app.Err(app.FuncErr) = 1;
            end
            
            %Check for any errors if any disable Generate button
            app.checkErr();
        end

        % Size changed function: ButtonGroup
        function ButtonGroupSizeChanged(app, event)
            position = app.ButtonGroup.Position;
            app.PointButton.Position(1) = round((position(3)-243)/2);
            app.PointsButton.Position(1) = app.PointButton.Position(1)+177;
        end

        % Size changed function: ButtonGroup_2
        function ButtonGroup_2SizeChanged(app, event)
            position = app.ButtonGroup_2.Position;
            app.RolletteWheelButton.Position(1) = round((position(3)-243)/2);
            app.ElitismButton.Position(1) = app.RolletteWheelButton.Position(1)+177;
        end

        % Button pushed function: GenerateButton
        function GenerateButtonPushed(app, event)
            
            % If there is Range or Population error show it then disable
            % Generate button
            if app.Err(app.RngErr) || app.Err(app.PopErr)
                app.RngPopErr();    % Show Range or Population error
                app.checkErr();     % Disable Generate button if any error
            elseif app.Err(app.FuncErr)
                app.FunctionEditField.BackgroundColor = '#EDB120';
                app.checkErr();
            else
                GenZero = struct('initPop',app.Pop,'denVal',[],'decVal',[],'fx',[],'fit',[],...
                    'cumFit',[],'selChroms',[],'bestTillNow',"",'bestFitTillNow',[],...
                    'finalPop',[]);
                
                GenZero = evaluate(GenZero);
                GenZero = select(GenZero,0);
                
                Gen(app.StopatGenerationEditField.Value) = struct('initPop',app.Pop,'crossPairs',[],'crossProbs',[],...
                    'crossPoints',[],'doCross',[],'crossedPop',[],'mutPairs',[],...
                    'mutProbs',[],'mutPoints',[],'doMutation',[],'mutatedPop',[],...
                    'denVal',[],'decVal',[],'fx',[],'fit',[],'cumFit',[],'selChroms',[],...
                    'bestTillNow',"",'bestFitTillNow',[],'finalPop',[]);
                
                for GenNo = 1:app.StopatGenerationEditField.Value
                    if GenNo == 1
                        Gen(GenNo).initPop = GenZero.finalPop;
                    else
                        Gen(GenNo).initPop = Gen(GenNo-1).finalPop;
                    end
                    
                    Gen(GenNo) = cross(Gen(GenNo));
                    Gen(GenNo) = mutate(Gen(GenNo));
                    Gen(GenNo) = evaluate(Gen(GenNo));
                    Gen(GenNo) = select(Gen(GenNo),GenNo);
                end
            end
            
            function Gen = cross(Gen)
                Gen.crossPairs = ones(app.PopulationSizeEditField.Value/2,2);
                for i = 1:app.PopulationSizeEditField.Value/2
                    Gen.crossPairs(i,:) = randi(app.PopulationSizeEditField.Value,1,2);
                    repErr = 1;
                    if i ~= 1
                        while repErr
                            check1 = Gen.crossPairs(i,:) == Gen.crossPairs(1:i-1,:);
                            check2 = Gen.crossPairs(i,1) == Gen.crossPairs(i,2);
                            if (any(all(check1,2)) || check2)
                                Gen.crossPairs(i,:) = randi(app.PopulationSizeEditField.Value,1,2);
                            else
                                repErr = 0;
                            end
                        end
                    end
                end
                Gen.crossProbs = rand(app.PopulationSizeEditField.Value/2,app.StringsPerChromosomeEditField.Value);
                if app.PointButton.Value
                    Gen.crossPoints = randi(app.BitsPerStringEditField.Value-1,app.PopulationSizeEditField.Value/2,1);
                else
                    Gen.crossPoints = zeros(app.PopulationSizeEditField.Value/2,2);
                    genNums = randi(app.BitsPerStringEditField.Value-1,app.PopulationSizeEditField.Value/2,2);
                    for j = 1:size(genNums,1)
                        Gen.crossPoints(j,1) = max(genNums(j,:));
                        Gen.crossPoints(j,2) = min(genNums(j,:));
                    end
                end
                Gen.doCross = Gen.crossProbs <= app.CrossOverProbabilityEditField.Value;
                Gen.crossedPop = strings(size(Gen.initPop));
                for i = 1:size(Gen.doCross,1)
                    for j = 1:size(Gen.doCross,2)
                        if Gen.doCross(i,j)
                            a = char(Gen.initPop(Gen.crossPairs(i,1),j));
                            b = char(Gen.initPop(Gen.crossPairs(i,2),j));
                            c = a;
                            if app.PointButton.Value
                                a(end-Gen.crossPoints(i)+1:end) = b(end-Gen.crossPoints(i)+1:end);
                                b(end-Gen.crossPoints(i)+1:end) = c(end-Gen.crossPoints(i)+1:end);
                            else
                                a(end-Gen.crossPoints(i,1)+1:end-Gen.crossPoints(i,2)) = ...
                                    b(end-Gen.crossPoints(i)+1:end-Gen.crossPoints(i,2));
                                b(end-Gen.crossPoints(i)+1:end-Gen.crossPoints(i,2)) = ...
                                    c(end-Gen.crossPoints(i)+1:end-Gen.crossPoints(i,2));
                            end
                            if str2double(a)*10^-app.DecimalPlacesEditField.Value < app.Rng(j,1)
                                Gen.crossedPop(i*2-1,j) = string(app.Rng(j,1));
                            elseif str2double(a)*10^-app.DecimalPlacesEditField.Value > app.Rng(j,2)
                                Gen.crossedPop(i*2-1,j) = string(app.Rng(j,2));
                            else
                                Gen.crossedPop(i*2-1,j) = string(a);
                            end
                            if str2double(b)*10^-app.DecimalPlacesEditField.Value < app.Rng(j,1)
                                Gen.crossedPop(i*2,j) = string(app.Rng(j,1));
                            elseif str2double(b)*10^-app.DecimalPlacesEditField.Value > app.Rng(j,2)
                                Gen.crossedPop(i*2,j) = string(app.Rng(j,2));
                            else
                                Gen.crossedPop(i*2,j) = string(b);
                            end
                        else
                            Gen.crossedPop([i*2-1 i*2],j) = ...
                                Gen.initPop([Gen.crossPairs(i,1) Gen.crossPairs(i,2)],j);
                        end
                    end
                end
            end
            
            function Gen = mutate(Gen)
                Gen.mutPairs = ones(app.PopulationSizeEditField.Value/2,2);
                for i = 1:app.PopulationSizeEditField.Value/2
                    Gen.mutPairs(i,:) = randi(app.PopulationSizeEditField.Value,1,2);
                    repErr = 1;
                    if i ~= 1
                        while repErr
                            check1 = Gen.mutPairs(i,:) == Gen.mutPairs(1:i-1,:);
                            check2 = Gen.mutPairs(i,1) == Gen.mutPairs(i,2);
                            if (any(all(check1,2)) || check2)
                                Gen.mutPairs(i,:) = randi(app.PopulationSizeEditField.Value,1,2);
                            else
                                repErr = 0;
                            end
                        end
                    end
                end
                Gen.mutProbs = rand(app.PopulationSizeEditField.Value/2,app.StringsPerChromosomeEditField.Value);
                Gen.mutPoints = randi(app.BitsPerStringEditField.Value-1,app.PopulationSizeEditField.Value/2,1);
                Gen.doMutation = Gen.mutProbs <= app.MutationProbabilityEditField.Value;
                Gen.mutatedPop = strings(size(Gen.crossedPop));
                for i = 1:size(Gen.doMutation,1)
                    for j = 1:size(Gen.doMutation,2)
                        if Gen.doMutation(i,j)
                            a = char(Gen.crossedPop(Gen.crossPairs(i,1),j));
                            b = char(Gen.crossedPop(Gen.crossPairs(i,2),j));
                            c = a;
                            a(Gen.mutPoints(i)) = b(Gen.mutPoints(i));
                            b(Gen.mutPoints(i)) = c(Gen.mutPoints(i));
                            if str2double(a)*10^-app.DecimalPlacesEditField.Value < app.Rng(j,1)
                                Gen.mutatedPop(i*2-1,j) = string(app.Rng(j,1));
                            elseif str2double(a)*10^-app.DecimalPlacesEditField.Value > app.Rng(j,2)
                                Gen.mutatedPop(i*2-1,j) = string(app.Rng(j,2));
                            else
                                Gen.mutatedPop(i*2-1,j) = string(a);
                            end
                            if str2double(b)*10^-app.DecimalPlacesEditField.Value < app.Rng(j,1)
                                Gen.mutatedPop(i*2,j) = string(app.Rng(j,1));
                            elseif str2double(b)*10^-app.DecimalPlacesEditField.Value > app.Rng(j,2)
                                Gen.mutatedPop(i*2,j) = string(app.Rng(j,2));
                            else
                                Gen.mutatedPop(i*2,j) = string(b);
                            end
                        else
                            Gen.mutatedPop([i*2-1 i*2],j) = ...
                                crossedPop([Gen.mutPairs(i,1) Gen.mutPairs(i,2)],j);
                        end
                    end
                end
            end
            
            function Gen = evaluate(Gen)
                fitFunc = str2func("@("+strjoin("x"+string(1:app.StringsPerChromosomeEditField.Value),',')+")"+app.FunctionEditField.Value); %#ok<NASGU>
                Gen.fx = zeros(app.PopulationSizeEditField.Value,1);
            
                if app.TypeofValuesDropDown.Value == 1
                    Gen.denVal = zeros(app.PopulationSizeEditField.Value,app.StringsPerChromosomeEditField.Value);
                    Gen.decVal = zeros(app.PopulationSizeEditField.Value,app.StringsPerChromosomeEditField.Value);
                    for i = 1:app.PopulationSizeEditField.Value
                        for j = 1:app.StringsPerChromosomeEditField.Value
                            Gen.denVal(i,j) = bin2dec(Gen.initPop(i,j));
                            Gen.decVal(i,j) = app.Rng(j,1) + (app.Rng(j,2)-app.Rng(j,1))*...
                                Gen.denVal(i,j)/(2^app.BitsPerStringEditField.Value-1);
                        end
                        Gen.fx(i) = eval("fitFunc("+strjoin(string(Gen.decVal(i,:)),...
                        ',')+")");
                    end
                else
                    Gen.decVal = zeros(app.PopulationSizeEditField.Value,app.StringsPerChromosomeEditField.Value);
                    for i = 1:app.PopulationSizeEditField.Value
                        for j = 1:app.StringsPerChromosomeEditField.Value
                            Gen.decVal(i,j) = str2double(Gen.initPop(i,j))*10^-app.DecimalPlacesEditField.Value;
                        end
                        Gen.fx(i) = eval("fitFunc("+strjoin(string(Gen.decVal(i,:)),...
                        ',')+")");
                    end
                end
                if app.MinMaxDropDown.Value == 1
                    Gen.fit = 1./Gen.fx;
                else
                    Gen.fit = Gen.fx;
                end
            end
            
            function CurGen = select(CurGen,GenNo)
                CurGen.cumFit = cumsum(CurGen.fit);
                [maxfit,ind] = max(CurGen.fit);
                if (GenNo==0)
                    CurGen.bestFitTillNow = maxfit;
                    CurGen.bestTillNow = CurGen.initPop(ind,:);
                elseif GenNo >= 2
                    if maxfit >= Gen(GenNo-1).bestFitTillNow
                        CurGen.bestFitTillNow = maxfit;
                        CurGen.bestTillNow = CurGen.initPop(ind,:);
                    else
                        CurGen.bestFitTillNow = Gen(GenNo-1).bestFitTillNow;
                        CurGen.bestTillNow = Gen(GenNo-1).bestTillNow;
                    end
                else
                    if maxfit >= GenZero.bestFitTillNow
                        CurGen.bestFitTillNow = maxfit;
                        CurGen.bestTillNow = CurGen.initPop(ind,:);
                    else
                        CurGen.bestFitTillNow = GenZero.bestFitTillNow;
                        CurGen.bestTillNow = GenZero.bestTillNow;
                    end
                end
                CurGen.finalPop = strings(size(CurGen.initPop));
                [~,sortInd] = sort(CurGen.fit);
                if (app.RolletteWheelButton.Value || length(sortInd) <= 2)
                    CurGen.selChroms = randi(length(sortInd),1,length(sortInd));
                else
                    if (length(sortInd) == 3 || length(sortInd) == 4)
                        CurGen.selChroms = ones(1,length(sortInd));
                        CurGen.selChroms([1 2]) = sortInd([1 end]);
                        CurGen.selChroms(3:end) = randi(length(sortInd),1,length(sortInd)-2);
                    else
                        CurGen.selChroms = ones(1,length(sortInd));
                        CurGen.selChroms(1:4) = sortInd([1 2 end-1 end]);
                        CurGen.selChroms(5:end) = randi(length(sortInd),1,length(sortInd)-4);
                    end
                end
                CurGen.finalPop = CurGen.initPop(CurGen.selChroms,:);
            end
            % Up next main algorithm!
            
            % To-Do: use uiputfile for filename and directory
            
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create GeneticAlgorithmUIFigure and hide until all components are created
            app.GeneticAlgorithmUIFigure = uifigure('Visible', 'off');
            app.GeneticAlgorithmUIFigure.Position = [100 100 640 640];
            app.GeneticAlgorithmUIFigure.Name = 'Genetic Algorithm';
            app.GeneticAlgorithmUIFigure.Scrollable = 'on';

            % Create GeneticAlgorithmLabel
            app.GeneticAlgorithmLabel = uilabel(app.GeneticAlgorithmUIFigure);
            app.GeneticAlgorithmLabel.HorizontalAlignment = 'center';
            app.GeneticAlgorithmLabel.FontName = 'Agency FB';
            app.GeneticAlgorithmLabel.FontSize = 20;
            app.GeneticAlgorithmLabel.FontWeight = 'bold';
            app.GeneticAlgorithmLabel.Position = [1 594 640 27];
            app.GeneticAlgorithmLabel.Text = 'Genetic Algorithm';

            % Create GenerateButton
            app.GenerateButton = uibutton(app.GeneticAlgorithmUIFigure, 'push');
            app.GenerateButton.ButtonPushedFcn = createCallbackFcn(app, @GenerateButtonPushed, true);
            app.GenerateButton.BackgroundColor = [0.302 0.7451 0.9333];
            app.GenerateButton.FontColor = [0.9412 0.9412 0.9412];
            app.GenerateButton.Position = [482 22 100 22];
            app.GenerateButton.Text = 'Generate';

            % Create PopulationSizeLabel
            app.PopulationSizeLabel = uilabel(app.GeneticAlgorithmUIFigure);
            app.PopulationSizeLabel.Position = [378 529 151 22];
            app.PopulationSizeLabel.Text = 'Population Size:';

            % Create PopulationSizeEditField
            app.PopulationSizeEditField = uieditfield(app.GeneticAlgorithmUIFigure, 'numeric');
            app.PopulationSizeEditField.LowerLimitInclusive = 'off';
            app.PopulationSizeEditField.UpperLimitInclusive = 'off';
            app.PopulationSizeEditField.Limits = [0 Inf];
            app.PopulationSizeEditField.RoundFractionalValues = 'on';
            app.PopulationSizeEditField.ValueDisplayFormat = '%.0f';
            app.PopulationSizeEditField.ValueChangedFcn = createCallbackFcn(app, @PopulationSizeEditFieldValueChanged, true);
            app.PopulationSizeEditField.Tooltip = {'Value must be an even number'};
            app.PopulationSizeEditField.Position = [539 529 43 22];
            app.PopulationSizeEditField.Value = 10;

            % Create StringsPerChromosomeLabel
            app.StringsPerChromosomeLabel = uilabel(app.GeneticAlgorithmUIFigure);
            app.StringsPerChromosomeLabel.Position = [44 483 150 22];
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
            app.StringsPerChromosomeEditField.Position = [203 483 56 22];
            app.StringsPerChromosomeEditField.Value = 5;

            % Create BitsPerStringEditFieldLabel
            app.BitsPerStringEditFieldLabel = uilabel(app.GeneticAlgorithmUIFigure);
            app.BitsPerStringEditFieldLabel.Position = [376 483 151 22];
            app.BitsPerStringEditFieldLabel.Text = 'Bits Per String:';

            % Create BitsPerStringEditField
            app.BitsPerStringEditField = uieditfield(app.GeneticAlgorithmUIFigure, 'numeric');
            app.BitsPerStringEditField.LowerLimitInclusive = 'off';
            app.BitsPerStringEditField.UpperLimitInclusive = 'off';
            app.BitsPerStringEditField.Limits = [0 Inf];
            app.BitsPerStringEditField.RoundFractionalValues = 'on';
            app.BitsPerStringEditField.ValueDisplayFormat = '%.0f';
            app.BitsPerStringEditField.ValueChangedFcn = createCallbackFcn(app, @BitsPerStringCheck, true);
            app.BitsPerStringEditField.Position = [537 483 45 22];
            app.BitsPerStringEditField.Value = 7;

            % Create FunctionEditFieldLabel
            app.FunctionEditFieldLabel = uilabel(app.GeneticAlgorithmUIFigure);
            app.FunctionEditFieldLabel.HorizontalAlignment = 'right';
            app.FunctionEditFieldLabel.Position = [219 316 60 22];
            app.FunctionEditFieldLabel.Text = 'Function:';

            % Create FunctionEditField
            app.FunctionEditField = uieditfield(app.GeneticAlgorithmUIFigure, 'text');
            app.FunctionEditField.ValueChangedFcn = createCallbackFcn(app, @FunctionEditFieldValueChanged, true);
            app.FunctionEditField.Position = [293 316 289 22];

            % Create TypeofValuesDropDownLabel
            app.TypeofValuesDropDownLabel = uilabel(app.GeneticAlgorithmUIFigure);
            app.TypeofValuesDropDownLabel.Position = [44 529 84 22];
            app.TypeofValuesDropDownLabel.Text = 'Type of Values';

            % Create TypeofValuesDropDown
            app.TypeofValuesDropDown = uidropdown(app.GeneticAlgorithmUIFigure);
            app.TypeofValuesDropDown.Items = {'Binary', 'Real'};
            app.TypeofValuesDropDown.ValueChangedFcn = createCallbackFcn(app, @TypeofValuesDropDownValueChanged, true);
            app.TypeofValuesDropDown.BackgroundColor = [1 1 1];
            app.TypeofValuesDropDown.Position = [133 529 126 22];
            app.TypeofValuesDropDown.Value = 'Binary';

            % Create MinMaxLabel
            app.MinMaxLabel = uilabel(app.GeneticAlgorithmUIFigure);
            app.MinMaxLabel.Position = [44 316 54 22];
            app.MinMaxLabel.Text = 'Min/Max:';

            % Create MinMaxDropDown
            app.MinMaxDropDown = uidropdown(app.GeneticAlgorithmUIFigure);
            app.MinMaxDropDown.Items = {'Min', 'Max'};
            app.MinMaxDropDown.BackgroundColor = [1 1 1];
            app.MinMaxDropDown.Position = [109 316 67 22];
            app.MinMaxDropDown.Value = 'Min';

            % Create EvaluationLabel
            app.EvaluationLabel = uilabel(app.GeneticAlgorithmUIFigure);
            app.EvaluationLabel.HorizontalAlignment = 'center';
            app.EvaluationLabel.Position = [1 348 640 22];
            app.EvaluationLabel.Text = 'Evaluation';

            % Create PopulationGenerationLabel
            app.PopulationGenerationLabel = uilabel(app.GeneticAlgorithmUIFigure);
            app.PopulationGenerationLabel.HorizontalAlignment = 'center';
            app.PopulationGenerationLabel.Position = [1 560 640 22];
            app.PopulationGenerationLabel.Text = 'Population Generation';

            % Create SetinitialPopulationButton
            app.SetinitialPopulationButton = uibutton(app.GeneticAlgorithmUIFigure, 'push');
            app.SetinitialPopulationButton.ButtonPushedFcn = createCallbackFcn(app, @SetinitialPopulationButtonPushed, true);
            app.SetinitialPopulationButton.BackgroundColor = [1 1 1];
            app.SetinitialPopulationButton.Position = [378 389 204 22];
            app.SetinitialPopulationButton.Text = 'Set initial Population *';

            % Create DecimalPlacesEditFieldLabel
            app.DecimalPlacesEditFieldLabel = uilabel(app.GeneticAlgorithmUIFigure);
            app.DecimalPlacesEditFieldLabel.Position = [44 436 151 22];
            app.DecimalPlacesEditFieldLabel.Text = 'Decimal Places:';

            % Create DecimalPlacesEditField
            app.DecimalPlacesEditField = uieditfield(app.GeneticAlgorithmUIFigure, 'numeric');
            app.DecimalPlacesEditField.Limits = [0 Inf];
            app.DecimalPlacesEditField.RoundFractionalValues = 'on';
            app.DecimalPlacesEditField.ValueDisplayFormat = '%.0f';
            app.DecimalPlacesEditField.ValueChangedFcn = createCallbackFcn(app, @DecimalPlacesEditFieldValueChanged, true);
            app.DecimalPlacesEditField.Tooltip = {'Value must not be more than bits per string'};
            app.DecimalPlacesEditField.Position = [205 436 54 22];

            % Create CrossOverLabel
            app.CrossOverLabel = uilabel(app.GeneticAlgorithmUIFigure);
            app.CrossOverLabel.HorizontalAlignment = 'center';
            app.CrossOverLabel.Position = [1 273 640 22];
            app.CrossOverLabel.Text = 'Cross-Over';

            % Create ButtonGroup
            app.ButtonGroup = uibuttongroup(app.GeneticAlgorithmUIFigure);
            app.ButtonGroup.AutoResizeChildren = 'off';
            app.ButtonGroup.BorderType = 'none';
            app.ButtonGroup.TitlePosition = 'centertop';
            app.ButtonGroup.SizeChangedFcn = createCallbackFcn(app, @ButtonGroupSizeChanged, true);
            app.ButtonGroup.Position = [1 244 640 30];

            % Create PointButton
            app.PointButton = uiradiobutton(app.ButtonGroup);
            app.PointButton.Text = '1 Point';
            app.PointButton.Position = [199 9 60 22];
            app.PointButton.Value = true;

            % Create PointsButton
            app.PointsButton = uiradiobutton(app.ButtonGroup);
            app.PointsButton.Text = '2 Points';
            app.PointsButton.Position = [376 5 66 22];

            % Create SetRangesButton
            app.SetRangesButton = uibutton(app.GeneticAlgorithmUIFigure, 'push');
            app.SetRangesButton.ButtonPushedFcn = createCallbackFcn(app, @SetRangesButtonPushed, true);
            app.SetRangesButton.BackgroundColor = [1 1 1];
            app.SetRangesButton.Position = [44 389 215 22];
            app.SetRangesButton.Text = 'Set Ranges *';

            % Create GenerationLabel
            app.GenerationLabel = uilabel(app.GeneticAlgorithmUIFigure);
            app.GenerationLabel.HorizontalAlignment = 'center';
            app.GenerationLabel.Position = [1 162 640 22];
            app.GenerationLabel.Text = 'Generation';

            % Create StopatGenerationLabel
            app.StopatGenerationLabel = uilabel(app.GeneticAlgorithmUIFigure);
            app.StopatGenerationLabel.Position = [44 141 150 22];
            app.StopatGenerationLabel.Text = 'Stop at Generation:';

            % Create StopatGenerationEditField
            app.StopatGenerationEditField = uieditfield(app.GeneticAlgorithmUIFigure, 'numeric');
            app.StopatGenerationEditField.UpperLimitInclusive = 'off';
            app.StopatGenerationEditField.Limits = [0 Inf];
            app.StopatGenerationEditField.RoundFractionalValues = 'on';
            app.StopatGenerationEditField.ValueDisplayFormat = '%.0f';
            app.StopatGenerationEditField.Position = [203 141 56 22];
            app.StopatGenerationEditField.Value = 10;

            % Create SelectionLabel
            app.SelectionLabel = uilabel(app.GeneticAlgorithmUIFigure);
            app.SelectionLabel.HorizontalAlignment = 'center';
            app.SelectionLabel.Position = [1 223 640 22];
            app.SelectionLabel.Text = 'Selection';

            % Create ButtonGroup_2
            app.ButtonGroup_2 = uibuttongroup(app.GeneticAlgorithmUIFigure);
            app.ButtonGroup_2.AutoResizeChildren = 'off';
            app.ButtonGroup_2.BorderType = 'none';
            app.ButtonGroup_2.SizeChangedFcn = createCallbackFcn(app, @ButtonGroup_2SizeChanged, true);
            app.ButtonGroup_2.Position = [1 194 640 30];

            % Create RolletteWheelButton
            app.RolletteWheelButton = uiradiobutton(app.ButtonGroup_2);
            app.RolletteWheelButton.Text = 'Rollette Wheel';
            app.RolletteWheelButton.Position = [199 1 106 22];
            app.RolletteWheelButton.Value = true;

            % Create ElitismButton
            app.ElitismButton = uiradiobutton(app.ButtonGroup_2);
            app.ElitismButton.Text = 'Elitism';
            app.ElitismButton.Position = [378 1 64 22];

            % Create GeneralProbabilitiesLabel
            app.GeneralProbabilitiesLabel = uilabel(app.GeneticAlgorithmUIFigure);
            app.GeneralProbabilitiesLabel.HorizontalAlignment = 'center';
            app.GeneralProbabilitiesLabel.Position = [1 109 640 22];
            app.GeneralProbabilitiesLabel.Text = 'General Probabilities';

            % Create CrossOverProbabilityEditFieldLabel
            app.CrossOverProbabilityEditFieldLabel = uilabel(app.GeneticAlgorithmUIFigure);
            app.CrossOverProbabilityEditFieldLabel.Position = [44 86 150 22];
            app.CrossOverProbabilityEditFieldLabel.Text = 'Cross-Over Probability:';

            % Create CrossOverProbabilityEditField
            app.CrossOverProbabilityEditField = uieditfield(app.GeneticAlgorithmUIFigure, 'numeric');
            app.CrossOverProbabilityEditField.Limits = [0 1];
            app.CrossOverProbabilityEditField.ValueDisplayFormat = '%.2f';
            app.CrossOverProbabilityEditField.Position = [203 86 56 22];
            app.CrossOverProbabilityEditField.Value = 0.85;

            % Create MutationProbabilityEditFieldLabel
            app.MutationProbabilityEditFieldLabel = uilabel(app.GeneticAlgorithmUIFigure);
            app.MutationProbabilityEditFieldLabel.Position = [378 86 150 22];
            app.MutationProbabilityEditFieldLabel.Text = 'Mutation Probability:';

            % Create MutationProbabilityEditField
            app.MutationProbabilityEditField = uieditfield(app.GeneticAlgorithmUIFigure, 'numeric');
            app.MutationProbabilityEditField.Limits = [0 1];
            app.MutationProbabilityEditField.ValueDisplayFormat = '%.2f';
            app.MutationProbabilityEditField.Position = [537 86 45 22];
            app.MutationProbabilityEditField.Value = 0.2;

            % Show the figure after all components are created
            app.GeneticAlgorithmUIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = GeneticAlgorithmCode

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