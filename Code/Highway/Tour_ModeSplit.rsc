Macro "Tour Mode Split"(Args)
    purps = {"Work", "Shop", "Other", "School", "Univ", "SubTour"}
    files = {"dcHBW", "dcHBS", "dcHBO", "dcSch", "dcHBU", "dcATW"}
    vwTAZ = OpenTable("TAZ", "FFB", {Args.[Run Directory] + "\\LandUse\\TAZ_AreaType.asc"})
    // Loop over each purpose
    for i = 1 to purps.length do
        // Open tours file and add the output mode choice field
        dcFile = Args.[Run Directory] + "\\TD\\" + files[i] + ".bin"
        objT = CreateObject("Table", dcFile)
        flds = {{FieldName: "TourMode", Type: "string", Length: 15}}
        objT.AddFields({Fields: flds})

        // Eval MC for purpose
        spec = null
        spec.Purpose = purps[i]
        spec.RandomSeed = 99999*i
        spec.TAZView = vwTAZ
        spec.ToursView = objT.GetView()
        RunMacro("Eval Tour MC Model", Args, spec)
    end
    objT = null
endMacro


Macro "Eval Tour MC Model"(Args, spec)
    purp = spec.Purpose
    utilFile = Args.[Run Directory] + "\\TourModeSplit\\" + purp + "_mc_specs.csv"
    nestFile = Args.[Run Directory] + "\\TourModeSplit\\" + purp + "_mc_nests.csv"
    nmSkim = printf("%s\\Skims\\TR_NonMotorized.mtx", {Args.[Run Directory]})

    periods = {"PK", "OffPK"}
    // Run model for each period separately. The skim files change by period.
    for j = 1 to periods.length do
        per = periods[j]
        
        // Get skim files
        wTranSkim = printf("%s\\Skims\\%s_WKTRAN_Skims.mtx", {Args.[Run Directory], per}) 
        pnrTranSkim = printf("%s\\Skims\\%s_DRVTRAN_Skims.mtx", {Args.[Run Directory], per})
        knrTranSkim = printf("%s\\Skims\\%s_DROPTRAN_Skims.mtx", {Args.[Run Directory], per})
        if per = "PK" then
            autoSkim = printf("%s\\AutoSkims\\SPMAT_auto.mtx", {Args.[Run Directory]})
        else
            autoSkim = printf("%s\\AutoSkims\\SPMAT_free.mtx", {Args.[Run Directory]})
        
        // Call and run model
        filter = printf("PAper = %u", {j})
        utilSpec = null
        utilSpec.UtilityFunction = RunMacro("ImportChoiceSpec", utilFile)
        utilSpec.NestingStructure = RunMacro("ImportChoiceSpec", nestFile)
        utilSpec.[Substitute Strings] = {{"<occ3>", "3.3"}}

        tag = printf("%s_%s_TourMC", {purp, per})
        obj = CreateObject("PMEChoiceModel", {ModelName: tag})
        obj.OutputModelFile = GetTempPath() + tag + ".mdl"
        obj.AddTableSource({SourceName: "Tours", View: spec.ToursView, IDField: "ID"})
        obj.AddTableSource({SourceName: "TAZ", View: spec.TAZView, IDField: "TAZ"})
        obj.AddMatrixSource({SourceName: "AutoSkim", File: autoSkim})
        obj.AddMatrixSource({SourceName: "NMSkim", File: nmSkim})
        obj.AddMatrixSource({SourceName: "WalkTransitSkim", File: wTranSkim})
        obj.AddMatrixSource({SourceName: "DriveTransitSkim", File: pnrTranSkim})
        obj.AddMatrixSource({SourceName: "DropoffTransitSkim", File: knrTranSkim})
        obj.AddPrimarySpec({Name: "Tours", Filter: filter, OField: "ORIG_TAZ", DField: "DEST_TAZ"})
        obj.AddUtility(utilSpec)
        obj.AddOutputSpec({ChoicesField: "TourMode"})
        obj.ReportShares = 1
        obj.RandomSeed = spec.RandomSeed + 99*j
        ret = obj.Evaluate()
        if !ret then
            Throw("Running '" + tag + " TOD' choice model failed.")
        Args.(tag + " Spec") = CopyArray(ret) // For calibration purposes
        obj = null
    end
endMacro


Macro "ImportChoiceSpec" (file)
    vw = OpenTable("Spec", "CSV", {file,})
    {flds, specs} = GetFields(vw,)
    vecs = GetDataVectors(vw + "|", flds, {OptArray: 1})
    
    util = null
    for fld in flds do
        util.(fld) = v2a(vecs.(fld))
    end
    CloseView(vw)
    Return(util)
endMacro
