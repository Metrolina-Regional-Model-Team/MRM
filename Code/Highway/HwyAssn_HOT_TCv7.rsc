macro "HwyAssn_HOT" (Args, hwyassnarguments, timeperiod)

//*********************************************************************************************************************
// Macro sets input files and calls hwyassn_MMA
// This version runs hwyassn_BPR - hwyassn gc_mrm will not compile in ver 7		

// HOT lanes highway assignment - updated from assn_hot3
// changed minspfac to maxTTfac - reflecting what the factor really is doing
// New UI - McLelland, Jan, 2016
// 2/2/17, mk: edited to copy original (non-HOT) matrix at the beginning of each iteration
// 10/19/17, mk: edited to add toll-only (funcl 23) lanes

// MK, 5/29/19: This version uses funcl 24 as a de facto no-truck lane (for the PPSLs on I-77 North) (under: Opts.Input.[Exclusion Link Sets])
//  	(may need to clean up references if used in official model)
// 5/30/19, mk: There are now three distinct networks: AM peak, PM peak, and offpeak; pass correct netview through

//*********************************************************************************************************************

	// on error goto TCError
	on escape goto UserKill

	// LogFile = Args.[Log File].value
	// SetLogFileName(LogFile)
	// ReportFile = Args.[Report File].value
	// SetReportFileName(ReportFile)

	METDir = Args.[MET Directory]
	Dir = Args.[Run Directory]
	timeweight = Args.TimeWeight
	distweight = Args.DistWeight
	maxTTfac = Args.MaxTravTimeFactor

	HOTAssnIterations = Args.[HOTAssn Iterations]
	hwyassnmaxiter = Args.[HwyAssn Max Iter Feedback]
	hwyassnconverge = .01
	hwyassnmaxiterfinal = Args.[HwyAssn Max Iter Final]
	hwyassnconvergefinal = Args.[HwyAssn Converge]
	hwy_file = Args.[Hwy Name]
	{, , netview, } = SplitPath(hwy_file)

	user_threads = GetNumThreads()
	initial_threads = user_threads
	
	if user_threads <> 16
		then SetNumThreads(16)
		else do SetNumThreads(user_threads)
		end

	// can change to "BPR" to run straight BPR function
	hwyassntype = "BPR"
	/*
	if timeperiod = "AMpeak" then do	
		hwy_file = Args.[AM Peak Hwy Name]
		{, , netview, } = SplitPath(hwy_file)
	end
	else if timeperiod = "PMpeak" then do	
		hwy_file = Args.[PM Peak Hwy Name]
		{, , netview, } = SplitPath(hwy_file)
	end
	else if timeperiod = "Offpeak" then do	
		hwy_file = Args.[Offpeak Hwy Name]
	{, , netview, } = SplitPath(hwy_file)
	end
	else do
		Throw("HwyAssn_HOT: Bad time period")
	end
	*/

	PERIOD = hwyassnarguments[1]
	cap_field = hwyassnarguments[2]
	cap_fields = "[" + cap_field + "AB / " + cap_field + "BA]"
	od_matrix = Dir + hwyassnarguments[3]
	od_hot_matrix = Dir + hwyassnarguments[4]
	od_hotonly_matrix = Dir + hwyassnarguments[5]
	ODDir = Dir + hwyassnarguments[6]
	HOTin = Dir + hwyassnarguments[8] 
	assnDir = Dir + hwyassnarguments[8]
	input_bin = Dir + hwyassnarguments[9]
	output_bin = Dir + hwyassnarguments[10]

	temp = SplitPath(input_bin)
	input_name = temp[3]

	temp = SplitPath(output_bin)
	output_dcb = temp[1] + temp[2] + temp[3] + ".dcb"

	timewgtassn = sqrt(timeweight)
	
	net_file = Dir + "\\" + netview + ".dbd"

	msg = null

	HOTHwyAssnOK = 1
	datentime = GetDateandTime()
	AppendToLogFile(1, "Enter HwyAssn_HOT "+ PERIOD + " : " + datentime)
	AppendToLogFile(2, "HOT Assign Total Iterations: " + i2s(HOTAssnIterations))
	AppendToLogFile(2, "Feedback maximum travel time factor (x) * TTfree, x=" + r2s(distweight))

	if hwyassntype = "BPR"
		then AppendToLogFile(2, "HwyAssn Type = BPR")
		else do
			AppendToLogFile(2, "HwyAssn Type = gc_mrm - weighted travel time / distance")
			AppendToLogFile(2, "HwyAssn weight on travel time (minutes) = " + r2s(timeweight))
			AppendToLogFile(2, "HwyAssn weight on distance (miles) = " + r2s(distweight))
		end


  	RunMacro("TCB Init")

	
//      check highway network if hov lanes exist
//      hov2+ are funcl 22 and 82  (24 is now a peak-period shoulder lane that excludes trucks (I-77 North)
//      hov3+ are funcl 25 and 83 (23 now tollonly)
//	tollonly are funcl 23 and 83


	info = GetDBInfo(net_file)
	scope = info[1]
	CreateMap(netview, {{"Scope", scope},{"Auto Project", "True"}})
	layers = GetDBLayers(net_file)
	node_lyr = addlayer(netview, layers[1], net_file, layers[1])
	link_lyr = addlayer(netview, layers[2], net_file, layers[2])
	SetLayerVisibility(node_lyr, "False")
	SetIcon(node_lyr + "|", "Font Character", "Caliper Cartographic|4", 36)
	SetLayerVisibility(link_lyr, "True")
	solid = LineStyle({{{1, -1, 0}}})
	SetLineStyle(link_lyr+"|", solid)
	SetLineColor(link_lyr+"|", ColorRGB(0, 0, 32000))
	SetLineWidth(link_lyr+"|", 0)

	setview(netview)



///////////////////////////////////////////////////////////////////////
//***************************************************************
//								*
//   Add TTHOT and IMPHOT AB/BA fields if necessary 				*
//								*
//***************************************************************

	field_array = GetFields (netview, "All")
	fld_names = field_array[1]

	pos = ArrayPosition(fld_names,{"TTHOTAB"},)
	if pos = 0 
		then do
			strct = GetTableStructure(netview)
			for i = 1 to strct.length do
				strct[i] = strct[i] + {strct[i][1]}
			end
			new_struct = strct + {{"TTHOTAB", "Real", 10, 2, "True",,,, null}}
			ModifyTable(netview, new_struct)
		end

	pos = ArrayPosition(fld_names,{"TTHOTBA"},)
	if pos = 0 
		then do
			strct = GetTableStructure(netview)
			for i = 1 to strct.length do
				strct[i] = strct[i] + {strct[i][1]}
			end
			new_struct = strct + {{"TTHOTBA", "Real", 10, 2, "True",,,, null}}
			ModifyTable(netview, new_struct)
		end
	
	pos = ArrayPosition(fld_names,{"ImpHOTAB"},)
	if pos = 0 
		then do
			strct = GetTableStructure(netview)
			for i = 1 to strct.length do
				strct[i] = strct[i] + {strct[i][1]}
			end
			new_struct = strct + {{"ImpHOTAB", "Real", 10, 2, "True",,,, null}}
			ModifyTable(netview, new_struct)
		end

	pos = ArrayPosition(fld_names,{"ImpHOTBA"},)
	if pos = 0 
		then do
			strct = GetTableStructure(netview)
			for i = 1 to strct.length do
				strct[i] = strct[i] + {strct[i][1]}
			end
			new_struct = strct + {{"ImpHOTBA", "Real", 10, 2, "True",,,, null}}
			ModifyTable(netview, new_struct)
		end
	
//***********************************************************************************
//*   First pass - roll last NON-HOT assignment speed into TTHOT and recalc impedance
//**********************************************************************************

	Opts = null
	Opts.Input.[Dataview Set] = {{Dir + "\\"+netview+".dbd|"+netview, input_bin, "ID", "ID1"}, netview+input_name}
	Opts.Global.Fields = {"TTHOTAB","TTHOTBA"}
	Opts.Global.Method = "Formula"
	Opts.Global.Parameter = {"min(nz(AB_time), nz(TTfreeAB * "+i2s(maxTTfac)+"))", "min(nz(BA_time), nz(TTfreeBA * "+i2s(maxTTfac)+"))"}

	ret_value = RunMacro("TCB Run Operation", 1, "Fill Dataview", Opts)
	if !ret_value then goto badtt


	Opts = null
    Opts.Input.[Dataview Set] = {Dir + "\\"+netview+".dbd|"+netview, netview}
    Opts.Global.Fields = {"ImpHOTAB","ImpHOTBA"}
    Opts.Global.Method = "Formula"
    Opts.Global.Parameter = {"nz(TTHOTAB)* " + r2s(timeweight) +" + nz(length)* " + r2s(distweight), "nz(TTHOTBA)* " + r2s(timeweight) +" + nz(length)*" + r2s(distweight)}
    ret_value = RunMacro("TCB Run Operation", 2, "Fill Dataview", Opts)
    if !ret_value then goto badimp

//*******************************************************************
//*
//*  LOOP THROUGH ITERATIONS 
//*
//*******************************************************************


	for z = 1 to HOTAssnIterations do

		HOTAssnVersion = PERIOD + i2s(z)
		AppendToLogFile(2, "HOTAssign "+ HOTAssnVersion + " - iteration " + i2s(z) + " started")

		//create .dcb file for assignment
		CopyFile(assnDir + "\\Assn_template.dcb", assnDir + "\\Assn_" + PERIOD + i2s(z) + ".dcb")

//mk: removed this part, so that the original (non-HOT) OD matrix is copied.  Otherwise, we lose the HOT trips from the previous assignment.
/*		minfo = GetFileInfo(od_hot_matrix)
		if minfo = null 
			then do
				m = OpenMatrix(od_matrix, )
				mc = CreateMatrixCurrency(m, "SOV", "Rows", "Columns",)
				new_mat = CopyMatrix(mc, {{"File Name", od_hot_matrix},
				    {"Label", "ODHwyVeh_"+PERIOD+"hot"},
				    {"File Based", "Yes"}})
			end
*/		//ShowMessage("opened od_matrix")

//mk: add below part
m = OpenMatrix(od_matrix, )
mc = CreateMatrixCurrency(m, "SOV", "Rows", "Columns",)
new_mat = CopyMatrix(mc, {{"File Name", od_hot_matrix},
    {"Label", "ODHwyVeh_"+PERIOD+"hot"},
    {"File Based", "Yes"}})

		if Lower(GetView()) <> Lower(netview) then do

			info = GetDBInfo(net_file)
			scope = info[1]
			CreateMap(netview, {{"Scope", scope},{"Auto Project", "True"}})
			layers = GetDBLayers(net_file)
			node_lyr = addlayer(netview, layers[1], net_file, layers[1])
			link_lyr = addlayer(netview, layers[2], net_file, layers[2])
			SetLayerVisibility(node_lyr, "False")
			SetIcon(node_lyr + "|", "Font Character", "Caliper Cartographic|4", 36)
			SetLayerVisibility(link_lyr, "True")
			solid = LineStyle({{{1, -1, 0}}})
			SetLineStyle(link_lyr+"|", solid)
			SetLineColor(link_lyr+"|", ColorRGB(0, 0, 32000))
			SetLineWidth(link_lyr+"|", 0)

			setview(netview)
		end

//***************************************************************
//								*
//   Create highway network excluding hot lanes			*
//								*
//***************************************************************

// Build Highway Network
     	Opts = null
     	Opts.Input.[Link Set] = {Dir + "\\"+netview+".DBD|"+netview, netview, "GP", "Select * where (funcl > 0 and funcl < 10) or funcl = 90"}
     	Opts.Global.[Network Options].[Node ID] = "Node.ID"
     	Opts.Global.[Network Options].[Link ID] = netview+".ID"
     	Opts.Global.[Network Options].[Turn Penalties] = "Yes"
     	Opts.Global.[Network Options].[Keep Duplicate Links] = "FALSE"
     	Opts.Global.[Network Options].[Ignore Link Direction] = "FALSE"
     	Opts.Global.[Link Options] = {{"Length", netview+".Length", netview+".Length"}, {"[ImpHOTAB / ImpHOTBA]", netview+".ImpHOTAB", netview+".ImpHOTBA"}, {"[TTHOTAB / TTHOTBA]", netview+".TTHOTAB", netview+".TTHOTBA"}}
     	Opts.Output.[Network File] = Dir + "\\net_gp.net"

     	ret_value = RunMacro("TCB Run Operation", 3, "Build Highway Network", Opts)
     	if !ret_value then goto badnetbuild
		AppendToLogFile(3, "HOT Assn " + HOTAssnVersion  + " - Build Network - No HOT lanes")

//ShowMessage("Built Network")
//***************************************************************
//								*
//   Skim highway network minimizing ImpHOTAB/BA			*
//								*
//***************************************************************

//Highway Network Setting
     	Opts = null
     	Opts.Input.Database = Dir + "\\"+netview+".DBD"
     	Opts.Input.Network = Dir + "\\net_gp.net"
     	Opts.Input.[Centroids Set] = {Dir + "\\"+netview+".DBD|Node", "Node", "centroid", "Select * where centroid = 1 or centroid = 2"}
		Opts.Input.[Spc Turn Pen Table]= {METDir + "\\trnpnlty.bin"}
     	Opts.Global.[Global Turn Penalties] = {0, 0, 0, -1}


     	ret_value = RunMacro("TCB Run Operation", 4, "Highway Network Setting", Opts)
     	if !ret_value then goto badnetsettings
		AppendToLogFile(3, "HOT Assn " + HOTAssnVersion  + " - Network setings - No HOT lanes")

     	Opts = null
     	Opts.Input.Network = Dir + "\\net_gp.net"
     	Opts.Input.[Origin Set] = {Dir + "\\"+netview+".DBD|Node", "Node", "centroid", "Select * where Centroid = 1 or centroid = 2"}
     	Opts.Input.[Destination Set] = {Dir + "\\"+netview+".DBD|Node", "Node", "centroid"}
     	Opts.Input.[Via Set] = {Dir + "\\"+netview+".DBD|Node", "Node"}
     	Opts.Field.Minimize = "[ImpHOTAB / ImpHOTBA]"
     	Opts.Field.Nodes = "Node.ID"
     	Opts.Field.[Skim Fields] = {{"[TTHOTAB / TTHOTBA] ", "All"}}
     	Opts.Output.[Output Matrix].Label = "SPMAT_GP_"+PERIOD+r2s(z)
     	Opts.Output.[Output Matrix].[File Name] = Dir + "\\skims\\SPMAT_GP_"+PERIOD+r2s(z)+".mtx"

     	ret_value = RunMacro("TCB Run Procedure", 5, "TCSPMAT", Opts)
 
     	if !ret_value then goto badskim
		AppendToLogFile(3, "HOT Assn " + HOTAssnVersion  + " - Hwy Skim - No HOT lanes")

//ShowMessage("Created Skims")
//***************************************************************
//								*
//   Create highway network with hot lanes			*
//								*
//***************************************************************
// Build Highway Network
     	Opts = null
     	Opts.Input.[Link Set] = {Dir + "\\"+netview+".DBD|"+netview, netview, "HOT", "Select * where (funcl > 0 and funcl < 10) or funcl = 90 or funcl = 22 or funcl = 24 or funcl = 82 or funcl = 23 or funcl = 25 or funcl = 83"}
     	Opts.Global.[Network Options].[Node ID] = "Node.ID"
     	Opts.Global.[Network Options].[Link ID] = netview+".ID"
     	Opts.Global.[Network Options].[Turn Penalties] = "Yes"
     	Opts.Global.[Network Options].[Keep Duplicate Links] = "FALSE"
     	Opts.Global.[Network Options].[Ignore Link Direction] = "FALSE"

     	Opts.Global.[Link Options] = {{"Length", netview+".Length", netview+".Length"}, {"[ImpHOTAB / ImpHOTBA]", netview+".ImpHOTAB", netview+".ImpHOTBA"}, {"[TTHOTAB / TTHOTBA] ", netview+".TTHOTAB", netview+".TTHOTBA"}, {"[HOTAB / HOTBA]", netview+".HOTAB", netview+".HOTBA"}}
     	Opts.Output.[Network File] = Dir + "\\net_hot.net"

     	ret_value = RunMacro("TCB Run Operation", 6, "Build Highway Network", Opts)
     	if !ret_value then goto badnetbuild
		AppendToLogFile(3, "HOT Assn " + HOTAssnVersion  + " - Build Network - With HOT lanes")

//***************************************************************
//								*
//    Skim highway network minimizing TTHot			*
//								*
//***************************************************************

//Highway Network Setting
     	Opts = null
     	Opts.Input.Database = Dir + "\\"+netview+".DBD"
     	Opts.Input.Network = Dir + "\\net_hot.net"
     	Opts.Input.[Centroids Set] = {Dir + "\\"+netview+".DBD|Node", "Node", "centroid", "Select * where centroid = 1 or centroid = 2"}
		Opts.Input.[Spc Turn Pen Table]= {METDir + "\\trnpnlty.bin"}
//???  	Opts.Input.[Toll Set]= {Dir + "\\"+netview+".DBD|"+netview, netview, "tollset", "Select * where HOTAB > 0 or HOTBA > 0"}
    	Opts.Global.[Global Turn Penalties] = {0, 0, 0, -1}

     	ret_value = RunMacro("TCB Run Operation", 7, "Highway Network Setting", Opts)

     	if !ret_value then goto badnetsettings
		AppendToLogFile(3, "HOT Assn " + HOTAssnVersion  + " - Network Settings - With HOT lanes")

     	Opts = null
     	Opts.Input.Network = Dir + "\\net_hot.net"
     	Opts.Input.[Origin Set] = {Dir + "\\"+netview+".DBD|Node", "Node", "centroid", "Select * where Centroid = 1 or centroid = 2"}
     	Opts.Input.[Destination Set] = {Dir + "\\"+netview+".DBD|Node", "Node", "centroid"}
     	Opts.Input.[Via Set] = {Dir + "\\"+netview+".DBD|Node", "Node"}
     	Opts.Field.Minimize = "[ImpHOTAB / ImpHOTBA]"
     	Opts.Field.Nodes = "Node.ID"
     	Opts.Field.[Skim Fields] = {{"[TTHOTAB / TTHOTBA] ", "All"}, {"[HOTAB / HOTBA]", "All"}}
     	Opts.Output.[Output Matrix].Label = "SPMAT_HOT_"+PERIOD+r2s(z)
     	Opts.Output.[Output Matrix].[File Name] = Dir + "\\skims\\SPMAT_HOT_"+PERIOD+r2s(z)+".mtx"

     	ret_value = RunMacro("TCB Run Procedure", 8, "TCSPMAT", Opts)
     	if !ret_value then goto badskim
		AppendToLogFile(3, "HOT Assn " + HOTAssnVersion  + " - Hwy Skim - WITH HOT lanes")

//ShowMessage("HOT Network and Skims")

//***************************************************************
//								*
// Add 4 cores to SPMAT_HOT matrix TTSav,CPMS and CPMS_VOT   *
//  								*
//***************************************************************
//ShowMessage(netview)

		HOT = OpenMatrix(Dir + "\\skims\\SPMAT_HOT_"+PERIOD+r2s(z)+".mtx", "True")
		core_list = GetMatrixCoreNames(HOT)
// Look for a cores named "TTSAV, CPMS"

		TTSAVpos = ArrayPosition(core_list, {"TTSAV"}, )
		CPMSpos = ArrayPosition(core_list, {"CPMS"}, )
		CPMS_VOTpos = ArrayPosition(core_list, {"CPMS_VOT"}, )
		Percentpos = ArrayPosition(core_list, {"PERCENT"}, )

// If there isn�t one, add it; if there is one, go to next step

		if TTSAVpos = 0 then
    	 	AddMatrixCore(HOT, "TTSav")
		if CPMSpos = 0 then
			AddMatrixCore(HOT, "CPMS")
		if CPMS_VOTpos = 0 then
			AddMatrixCore(HOT, "CPMS_VOT")
		if Percentpos = 0 then
			AddMatrixCore(HOT, "PERCENT")
		else goto Fill_Cores
		HOT = null

//ShowMessage("Added 4 cores to SPMAT_HOT")
//***************************************************************
//								*
//  Fill the TOD TTSav cores with the difference of		*
//  Skim_GP and Skim_HOT					*
//  								*
//***************************************************************
		Fill_Cores:
        HOT = OpenMatrix(Dir + "\\skims\\SPMAT_HOT_"+PERIOD+r2s(z)+".mtx", "True")
//ShowMessage("Opened SPMAT_HOT")
        GP = OpenMatrix(Dir + "\\skims\\SPMAT_GP_"+PERIOD+r2s(z)+".mtx", "True")
//ShowMessage("Opened SPMAT_GP")

//STEP 1: Fill Matrices
		Opts = null
		Opts.Input.[Matrix Currency] = {Dir+"\\skims\\SPMAT_HOT_"+PERIOD+r2s(z)+".mtx", "TTSav", "Origin", "Destination"}
		Opts.Input.[Core Currencies] = {{Dir+"\\skims\\SPMAT_GP_"+PERIOD+r2s(z)+".mtx", "[TTHOTAB / TTHOTBA] (Skim)", "Origin", "Destination"}, {Dir+"\\skims\\SPMAT_HOT_"+PERIOD+r2s(z)+".mtx", "[TTHOTAB / TTHOTBA]  (Skim)", "Origin", "Destination"}}
		Opts.Global.Method = 8
		Opts.Global.[Cell Range] = 2
		Opts.Global.[Matrix K] = {1, 1}
		Opts.Global.[Force Missing] = "No"

		ret_value = RunMacro("TCB Run Operation", 9, "Fill Matrices", Opts, &Ret)

		if !ret_value then goto badfill1
		AppendToLogFile(3, "HOT Assn " + HOTAssnVersion  + " - Fill TTSav core")

//	c1 = CreateMatrixCurrency(HOT, "TTHOTAB / TTHOTBA  (Skim)", "Origin", "Destination",)
//ShowMessage("CreateMatrixCurrency HOT")
//	c2 = CreateMatrixCurrency(GP, "TTHOTAB / TTHOTBA (Skim)", "Origin", "Destination",)
//ShowMessage("CreateMatrixCurrency_GP")
//	c3 = CreateMatrixCurrency(HOT, "TTSav", "Origin", "Destination",)
//ShowMessage("CreateMatrixCurrency_HOT")
//        MatrixOperations(c3, {c2,c1}, {1,1},,, {{"Operation", "Subtract"}, {"Force Missing", "No"}})

//    	c1 = null
//    	c2 = null
//    	c3 = null
//   	HOT = null
//    	GP = null
//ShowMessage("filled TTSav")
//***************************************************************
//								*
//  Filling CPMS and CPMS_VOT					*
//								*
//***************************************************************
//ShowMessage(netview)

// STEP 1: Fill Matrices
		Opts = null
		Opts.Input.[Matrix Currency] = {Dir+"\\skims\\SPMAT_HOT_"+PERIOD+r2s(z)+".mtx", "TTSav", "Origin", "Destination"}
		Opts.Global.Method = 11
		Opts.Global.[Cell Range] = 2
		Opts.Global.[Expression Text] = "if [TTSav] < 0 then 0 else [TTSav]"
		Opts.Global.[Force Missing] = "Yes"

		ret_value = RunMacro("TCB Run Operation", 10, "Fill Matrices", Opts)
     	if !ret_value then goto badfill


		Opts = null
		Opts.Input.[Matrix Currency] = {Dir+"\\skims\\SPMAT_HOT_"+PERIOD+r2s(z)+".mtx", "CPMS", "Origin", "Destination"}
		Opts.Global.Method = 11
		Opts.Global.[Cell Range] = 2
		Opts.Global.[Expression Text] = "if TTSav <>0 then [[HOTAB / HOTBA] (Skim)]/ [TTSav] else 100"
		Opts.Global.[Force Missing] = "Yes"

		ret_value = RunMacro("TCB Run Operation", 11, "Fill Matrices", Opts)
     	if !ret_value then goto badfill


		Opts = null
		Opts.Input.[Matrix Currency] = {Dir+"\\skims\\SPMAT_HOT_"+PERIOD+r2s(z)+".mtx", "CPMS_VOT", "Origin", "Destination"}
		Opts.Global.Method = 11
		Opts.Global.[Cell Range] = 2
		Opts.Global.[Expression Text] = "Round(CPMS / 0.165,2)"
		Opts.Global.[Force Missing] = "Yes"

		ret_value = RunMacro("TCB Run Operation", 12, "Fill Matrices", Opts)
     	if !ret_value then goto badfill

		//ShowMessage("filled CPMS & CPMS_VOT")

		//***************************************************************
		//								*
		//  Export Matrix to obtain the percentages			*
		//								*
		//***************************************************************

		HOT = OpenMatrix(Dir + "\\skims\\SPMAT_HOT_"+PERIOD+r2s(z)+".mtx", "True")
		CreateTableFromMatrix(HOT ,Dir +  "\\skims\\HOT_"+PERIOD+r2s(z)+".dbf", "DBASE", {{"Complete", "Yes"}})
		AppendToLogFile(3, "HOT Assn " + HOTAssnVersion  + " - HOT matrix to dbf")

		//ShowMessage("Created HOT_AM.dbf")
		//***************************************************************
		//	Create HOT_Table.bin							*
		// Fill the Percent column with the lookup table values	and	*
		//	make new matrix						*
		//***************************************************************

		info = GetFileInfo(METDir + "\\HOT_Table.hot")
		if info = null 
			then do
				Throw("HwyAssn_HOT - ERROR! - \\Metrolina\\HOT_Table.hot not found")
				AppendToLogFile(2, "HwyAssn_HOT - ERROR! - \\Metrolina\\HOT_Table.hot not found")
				HOTHwyAssnOK = 0
				goto badHOTtable
 			end
			else do
				CopyFile(METDir + "\\HOT_Table.hot", METDir + "\\HOT_Table.bin")
				dcbname = METDir + "\\HOT_Table.DCB"	 
				exist = GetFileInfo(dcbname)
				if (exist <> null) then DeleteFile(dcbname)
				mac = OpenFile(dcbname, "w")
				WriteLine(mac, " ")
				WriteLine(mac, "16")
				WriteLine(mac, "\"CPMS_VOT\",R,1,8,0,8,2,,,\"\",,Blank,")
				WriteLine(mac, "\"PERCENT\",R,9,8,0,8,1,,,\"\",,Blank,")
				CloseFile(mac)
			end

		HOT_Table = OpenTable("HOT_Table", "FFB", {METDir + "\\HOT_Table.bin"}, {{"Read Only", "False"},{"Shared", "False"}})
 
		

		Opts = null
		Opts.Input.[Dataview Set] = {{Dir +"\\skims\\HOT_"+PERIOD+r2s(z)+".DBF", METDir + "\\HOT_Table.bin", "CPMS_VOT", "CPMS_VOT"}, "HOT_"+PERIOD+r2s(z)+"+HOT_Table"}
		Opts.Global.Fields = {"HOT_"+PERIOD+r2s(z)+".PERCENT"}
		Opts.Global.Method = "Formula"
		Opts.Global.Parameter = "HOT_Table.PERCENT"

		ret_value = RunMacro("TCB Run Operation", 13, "Fill Dataview", Opts)
     	if !ret_value then goto badfill

		CloseView("HOT_Table")
		DeleteFile(METDir + "\\HOT_Table.bin")
		DeleteFile(METDir + "\\HOT_Table.DCB")
		
		Opts = null
		Opts.Input.[Dataview Set] = {Dir +"\\skims\\HOT_"+PERIOD+r2s(z)+".DBF", "Percent"}
		Opts.Global.Fields = {"PERCENT"}
		Opts.Global.Method = "Formula"
		Opts.Global.Parameter = "If Percent = null then 0 else Percent"

		ret_value = RunMacro("TCB Run Operation", 14, "Fill Dataview", Opts)
     	if !ret_value then goto badfill


		OpenTable("HOT_"+PERIOD+r2s(z), "DBASE", {Dir + "\\skims\\HOT_"+PERIOD+r2s(z)+".dbf",})
		//ShowMessage ("Got Here")
		mv = CreateMatrixFromView("HOT_"+PERIOD+r2s(z),"HOT_"+PERIOD+r2s(z)+"|","Origin","Destinatio",{"PERCENT"},
			{{"File Name",Dir+"\\skims\\Percent_"+PERIOD+r2s(z)+".mtx"},
			 {"Type","Float"},{"Sparse", "No" },{"Column Major", "No" },{"File Based", "Yes" }})
		//ShowMessage ("Got Here")
		closeview("HOT_"+PERIOD+r2s(z))

		//ShowMessage("created percent_ampeak.mtx")

		//***************************************************************
		//								*
		// Multiply the values in PERCENT by .01			*
		//								*
		//***************************************************************
		Opts = null
		Opts.Input.[Matrix Currency] = {Dir+"\\skims\\Percent_"+PERIOD+r2s(z)+".mtx", "PERCENT", "Origin", "Destinatio"}
		Opts.Global.Method = 11
		Opts.Global.[Cell Range] = 2
		Opts.Global.[Expression Text] = "[PERCENT] * 0.01"
		Opts.Global.[Force Missing] = "Yes"

		ret_value = RunMacro("TCB Run Operation", 15, "Fill Matrices", Opts)
     	if !ret_value then goto badfill

		//***************************************************************Gallup
		//								*Gallup
		// Add 4 cores to OD matricies HOT				*Gallup		changed to 4 cores for tollonly
		//  								*Gallup
		//***************************************************************Gallup
		HOT = OpenMatrix(od_hot_matrix,)

		HOT_Cores = GetMatrixCoreNames(HOT)
	
		gotSOV = "False"
		gotP2 = "False"
		gotP3 = "False"
		gotCOM = "False"

		for i = 1 to HOT_Cores.length do
			if HOT_Cores[i] = "HOTSOV" then gotSOV = "True"
			if HOT_Cores[i] = "HOTPOOL2" then gotP2 = "True"
			if HOT_Cores[i] = "HOTPOOL3" then gotP3 = "True"		//added for tollonly
			if HOT_Cores[i] = "HOTCOM" then gotCOM = "True"
		end

		if gotSOV = "False" then AddMatrixCore(HOT, "HOTSOV")
		if gotP2 = "False" then AddMatrixCore(HOT, "HOTPOOL2")
		if gotP3 = "False" then AddMatrixCore(HOT, "HOTPOOL3")		//added for tollonly
		if gotCOM = "False" then AddMatrixCore(HOT, "HOTCOM")


		//***************************************************************
		//								*
		// Fill HOTSOV core with SOV * PERCENT				*
		//  								*
		//***************************************************************

		// STEP 1: Fill Matrices
		Opts = null
		Opts.Input.[Matrix Currency] = {od_hot_matrix, "HOTSOV", "Rows", "Columns"}
		Opts.Input.[Core Currencies] = {{od_hot_matrix, "SOV", "Rows", "Columns"}, 
			{Dir + "\\skims\\Percent_"+PERIOD+r2s(z)+".mtx", "PERCENT", "Origin", "Destinatio"}}
		Opts.Global.Method = 9
		Opts.Global.[Cell Range] = 2
		Opts.Global.[Matrix K] = {1, 1}
		Opts.Global.[Force Missing] = "Yes"

		ret_value = RunMacro("TCB Run Operation", 16, "Fill Matrices", Opts)
     	if !ret_value then goto badfill
		AppendToLogFile(3, "HOT Assn " + HOTAssnVersion  + " - Fill HOT trips")

		//ShowMessage("filled HOTSOV")

		//***************************************************************Gallup
		//								*Gallup
		// Fill HOTPOOL2 core with POOL2 * PERCENT			*Gallup
		//  								*Gallup
		//***************************************************************Gallup

		// STEP 1: Fill Matrices
		Opts = null
		Opts.Input.[Matrix Currency] = {od_hot_matrix, "HOTPOOL2", "Rows", "Columns"}
		Opts.Input.[Core Currencies] = {{od_hot_matrix, "POOL2", "Rows", "Columns"}, 
			{Dir + "\\skims\\Percent_"+PERIOD+r2s(z)+".mtx", "PERCENT", "Origin", "Destinatio"}}
		Opts.Global.Method = 9
		Opts.Global.[Cell Range] = 2
		Opts.Global.[Matrix K] = {1, 1}
		Opts.Global.[Force Missing] = "Yes"

		ret_value = RunMacro("TCB Run Operation", 17, "Fill Matrices", Opts)
     	if !ret_value then goto badfill

		//ShowMessage("filled HOTPOOL2")

		//***************************************************************MK
		//								*MK
		// Fill HOTPOOL3 core with POOL3 * PERCENT			*MK
		//  								*MK
		//***************************************************************MK

		// STEP 1: Fill Matrices
		Opts = null
		Opts.Input.[Matrix Currency] = {od_hot_matrix, "HOTPOOL3", "Rows", "Columns"}
		Opts.Input.[Core Currencies] = {{od_hot_matrix, "POOL3", "Rows", "Columns"}, 
			{Dir + "\\skims\\Percent_"+PERIOD+r2s(z)+".mtx", "PERCENT", "Origin", "Destinatio"}}
		Opts.Global.Method = 9
		Opts.Global.[Cell Range] = 2
		Opts.Global.[Matrix K] = {1, 1}
		Opts.Global.[Force Missing] = "Yes"

		ret_value = RunMacro("TCB Run Operation", 17, "Fill Matrices", Opts)
     	if !ret_value then goto badfill

		//ShowMessage("filled HOTPOOL3")

		//***************************************************************Gallup
		//								*Gallup
		// Fill HOTCOM core with COM * PERCENT				*Gallup
		//  								*Gallup
		//***************************************************************Gallup

		// STEP 1: Fill Matrices
		Opts = null
		Opts.Input.[Matrix Currency] = {od_hot_matrix, "HOTCOM", "Rows", "Columns"}
		Opts.Input.[Core Currencies] = {{od_hot_matrix, "COM", "Rows", "Columns"}, 
			{Dir + "\\skims\\Percent_"+PERIOD+r2s(z)+".mtx", "PERCENT", "Origin", "Destinatio"}}
		Opts.Global.Method = 9
		Opts.Global.[Cell Range] = 2
		Opts.Global.[Matrix K] = {1, 1}
		Opts.Global.[Force Missing] = "Yes"

		ret_value = RunMacro("TCB Run Operation", 18, "Fill Matrices", Opts)
     	if !ret_value then goto badfill

		//ShowMessage("filled HOTCOM")

		//***************************************************************Gallup
		//								*Gallup
		// Subtract HOTSOV from SOV					*Gallup
		//  								*Gallup
		//***************************************************************Gallup

		Opts = null
		Opts.Input.[Matrix Currency] = {od_hot_matrix, "SOV", "Rows", "Columns"}
		Opts.Global.Method = 11
		Opts.Global.[Cell Range] = 2
		Opts.Global.[Expression Text] = "[SOV]- [HOTSOV]"
		Opts.Global.[Force Missing] = "Yes"

		ret_value = RunMacro("TCB Run Operation", 19, "Fill Matrices", Opts)
     	if !ret_value then goto badfill

		//ShowMessage("subtracted HOTSOV")

		//***************************************************************Gallup
		//								*Gallup
		// Subtract HOTPOOL2 from POOL2					*Gallup
		//  								*Gallup
		//***************************************************************Gallup

		Opts = null
		Opts.Input.[Matrix Currency] = {od_hot_matrix, "POOL2", "Rows", "Columns"}
		Opts.Global.Method = 11
		Opts.Global.[Cell Range] = 2
		Opts.Global.[Expression Text] = "[POOL2]- [HOTPOOL2]"
		Opts.Global.[Force Missing] = "Yes"

		ret_value = RunMacro("TCB Run Operation", 20, "Fill Matrices", Opts)
     	if !ret_value then goto badfill

		//ShowMessage("subtracted HOTPOOL2")

		//***************************************************************MK
		//								*MK
		// Subtract HOTPOOL3 from POOL3					*MK
		//  								*MK
		//***************************************************************MK

		Opts = null
		Opts.Input.[Matrix Currency] = {od_hot_matrix, "POOL3", "Rows", "Columns"}
		Opts.Global.Method = 11
		Opts.Global.[Cell Range] = 2
		Opts.Global.[Expression Text] = "[POOL3]- [HOTPOOL3]"
		Opts.Global.[Force Missing] = "Yes"

		ret_value = RunMacro("TCB Run Operation", 20, "Fill Matrices", Opts)
     	if !ret_value then goto badfill

		//ShowMessage("subtracted HOTPOOL3")

		//***************************************************************Gallup
		//								*Gallup
		// Subtract HOTCOM from COM					*Gallup
		//  								*Gallup
		//***************************************************************Gallup

		Opts = null
		Opts.Input.[Matrix Currency] = {od_hot_matrix, "COM", "Rows", "Columns"}
		Opts.Global.Method = 11
		Opts.Global.[Cell Range] = 2
		Opts.Global.[Expression Text] = "[COM]- [HOTCOM]"
		Opts.Global.[Force Missing] = "Yes"

		ret_value = RunMacro("TCB Run Operation", 21, "Fill Matrices", Opts)
     	if !ret_value then goto badfill

		//ShowMessage("subtracted HOTCOM")


		//***************************************************************
		//								*
		//  Assignment							*
		//								*
		//***************************************************************

		//ShowMessage("HOT Matrix")

		//skiparound:

		//Network has HOV2, HOV3 & tollonly lanes 
		//exclude link sets for 10 vol classes
		// 1 = sov - exclude from hov2+ , hov3+ & tollonly (funcl 22,24,82 & 25,83 & 23=sovexclude)
		// 2 = pool2 - exclude from hov3+ & tollonly (funcl 25,83 & 23=pool2exclude)
		// 3 = pool3 - exclude from tollonly (funcl 23=pool3exclude)
		// 4 = COM - exclude from all hov (sovexclude)
		// 5 = MTK - exclude from all hov (sovexclude)
		// 6 = HTK - exclude from all hov (sovexclude)
		// 7 = HOTSOV - no exclude 
		// 8 = HOTPOOL2 - no exclude
		// 9 = HOTPOOL3 - no exclude
		// 10 = HOTCOM - no exclude

		//Build Highway Network
		Opts = null
     	Opts.Input.[Link Set] = {Dir + "\\"+netview+".DBD|"+netview, netview, "hwynet", "Select * where (funcl > 0 and funcl < 10) or funcl = 22 or funcl = 23 or funcl = 24 or funcl = 25 or funcl = 82 or funcl = 83 or funcl = 90"}
		Opts.Global.[Network Options].[Link Type] = {"funcl", netview+".funcl", netview+".funcl"}
		Opts.Global.[Network Options].[Time Unit] = "Minutes"
		Opts.Global.[Network Options].[Node ID] = "Node.ID"
		Opts.Global.[Network Options].[Link ID] = netview+".ID"
		Opts.Global.[Network Options].[Turn Penalties] = "Yes"
		Opts.Global.[Network Options].[Keep Duplicate Links] = "FALSE"
		Opts.Global.[Network Options].[Ignore Link Direction] = "FALSE"
		Opts.Global.[Link Options] = 
			{{"Length", {netview+".Length", netview+".Length", , , "False"}}, 
			 {"alpha", {netview+".alpha", netview+".alpha", , , "False"}},
			 {"beta", {netview+".beta", netview+".beta", , , "False"}}, 
			 {"[TTFreeAB / TTFreeBA]", {netview+".TTFreeAB", netview+".TTFreeBA", , , "True"}},
			 {"[CapPk3hrAB / CapPk3hrBA]", {netview+".CapPk3hrAB", netview+".CapPk3hrBA", , , "False"}},
			 {"[capMidAB / capMidBA]", {netview+".capMidAB", netview+".capMidBA", , , "False"}},
			 {"[capNightAB / capNightBA]", {netview+".capNightAB", netview+".capNightBA", , , "False"}},
			 {"[TollAB / TollBA]", {netview+".TollAB", netview+".TollBA", , , "False"}}}
		Opts.Global.[Length Unit] = "Miles"
		Opts.Global.[Time Unit] = "Minutes"
 		Opts.Output.[Network File] = Dir + "\\net_highway.net"

		ret_value = RunMacro("TCB Run Operation", 22, "Build Highway Network", Opts, &Ret)
    	if !ret_value then goto badnetbuild
		AppendToLogFile(3, "HOT Assn " + HOTAssnVersion  + " - Highway nework settings for assign")

		// Highway Network Setting
	
		// determine if toll links present
		SetView(netview)
		tollquery = "Select * where TollAB > 0 or TollBA > 0"
		ntolls = SelectByQuery("TollLinks", "Several", tollquery,)
		 
		if ntolls = 0 then goto notolls2

		Opts = null
		Opts.Input.Database = Dir + "\\"+netview+".DBD"
		Opts.Input.Network = Dir + "\\net_highway.net"
		Opts.Input.[Centroids Set] = {Dir + "\\"+netview+".DBD|Node", "Node", "centroid", "Select * where centroid = 1 or centroid = 2"}
		Opts.Input.[Spc Turn Pen Table]= {METDir + "\\trnpnlty.bin"}
		Opts.Input.[Toll Set]= {Dir + "\\"+netview+".DBD|"+netview, netview, "tollset", "Select * where TollAB > 0 or TollBA > 0"}
		Opts.Global.[Global Turn Penalties] = {0, 0, 0, -1}

		ret_value = RunMacro("TCB Run Operation", 23, "Highway Network Setting", Opts, &Ret)
		if !ret_value then goto badnetsettings
		AppendToLogFile(3, "HOT Assn " + HOTAssnVersion  + " - Network settings with tolls")
		goto skipnotolls2

		notolls2:
		Opts = null
		Opts.Input.Database = Dir + "\\"+netview+".DBD"
		Opts.Input.Network = Dir + "\\net_highway.net"
		Opts.Input.[Centroids Set] = {Dir + "\\"+netview+".DBD|Node", "Node", "centroid", "Select * where centroid = 1 or centroid = 2"}
		Opts.Input.[Spc Turn Pen Table]= {METDir + "\\trnpnlty.bin"}
		Opts.Global.[Global Turn Penalties] = {0, 0, 0, -1}

		ret_value = RunMacro("TCB Run Operation", 24, "Highway Network Setting", Opts, &Ret)
		if !ret_value then goto badnetsettings
		AppendToLogFile(3, "HOT Assn " + HOTAssnVersion  + " - Network settings - No tolls")

		skipnotolls2:

		// MMA Assignment 
		//exclude link sets for 10 vol classes
		// 1 = sov - exclude from hov2+ , hov3+ & tollonly (funcl 22,82 & 25,83 & 23=sovexclude)
		// 2 = pool2 - exclude from hov3+ & tollonly (funcl 25,83 & 23=pool2exclude)
		// 3 = pool3 - exclude from tollonly (funcl 23=pool3exclude)
		// 4 = COM - exclude from all hov (sovexclude)
		// 5 = MTK - exclude from all hov & funcl 24 (truckexclude)
		// 6 = HTK - exclude from all hov & funcl 24 (truckexclude)
		// 7 = HOTSOV - no exclude 
		// 8 = HOTPOOL2 - no exclude
		// 9 = HOTPOOL3 - no exclude
		// 10 = HOTCOM - no exclude

		//showmessage(od_hot_matrix+" "+cap_fields+" "+output_bin+" "+netview+" "+Dir+" "+METDir)
		Opts = null
		Opts.Input.Database = Dir + "\\"+netview+".DBD"
		Opts.Input.Network = Dir + "\\net_highway.net"
		Opts.Input.[OD Matrix Currency] = {od_hot_matrix, "SOV", "Rows", "Columns"}
		Opts.Input.[Exclusion Link Sets] = 
			{{Dir + "\\"+netview+".DBD|"+netview, netview, "sovexclude", 
							"Select * where funcl = 22 or funcl = 23 or funcl = 25"}, 
			 {Dir + "\\"+netview+".DBD|"+netview, netview, "pool2exclude", 
			 				"Select * where funcl = 23 or funcl = 25"},
			 {Dir + "\\"+netview+".DBD|"+netview, netview, "pool3exclude", 
			 				"Select * where funcl = 23"},
			 {Dir + "\\"+netview+".DBD|"+netview, netview, "sovexclude"}, 
			 {Dir + "\\"+netview+".DBD|"+netview, netview, "trkexclude", "Select * where funcl = 22 or funcl = 23 or funcl = 24 or funcl = 25 or funcl = 82 or funcl = 83"}, 
			 {Dir + "\\"+netview+".DBD|"+netview, netview, "trkexclude"}, , , ,}
		Opts.Field.[Vehicle Classes] = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10}
 		Opts.Field.[PCE Fields] = {"None", "None", "None", "None", "None", "None", "None", "None", "None", "None"}
		Opts.Global.[Number of Classes] = 10
		Opts.Field.[Fixed Toll Fields] = {"[TollAB / TollBA]", "[TollAB / TollBA]", "[TollAB / TollBA]", "[TollAB / TollBA]", 
							"[TollAB / TollBA]", "[TollAB / TollBA]", "[TollAB / TollBA]", "[TollAB / TollBA]", "[TollAB / TollBA]", "[TollAB / TollBA]"}
		Opts.Global.[Class PCEs] = {1, 1, 1, 1, 1.5, 2.5, 1, 1, 1, 1}
		Opts.Global.[Class VOIs] = {1, 1, 1, 1, 1, 1, 1, 1, 1, 1}

// *********************************************************
//	Change from gc_mrm.vdf to bpr.vdf, Sept 2016

		if hwyassntype = "BPR" 
			then do
				Opts.Global.[Cost Function File] = "bpr.vdf"
				Opts.Global.[VDF Defaults] = {, , 0.15, 4, }
				Opts.Field.[VDF Fld Names] = {"[TTfreeAB / TTfreeBA]", cap_fields, "alpha", "beta", "None"}
			end
			else do
				Opts.Global.[Cost Function File] = "gc_mrm.vdf"
				Opts.Global.[VDF Defaults] = {, , 0.15, 4, 0, distweight, timeweight, , 0}
				Opts.Field.[VDF Fld Names] = {"[TTfreeAB / TTfreeBA]", cap_fields, "alpha", "beta", "None", "[TollAB / TollBA]", "None", "Length", "None"}
			end

		AppendToLogFile(4, "Assignment type = " + hwyassntype)


		
// ************************************************

		// final assignment can have more iterations and tighter convergence
		if z < HOTAssnIterations
			then do
				Opts.Global.Convergence = hwyassnconverge
				Opts.Global.Iterations = hwyassnmaxiter
				AppendToLogFile(4, "Feedback HwyAssn maximum no. of iterations = " + i2s(hwyassnmaxiter))
				AppendToLogFile(4, "Feedback HwyAssn convergence = " + r2s(hwyassnconverge))
			end
			else do
				Opts.Global.Convergence = hwyassnconvergefinal
				Opts.Global.Iterations = hwyassnmaxiterfinal
				AppendToLogFile(4, "Final HwyAssn maximum no. of iterations = " + i2s(hwyassnmaxiterfinal))
				AppendToLogFile(4, "Final HwyAssn convergence = " + r2s(hwyassnconvergefinal))
			end

		Opts.Flag.[Do Critical] = 0
		Opts.Flag.[Do Share Report] = 1   
		Opts.Output.[Flow Table] = output_bin
		
		ret_value = RunMacro("TCB Run Procedure", 25, "MMA", Opts)

		if !ret_value then goto badassign
		AppendToLogFile(3, "HOT Assn " + HOTAssnVersion  + " - Highway assignment")


		//ShowMessage("Assigned")


		///////////////////////////////////////////////////////////////////////
		//***************************************************************
		//								*
		//   Add prev speed fields for current iteration       		*
		//								*
		//***************************************************************
		on notfound do

			strct = GetTableStructure(netview)
			for i = 1 to strct.length do
				strct[i] = strct[i] + {strct[i][1]}
			end
			new_struct = strct + {{"TTHOTPrev"+PERIOD+i2s(z)+"AB", "Real", 10, 2, "True",,,, null}}
			ModifyTable(netview, new_struct)
			goto next4
		end
		GetField(netview+".TTHOTPrev"+PERIOD+i2s(z)+"AB")

		next4:
		//on notfound default
		on notfound do
			strct = GetTableStructure(netview)
			for i = 1 to strct.length do
				strct[i] = strct[i] + {strct[i][1]}
			end
			new_struct = strct + {{"TTHOTPrev"+PERIOD+i2s(z)+"BA", "Real", 10, 2, "True",,,, null}}
			ModifyTable(netview, new_struct)
			goto next5
		end
		GetField(netview+".TTHOTPrev"+PERIOD+i2s(z)+"BA")
	
		next5:



		//*************************************************************************************
		//Roll TTHOT* to TTHOTPrev* (AB & BA)
		//*************************************************************************************

		Opts = null
		Opts.Input.[Dataview Set] = {Dir + "\\"+netview+".dbd|"+netview, netview}
		Opts.Global.Fields = {"TTHOTPrev"+PERIOD+i2s(z)+"AB","TTHOTPrev"+PERIOD+i2s(z)+"BA"}
		Opts.Global.Method = "Formula"
		Opts.Global.Parameter = {"TTHOTAB", "TTHOTBA"}
		ret_value = RunMacro("TCB Run Operation", 26, "Fill Dataview", Opts)
		if !ret_value then goto badroll
		AppendToLogFile(3, "HOT Assn " + HOTAssnVersion  + " - roll back Travel Time")


		//*************************************************************************************
		//New assignment speed is weighted average (50%-50%) of Previous TT and last assigned  
		//Minimum assignment speed is currently 10% of free speed (maxTTfac) - all handled in travel time
		//*************************************************************************************

		Opts = null
		Opts.Input.[Dataview Set] = {{Dir + "\\"+netview+".dbd|"+netview, output_bin, "ID", "ID1"}, netview+"+Assn_"+PERIOD+"hot"}
		Opts.Global.Fields = {"TTHOTAB","TTHOTBA"}
		Opts.Global.Method = "Formula"
		Opts.Global.Parameter = {"TTHOTPrev"+PERIOD+i2s(z)+"AB * 0.67 + min(nz(AB_time), (nz(TTfreeAB) * "+i2s(maxTTfac)+")) * 0.33", 
				"TTHOTPrev"+PERIOD+i2s(z)+"BA * 0.67 + min(nz(BA_time), (nz(TTfreeBA) * "+i2s(maxTTfac)+")) * 0.33"}

		ret_value = RunMacro("TCB Run Operation", 27, "Fill Dataview", Opts)
		if !ret_value then goto badtt


		Opts = null
		Opts.Input.[Dataview Set] = {Dir + "\\"+netview+".dbd|"+netview, netview}
		Opts.Global.Fields = {"ImpHOTAB","ImpHOTBA"}
		Opts.Global.Method = "Formula"
		Opts.Global.Parameter = {"nz(TTHOTAB)* " + r2s(timeweight) +" + nz(length)* " + r2s(distweight), 
								 "nz(TTHOTBA)* " + r2s(timeweight) +" + nz(length)* " + r2s(distweight)}
		ret_value = RunMacro("TCB Run Operation", 28, "Fill Dataview", Opts)
		if !ret_value then goto badimp




		//skiparound:
		m = OpenMatrix(od_hot_matrix, )
		mc = CreateMatrixCurrency(m, "SOV", "Rows", "Columns",)
		new_mat = CopyMatrix(mc, {{"File Name", ODDir + "\\ODHwyVeh_"+PERIOD+"hot"+r2s(z)+".mtx"},
		    {"Label", "ODHwyVeh_"+PERIOD+"hot"+r2s(z)},
		    {"File Based", "Yes"}})

		//ShowMessage("Feedback of HOT Assn")

		//ShowMessage(netview)

		m = null
		mc = null
		HOT = null
		HOT_Cores = null


		batchname  = Dir+ "\\copy_file.bat"
		exist = GetFileInfo(batchname)
		if (exist <> null) then DeleteFile(batchname)
		batchhandle = OpenFile(batchname, "w")
		WriteLine(batchhandle, "copy " + output_bin + " " + assnDir + "\\Assn_"+PERIOD+r2s(z)+".bin")
		WriteLine(batchhandle, "copy " + output_dcb + " " + assnDir + "\\Assn_"+PERIOD+r2s(z)+".dcb")
		//WriteLine(batchhandle, "copy " + Dir + "\\skims\\SPMAT_GP_"+PERIOD+".mtx "+ Dir + "\\skims\\SPMAT_GP_"+PERIOD+r2s(z)+".mtx")
		//WriteLine(batchhandle, "copy " + Dir + "\\skims\\SPMAT_HOT_"+PERIOD+".mtx "+ Dir + "\\skims\\SPMAT_HOT_"+PERIOD+r2s(z)+".mtx")
		//WriteLine(batchhandle, "copy " + Dir + "\\skims\\HOT_"+PERIOD+".dbf " + Dir + "\\skims\\HOT_"+PERIOD+r2s(z)+".dbf")


		//Run the batch file
		CloseFile(batchhandle)

		//showmessage(batchname)

		status = RunProgram(batchname, )
		if (status <> 0) then ShowMessage("Error copying bin / dcb files")
						 else DeleteFile(batchname)


		AppendToLogFile(3, "HOT Assn " + HOTAssnVersion  + " - Copy bin and dcbs")


		//ShowMessage(netview)
		//ShowMessage ("closed map")

	end  // for z
	//nodirquit:
	goto quit

	badtimeperiod:
	Throw("Highway HOT Assignment Time period error")
	AppendToLogFile(1, "Highway HOT Assignment: Error: - Time period error")
	ShowItem(" Error/Warning messages ")
	ShowItem("netmessageslist")
	goto quit

	badnetbuild:
	Throw("HOT HwyAssn - ERROR building highway network, check for HOTAB & HOTBA network fields")
	AppendToLogFile(2, "HOT HwyAssn - ERROR building highway network, check for HOTAB & HOTBA network fields")
	HOTHwyAssnOK = 0
	goto badquit
	
	badnetsettings:
	Throw("HOT HwyAssn - ERROR in highway network settings")
	AppendToLogFile(2, "HOT HwyAssn - ERROR in highway network settings")
	HOTHwyAssnOK = 0
	goto badquit

	badassign:
	Throw("HOT HwyAssn - ERROR in highway assignment")
	AppendToLogFile(2, "HOT HwyAssn - ERROR in highway assignment")
	HOTHwyAssnOK = 0
	goto badquit

	badskim:
	Throw("HOT HwyAssn - ERROR in peak highway skim")
	AppendToLogFile(2, "HOT HwyAssn - ERROR in peak highway skim")
	HOTHwyAssnOK = 0
	goto badquit

	badroll:
	Throw("HOT HwyAssn - ERROR, did not roll TTpeak Assign to TTPeak Prev")
	AppendToLogFile(2, "HOT HwyAssn - ERROR, did not roll TTpeak Assign to TTPeak Prev")
	HOTHwyAssnOK = 0
	goto badquit

	badtt:
	Throw("HOT HwyAssn - ERROR, could not calculate new TTAssign")
	AppendToLogFile(2, "HOT HwyAssn - ERROR, could not calculate new TTAssign")
	HOTHwyAssnOK = 0
	goto badquit

	badimp:
	Throw("HOT HwyAssn - ERROR, could not calculate new Imped")
	AppendToLogFile(2, "HOT HwyAssn - ERROR, could not calculate new Imped")
	HOTHwyAssnOK = 0
	goto badquit

	badfill:
	Throw("HOT HwyAssn - ERROR, Did not fill HOT core with 0s")
	AppendToLogFile(2, "HOT HwyAssn - ERROR, Did not fill HOT core with 0s")
	HOTHwyAssnOK = 0
	goto badquit

	badHOTtable:
	Throw("HOT HwyAssn - ERROR, HOT_Table.bin doesn't exist")
	AppendToLogFile(2, "HOT HwyAssn - ERROR, HOT_Table.bin doesn't exist")
	HOTHwyAssnOK = 0
	goto badquit

	badfill1:
	Throw("HOT HwyAssn - ERROR, Did not fill TTSav")
	AppendToLogFile(2, "HOT HwyAssn - ERROR, Did not fill TTSav")
	HOTHwyAssnOK = 0
	goto badquit

	badquit:
	Throw("badquit: Last error message= " + GetLastError())
	AppendToLogFile(2, "badquit: Last error message= " + GetLastError())
	RunMacro("TCB Closing", ret_value, "TRUE" )
	RunMacro("TCB Closing", ret_value, "TRUE" )
	goto quit

	TCError:
	errmsg = GetLastError()
	Throw("HOT HwyAssn - TC ERROR : "+ errmsg)
	AppendToLogFile(2, "HOT HwyAssn - TC ERROR : "+ errmsg)
	HOTHwyAssnOK = 0
	goto quit

	UserKill:
	Throw("HOT HwyAssn - User killed job" )
	AppendToLogFile(2, "HOT HwyAssn - User killed job")
	HOTHwyAssnOK = 0
	goto quit

	quit:
	on error default
	on escape default
	Closemap()
	RunMacro("G30 File Close All")
	datentime = GetDateandTime()
	AppendToLogFile(1, "Exit HwyAssn_HOT: " + datentime)
	SetNumThreads(initial_threads)

	return(HOTHwyAssnOK)

EndMacro

