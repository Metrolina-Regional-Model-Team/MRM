Macro "Calibrate Tour MCs"(Args)
    purps = {"work", "shop", "other", "school", "univ", "subtour"}
    files = {"dcHBW", "dcHBS", "dcHBO", "dcSch", "dcHBU", "dcATW"}
    vwTAZ = OpenTable("TAZ", "FFB", {Args.[Run Directory] + "\\LandUse\\TAZ_AreaType.bin"})
    for i = 1 to purps.length do
        dcFile = Args.[Run Directory] + "\\TD\\" + files[i] + ".bin"
        objT = CreateObject("Table", dcFile)

        spec = null
        spec.Purpose = purps[i]
        spec.RandomSeed = 99999*i
        spec.TAZView = vwTAZ
        spec.ToursView = objT.GetView()
        RunMacro("Calibrate Tour MC", Args, spec)
    end
    objT = null
    CloseView(vwTAZ)
    Return(1)
endMacro


Macro "Calibrate Tour MC"(Args, spec)
    // Evaluate mode choice first to get all the model specs
    RunMacro("Eval Tour MC Model", Args, spec)

    // Start loop for model ASC adjustments
    calibrationFile = printf("%s\\TourModeSplit\\Calibration\\%sMC_Targets.csv", 
                                {Args.[Run Directory], spec.Purpose})
    RunMacro("Calibrate MC ASCs", Args, spec, calibrationFile)
endMacro


/* 
    Macro to calibrate ASCs for the mandatory MC models.
    There are three mdl files to handle (as opposed to one)

    The loop for the ASC adjustment:
    A. Gets the initial ASCs
    B. Run three choice models, once for each period with appropriate selection set
    C. Combine results from all three models to get model shares
    D. Calculate the ASC adjustments
    E. Update ASCs of all three models
*/ 
Macro "Calibrate MC ASCs"(Args, spec, calibrationFile)
    periods = {"PK", "OffPK"}

    // Get initial ASCs, create calibration file
    if !GetFileInfo(calibrationFile) then
        Throw("Calibration file for " + modelName + " not found in the 'Calibration' folder.")

    objTable = CreateObject("Table", calibrationFile)
    alts = v2a(objTable.Alternative)    
    targets = v2a(objTable.TargetShare)
    thresholds = targets.Map(do (f) Return(0.02*f) end)

    // Copy input model files into output model files
    for p in periods do
        tag = spec.Purpose + "_" + p + "_TourMC"
        modelSpec = Args.(tag + " Spec")
        isAggregate = modelSpec.isAggregateModel
        if modelSpec = null then
            continue
        inputModel = modelSpec.ModelFile
        pth = SplitPath(inputModel)
        outputModel = pth[1] + pth[2] + pth[3] + "_out" + pth[4]
        outputModels.(p) = outputModel
        CopyFile(inputModel, outputModel)
    end
    
    dim shares[alts.length]
    convergence = 0
    iters = 0
    max_iters = 20

    // Get Initial ASCs (from any one of the time period models)
    initialAscs = RunMacro("GetASCs", outputModels[1][2], alts)
    
    pbar = CreateObject("G30 Progress Bar", "Calibration Iterations...", true, max_iters)
    while convergence = 0 and iters <= max_iters do
        // Run Model
        outFiles = RunMacro("Evaluate MC Models", Args, spec, outputModels)
        if outFiles = null then
            Throw("Evaluating models for calibration failed")
            
        // Get Model Shares
        RunMacro("Generate MC Model Shares", alts, outFiles, isAggregate, &shares)
        if iters = 0 then
            initialShares = CopyArray(shares)

        // Check convergence
        convergence = RunMacro("Convergence", shares, targets, thresholds)
        if convergence = null then
            Throw("Error in checking convergence")
            
        // Modify Model ASCs for next loop
        if convergence = 0 then
            RunMacro("Modify MC Models", outputModels, alts, shares, targets)

        iters = iters + 1

        if pbar.Step() then
            Return()
    end
    pbar.Destroy()

    // Get Final ASCs
    finalAscs = RunMacro("GetASCs", outputModels[1][2], alts)

    csvFile = Args.[Run Directory] + "\\TourModeSplit\\" + spec.Purpose + "_mc_specs.csv"
    RunMacro("Update MC CSV Spec File", Args, csvFile, alts, initialAscs, finalAscs)

    if convergence = 0 then
        msg = "ASC Adjustment did not converge after " + i2s(max_iters) + " iterations"
    else
        msg = "ASC Adjustment converged after " + i2s(iters) + " iterations"
    
    AppendToReportFile(1, msg)
endMacro
 

/* 
    Loop over periods, run the mandatory MC models and return an option array of output probability files.  
*/ 
Macro "Evaluate MC Models"(Args, spec, outputModels)
    periods = {"PK", "OffPK"}

    // Evaluate each period model, one at a time
    outFiles = null
    for j = 1 to periods.length do
        p = periods[j]
        
        // Get Model details
        tag = spec.Purpose + "_" + p + "_TourMC"
        modelSpec = Args.(tag + " Spec")
        outputModel = outputModels.(p)

        // Open Matrix Sources
        for src in modelSpec.MatrixSources do
            mObjs.(src.Label) = CreateObject("Matrix", src.FileName)
        end

        // Make appropriate selection set (only for Mandatory mode choice models)
        finalFilter = printf("PAper = %u", {j})
        
        SetView(spec.ToursView)
        n = SelectByQuery("___Selection", "several", "Select * where " + finalFilter,)
        if n = 0 then
            goto next_period

        // Run model
        outFiles.(p) = RunMacro("Evaluate Model", modelSpec, outputModel)
     
     next_period:
    end
    Return(outFiles)
endMacro


Macro "Generate MC Model Shares"(alts, outFiles, isAggregate, shares)
    periods = {"PK", "OffPK"}

    shares = shares.Map(do (f) Return(0) end)
    if isAggregate then do
        for p in periods do
            outFile = outFiles.(p)
            if !GetFileInfo(outFile) then
                continue
            m = OpenMatrix(outFile,)
            cores = GetMatrixCoreNames(m)
            stats = MatrixStatistics(m,)
            for i = 1 to alts.length do
                shares[i] = shares[i] + nz(stats.(alts[i]).Sum)
            end
            m = null
        end
    end
    else do
        for p in periods do
            outFile = outFiles.(p)
            if !GetFileInfo(outFile) then
                continue
            objP = CreateObject("Table", outFile)
            vwP = objP.GetView()
            probFlds = alts.Map(do (f) Return("[" + f + " Probability]") end)
            vecs = GetDataVectors(vwP + "|", probFlds,)
            for i = 1 to vecs.length do // Note vecs array same length as alts
                shares[i] = shares[i] + VectorStatistic(vecs[i], "Sum",)
            end
            objP = null
        end
    end

    tSum = Sum(shares)
    if tSum = 0 then
        Throw("Mode Choice calibration failed. Model shares are all zero.")
    shares = shares.Map(do (f) Return(f*100/tSum) end)
    dmP = null
endMacro


Macro "Modify MC Models"(outputModels, alts, shares, targets)
    periods = {"PK", "OffPK"}
    for p in periods do
        outputModel = outputModels.(p)
        if !GetFileInfo(outputModel) then
            continue
        RunMacro("Modify Model", outputModel, alts, shares, targets)
    end
endMacro


// ******************** Generic macros used by all calibration macros ********************
// Run Model. Uses the modelSpec array. Note that all relevant files are open at this point.
Macro "Evaluate Model"(modelSpec, outputModel)
    isAggregate = modelSpec.isAggregateModel

    o = CreateObject("Choice.Mode")
    o.ModelFile = outputModel
    o.UtilityScaling = "By Parent Theta"
    
    if isAggregate then do
        probFile = GetRandFileName("Probability*.mtx")
        outputFile = GetRandFileName("Totals*.mtx")
        o.AddMatrixOutput("*", {Probability: probFile, Totals: outputFile})
    end
    else do
        outputFile = GetRandFileName("Probability*.bin")
        o.OutputProbabilityFile = outputFile
        o.OutputChoiceFile = GetRandFileName("Choices*.bin")
    end

    o.Run()
    Return(outputFile)
endMacro


// Returns 1 if all of the current model shares are within the target range.
Macro "Convergence"(shares, targets, thresholds)
    if shares.length <> targets.length or shares.length <> thresholds.length then
        Return()
        
    for i = 1 to shares.length do
        if shares[i] > (targets[i] + thresholds[i]) or shares[i] < (targets[i] - thresholds[i]) then // Out of bounds. Not Converged.
            Return(0)  
    end
    
    Return(1)    
endmacro


// Adjust ASC in output model
Macro "Modify Model"(model_file, alts, shares, targets)
    model = CreateObject("NLM.Model")
    model.Read(model_file, true)
    seg = model.GetSegment("*")

    for i = 1 to alts.length do
        alt = seg.GetAlternative(alts[i])
        if shares[i] > 0 and targets[i] > 0 then
            alt.ASC.Coeff = nz(alt.ASC.Coeff) + 0.5*log(targets[i]/shares[i])
        model.Write(model_file)
    end

    model.Clear()
endMacro


Macro "GetASCs"(model_file, alts)
    model = CreateObject("NLM.Model")
    model.Read(model_file, true)
    seg = model.GetSegment("*")

    dim ascs[alts.length]
    for i = 1 to alts.length do
        alt = seg.GetAlternative(alts[i])
        ascs[i] = alt.ASC.Coeff
    end

    model.Clear()
    Return(ascs)         
endMacro


Macro "Update MC CSV Spec File"(Args, csvFile, altNames, initialASCs, finalASCs)
    f = OpenFile(csvFile, "a")
    for i = 1 to altNames.length do
        val = nz(finalASCs[i]) - nz(initialASCs[i]) // The delta ASC
        if abs(val) < 1e-4 then 
            continue
        
        alt = altNames[i]
        line = altNames[i] + ",Constant,," + String(val) + ",Additional Calibration Constant"
        WriteLine(f, line)
    end
    CloseFile(f)
endMacro
