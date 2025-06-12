Macro "HwyAssn_MMA" (Args, od_matrix, cap_field, output_bin, timeperiod)

//*********************************************************************************************************************
//Hwy Assn
// This version runs BPR - generalized cost won't work in v.7.		

//   Added funcls 24 and 25: JWM, July 19, 2007
//   Update to TC 5.0 - change to bpr delay, Feb, 2008
//   Updated for new UI - McLelland, Nov, 2015

//	Allows user to choose gc_mrm - generalized cost function used in previous MRM 
//	  versions on Arguments setup - gc_mrm will not work with ver.7
//      (we were running travel time as 95% of GC anyway)  JWM 09/19/16
//  added toll only (funcl 23): MK, 10/20/17

// MK, 5/29/19: This version uses funcl 24 as a de facto no-truck lane (for the PPSLs on I-77 North) (under: Opts.Input.[Exclusion Link Sets])
//  	(may need to clean up references if used in official model)
// 5/30/19, mk: There are now three distinct networks: AM peak, PM peak, and offpeak; pass correct netview through

//*********************************************************************************************************************

	// LogFile = Args.[Log File].value
	// SetLogFileName(LogFile)
	// ReportFile = Args.[Report File].value
	// SetReportFileName(ReportFile)

	METDir = Args.[MET Directory]
	Dir = Args.[Run Directory]
	timeweight = Args.TimeWeight
	distweight = Args.DistWeight
	hwyassnmaxiter = Args.[HwyAssn Max Iter Feedback]
	hwyassnconverge = Args.[HwyAssn Converge]
	hwy_file = Args.[Hwy Name]
	{, , netview, } = SplitPath(hwy_file)

	user_threads = GetNumThreads()
	
	if user_threads <> 16
		then SetNumThreads(16)
		else do SetNumThreads(user_threads)
		end
	
	run_threads = GetNumThreads()

	AppendToLogFile(2, "Set Threads = " + i2s(run_threads))
	

	/*if timeperiod = "AMpeak" then do	
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
		goto badtimeperiod
	end
	*/
	
	hwyassntype = "BPR"
	msg = null
					
	HwyAssnOK = 1
	datentime = GetDateandTime()
	AppendToLogFile(2, "Enter HwyAssn_MMA: " + datentime)
	AppendToLogFile(2, "HwyAssn maximum no. of iterations = " + i2s(hwyassnmaxiter))
	AppendToLogFile(2, "HwyAssn convergence = " + r2s(hwyassnconverge))
	if hwyassntype = "BPR"
		then AppendToLogFile(2, "HwyAssn Type = BPR")
		else do
			AppendToLogFile(2, "HwyAssn Type = gc_mrm - weighted travel time / distance")
			AppendToLogFile(2, "HwyAssn weight on travel time (minutes) = " + r2s(timeweight))
			AppendToLogFile(2, "HwyAssn weight on distance (miles) = " + r2s(distweight))
		end

//capacity fields
	cap_fields = "[" + cap_field + "AB / " + cap_field + "BA]"

//      check highway network if hov lanes exist
//      hov2+ are funcl 22 and 82  (24 is now a peak-period shoulder lane that excludes trucks (I-77 North)
//      hov3+ are funcl 25 and 83 (23 now tollonly)
//	tollonly are funcl 23 and 83
	
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
	selpool2 = "Select * where funcl = 22 or funcl = 82"
	selpool3 = "Select * where funcl = 25 or funcl = 83"
	seltollonly = "Select * where funcl = 23"
	seltoll = "Select * where tollAB > 0 or tollBA > 0"
	Selectbyquery("check_pool2", "Several", selpool2,)
	Selectbyquery("check_pool3", "Several", selpool3,)
	Selectbyquery("check_tollonly", "Several", seltollonly,)
	Selectbyquery("check_toll", "Several", seltoll,)
	pool2count = getsetcount("check_pool2")
	pool3count = getsetcount("check_pool3")
	tollonlycount = getsetcount("check_tollonly")
	tollcount = getsetcount("check_toll")
//        showmessage("pool2 " + string(pool2count)+"    pool3 "+string(pool3count))
	closemap()


	if pool2count = 0 and pool3count = 0 and tollonlycount = 0 then do
		HOVlanes = "noHOV"
		AppendToLogFile(2, "HwyAssn network has NO HOV/HOT lanes ")
	end
/*edit, MK: don't need to specify what types of HOV/toll facilities
	else if pool2count > 0 and pool3count = 0 then do

		//Network has HOV2+ facilities - and no HOV3+ facilities
		//exclude link sets for 6 vol classes
		// 1 = sov - exclude from hov2+ and hov3+  (funcl 22,82 & 23,25,83=sovexclude)
		// 2 = pool2 - no exclusion 
		// 3 = pool3 - no exclusion
		// 4 = COM - exclude from all hov (sovexclude)
		// 5 = MTK - exclude from all hov & funcl 24 (truckexclude)
		// 6 = HTK - exclude from all hov & funcl 24 (truckexclude)

		HOVlanes = "HOV2only"
		AppendToLogFile(2, "HwyAssn network has HOV/HOT 2+ lanes, count="+i2s(pool2count))
	end
	else if pool2count = 0 and pool3count > 0 then do
		// 2 = pool2 - exclude from HOV3+ (funcl 23, 25, 83)
		HOVlanes = "HOV3only"
		AppendToLogFile(2, "HwyAssn network has HOV/HOT 3+ lanes, count="+i2s(pool3count))
	end
	else do  // HOV2 & HOV3
		HOVlanes = "HOV2and3"
		AppendToLogFile(2, "HwyAssn network has HOV/HOT 2+ lanes AND 3+ lanes, 2+ count="+i2s(pool2count) +" 3+ count="+i2s(pool3count))
	end
*/	else do
		AppendToLogFile(2, "HwyAssn network has " + i2s(pool2count) + "HOV/HOT 2+ lanes, " + i2s(pool3count) + " HOV/HOT 3+ lanes, " + i2s(tollonlycount) + " toll only lanes")
	end

    RunMacro("TCB Init")

// Build Highway Network

    Opts = null

	// Common opts (regardless of HOV
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

/*edit mk; don't need to do options for link set, since it is implied in the definition of each option
	//HOV specific opts
	if HOVlanes = "noHOV" then do	
     	Opts.Input.[Link Set] = {Dir + "\\"+netview+".DBD|"+netview, netview, "hwynet", "Select * where (funcl > 0 and funcl < 10) or funcl =90"}
	end
	else if HOVlanes = "HOV2only" then do
     	Opts.Input.[Link Set] = {Dir + "\\"+netview+".DBD|"+netview, netview, "hwynet", "Select * where (funcl > 0 and funcl < 10) or funcl = 22 or  funcl = 24 or funcl = 82 or funcl = 90"}
	end
	else if HOVlanes = "HOV3only" then do
     	Opts.Input.[Link Set] = {Dir + "\\"+netview+".DBD|"+netview, netview, "hwynet", "Select * where (funcl > 0 and funcl < 10) or funcl = 23 or  funcl = 25 or funcl = 83 or funcl = 90"}
	end
	else do  // HOV2 & HOV3
 */    	Opts.Input.[Link Set] = {Dir + "\\"+netview+".DBD|"+netview, netview, "hwynet", "Select * where (funcl > 0 and funcl < 10) or funcl = 22 or funcl = 23 or funcl = 24 or funcl = 25 or funcl = 82 or funcl = 83 or funcl = 90"}
//	end	

	ret_value = RunMacro("TCB Run Operation", "Build Highway Network", Opts, &Ret)
     	if !ret_value then goto badnetbuild


// Highway Network Setting

	Opts = null
	
	Opts.Input.Database = Dir + "\\"+netview+".DBD"
	Opts.Input.Network = Dir + "\\net_highway.net"
	Opts.Input.[Centroids Set] = {Dir + "\\"+netview+".DBD|Node", "Node", "centroid", "Select * where centroid = 1 or centroid = 2"}
	Opts.Input.[Spc Turn Pen Table]= {METDir + "\\trnpnlty.bin"}
	Opts.Global.[Global Turn Penalties] = {0, 0, 0, -1}
	
	// Toll specific opts
	if tollcount > 0 then do
		Opts.Input.[Toll Set]= {Dir + "\\"+netview+".DBD|"+netview, netview, "tollset", "Select * where TollAB > 0 or TollBA > 0"}
		AppendToLogFile(2, "HwyAssn network has toll links, count="+i2s(tollcount))
	end
	
	ret_value = RunMacro("TCB Run Operation", "Highway Network Setting", Opts, &Ret)
    if !ret_value then goto badnetsettings

//MMA Assignment - 

	Opts = null

	Opts.Input.Database = Dir + "\\"+netview+".DBD"
	Opts.Input.Network = Dir + "\\net_highway.net"
	Opts.Input.[OD Matrix Currency] = {od_matrix, "SOV", "Rows", "Columns"}
	Opts.Field.[Vehicle Classes] = {1, 2, 3, 4, 5, 6}
	Opts.Field.[Fixed Toll Fields] = {"[TollAB / TollBA]", "[TollAB / TollBA]", "[TollAB / TollBA]", "[TollAB / TollBA]", "[TollAB / TollBA]", "[TollAB / TollBA]"}
	Opts.Field.[PCE Fields] = {"None", "None", "None", "None", "None", "None"}
	Opts.Global.[Number of Classes] = 6
	Opts.Global.[Load Method] = "CUE"
	Opts.Global.[Loading Multiplier] = 1
	Opts.Global.[Time Minimum] = 0.01
	Opts.Global.[Class PCEs] = {1, 1, 1, 1, 1.5, 2.5}
	Opts.Global.[Class VOIs] = {1, 1, 1, 1, 1, 1}
	Opts.Global.Iterations = hwyassnmaxiter
	Opts.Global.Convergence = hwyassnconverge

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
		
// ************************************************

	Opts.Flag.[Do Critical] = 0
	Opts.Flag.[Do Share Report] = 1   
	Opts.Output.[Flow Table] = output_bin

	//HOV specific opts
	if HOVlanes = "noHOV" then do	
		Opts.Input.[Exclusion Link Sets] = {, , , , ,}
	end
/*edit, mk: just set up exclusion sets one time.  If network doesn't have funcls, then won't matter to have them listed
	else if HOVlanes = "HOV2only" then do
     	Opts.Input.[Exclusion Link Sets] = 
			{{Dir + "\\"+netview+".DBD|"+netview, netview, "sovexclude", "Select * where funcl = 22 or funcl = 23 or funcl = 24 or funcl = 25 or funcl = 82 or funcl = 83"},
			  , 
			  , 
			 {Dir + "\\"+netview+".DBD|"+netview, netview, "sovexclude"}, 
			 {Dir + "\\"+netview+".DBD|"+netview, netview, "sovexclude"}, 
			 {Dir + "\\"+netview+".DBD|"+netview, netview, "sovexclude"}}
	end
	else if HOVlanes = "HOV3only" then do
     	Opts.Input.[Exclusion Link Sets] = 
			{{Dir + "\\"+netview+".DBD|"+netview, netview, "sovexclude", "Select * where funcl = 22 or funcl = 23 or funcl = 24 or funcl = 25 or funcl = 82 or funcl = 83"},
			 {Dir + "\\"+netview+".DBD|"+netview, netview, "pool2exclude", "Select * where funcl = 23 or funcl = 25 or funcl = 83"}, 
			  , 
			 {Dir + "\\"+netview+".DBD|"+netview, netview, "sovexclude"}, 
			 {Dir + "\\"+netview+".DBD|"+netview, netview, "sovexclude"}, 
			 {Dir + "\\"+netview+".DBD|"+netview, netview, "sovexclude"}}
	end
	else do  // HOV2 & HOV3
     	Opts.Input.[Exclusion Link Sets] = 
			{{Dir + "\\"+netview+".DBD|"+netview, netview, "sovexclude", "Select * where funcl = 22 or funcl = 23 or funcl = 24 or funcl = 25 or funcl = 82 or funcl = 83"},
		  	 {Dir + "\\"+netview+".DBD|"+netview, netview, "pool2exclude", "Select * where funcl = 23 or funcl = 25 or funcl = 83"}, 
			  , 
			 {Dir + "\\"+netview+".DBD|"+netview, netview, "sovexclude"}, 
			 {Dir + "\\"+netview+".DBD|"+netview, netview, "sovexclude"}, 
			 {Dir + "\\"+netview+".DBD|"+netview, netview, "sovexclude"}}
	end	
*/	else do
    	Opts.Input.[Exclusion Link Sets] = 
		{{Dir + "\\"+netview+".DBD|"+netview, netview, "sovexclude", "Select * where funcl = 22 or funcl = 23 or funcl = 25 or funcl = 82 or funcl = 83"},
	  	 {Dir + "\\"+netview+".DBD|"+netview, netview, "pool2exclude", "Select * where funcl = 23 or funcl = 25 or funcl = 83"}, 
	  	 {Dir + "\\"+netview+".DBD|"+netview, netview, "pool3exclude", "Select * where funcl = 23"}, 
		 {Dir + "\\"+netview+".DBD|"+netview, netview, "sovexclude"}, 
		 {Dir + "\\"+netview+".DBD|"+netview, netview, "trkexclude", "Select * where funcl = 22 or funcl = 23 or funcl = 24 or funcl = 25 or funcl = 82 or funcl = 83"},
		 {Dir + "\\"+netview+".DBD|"+netview, netview, "trkexclude"}}
	end


	ret_value = RunMacro("TCB Run Procedure", "MMA", Opts, &Ret)
   	if !ret_value then goto badassign

goto quit

badtimeperiod:
	Throw("Highway Assignment Time period error")
	AppendToLogFile(1, "Highway Assignment: Error: - Time period error")
	ShowItem(" Error/Warning messages ")
	ShowItem("netmessageslist")
	goto quit

badnetbuild:
	Throw("HwyAssn MMA - error building highway network")
	AppendToLogFile(2, "HwyAssn MMA - error building highway network")
	goto badquit

badnetsettings:
	Throw("HwyAssn MMA - error in highway network settings")
	AppendToLogFile(2, "HwyAssn MMA - error in highway network settings")
	goto badquit

badassign:
	Throw("HwyAssn MMA - error in highway MMA Assignment")
	AppendToLogFile(2, "HwyAssn MMA - error in highway MMA Assignment")
	goto badquit

badquit:
	HwyAssnOK = 0
	Throw("badquit: Last error message= " + GetLastError())
	AppendToLogFile(2, "badquit: Last error message= " + GetLastError())

	RunMacro("TCB Closing", ret_value, "TRUE" )

quit:
	datentime = GetDateandTime()
	AppendToLogFile(2, "Exit HwyAssn_MMA: " + datentime)
	SetNumThreads(initial_threads)
	return(HwyAssnOK)

endMacro
