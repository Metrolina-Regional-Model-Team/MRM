//*********************************************************************************************************************
//  HwyAssn_SelectLink - with HOT assignment option
//
//  Original select link tool (regular / non-HOT MMA assignment) preserved as "HwyAssn_sel".
//  New macro "HwyAssn_selHOT" runs the iterative HOT (managed lane) assignment procedure
//  taken from HwyAssn_HOT, but ends with a select-link (critical link) MMA so the outputs
//  are IDENTICAL in name and structure to the old tool:
//        <output>\selectlink_AM_<linkID>.bin     (+ .dcb)   - flow table w/ Crit_link fields
//        <output>\selectlink_MID_<linkID>.bin
//        <output>\selectlink_PM_<linkID>.bin
//        <output>\selectlink_NI_<linkID>.bin
//        <run>\tod2\ODHwyVeh_<PERIOD>Select.mtx             - critical (select link) O-D matrix
//        <output>\Tot_Assn_<linkID>.dbf                     - via "Tot Assn" button
//
//  Prerequisites for the HOT path (same as the model's HOT assignment):
//     - network has HOTAB / HOTBA fields (HOT lane toll), alpha, beta, TTfree*, cap fields
//     - <parent of run dir>\trnpnlty.bin      (same location the old tool used)
//     - <parent of run dir>\HOT_Table.hot     (CPMS_VOT -> PERCENT lookup)
//     - OD matrix has cores in this order: SOV, POOL2, POOL3, COM, MTK, HTK
//     - the period's previous assignment, used to seed the HOT travel times:
//              <run>\HwyAssn\Assn_AMPeak.bin
//              <run>\HwyAssn\Assn_Midday.bin
//              <run>\HwyAssn\Assn_PMPeak.bin
//              <run>\HwyAssn\Assn_Night.bin
//       set in the Run Select Link button - see arguments[19]. If the file is missing,
//       free flow times are used and a message names every path that was tried.
//
//  All HOT parameters (iterations, max travel time factor, convergence, assn sub folder)
//  are fixed constants at the top of macro "HwyAssn_selHOT".
//
//  All HOT working files (GP/HOT skims, percent matrices, HOT dbfs, HOT_Table copy) are written to
//  <output>\SL_HOT_temp so nothing in the model run directory's \skims folder is overwritten.
//*********************************************************************************************************************
Macro "Open Select Link Dbox" (Args)
	RunDbox("HwyAssn_SelectLink_dbox", Args)
endmacro
DBox "HwyAssn_SelectLink_dbox" Title: "SelectLink: Have to enter link ID"
// Test to determine if only HOV are paying tolls (they shouldn't be)_July 11, 2007
toolbox
		init do
			shared arguments
			global slinkid
			dim arguments[20]
			arguments[1] = "Directory Location"
			arguments[5] = "Network File"
			arguments[15] = "Output Location"
			arguments[2] = 2.0
			arguments[3] = 0.1
			numthreads = GetNumThreads()		//default = whatever TransCAD is set to now
			arguments[20] = numthreads
		enditem
		Button 1,1,40 Prompt: arguments[1] Help: "Please choose a directory for run" do
				on escape goto direscaped
				arguments[1] = chooseDirectory("Please choose a directory for run:",)
				direscaped:
				on escape default
			enditem
		Button 1,3,40 Prompt: arguments[5] Help: "Please choose the network file" do
				on escape goto fileescaped
				arguments[5] = choosefile({{"TransCAD file","*.dbd"}},"Choose the Network File",{{"Initial Directory", arguments[1]}})
				tempfile = splitpath(arguments[5])
				arguments[4] = tempfile[3]
				fileescaped:
				on escape default
			enditem
		Button 1,5,40 Prompt: arguments[15] Help: "Please choose an output directory" do
				on escape goto direscaped
				arguments[15] = chooseDirectory("Please choose a directory for output:",{{"Initial Directory", arguments[1]}})
				direscaped:
				on escape default
			enditem
		Edit Int "NumThreads" 10, 7, 4 Prompt: "Threads:" Help: "Number of threads used for the assignment. Restored to the current TransCAD setting when the run finishes." variable: numthreads do
				if numthreads < 1 then numthreads = 1
				arguments[20] = numthreads
			enditem		
//
//***************************************************************
//								*
//   PERIOD = Time of day					*
//								*
//***************************************************************
		Checkbox "AM PEAK" 3, 9 Help: "Add the Area Type macro to the list of macros to be run at one time" variable: ampeak do
			enditem
		Checkbox "MIDDAY" 3, 11 Help: "Add the Area Type macro to the list of macros to be run at one time" variable: midday do
			enditem
		Checkbox "PM PEAK" 23, 9 Help: "Add the Area Type macro to the list of macros to be run at one time" variable: pmpeak do
			enditem
		Checkbox "NIGHT" 23, 11 Help: "Add the Area Type macro to the list of macros to be run at one time" variable: night do
			enditem
		Checkbox "HOT Assignment?" 23, 13 Help: "Check to run the iterative HOT (managed lane) assignment for the select link" variable: hotassn do
			enditem
		Button 4,13 Prompt: "Enter Link ID" do
			on escape goto fileescaped
				arguments[11] = rundbox("IDgetter")
				fileescaped:
				on escape default
			enditem
	Button 4,15 Prompt: "Run Select Link" do
			if slinkid = null then do
				ShowMessage("Enter a Link ID first.")
				goto endrun
				end
			if ampeak = 1 then do
				arguments[6] = "AMPeak"
				arguments[7] = arguments[1] + "\\tod2\\ODHwyVeh_AMPeak.mtx"
			        arguments[8] = "CapPk3hr"
			        arguments[9] = arguments[15] + "\\" + "selectlink_AM_" + slinkid + ".bin"
				arguments[10] = arguments[1] + "\\tod2\\ODHwyVeh_AMPeakSelect.mtx"
				arguments[16] = arguments[1] + "\\tod2\\ODHwyVeh_AMPeakhot.mtx"
				arguments[19] = arguments[1] + "\\HwyAssn\\Assn_AMPeak.bin"
				if hotassn = 1
					then runmacro("HwyAssn_selHOT", arguments)
					else runmacro("HwyAssn_sel", arguments)
				end
			if midday = 1 then do
				arguments[6] = "MIDDAY"
				arguments[7] = arguments[1] + "\\tod2\\ODHwyVeh_MIDDAY.mtx"
			        arguments[8] = "capMid"
			        arguments[9] = arguments[15] + "\\" + "selectlink_MID_" + slinkid + ".bin"
				arguments[10] = arguments[1] + "\\tod2\\ODHwyVeh_MIDDAYSelect.mtx"
				arguments[16] = arguments[1] + "\\tod2\\ODHwyVeh_MIDDAYhot.mtx"
				arguments[19] = arguments[1] + "\\HwyAssn\\Assn_Midday.bin"
				if hotassn = 1
					then runmacro("HwyAssn_selHOT", arguments)
					else runmacro("HwyAssn_sel", arguments)
				end
			if pmpeak = 1 then do
				arguments[6] = "PMPeak"
				arguments[7] = arguments[1] + "\\tod2\\ODHwyVeh_PMPeak.mtx"
			        arguments[8] = "CapPk3hr"
			        arguments[9] = arguments[15] + "\\" + "selectlink_PM_" + slinkid + ".bin"
				arguments[10] = arguments[1] + "\\tod2\\ODHwyVeh_PMPeakSelect.mtx"
				arguments[16] = arguments[1] + "\\tod2\\ODHwyVeh_PMPeakhot.mtx"
				arguments[19] = arguments[1] + "\\HwyAssn\\Assn_PMPeak.bin"
				if hotassn = 1
					then runmacro("HwyAssn_selHOT", arguments)
					else runmacro("HwyAssn_sel", arguments)
				end
			if night = 1 then do
				arguments[6] = "NIGHT"
				arguments[7] = arguments[1] + "\\tod2\\ODHwyVeh_NIGHT.mtx"
			        arguments[8] = "CapNight"
			        arguments[9] = arguments[15] + "\\" + "selectlink_NI_" + slinkid + ".bin"
				arguments[10] = arguments[1] + "\\tod2\\ODHwyVeh_NIGHTSelect.mtx"
				arguments[16] = arguments[1] + "\\tod2\\ODHwyVeh_NIGHThot.mtx"
				arguments[19] = arguments[1] + "\\HwyAssn\\Assn_Night.bin"
				if hotassn = 1
					then runmacro("HwyAssn_selHOT", arguments)
					else runmacro("HwyAssn_sel", arguments)
				end
			endrun:
			enditem
	Close do
        	Return()
        	endItem
	Button 4,17 Prompt: "Tot Assn" do
			Dir = arguments[1]
			AssnSubDir = arguments[15]
			netview = arguments[4]
			minspfac = 10
			pkhrfac = 0.40
			runmacro("tot_assn_sellink", pkhrfac, minspfac, Dir, netview, AssnSubDir, "select_link")
		enditem
enddbox

//*********************************************************************************************************************
//   HwyAssn_sel  -  ORIGINAL (non-HOT) select link assignment - unchanged except Do Critical turned on
//*********************************************************************************************************************
Macro "HwyAssn_sel" (arguments)
        shared net_file
//*********************************************************************************************************************
//Hwy Assn
// This version runs straight bpr delay.
//   Added funcls 24 and 25: JWM, July 19, 2007
//   Update to TC 5.0 - change to bpr delay, Feb, 2008
//*********************************************************************************************************************
	Dir = arguments[1]
	timeweight = arguments[2]
	distweight = arguments[3]
        minspfac = 10
	od_matrix = arguments[7]
	cap_field = arguments[8]
	output_bin = arguments[9]
	netview = arguments[4]
	netname = netview
	run_threads = arguments[20]			//thread count set in the toolbox
	initial_threads = GetNumThreads()
	if run_threads <> null then do
		if run_threads > 0 then SetNumThreads(run_threads)
	end
	Location = splitpath(Dir)
	arguments[11] = slinkid
//	showmessage("arguments11 = " + arguments[11])
	arguments[12] = "LinkAB(" + arguments[11] + ")"
	arguments[13] = "LinkBA(" + arguments[11] + ")"
	arguments[14] = arguments[12] + " or " + arguments[13]
//capacity fields
	cap_fields = "[" + cap_field + "AB / " + cap_field + "BA]"
//      check highway network if hov lanes exist
//      hov2+ are funcl 22, 24, and 82
//      hov3+ are funcl 23, 25, and 83
	net_file = Dir + "\\"+netview+".DBD"
	info = GetDBInfo(net_file)
	scope = info[1]
	CreateMap(netname, {{"Scope", scope},{"Auto Project", "True"}})
	layers = GetDBLayers(net_file)
	node_lyr = addlayer(netname, layers[1], net_file, layers[1])
	link_lyr = addlayer(netname, layers[2], net_file, layers[2])
	SetLayerVisibility(node_lyr, "False")
	SetIcon(node_lyr + "|", "Font Character", "Caliper Cartographic|4", 36)
	SetLayerVisibility(link_lyr, "True")
	solid = LineStyle({{{1, -1, 0}}})
	SetLineStyle(link_lyr+"|", solid)
	SetLineColor(link_lyr+"|", ColorRGB(0, 0, 32000))
	SetLineWidth(link_lyr+"|", 0)
	setview(netview)
	selpool2 = "Select * where funcl = 22 or funcl = 23 or funcl = 24 or funcl = 25 or funcl = 82 or funcl = 83"
	selpool3 = "Select * where funcl = 23 or funcl = 25 or funcl = 83"
	Selectbyquery("check_pool2", "Several", selpool2,)
	Selectbyquery("check_pool3", "Several", selpool3,)
	pool2count = getsetcount("check_pool2")
	pool3count = getsetcount("check_pool3")
//        showmessage("pool2 " + string(pool2count)+"    pool3 "+string(pool3count))
	closemap()
	if pool2count = 0 and pool3count = 0 then do
		goto assnnoHOV
		end
	else if pool2count > 0 and pool3count = 0 then do
		goto assnHOV2only
		end
	else do
		goto assnHOV2andHOV3
		end
assnnoHOV:
//showmessage("got here a")
//Network has no HOV facilities - don't worry about exclusion sets
    RunMacro("TCB Init")
// Build Highway Network
     	Opts = null
     	Opts.Input.[Link Set] = {Dir + "\\"+netview+".DBD|"+netview, netview, "hwynet", "Select * where (funcl > 0 and funcl < 10) or funcl =90"}
	Opts.Global.[Network Options].[Link Type] = {"funcl", netview+".funcl", netview+".funcl"}
	Opts.Global.[Network Options].[Time Unit] = "Minutes"
     	Opts.Global.[Network Options].[Node ID] = "Node.ID"
     	Opts.Global.[Network Options].[Link ID] = netview+".ID"
     	Opts.Global.[Network Options].[Turn Penalties] = "No"
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
	ret_value = RunMacro("TCB Run Operation", "Build Highway Network", Opts, &Ret)
     	if !ret_value then goto badnetbuild
// Highway Network Setting
     	Opts = null
     	Opts.Input.Database = Dir + "\\"+netview+".DBD"
     	Opts.Input.Network = Dir + "\\net_highway.net"
     	Opts.Input.[Centroids Set] = {Dir + "\\"+netview+".DBD|Node", "Node", "centroid", "Select * where centroid = 1 or centroid = 2"}
	Opts.Input.[Spc Turn Pen Table]= {Location[1] + Location[2] + "trnpnlty.bin"}
      	Opts.Input.[Toll Set]= {Dir + "\\"+netview+".DBD|"+netview, netview, "tollset", "Select * where TollAB > 0 or TollBA > 0"}
     	Opts.Global.[Global Turn Penalties] = {0, 0, 0, -1}
	ret_value = RunMacro("TCB Run Operation", "Highway Network Setting", Opts, &Ret)
     	if !ret_value then goto notolls1
	goto skipnotolls1
	notolls1:
	Opts = null
     	Opts.Input.Database = Dir + "\\"+netview+".DBD"
     	Opts.Input.Network = Dir + "\\net_highway.net"
     	Opts.Input.[Centroids Set] = {Dir + "\\"+netview+".DBD|Node", "Node", "centroid", "Select * where centroid = 1 or centroid = 2"}
	Opts.Input.[Spc Turn Pen Table]= {Location[1] + Location[2] + "trnpnlty.bin"}
	Opts.Global.[Global Turn Penalties] = {0, 0, 0, -1}
	ret_value = RunMacro("TCB Run Operation", "Highway Network Setting", Opts, &Ret)
     	if !ret_value then goto badnetsettings

	skipnotolls1:
//MMA Assignment - No HOV
     	Opts = null
     	Opts.Input.Database = Dir + "\\"+netview+".DBD"
     	Opts.Input.Network = Dir + "\\net_highway.net"
     	Opts.Input.[OD Matrix Currency] = {od_matrix, "SOV", "Rows", "Columns"}
     	Opts.Input.[Exclusion Link Sets] = {, , , , ,}
     	Opts.Field.[Vehicle Classes] = {1, 2, 3, 4, 5, 6}
	Opts.Field.[Fixed Toll Fields] = {"[TollAB / TollBA]", "[TollAB / TollBA]", "[TollAB / TollBA]", "[TollAB / TollBA]", "[TollAB / TollBA]", "[TollAB / TollBA]"}
	Opts.Field.[PCE Fields] = {"None", "None", "None", "None", "None", "None"}
			Opts.Global.[Cost Function File] = "bpr.vdf"
			Opts.Global.[VDF Defaults] = {, , 0.15, 4, }
			Opts.Field.[VDF Fld Names] = {"[TTfreeAB / TTfreeBA]", cap_fields, "alpha", "beta", "None"}
     	Opts.Global.[Number of Classes] = 6
	Opts.Global.[Load Method] = "CUE"
	Opts.Global.[Loading Multiplier] = 1
	Opts.Global.Convergence = 0.0001
	Opts.Global.[Time Minimum] = 0.01
    	Opts.Global.[Class PCEs] = {1, 1, 1, 1, 1.5, 2.5}
     	Opts.Global.[Class VOIs] = {1, 1, 1, 1, 1, 1}
     	Opts.Global.Iterations = 250
	Opts.Global.[Critical Queries] = {arguments[14]}
    	Opts.Global.[Critical Set Names] = {"Crit_link"}
     	Opts.Flag.[Do Critical] = 1
     	Opts.Flag.[Do Share Report] = 1
     	Opts.Output.[Flow Table] = output_bin
 	Opts.Output.[Critical Matrix].Label = "Critical Matrix"
    	Opts.Output.[Critical Matrix].[File Name] = arguments[10]
	ret_value = RunMacro("TCB Run Procedure", "MMA", Opts, &Ret)
     	if !ret_value then goto badassign
goto quit
assnHOV2only:
//showmessage("got here b")
    RunMacro("TCB Init")
//Network has HOV2+ facilities - and no HOV3+ facilities
//exclude link sets for 6 vol classes
// 1 = sov - exclude from hov2+ and hov3+  (funcl 22,24,82 & 23,25,83=sovexclude)
// 2 = pool2 - no exclusion
// 3 = pool3 - no exclusion
// 4 = COM - exclude from all hov (sovexclude)
// 5 = MTK - exclude from all hov (sovexclude)
// 6 = HTK - exclude from all hov (sovexclude)
// Build Highway Network
    RunMacro("TCB Init")
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
	ret_value = RunMacro("TCB Run Operation", "Build Highway Network", Opts, &Ret)
     	if !ret_value then goto badnetbuild
// Highway Network Setting
     	Opts = null
     	Opts.Input.Database = Dir + "\\"+netview+".DBD"
     	Opts.Input.Network = Dir + "\\net_highway.net"
     	Opts.Input.[Centroids Set] = {Dir + "\\"+netview+".DBD|Node", "Node", "centroid", "Select * where centroid = 1 or centroid = 2"}
	Opts.Input.[Spc Turn Pen Table]= {Location[1] + Location[2] + "trnpnlty.bin"}
      	Opts.Input.[Toll Set]= {Dir + "\\"+netview+".DBD|"+netview, netview, "tollset", "Select * where TollAB > 0 or TollBA > 0"}
    	Opts.Global.[Global Turn Penalties] = {0, 0, 0, -1}
	ret_value = RunMacro("TCB Run Operation", "Highway Network Setting", Opts, &Ret)
     	if !ret_value then goto notolls2
	goto skipnotolls2
	notolls2:
	Opts = null
     	Opts.Input.Database = Dir + "\\"+netview+".DBD"
     	Opts.Input.Network = Dir + "\\net_highway.net"
     	Opts.Input.[Centroids Set] = {Dir + "\\"+netview+".DBD|Node", "Node", "centroid", "Select * where centroid = 1 or centroid = 2"}
	Opts.Input.[Spc Turn Pen Table]= {Location[1] + Location[2] + "trnpnlty.bin"}
	Opts.Global.[Global Turn Penalties] = {0, 0, 0, -1}
	ret_value = RunMacro("TCB Run Operation", "Highway Network Setting", Opts, &Ret)
     	if !ret_value then goto badnetsettings
	skipnotolls2:
// MMA Assignment
     	Opts = null
     	Opts.Input.Database = Dir + "\\"+netview+".DBD"
     	Opts.Input.Network = Dir + "\\net_highway.net"
     	Opts.Input.[OD Matrix Currency] = {od_matrix, "SOV", "Rows", "Columns"}
     	Opts.Input.[Exclusion Link Sets] =
{{Dir + "\\"+netview+".DBD|"+netview, netview, "sovexclude", "Select * where funcl = 22 or funcl = 23 or funcl = 25 or funcl = 82 or funcl = 83"}, , , {Dir + "\\"+netview+".DBD|"+netview, netview, "sovexclude"}, {Dir + "\\"+netview+".DBD|"+netview, netview, "trkexclude", "Select * where funcl = 22 or funcl = 23 or funcl = 24 or funcl = 25 or funcl = 82 or funcl = 83"}, {Dir + "\\"+netview+".DBD|"+netview, netview, "trkexclude"}}
     	Opts.Field.[Vehicle Classes] = {1, 2, 3, 4, 5, 6}
	Opts.Field.[Fixed Toll Fields] = {"[TollAB / TollBA]", "[TollAB / TollBA]", "[TollAB / TollBA]", "[TollAB / TollBA]", "[TollAB / TollBA]", "[TollAB / TollBA]"}
	Opts.Field.[PCE Fields] = {"None", "None", "None", "None", "None", "None"}
			Opts.Global.[Cost Function File] = "bpr.vdf"
			Opts.Global.[VDF Defaults] = {, , 0.15, 4, }
			Opts.Field.[VDF Fld Names] = {"[TTfreeAB / TTfreeBA]", cap_fields, "alpha", "beta", "None"}
     	Opts.Global.[Number of Classes] = 6
	Opts.Global.[Load Method] = "CUE"
	Opts.Global.[Loading Multiplier] = 1
	Opts.Global.Convergence = 0.0001
	Opts.Global.[Time Minimum] = 0.01
     	Opts.Global.[Class PCEs] = {1, 1, 1, 1, 1.5, 2.5}
     	Opts.Global.[Class VOIs] = {1, 1, 1, 1, 1, 1}
    	Opts.Global.Iterations = 250
	Opts.Global.[Critical Queries] = {arguments[14]}
    	Opts.Global.[Critical Set Names] = {"Crit_link"}
        Opts.Flag.[Do Critical] = 1
     	Opts.Flag.[Do Share Report] = 1
     	Opts.Output.[Flow Table] = output_bin
 	Opts.Output.[Critical Matrix].Label = "Critical Matrix"
    	Opts.Output.[Critical Matrix].[File Name] = arguments[10]

	ret_value = RunMacro("TCB Run Procedure", "MMA", Opts, &Ret)
     	if !ret_value then goto badassign
goto quit
assnHOV2andHOV3:
//showmessage("got here c")
    RunMacro("TCB Init")
//Network has both HOV2 and HOV3 lanes
//exclude link sets for 6 vol classes
// 1 = sov - exclude from hov2+ and hov3+  (funcl 22,24,82 & 23,25,83=sovexclude)
// 2 = pool2 - exclude from hov3+ (funcl 23,25,83=pool2exclude)
// 3 = pool3 - no exclusion
// 4 = COM - exclude from all hov (sovexclude)
// 5 = MTK - exclude from all hov (sovexclude)
// 6 = HTK - exclude from all hov (sovexclude)
// Build Highway Network
     	Opts = null
     	Opts.Input.[Link Set] = {Dir + "\\"+netview+".DBD|"+netview, netview, "hwynet", "Select * where (funcl > 0 and funcl < 10) or funcl = 22 or funcl = 23 or funcl = 24 or funcl = 25 or funcl = 82 or funcl = 83 or funcl = 90"}
       Opts.Global.[Network Options].[Link Type] = {"funcl", netview+".funcl", netview+".funcl"}
     	Opts.Global.[Network Options].[Node ID] = "Node.ID"
     	Opts.Global.[Network Options].[Link ID] = netview+".ID"
     	Opts.Global.[Network Options].[Turn Penalties] = "Yes"
     	Opts.Global.[Network Options].[Keep Duplicate Links] = "FALSE"
     	Opts.Global.[Network Options].[Ignore Link Direction] = "FALSE"
	Opts.Global.[Network Options].[Time Unit] = "Minutes"
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
	ret_value = RunMacro("TCB Run Operation", "Build Highway Network", Opts, &Ret)
    	if !ret_value then goto badnetbuild
// Highway Network Setting
     	Opts = null
     	Opts.Input.Database = Dir + "\\"+netview+".DBD"
     	Opts.Input.Network = Dir + "\\net_highway.net"
     	Opts.Input.[Centroids Set] = {Dir + "\\"+netview+".DBD|Node", "Node", "centroid", "Select * where centroid = 1 or centroid = 2"}
	Opts.Input.[Spc Turn Pen Table]= {Location[1] + Location[2] + "trnpnlty.bin"}
      	Opts.Input.[Toll Set]= {Dir + "\\"+netview+".DBD|"+netview, netview, "tollset", "Select * where TollAB > 0 or TollBA > 0"}
     	Opts.Global.[Global Turn Penalties] = {0, 0, 0, -1}
	ret_value = RunMacro("TCB Run Operation", "Highway Network Setting", Opts, &Ret)
     	if !ret_value then goto notolls3
	goto skipnotolls3
	notolls3:
	Opts = null
     	Opts.Input.Database = Dir + "\\"+netview+".DBD"
     	Opts.Input.Network = Dir + "\\net_highway.net"
     	Opts.Input.[Centroids Set] = {Dir + "\\"+netview+".DBD|Node", "Node", "centroid", "Select * where centroid = 1 or centroid = 2"}
	Opts.Input.[Spc Turn Pen Table]= {Location[1] + Location[2] + "trnpnlty.bin"}
	Opts.Global.[Global Turn Penalties] = {0, 0, 0, -1}
	ret_value = RunMacro("TCB Run Operation", "Highway Network Setting", Opts, &Ret)
     	if !ret_value then goto badnetsettings

	skipnotolls3:
// MMA Assignment
     	Opts = null
     	Opts.Input.Database = Dir + "\\"+netview+".DBD"
     	Opts.Input.Network = Dir + "\\net_highway.net"
     	Opts.Input.[OD Matrix Currency] = {od_matrix, "SOV", "Rows", "Columns"}
     	Opts.Input.[Exclusion Link Sets] =
{{Dir + "\\"+netview+".DBD|"+netview, netview, "sovexclude", "Select * where funcl = 22 or funcl = 23 or funcl = 25 or funcl = 82 or funcl = 83"}, {Dir + "\\"+netview+".DBD|"+netview, netview, "pool2exclude", "Select * where funcl = 23 or funcl = 25 or funcl = 83"}, , {Dir + "\\"+netview+".DBD|"+netview, netview, "sovexclude"}, {Dir + "\\"+netview+".DBD|"+netview, netview, "trkexclude", "Select * where funcl = 22 or funcl = 23 or funcl = 24 or funcl = 25 or funcl = 82 or funcl = 83"}, {Dir + "\\"+netview+".DBD|"+netview, netview, "trkexclude"}}
     	Opts.Field.[Vehicle Classes] = {1, 2, 3, 4, 5, 6}
	Opts.Field.[Fixed Toll Fields] = {"[TollAB / TollBA]", "[TollAB / TollBA]", "[TollAB / TollBA]", "[TollAB / TollBA]", "[TollAB / TollBA]", "[TollAB / TollBA]"}
	Opts.Field.[PCE Fields] = {"None", "None", "None", "None", "None", "None"}
			Opts.Global.[Cost Function File] = "bpr.vdf"
			Opts.Global.[VDF Defaults] = {, , 0.15, 4, }
			Opts.Field.[VDF Fld Names] = {"[TTfreeAB / TTfreeBA]", cap_fields, "alpha", "beta", "None"}
     	Opts.Global.[Number of Classes] = 6
	Opts.Global.[Load Method] = "CUE"
	Opts.Global.[Loading Multiplier] = 1
	Opts.Global.Convergence = 0.0001
	Opts.Global.[Time Minimum] = 0.01
     	Opts.Global.[Class PCEs] = {1, 1, 1, 1, 1.5, 2.5}
     	Opts.Global.[Class VOIs] = {1, 1, 1, 1, 1, 1}
     	Opts.Global.Iterations = 250
	Opts.Global.[Critical Queries] = {arguments[14]}
    	Opts.Global.[Critical Set Names] = {"Crit_link"}
     	Opts.Flag.[Do Critical] = 1
     	Opts.Flag.[Do Share Report] = 1
     	Opts.Output.[Flow Table] = output_bin
	Opts.Output.[Critical Matrix].Label = "Critical Matrix"
    	Opts.Output.[Critical Matrix].[File Name] = arguments[10]
	ret_value = RunMacro("TCB Run Procedure", "MMA", Opts, &Ret)
     	if !ret_value then goto badassign
goto quit
badnetbuild:
	btn = MessageBox("Highway Assignment - cannot build highway network, kill job?",
         {{"Caption", "ERROR"},
         {"Buttons", "YesNo"}})
	if btn = "Yes" then killjob = 1
        goto badquit
badnetsettings:
	btn = MessageBox("Highway Assignment - highway network settings error, kill job?",
         {{"Caption", "ERROR"},
         {"Buttons", "YesNo"}})
	if btn = "Yes" then killjob = 1
        goto badquit
badassign:
	btn = MessageBox("Highway Assignment - highway assignment error, kill job?",
         {{"Caption", "ERROR"},
         {"Buttons", "YesNo"}})
	if btn = "Yes" then killjob = 1
        goto badquit
badquit:
	RunMacro("TCB Closing", ret_value, "TRUE" )
quit:
	if initial_threads <> null then SetNumThreads(initial_threads)
endMacro

//*********************************************************************************************************************
//   HwyAssn_selHOT  -  SELECT LINK using the HOT (managed lane) assignment procedure
//
//   Logic taken from macro "HwyAssn_HOT":
//      - roll a starting travel time into TTHOT AB/BA and compute ImpHOT AB/BA
//      - loop HOTAssnIterations times:
//           * copy the base OD matrix to the HOT OD matrix
//           * build/skim a General Purpose network (no managed lanes)
//           * build/skim a network WITH the managed lanes (skims HOT toll too)
//           * TTSav = GP time - HOT time ; CPMS = HOTtoll/TTSav ; CPMS_VOT = CPMS/0.165
//           * look CPMS_VOT up in HOT_Table.hot to get PERCENT willing to pay
//           * move PERCENT of SOV/POOL2/POOL3/COM into HOTSOV/HOTPOOL2/HOTPOOL3/HOTCOM cores
//           * 10 class MMA assignment (BPR)
//           * feed assigned times back into TTHOT (0.67 previous / 0.33 new) and ImpHOT
//      - the LAST iteration is run with Do Critical = 1 and the select link query, so
//        the flow table and the critical O-D matrix are written exactly where the old tool put them.
//*********************************************************************************************************************
Macro "HwyAssn_selHOT" (arguments)
	shared net_file
	global slinkid
	on escape goto UserKill

	Dir 		= arguments[1]
	netview 	= arguments[4]
	PERIOD 		= arguments[6]
	run_threads	= arguments[20]			//thread count set in the toolbox
	od_matrix 	= arguments[7]			// base (non HOT) OD matrix
	cap_field 	= arguments[8]
	output_bin 	= arguments[9]			// selectlink_XX_<id>.bin
	crit_matrix	= arguments[10]			// ODHwyVeh_<PERIOD>Select.mtx
	AssnSubDir	= arguments[15]
	od_hot_matrix	= arguments[16]			// ODHwyVeh_<PERIOD>hot.mtx
	seed_name	= arguments[19]			// Assn_<PERIOD>.bin - full path or bare file name

//*********************************************************************************************************************
//   FIXED HOT PARAMETERS - change them here if the model settings change
//*********************************************************************************************************************
//   *** These MUST match the model's HOT assignment settings or the volumes will not ***
//   *** reproduce. Values below are taken from the model Args (see comment on each). ***
//
//   NOTE: timeweight / distweight are the HOT IMPEDANCE weights (ImpHOT = TTHOT*tw + length*dw)
//   and are deliberately NOT taken from arguments[2] / arguments[3]. Those two are the old
//   non-HOT select link tool's values (2.0 / 0.1) and would send the GP and HOT skims down
//   different paths than the model, changing TTSav, CPMS and the HOT diversion percentages.
	timeweight = 1				// Args.TimeWeight
	distweight = 0				// Args.DistWeight
	HOTAssnIterations = 5			// Args.[HOTAssn Iterations]
	maxTTfac = 10				// Args.MaxTravTimeFactor
	hwyassnconverge = 0.01			// hard coded as .01 in HwyAssn_HOT - feedback iterations
	hwyassnmaxiter = 250			// Args.[HwyAssn Max Iter Feedback]
	hwyassnconvergefinal = 0.0001		// Args.[HwyAssn Converge]
	hwyassnmaxiterfinal = 500		// Args.[HwyAssn Max Iter Final]
	assnfolder = "\\HwyAssn"		// only used if arguments[19] is a bare file name
//*********************************************************************************************************************

	HOTHwyAssnOK = 1
	ret_value = 1

//   remember the user's thread setting, then switch to the count asked for in the toolbox
	initial_threads = GetNumThreads()
	if run_threads <> null then do
		if run_threads > 0 then SetNumThreads(run_threads)
	end

//  select link query - same construction as the original tool
	arguments[11] = slinkid
	arguments[12] = "LinkAB(" + arguments[11] + ")"
	arguments[13] = "LinkBA(" + arguments[11] + ")"
	arguments[14] = arguments[12] + " or " + arguments[13]
	critquery = arguments[14]

//  capacity fields
	cap_fields = "[" + cap_field + "AB / " + cap_field + "BA]"

//  trnpnlty.bin and HOT_Table.hot live one level above the run directory (same as the old tool)
	Location = SplitPath(Dir)
	METDir = Location[1] + Location[2]
	if Right(METDir, 1) = "\\" then METDir = Left(METDir, StringLength(METDir) - 1)

	net_file = Dir + "\\" + netview + ".DBD"

//  working directory for all HOT intermediate files - keeps the model's \skims folder untouched
	tmpdir = AssnSubDir + "\\SL_HOT_temp"
	dirinfo = GetDirectoryInfo(tmpdir, "Directory")
	if dirinfo = null then CreateDirectory(tmpdir)

	temp = SplitPath(output_bin)
	output_dcb = temp[1] + temp[2] + temp[3] + ".dcb"

	RunMacro("TCB Init")

//***************************************************************
//   Open the network										*
//***************************************************************
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

//***************************************************************
//   HOTAB / HOTBA must exist for the managed lane skim			*
//***************************************************************
	field_array = GetFields(netview, "All")
	fld_names = field_array[1]
	if ArrayPosition(fld_names, {"HOTAB"},) = 0 or ArrayPosition(fld_names, {"HOTBA"},) = 0
		then goto badhotfield

//***************************************************************
//   Add TTHOT and IMPHOT AB/BA fields if necessary				*
//***************************************************************
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
//   First pass - roll the last NON-HOT assignment travel time into TTHOT
//   (capped at TTfree * maxTTfac), exactly as HwyAssn_HOT does.
//
//   arguments[19] may be EITHER a full path  (Dir + "\\HwyAssn\\Assn_AMPeak.bin")
//                          OR a bare file name ("Assn_AMPeak.bin"), in which case it is
//   looked for in <run>+assnfolder, then the run directory, then the output directory.
//***********************************************************************************
	seed_bin = null
	useseed = 0
	seedparts = SplitPath(seed_name)
	if seedparts[1] <> "" or seedparts[2] <> ""
		then trylist = {seed_name}					//already a full path - use as given
		else trylist = {Dir + assnfolder + "\\" + seed_name,
				Dir + "\\" + seed_name,
				AssnSubDir + "\\" + seed_name}
	triedlist = ""
	for i = 1 to trylist.length do
		triedlist = triedlist + "\n     " + trylist[i]
		if useseed = 0 then do
			seedinfo = GetFileInfo(trylist[i])
			if seedinfo <> null then do
				seed_bin = trylist[i]
				useseed = 1
			end
		end
	end
	if useseed = 0 then do
		ShowMessage("HOT Select Link - seed assignment bin not found. Looked for:" + triedlist +
			"\n\nHOT travel times will be seeded from free flow times instead.")
	end

	if useseed = 1
		then do
			temp = SplitPath(seed_bin)
			seed_view = temp[3]
			Opts = null
			Opts.Input.[Dataview Set] = {{Dir + "\\"+netview+".dbd|"+netview, seed_bin, "ID", "ID1"}, netview+seed_view}
			Opts.Global.Fields = {"TTHOTAB","TTHOTBA"}
			Opts.Global.Method = "Formula"
			Opts.Global.Parameter = {"min(nz(AB_time), nz(TTfreeAB * "+i2s(maxTTfac)+"))", "min(nz(BA_time), nz(TTfreeBA * "+i2s(maxTTfac)+"))"}
			ret_value = RunMacro("TCB Run Operation", 1, "Fill Dataview", Opts)
			if !ret_value then goto badtt
		end
		else do
			Opts = null
			Opts.Input.[Dataview Set] = {Dir + "\\"+netview+".dbd|"+netview, netview}
			Opts.Global.Fields = {"TTHOTAB","TTHOTBA"}
			Opts.Global.Method = "Formula"
			Opts.Global.Parameter = {"nz(TTfreeAB)", "nz(TTfreeBA)"}
			ret_value = RunMacro("TCB Run Operation", 1, "Fill Dataview", Opts)
			if !ret_value then goto badtt
		end

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

		//copy the ORIGINAL (non HOT) OD matrix at the start of every iteration
		m = OpenMatrix(od_matrix, )
		mc = CreateMatrixCurrency(m, "SOV", "Rows", "Columns",)
		new_mat = CopyMatrix(mc, {{"File Name", od_hot_matrix},
		    {"Label", "ODHwyVeh_"+PERIOD+"hot"},
		    {"File Based", "Yes"}})
		m = null
		mc = null
		new_mat = null

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
//   Create highway network excluding hot lanes					*
//***************************************************************
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

//***************************************************************
//   Skim highway network minimizing ImpHOTAB/BA				*
//***************************************************************
		Opts = null
		Opts.Input.Database = Dir + "\\"+netview+".DBD"
		Opts.Input.Network = Dir + "\\net_gp.net"
		Opts.Input.[Centroids Set] = {Dir + "\\"+netview+".DBD|Node", "Node", "centroid", "Select * where centroid = 1 or centroid = 2"}
		Opts.Input.[Spc Turn Pen Table]= {METDir + "\\trnpnlty.bin"}
		Opts.Global.[Global Turn Penalties] = {0, 0, 0, -1}
		ret_value = RunMacro("TCB Run Operation", 4, "Highway Network Setting", Opts)
		if !ret_value then goto badnetsettings

		Opts = null
		Opts.Input.Network = Dir + "\\net_gp.net"
		Opts.Input.[Origin Set] = {Dir + "\\"+netview+".DBD|Node", "Node", "centroid", "Select * where Centroid = 1 or centroid = 2"}
		Opts.Input.[Destination Set] = {Dir + "\\"+netview+".DBD|Node", "Node", "centroid"}
		Opts.Input.[Via Set] = {Dir + "\\"+netview+".DBD|Node", "Node"}
		Opts.Field.Minimize = "[ImpHOTAB / ImpHOTBA]"
		Opts.Field.Nodes = "Node.ID"
		Opts.Field.[Skim Fields] = {{"[TTHOTAB / TTHOTBA] ", "All"}}
		Opts.Output.[Output Matrix].Label = "SPMAT_GP_"+PERIOD+i2s(z)
		Opts.Output.[Output Matrix].[File Name] = tmpdir + "\\SPMAT_GP_"+PERIOD+i2s(z)+".mtx"
		ret_value = RunMacro("TCB Run Procedure", 5, "TCSPMAT", Opts)
		if !ret_value then goto badskim

//***************************************************************
//   Create highway network with hot lanes						*
//***************************************************************
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

//***************************************************************
//   Skim highway network with the managed lanes				*
//***************************************************************
		Opts = null
		Opts.Input.Database = Dir + "\\"+netview+".DBD"
		Opts.Input.Network = Dir + "\\net_hot.net"
		Opts.Input.[Centroids Set] = {Dir + "\\"+netview+".DBD|Node", "Node", "centroid", "Select * where centroid = 1 or centroid = 2"}
		Opts.Input.[Spc Turn Pen Table]= {METDir + "\\trnpnlty.bin"}
		Opts.Global.[Global Turn Penalties] = {0, 0, 0, -1}
		ret_value = RunMacro("TCB Run Operation", 7, "Highway Network Setting", Opts)
		if !ret_value then goto badnetsettings

		Opts = null
		Opts.Input.Network = Dir + "\\net_hot.net"
		Opts.Input.[Origin Set] = {Dir + "\\"+netview+".DBD|Node", "Node", "centroid", "Select * where Centroid = 1 or centroid = 2"}
		Opts.Input.[Destination Set] = {Dir + "\\"+netview+".DBD|Node", "Node", "centroid"}
		Opts.Input.[Via Set] = {Dir + "\\"+netview+".DBD|Node", "Node"}
		Opts.Field.Minimize = "[ImpHOTAB / ImpHOTBA]"
		Opts.Field.Nodes = "Node.ID"
		Opts.Field.[Skim Fields] = {{"[TTHOTAB / TTHOTBA] ", "All"}, {"[HOTAB / HOTBA]", "All"}}
		Opts.Output.[Output Matrix].Label = "SPMAT_HOT_"+PERIOD+i2s(z)
		Opts.Output.[Output Matrix].[File Name] = tmpdir + "\\SPMAT_HOT_"+PERIOD+i2s(z)+".mtx"
		ret_value = RunMacro("TCB Run Procedure", 8, "TCSPMAT", Opts)
		if !ret_value then goto badskim

//***************************************************************
//   Add TTSav, CPMS, CPMS_VOT and PERCENT cores to SPMAT_HOT	*
//***************************************************************
		HOT = OpenMatrix(tmpdir + "\\SPMAT_HOT_"+PERIOD+i2s(z)+".mtx", "True")
		core_list = GetMatrixCoreNames(HOT)
		TTSAVpos = ArrayPosition(core_list, {"TTSAV"}, )
		CPMSpos = ArrayPosition(core_list, {"CPMS"}, )
		CPMS_VOTpos = ArrayPosition(core_list, {"CPMS_VOT"}, )
		Percentpos = ArrayPosition(core_list, {"PERCENT"}, )
		if TTSAVpos = 0 then AddMatrixCore(HOT, "TTSav")
		if CPMSpos = 0 then AddMatrixCore(HOT, "CPMS")
		if CPMS_VOTpos = 0 then AddMatrixCore(HOT, "CPMS_VOT")
		if Percentpos = 0 then AddMatrixCore(HOT, "PERCENT")
		core_list = null
		HOT = null

//***************************************************************
//   TTSav = GP skim time - HOT skim time						*
//***************************************************************
		Opts = null
		Opts.Input.[Matrix Currency] = {tmpdir+"\\SPMAT_HOT_"+PERIOD+i2s(z)+".mtx", "TTSav", "Origin", "Destination"}
		Opts.Input.[Core Currencies] = {{tmpdir+"\\SPMAT_GP_"+PERIOD+i2s(z)+".mtx", "[TTHOTAB / TTHOTBA] (Skim)", "Origin", "Destination"}, {tmpdir+"\\SPMAT_HOT_"+PERIOD+i2s(z)+".mtx", "[TTHOTAB / TTHOTBA]  (Skim)", "Origin", "Destination"}}
		Opts.Global.Method = 8
		Opts.Global.[Cell Range] = 2
		Opts.Global.[Matrix K] = {1, 1}
		Opts.Global.[Force Missing] = "No"
		ret_value = RunMacro("TCB Run Operation", 9, "Fill Matrices", Opts, &Ret)
		if !ret_value then goto badfill1

//***************************************************************
//   Filling CPMS and CPMS_VOT									*
//***************************************************************
		Opts = null
		Opts.Input.[Matrix Currency] = {tmpdir+"\\SPMAT_HOT_"+PERIOD+i2s(z)+".mtx", "TTSav", "Origin", "Destination"}
		Opts.Global.Method = 11
		Opts.Global.[Cell Range] = 2
		Opts.Global.[Expression Text] = "if [TTSav] < 0 then 0 else [TTSav]"
		Opts.Global.[Force Missing] = "Yes"
		ret_value = RunMacro("TCB Run Operation", 10, "Fill Matrices", Opts)
		if !ret_value then goto badfill

		Opts = null
		Opts.Input.[Matrix Currency] = {tmpdir+"\\SPMAT_HOT_"+PERIOD+i2s(z)+".mtx", "CPMS", "Origin", "Destination"}
		Opts.Global.Method = 11
		Opts.Global.[Cell Range] = 2
		Opts.Global.[Expression Text] = "if TTSav <>0 then [[HOTAB / HOTBA] (Skim)]/ [TTSav] else 100"
		Opts.Global.[Force Missing] = "Yes"
		ret_value = RunMacro("TCB Run Operation", 11, "Fill Matrices", Opts)
		if !ret_value then goto badfill

		Opts = null
		Opts.Input.[Matrix Currency] = {tmpdir+"\\SPMAT_HOT_"+PERIOD+i2s(z)+".mtx", "CPMS_VOT", "Origin", "Destination"}
		Opts.Global.Method = 11
		Opts.Global.[Cell Range] = 2
		Opts.Global.[Expression Text] = "Round(CPMS / 0.165,2)"
		Opts.Global.[Force Missing] = "Yes"
		ret_value = RunMacro("TCB Run Operation", 12, "Fill Matrices", Opts)
		if !ret_value then goto badfill

//***************************************************************
//   Export matrix to obtain the percentages					*
//***************************************************************
		HOT = OpenMatrix(tmpdir + "\\SPMAT_HOT_"+PERIOD+i2s(z)+".mtx", "True")
		CreateTableFromMatrix(HOT, tmpdir + "\\HOT_"+PERIOD+i2s(z)+".dbf", "DBASE", {{"Complete", "Yes"}})
		HOT = null

//***************************************************************
//   Create HOT_Table.bin and look up the PERCENT				*
//***************************************************************
		info = GetFileInfo(METDir + "\\HOT_Table.hot")
		if info = null
			then do
				ShowMessage("HwyAssn_selHOT - ERROR! - " + METDir + "\\HOT_Table.hot not found")
				HOTHwyAssnOK = 0
				goto badHOTtable
 			end
			else do
				CopyFile(METDir + "\\HOT_Table.hot", tmpdir + "\\HOT_Table.bin")
				dcbname = tmpdir + "\\HOT_Table.DCB"
				exist = GetFileInfo(dcbname)
				if (exist <> null) then DeleteFile(dcbname)
				mac = OpenFile(dcbname, "w")
				WriteLine(mac, " ")
				WriteLine(mac, "16")
				WriteLine(mac, "\"CPMS_VOT\",R,1,8,0,8,2,,,\"\",,Blank,")
				WriteLine(mac, "\"PERCENT\",R,9,8,0,8,1,,,\"\",,Blank,")
				CloseFile(mac)
			end
		HOT_Table = OpenTable("HOT_Table", "FFB", {tmpdir + "\\HOT_Table.bin"}, {{"Read Only", "False"},{"Shared", "False"}})

		Opts = null
		Opts.Input.[Dataview Set] = {{tmpdir +"\\HOT_"+PERIOD+i2s(z)+".DBF", tmpdir + "\\HOT_Table.bin", "CPMS_VOT", "CPMS_VOT"}, "HOT_"+PERIOD+i2s(z)+"+HOT_Table"}
		Opts.Global.Fields = {"HOT_"+PERIOD+i2s(z)+".PERCENT"}
		Opts.Global.Method = "Formula"
		Opts.Global.Parameter = "HOT_Table.PERCENT"
		ret_value = RunMacro("TCB Run Operation", 13, "Fill Dataview", Opts)
		if !ret_value then goto badfill
		CloseView("HOT_Table")
		DeleteFile(tmpdir + "\\HOT_Table.bin")
		DeleteFile(tmpdir + "\\HOT_Table.DCB")

		Opts = null
		Opts.Input.[Dataview Set] = {tmpdir +"\\HOT_"+PERIOD+i2s(z)+".DBF", "Percent"}
		Opts.Global.Fields = {"PERCENT"}
		Opts.Global.Method = "Formula"
		Opts.Global.Parameter = "If Percent = null then 0 else Percent"
		ret_value = RunMacro("TCB Run Operation", 14, "Fill Dataview", Opts)
		if !ret_value then goto badfill

		OpenTable("HOT_"+PERIOD+i2s(z), "DBASE", {tmpdir + "\\HOT_"+PERIOD+i2s(z)+".dbf",})
		mv = CreateMatrixFromView("HOT_"+PERIOD+i2s(z),"HOT_"+PERIOD+i2s(z)+"|","Origin","Destinatio",{"PERCENT"},
			{{"File Name",tmpdir+"\\Percent_"+PERIOD+i2s(z)+".mtx"},
			 {"Type","Float"},{"Sparse", "No" },{"Column Major", "No" },{"File Based", "Yes" }})
		mv = null
		closeview("HOT_"+PERIOD+i2s(z))

//***************************************************************
//   Multiply the values in PERCENT by .01						*
//***************************************************************
		Opts = null
		Opts.Input.[Matrix Currency] = {tmpdir+"\\Percent_"+PERIOD+i2s(z)+".mtx", "PERCENT", "Origin", "Destinatio"}
		Opts.Global.Method = 11
		Opts.Global.[Cell Range] = 2
		Opts.Global.[Expression Text] = "[PERCENT] * 0.01"
		Opts.Global.[Force Missing] = "Yes"
		ret_value = RunMacro("TCB Run Operation", 15, "Fill Matrices", Opts)
		if !ret_value then goto badfill

//***************************************************************
//   Add the 4 HOT cores to the HOT OD matrix					*
//***************************************************************
		HOT = OpenMatrix(od_hot_matrix,)
		HOT_Cores = GetMatrixCoreNames(HOT)
		gotSOV = "False"
		gotP2 = "False"
		gotP3 = "False"
		gotCOM = "False"
		for i = 1 to HOT_Cores.length do
			if HOT_Cores[i] = "HOTSOV" then gotSOV = "True"
			if HOT_Cores[i] = "HOTPOOL2" then gotP2 = "True"
			if HOT_Cores[i] = "HOTPOOL3" then gotP3 = "True"
			if HOT_Cores[i] = "HOTCOM" then gotCOM = "True"
		end
		if gotSOV = "False" then AddMatrixCore(HOT, "HOTSOV")
		if gotP2 = "False" then AddMatrixCore(HOT, "HOTPOOL2")
		if gotP3 = "False" then AddMatrixCore(HOT, "HOTPOOL3")
		if gotCOM = "False" then AddMatrixCore(HOT, "HOTCOM")
		HOT_Cores = null
		HOT = null

//***************************************************************
//   Fill HOTSOV core with SOV * PERCENT						*
//***************************************************************
		Opts = null
		Opts.Input.[Matrix Currency] = {od_hot_matrix, "HOTSOV", "Rows", "Columns"}
		Opts.Input.[Core Currencies] = {{od_hot_matrix, "SOV", "Rows", "Columns"},
			{tmpdir + "\\Percent_"+PERIOD+i2s(z)+".mtx", "PERCENT", "Origin", "Destinatio"}}
		Opts.Global.Method = 9
		Opts.Global.[Cell Range] = 2
		Opts.Global.[Matrix K] = {1, 1}
		Opts.Global.[Force Missing] = "Yes"
		ret_value = RunMacro("TCB Run Operation", 16, "Fill Matrices", Opts)
		if !ret_value then goto badfill

//***************************************************************
//   Fill HOTPOOL2 core with POOL2 * PERCENT					*
//***************************************************************
		Opts = null
		Opts.Input.[Matrix Currency] = {od_hot_matrix, "HOTPOOL2", "Rows", "Columns"}
		Opts.Input.[Core Currencies] = {{od_hot_matrix, "POOL2", "Rows", "Columns"},
			{tmpdir + "\\Percent_"+PERIOD+i2s(z)+".mtx", "PERCENT", "Origin", "Destinatio"}}
		Opts.Global.Method = 9
		Opts.Global.[Cell Range] = 2
		Opts.Global.[Matrix K] = {1, 1}
		Opts.Global.[Force Missing] = "Yes"
		ret_value = RunMacro("TCB Run Operation", 17, "Fill Matrices", Opts)
		if !ret_value then goto badfill

//***************************************************************
//   Fill HOTPOOL3 core with POOL3 * PERCENT					*
//***************************************************************
		Opts = null
		Opts.Input.[Matrix Currency] = {od_hot_matrix, "HOTPOOL3", "Rows", "Columns"}
		Opts.Input.[Core Currencies] = {{od_hot_matrix, "POOL3", "Rows", "Columns"},
			{tmpdir + "\\Percent_"+PERIOD+i2s(z)+".mtx", "PERCENT", "Origin", "Destinatio"}}
		Opts.Global.Method = 9
		Opts.Global.[Cell Range] = 2
		Opts.Global.[Matrix K] = {1, 1}
		Opts.Global.[Force Missing] = "Yes"
		ret_value = RunMacro("TCB Run Operation", 17, "Fill Matrices", Opts)
		if !ret_value then goto badfill

//***************************************************************
//   Fill HOTCOM core with COM * PERCENT						*
//***************************************************************
		Opts = null
		Opts.Input.[Matrix Currency] = {od_hot_matrix, "HOTCOM", "Rows", "Columns"}
		Opts.Input.[Core Currencies] = {{od_hot_matrix, "COM", "Rows", "Columns"},
			{tmpdir + "\\Percent_"+PERIOD+i2s(z)+".mtx", "PERCENT", "Origin", "Destinatio"}}
		Opts.Global.Method = 9
		Opts.Global.[Cell Range] = 2
		Opts.Global.[Matrix K] = {1, 1}
		Opts.Global.[Force Missing] = "Yes"
		ret_value = RunMacro("TCB Run Operation", 18, "Fill Matrices", Opts)
		if !ret_value then goto badfill

//***************************************************************
//   Subtract the HOT trips from the general purpose cores		*
//***************************************************************
		Opts = null
		Opts.Input.[Matrix Currency] = {od_hot_matrix, "SOV", "Rows", "Columns"}
		Opts.Global.Method = 11
		Opts.Global.[Cell Range] = 2
		Opts.Global.[Expression Text] = "[SOV]- [HOTSOV]"
		Opts.Global.[Force Missing] = "Yes"
		ret_value = RunMacro("TCB Run Operation", 19, "Fill Matrices", Opts)
		if !ret_value then goto badfill

		Opts = null
		Opts.Input.[Matrix Currency] = {od_hot_matrix, "POOL2", "Rows", "Columns"}
		Opts.Global.Method = 11
		Opts.Global.[Cell Range] = 2
		Opts.Global.[Expression Text] = "[POOL2]- [HOTPOOL2]"
		Opts.Global.[Force Missing] = "Yes"
		ret_value = RunMacro("TCB Run Operation", 20, "Fill Matrices", Opts)
		if !ret_value then goto badfill

		Opts = null
		Opts.Input.[Matrix Currency] = {od_hot_matrix, "POOL3", "Rows", "Columns"}
		Opts.Global.Method = 11
		Opts.Global.[Cell Range] = 2
		Opts.Global.[Expression Text] = "[POOL3]- [HOTPOOL3]"
		Opts.Global.[Force Missing] = "Yes"
		ret_value = RunMacro("TCB Run Operation", 20, "Fill Matrices", Opts)
		if !ret_value then goto badfill

		Opts = null
		Opts.Input.[Matrix Currency] = {od_hot_matrix, "COM", "Rows", "Columns"}
		Opts.Global.Method = 11
		Opts.Global.[Cell Range] = 2
		Opts.Global.[Expression Text] = "[COM]- [HOTCOM]"
		Opts.Global.[Force Missing] = "Yes"
		ret_value = RunMacro("TCB Run Operation", 21, "Fill Matrices", Opts)
		if !ret_value then goto badfill

//***************************************************************
//   Assignment													*
//   exclude link sets for 10 vol classes						*
//    1 = sov      - exclude from hov2+, hov3+ & tollonly		*
//    2 = pool2    - exclude from hov3+ & tollonly				*
//    3 = pool3    - exclude from tollonly						*
//    4 = COM      - sovexclude									*
//    5 = MTK      - trkexclude									*
//    6 = HTK      - trkexclude									*
//    7 = HOTSOV   - no exclude									*
//    8 = HOTPOOL2 - no exclude									*
//    9 = HOTPOOL3 - no exclude									*
//   10 = HOTCOM   - no exclude									*
//***************************************************************
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

// Highway Network Setting - determine if toll links present
		SetView(netview)
		tollquery = "Select * where TollAB > 0 or TollBA > 0"
		ntolls = SelectByQuery("TollLinks", "Several", tollquery,)
		if ntolls = 0 then goto notollsHOT

		Opts = null
		Opts.Input.Database = Dir + "\\"+netview+".DBD"
		Opts.Input.Network = Dir + "\\net_highway.net"
		Opts.Input.[Centroids Set] = {Dir + "\\"+netview+".DBD|Node", "Node", "centroid", "Select * where centroid = 1 or centroid = 2"}
		Opts.Input.[Spc Turn Pen Table]= {METDir + "\\trnpnlty.bin"}
		Opts.Input.[Toll Set]= {Dir + "\\"+netview+".DBD|"+netview, netview, "tollset", "Select * where TollAB > 0 or TollBA > 0"}
		Opts.Global.[Global Turn Penalties] = {0, 0, 0, -1}
		ret_value = RunMacro("TCB Run Operation", 23, "Highway Network Setting", Opts, &Ret)
		if !ret_value then goto badnetsettings
		goto skipnotollsHOT
		notollsHOT:
		Opts = null
		Opts.Input.Database = Dir + "\\"+netview+".DBD"
		Opts.Input.Network = Dir + "\\net_highway.net"
		Opts.Input.[Centroids Set] = {Dir + "\\"+netview+".DBD|Node", "Node", "centroid", "Select * where centroid = 1 or centroid = 2"}
		Opts.Input.[Spc Turn Pen Table]= {METDir + "\\trnpnlty.bin"}
		Opts.Global.[Global Turn Penalties] = {0, 0, 0, -1}
		ret_value = RunMacro("TCB Run Operation", 24, "Highway Network Setting", Opts, &Ret)
		if !ret_value then goto badnetsettings
		skipnotollsHOT:

// MMA Assignment - 10 classes
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
		Opts.Global.[Cost Function File] = "bpr.vdf"
		Opts.Global.[VDF Defaults] = {, , 0.15, 4, }
		Opts.Field.[VDF Fld Names] = {"[TTfreeAB / TTfreeBA]", cap_fields, "alpha", "beta", "None"}
//   NOTE: [Load Method], [Loading Multiplier] and [Time Minimum] are deliberately NOT set here.
//   HwyAssn_HOT does not set them, so leaving them at the TransCAD defaults keeps this
//   assignment identical to the model's. Setting Load Method = "CUE" (as the old non-HOT
//   select link macro did) changes the equilibrium path and shifts link volumes slightly.

//   *** the LAST HOT iteration is the select link run - more iterations, tighter convergence ***
		if z = HOTAssnIterations
			then do
				Opts.Global.Convergence = hwyassnconvergefinal
				Opts.Global.Iterations = hwyassnmaxiterfinal
				Opts.Global.[Critical Queries] = {critquery}
				Opts.Global.[Critical Set Names] = {"Crit_link"}
				Opts.Flag.[Do Critical] = 1
				Opts.Output.[Critical Matrix].Label = "Critical Matrix"
				Opts.Output.[Critical Matrix].[File Name] = crit_matrix
			end
			else do
				Opts.Global.Convergence = hwyassnconverge
				Opts.Global.Iterations = hwyassnmaxiter
				Opts.Flag.[Do Critical] = 0
			end
		Opts.Flag.[Do Share Report] = 1
		Opts.Output.[Flow Table] = output_bin

		ret_value = RunMacro("TCB Run Procedure", 25, "MMA", Opts)
		if !ret_value then goto badassign

//   no feedback needed after the final (select link) assignment
		if z = HOTAssnIterations then goto donewithloop

//***************************************************************
//   Add prev travel time fields for the current iteration		*
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
		on notfound default

//*************************************************************************************
//   Roll TTHOT to TTHOTPrev (AB & BA)
//*************************************************************************************
		Opts = null
		Opts.Input.[Dataview Set] = {Dir + "\\"+netview+".dbd|"+netview, netview}
		Opts.Global.Fields = {"TTHOTPrev"+PERIOD+i2s(z)+"AB","TTHOTPrev"+PERIOD+i2s(z)+"BA"}
		Opts.Global.Method = "Formula"
		Opts.Global.Parameter = {"TTHOTAB", "TTHOTBA"}
		ret_value = RunMacro("TCB Run Operation", 26, "Fill Dataview", Opts)
		if !ret_value then goto badroll

//*************************************************************************************
//   New assignment travel time = 0.67 previous + 0.33 last assigned
//   Assigned time is capped at TTfree * maxTTfac
//*************************************************************************************
		Opts = null
		Opts.Input.[Dataview Set] = {{Dir + "\\"+netview+".dbd|"+netview, output_bin, "ID", "ID1"}, netview+"+SLAssn_"+PERIOD+"hot"}
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

	end  // for z
	donewithloop:
	goto quit

	badhotfield:
	ShowMessage("HOT Select Link - ERROR: HOTAB / HOTBA fields not found in " + netview + ". A HOT assignment cannot be run on this network.")
	HOTHwyAssnOK = 0
	goto badquit
	badnetbuild:
	ShowMessage("HOT Select Link - ERROR building highway network, check for HOTAB & HOTBA network fields")
	HOTHwyAssnOK = 0
	goto badquit
	badnetsettings:
	ShowMessage("HOT Select Link - ERROR in highway network settings")
	HOTHwyAssnOK = 0
	goto badquit
	badassign:
	ShowMessage("HOT Select Link - ERROR in highway assignment")
	HOTHwyAssnOK = 0
	goto badquit
	badskim:
	ShowMessage("HOT Select Link - ERROR in highway skim")
	HOTHwyAssnOK = 0
	goto badquit
	badroll:
	ShowMessage("HOT Select Link - ERROR, did not roll TTHOT to TTHOTPrev")
	HOTHwyAssnOK = 0
	goto badquit
	badtt:
	ShowMessage("HOT Select Link - ERROR, could not calculate new TTHOT")
	HOTHwyAssnOK = 0
	goto badquit
	badimp:
	ShowMessage("HOT Select Link - ERROR, could not calculate new ImpHOT")
	HOTHwyAssnOK = 0
	goto badquit
	badfill:
	ShowMessage("HOT Select Link - ERROR filling a HOT matrix / dataview")
	HOTHwyAssnOK = 0
	goto badquit
	badHOTtable:
	ShowMessage("HOT Select Link - ERROR, HOT_Table.hot doesn't exist")
	HOTHwyAssnOK = 0
	goto badquit
	badfill1:
	ShowMessage("HOT Select Link - ERROR, Did not fill TTSav")
	HOTHwyAssnOK = 0
	goto badquit
	UserKill:
	ShowMessage("HOT Select Link - User killed job")
	HOTHwyAssnOK = 0
	goto quit
	badquit:
	RunMacro("TCB Closing", ret_value, "TRUE" )
	quit:
	on notfound default
	on error default
	on escape default
	if GetView() <> null then CloseMap()
	RunMacro("G30 File Close All")
	if initial_threads <> null then SetNumThreads(initial_threads)
	return(HOTHwyAssnOK)
endMacro

macro "tot_assn_sellink" (pkhrfac, minspfac, Dir, netview, AssnSubDir, assntype)
//revised August 2013 using mobile6.rsc as form - thanks Jhun @ KHA
//assntype - "select_link"
// McLelland
	info = GetDBInfo(Dir + "\\"+netview+".dbd")
	scope = info[1]
	// Create a map using this scope
	CreateMap(netview, {{"Scope", scope},{"Auto Project", "True"}})
	file = Dir + "\\"+netview+".dbd"
	layers = GetDBLayers(file)
	addlayer(netview, "Node", file, layers[1])
	addlayer(netview, netview, file, layers[2])
	SetLayerVisibility("Node", "True")
	SetIcon("Node|", "Font Character", "Caliper Cartographic|2", 36)
	SetLayerVisibility(netview, "True")
	solid = LineStyle({{{1, -1, 0}}})
	SetLineStyle(netview+"|", solid)
	SetLineColor(netview+"|", ColorRGB(32000, 32000, 32000))
	SetLineWidth(netview+"|", 0)
	setview(netview)
// drop transit links
	selectset = "select * where FUNCL < 30 or FUNCL = 82 or FUNCL = 83 or FUNCL = 90"
	nlnks = SelectbyQuery("HwyLinks", "Several", selectset,)
	ExportView(netview+"|HwyLinks", "FFB", AssnSubDir + "\\Tempnet.bin", {"ID", "LENGTH", "DIR", "FUNCL", "FEDFUNC_AQ", "CO_FEDFUNC", "Strname", "A_CrossStr", "B_CrossStr", "AREATP", "CALIB15", "Scrln", "COUNTY", "Cap1hrAB", "Cap1hrBA", "TTfreeAB", "TTfreeBA", "TTPkAssnAB", "TTPkAssnBA", "lanesAB", "lanesBA"},)
	closemap()

	net_bin = AssnSubDir + "\\Tempnet.bin"
	if assntype = "select_link" then do
		am_bin = AssnSubDir + "\\" + "selectlink_AM_" + slinkid + ".bin"
		pm_bin = AssnSubDir + "\\" + "selectlink_PM_" + slinkid + ".bin"
		mi_bin = AssnSubDir + "\\" + "selectlink_MID_" + slinkid + ".bin"
		nt_bin = AssnSubDir + "\\" + "selectlink_NI_" + slinkid + ".bin"
		out_dbf = AssnSubDir + "\\" + "Tot_Assn_" + slinkid + ".dbf"
	end
	tempam_bin = AssnSubDir + "\\TempAM.bin"
	temppm_bin = AssnSubDir + "\\TempPM.bin"
	tempmi_bin = AssnSubDir + "\\TempMI.bin"
// open network and am peak - join
	net_in = OpenTable("Net", "FFB", {net_bin,})
	am_in  = OpenTable("AM", "FFB", {am_bin,})

	joinam = JoinViews("NetAM", "Net.ID","AM.ID1",)

// Close input tables
	CloseView(net_in)
	CloseView(am_in)

// Create AM fields
	fun2		= CreateExpression(joinam, "Fun2", "if FUNCL = 1 or FUNCL = 2 or FUNCL = 9 then 1 else if funcl < 6 then 3 else if funcl < 10 then 4 else if (funcl > 20 and funcl < 30 or funcl = 82 or funcl = 83) then 2 else 0",)
	cntyaf		= CreateExpression(joinam, "CntyAF", "COUNTY * 10000 + AREATP * 100 + Fun2",)
	vmtlen		= CreateExpression(joinam, "VMTLen", "if FUNCL = 90 then nz(LENGTH) * 2 else nz(LENGTH)",)
	volamab		= CreateExpression(joinam, "VolAMAB", "nz(AB_Flow)",)
	volamba		= CreateExpression(joinam, "VolAMBA", "nz(BA_Flow)",)
	selvolamab	= CreateExpression(joinam, "selVolAMAB", "nz(AB_Flow_Crit_link)",)
	selvolamba	= CreateExpression(joinam, "selVolAMBA", "nz(BA_Flow_Crit_link)",)
	AMFields = {"ID", "LENGTH", "DIR", "FUNCL", "FEDFUNC_AQ", "CO_FEDFUNC", "Strname", "A_CrossStr", "B_CrossStr", "AREATP", "CALIB15", "Scrln", "COUNTY", "Cap1hrAB", "Cap1hrBA", "TTfreeAB", "TTfreeBA", "TTPkAssnAB", "TTPkAssnBA", "lanesAB", "lanesBA", "Fun2", "CntyAF", "VMTLen", "VolAMAB", "VolAMBA", "selVolAMAB", "selVolAMBA"}
	ExportView(joinam+"|", "FFB", tempam_bin, AMFields,)
	CloseView(joinam)
// PM Peak
// open temp am file and pm peak - join
	tam_in = OpenTable("TAM", "FFB", {tempam_bin,})
  	pm_in  = OpenTable("PM", "FFB", {pm_bin,})

	joinpm = JoinViews("TamPM", "TAM.ID","PM.ID1",)

// Close input tables
	CloseView(tam_in)
	CloseView(pm_in)

// Create PM fields
	volpmab		= CreateExpression(joinpm, "VolPMAB", "nz(AB_Flow)",)
	volpmba		= CreateExpression(joinpm, "VolPMBA", "nz(BA_Flow)",)
	selvolpmab	= CreateExpression(joinpm, "selVolPMAB", "nz(AB_Flow_Crit_link)",)
	selvolpmba	= CreateExpression(joinpm, "selVolPMBA", "nz(BA_Flow_Crit_link)",)
	PMFields = {"VolPMAB", "VolPMBA", "selVolPMAB", "selVolPMBA"}
	AMPMFields = AMFields + PMFields
	ExportView(joinpm+"|", "FFB", temppm_bin, AMPMFields,)
	CloseView(joinpm)
// Midday
// open temp pm file and midday - join
	tpm_in = OpenTable("TPM", "FFB", {temppm_bin,})
  	mi_in  = OpenTable("MI", "FFB", {mi_bin,})

	joinmi = JoinViews("TpmMI", "TPM.ID","MI.ID1",)

// Close input tables
	CloseView(tpm_in)
	CloseView(mi_in)

// Create MI fields
	volmiab		= CreateExpression(joinmi, "VolMIAB", "nz(AB_Flow)",)
	volmiba		= CreateExpression(joinmi, "VolMIBA", "nz(BA_Flow)",)
	selvolmiab	= CreateExpression(joinmi, "selVolMIAB", "nz(AB_Flow_Crit_link)",)
	selvolmiba	= CreateExpression(joinmi, "selVolMIBA", "nz(BA_Flow_Crit_link)",)
	MIFields = {"VolMIAB", "VolMIBA", "selVolMIAB", "selVolMIBA"}
	AMPMMIFields = AMPMFields + MIFields
	ExportView(joinmi+"|", "FFB", tempmi_bin, AMPMMIFields,)
	CloseView(joinmi)

// Night
// open temp mi file and night  - join
	tmi_in = OpenTable("TMI", "FFB", {tempmi_bin,})
  	nt_in  = OpenTable("NT", "FFB", {nt_bin,})

	joinnt = JoinViews("TmiMI", "TMI.ID","NT.ID1",)

// Close input tables
	CloseView(tmi_in)
	CloseView(nt_in)

// Create NT fields
	volntab		= CreateExpression(joinnt, "VolNTAB", "nz(AB_Flow)",)
	volntba		= CreateExpression(joinnt, "VolNTBA", "nz(BA_Flow)",)
	selvolntab	= CreateExpression(joinnt, "selVolNTAB", "nz(AB_Flow_Crit_link)",)
	selvolntba	= CreateExpression(joinnt, "selVolNTBA", "nz(BA_Flow_Crit_link)",)
	NTFields = {"VolNTAB", "VolNTA", "selVolNTAB", "selVolNTBA"}
//Daily tables
	tot_vol		= CreateExpression(joinnt, "Tot_Vol", "VolAMAB + VolAMBA + VolPMAB + VolPMBA + VolMIAB + VolMIBA + VolNTAB + VolNTBA",)
	totselvol	= CreateExpression(joinnt, "TOTselVol", "selVolAMAB + selVolAMBA + selVolPMAB + selVolPMBA + selVolMIAB + selVolMIBA + selVolNTAB + selVolNTBA",)
		OutFields =
		{"ID", "LENGTH", "DIR", "FUNCL", "FEDFUNC_AQ", "CO_FEDFUNC", "Strname", "A_CrossStr", "B_CrossStr",
	  	 "AREATP", "CALIB15", "Scrln", "COUNTY", "Cap1hrAB", "Cap1hrBA",
	 	 "TTfreeAB", "TTfreeBA", "TTPkAssnAB", "TTPkAssnBA", "lanesAB", "lanesBA",
	 	 "Fun2", "CntyAF", "VolAMAB", "VolAMBA", "VolMIAB", "VolMIBA", "VolPMAB", "VolPMBA",
		 "VolNTAB", "VolNTBA", "selVolAMAB", "selVolAMBA", "selVolMIAB", "selVolMIBA",
		 "selVolPMAB", "selVolPMBA", "selVolNTAB", "selVolNTBA", "Tot_Vol", "TotselVol"}
	ExportView(joinnt+"|", "DBASE", out_dbf, OutFields,)
	CloseView(joinnt)
	//Get Rid of temps
	tempset = {net_bin, tempam_bin, temppm_bin, tempmi_bin}
	for i = 1 to tempset.length do
		killit = GetFileInfo(tempset[i])
		if killit <> null then do
			killparts = SplitPath(tempset[i])
			DeleteFile(tempset[i])
			DeleteFile(killparts[1] + killparts[2] + killparts[3] + ".dcb")
		end
	end //for i
endmacro

dbox "IDgetter" Title: "Link ID?"
	Edit Text "LinkID" 10, 1, 10 prompt: "Enter Link ID" variable: slinkid

	Button "Continue" 2, 3, 8, 1 default do
		Return(1)
        	endItem
enddbox
