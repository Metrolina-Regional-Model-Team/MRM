Macro "Open Select Link Dbox" (Args)
	RunDbox("HwyAssn_SelectLink_dbox", Args)
endmacro
DBox "HwyAssn_SelectLink_dbox" center, center, 45, 18 Title: "Select Link Analysis" Help: "test" toolbox
// Test to determine if only HOV are paying tolls (they shouldn't be)_July 11, 2007
//toolbox
		init do
			shared arguments
			global slinkid
			dim arguments[15]
			arguments[1] = "Directory Location"
			arguments[5] = "Network File"
			arguments[15] = "Output Location"
			arguments[2] = 2.0
			arguments[3] = 0.1
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
//
//***************************************************************
//								*
//   PERIOD = Time of day					*
//								*
//***************************************************************

		Checkbox "AM PEAK" 3, 7 Help: "Add the Area Type macro to the list of macros to be run at one time" variable: ampeak do
			enditem	

		Checkbox "MIDDAY" 3, 9 Help: "Add the Area Type macro to the list of macros to be run at one time" variable: midday do
			enditem	

		Checkbox "PM PEAK" 23, 7 Help: "Add the Area Type macro to the list of macros to be run at one time" variable: pmpeak do
			enditem	

		Checkbox "NIGHT" 23, 9 Help: "Add the Area Type macro to the list of macros to be run at one time" variable: night do
			enditem	

		Checkbox "HOT Assignment?" 23, 11 Help: "Check if a HOT Assignment was run" variable: hotassn do
			enditem	

		Button 4,11 Prompt: "Enter Link ID" do
			on escape goto fileescaped
				arguments[11] = rundbox("IDgetter")
				fileescaped:
				on escape default
			enditem
			
/*		Button 22,11 Prompt: "Select Link from Map (not ready)" do
			if ampeak = 1 then do
				arguments[6] = "AM"
				arguments[7] = arguments[1] + "\\tod2\\ODHwyVeh_AMPeak.mtx"
			        arguments[8] = "CapPk3hr"
			        arguments[9] = arguments[15] + "\\" + "selectlink_AM_" + slinkid + ".bin"
				arguments[10] = arguments[1] + "\\tod2\\ODHwyVeh_AMPeakSelect.mtx"
				if hotassn = 1 then do
					arguments[7] = arguments[1] + "\\tod2\\ODHwyVeh_AMPeakhot.mtx"
				end	
				runmacro("HwyAssn_sel", arguments)
				end
			if midday = 1 then do
				arguments[6] = "MD"
				arguments[7] = arguments[1] + "\\tod2\\ODHwyVeh_MIDDAY.mtx"
			        arguments[8] = "capMid"
			        arguments[9] = arguments[15] + "\\" + "selectlink_MID_" + slinkid + ".bin"
				arguments[10] = arguments[1] + "\\tod2\\ODHwyVeh_MIDDAYSelect.mtx"
				if hotassn = 1 then do
					arguments[7] = arguments[1] + "\\tod2\\ODHwyVeh_MIDDAYhot.mtx"
				end	
				runmacro("HwyAssn_sel", arguments)
				end
			if pmpeak = 1 then do
				arguments[6] = "PM"
				arguments[7] = arguments[1] + "\\tod2\\ODHwyVeh_PMPeak.mtx"
			        arguments[8] = "CapPk3hr"
			        arguments[9] = arguments[15] + "\\" + "selectlink_PM_" + slinkid + ".bin"
				arguments[10] = arguments[1] + "\\tod2\\ODHwyVeh_PMPeakSelect.mtx"
				runmacro("HwyAssn_sel", arguments)
				end
			if night = 1 then do
				arguments[6] = "NI"
				arguments[7] = arguments[1] + "\\tod2\\ODHwyVeh_NIGHT.mtx"
			        arguments[8] = "CapPk3hr"
			        arguments[9] = arguments[15] + "\\" + "selectlink_NI_" + slinkid + ".bin"
				arguments[10] = arguments[1] + "\\tod2\\ODHwyVeh_NIGHTSelect.mtx"
				if hotassn = 1 then do
					arguments[7] = arguments[1] + "\\tod2\\ODHwyVeh_AMPeakhot.mtx"
				end	
				runmacro("HwyAssn_sel", arguments)
				end
			enditem
*/
	Button 4,13 Prompt: "Run Select Link" do
			if ampeak = 1 then do
				arguments[6] = "AM"
				arguments[7] = arguments[1] + "\\tod2\\ODHwyVeh_AMPeak.mtx"
			        arguments[8] = "CapPk3hr"
			        arguments[9] = arguments[15] + "\\" + "selectlink_AM_" + slinkid + ".bin"
				arguments[10] = arguments[1] + "\\tod2\\ODHwyVeh_AMPeakSelect.mtx"
				if hotassn = 1 then do
					arguments[7] = arguments[1] + "\\tod2\\ODHwyVeh_AMPeakhot.mtx"
				end	
				runmacro("HwyAssn_sel", arguments)
				end
			if midday = 1 then do
				arguments[6] = "MD"
				arguments[7] = arguments[1] + "\\tod2\\ODHwyVeh_MIDDAY.mtx"
			        arguments[8] = "capMid"
			        arguments[9] = arguments[15] + "\\" + "selectlink_MID_" + slinkid + ".bin"
				arguments[10] = arguments[1] + "\\tod2\\ODHwyVeh_MIDDAYSelect.mtx"
				if hotassn = 1 then do
					arguments[7] = arguments[1] + "\\tod2\\ODHwyVeh_MIDDAYhot.mtx"
				end	
				runmacro("HwyAssn_sel", arguments)
				end
			if pmpeak = 1 then do
				arguments[6] = "PM"
				arguments[7] = arguments[1] + "\\tod2\\ODHwyVeh_PMPeak.mtx"
			        arguments[8] = "CapPk3hr"
			        arguments[9] = arguments[15] + "\\" + "selectlink_PM_" + slinkid + ".bin"
				arguments[10] = arguments[1] + "\\tod2\\ODHwyVeh_PMPeakSelect.mtx"
				if hotassn = 1 then do
					arguments[7] = arguments[1] + "\\tod2\\ODHwyVeh_PMPeakhot.mtx"
				end	
				runmacro("HwyAssn_sel", arguments)
				end
			if night = 1 then do
				arguments[6] = "NI"
				arguments[7] = arguments[1] + "\\tod2\\ODHwyVeh_NIGHT.mtx"
			        arguments[8] = "CapNight"
			        arguments[9] = arguments[15] + "\\" + "selectlink_NI_" + slinkid + ".bin"
				arguments[10] = arguments[1] + "\\tod2\\ODHwyVeh_NIGHTSelect.mtx"
				if hotassn = 1 then do
					arguments[7] = arguments[1] + "\\tod2\\ODHwyVeh_NIGHThot.mtx"
				end	
				runmacro("HwyAssn_sel", arguments)
				end
			enditem

	Close do
        	Return()
        	endItem

	Button 4,15 Prompt: "Tot Assn" do

			Dir = arguments[1]
			AssnSubDir = arguments[15]
			netview = arguments[4]
			minspfac = 10
			pkhrfac = 0.40
			runmacro("tot_assn_sellink", pkhrfac, minspfac, Dir, netview, AssnSubDir, "select_link")
		enditem

enddbox


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
		goto assnHOV2only
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
//	Opts.Field.[VDF Fld Names] = {"[TTfreeAB / TTfreeBA]", cap_fields, "alpha", "beta", "None", "[TollAB / TollBA]", "None", "Length", "None"}
     	Opts.Global.[Number of Classes] = 6
	Opts.Global.[Load Method] = "UE"
	Opts.Global.[Loading Multiplier] = 1
	Opts.Global.Convergence = 0.01
	Opts.Global.[Time Minimum] = 0.01
    	Opts.Global.[Class PCEs] = {1, 1, 1, 1, 1.5, 2.5}
     	Opts.Global.[Class VOIs] = {1, 1, 1, 1, 1, 1}
//     	Opts.Global.[Cost Function File] = "gc_mrm.vdf"
//	Opts.Global.[VDF Defaults] = {, , 0.15, 4, 0, distweight, timeweight, , 0}
     	Opts.Global.Iterations = 50

     	Opts.Flag.[Do Critical] = 0
     	Opts.Flag.[Do Share Report] = 1   
     	Opts.Output.[Flow Table] = output_bin

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

//showmessage(od_matrix+" "+cap_field+" "+output_bin+" "+netview+" "+Dir+" "+Location[1]+Location[2])
     	Opts = null
     	Opts.Input.Database = Dir + "\\"+netview+".DBD"
     	Opts.Input.Network = Dir + "\\net_highway.net"
     	Opts.Input.[OD Matrix Currency] = {od_matrix, "SOV", "Rows", "Columns"}
     	Opts.Input.[Exclusion Link Sets] = 
{{Dir + "\\"+netview+".DBD|"+netview, netview, "sovexclude", "Select * where funcl = 22 or funcl = 23 or funcl = 24 or funcl = 25 or funcl = 82 or funcl = 83"}, , , {Dir + "\\"+netview+".DBD|"+netview, netview, "sovexclude"}, {Dir + "\\"+netview+".DBD|"+netview, netview, "sovexclude"}, {Dir + "\\"+netview+".DBD|"+netview, netview, "sovexclude"}}
     	Opts.Field.[Vehicle Classes] = {1, 2, 3, 4, 5, 6}
	Opts.Field.[Fixed Toll Fields] = {"[TollAB / TollBA]", "[TollAB / TollBA]", "[TollAB / TollBA]", "[TollAB / TollBA]", "[TollAB / TollBA]", "[TollAB / TollBA]"}
	Opts.Field.[PCE Fields] = {"None", "None", "None", "None", "None", "None"}
//	Opts.Field.[VDF Fld Names] = {"[TTfreeAB / TTfreeBA]", cap_fields, "alpha", "beta", "None", "[TollAB / TollBA]", "None", "Length", "None"}
			Opts.Global.[Cost Function File] = "bpr.vdf"
			Opts.Global.[VDF Defaults] = {, , 0.15, 4, }
			Opts.Field.[VDF Fld Names] = {"[TTfreeAB / TTfreeBA]", cap_fields, "alpha", "beta", "None"}
     	Opts.Global.[Number of Classes] = 6
	Opts.Global.[Load Method] = "UE"
	Opts.Global.[Loading Multiplier] = 1
	Opts.Global.Convergence = 0.01
	Opts.Global.[Time Minimum] = 0.01
     	Opts.Global.[Class PCEs] = {1, 1, 1, 1, 1.5, 2.5}
     	Opts.Global.[Class VOIs] = {1, 1, 1, 1, 1, 1}
//     	Opts.Global.[Cost Function File] = "gc_mrm.vdf"
//     	Opts.Global.[VDF Defaults] = {, , 0.15, 4, 0, distweight, timeweight,,0}
    	Opts.Global.Iterations = 50
	Opts.Global.[Critical Queries] = {arguments[14]}

    	Opts.Global.[Critical Set Names] = {"Crit_link"}
//	showmessage("got here")
        Opts.Flag.[Do Critical] = 0
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
//exclude link sets for 6 vol classes
// 1 = sov - exclude from hov2+ and hov3+  (funcl 22,24,82 & 23,25,83=sovexclude)
// 2 = pool2 - exclude from hov3+ (funcl 23,25,83=pool2exclude)
// 3 = pool3 - no exclusion
// 4 = COM - exclude from all hov (sovexclude)
// 5 = MTK - exclude from all hov (sovexclude)
// 6 = HTK - exclude from all hov (sovexclude)

//showmessage(od_matrix+" "+cap_field+" "+output_bin+" "+netview+" "+Dir+" "+Location[1]+Location[2])
     	Opts = null
     	Opts.Input.Database = Dir + "\\"+netview+".DBD"
     	Opts.Input.Network = Dir + "\\net_highway.net"
     	Opts.Input.[OD Matrix Currency] = {od_matrix, "SOV", "Rows", "Columns"}
     	Opts.Input.[Exclusion Link Sets] = 
{{Dir + "\\"+netview+".DBD|"+netview, netview, "sovexclude", "Select * where funcl = 22 or funcl = 23 or funcl = 24 or funcl = 25 or funcl = 82 or funcl = 83"}, {Dir + "\\"+netview+".DBD|"+netview, netview, "pool2exclude", "Select * where funcl = 23 or funcl = 25 or funcl = 83"}, , {Dir + "\\"+netview+".DBD|"+netview, netview, "sovexclude"}, {Dir + "\\"+netview+".DBD|"+netview, netview, "sovexclude"}, {Dir + "\\"+netview+".DBD|"+netview, netview, "sovexclude"}}
     	Opts.Field.[Vehicle Classes] = {1, 2, 3, 4, 5, 6}
	Opts.Field.[Fixed Toll Fields] = {"[TollAB / TollBA]", "[TollAB / TollBA]", "[TollAB / TollBA]", "[TollAB / TollBA]", "[TollAB / TollBA]", "[TollAB / TollBA]"}
	Opts.Field.[PCE Fields] = {"None", "None", "None", "None", "None", "None"}
//	Opts.Field.[VDF Fld Names] = {"[TTfreeAB / TTfreeBA]", cap_fields, "alpha", "beta", "None", "[TollAB / TollBA]", "None", "Length", "None"}
			Opts.Global.[Cost Function File] = "bpr.vdf"
			Opts.Global.[VDF Defaults] = {, , 0.15, 4, }
			Opts.Field.[VDF Fld Names] = {"[TTfreeAB / TTfreeBA]", cap_fields, "alpha", "beta", "None"}
     	Opts.Global.[Number of Classes] = 6
	Opts.Global.[Load Method] = "UE"
	Opts.Global.[Loading Multiplier] = 1
	Opts.Global.Convergence = 0.01
	Opts.Global.[Time Minimum] = 0.01
     	Opts.Global.[Class PCEs] = {1, 1, 1, 1, 1.5, 2.5}
     	Opts.Global.[Class VOIs] = {1, 1, 1, 1, 1, 1}
//     	Opts.Global.[Cost Function File] = "gc_mrm.vdf"
  //   	Opts.Global.[VDF Defaults] = {, , 0.15, 4, 0, distweight, timeweight,,0}
     	Opts.Global.Iterations = 50
	Opts.Global.[Critical Queries] = {"arguments[12]"}
//showmessage("got here2")
    	Opts.Global.[Critical Set Names] = {"Crit_link"}
//showmessage("got here3")
     	Opts.Flag.[Do Critical] = 0
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

endMacro


macro "tot_assn_sellink" (pkhrfac, minspfac, Dir, netview, AssnSubDir, assntype)

//revised August 2013 using mobile6.rsc as form - thanks Jhun @ KHA
//assntype - "select_link"
// McLelland 

//	goto skiparound

//   	RunMacro("TCB Init")

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

//	AMPMMINTFields = AMPMMIFields + NTFields 
//	ExportView(joinnt+"|", "FFB", AMPMMINTFields,)

//	CloseView(joinnt)

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


