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
        ChromNumErr = 1;  % Index of Err corresponding to no of chromosomes
                          % error
        RngErr = 2;       % Index of Err corresponding to Range error
        PopErr = 3;       % Index of Err corresponding to Population error
        FuncErr = 4;      % Index of Err corresponding to function error
        Rng               % Ranges for strings
        LastRng           % Last valid user input for ranges 
        Pop = "";         % Population
        LastPop = "";     % Last valid population
        GenZero           % Initial generation
        % Other Generations
        Gen = struct('initPop',"",'crossPairs',[],'crossProbs',[],...
                    'crossPoints',[],'doCross',[],'crossedPop',[],...
                    'mutPairs',[],'mutProbs',[],'mutPoints',[],...
                    'doMutation',[],'mutatedPop',[],'denVal',[],...
                    'decVal',[],'fx',[],'fit',[],'cumFit',[],...
                    'selChroms',[],'bestTillNow',"",...
                    'bestFitTillNow',[],'finalPop',[]);
    end
    
    methods (Access = private)
        
        function cellRng = RngCell(app)
            %This function stores each set of ranges in app.Rng as a
            %string in the output cell array (cellRng)
            cellRng = cell(size(app.Rng,1),1);
            for row = 1:length(cellRng)
                cellRng{row} = num2str(app.Rng(row,:));
            end
        end
        
        function ResetRngVal(app,val,input)
            % This function sets the values of the ranges as the
            % default value if val is 1 or to the last valid values
            % if val is 2
            value = app.StringsPerChromosomeEditField.Value;
            strNum = app.StringsPerChromosomeEditField.Value;
            bits = app.BitsPerStringEditField.Value;
            decPl = app.DecimalPlacesEditField.Value;
            if val == 1
                if (app.TypeofValuesDropDown.Value == 1)
                    app.Rng = repmat([0 10],strNum,1);
                else
                    app.Rng = repmat([0 (10^bits-1)*10^-decPl],strNum,1);
                end
            elseif val == 2
                if size(app.LastRng,1) < value
                    if (app.TypeofValuesDropDown.Value == 1)
                        app.Rng = [app.LastRng; repmat([0 10],...
                            value-size(app.LastRng,1),1)];
                    else
                        app.Rng = [app.LastRng; repmat([0 (10^bits-1)*10^-decPl],...
                            value-size(app.LastRng,1),1)];
                    end
                elseif size(app.LastRng,1) > value
                    app.Rng = app.LastRng(1:value,:);
                else
                    app.Rng = app.LastRng;
                end
            end
            
            % Save the ranges in a cell array
            cellRng = app.RngCell();
            
            % Output the ranges in the GUI for ranges and make
            % background white
            input.Value = cellRng;
            input.BackgroundColor = '#fff';
        end
        
        function checkRngVal(app,uf,input)
            
            strNum = app.StringsPerChromosomeEditField.Value;
            bits = app.BitsPerStringEditField.Value;
            decPl = app.DecimalPlacesEditField.Value;
                
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
                expr = "([-]*[\d]+\.[\d]*|(?:[-]*[\d]*)?[.]?[\d]+)[ ]+"+...
                    "([-]*[\d]+\.[\d]*|(?:[-]*[\d]*)?[.]?[\d]+)";
                
                % Error check each line of input. If any error track
                % with valErr
                for i = 1:size(input.Value,1)
                                            
                    % Remove leading and trailing spaces then check if current line matches expr
                    [start,last] = regexp(strip(input.Value{i}),expr,'once');
                    
                    if isempty(start) && isempty(last)
                    % current line does not match expr
                        alertmsg{2,1} = 'min and max should be integers separated by space';
                        alertmsg{1,1} = 'Input format: min max';
                        uialert(uf,alertmsg,'Error')
                        valErr = 1;
                        input.BackgroundColor = '#EDB120';
                        break
                    elseif (start(1) == 1 && last(end) == length(strip(input.Value{i})))
                    % Current line matches expr exactly
                    
                        % Capture the two numbers into respective columns in cellAScan
                        cellAScan(i,:) = textscan(input.Value{i},'%f %f');
                        
                        if ~(cellAScan{i,1} <= cellAScan{i,2})
                        % First number (min) is greater than the second number (max)
                            alertmsg = 'Each min should not be greater than the respective max';
                            uialert(uf,alertmsg,'Error')
                            valErr = 1;
                            input.BackgroundColor = '#EDB120';
                            break
                        elseif (app.TypeofValuesDropDown.Value == 2 && cellAScan{i,1}<0)
                        % Type is real and first Number is lesser than zero
                            format long
                            alertmsg = 'Each min should not be lesser than zero';
                            uialert(uf,alertmsg,'Error')
                            valErr = 1;
                            input.BackgroundColor = '#EDB120';
                            break
                        elseif (app.TypeofValuesDropDown.Value == 2 ...
                                && cellAScan{i,2}>(10^bits)*10^-decPl)
                        % Type is real and the second number is higher than
                        % the maximum possible value. the maximum posibble
                        % value is 10 raised to the power of the number of
                        % bits minus one then shift decimal places forward
                        % by the specified decimal places
                        
                        % Every value in the population is to the decimal
                        % places specified from onset
                            format long
                            alertmsg = "Each max should not be greater than "+...
                                string((10^bits-1)*10^-decPl);
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
        
        function cellPop = PopLines(app)
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
        
        function ResetPopVal(app,val,input)
            % This function sets the values of the Population as
            % random values if val is 1 or to the last valid values
            % if val is 2
            
            % Get the dropdown value 1 (binary) or 2 (real)
            type = app.TypeofValuesDropDown.Value;
            
            % Get the number of chromosomes
            chromNum = app.PopulationSizeEditField.Value;
            
            % Get number of strings
            strNum = app.StringsPerChromosomeEditField.Value;
            
            % Get the number of bits per string
            bitNum = app.BitsPerStringEditField.Value;
            
            decPl = app.DecimalPlacesEditField.Value;
        
            if val == 1
                if type == 1
                    randInts = randi([0 2^bitNum-1],chromNum,strNum);
                else
                    randInts = zeros(chromNum,strNum);
                    for i = 1:strNum
                        if (10^bitNum-1) <= round(app.Rng(i,2)*10^decPl)
                            upLim = 10^bitNum-1;
                        else
                            upLim = round(app.Rng(i,2)*10^decPl);
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
            cellPopOut = app.PopLines();
            
            % Output the Population in the GUI for Population
            input.Value = cellPopOut;
            input.BackgroundColor = '#fff';
        end
        
        function set(app,uf,input)
                
            % Get the dropdown value 1 (binary) or 2 (real)
            type = app.TypeofValuesDropDown.Value;
            
            % Get the number of chromosomes
            chromNum = app.PopulationSizeEditField.Value;
            
            % Get number of strings
            strNum = app.StringsPerChromosomeEditField.Value;
            
            % Get the number of bits per string
            bitNum = app.BitsPerStringEditField.Value;
            
            decPl = app.DecimalPlacesEditField.Value;
            
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
                    labelend = ' of 1s and 0s';
                elseif type == 2
                    digits = "\d{"+string(bitNum)+"}";
                    labelend = '';
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
                    elseif (start(1) == 1 && last(end) == length(strip(input.Value{i})))
                    % current line matches expr exactly
                        scanformat = strjoin(repmat("%s",1,strNum));
                        cellPopScan(i,:) = textscan(input.Value{i},scanformat);
                        if type == 1
                            valErr = 0;
                            input.BackgroundColor = '#fff';
                        elseif type == 2
                            for j = 1:size(cellPopScan(i,:),2)
                                if str2double(cellPopScan{i,j})*10^-decPl < app.Rng(j,1)
                                    alertmsg = sprintf("Each value should not be lesser than %d",...
                                        app.Rng(j,1)*10^-decPl);
                                    uialert(uf,alertmsg,'Error')
                                    valErr = 1;
                                    input.BackgroundColor = '#EDB120';
                                    break
                                elseif str2double(cellPopScan{i,j})*10^-decPl > app.Rng(j,2)
                                    alertmsg = sprintf("Each value should not be more than %d",...
                                        app.Rng(j,2)*10^-decPl);
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
        
        function popUfDeleteFcn(app)
            % This function shows the base GUI when the GUI for ranges
            % is being deleted
            
            % Using modal for this second uifigure should be better but
            % modal is not available in MATLAB R2019b. I want to update
            % this part when I get a later version of MATLAB
            app.GeneticAlgorithmUIFigure.Visible = 'on';
        end
        
        function popUfCloseFcn(app,uf)
            % This function shows the base GUI when the GUI for ranges
            % has been deleted
            
            % Using modal for this second uifigure should be better but
            % modal is not available in MATLAB R2019b. I want to update
            % this part when I get a later version of MATLAB
            delete(uf);
            app.GeneticAlgorithmUIFigure.Visible = 'on';
        end
        
        function CurGen = cross(app,GenNo)
            popSize = app.PopulationSizeEditField.Value;
            strNo = app.StringsPerChromosomeEditField.Value;
            bits = app.BitsPerStringEditField.Value;
            CurGen = app.Gen(GenNo);
            CurGen.crossPairs = ones(popSize/2,2);
            for i = 1:popSize/2
                CurGen.crossPairs(i,:) = randi(popSize,1,2);
                repErr = 1;
                if i ~= 1
                    while repErr
                        check1 = CurGen.crossPairs(i,:) == CurGen.crossPairs(1:i-1,:);
                        check2 = CurGen.crossPairs(i,:) == CurGen.crossPairs(1:i-1,[2 1]);
                        check3 = CurGen.crossPairs(i,1) == CurGen.crossPairs(i,2);
                        if (any(all(check1,2)) || any(all(check2,2)) || check3)
                            CurGen.crossPairs(i,:) = randi(popSize,1,2);
                        else
                            repErr = 0;
                        end
                    end
                else
                    while repErr
                        if CurGen.crossPairs(i,1) == CurGen.crossPairs(i,2)
                            CurGen.crossPairs(i,:) = randi(popSize,1,2);
                        else
                            repErr = 0;
                        end
                    end
                end
            end
            CurGen.crossProbs = rand(popSize/2,strNo);
            if app.PointButton.Value
                CurGen.crossPoints = randi(bits-1,popSize/2,1);
            else
                CurGen.crossPoints = zeros(popSize/2,2);
                for j = 1:popSize/2
                    while CurGen.crossPoints(j,1) == CurGen.crossPoints(j,2)
                        genNums = randi(bits-1,popSize/2,2)-1;
                        CurGen.crossPoints(j,1) = max(genNums(j,:));
                        CurGen.crossPoints(j,2) = min(genNums(j,:));
                    end
                end
            end
            CurGen.doCross = CurGen.crossProbs <= app.CrossOverProbabilityEditField.Value;
            CurGen.crossedPop = strings(size(CurGen.initPop));
            for i = 1:size(CurGen.doCross,1)
                for j = 1:size(CurGen.doCross,2)
                    if CurGen.doCross(i,j)
                        a = char(CurGen.initPop(CurGen.crossPairs(i,1),j));
                        b = char(CurGen.initPop(CurGen.crossPairs(i,2),j));
                        c = a;
                        if app.PointButton.Value
                            a(end-CurGen.crossPoints(i)+1:end) = b(end-CurGen.crossPoints(i)+1:end);
                            b(end-CurGen.crossPoints(i)+1:end) = c(end-CurGen.crossPoints(i)+1:end);
                        else
                            a(end-CurGen.crossPoints(i,1)+1:end-CurGen.crossPoints(i,2)) = ...
                                b(end-CurGen.crossPoints(i,1)+1:end-CurGen.crossPoints(i,2));
                            b(end-CurGen.crossPoints(i,1)+1:end-CurGen.crossPoints(i,2)) = ...
                                c(end-CurGen.crossPoints(i,1)+1:end-CurGen.crossPoints(i,2));
                        end
                        if app.TypeofValuesDropDown.Value == 2
                            if str2double(a)*10^-app.DecimalPlacesEditField.Value < app.Rng(j,1)
                                CurGen.crossedPop(i*2-1,j) = sprintf("%0"+...
                                string(bits)+"d",app.Rng(j,1)*10^decPl);
                            elseif str2double(a)*10^-app.DecimalPlacesEditField.Value > app.Rng(j,2)
                                CurGen.crossedPop(i*2-1,j) = sprintf("%0"+...
                                string(bits)+"d",app.Rng(j,2)*10^decPl);
                            else
                                CurGen.crossedPop(i*2-1,j) = string(a);
                            end
                            if str2double(b)*10^-app.DecimalPlacesEditField.Value < app.Rng(j,1)
                                CurGen.crossedPop(i*2,j) = sprintf("%0"+...
                                string(bits)+"d",app.Rng(j,1)*10^decPl);
                            elseif str2double(b)*10^-app.DecimalPlacesEditField.Value > app.Rng(j,2)
                                CurGen.crossedPop(i*2,j) = sprintf("%0"+...
                                string(bits)+"d",app.Rng(j,2)*10^decPl);
                            else
                                CurGen.crossedPop(i*2,j) = string(b);
                            end
                        else
                            CurGen.crossedPop(i*2-1,j) = string(a);
                            CurGen.crossedPop(i*2,j) = string(b);
                        end
                    else
                        CurGen.crossedPop([i*2-1 i*2],j) = ...
                            CurGen.initPop([CurGen.crossPairs(i,1) CurGen.crossPairs(i,2)],j);
                    end
                end
            end
        end
        
        function CurGen = mutate(app,GenNo)
            popSize = app.PopulationSizeEditField.Value;
            strNo = app.StringsPerChromosomeEditField.Value;
            bits = app.BitsPerStringEditField.Value;
            decPl = app.DecimalPlacesEditField.Value;
            CurGen = app.Gen(GenNo);
            CurGen.mutPairs = ones(popSize/2,2);
            for i = 1:popSize/2
                CurGen.mutPairs(i,:) = randi(popSize,1,2);
                repErr = 1;
                if i ~= 1
                    while repErr
                        check1 = CurGen.mutPairs(i,:) == CurGen.mutPairs(1:i-1,:);
                        check2 = CurGen.mutPairs(i,:) == CurGen.mutPairs(1:i-1,[2 1]);
                        check3 = CurGen.mutPairs(i,1) == CurGen.mutPairs(i,2);
                        if (any(all(check1,2)) || any(all(check2,2)) || check3)
                            CurGen.mutPairs(i,:) = randi(popSize,1,2);
                        else
                            repErr = 0;
                        end
                    end
                else
                    while repErr
                        if CurGen.mutPairs(i,1) == CurGen.mutPairs(i,2)
                            CurGen.mutPairs(i,:) = randi(popSize,1,2);
                        else
                            repErr = 0;
                        end
                    end
                end
            end
            CurGen.mutProbs = rand(popSize/2,strNo);
            CurGen.mutPoints = randi(bits,popSize/2,1)-1;
            CurGen.doMutation = CurGen.mutProbs <= app.MutationProbabilityEditField.Value;
            CurGen.mutatedPop = strings(size(CurGen.crossedPop));
            for i = 1:size(CurGen.doMutation,1)
                for j = 1:size(CurGen.doMutation,2)
                    if CurGen.doMutation(i,j)
                        a = char(CurGen.crossedPop(CurGen.mutPairs(i,1),j));
                        b = char(CurGen.crossedPop(CurGen.mutPairs(i,2),j));
                        c = a;
                        a(end-CurGen.mutPoints(i)) = b(end-CurGen.mutPoints(i));
                        b(end-CurGen.mutPoints(i)) = c(end-CurGen.mutPoints(i));
                        if app.TypeofValuesDropDown.Value == 2
                            if str2double(a)*10^-decPl < app.Rng(j,1)
                                CurGen.mutatedPop(i*2-1,j) = sprintf("%0"+...
                                string(bits)+"d",app.Rng(j,1)*10^decPl);
                            elseif str2double(a)*10^-decPl > app.Rng(j,2)
                                CurGen.mutatedPop(i*2-1,j) = sprintf("%0"+...
                                string(bits)+"d",app.Rng(j,2)*10^decPl);
                            else
                                CurGen.mutatedPop(i*2-1,j) = string(a);
                            end
                            if str2double(b)*10^-decPl < app.Rng(j,1)
                                CurGen.mutatedPop(i*2,j) = sprintf("%0"+...
                                string(bits)+"d",app.Rng(j,1)*10^decPl);
                            elseif str2double(b)*10^-decPl > app.Rng(j,2)
                                CurGen.mutatedPop(i*2,j) = sprintf("%0"+...
                                string(bits)+"d",app.Rng(j,2)*10^decPl);
                            else
                                CurGen.mutatedPop(i*2,j) = string(b);
                            end
                        else
                            CurGen.mutatedPop(i*2-1,j) = string(a);
                            CurGen.mutatedPop(i*2,j) = string(b);
                        end
                    else
                        CurGen.mutatedPop([i*2-1 i*2],j) = ...
                            CurGen.crossedPop([CurGen.mutPairs(i,1) CurGen.mutPairs(i,2)],j);
                    end
                end
            end
        end
        
        function CurGen = evaluate(app,GenNo)
            popSize = app.PopulationSizeEditField.Value;
            strNo = app.StringsPerChromosomeEditField.Value;
            bits = app.BitsPerStringEditField.Value;
            decPl = app.DecimalPlacesEditField.Value;
            if GenNo == 0
                CurGen = app.GenZero;
            else
                CurGen = app.Gen(GenNo);
            end
            fitFunc = str2func("@("+strjoin("x"+string(1:strNo),',')+")"+...
                app.FunctionEditField.Value); %#ok<NASGU>
            CurGen.fx = zeros(popSize,1);
        
            if app.TypeofValuesDropDown.Value == 1
                CurGen.denVal = zeros(popSize,strNo);
                CurGen.decVal = zeros(popSize,strNo);
                for i = 1:popSize
                    for j = 1:strNo
                        CurGen.denVal(i,j) = bin2dec(CurGen.initPop(i,j));
                        CurGen.decVal(i,j) = app.Rng(j,1) + (app.Rng(j,2)-app.Rng(j,1))*...
                            CurGen.denVal(i,j)/(2^bits-1);
                    end
                    CurGen.fx(i) = eval("fitFunc("+strjoin(string(CurGen.decVal(i,:)),...
                        ',')+")");
                end
            else
                CurGen.decVal = zeros(popSize,strNo);
                for i = 1:popSize
                    for j = 1:strNo
                        CurGen.decVal(i,j) = str2double(CurGen.initPop(i,j))*10^-decPl;
                    end
                    CurGen.fx(i) = eval("fitFunc("+strjoin(string(CurGen.decVal(i,:)),...
                    ',')+")");
                end
            end
            if app.MinMaxDropDown.Value == 1
                CurGen.fit = 1./CurGen.fx;
            else
                CurGen.fit = CurGen.fx;
            end
        end
        
        function CurGen = select(app,GenNo)
            if GenNo == 0
                CurGen = app.GenZero;
            else
                CurGen = app.Gen(GenNo);
            end
            CurGen.cumFit = cumsum(CurGen.fit);
            [maxfit,ind] = max(CurGen.fit);
            if (GenNo==0)
                CurGen.bestFitTillNow = maxfit;
                CurGen.bestTillNow = CurGen.initPop(ind,:);
            elseif GenNo >= 2
                if maxfit >= app.Gen(GenNo-1).bestFitTillNow
                    CurGen.bestFitTillNow = maxfit;
                    CurGen.bestTillNow = CurGen.initPop(ind,:);
                else
                    CurGen.bestFitTillNow = app.Gen(GenNo-1).bestFitTillNow;
                    CurGen.bestTillNow = app.Gen(GenNo-1).bestTillNow;
                end
            else
                if maxfit >= app.GenZero.bestFitTillNow
                    CurGen.bestFitTillNow = maxfit;
                    CurGen.bestTillNow = CurGen.initPop(ind,:);
                else
                    CurGen.bestFitTillNow = app.GenZero.bestFitTillNow;
                    CurGen.bestTillNow = app.GenZero.bestTillNow;
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
        
        function print(app)
            format short
            option = 'Specify';
            while isequal(option,'Specify')
                [file,path] = uiputfile('GeneticAlgorithm.txt');
                option = '';
                if isequal(file,0) || isequal(path,0)
                    option = uiconfirm(app.GeneticAlgorithmUIFigure,'Could not save file, filename was not specified',...
                        'Error','Options',{'Specify','Cancel'},'Icon','warning','DefaultOption',1);
                end
            end
            if isequal(option,'')
                filename = fullfile(path,file);
                [fid,msg] = fopen(filename,'w');
                if fid == -1
                    uialert(app.GeneticAlgorithmUIFigure,msg,'Error')
                else
                    app.printhead(fid,"GENETIC ALGORITHM",2)
                    app.printhead(fid,"PARAMETERS",1);
                    if app.TypeofValuesDropDown.Value == 1
                        type = "Binary";
                    else
                        type = "Real";
                    end
                    fprintf(fid,"Type: %s\n",type);
                    fprintf(fid,"Population Size: %d\n",app.PopulationSizeEditField.Value);
                    fprintf(fid,"Strings Per Chromosomes: %d\n",app.StringsPerChromosomeEditField.Value);
                    fprintf(fid,"Bits Per String: %d\n",app.BitsPerStringEditField.Value);
                    if app.TypeofValuesDropDown.Value == 2
                        fprintf(fid,"Decimal Places: %d\n",app.DecimalPlacesEditField.Value);
                    end
                    if app.MinMaxDropDown.Value == 1
                        minMaxStr = "Min";
                    else
                        minMaxStr = "Max";
                    end
                    fprintf(fid,"Function: %s. %s\n",minMaxStr,app.FunctionEditField.Value);
                    if app.PointButton.Value
                        crossStr = "1-Point";
                    else
                        crossStr = "2-Points";
                    end
                    fprintf(fid,"Cross-Over Type: %s Cross-Over\n",crossStr);
                    if app.RolletteWheelButton.Value
                        selType = "Rollette Wheel";
                    else
                        selType = "Elitism";
                    end
                    fprintf(fid,"SelectionType: %s\n",selType);
                    fprintf(fid,"General Cross-Over Probability: %.2f\n",app.CrossOverProbabilityEditField.Value);
                    fprintf(fid,"General Mutation Probability: %.2f\n",app.MutationProbabilityEditField.Value);
                    fprintf(fid,"End at Generation: %d\n",app.StopatGenerationEditField.Value);
                    fprintf(fid,"Ranges for Strings (Min Max): %d %d\n",...
                        app.Rng(1,:));
                    if size(app.Rng,1) >= 2
                        fprintf(fid,"                              "+"%d %d\n",...
                            app.Rng(2:end,:)');
                    end
                    fprintf(fid,"Initial Population: %s\n",strjoin(app.Pop(1,:)));
                    if size(app.Pop,1) >= 2
                        fprintf(fid,"                    "+...
                            strjoin(repmat("%s",1,size(app.Pop,2))," ")+"\n",app.Pop(2:end,:)');
                    end
                    
                    app.printhead(fid,"GENERATION 0",2)
                    fprintf(fid,"Initial Population: ");
                    fprintf(fid,"%s\n",strjoin(app.GenZero.initPop(1,:)));
                    if size(app.GenZero.initPop,1) >= 2
                        for r = 2:size(app.GenZero.initPop,1)
                            fprintf(fid,"%s%s\n",strjoin(repmat(" ",1,20),""),...
                                strjoin(app.GenZero.initPop(r,:)));
                        end
                    end
                    
                    app.printhead(fid,"EVALUATION",1)
                    app.printeval(fid,app.GenZero)
                    app.printhead(fid,"SELECTION",1)
                    app.printsel(fid,app.GenZero)
                    
                    
                    closeFile = fclose(fid);
                    tryNum = 1;
                    while closeFile ~= 0 && tryNum <= 5
                        closeFile = fclose(fid);
                        tryNum = tryNum+1;
                    end
                    open(filename)
                end
            end
        end
        
        function printhead(~,fid,head,type)
            len = strlength(head);
            if type == 1
                line1 = "";
                line2 = sprintf("%s\n\n",strjoin(repmat("-",1,len),''));
            elseif type == 2
                line1 = sprintf("%s\n",strjoin(repmat("=",1,len),''));
                line2 = sprintf("%s\n\n",strjoin(repmat("=",1,len),''));
            end
            
            fprintf(fid,line1);
            fprintf(fid,head+"\n");
            fprintf(fid,line2);
        end
        
        function printeval(app,fid,CurGen)
            if app.TypeofValuesDropDown.Value == 1
                % This part is not working
                %fprintf(fid,table(CurGen.denVal,CurGen.decVal,...
                %    'VariableNames',["Denary Values" "Decoded Values"]));
                
                denValWid = 0;
                decValWid = 0;
                for row = 1:size(CurGen.denVal,1)
                    for col = 1:size(CurGen.denVal,2)
                        if strlength(sprintf("%d",CurGen.denVal(row,col))) > denValWid
                            denValWid = strlength(sprintf("%d",CurGen.denVal(row,col)));
                        end
                        if strlength(sprintf("%.4f",CurGen.decVal(row,col))) > decValWid
                            decValWid = strlength(sprintf("%.4f",CurGen.decVal(row,col)));
                        end
                    end
                end
                
                smallDenVal = false;
                smallDecVal = false;
                denValLineWid = size(CurGen.denVal,2)*(denValWid+2)-2;
                if denValLineWid < 13
                    denValLineWid = 13;
                    smallDenVal = true;
                end
                
                decValLineWid = size(CurGen.decVal,2)*(decValWid+2)-2;
                if decValLineWid < 14
                    decValLineWid = 14;
                    smallDecVal = true;
                end
                beg = strjoin(repmat(" ",1,floor((denValLineWid-13)/2)),"");
                mid = strjoin(repmat(" ",1,ceil((denValLineWid-13)/2)),"")+...
                    "    "+strjoin(repmat(" ",1,floor((decValLineWid-14)/2)),"");
                fprintf(fid,"%sDenary Values%sDecoded Values\n",beg,mid);
                fprintf(fid,"%s    %s\n",strjoin(repmat("_",1,denValLineWid),""),...
                    strjoin(repmat("_",1,decValLineWid),""));
                
                denValForm = strjoin(repmat("%"+string(denValWid)+...
                        "d",1,size(CurGen.denVal,2)),"  ");
                decValForm = strjoin(repmat("%"+string(decValWid)+...
                        ".4f",1,size(CurGen.decVal,2)),"  ");
                if smallDenVal && smallDecVal
                    for row = 1:size(CurGen.denVal,1)
                        denLine = sprintf(denValForm,CurGen.denVal(row,:));
                        decLine = sprintf(decValForm,CurGen.decVal(row,:));
                        fprintf(fid,"%13s    %14s\n",denLine,decLine);
                    end                
                elseif smallDenVal && ~smallDecVal
                    for row = 1:size(CurGen.denVal,1)
                        denLine = sprintf(denValForm,CurGen.denVal(row,:));
                        decLine = sprintf(decValForm,CurGen.decVal(row,:));
                        fprintf(fid,"%13s    %s\n",denLine,decLine);
                    end
                elseif ~smallDenVal && smallDecVal
                    for row = 1:size(CurGen.denVal,1)
                        denLine = sprintf(denValForm,CurGen.denVal(row,:));
                        decLine = sprintf(decValForm,CurGen.decVal(row,:));
                        fprintf(fid,"%s    %14s\n",denLine,decLine);
                    end
                else
                    for row = 1:size(CurGen.denVal,1)
                        fprintf(fid,denValForm+"    "+decValForm+"\n",CurGen.denVal(row,:),...
                            CurGen.decVal(row,:));
                    end
                end
                fprintf(fid,"\n");
            end
            
            fxWid = 0;
            fitWid = 0;
            cumFitWid = 0;
            for row = 1:length(CurGen.fx)
            if strlength(sprintf("%.2f",CurGen.fx(row))) > fxWid
                fxWid = strlength(sprintf("%.2f",CurGen.fx(row)));
            end
             if strlength(sprintf("%.6f",CurGen.fit(row))) > fitWid
                fitWid = strlength(sprintf("%.6f",CurGen.fit(row)));
            end
            if strlength(sprintf("%.7f",CurGen.cumFit(row))) > cumFitWid
                cumFitWid = strlength(sprintf("%.7f",CurGen.cumFit(row)));
            end                
            end
            
            beg = strjoin(repmat(" ",1,floor((fxWid-4)/2)),"");
            mid1 = strjoin(repmat(" ",1,ceil((fxWid-4)/2)),"")+...
            strjoin(repmat(" ",1,floor((fitWid-7)/2)),"")+"    ";
            mid2 = strjoin(repmat(" ",1,ceil((fitWid-7)/2)),"")+...
            strjoin(repmat(" ",1,floor((cumFitWid-9)/2)),"")+"    ";
            fprintf(fid,"%sf(x)%sFitness%sCum. Fit.\n",beg,mid1,mid2);
            fprintf(fid,"%s    %s    %s\n",strjoin(repmat("_",1,fxWid),""),...
            strjoin(repmat("_",1,fitWid),""),strjoin(repmat("_",1,cumFitWid),""));
            fxForm = "%"+string(fxWid)+".2f";
            fitForm = "%"+string(fitWid)+".6f";
            cumFitForm = "%"+string(cumFitWid)+".7f";
            for i = 1:size(CurGen.fx,1)
            fprintf(fid,fxForm+"    "+fitForm+"    "+cumFitForm+"\n",...
                CurGen.fx(i),CurGen.fit(i),CurGen.cumFit(i));
            end
            fprintf(fid,"\n");
        end
        
        function printsel(~,fid,CurGen)
            fprintf(fid,"The randomly selected chromosomes are: %s\n",strjoin(string(CurGen.selChroms)));
            fprintf(fid,"The best chromosome till date is: %s\n",strjoin(CurGen.bestTillNow));
            fprintf(fid,"with fitness: %s\n",string(CurGen.bestFitTillNow));
        end
    end

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)
            
            strNo = app.StringsPerChromosomeEditField.Value;
            
            decPlField = app.DecimalPlacesEditField;
            
            bits = app.BitsPerStringEditField.Value;
            
            % Hide the figure while startupFcn executes
            app.GeneticAlgorithmUIFigure.Visible = 'off';
            
            % Track dropdown value with itemsdata
            app.TypeofValuesDropDown.ItemsData =  [1 2];
            
            % Set upper limit of decimal places to number of bits
            decPlField.Limits = [0 bits];
            
            % Enable setting decimal place if dropdown value is 2 (real)
            % otherwise disable
            if (app.TypeofValuesDropDown.Value == 2)
                decPlField.Enable = 1;
            else
                decPlField.Enable = 0;
            end
            
            % Set ranges to default 0-10 values
            if (app.TypeofValuesDropDown.Value == 1)
                app.Rng = repmat([0 10],strNo,1);
            else
                app.Rng = repmat([0 (10^bits-1)*10^-decPlField.Value],strNo,1);
            end
            
            % Raise error for Range and Population so that user will have
            % to set it
            % app.RngPopErr();
            
            % Track minMax value with itemsdata
            app.MinMaxDropDown.ItemsData =  [1 2];
            
            % Set tooltip for function
            app.FunctionEditField.Tooltip = "Variables: x1-x"+string(strNo)+...
                ". Operators:  +-*/^";
            
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
            app.FunctionEditField.Tooltip = "Variables: x1-x"+string(value)+". Operators:  +-*/^";
            
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
            
            bits = app.BitsPerStringEditField.Value;
            
            decPl = app.DecimalPlacesEditField.Value;
            
            % If ranges is not set use default values
            if isempty(app.Rng)
                if (app.TypeofValuesDropDown.Value == 1)
                    app.Rng = repmat([0 10],strNum,1);
                else
                    app.Rng = repmat([0 (10^bits-1)*10^-decPl],strNum,1);
                end
            end
            
            % If there are no last valid values use default values
            if isempty(app.LastRng)
                if (app.TypeofValuesDropDown.Value == 1)
                    app.LastRng = repmat([0 10],strNum,1);
                else
                    app.LastRng = repmat([0 (10^bits-1)*10^-decPl],strNum,1);
                end
            end
            
            % Variable for tracking error in this function
            %valErr = 0;
            
            % create UI figure (uf) to set ranges but do not show till setup finishes
            uf = uifigure('Name','Ranges','Position',[100 100 560 420], ...
                'Scrollable','on','DeleteFcn',@(uf,event) app.rngUfDeleteFcn(), ...
                'CloseRequestFcn',@(uf,event) app.rngUfCloseFcn(uf),'Visible','off');
            
            % Set each line (range) in ranges as a string in cell array cellRng
            cellRng = app.RngCell();
            
            % Input instruction
            labelmsg = sprintf("Input values in each row for the respective strings."+...
                "\nFormat: min max");
            uilabel(uf,'Position',[56 356 448 28],'Text',labelmsg);
            
            % User input values area
            input = uitextarea(uf,'Position',[56 42 224 294],...
                'Value',cellRng);
            
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
                'ButtonPushedFcn',@(btn,event) app.checkRngVal(uf,input));
            
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
                        
            % Get number of strings
            strNum = app.StringsPerChromosomeEditField.Value;
            
            % Get the number of bits per string
            bitNum = app.BitsPerStringEditField.Value;
            
            % If Population is empty make cellPopOut empty otherwise save
            % each line of the Population as an element in cellPopOut
            if app.Pop == ""
                cellPopOut = '';
            else
                cellPopOut = app.PopLines();
            end
            
            % If last valid Population is empty make it equal to cellPopOut
            if app.LastPop == ""
                app.LastPop = cellPopOut;
            end

            % Create UI figure (uf) to set set initial population but do
            % not show till setup finishes
            uf = uifigure('Name','Initial Population','Position',...
                [100 100 616 420],'Scrollable','on','DeleteFcn',...
                @(uf,event) app.popUfDeleteFcn(),'CloseRequestFcn',...
                @(uf,event) app.popUfCloseFcn(uf),'Visible','off');

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
                'ButtonPushedFcn',@(btn,event) app.ResetPopVal(1,input));
            
            % Last valid Population button
            uibutton(uf,'push','Text','Last Valid Pop.',...
                'Position',[448 178 112 22],...
                'ButtonPushedFcn',@(btn,event) app.ResetPopVal(2,input));
            
            % Set button
            uibutton(uf,'push','Text','Set',...
                'Position',[448 84 112 22],'BackgroundColor','#4DBEEE',...
                'ButtonPushedFcn',@(btn,event) app.set(uf,input));
            
            % Center GUI for setting Population
            movegui(uf,'center')
            
            % Hide base GUI
            % When I get a later version of MATLAB using modal should be
            % better than hiding the figure
            app.GeneticAlgorithmUIFigure.Visible = 'off';
            
            % Show GUI for setting ranges
            uf.Visible = 'on';
        end

        % Value changed function: FunctionEditField
        function FunctionEditFieldValueChanged(app, event)
            value = regexprep(app.FunctionEditField.Value,'\s','');
            
            value = regexprep(value,'X','x');
            
            app.FunctionEditField.Value = value;
            
            % Get number of strings
            strNum = app.StringsPerChromosomeEditField.Value;
            
            % expr is a regular expression to check the function
            expr = "[-+]?(?:x["+strjoin(string(1:strNum),'')+"])(?:[+*/^-]x["+...
                strjoin(string(1:strNum),'')+"])*";
            
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
                app.GenZero = struct('initPop',app.Pop,'denVal',[],'decVal',[],'fx',[],...
                    'fit',[],'cumFit',[],'selChroms',[],'bestTillNow',"",'bestFitTillNow',[],...
                    'finalPop',[]);
                
                app.GenZero = app.evaluate(0);
                app.GenZero = app.select(0);
                
                app.Gen(app.StopatGenerationEditField.Value) = struct('initPop',"",...
                    'crossPairs',[],'crossProbs',[],'crossPoints',[],'doCross',[],...
                    'crossedPop',[],'mutPairs',[],'mutProbs',[],'mutPoints',[],...
                    'doMutation',[],'mutatedPop',[],'denVal',[],'decVal',[],'fx',[],...
                    'fit',[],'cumFit',[],'selChroms',[],'bestTillNow',"",...
                    'bestFitTillNow',[],'finalPop',[]);
                
                for GenNo = 1:app.StopatGenerationEditField.Value
                    if GenNo == 1
                        app.Gen(GenNo).initPop = app.GenZero.finalPop;
                    else
                        app.Gen(GenNo).initPop = app.Gen(GenNo-1).finalPop;
                    end
                    
                    app.Gen(GenNo) = app.cross(GenNo);
                    app.Gen(GenNo) = app.mutate(GenNo);
                    app.Gen(GenNo) = app.evaluate(GenNo);
                    app.Gen(GenNo) = app.select(GenNo);
                end
            end
                      
            % Up next- Print Ouput
            % To-Do: use uiputfile for filename and directory
            app.print()
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
            app.PopulationSizeEditField.UpperLimitInclusive = 'off';
            app.PopulationSizeEditField.Limits = [2 Inf];
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
            app.StringsPerChromosomeEditField.UpperLimitInclusive = 'off';
            app.StringsPerChromosomeEditField.Limits = [1 Inf];
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
            app.BitsPerStringEditField.Limits = [1 14];
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