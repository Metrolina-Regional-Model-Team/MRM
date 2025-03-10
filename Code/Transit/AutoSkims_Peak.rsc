Macro "AutoSkims_Peak" (Args)

//Highway skims to Park-n-ride, kiss-n-ride - peak 
// previously part of reg_spmats.rsc
// McLelland - Sept, 2015
// 5/30/19, mk: There are now three distinct networks, use AM network for Peak

	// LogFile = Args.[Log File].value
	// ReportFile = Args.[Report File].value
	// SetLogFileName(LogFile)
	// SetReportFileName(ReportFile)

	METDir = Args.[MET Directory]
	Dir = Args.[Run Directory]
	theyear = Args.[Run Year]
	yearnet = right(theyear,2)
	//hwy_file = Args.[AM Peak Hwy Name]
	hwy_file = Args.[Hwy Name]
	{, , netname, } = SplitPath(hwy_file)

	curiter = Args.[Current Feedback Iter]
	AutoSkimsPeakOK = 1
	msg = null

	datentime = GetDateandTime()
	AppendToLogFile(1, "Enter AutoSkims_Peak: " + datentime)
	AppendToLogFile(2, "AM Peak feedback iteration: " + i2s(curiter))


	analysis_year = yearnet

//changed route_file, routename, net_file, link_lyr, node_lyr to
// trans_trans_route_file, trans_trans_routename, trans_net_file, trans_link_lyr, trans_node_lyr
// to make the shared variables unique and not conflict with global

// --- Create a selection set for all the park & ride stations

//	station = "Select * where Parknride <= \"" + analysis_year + "\""

//	station = "Select * where Station <> 2 and Parknride <= \"" + theyear 

	premium_station = "Select * where Station = 2"
	express_station = "Select * where Station <> 2 and Parknride <= " + theyear 

// --- Year "2000" network doesn't have premium stations. Set the express stations as 
// --- premium station so that the skims get generated

	if (s2i(theyear) < 2007) then 
		premium_stations=express_stations

//	netname = "RegNet"+yearnet
	trans_routename = "TranSys"

	// Get the scope of a geographic file

	info = GetDBInfo(Dir + "\\"+netname+".dbd")
	scope = info[1]

	// Create a map using this scope
	CreateMap(netname, {{"Scope", scope},{"Auto Project", "True"}})

	file = Dir + "\\"+netname+".dbd"
	layers = GetDBLayers(file)
	addlayer(netname, "Node", file, layers[1])
	link_layer = addlayer(netname, netname, file, layers[2])
	rtelyr = AddRouteSystemLayer(netname, "Vehicle Routes", Dir + "\\" + trans_routename + ".rts", )
	RunMacro("Set Default RS Style", rtelyr, "TRUE", "TRUE")
	SetLayerVisibility("Node", "False")
	SetIcon("Node|", "Font Character", "Caliper Cartographic|4", 36)
	SetIcon("Route Stops|", "Font Character", "Caliper Cartographic|4", 36)
	SetLayerVisibility(link_layer, "True")
	solid = LineStyle({{{1, -1, 0}}})
	SetLineStyle(link_layer+"|", solid)
	SetLineColor(link_layer+"|", ColorRGB(0, 0, 32000))
	SetLineWidth(link_layer+"|", 0)
	SetLayerVisibility("Route Stops", "False")

	setview(link_layer)

	hwyassign = "Select * where (funcl > 0 and funcl < 10) or funcl = 82 or funcl = 83 or funcl = 84 or funcl=90"
	SelectByQuery("Drvapp", "Several", hwyassign,)

	CreateNetwork("Drvapp", Dir + "\\Drvapp.net", "Drvapp", {
		{"Length", link_layer+".length"},
		{"TTPkAssn*", link_layer+".TTPkAssnAB", link_layer+".TTPkAssnBA"},
		{"TTfree*", link_layer+".TTfreeAB", link_layer+".TTfreeBA"}},,)

	setview("Node")


   RunMacro("TCB Init")


// STEP 1: PPRMD - Peak Premium Drive

    Opts = {{"Input",    {{"Network",           Dir + "\\Drvapp.net"},
                           {"Origin Set",        {Dir + "\\"+netname+".DBD|Node",
                                                  "Node",
                                                  "centroids",
                                                  "Select * where centroid = 1"}},
                          {"Destination Set",   {Dir + "\\"+netname+".DBD|Node",
                                                  "Node",
                                                  "StaandX",
                                                  premium_station}},
                           {"Via Set",           {Dir + "\\"+netname+".DBD|Node",
                                                  "Node"}}}},
             {"Field",    {{"Minimize",          "TTPkAssn*"},
                           {"Nodes",             "Node.ID"},
                           {"Skim Fields",       {{"Length",
                                                  "All"}}}}},
             {"Output",   {{"Output Matrix",     {{"Label",
                                                  "SPMAT_PPRMD"},
                                                  {"File Name",
                                                  Dir + "\\skims\\SPMAT_PPRMD.mtx"}}}}}}

     ret_value = RunMacro("TCB Run Procedure", 1, "TCSPMAT", Opts)

     if !ret_value then goto badpprmd

  
// STEP 1: PXPRD - Peak Express Drive

    Opts = {{"Input",    {{"Network",           Dir + "\\Drvapp.net"},
                           {"Origin Set",        {Dir + "\\"+netname+".DBD|Node",
                                                  "Node",
                                                  "centroids",
                                                  "Select * where centroid = 1"}},
                          {"Destination Set",   {Dir + "\\"+netname+".DBD|Node",
                                                  "Node",
                                                  "StaandX",
                                                  express_station}},
                           {"Via Set",           {Dir + "\\"+netname+".DBD|Node",
                                                  "Node"}}}},
             {"Field",    {{"Minimize",          "TTPkAssn*"},
                           {"Nodes",             "Node.ID"},
                           {"Skim Fields",       {{"Length",
                                                  "All"}}}}},
             {"Output",   {{"Output Matrix",     {{"Label",
                                                  "SPMAT_PXPRD"},
                                                  {"File Name",
                                                  Dir + "\\skims\\SPMAT_PXPRD.mtx"}}}}}}

     ret_value = RunMacro("TCB Run Procedure", 3, "TCSPMAT", Opts)
     if !ret_value then goto badpxprd


closemap()



// BUILD HOV SKIMS - only if HOV exists 

if s2i(theyear) < 2005 then do
	goto skiphovskims
	end

      
// STEP 1: Build Highway Network
     Opts = null
     Opts.Input.[Link Set] = {Dir + "\\"+netname+".DBD|"+netname, netname, "hwyskim", "Select * where (funcl > 0 and funcl < 10) or funcl = 22 or funcl = 23 or funcl = 82 or funcl = 83 or funcl =90"}
     Opts.Global.[Network Options].[Node ID] = "Node.ID"
     Opts.Global.[Network Options].[Link ID] = netname+".ID"
     Opts.Global.[Network Options].[Turn Penalties] = "Yes"
     Opts.Global.[Network Options].[Keep Duplicate Links] = "FALSE"
     Opts.Global.[Network Options].[Ignore Link Direction] = "FALSE"
     Opts.Global.[Link Options] = {{"Length", netname+".Length", netname+".Length"}, {"ImpFree*", netname+".ImpFreeAB", netname+".ImpFreeBA"}, {"ImpPk*", netname+".ImpPkAB", netname+".ImpPkBA"}, {"TTfree*", netname+".TTfreeAB", netname+".TTfreeBA"}, {"TTPkAssn*", netname+".TTPkAssnAB", netname+".TTPeakBA"}}
     Opts.Global.[Node Options].ID = "Node.ID"
     Opts.Output.[Network File] = Dir + "\\net_highway_hov.net"

     ret_value = RunMacro("TCB Run Operation", 5, "Build Highway Network", Opts)
     if !ret_value then goto badhwybldhov

// STEP 1a: Highway Network Setting
     Opts = null
     Opts.Input.Database = Dir + "\\"+netname+".DBD"
     Opts.Input.Network = Dir + "\\net_highway_hov.net"
     Opts.Input.[Centroids Set] = {Dir + "\\"+netname+".DBD|Node", "Node", "centroid", "Select * where centroid = 1 or centroid = 2"}

      ret_value = RunMacro("TCB Run Operation", 6, "Highway Network Setting", Opts)
     if !ret_value then goto badhwysethov


// STEP 3: TCSPMAT PEAK SPEED
     Opts = null
     Opts.Input.Network = Dir + "\\net_highway_hov.net"
     Opts.Input.[Origin Set] = {Dir + "\\"+netname+".DBD|Node", "Node", "centroid", "Select * where Centroid = 1 or centroid = 2"}
     Opts.Input.[Destination Set] = {Dir + "\\"+netname+".DBD|Node", "Node", "centroid"}
     Opts.Input.[Via Set] = {Dir + "\\"+netname+".DBD|Node", "Node"}
     Opts.Field.Minimize = "ImpPk*"
     Opts.Field.Nodes = "Node.ID"
     Opts.Field.[Skim Fields].Length = "All"
     Opts.Field.[Skim Fields].[TTPkAssn*] = "All"
     Opts.Output.[Output Matrix].Label = "SPMAT_Peak"
     Opts.Output.[Output Matrix].[File Name] = Dir + "\\skims\\SPMAT_peak_hov.mtx"

     ret_value = RunMacro("TCB Run Procedure", 8, "TCSPMAT", Opts)
     if !ret_value then goto badspmathovpeak


skiphovskims:


//Build matrices for hov and 

//template matrix 

TM = null
mc1 = null

TM = OpenMatrix(METDir + "\\taz\\matrix_template.mtx", "True")
mc1 = CreateMatrixCurrency(TM, "Table", "Rows", "Columns", )


       CopyMatrixStructure({mc1}, {{"File Name", Dir + "\\autoskims\\SPMAT_auto.mtx"},
           {"Label", "spmat_auto"},
           {"File Based", "Yes"},
           {"Tables", {"Non HOV TTPeak", "Non HOV Length", "Non HOV TermTT", "Non HOV Park Cost","HOV TTPeak","HOV Length","HOV TermTT", "HOV Time Saving", "HOV Park Cost"}},
           {"Operation", "Union"}})


//build skim tables for mode choice.  
// for models before 2005 - no HOV, copy all of the HOV stuff into the non HOV stuff

	if s2i(theyear) < 2005 then do
		goto spmatbeforeHOV
	end
	else do
		goto spmatafterHOV
	end

spmatbeforeHOV:
// Matrices:  IM1 - highway skims from highway side of model - no HOV   
//            IM2 - intraterm - intrazonal travel time and terminal times
//            IM3 - parking cost

	IM1 = OpenMatrix(Dir + "\\skims\\SPMAT_peak.mtx", "True")
	IM2 = OpenMatrix(Dir + "\\autoskims\\parkingcost.mtx", "True")
	IM3 = OpenMatrix(Dir + "\\autoskims\\Terminal_IntrazonalTT_Peak.mtx", "True")
	OM =  Openmatrix(Dir + "\\autoskims\\SPMAT_auto.mtx", "True")
	ic1 = CreateMatrixCurrency(IM1, "Length (Skim)", "Origin", "Destination",)
	ic2 = CreateMatrixCurrency(IM1, "TTPkAssn* (Skim)", "Origin", "Destination",)
	ic3 = CreateMatrixCurrency(IM2, "Peak park cost", "Rows", "Columns",)
	ic4 = CreateMatrixCurrency(IM3, "Peak", "Rows", "Columns",)

	oc1 = CreateMatrixCurrency(OM, "Non HOV TTPeak", "Rows", "Columns",)
	oc2 = CreateMatrixCurrency(OM, "Non HOV Length", "Rows", "Columns",)
	oc3 = CreateMatrixCurrency(OM, "Non HOV TermTT", "Rows", "Columns",)
	oc4 = CreateMatrixCurrency(OM, "Non HOV Park Cost", "Rows", "Columns",)
	oc5 = CreateMatrixCurrency(OM, "HOV TTPeak", "Rows", "Columns",)
	oc6 = CreateMatrixCurrency(OM, "HOV Length", "Rows", "Columns",)
	oc7 = CreateMatrixCurrency(OM, "HOV TermTT", "Rows", "Columns",)
	oc8 = CreateMatrixCurrency(OM, "HOV Time Saving", "Rows", "Columns",)
	oc9 = CreateMatrixCurrency(OM, "HOV Park Cost", "Rows", "Columns",)

	MatrixOperations(oc1, {ic2}, {1},,, {{"Operation", "Add"}, {"Force Missing", "No"}})
	MatrixOperations(oc2, {ic1}, {1},,, {{"Operation", "Add"}, {"Force Missing", "No"}})
	MatrixOperations(oc3, {ic2,ic4}, {1,1},,, {{"Operation", "Add"}, {"Force Missing", "No"}})
	MatrixOperations(oc4, {ic3}, {1},,, {{"Operation", "Add"}, {"Force Missing", "No"}})
	MatrixOperations(oc5, {ic2}, {1},,, {{"Operation", "Add"}, {"Force Missing", "No"}})
	MatrixOperations(oc6, {ic1}, {1},,, {{"Operation", "Add"}, {"Force Missing", "No"}})
	MatrixOperations(oc7, {ic2,ic4}, {1,1},,, {{"Operation", "Add"}, {"Force Missing", "No"}})
	MatrixOperations(oc8, {oc7,oc3}, {1,-1},,, {{"Operation", "Add"}, {"Force Missing", "No"}})
	MatrixOperations(oc9, {ic3}, {1},,, {{"Operation", "Add"}, {"Force Missing", "No"}})

    	ic1 = null
    	ic2 = null
    	ic3 = null
    	ic4 = null
    	oc1 = null
    	oc2 = null
    	oc3 = null
    	oc4 = null
    	oc5 = null
    	oc6 = null
    	oc7 = null
    	oc8 = null
    	oc9 = null
    	IM1 = null
    	IM2 = null
    	IM3 = null
    	OM = null  


goto alldone
spmatafterHOV:

//this version includes HOV travel times calculated above

        IM1 = OpenMatrix(Dir + "\\skims\\SPMAT_peak.mtx", "True")
        IM2 = OpenMatrix(Dir + "\\autoskims\\parkingcost.mtx", "True")
        IM3 = OpenMatrix(Dir + "\\autoskims\\Terminal_IntrazonalTT_Peak.mtx", "True")
        IM4 = OpenMatrix(Dir + "\\skims\\SPMAT_peak_hov.mtx", "True")
        OM =  Openmatrix(Dir + "\\autoskims\\SPMAT_auto.mtx", "True")
	ic1 = CreateMatrixCurrency(IM1, "Length (Skim)", "Origin", "Destination",)
	ic2 = CreateMatrixCurrency(IM1, "TTPkAssn* (Skim)", "Origin", "Destination",)
	ic3 = CreateMatrixCurrency(IM2, "Peak park cost", "Rows", "Columns",)
	ic4 = CreateMatrixCurrency(IM3, "Peak", "Rows", "Columns",)
	ic5 = CreateMatrixCurrency(IM4, "Length (Skim)", "Origin", "Destination",)
	ic6 = CreateMatrixCurrency(IM4, "TTPkAssn* (Skim)", "Origin", "Destination",)

	oc1 = CreateMatrixCurrency(OM, "Non HOV TTPeak", "Rows", "Columns",)
	oc2 = CreateMatrixCurrency(OM, "Non HOV Length", "Rows", "Columns",)
	oc3 = CreateMatrixCurrency(OM, "Non HOV TermTT", "Rows", "Columns",)
	oc4 = CreateMatrixCurrency(OM, "Non HOV Park Cost", "Rows", "Columns",)
	oc5 = CreateMatrixCurrency(OM, "HOV TTPeak", "Rows", "Columns",)
	oc6 = CreateMatrixCurrency(OM, "HOV Length", "Rows", "Columns",)
	oc7 = CreateMatrixCurrency(OM, "HOV TermTT", "Rows", "Columns",)
	oc8 = CreateMatrixCurrency(OM, "HOV Time Saving", "Rows", "Columns",)
	oc9 = CreateMatrixCurrency(OM, "HOV Park Cost", "Rows", "Columns",)

        MatrixOperations(oc1, {ic2}, {1},,, {{"Operation", "Add"}, {"Force Missing", "No"}})
        MatrixOperations(oc2, {ic1}, {1},,, {{"Operation", "Add"}, {"Force Missing", "No"}})
        MatrixOperations(oc3, {ic2,ic4}, {1,1},,, {{"Operation", "Add"}, {"Force Missing", "No"}})
        MatrixOperations(oc4, {ic3}, {1},,, {{"Operation", "Add"}, {"Force Missing", "No"}})
        MatrixOperations(oc5, {ic6}, {1},,, {{"Operation", "Add"}, {"Force Missing", "No"}})
        MatrixOperations(oc6, {ic5}, {1},,, {{"Operation", "Add"}, {"Force Missing", "No"}})
        MatrixOperations(oc7, {ic6,ic4}, {1,1},,, {{"Operation", "Add"}, {"Force Missing", "No"}})
        MatrixOperations(oc8, {oc7,oc3}, {1,-1},,, {{"Operation", "Add"}, {"Force Missing", "No"}})
        MatrixOperations(oc9, {ic3}, {1},,, {{"Operation", "Add"}, {"Force Missing", "No"}})

    ic1 = null
    ic2 = null
    ic3 = null
    ic4 = null
    ic5 = null
    ic6 = null
    oc1 = null
    oc2 = null
    oc3 = null
    oc4 = null
    oc5 = null
    oc6 = null
    oc7 = null
    oc8 = null
    oc9 = null
    IM1 = null
    IM2 = null
    IM3 = null
    IM4 = null
    OM = null  


goto quit

badpprmd:
	Throw("AutoSkims_Peak - error creating spmat_pprmd")
	// Throw("AutoSkims_Peak - error creating spmat_pprmd")
	// AppendToLogFile(1, "AutoSkims_Peak - error creating spmat_pprmd")
	// AutoSkimsPeakOK = 0
    // goto badquit

badpxprd:
	Throw("AutoSkims_Peak - error creating spmat_pxprd")
	// Throw("AutoSkims_Peak - error creating spmat_pxprd")
	// AppendToLogFile(1, "AutoSkims_Peak - error creating spmat_pxprd")
	// AutoSkimsPeakOK = 0
    // goto badquit

badhwybldhov:
	Throw("AutoSkims_Peak - error building highway network - hov network")
	// Throw("AutoSkims_Peak - error building highway network - hov network")
	// AppendToLogFile(1, "AutoSkims_Peak - error building highway network - hov network")
	// AutoSkimsPeakOK = 0
    // goto badquit

badhwysethov:
	Throw("AutoSkims_Peak - error highway network settings - hov network")
	// Throw("AutoSkims_Peak - error highway network settings - hov network")
	// AppendToLogFile(1, "AutoSkims_Peak - error highway network settings - hov network")
	// AutoSkimsPeakOK = 0
	// goto badquit

badspmathovpeak:
	Throw("AutoSkims_Peak - error highway skims - peak speed - hov network, free speed")
	// Throw("AutoSkims_Peak - error highway skims - peak speed - hov network, free speed")
	// AppendToLogFile(1, "AutoSkims_Peak - error highway skims - peak speed - hov network, free speed")
	// AutoSkimsPeakOK = 0
    // goto badquit

badquit:
    RunMacro("TCB Closing", 0, "TRUE" ) 
	RunMacro("G30 File Close All")
//       	Return( RunMacro("TCB Closing", 0, "TRUE" ) )
alldone:

	datentime = GetDateandTime()
	AppendToLogFile(1, "Exit AutoSkims_Peak: " + datentime)
	AppendToLogFile(1, " ")


quit:
	return({AutoSkimsPeakOK, msg})

endMacro