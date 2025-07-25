Macro "FillParkCost" (Args)

// Edited for new User Interface - Aug, 2015
//	Repaired external station segment - JWM, June, 2016

	// LogFile = Args.[Log File].value
	// ReportFile = Args.[Report File].value
	// SetLogFileName(LogFile)
	// SetReportFileName(ReportFile)

	METDir = Args.[MET Directory]
	Dir = Args.[Run Directory]
	se_file = Args.[LandUse File]
	theyear = Args.[Run Year]
	TAZFile = Args.[TAZ File]
	
	msg = null
	FillParkCostOK = 1

	datentime = GetDateandTime()
	AppendToLogFile(1, "Enter FillParkCost " + datentime)


 
    RunMacro("TCB Init")

    base_file= METDir + "\\TAZ\\Parking_Cost_Base06.dbf"
	exist = GetFileInfo(base_file)
	if exist = null
		then do
            Throw("FillParkCost: ERROR! \\TAZ\\Parking_Cost_Base06.dbf not found")
			// Throw("FillParkCost: ERROR! \\TAZ\\Parking_Cost_Base06.dbf not found")
			// AppendToLogFile(2, "FillParkCost: ERROR! \\TAZ\\Parking_Cost_Base06.dbf not found")
			// FillParkCostOK = 0
			// goto badend
		end

    // -- create a table to store peak (average weekday) parking cost

    peak_cost_table = {
        {"TAZ", "Integer", 8, null, "Yes"},		
        {"PK"+theyear, "Real", 10, 2, "No"}
        }

    peak_cost_name = "PEAKPARKINGCOST"	
    peak_cost_file = Dir + "\\PEAKPARKINGCOST.dbf"

    //---- close open view ----

    tmp = GetViews ()
    if (tmp <> null) then do
        views = tmp [1]
        for k = 1 to views.length do
            if (views [k] = peak_cost_name) then 
                CloseView (views [k])
        end
    end

    peak_cost_view = CreateTable (peak_cost_name, peak_cost_file, "DBASE", peak_cost_table)

   // -- create a table to store off-peak (Hourly) parking cost

    offpeak_cost_table = {
        {"TAZ", "Integer", 8, null, "Yes"},		
        {"OP"+theyear, "Real", 10, 2, "No"}
        }

    offpeak_cost_name = "OFFPEAKPARKINGCOST"	
    offpeak_cost_file = Dir + "\\OFFPEAKPARKINGCOST.dbf"

    //---- close open view ----

    tmp = GetViews ()
    if (tmp <> null) then do
        views = tmp [1]
        for k = 1 to views.length do
            if (views [k] = offpeak_cost_name) then 
                CloseView (views [k])
        end
    end

    offpeak_cost_view = CreateTable (offpeak_cost_name, offpeak_cost_file, "DBASE", offpeak_cost_table)

    se_vw=opentable("SE"+theyear, "FFB", {se_file,})

    base_vw=opentable("Parking_Cost_Base06", "DBASE", {base_file,})


    avgdensity = Dir + "\\Parking_Cost_Emp_Density.prn"
	      	
    prtfile=OpenFile(avgdensity,"w")
	      	
    WriteLine(prtfile," TAZ      EMP DENSITY   AVG EMP DENSITY ")

    rec = 0
    nrec = GetRecordCount (base_vw, null)

////
    dim org[nrec]
    dim spaces[nrec]
    dim mocost[nrec]
    dim hrcost[nrec]
    dim area[nrec]
    dim num[nrec]
    dim use[nrec,9]
    dim numuse[nrec]
    dim calc[nrec]
    dim den[nrec]
////
    
    fields = GetFields(base_vw, "All")
		 
    base_rec = GetFirstRecord (base_vw + "|", {{"Zone", "Ascending"}})
	
    rec = 0
    while base_rec <> null do
	rec = rec + 1
	org[rec]    = base_vw.ZONE
	spaces[rec] = base_vw.SPACES
	mocost[rec] = base_vw.MODLYCST06
	hrcost[rec] = base_vw.HRCOST06
	area[rec]   = base_vw.AREA
	num[rec]    = base_vw.NUM
	use[rec][1] = base_vw.N1
	use[rec][2] = base_vw.N2
	use[rec][3] = base_vw.N3
	use[rec][4] = base_vw.N4
	use[rec][5] = base_vw.N5
	use[rec][6] = base_vw.N6
	use[rec][7] = base_vw.N7
	use[rec][8] = base_vw.N8
	use[rec][9] = base_vw.N9

        numuse[rec] = 0
        calc[rec]   = 0
        den[rec]    = 0

	SetView(base_vw)
	base_rec = GetNextRecord (base_vw + "|", null, {{"ZONE", "Ascending"}})
    end


    for i=1 to rec do
        setview(se_vw)
        // get the employment and area from SE file
        rh2 = LocateRecord(se_vw+"|", se_vw + ".TAZ", {org[i]}, {{"Exact", "True"}})
        emp=se_vw.[TOTEMP]
        area=round(se_vw.[AREA],3)
        den[i]=emp/area
    end

    for i=1 to rec do
        calc[i]=2*den[i]
        for j=1 to num[i] do
            look=0
            look=use[i][j]
            for k=1 to rec do
                if (org[k]=look) then do
                    if (spaces[k] >0) then do 
                        calc[i]=calc[i]+den[k]
                        numuse[i]=numuse[i]+1
                    end
                end
            end
        end
        calc[i]=calc[i]/(numuse[i]+2)
        
	fld1 = Lpad(String(org[i]),8)
	fld2 = Lpad(format(den[i],"*.00"), 16)
	fld3 = Lpad(format(calc[i],"*.00"),16)
	WriteLine(prtfile,fld1 + fld2 + fld3)
        
    end
       
    setview(se_vw)
           
    se_rec = GetFirstRecord (se_vw + "|", {{"TAZ", "Ascending"}})
	
    srec = 0
    while se_rec <> null do
    	current_rec = GetRecord(se_vw)
        zone = se_vw.TAZ
        
        // --- Get the average density for this zone
				
	i=0
	pkcost=0.0
	opcost=0.0
	skip=0
        
        // check if overrides apply (zones outside the CBD loop start incurring parking cost only for future years beyond 2015)
        if (s2i(theyear) < 2015) then do
            if(zone=10029 or zone=10033 or zone=10034 or zone=10036 or zone=10146 or zone=10160 or zone=10161 or zone=10162 or zone=10163 or zone=10164 or zone=10165 or zone=10166 or zone = 10167 or zone=10214 or zone=10235 or zone=10236) then skip=1
        end
        if skip=1 then goto writecost
	
	SetView(base_vw)
			
        base_rec = GetFirstRecord (base_vw + "|", {{"Zone", "Ascending"}})
        while base_rec <> null do
            i=i+1
	    if (zone = base_vw.zone) then do
	        avgden=calc[i]
	        if (avgden < 15000) then pkcost=100
	        else pkcost=round(0.002449*avgden + 214.949726,0)
	        opcost=round(MAX(100,(avgden*0.002565)-2.610017),0)
	        
	        pkcost=min(800,pkcost)
	        opcost=min(600,opcost)
	        
	        // UNCC zone 10375 and 10376 has minimum daily cost of 200 cents
	        if (zone=10375 or zone=10376) then pkcost=max(200,pkcost)
	        
	        goto writecost
	    end
            SetView(base_vw)
            base_rec = GetNextRecord (base_vw + "|", null, {{"ZONE", "Ascending"}})
        end


        //write the cost to DBF files
writecost:
			
        peak_cost_values = {
            {"TAZ", zone},		
            {"PK"+theyear, pkcost}
            }

        AddRecord(peak_cost_view, peak_cost_values)

        offpeak_cost_values = {
            {"TAZ", zone},		
            {"OP"+theyear, opcost}
            }

        AddRecord(offpeak_cost_view, offpeak_cost_values)


        SetView(se_vw)
        se_rec = GetNextRecord (se_vw + "|", null, {{"TAZ", "Ascending"}})
    end

// add rows for external zones using the TAZ_ID file
	pkcost=0.0
	opcost=0.0

	tazpath = SplitPath(TAZFile)
	TAZIDFile = tazpath[1] + tazpath[2] + tazpath[3] + "_TAZID.bin"
	exist = GetFileInfo(TAZIDFile)
	if exist = null
		then do
            Throw("FillParkCost: ERROR! \\TAZ\\" + tazpath[3] + "_TAZID.bin not found")
			// Throw("FillParkCost: ERROR! \\TAZ\\" + tazpath[3] + "_TAZID.asc not found")
			// AppendToLogFile(2, "FillParkCost: ERROR! \\TAZ\\" + tazpath[3] + "_TAZID.asc not found")
			// FillParkCostOK = 0
			// goto badend
		end
	TAZID = OpenTable("TAZID", "FFB", {TAZIDFile,})
	selext = "Select * where INT_EXT = 2"

	SetView(TAZID)

	nexttaz = SelectByQuery("externalTAZ", "Several", selext,)    

	ext_rec = GetFirstRecord ("TAZID|externalTAZ", {{"TAZ", "Ascending"}})
	while ext_rec <> null do
		mval = GetRecordValues("TAZID", , {"TAZ"})
		zone = mval[1][2]

		peak_cost_values = {
			{"TAZ", zone},		
			{"PK"+theyear, pkcost}
			}

		AddRecord(peak_cost_view, peak_cost_values)

		offpeak_cost_values = {
			{"TAZ", zone},		
			{"OP"+theyear, opcost}
			}

		AddRecord(offpeak_cost_view, offpeak_cost_values)

 		ext_rec = GetNextRecord ("TAZID|externalTAZ", null, {{"TAZ", "Ascending"}})
	end   // while ext_rec

    tmp = GetViews ()
    if (tmp <> null) then do
        views = tmp [1]
        for k = 1 to views.length do
            CloseView (views [k])
        end
    end


//// DONE with creating input file for parking cost matrix

//template matrix

	TemplateMat = null
	templatecore = null

	TemplateMat = OpenMatrix(METDir + "\\TAZ\\Matrix_Template.mtx", "True")
	templatecore = CreateMatrixCurrency(TemplateMat, "Table", "Rows", "Columns", )

//create new parkingcost matrix

CopyMatrixStructure({templatecore}, {{"File Name", Dir + "\\Autoskims\\parkingcost.mtx"},
    {"Label", "Parking Cost " + theyear},
    {"File Based", "Yes"},
    {"Tables", {"Peak Park cost", "Offpeak park cost"}},
    {"Operation", "Union"}})

//fill new matrices with ones for vector multiply

     Opts = null
     Opts.Input.[Matrix Currency] = {Dir + "\\AutoSkims\\parkingcost.mtx", "Peak Park cost", "Rows", "Columns"}
     Opts.Global.Method = 1
     Opts.Global.Value = 1
     Opts.Global.[Cell Range] = 2
     Opts.Global.[Matrix Range] = 3
     Opts.Global.[Matrix List] = {"Peak Park cost", "Offpeak park cost"}

     ret_value = RunMacro("TCB Run Operation", 1, "Fill Matrices", Opts)
     if !ret_value then goto badquit

// Vector multiply peak cost 
 
     Opts = null
     Opts.Input.[Matrix Currency] = {Dir + "\\AutoSkims\\parkingcost.mtx", "Peak Park cost", "Rows", "Columns"}
     Opts.Input.[Source Matrix Currency] = {Dir + "\\AutoSkims\\parkingcost.mtx", "Peak Park cost", "Rows", "Columns"}
     Opts.Input.[Data Set] = {Dir + "\\PEAKPARKINGCOST.DBF", "PEAKPARKINGCOST"}
     Opts.Global.Method = 12
     Opts.Global.[Fill Option].[ID Field] = "PEAKPARKINGCOST.TAZ"
     Opts.Global.[Fill Option].[Value Field] = "PEAKPARKINGCOST.PK" + theyear
     Opts.Global.[Fill Option].[Apply by Rows] = "No"
     Opts.Global.[Fill Option].[Missing is Zero] = "Yes"


     ret_value = RunMacro("TCB Run Operation", 2, "Fill Matrices", Opts)
     if !ret_value then goto badquit


// Vector multiply offpeak cost 
 
     Opts = null
     Opts.Input.[Matrix Currency] = {Dir + "\\AutoSkims\\parkingcost.mtx", "Offpeak park cost", "Rows", "Columns"}
     Opts.Input.[Source Matrix Currency] = {Dir + "\\AutoSkims\\parkingcost.mtx", "Offpeak park cost", "Rows", "Columns"}
     Opts.Input.[Data Set] = {Dir + "\\OFFPEAKPARKINGCOST.DBF", "OFFPEAKPARKINGCOST"}
     Opts.Global.Method = 12
     Opts.Global.[Fill Option].[ID Field] = "OFFPEAKPARKINGCOST.TAZ"
     Opts.Global.[Fill Option].[Value Field] = "OFFPEAKPARKINGCOST.OP" + theyear
     Opts.Global.[Fill Option].[Apply by Rows] = "No"
     Opts.Global.[Fill Option].[Missing is Zero] = "Yes"


     ret_value = RunMacro("TCB Run Operation", 3, "Fill Matrices", Opts)
     if !ret_value then goto badquit

    goto quit

    badquit:
        FillParkCostOK = 0
        Throw("FillParkCost:  Error in TCB Fill Matrices")
        // Throw("FillParkCost:  Error in TCB Fill Matrices")
		// AppendToLogFile(1, "FillParkCost:  Error in TCB Fill Matrices")
        RunMacro("TCB Closing", ret_value, True )
        return({FillParkCostOK, msg})
        
    badend:
    
	quit:
		datentime = GetDateandTime()
		AppendToLogFile(1, "Exit FillParkCost " + datentime)
        return({FillParkCostOK, msg})


endMacro

