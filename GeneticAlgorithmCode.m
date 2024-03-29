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
        % Initial Generation
        GenZero = struct('initPop',"",'denVal',[],'decVal',[],'fx',[],...
                    'fit',[],'cumFit',[],'selChroms',[],'bestTillNow',"",'bestFitTillNow',[],...
                    'finalPop',[]);
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
            
            % Get the number of strings per chromosomes
            strNum = app.StringsPerChromosomeEditField.Value;
            
            % Get the number of bits per chromosome
            bits = app.BitsPerStringEditField.Value;
            
            % Get the number of decimal places
            decPl = app.DecimalPlacesEditField.Value;
            
            if val == 1
                if (app.TypeofValuesDropDown.Value == 1)
                    app.Rng = repmat([0 10],strNum,1);
                else
                    app.Rng = repmat([0 (10^bits-1)*10^-decPl],strNum,1);
                end
            elseif val == 2
                if size(app.LastRng,1) < strNum
                    if (app.TypeofValuesDropDown.Value == 1)
                        app.Rng = [app.LastRng; repmat([0 10],...
                            strNum-size(app.LastRng,1),1)];
                    else
                        app.Rng = [app.LastRng; repmat([0 (10^bits-1)*10^-decPl],...
                            strNum-size(app.LastRng,1),1)];
                    end
                elseif size(app.LastRng,1) > strNum
                    app.Rng = app.LastRng(1:strNum,:);
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
            
            % Get the number of strings per chromosomes
            strNum = app.StringsPerChromosomeEditField.Value;
            
            % Get the number of bits per strings
            bits = app.BitsPerStringEditField.Value;
            
            % get the number of decimal places
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
                            alertmsg = "Each max should be lesser than "+...
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
                    
                    % change the input background to white
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
            % a string in the output cell array (cellPop) if app.Pop is not
            % empty
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
            
            % get the number of decimal places
            decPl = app.DecimalPlacesEditField.Value;
        
            if val == 1
            % Set random population according to the type (binary or real)
                if type == 1
                % Type is binary
                    % Generate random numbers where the maximum value is
                    % the maximum value a binary number with bitNum digits
                    % can have and the lowest possible value is zero
                    randInts = randi([0 2^bitNum-1],chromNum,strNum);
                else
                % Type is real
                    randInts = zeros(chromNum,strNum);
                    for i = 1:strNum
                        % Check each range if the value is higher than the
                        % highest possible value make the up limit the highest
                        % possible value else make the up limit equal to the
                        % range
                        if (10^bitNum-1) <= round(app.Rng(i,2)*10^decPl)
                            upLim = 10^bitNum-1;
                        else
                            upLim = round(app.Rng(i,2)*10^decPl);
                        end
                        
                        % Make the down limit the min of the ranges
                        downLim = round(app.Rng(i,1)*10^decPl);
                        
                        % Generate random numbers for each column (string)
                        % between uplim and downlim for such column
                        randInts(:,i) = randi([downLim upLim],chromNum,1);
                    end
                end
                
                % Empty Pop having the required size
                app.Pop = strings(chromNum,strNum);
                
                % Fill each element in the population with binary values of
                % the randomly generated numbers (ranInts) each filled
                % element in the population has number of digits equal to
                % the number of bits specified
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
            % Set last valid population if it exists
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
            
            % Make the input background white
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
            
            % Get the number of decimalplaces
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
                    
                    if isempty(start) && isempty(last)
                    % current line does not match expr
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
                        
                        % If type is one do not check if the values are
                        % within the specified ranges else (type is real)
                        % check 
                        if type == 1
                            valErr = 0;
                            input.BackgroundColor = '#fff';
                        elseif type == 2
                            for j = 1:size(cellPopScan(i,:),2)
                                if str2double(cellPopScan{i,j})*10^-decPl < app.Rng(j,1)
                                % An element in the population is lesser
                                % than the min range for the string it
                                % belongs
                                    alertmsg = sprintf("Each value should be more than %d",...
                                        app.Rng(j,1)*10^-decPl);
                                    uialert(uf,alertmsg,'Error')
                                    valErr = 1;
                                    input.BackgroundColor = '#EDB120';
                                    break
                                elseif str2double(cellPopScan{i,j})*10^-decPl > app.Rng(j,2)
                                % An element in the population is more than
                                % the max range for the string it belongs 
                                    alertmsg = sprintf("Each value should be lesser than %d",...
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
                        
                        % If error was raised stop checking the inputs
                        if valErr
                            break
                        end
                    else
                    % current line matches expr partly
                        alertmsg = sprintf("Format: Input %d %d-digit numbers"+...
                            "%s\nfor each chromosome (row)",strNum,bitNum,labelend);
                        uialert(uf,alertmsg,'Error')
                        valErr = 1;
                        input.BackgroundColor = '#EDB120';
                        break
                    end
                end
                if ~valErr
                % if no error occurs
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
        
        function CurGen = cross(app,GenNo)
            % This function does the crossover anywhere required
            
            % Get the population size
            popSize = app.PopulationSizeEditField.Value;
            
            % Get the number of strings
            strNo = app.StringsPerChromosomeEditField.Value;
            
            % Get the number of bits
            bits = app.BitsPerStringEditField.Value;
            
            % Get the generation to work on according to the number
            % specified in the function call
            CurGen = app.Gen(GenNo);
            
            % Pair the chromosomes randomly. The number of pairs would be
            % half the population size. If a pair A&B has been chosen no
            % other pair A&B or B&A should be chosen but each can still be
            % paired with any other chromosome i.e. A&C would be valid
            % likewise D&B
            CurGen.crossPairs = ones(popSize/2,2);
            for i = 1:popSize/2
                % Get a random pair of the chromosoms
                CurGen.crossPairs(i,:) = randi(popSize,1,2);
                
                % Track pairing error
                repErr = 1;
                if i ~= 1
                % The current pairing is not the first
                    while repErr
                        % Check if current pairing exist ealier
                        check1 = CurGen.crossPairs(i,:) == CurGen.crossPairs(1:i-1,:);
                        
                        % Check if current pairing exists ealier in reverse
                        check2 = CurGen.crossPairs(i,:) == CurGen.crossPairs(1:i-1,[2 1]);
                        
                        % Check if the current pairing is same i.e. having
                        % A&A
                        check3 = CurGen.crossPairs(i,1) == CurGen.crossPairs(i,2);
                        
                        if (any(all(check1,2)) || any(all(check2,2)) || check3)
                            % If there is any pairing error pair again
                            CurGen.crossPairs(i,:) = randi(popSize,1,2);
                        else
                            % If there are no pairing error break out from
                            % pairing again
                            repErr = 0;
                        end
                    end
                else
                % The current pairing is the first
                    while repErr
                        if CurGen.crossPairs(i,1) == CurGen.crossPairs(i,2)
                            % Check if the current pairing is same i.e. having
                            % A&A if so repair
                            CurGen.crossPairs(i,:) = randi(popSize,1,2);
                        else
                            % If no pairing error do not pair again
                            repErr = 0;
                        end
                    end
                end
            end
            
            % Generate random cross-over probabilty for each pairs. A
            % probabilty should be generated for each strings i.e. each
            % pairs should have number of probabilities equal to the number
            % of strings
            CurGen.crossProbs = rand(popSize/2,strNo);
            
            % If the cross-over type is 1-point crossover generate one
            % crossover point for each pair else (if cross-over type is
            % 2-points cross-over) generate two cross-over points for each
            % pair both points must not be the same
            if app.PointButton.Value
                CurGen.crossPoints = randi(bits-1,popSize/2,1);
            else
                CurGen.crossPoints = zeros(popSize/2,2);
                for j = 1:popSize/2
                    while CurGen.crossPoints(j,1) == CurGen.crossPoints(j,2)
                        genNums = randi(bits,1,2)-1;
                        CurGen.crossPoints(j,1) = max(genNums);
                        CurGen.crossPoints(j,2) = min(genNums);
                    end
                end
            end
            
            % Check where the cross-over probability generated is lesser
            % than the specified general cross-over probability from onset.
            % If the cross-over probability generated is lesser than the
            % general cross-over probability for a string pair, there would
            % be cross-over for such string pair
            CurGen.doCross = CurGen.crossProbs <= app.CrossOverProbabilityEditField.Value;
            
            % Do cross-over where required
            CurGen.crossedPop = strings(size(CurGen.initPop));
            for i = 1:size(CurGen.doCross,1)
            % Loop through pairs
                for j = 1:size(CurGen.doCross,2)
                % Loop through strings
                    if CurGen.doCross(i,j)
                    % Current string pairs meet the criteria for cross-over
                        a = char(CurGen.initPop(CurGen.crossPairs(i,1),j));
                        b = char(CurGen.initPop(CurGen.crossPairs(i,2),j));
                        c = a;
                        if app.PointButton.Value
                            % If type of cross-over is 1-point, exchange the
                            % bits (digits) from the right up to the cross-over
                            % point
                            a(end-CurGen.crossPoints(i)+1:end) = b(end-CurGen.crossPoints(i)+1:end);
                            b(end-CurGen.crossPoints(i)+1:end) = c(end-CurGen.crossPoints(i)+1:end);
                        else
                            % If the type of cross-over is 2-points,
                            % exchange the bits (digits) between the cross
                            % points. Counting is from the left i.e. if 2 &
                            % 0 are generated, the last two digits would be
                            % exchanged likewise if 4 & 1 are generated the
                            % 3 digits before the last digit are exchanged
                            a(end-CurGen.crossPoints(i,1)+1:end-CurGen.crossPoints(i,2)) = ...
                                b(end-CurGen.crossPoints(i,1)+1:end-CurGen.crossPoints(i,2));
                            b(end-CurGen.crossPoints(i,1)+1:end-CurGen.crossPoints(i,2)) = ...
                                c(end-CurGen.crossPoints(i,1)+1:end-CurGen.crossPoints(i,2));
                        end
                        
                        % If the type of value is real, check wether the
                        % values have gone more or less than the max range
                        % and min range respectively. If a value goes more
                        % than the max range it is set to max range else if
                        % it goes below min range it is set to min range
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
                        % No checking is needed if the type of value is
                        % binary
                        CurGen.crossedPop([i*2-1 i*2],j) = ...
                            CurGen.initPop([CurGen.crossPairs(i,1) CurGen.crossPairs(i,2)],j);
                    end
                end
            end
        end
        
        function CurGen = mutate(app,GenNo)
            % This function does mutation where neccesary
            
            % Get the population size
            popSize = app.PopulationSizeEditField.Value;
            
            % Get the number of chromosomes
            strNo = app.StringsPerChromosomeEditField.Value;
            
            % Get the number of bits per chromosome
            bits = app.BitsPerStringEditField.Value;
            
            % Get the number of decimal places
            decPl = app.DecimalPlacesEditField.Value;
            
            % Get the generation to work on according to the number
            % specified in the function call
            CurGen = app.Gen(GenNo);
            
            % Pair the chromosomes randomly. The number of pairs would be
            % half the population size. If a pair A&B has been chosen no
            % other pair A&B or B&A should be chosen but each can still be
            % paired with any other chromosome i.e. A&C would be valid
            % likewise D&B
            CurGen.mutPairs = ones(popSize/2,2);
            for i = 1:popSize/2
                % Get a random pair of the chromosomes
                CurGen.mutPairs(i,:) = randi(popSize,1,2);
                
                % Track pairing error
                repErr = 1;
                if i ~= 1
                % The current pairing is not the first
                    while repErr
                        % Check if current pairing exist ealier
                        check1 = CurGen.mutPairs(i,:) == CurGen.mutPairs(1:i-1,:);
                        
                        % Check if current pairing exists ealier in reverse
                        check2 = CurGen.mutPairs(i,:) == CurGen.mutPairs(1:i-1,[2 1]);
                        
                        % Check if the current pairing is same i.e. having
                        % A&A
                        check3 = CurGen.mutPairs(i,1) == CurGen.mutPairs(i,2);
                        if (any(all(check1,2)) || any(all(check2,2)) || check3)
                            % If there is any pairing error pair again
                            CurGen.mutPairs(i,:) = randi(popSize,1,2);
                        else
                            % If there are no pairing error break out from
                            % pairing again
                            repErr = 0;
                        end
                    end
                else
                % The current pairing is the first
                    while repErr
                        if CurGen.mutPairs(i,1) == CurGen.mutPairs(i,2)
                            % Check if the current pairing is same i.e. having
                            % A&A if so repair
                            CurGen.mutPairs(i,:) = randi(popSize,1,2);
                        else
                            % If no pairing error do not pair again
                            repErr = 0;
                        end
                    end
                end
            end
            
            % Generate random mutation probabilty for each pairs. A
            % probabilty should be generated for each strings i.e. each
            % pairs should have number of probabilities equal to the number
            % of strings
            CurGen.mutProbs = rand(popSize/2,strNo);
            
            % Generated a random mutation point between 1 and bits
            CurGen.mutPoints = randi(bits,popSize/2,1);
            
            % Check where the mutation probability generated is lesser
            % than the specified general mutation probability from onset.
            % If the mutation probability generated is lesser than the
            % general mutation probability for a string pair, there would
            % be mutation for such string pair
            CurGen.doMutation = CurGen.mutProbs <= app.MutationProbabilityEditField.Value;
            
            % Mutate where required
            CurGen.mutatedPop = strings(size(CurGen.crossedPop));
            for i = 1:size(CurGen.doMutation,1)
            % Loop through pairs
                for j = 1:size(CurGen.doMutation,2)
                % Loop through strings
                    if CurGen.doMutation(i,j)
                    % Current string pairs meet the criteria for mutation
                        a = char(CurGen.crossedPop(CurGen.mutPairs(i,1),j));
                        b = char(CurGen.crossedPop(CurGen.mutPairs(i,2),j));
                        c = a;
                        
                        % Exchange the bits (digits) from the right up to
                        % the mutation point
                        a(end-CurGen.mutPoints(i)+1) = b(end-CurGen.mutPoints(i)+1);
                        b(end-CurGen.mutPoints(i)+1) = c(end-CurGen.mutPoints(i)+1);
                        
                        % If the type of value is real, check wether the
                        % values have gone more or less than the max range
                        % and min range respectively. If a value goes more
                        % than the max range it is set to max range else if
                        % it goes below min range it is set to min range
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
                        % No checking is needed if the type of value is
                        % binary
                            CurGen.mutatedPop(i*2-1,j) = string(a);
                            CurGen.mutatedPop(i*2,j) = string(b);
                        end
                    else
                    % No mutation
                        CurGen.mutatedPop([i*2-1 i*2],j) = ...
                            CurGen.crossedPop([CurGen.mutPairs(i,1) CurGen.mutPairs(i,2)],j);
                    end
                end
            end
        end
        
        function CurGen = evaluate(app,GenNo)
            % This function evaluates the the generation corresponding to
            % GenNo
            
            % Get the population size
            popSize = app.PopulationSizeEditField.Value;
            
            % Get the number of strings per chromosome
            strNo = app.StringsPerChromosomeEditField.Value;
            
            % get the number of bits per chromosomes
            bits = app.BitsPerStringEditField.Value;
            
            % Get the number of decimal places
            decPl = app.DecimalPlacesEditField.Value;
            
            % If the GenNo is 0, work on Genzero else work on the the
            % specified generation in Gen
            if GenNo == 0
                CurGen = app.GenZero;
            else
                CurGen = app.Gen(GenNo);
            end
            
            % Covert the user specified function to an anonymous function
            % that can be worked with
            fitFunc = str2func("@("+strjoin("x"+string(1:strNo),',')+")"+...
                app.FunctionEditField.Value); %#ok<NASGU>
            
            % Get the function value for each chromosome. If type is binary
            % get denary values (denVal) and decoded values (decVal) first
            % else if type is real just get the decoded values (decVal)
            % first denary values are not needed
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
            
            % If the objective is minimization the fitness of each
            % chromosome is the reciprocal of the function value else if
            % the objective is maximization the fitness is same as the
            % function value
            if app.MinMaxDropDown.Value == 1
                CurGen.fit = 1./CurGen.fx;
            else
                CurGen.fit = CurGen.fx;
            end
        end
        
        function CurGen = select(app,GenNo)
            % This function performs the selection of chromosomes to the
            % next generation
            
            % If the GenNo is 0, work on Genzero else work on the the
            % specified generation in Gen
            if GenNo == 0
                CurGen = app.GenZero;
            else
                CurGen = app.Gen(GenNo);
            end
            
            % Get the cummulative fitness
            CurGen.cumFit = cumsum(CurGen.fit);
            
            % Get the maxi fitness for this generation as well as the
            % chromosome having the max fitness
            [maxfit,ind] = max(CurGen.fit);
            
            % Update the best chromosome and best fitness till now if
            % neccesary
            if (GenNo==0)
                % For the initial generation the best chromosome and
                % fitness are the best till date
                CurGen.bestFitTillNow = maxfit;
                CurGen.bestTillNow = CurGen.initPop(ind,:);
            elseif GenNo >= 2
            % Gen 2 upwards
                % If the current best is better than the best till the
                % generation before update the best else the best remains
                % the best
                if maxfit >= app.Gen(GenNo-1).bestFitTillNow
                    CurGen.bestFitTillNow = maxfit;
                    CurGen.bestTillNow = CurGen.initPop(ind,:);
                else
                    CurGen.bestFitTillNow = app.Gen(GenNo-1).bestFitTillNow;
                    CurGen.bestTillNow = app.Gen(GenNo-1).bestTillNow;
                end
            else
                % If the current best is better than the best in generation
                % zero update the best else the best remains the best
                if maxfit >= app.GenZero.bestFitTillNow
                    CurGen.bestFitTillNow = maxfit;
                    CurGen.bestTillNow = CurGen.initPop(ind,:);
                else
                    CurGen.bestFitTillNow = app.GenZero.bestFitTillNow;
                    CurGen.bestTillNow = app.GenZero.bestTillNow;
                end
            end
            
            % Next select the chromosomes going to the next generation
            CurGen.finalPop = strings(size(CurGen.initPop));
            
            % Get the sort  indices for sorting the chromosomes according
            % to their fitness
            [~,sortInd] = sort(CurGen.fit);
            
            % If selection type is rollette wheel or the number of
            % chromosomes is not more than 2 randomly select the
            % chromosomes. A chromosome may appear more than once
            if (app.RolletteWheelButton.Value || length(sortInd) <= 2)
                CurGen.selChroms = randi(length(sortInd),1,length(sortInd));
            else
            % The selection type is elitism
                if (length(sortInd) == 3 || length(sortInd) == 4)
                    % If the number of chromosomes is 3 or 4 pick the best
                    % and the worst then randomly pick the rest
                    CurGen.selChroms = ones(1,length(sortInd));
                    CurGen.selChroms([1 2]) = sortInd([end 1]);
                    CurGen.selChroms(3:end) = randi(length(sortInd),1,length(sortInd)-2);
                else
                    % If the number of chromosomes is more than 4 pick the
                    % best two then the best two then randomly pick the
                    % rest
                    CurGen.selChroms = ones(1,length(sortInd));
                    CurGen.selChroms(1:4) = sortInd([end end-1 1 2]);
                    CurGen.selChroms(5:end) = randi(length(sortInd),1,length(sortInd)-4);
                end
            end
            % get the final population to be transferred to the next
            % generation by using the indices of the selected chromosomes
            % to index into the initial chromosome for this generation
            CurGen.finalPop = CurGen.initPop(CurGen.selChroms,:);
        end
        
        function print(app)
            % This function prints the results of the genetic algorithm in
            % a text file. All printed texts are spaced for readability
            % when required
            
            % Display values in the short format unless stated otherwise
            format short
            
            % Get the filename and location if nothing was specified ask
            % the user to either specify or cancel the printing
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
            % Filename and directory has been specified
                
                % Try creating file or overwrite if it exists
                filename = fullfile(path,file);
                [fid,msg] = fopen(filename,'w','n','UTF-8');
                
                % If file cannot be open raise error else continue to
                % printing
                if fid == -1
                    uialert(app.GeneticAlgorithmUIFigure,msg,'Error')
                else
                    % Print header
                    app.printhead(fid,"GENETIC ALGORITHM",2)
                    
                    % Print info
                    app.printhead(fid,"INFO",1)
                    fprintf(fid,"This file is encoded in UTF-8, it is best to open in a UTF-8 supported viewer.");
                    fprintf(fid,"\n\n\n");
                    
                    % Print parameters
                    app.printparams(fid)
                    
                    % % Print heading for generation zero                    
                    app.printhead(fid,"GENERATION 0",2)
                    
                    % Print initial population of generation zero
                    app.printpop(fid,0,1)
                    
                    % Print evaluation of generation zero
                    app.printeval(fid,0)
                    
                    % Print selection of generation zero
                    app.printsel(fid,0)
                    
                    % Print population at the end of generation zero
                    app.printpop(fid,0,2)
                    
                    for GenNo = 1:app.StopatGenerationEditField.Value
                        
                        % Print heading for generation GenNo
                        app.printhead(fid,"GENERATION "+string(GenNo),2)
                        
                        % Print initial population of generation zero
                        app.printpop(fid,GenNo,1)
                        
                        % Print cross-over of generation GenNo
                        app.printcross(fid,GenNo)
                        
                        % Print mutation of generation GenNo
                        app.printmut(fid,GenNo)
                        
                        % Print evaluation of generation GenNo
                        app.printeval(fid,GenNo)
                        
                        % Print selection of generation GenNo
                        app.printsel(fid,GenNo)
                        
                        % Print population at the end of generation zero
                        app.printpop(fid,GenNo,2)
                    end
                    
                    % Add a note to join the discussion for this project on
                    % github
                    fprintf(fid,"\n\n");
                    fprintf(fid,"==========================================================================\n");
                    fprintf(fid,"If you found any bug or have any observation, comment, recommendation etc.\n");
                    fprintf(fid,"You can join the discussion for this project on gihub with the link below:\n");
                    fprintf(fid,"https://github.com/usmanadaudu/GeneticAlgorithmApp/discussions");
                    % Print footer
                    fprintf(fid,"\n\n-----------\n");
                    fprintf(fid,"End of file");
                    
                    % close file
                    closeFile = fclose(fid);
                    
                    % If file could not be closed try 4 more times
                    tryNum = 1;
                    while closeFile ~= 0 && tryNum <= 5
                        closeFile = fclose(fid);
                        tryNum = tryNum+1;
                    end
                    
                    % Open the text file
                    open(filename)
                end
            end
        end
        
        function printhead(~,fid,head,type)
            % This function prints headings (type = 2) and sub-headings
            % (type = 1).
            
            % Get the length of string to work on
            len = strlength(head);
            
            if type == 1
            % Sub-heading
                % Print nothing above it
                line1 = "";
                
                % Print dashed lines with length equal to the length of the
                % string below it
                line2 = sprintf("%s\n\n",strjoin(repmat("-",1,len),''));
            elseif type == 2
            % Heading
                % Print double dashed lines with length equal to the length
                % of the string above it
                line1 = sprintf("%s\n",strjoin(repmat("=",1,len),''));
                
                % Also print double dashed lines with length equal to the
                % length of the string below it
                line2 = sprintf("%s\n\n",strjoin(repmat("=",1,len),''));
            end
            
            fprintf(fid,line1);
            fprintf(fid,head+"\n");
            fprintf(fid,line2);
        end
        
        function printparams(app,fid)
            
            % Print the user specified parameters
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
                % fprintf prints to each line columnwise in this
                % sense so I had to use the transpose of the ranges
                fprintf(fid,"                              "+"%d %d\n",...
                    app.Rng(2:end,:)');
            end
            fprintf(fid,"Initial Population: %s\n",strjoin(app.Pop(1,:)));
            if size(app.Pop,1) >= 2
                % fprintf prints to each line columnwise in this
                % sense so I had to use the transpose of the
                % population
                fprintf(fid,"                    "+...
                    strjoin(repmat("%s",1,size(app.Pop,2))," ")+"\n",app.Pop(2:end,:)');
            end
            fprintf(fid,"\n");
        end
        
        function printcross(app,fid,GenNo)
            
            stringNo = app.StringsPerChromosomeEditField.Value;
            
            bits = app.BitsPerStringEditField.Value;
            
            app.printhead(fid,"CROSS-OVER",1)
            
            if GenNo == 0
                CurGen = app.GenZero;
            else
                CurGen = app.Gen(GenNo);
            end
            
            for i = 1:size(CurGen.crossPairs,1)
                fprintf(fid,"Pairs: %d and %d\t\t\t",CurGen.crossPairs(i,:));
                if app.PointButton.Value
                    fprintf(fid,"Point: %d\n",CurGen.crossPoints(i));
                else
                    fprintf(fid,"Points: %d & %d\n",CurGen.crossPoints(i,:));
                end
                form = strjoin(repmat("%.2f",1,length(CurGen.crossProbs(i,:))));
                fprintf(fid,"Cross-Over Probabilities: "+form+"\n",...
                    CurGen.crossProbs(i,:));
                fprintf(fid,strjoin([CurGen.initPop(CurGen.crossPairs(i,1),:),"=>",...
                    CurGen.crossedPop(i*2-1,:),"\n"]));
                if ~any(CurGen.doCross(i,:))
                    fprintf(fid,strjoin(repmat(" ",1,stringNo*(bits+1)),'')+...
                        "=>"+strjoin(repmat(" ",1,stringNo*(bits+1)),'')+"\n");
                else
                    for j = 1:stringNo
                        if CurGen.doCross(i,j)
                            if app.PointButton.Value
                                fprintf(fid,strjoin(repmat(" ",1,bits-CurGen.crossPoints(i)),''));
                                fprintf(fid,strjoin(repmat("\x21D5",1,CurGen.crossPoints(i)),''));
                                fprintf(fid," ");
                            else
                                fprintf(fid,strjoin(repmat(" ",1,bits-CurGen.crossPoints(i,1)),''));
                                fprintf(fid,strjoin(repmat("\x21D5",1,...
                                    CurGen.crossPoints(i,1)-CurGen.crossPoints(i,2)),''));
                                fprintf(fid,strjoin(repmat(" ",1,CurGen.crossPoints(i,2)+1),''));
                            end
                        else
                            fprintf(fid,strjoin(repmat(" ",1,bits+1),''));
                        end
                    end
                    fprintf(fid,"=> %s\n",strjoin(repmat(" ",1,stringNo*(bits+1)),''));
                end
                fprintf(fid,strjoin([CurGen.initPop(CurGen.crossPairs(i,2),:),"=>",...
                    CurGen.crossedPop(i*2,:),"\n\n"]));
            end
            fprintf(fid,"Population after Cross-over: %s\n",strjoin(CurGen.crossedPop(1,:)));
            if size(CurGen.crossedPop,1) > 1
                for i = 2:size(CurGen.crossedPop,1)
                    fprintf(fid,"                             %s\n",strjoin(CurGen.crossedPop(i,:)));
                end
            end
            fprintf(fid,"\n");
        end
        
        function printmut(app,fid,GenNo)
            
            stringNo = app.StringsPerChromosomeEditField.Value;
            
            bits = app.BitsPerStringEditField.Value;
            
            app.printhead(fid,"MUTATION",1)
            
            if GenNo == 0
                CurGen = app.GenZero;
            else
                CurGen = app.Gen(GenNo);
            end
            
            for i = 1:size(CurGen.mutPairs,1)
                fprintf(fid,"Pairs: %d and %d\t\t\t",CurGen.mutPairs(i,:));
                fprintf(fid,"Point: %d\n",CurGen.mutPoints(i));
                form = strjoin(repmat("%.2f",1,length(CurGen.mutProbs(i,:))));
                fprintf(fid,"Mutation Probabilities: "+form+"\n",...
                    CurGen.mutProbs(i,:));
                fprintf(fid,strjoin([CurGen.crossedPop(CurGen.mutPairs(i,1),:),"=>",...
                    CurGen.mutatedPop(i*2-1,:),"\n"]));
                if ~any(CurGen.doMutation(i,:))
                    fprintf(fid,strjoin(repmat(" ",1,stringNo*(bits+1)),'')+...
                        "=>"+strjoin(repmat(" ",1,stringNo*(bits+1)),'')+"\n");
                else
                    for j = 1:stringNo
                        if CurGen.doMutation(i,j)
                            fprintf(fid,strjoin(repmat(" ",1,bits-CurGen.mutPoints(i)),''));
                            fprintf(fid,"\x21D5");
                            fprintf(fid,strjoin(repmat(" ",1,CurGen.mutPoints(i)),''));
                        else
                            fprintf(fid,strjoin(repmat(" ",1,bits+1),''));
                        end
                    end
                    fprintf(fid,"=> %s\n",strjoin(repmat(" ",1,stringNo*(bits+1)),''));
                end
                fprintf(fid,strjoin([CurGen.crossedPop(CurGen.mutPairs(i,2),:),"=>",...
                    CurGen.mutatedPop(i*2,:),"\n\n"]));
            end
            fprintf(fid,"Population after Mutation: %s\n",strjoin(CurGen.mutatedPop(1,:)));
            if size(CurGen.mutatedPop,1) > 1
                for i = 2:size(CurGen.mutatedPop,1)
                    fprintf(fid,"                           %s\n",strjoin(CurGen.mutatedPop(i,:)));
                end
            end
            fprintf(fid,"\n");
        end
        
        function printeval(app,fid,GenNo)
            % This function prints the evaluation part of generations to
            % text file. All printed texts are spaced for readability when
            % required
            
            app.printhead(fid,"EVALUATION",1)
            
            if GenNo == 0
                CurGen = app.GenZero;
            else
                CurGen = app.Gen(GenNo);
            end
            
            % If type is binary print the denary values and the decoded
            % values else do not print both
            if app.TypeofValuesDropDown.Value == 1
                
                % The part below is not working. I wanted to print to the
                % text file just as matlab displays tables in the command
                % window but it did not work so I had to write the
                % algorithm myself
                
                %fprintf(fid,table(CurGen.denVal,CurGen.decVal,...
                %    'VariableNames',["Denary Values" "Decoded Values"]));
                
                % Get the widths of the denary value and decoded value with
                % the highest width when taken as digits and to 4 d.p.
                % respectively
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
                
                % Check if the width of any line of the denary values or
                % decoded values is more than the heading. Track with
                % smallDenVal and smallDecVal respectively
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
                
                % Get the number of spaces before the first heading
                beg = strjoin(repmat(" ",1,floor((denValLineWid-13)/2)),"");
                
                % Get the number of spaces between the headings
                mid = strjoin(repmat(" ",1,ceil((denValLineWid-13)/2)),"")+...
                    "    "+strjoin(repmat(" ",1,floor((decValLineWid-14)/2)),"");
                
                % print the headings
                fprintf(fid,"%sDenary Values%sDecoded Values\n",beg,mid);
                
                % Underline the headings
                fprintf(fid,"%s    %s\n",strjoin(repmat("_",1,denValLineWid),""),...
                    strjoin(repmat("_",1,decValLineWid),""));
                
                % Specify the format for printing the denary values
                denValForm = strjoin(repmat("%"+string(denValWid)+...
                        "d",1,size(CurGen.denVal,2)),"  ");
                    
                % specify the format for printing the decoded values
                decValForm = strjoin(repmat("%"+string(decValWid)+...
                        ".4f",1,size(CurGen.decVal,2)),"  ");
                    
                % If the length of each line of the denary values to be
                % printed is lesser than the length of the heading pad it
                % with spaces. Also if the length of each line of the
                % decoded values to be printed is lesser the length of the
                % heading pad it with spaces
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
            
            % Get the width of fx value, fitness and cummulative fitness
            % with the highest width among the values to be printed
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
            
            % Get the number of spaces before the first heading
            beg = strjoin(repmat(" ",1,floor((fxWid-4)/2)),"");
            
            % Get the number of spaces between the first and second heading
            mid1 = strjoin(repmat(" ",1,ceil((fxWid-4)/2)),"")+...
                strjoin(repmat(" ",1,floor((fitWid-7)/2)),"")+"    ";
            
            % Get the number of spaces between the second and the third
            % heading
            mid2 = strjoin(repmat(" ",1,ceil((fitWid-7)/2)),"")+...
                strjoin(repmat(" ",1,floor((cumFitWid-9)/2)),"")+"    ";
            
            % Print the headings
            fprintf(fid,"%sf(x)%sFitness%sCum. Fit.\n",beg,mid1,mid2);
            
            % Underline the headings
            fprintf(fid,"%s    %s    %s\n",strjoin(repmat("_",1,fxWid),""),...
                strjoin(repmat("_",1,fitWid),""),strjoin(repmat("_",1,cumFitWid),""));
            
            % Specify the format for printing fx
            fxForm = "%"+string(fxWid)+".2f";
            
            % specify the format for printing fitness
            fitForm = "%"+string(fitWid)+".6f";
            
            % specify the format for printing cummulative fitness
            cumFitForm = "%"+string(cumFitWid)+".7f";
            
            % Print the values
            for i = 1:size(CurGen.fx,1)
            fprintf(fid,fxForm+"    "+fitForm+"    "+cumFitForm+"\n",...
                CurGen.fx(i),CurGen.fit(i),CurGen.cumFit(i));
            end
            fprintf(fid,"\n");
        end
        
        function printsel(app,fid,GenNo)
            % This function prints the selection part of generations
            
            app.printhead(fid,"SELECTION",1)
            
            if GenNo == 0
                CurGen = app.GenZero;
            else
                CurGen = app.Gen(GenNo);
            end
            
            if app.RolletteWheelButton.Value || app.PopulationSizeEditField.Value <= 2
                % Print the selected chromosomes
                fprintf(fid,"The randomly selected chromosomes are: %s\n",strjoin(string(CurGen.selChroms)));
            else
                if app.PopulationSizeEditField.Value == 3
                    fprintf(fid,"The best and the worst chromosomes respectively are: %s\n",strjoin(string(CurGen.selChroms(1:2))));
                    fprintf(fid,"The randomly selected chromosome is: %s\n",strjoin(string(CurGen.selChroms(3:end))));
                elseif app.PopulationSizeEditField.Value == 4
                    fprintf(fid,"The best and the worst chromosomes respectively are: %s\n",strjoin(string(CurGen.selChroms(1:2))));
                    fprintf(fid,"The randomly selected chromosomes are: %s\n",strjoin(string(CurGen.selChroms(3:end))));
                else
                    fprintf(fid,"The best two and the worst two chromosomes respectively are: %s\n",strjoin(string(CurGen.selChroms(1:4))));
                    fprintf(fid,"The randomly selected chromosomes are: %s\n",strjoin(string(CurGen.selChroms(5:end))));
                end
            end
            
            % Print the best chromosome till date
            fprintf(fid,"The best chromosome till date is: %s\n",strjoin(CurGen.bestTillNow));
            
            % Print the fitness of the best till date
            fprintf(fid,"with fitness: %s\n\n",string(CurGen.bestFitTillNow));
        end
        
        function printpop(app,fid,GenNo,type)
            if GenNo == 0
                CurGen = app.GenZero;
            else
                CurGen = app.Gen(GenNo);
            end
            
            if type == 1
                CurPop = CurGen.initPop;
                heading = "Initial Population: ";
                beg = strjoin(repmat(" ",1,20),"");
            else
                CurPop = CurGen.finalPop;
                heading = "Final Population: ";
                beg = strjoin(repmat(" ",1,18),"");
            end
            
            fprintf(fid,heading);
            fprintf(fid,"%s\n",strjoin(CurPop(1,:)));
            if size(CurPop,1) >= 2
                for r = 2:size(CurPop,1)
                    fprintf(fid,"%s%s\n",beg,strjoin(CurPop(r,:)));
                end
            end
            fprintf(fid,"\n");
        end
    end

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)
            
            % Get the number of strings per chromosomes
            strNo = app.StringsPerChromosomeEditField.Value;
            
            % Get the number of decimal places
            decPlField = app.DecimalPlacesEditField;
            
            % Get the number of bits per chromosomes
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
            
            % Get number of strings per chromosome
            strNum = app.StringsPerChromosomeEditField.Value;
            
            % Get the number of bits per string
            bits = app.BitsPerStringEditField.Value;
            
            % Get the number of decimal places
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
            % Get the specified function and remove any space if there is
            value = regexprep(app.FunctionEditField.Value,'\s','');
            
            % Change any X (upper case) to x (lower case)
            value = regexprep(value,'X','x');
            
            % Change the function value to this modified form
            app.FunctionEditField.Value = value;
            
            % Get number of strings per chromosome
            strNum = app.StringsPerChromosomeEditField.Value;
            
            % expr is a regular expression to check the function
            expr = "[-+]?(?:x["+strjoin(string(1:strNum),'')+"])(?:[+*/^-]x["+...
                strjoin(string(1:strNum),'')+"])*";
            
            % Check if function matches expr
            [start,last] = regexp(value,expr,'once');
            
            if isempty(start) || isempty(last)
            % Function does not match expr
                app.FunctionEditField.BackgroundColor = '#EDB120';
                app.Err(app.FuncErr) = 1;
            elseif start(1) == 1 && last(end) == length(value)
            % function matches expr exactly
                app.FunctionEditField.BackgroundColor = '#fff';
                app.Err(app.FuncErr) = 0;
            else
            % current line matches expr partly
                app.FunctionEditField.BackgroundColor = '#EDB120';
                app.Err(app.FuncErr) = 1;
            end
            
            %Check for any errors if any disable Generate button
            app.checkErr();
        end

        % Size changed function: ButtonGroup
        function ButtonGroupSizeChanged(app, event)
            % Get the position of the cross-over button group
            position = app.ButtonGroup.Position;
            
            % Reposition the first button
            app.PointButton.Position(1) = round((position(3)-243)/2);
            
            % Reposition the second button
            app.PointsButton.Position(1) = app.PointButton.Position(1)+177;
        end

        % Size changed function: ButtonGroup_2
        function ButtonGroup_2SizeChanged(app, event)
            % Get the position of the selection button group
            position = app.ButtonGroup_2.Position;
            
            % Reposition the first button
            app.RolletteWheelButton.Position(1) = round((position(3)-243)/2);
            
            % Reposition the second button
            app.ElitismButton.Position(1) = app.RolletteWheelButton.Position(1)+177;
        end

        % Button pushed function: GenerateButton
        function GenerateButtonPushed(app, event)
            
            % If there is Range, Population or Function error show it
            % then disable Generate button else proceed to the algorithm
            if app.Err(app.RngErr) || app.Err(app.PopErr)
                app.RngPopErr();    % Show Range or Population error
                app.checkErr();     % Disable Generate button if any error
            elseif app.Err(app.FuncErr)
                app.FunctionEditField.BackgroundColor = '#EDB120';
                app.checkErr();
            else
                % Set the initial population of GenZero to the specified
                % population
                app.GenZero.initPop = app.Pop;
                
                % Evaluate GenZero
                app.GenZero = app.evaluate(0);
                
                % Select in GenZero
                app.GenZero = app.select(0);
                
                % If the generation to stop is not zero
                if app.StopatGenerationEditField.Value > 0
                    % Create empty struct array for the other generations
                    app.Gen(app.StopatGenerationEditField.Value) = struct('initPop',"",...
                        'crossPairs',[],'crossProbs',[],'crossPoints',[],'doCross',[],...
                        'crossedPop',[],'mutPairs',[],'mutProbs',[],'mutPoints',[],...
                        'doMutation',[],'mutatedPop',[],'denVal',[],'decVal',[],'fx',[],...
                        'fit',[],'cumFit',[],'selChroms',[],'bestTillNow',"",...
                        'bestFitTillNow',[],'finalPop',[]);
                    
                    for GenNo = 1:app.StopatGenerationEditField.Value
                        if GenNo == 1
                            % For generation 1 the initial popuplation is
                            % the final population of GenZero
                            app.Gen(GenNo).initPop = app.GenZero.finalPop;
                        else
                            % For generations 2 upward the initial
                            % generation is the final generation of the
                            % preceeding generation
                            app.Gen(GenNo).initPop = app.Gen(GenNo-1).finalPop;
                        end
                        
                        % Do cross-over for the current generation
                        app.Gen(GenNo) = app.cross(GenNo);
                        
                        % Do mutation for the current generation
                        app.Gen(GenNo) = app.mutate(GenNo);
                        
                        % Evaluate The current generation
                        app.Gen(GenNo) = app.evaluate(GenNo);
                        
                        % Do selection for the current generation
                        app.Gen(GenNo) = app.select(GenNo);
                    end
                end
            end
            
            app.print()
            close(app.GeneticAlgorithmUIFigure)
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