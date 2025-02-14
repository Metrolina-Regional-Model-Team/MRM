Macro "Tour_TripAccumulator" (Args)

// 1/17, mk: changed from .dbf to .bin

	// on error goto badquit
	// LogFile = Args.[Log File].value
	// ReportFile = Args.[Report File].value
	// SetLogFileName(LogFile)
	// SetReportFileName(ReportFile)
	
	sedata_file = Args.[LandUse file]
	Dir = Args.[Run Directory]
	theyear = Args.[Run Year]
//	net_file = Args.[Hwy Name].value
	msg = null
	datentime = GetDateandTime()
	AppendToLogFile(1, "Tour Trip Accumulator: " + datentime)
	RunMacro("TCB Init")

	RunMacro("G30 File Close All") 

	DirArray  = Dir + "\\TG"
 	DirOutDC  = Dir + "\\TD"
 	DirOutTripTab  = Dir + "\\TripTables"
 	
 	yr_str = Right(theyear,2)
	yr = s2i(yr_str)

  CreateProgressBar("Starting Trip Accumulator", "TRUE")

	autofree = OpenMatrix(Dir + "\\Skims\\TThwy_free.mtx", "False")			//open as memory-based
	autofreecur = CreateMatrixCurrency(autofree, "TotalTT", "Rows", "Columns", )
	CopyMatrixStructure({autofreecur}, {{"File Name", DirOutTripTab + "\\HBO_OFFPEAK_TRIPS.mtx"},{"Label", "hbo_offpeak_person"},{"Type", "Short"},{"File Based", "No"},{"Tables", {"INCOME1", "INCOME2","INCOME3", "INCOME4"}},{"Operation", "Union"}})
	CopyMatrixStructure({autofreecur}, {{"File Name", DirOutTripTab + "\\HBO_PEAK_TRIPS.mtx"},{"Label", "hbo_peak_person"},{"Type", "Short"},{"File Based", "No"},{"Tables", {"INCOME1", "INCOME2","INCOME3", "INCOME4"}},{"Operation", "Union"}})
	CopyMatrixStructure({autofreecur}, {{"File Name", DirOutTripTab + "\\HBU_OFFPEAK_TRIPS.mtx"},{"Label", "hbu_offpeak_person"},{"Type", "Short"},{"File Based", "No"},{"Tables", {"HBU_OFFPK"}},{"Operation", "Union"}})
	CopyMatrixStructure({autofreecur}, {{"File Name", DirOutTripTab + "\\HBU_PEAK_TRIPS.mtx"},{"Label", "hbu_peak_person"},{"Type", "Short"},{"File Based", "No"},{"Tables", {"HBU_PEAK"}},{"Operation", "Union"}})
	CopyMatrixStructure({autofreecur}, {{"File Name", DirOutTripTab + "\\HBW_OFFPEAK_TRIPS.mtx"},{"Label", "hbw_offpeak_person"},{"Type", "Short"},{"File Based", "No"},{"Tables", {"INCOME1", "INCOME2","INCOME3", "INCOME4"}},{"Operation", "Union"}})
	CopyMatrixStructure({autofreecur}, {{"File Name", DirOutTripTab + "\\HBW_PEAK_TRIPS.mtx"},{"Label", "hbw_peak_person"},{"Type", "Short"},{"File Based", "No"},{"Tables", {"INCOME1", "INCOME2","INCOME3", "INCOME4"}},{"Operation", "Union"}})
	CopyMatrixStructure({autofreecur}, {{"File Name", DirOutTripTab + "\\NHB_OFFPEAK_TRIPS.mtx"},{"Label", "nhb_offpeak_person"},{"Type", "Short"},{"File Based", "No"},{"Tables", {"NHB_OFFPK"}},{"Operation", "Union"}})
	CopyMatrixStructure({autofreecur}, {{"File Name", DirOutTripTab + "\\NHB_PEAK_TRIPS.mtx"},{"Label", "nhb_peak_person"},{"Type", "Short"},{"File Based", "No"},{"Tables", {"NHB_PEAK"}},{"Operation", "Union"}})
	CopyMatrixStructure({autofreecur}, {{"File Name", DirOutTripTab + "\\SCH_AMPEAK_TRIPS.mtx"},{"Label", "sch_AMpeak_vehicle"},{"Type", "Short"},{"File Based", "No"},{"Tables", {"SOV", "Pool2","Pool3"}},{"Operation", "Union"}})
	CopyMatrixStructure({autofreecur}, {{"File Name", DirOutTripTab + "\\SCH_PMPEAK_TRIPS.mtx"},{"Label", "sch_PMpeak_vehicle"},{"Type", "Short"},{"File Based", "No"},{"Tables", {"SOV", "Pool2","Pool3"}},{"Operation", "Union"}})
	CopyMatrixStructure({autofreecur}, {{"File Name", DirOutTripTab + "\\SCH_MD_TRIPS.mtx"},{"Label", "sch_MD_vehicle"},{"Type", "Short"},{"File Based", "No"},{"Tables", {"SOV", "Pool2","Pool3"}},{"Operation", "Union"}})
	CopyMatrixStructure({autofreecur}, {{"File Name", DirOutTripTab + "\\SCH_NT_TRIPS.mtx"},{"Label", "sch_NT_vehicle"},{"Type", "Short"},{"File Based", "No"},{"Tables", {"SOV", "Pool2","Pool3"}},{"Operation", "Union"}})
	CopyMatrixStructure({autofreecur}, {{"File Name", DirOutTripTab + "\\IE_AMPEAK_TRIPS.mtx"},{"Label", "IE_AM_vehicle"},{"Type", "Short"},{"File Based", "No"},{"Tables", {"SOV", "Pool2","Pool3"}},{"Operation", "Union"}})
	CopyMatrixStructure({autofreecur}, {{"File Name", DirOutTripTab + "\\IE_PMPEAK_TRIPS.mtx"},{"Label", "IE_PM_vehicle"},{"Type", "Short"},{"File Based", "No"},{"Tables", {"SOV", "Pool2","Pool3"}},{"Operation", "Union"}})
	CopyMatrixStructure({autofreecur}, {{"File Name", DirOutTripTab + "\\IE_MD_TRIPS.mtx"},{"Label", "IE_MD_vehicle"},{"Type", "Short"},{"File Based", "No"},{"Tables", {"SOV", "Pool2","Pool3"}},{"Operation", "Union"}})
	CopyMatrixStructure({autofreecur}, {{"File Name", DirOutTripTab + "\\IE_NT_TRIPS.mtx"},{"Label", "IE_NT_vehicle"},{"Type", "Short"},{"File Based", "No"},{"Tables", {"SOV", "Pool2","Pool3"}},{"Operation", "Union"}})
	CopyMatrixStructure({autofreecur}, {{"File Name", DirOutTripTab + "\\EI_AMPEAK_TRIPS.mtx"},{"Label", "EI_AM_vehicle"},{"Type", "Short"},{"File Based", "No"},{"Tables", {"SOV", "Pool2","Pool3"}},{"Operation", "Union"}})
	CopyMatrixStructure({autofreecur}, {{"File Name", DirOutTripTab + "\\EI_PMPEAK_TRIPS.mtx"},{"Label", "EI_PM_vehicle"},{"Type", "Short"},{"File Based", "No"},{"Tables", {"SOV", "Pool2","Pool3"}},{"Operation", "Union"}})
	CopyMatrixStructure({autofreecur}, {{"File Name", DirOutTripTab + "\\EI_MD_TRIPS.mtx"},{"Label", "EI_MD_vehicle"},{"Type", "Short"},{"File Based", "No"},{"Tables", {"SOV", "Pool2","Pool3"}},{"Operation", "Union"}})
	CopyMatrixStructure({autofreecur}, {{"File Name", DirOutTripTab + "\\EI_NT_TRIPS.mtx"},{"Label", "EI_NT_vehicle"},{"Type", "Short"},{"File Based", "No"},{"Tables", {"SOV", "Pool2","Pool3"}},{"Operation", "Union"}})

	m_hbo_off = OpenMatrix(DirOutTripTab + "\\HBO_OFFPEAK_TRIPS.mtx", "False")			//open as memory-based
	m_hbo_pk = OpenMatrix(DirOutTripTab + "\\HBO_PEAK_TRIPS.mtx", "False")			//open as memory-based
	m_hbu_off = OpenMatrix(DirOutTripTab + "\\HBU_OFFPEAK_TRIPS.mtx", "False")			//open as memory-based
	m_hbu_pk = OpenMatrix(DirOutTripTab + "\\HBU_PEAK_TRIPS.mtx", "False")			//open as memory-based
	m_hbw_off = OpenMatrix(DirOutTripTab + "\\HBW_OFFPEAK_TRIPS.mtx", "False")			//open as memory-based
	m_hbw_pk = OpenMatrix(DirOutTripTab + "\\HBW_PEAK_TRIPS.mtx", "False")			//open as memory-based
	m_nhb_off = OpenMatrix(DirOutTripTab + "\\NHB_OFFPEAK_TRIPS.mtx", "False")			//open as memory-based
	m_nhb_pk = OpenMatrix(DirOutTripTab + "\\NHB_PEAK_TRIPS.mtx", "False")			//open as memory-based

	//Fill above matrices with zeros, otherwise Mode Choice will not work correctly
	mats = {m_hbo_off, m_hbo_off, m_hbo_off, m_hbo_off, m_hbo_pk, m_hbo_pk, m_hbo_pk, m_hbo_pk, m_hbu_off, m_hbu_pk, 
			m_hbw_off, m_hbw_off, m_hbw_off, m_hbw_off, m_hbw_pk, m_hbw_pk, m_hbw_pk, m_hbw_pk, m_nhb_off, m_nhb_pk}
	matcores = {"INCOME1", "INCOME2", "INCOME3", "INCOME4", "INCOME1", "INCOME2", "INCOME3", "INCOME4", "HBU_OFFPK", "HBU_PEAK",
			"INCOME1", "INCOME2", "INCOME3", "INCOME4", "INCOME1", "INCOME2", "INCOME3", "INCOME4", "NHB_OFFPK", "NHB_PEAK"}
	for i = 1 to mats.length do
		mc = CreateMatrixCurrency(mats[i], matcores[i], "Rows", "Columns", )
		FillMatrix(mc, , , {"Copy", 0}, )
	end

	purp = {"HBW", "HBU", "HBS", "HBO", "ATW", "SCH", "IX", "XIW", "XIN"}
	purpfile = {"dcHBW", "dcHBU", "dcHBS", "dcHBO", "dcATW", "dcSCH", "dcEXT", "dcXIW", "dcXIN"}

//************************************************************************************************************************************************************************
//Start with internal non-school trips.  School & external trips are done below; COM/MTK/HTK are done separately
//School & external trips (except XIN) do not go through mode choice.

//Relabel the segments with trip purpose codes that are consistent with the trip-based model, for input to mode choice. New TRIP purposes:
// 1 = HBW; 2 = HBU; 3 = "HBO"; 4 = "NHB"
	newpurp = {1, 2, 3, 3, 4}
	newpurp_m_off = {m_hbw_off, m_hbu_off, m_hbo_off, m_hbo_off, m_nhb_off}
	newpurp_m_pk = {m_hbw_pk, m_hbu_pk, m_hbo_pk, m_hbo_pk, m_nhb_pk}					//fix here and below {SCHOOL messed up}
	slpa_fields = {"SL_PA1", "SL_PA2", "SL_PA3", "SL_PA4", "SL_PA5", "SL_PA6", "SL_PA7"} 
	slap_fields = {"SL_AP1", "SL_AP2", "SL_AP3", "SL_AP4", "SL_AP5", "SL_AP6", "SL_AP7"} 

	for p = 1 to 5 do	//5	school & externals are done below outside of this loop
	  UpdateProgressBar("Trip Accumulator (" + purp[p] + ")", 10) 

		current_file = OpenTable(purpfile[p], "FFB", {DirOutDC + "\\" + purpfile[p] + ".bin",})
	 	strct = GetTableStructure(purpfile[p])		//Fields to store output table number (see below) 			
		for j = 1 to strct.length do
	 		strct[j] = strct[j] + {strct[j][1]}
	 	end
		strct = strct + {{"INCOME1", "Integer", 1,,,,,,,,,}}
		strct = strct + {{"INCOME2", "Integer", 1,,,,,,,,,}}
		strct = strct + {{"INCOME3", "Integer", 1,,,,,,,,,}}	//create a field with value of 1 for equivalent trip Income group, for use in UpdateMatrixFromView below
		strct = strct + {{"INCOME4", "Integer", 1,,,,,,,,,}}	
		strct = strct + {{"INCOME4", "Integer", 1,,,,,,,,,}}	
		strct = strct + {{"HBU_OFFPK", "Integer", 1,,,,,,,,,}}	
		strct = strct + {{"HBU_PEAK", "Integer", 1,,,,,,,,,}}	
		strct = strct + {{"NHB_OFFPK", "Integer", 1,,,,,,,,,}}	
		strct = strct + {{"NHB_PEAK", "Integer", 1,,,,,,,,,}}	
		ModifyTable(purpfile[p], strct)

		incset = GetDataVector(purpfile[p]+"|", "INCOME", )
		inc1 = if incset = 1 then 1 else 0
		inc2 = if incset = 2 then 1 else 0
		inc3 = if incset = 3 then 1 else 0
		inc4 = if incset = 4 then 1 else 0
		all1 = Vector(incset.length, "short", {{"Constant", 1}})
		SetDataVector(purpfile[p]+"|", "INCOME1", inc1,)
		SetDataVector(purpfile[p]+"|", "INCOME2", inc2,)
		SetDataVector(purpfile[p]+"|", "INCOME3", inc3,)
		SetDataVector(purpfile[p]+"|", "INCOME4", inc4,)
		SetDataVector(purpfile[p]+"|", "HBU_OFFPK", all1,)
		SetDataVector(purpfile[p]+"|", "HBU_PEAK", all1,)
		SetDataVector(purpfile[p]+"|", "NHB_OFFPK", all1,)
		SetDataVector(purpfile[p]+"|", "NHB_PEAK", all1,)
		inc_array = {"INCOME1", "INCOME2", "INCOME3", "INCOME4"} 
		PAstops = GetDataVector(purpfile[p]+"|", "IS_PA", )
		APstops = GetDataVector(purpfile[p]+"|", "IS_AP", )
		//Convert RT tours to individual trip records by time period, income, and old purpose.  Output tables: 
		//  1=op inc 1  2=op inc 2  3=op inc 3  4=op inc 4
		//  5=pk inc 1  6=pk inc 2  7=pk inc 3  8=pk inc 4
/*		PAtbl = 4*(current_file.PAper - 1) + current_file.incset
		APtbl = 4*(current_file.APper - 1) + current_file.incset
		SetDataVector(purpfile[p]+"|", "PAtbl", PAtbl,{{"Sort Order", {{"ID","Ascending"}}}})
		SetDataVector(purpfile[p]+"|", "APtbl", APtbl,{{"Sort Order", {{"ID","Ascending"}}}})

		fill_v = Vector(PAstops.length, "short", {{"Constant", 1}})
		SetDataVector(purpfile[p]+"|", "fill", fill_v,)
*/
		/*As we break up the tour record into trip segments, must relabel the segments with trip purpose codes that are consistent with
		  the trip-based model, for input to mode choice.  New TRIP purposes:
		  	1 = HBW  2 = HBU, 3 = HBO, 4 = NHB
		  Purpose variable for each segment for all purposes except ATW:
			  PA direction:
			    if no stops
				   orig-dest = ri.tourpurp
			    if stops
				    orig-stop = HBO
				    stop-stop = NHB
				    stop-dest = NHB
			  AP direction
			   if no stops
				   dest-orig = ri.tourpurp
			   if stops
				   dest-stop = NHB
				   stop-stop = NHB
				   stop-orig = HBO
		  Purpose variable for ATW: all segments are NHB
		*/
		maxPAstops = r2i(VectorStatistic(PAstops, "Max",))
		maxAPstops = r2i(VectorStatistic(APstops, "Max",))
		//Start in PA direction
		for i = 1 to (maxPAstops + 1) do	//(maxPAstops + 1) do
			//do offpeak trips first:  1 = off-peak; 2 = peak
			qry = "Select * where IS_PA = " + i2s(i - 1) + " and PAPER = 1"	
			SetView(purpfile[p])
			trippurp = SelectByQuery("trippurp", "Several", qry, {{"Index Limit", 0}})
			if i = 1 then do	//zero intermediate stop tours
				if p = 2 then do			//HBU matrices don't have income categories
					UpdateMatrixFromView(newpurp_m_off[p], purpfile[p]+"|trippurp", "ORIG_TAZ", "DEST_TAZ", null, {"HBU_OFFPK"}, "Add", 
						{{"Missing is zero", "Yes"}})
				end
				else if p = 5 then do			//NHB matrices don't have income categories either
					UpdateMatrixFromView(newpurp_m_off[p], purpfile[p]+"|trippurp", "ORIG_TAZ", "DEST_TAZ", null, {"NHB_OFFPK"}, "Add", 
						{{"Missing is zero", "Yes"}})
				end
				else do
					UpdateMatrixFromView(newpurp_m_off[p], purpfile[p]+"|trippurp", "ORIG_TAZ", "DEST_TAZ", null, inc_array, "Add", 
						{{"Missing is zero", "Yes"}})
				end
			end
			if i > 1 then do	//for all (non-ATW) tours with at least one stop, first trip is HBO
				if p <> 5 then do
					UpdateMatrixFromView(newpurp_m_off[3], purpfile[p]+"|trippurp", "ORIG_TAZ", "SL_PA1", null, inc_array, "Add", 
						{{"Missing is zero", "Yes"}})
				end
				else do
					UpdateMatrixFromView(newpurp_m_off[5], purpfile[p]+"|trippurp", "ORIG_TAZ", "SL_PA1", null, {"NHB_OFFPK"}, "Add", 
						{{"Missing is zero", "Yes"}})
				end	
				UpdateMatrixFromView(newpurp_m_off[5], purpfile[p]+"|trippurp", slpa_fields[i-1], "DEST_TAZ", null, {"NHB_OFFPK"}, "Add", 
					{{"Missing is zero", "Yes"}})	
				if i > 2 then do	//for all tours, all trips after first segment is NHB
					for j = 3 to i do
						UpdateMatrixFromView(newpurp_m_off[5], purpfile[p]+"|trippurp", slpa_fields[j-2], slpa_fields[j-1], null, {"NHB_OFFPK"}, "Add", 
							{{"Missing is zero", "Yes"}})	
					end
				end
			end
			//next do peak trips:  1 = off-peak; 2 = peak
			qry = "Select * where IS_PA = " + i2s(i - 1) + " and PAPER = 2"	
			SetView(purpfile[p])
			trippurp = SelectByQuery("trippurp", "Several", qry, {{"Index Limit", 0}})
			if i = 1 then do	//zero intermediate stop tours
				if p = 2 then do			//HBU matrices don't have income categories
					UpdateMatrixFromView(newpurp_m_pk[p], purpfile[p]+"|trippurp", "ORIG_TAZ", "DEST_TAZ", null, {"HBU_PEAK"}, "Add", 
						{{"Missing is zero", "Yes"}})
				end
				else if p = 5 then do			//NHB matrices don't have income categories either
					UpdateMatrixFromView(newpurp_m_pk[p], purpfile[p]+"|trippurp", "ORIG_TAZ", "DEST_TAZ", null, {"NHB_PEAK"}, "Add", 
						{{"Missing is zero", "Yes"}})
				end
				else do
					UpdateMatrixFromView(newpurp_m_pk[p], purpfile[p]+"|trippurp", "ORIG_TAZ", "DEST_TAZ", null, inc_array, "Add", 
						{{"Missing is zero", "Yes"}})
				end
			end
			if i > 1 then do	//for all (non-ATW) tours with at least one stop, first trip is HBO[2], all others are NHB[6]
				if p <> 5 then do
					UpdateMatrixFromView(newpurp_m_pk[3], purpfile[p]+"|trippurp", "ORIG_TAZ", "SL_PA1", null, inc_array, "Add", 
						{{"Missing is zero", "Yes"}})
				end
				else do
					UpdateMatrixFromView(newpurp_m_pk[5], purpfile[p]+"|trippurp", "ORIG_TAZ", "SL_PA1", null, {"NHB_PEAK"}, "Add", 
						{{"Missing is zero", "Yes"}})
				end	
				UpdateMatrixFromView(newpurp_m_pk[5], purpfile[p]+"|trippurp", slpa_fields[i-1], "DEST_TAZ", null, {"NHB_PEAK"}, "Add", 
					{{"Missing is zero", "Yes"}})	
				if i > 2 then do	//for all tours, all trips after first segment is NHB
					for j = 3 to i do
						UpdateMatrixFromView(newpurp_m_pk[5], purpfile[p]+"|trippurp", slpa_fields[j-2], slpa_fields[j-1], null, {"NHB_PEAK"}, "Add", 
							{{"Missing is zero", "Yes"}})	
					end
				end
			end
		end
		//Now do AP direction
		for i = 1 to (maxAPstops + 1) do	//(maxAPstops + 1) do
			//do offpeak trips first:  1 = off-peak; 2 = peak
			qry = "Select * where IS_AP = " + i2s(i - 1) + " and APPER = 1"	
			SetView(purpfile[p])
			trippurp = SelectByQuery("trippurp", "Several", qry, {{"Index Limit", 0}})
			if i = 1 then do	//zero intermediate stop tours
				if p = 2 then do			//HBU matrices don't have income categories
					UpdateMatrixFromView(newpurp_m_off[p], purpfile[p]+"|trippurp", "DEST_TAZ", "ORIG_TAZ", null, {"HBU_OFFPK"}, "Add", 
						{{"Missing is zero", "Yes"}})
				end
				else if p = 5 then do			//NHB matrices don't have income categories either
					UpdateMatrixFromView(newpurp_m_off[p], purpfile[p]+"|trippurp", "DEST_TAZ", "ORIG_TAZ", null, {"NHB_OFFPK"}, "Add", 
						{{"Missing is zero", "Yes"}})
				end
				else do
					UpdateMatrixFromView(newpurp_m_off[p], purpfile[p]+"|trippurp", "DEST_TAZ", "ORIG_TAZ", null, inc_array, "Add", 
						{{"Missing is zero", "Yes"}})
				end
			end
			if i > 1 then do	//for all (non-ATW) tours with at least one stop, last trip is HBO[3], others are NHB[5]
				UpdateMatrixFromView(newpurp_m_off[5], purpfile[p]+"|trippurp", "DEST_TAZ", slap_fields[i-1], null, {"NHB_OFFPK"}, "Add", 
					{{"Missing is zero", "Yes"}})	
				for j = 2 to i do
					if j = i then do
						if p <> 5 then do
							UpdateMatrixFromView(newpurp_m_off[3], purpfile[p]+"|trippurp", slap_fields[j-1], "ORIG_TAZ", null, inc_array, "Add", 
								{{"Missing is zero", "Yes"}})
						end
						else do
							UpdateMatrixFromView(newpurp_m_off[5], purpfile[p]+"|trippurp", slap_fields[j-1], "ORIG_TAZ", null, {"NHB_OFFPK"}, "Add", 
								{{"Missing is zero", "Yes"}})
						end	
					end
					else do
						UpdateMatrixFromView(newpurp_m_off[5], purpfile[p]+"|trippurp", slap_fields[j-1], slap_fields[j], null, {"NHB_OFFPK"}, "Add", 
							{{"Missing is zero", "Yes"}})	
					end
				end
			end
			//next do peak trips:  1 = off-peak; 2 = peak
			qry = "Select * where IS_AP = " + i2s(i - 1) + " and APPER = 2"	
			SetView(purpfile[p])
			trippurp = SelectByQuery("trippurp", "Several", qry, {{"Index Limit", 0}})
			if i = 1 then do	//zero intermediate stop tours
				if p = 2 then do			//HBU matrices don't have income categories
					UpdateMatrixFromView(newpurp_m_pk[p], purpfile[p]+"|trippurp", "DEST_TAZ", "ORIG_TAZ", null, {"HBU_PEAK"}, "Add", 
						{{"Missing is zero", "Yes"}})
				end
				else if p = 5 then do			//NHB matrices don't have income categories either
					UpdateMatrixFromView(newpurp_m_pk[p], purpfile[p]+"|trippurp", "DEST_TAZ", "ORIG_TAZ", null, {"NHB_PEAK"}, "Add", 
						{{"Missing is zero", "Yes"}})
				end
				else do
					UpdateMatrixFromView(newpurp_m_pk[p], purpfile[p]+"|trippurp", "DEST_TAZ", "ORIG_TAZ", null, inc_array, "Add", 
						{{"Missing is zero", "Yes"}})
				end
			end
			if i > 1 then do	//for all (non-ATW) tours with at least one stop, last trip is HBO[3], others are NHB[5]
				UpdateMatrixFromView(newpurp_m_pk[5], purpfile[p]+"|trippurp", "DEST_TAZ", slap_fields[i-1], null, {"NHB_PEAK"}, "Add", 
					{{"Missing is zero", "Yes"}})	
				for j = 2 to i do
					if j = i then do
						if p <> 5 then do
							UpdateMatrixFromView(newpurp_m_pk[3], purpfile[p]+"|trippurp", slap_fields[j-1], "ORIG_TAZ", null, inc_array, "Add", 
								{{"Missing is zero", "Yes"}})
						end
						else do
							UpdateMatrixFromView(newpurp_m_pk[5], purpfile[p]+"|trippurp", slap_fields[j-1], "ORIG_TAZ", null, {"NHB_PEAK"}, "Add", 
								{{"Missing is zero", "Yes"}})
						end	
					end
					else do
						UpdateMatrixFromView(newpurp_m_pk[5], purpfile[p]+"|trippurp", slap_fields[j-1], slap_fields[j], null, {"NHB_PEAK"}, "Add", 
							{{"Missing is zero", "Yes"}})	
					end
				end
			end

		end
	end

//************************************************************************************************************************************************************************
//			School trips			School trips			School trips			School trips			School trips

//Trip Accumulator: SCH
//This step converts SCH person tours to vehicle trips by occupancy. 
//All trips go into a tdsch matrix (new to tour model) in the /td folder.  None of these trips go into mode choice.

  UpdateProgressBar("Trip Accumulator (School tours)", 10) 

	sch_table = OpenTable("sch_table", "FFB", {DirOutDC + "\\dcSCH.bin",})
 	strct = GetTableStructure("sch_table")		// 			
	for j = 1 to strct.length do
 		strct[j] = strct[j] + {strct[j][1]}
 	end
	strct = strct + {{"PA_TOD", "Integer", 1,,,,,,,,,}}
	strct = strct + {{"AP_TOD", "Integer", 1,,,,,,,,,}}
	strct = strct + {{"PA_BUS", "Integer", 1,,,,,,,,,}}
	strct = strct + {{"AP_BUS", "Integer", 1,,,,,,,,,}}
	strct = strct + {{"SOV", "Integer", 1,,,,,,,,,}}
	strct = strct + {{"Pool2", "Integer", 1,,,,,,,,,}}
	strct = strct + {{"Pool3", "Integer", 1,,,,,,,,,}}
	ModifyTable("sch_table", strct)

	paper = GetDataVector(sch_table+"|", "PAPER", {{"Sort Order", {{"ID","Ascending"}}}}) 
	apper = GetDataVector(sch_table+"|", "APPER", {{"Sort Order", {{"ID","Ascending"}}}}) 
	PAstops = GetDataVector(sch_table+"|", "IS_PA", {{"Sort Order", {{"ID","Ascending"}}}}) 
	APstops = GetDataVector(sch_table+"|", "IS_AP", {{"Sort Order", {{"ID","Ascending"}}}}) 
	size = GetDataVector(sch_table+"|", "SIZE", {{"Sort Order", {{"ID","Ascending"}}}}) 

//tod1 choices are peak/peak (1), peak/offpeak (2), offpeak/peak (3), offpeak/offpeak (4)
	tod1 = if (paper = 2 and apper = 2) then 1 else if (paper = 2 and apper = 1) then 2 else if (paper = 1 and apper = 2) then 3 else 4

//stopcode choices are PA no-stops/AP no-stops (1), PA no-stops/AP stops (2), PA stops/AP no-stops (3), PA stops/AP stops (4)
	stopcode = if (PAstops = 0 and APstops = 0) then 1 else if (PAstops = 0 and APstops > 0) then 2 else if (PAstops > 0 and APstops = 0) then 3 else 4


/* These are the TOD2 fractions based on whether complete tour is peak/offpeak, etc., and on if there are stops in either half tour.  Mode choice (in this case School Bus, which
	gets deleted, Drive-Alone, Pool2 or Pool3+ is determined below.
		PA no stops			PA stops	
	AP no stops	AP stops	AP no stops	AP stops
AM-PM	0.9775		0.9944		0.9984		1.000
PM-PM	0.0225		0.0056		0.0016		0.000

AM-MD	0.9958		0.9958		1.000		1.000
AM-NT	0.0042		0.0042		0.000		0.000
	
MD-PM	0.6341		0.6341		0.6341		0.6341
NT-PM	0.3659		0.3659		0.3659		0.3659

MD-MD	0.1553		0.1173		0.4425		0.4425
NT-MD	0.8447		0.8827		0.5575		0.5575
*/

	_opt = { {1, 2}, {1, 1}, {3, 4}, {3, 4} }	//AM = 1, PM = 2, MD = 3, NT = 4
	ap_tod_opt = { {2, 2}, {3, 4}, {2, 2}, {3, 3} }

	tod2frac = { {0.9775, 0.9944, 0.9984, 1.000}, {0.9958, 0.9958, 1.000, 1.000}, {0.6341, 0.6341, 0.6341, 0.6341}, {0.1553, 0.1173, 0.4425, 0.4425} }

	_v = Vector(paper.length, "Short",)
	ap_tod_v = Vector(paper.length, "Short",)
	 = Vector(paper.length, "String",)
	ap_tod = Vector(paper.length, "String",)

SetRandomSeed(8080)
//Loop to determine specific time period for PA and AP half tour
	for n = 1 to paper.length do
		rand_val = RandomNumber()
		if (tod2frac[tod1[n]][stopcode[n]] > rand_val) then do
			_v[n] = pa_tod_opt[tod1[n]][1]
			ap_tod_v[n] = ap_tod_opt[tod1[n]][1]
		end
		else do
			pa_tod_v[n] = pa_tod_opt[tod1[n]][2]
			ap_tod_v[n] = ap_tod_opt[tod1[n]][2]
		end
	end

//	pa_tod = if (pa_tod_v = 1) then "AM" else if (pa_tod_v = 2) then "PM" else if (pa_tod_v = 3) then "MD" else "NT" 	
//	ap_tod = if (ap_tod_v = 1) then "AM" else if (ap_tod_v = 2) then "PM" else if (ap_tod_v = 3) then "MD" else "NT" 	

//	SetDataVector(sch_table+"|", "PA_TOD", pa_tod,{{"Sort Order", {{"ID","Ascending"}}}})
//	SetDataVector(sch_table+"|", "AP_TOD", ap_tod,{{"Sort Order", {{"ID","Ascending"}}}})
	SetDataVector(sch_table+"|", "PA_TOD", pa_tod_v,{{"Sort Order", {{"ID","Ascending"}}}})
	SetDataVector(sch_table+"|", "AP_TOD", ap_tod_v,{{"Sort Order", {{"ID","Ascending"}}}})

/*These are the percentages of bus or personal vehicle half tours for each of the TOD choices.
	PA		PA		AP		AP	
	no stops	stops		no stops	stops	
	bus	car	bus	car	bus	car	bus	car
AM-PM	0.386	0.614	0.00	1.000	0.429	0.571	0.124	0.876
PM-PM	0.00	1.000	0.00	1.000	0.00	1.000	0.00	1.000
AM-MD	0.412	0.588	0.00	1.000	0.574	0.426	0.200	0.800
AM-NT	0.187	0.813	0.00	1.000	0.00	1.000	0.00	1.000
MD-PM	0.00	1.000	0.00	1.000	0.285	0.715	0.00	1.000
NT-PM	0.290	0.710	0.00	1.000	0.00	1.000	0.00	1.000
MD-MD	0.122	0.878	0.00	1.000	0.350	0.650	0.00	1.000
NT-MD	0.853	0.147	0.00	1.000	0.836	0.164	0.560	0.440
*/

	pa_nostop_bus = { { , 0.386, 0.412, 0.187}, { , 0.0, , }, { , 0.000, 0.122, }, { , 0.290, 0.853, } } //1st element is AM, 2nd is PM, 3rd is MD, 4th is NT
	ap_nostop_bus = { { , 0.429, 0.574, 0.000}, { , 0.0, , }, { , 0.285, 0.350, }, { , 0.000, 0.836, } }
	ap_stops_bus =  { { , 0.124, 0.200, 0.000}, { , 0.0, , }, { , 0.000, 0.000, }, { , 0.000, 0.560, } }

	pa_bus_v = Vector(paper.length, "Short",)
	ap_bus_v = Vector(paper.length, "Short",)

//Loop to determine if half tour is a bus or personal vehicle.
	for n = 1 to paper.length do
		//start in PA direction
		rand_val = RandomNumber()
		if PAstops[n] > 0 then do
			pa_bus_v[n] = 0
		end
		else do
			pa_bus_v[n] = if (pa_nostop_bus[pa_tod_v[n]][ap_tod_v[n]] > rand_val) then 1 else 0
		end
		//now do AP direction
		rand_val = RandomNumber()
		if APstops[n] = 0 then do
			ap_bus_v[n] = if (ap_nostop_bus[pa_tod_v[n]][ap_tod_v[n]] > rand_val) then 1 else 0
		end
		else do
			ap_bus_v[n] = if (ap_stops_bus[pa_tod_v[n]][ap_tod_v[n]] > rand_val) then 1 else 0
		end
	end

	SetDataVector(sch_table+"|", "PA_BUS", pa_bus_v,{{"Sort Order", {{"ID","Ascending"}}}})
	SetDataVector(sch_table+"|", "AP_BUS", ap_bus_v,{{"Sort Order", {{"ID","Ascending"}}}})

/* These are the fractions for person occupancy based on size of household
Size	DA	Pool2	Pool3+
2	0.333	0.459	0.208
3	0.273	0.539	0.188
4	0.104	0.367	0.529
5	0.047	0.264	0.689

	vehocc
Pool2	0.093
Pool3+	0.026
*/

	per_occ_ar = { {0.333, 0.792}, {0.273, 0.812}, {0.104, 0.471}, {0.047, 0.311} }	//first element in each subarray is DA, second is DA + Pool2

	DA_v = Vector(paper.length, "Short",)
	Pool2_v = Vector(paper.length, "Short",)
	Pool3_v = Vector(paper.length, "Short",)

//Loop to determine person & vehicle occupancy
//Assumes that any student taking a bus on either half tour will not be driving a car, and therefore not a vehicle trip.
//Also assumes that only drivers in the PA direction are eligible to be drivers (and will be drivers) in the AP direction with the same vehicle occupancy.
	for n = 1 to paper.length do
		if (pa_bus_v[n] = 1 or ap_bus_v[n] = 1) then do		
			DA_v[n] = 0
			Pool2_v[n] = 0
			Pool3_v[n] = 0
		end
		else do
			rand_val = RandomNumber()
			if per_occ_ar[size[n]-1][1] > rand_val then do
				DA_v[n] = 1
				Pool2_v[n] = 0
				Pool3_v[n] = 0
			end
			else if per_occ_ar[size[n]-1][2] > rand_val then do
				DA_v[n] = 0
				Pool3_v[n] = 0
				rand_val = RandomNumber()
				Pool2_v[n] = if (0.093 > rand_val) then 1 else 0
			end
			else do
				DA_v[n] = 0
				Pool2_v[n] = 0
				rand_val = RandomNumber()
				Pool3_v[n] = if (0.026 > rand_val) then 1 else 0
			end
		end
	end

	SetDataVector(sch_table+"|", "SOV", DA_v,{{"Sort Order", {{"ID","Ascending"}}}})
	SetDataVector(sch_table+"|", "Pool2", Pool2_v,{{"Sort Order", {{"ID","Ascending"}}}})
	SetDataVector(sch_table+"|", "Pool3", Pool3_v,{{"Sort Order", {{"ID","Ascending"}}}})

	m_sch_am = OpenMatrix(DirOutTripTab + "\\SCH_AMPEAK_TRIPS.mtx", "False")			//open as memory-based
	m_sch_pm = OpenMatrix(DirOutTripTab + "\\SCH_PMPEAK_TRIPS.mtx", "False")			//open as memory-based
	m_sch_md = OpenMatrix(DirOutTripTab + "\\SCH_MD_TRIPS.mtx", "False")			//open as memory-based
	m_sch_nt = OpenMatrix(DirOutTripTab + "\\SCH_NT_TRIPS.mtx", "False")			//open as memory-based

	vehocc_ar = {"SOV", "Pool2", "Pool3"}
//	timeperiod_ar = {"AM", "PM", "MD", "NT"}
	schoolTODmat = {m_sch_am, m_sch_pm, m_sch_md, m_sch_nt}
	slpa_fields = {"SL_PA1", "SL_PA2", "SL_PA3", "SL_PA4", "SL_PA5", "SL_PA6", "SL_PA7"} 
	slap_fields = {"SL_AP1", "SL_AP2", "SL_AP3", "SL_AP4", "SL_AP5", "SL_AP6", "SL_AP7"} 
	


//Loop through the number of intermediate stops to fill in the School TOD matrices.  The matrices will be vehicle trips and will feed directly into the TOD2 OD matrices.
	maxPAstops = r2i(VectorStatistic(PAstops, "Max",))
	maxAPstops = r2i(VectorStatistic(APstops, "Max",))

//Note that each leg of the School tour gets assigned to the School TOD matrices (and not to HBO, NHB).  Also, only the drivers of vehicles are counted.  For example, kids who ride
//	to school with their parents are in a HBO tour.  Currently, these are not explicitly aligned in the model.

	//Start in PA direction
	for i = 1 to (maxPAstops + 1) do	
		//loop by the 4 time periods
		for tp = 1 to 4 do
			qry = "Select * where PA_TOD = " + i2s(tp) + " and IS_PA = " + i2s(i - 1)
			SetView(sch_table)
			vehcocc_tod = SelectByQuery("vehcocc_tod", "Several", qry, {{"Index Limit", 0}})
			if i = 1 then do	//zero intermediate stop tours
				UpdateMatrixFromView(schoolTODmat[tp], sch_table+"|vehcocc_tod", "ORIG_TAZ", "DEST_TAZ", null, vehocc_ar, "Add", 
					{{"Missing is zero", "Yes"}})
			end
			if i > 1 then do	
				UpdateMatrixFromView(schoolTODmat[tp], sch_table+"|vehcocc_tod", "ORIG_TAZ", "SL_PA1", null, vehocc_ar, "Add", 
					{{"Missing is zero", "Yes"}})
				for j = 2 to i do
					if j = i then do
						UpdateMatrixFromView(schoolTODmat[tp], sch_table+"|vehcocc_tod", slpa_fields[j-1], "DEST_TAZ", null, vehocc_ar, "Add", 
							{{"Missing is zero", "Yes"}})	
					end
					else do
						UpdateMatrixFromView(schoolTODmat[tp], sch_table+"|vehcocc_tod", slpa_fields[j-1], slpa_fields[j], null, vehocc_ar, "Add", 
							{{"Missing is zero", "Yes"}})	
					end
				end
			end
		end
	end

	//Next do AP direction
	for i = 1 to (maxAPstops + 1) do	
		//loop by the 4 time periods
		for tp = 1 to 4 do
			qry = "Select * where AP_TOD = " + i2s(tp) + " and IS_AP = " + i2s(i - 1)
			SetView(sch_table)
			vehcocc_tod = SelectByQuery("vehcocc_tod", "Several", qry, {{"Index Limit", 0}})
			if i = 1 then do	//zero intermediate stop tours
				UpdateMatrixFromView(schoolTODmat[tp], sch_table+"|vehcocc_tod", "DEST_TAZ", "ORIG_TAZ", null, vehocc_ar, "Add", 
					{{"Missing is zero", "Yes"}})
			end
			if i > 1 then do	
				UpdateMatrixFromView(schoolTODmat[tp], sch_table+"|vehcocc_tod", "DEST_TAZ", "SL_AP1", null, vehocc_ar, "Add", 
					{{"Missing is zero", "Yes"}})
				for j = 2 to i do
					if j = i then do
						UpdateMatrixFromView(schoolTODmat[tp], sch_table+"|vehcocc_tod", slap_fields[j-1], "ORIG_TAZ", null, vehocc_ar, "Add", 
							{{"Missing is zero", "Yes"}})	
					end
					else do
						UpdateMatrixFromView(schoolTODmat[tp], sch_table+"|vehcocc_tod", slap_fields[j-1], slap_fields[j], null, vehocc_ar, "Add", 
							{{"Missing is zero", "Yes"}})	
					end
				end
			end
		end
	end


//************************************************************************************************************************************************************************
//			External trips			External trips			External trips			External trips			External trips

//Trip Accumulator: IX
//This step converts I/X person tours to vehicle trips by occupancy. 
//All trips go into the AM/PM/MD/NT IE matrices in the /td folder.  None of these trips go into mode choice.

  UpdateProgressBar("Trip Accumulator (IX tours)", 10) 

	ix_table = OpenTable("ix_table", "FFB", {DirOutDC + "\\dcEXT.bin",})
 	strct = GetTableStructure("ix_table")		//Fields to store output table number (see below) 			
	for j = 1 to strct.length do
 		strct[j] = strct[j] + {strct[j][1]}
 	end
	strct = strct + {{"PA_TOD", "Integer", 1,,,,,,,,,}}
	strct = strct + {{"AP_TOD", "Integer", 1,,,,,,,,,}}
	strct = strct + {{"SOV", "Integer", 1,,,,,,,,,}}
	strct = strct + {{"Pool2", "Integer", 1,,,,,,,,,}}
	strct = strct + {{"Pool3", "Integer", 1,,,,,,,,,}}
	ModifyTable("ix_table", strct)

	paper = GetDataVector(ix_table+"|", "PAPER", {{"Sort Order", {{"ID","Ascending"}}}}) 
	apper = GetDataVector(ix_table+"|", "APPER", {{"Sort Order", {{"ID","Ascending"}}}}) 
	PAstops = GetDataVector(ix_table+"|", "IS_PA", {{"Sort Order", {{"ID","Ascending"}}}}) 
	APstops = GetDataVector(ix_table+"|", "IS_AP", {{"Sort Order", {{"ID","Ascending"}}}}) 
	purp_v = GetDataVector(ix_table+"|", "PURP", {{"Sort Order", {{"ID","Ascending"}}}}) 

	//Look up table with the cumulative probability of person tours by vehicle occupancy, from Metrolina 2012 survey: AVO=1.36 (or 0.7346 veh trip/psn trip)
	//	    % psn by occ: 53.8%, 27.9%, 18.3% (1, 2, 3+);  	3+ veh/psn ratio: 0.3125
	//First, determine the vehicle occupancy of the person tour.  Generate a random number and compare it to the probability distribution in table 'vehOcc'.
SetRandomSeed(2050)
	rand_num_v = Vector(paper.length, "float", {{"Constant", 1}})
	occ = Vector(paper.length, "short", {{"Constant", 1}})
	for n = 1 to paper.length do
		rand_num_v[n] = RandomNumber()
	end
	occ = if (rand_num_v > 0.538) then 2 else occ			//Occupancy rate--this could change!!
	occ = if (rand_num_v > 0.817) then 3 else occ

	/*Next, convert person tours to vehicle tours.  This is done by randomly selecting a subset of records for output on the vehicle file.  If OCC=1, always output
	  a vehicle record.  If OCC=2, there's a 50% chance of outputting a vehicle record.  If OCC=3, there's a 31.25% chance of outputting a vehicle record.
	  Generate another random number for this purpose.
	*/
	DA_v = Vector(paper.length, "Short", {{"Constant", 0}})
	Pool2_v = Vector(paper.length, "Short", {{"Constant", 0}})
	Pool3_v = Vector(paper.length, "Short", {{"Constant", 0}})
	for n = 1 to PAstops.length do
		if (occ[n] = 1) then do
			DA_v[n] = 1
		end
		else if (occ[n] = 2) then do
			rand_val = RandomNumber()
			Pool2_v[n] = if (0.5 > rand_val) then 1 else 0
		end
		else do
			rand_val = RandomNumber()
			Pool3_v[n] = if (0.3125 > rand_val) then 1 else 0
		end
	end

	SetDataVector(ix_table+"|", "SOV", DA_v,{{"Sort Order", {{"ID","Ascending"}}}})
	SetDataVector(ix_table+"|", "Pool2", Pool2_v,{{"Sort Order", {{"ID","Ascending"}}}})
	SetDataVector(ix_table+"|", "Pool3", Pool3_v,{{"Sort Order", {{"ID","Ascending"}}}})

/* Convert the Peak/Offpeak tours to the four TOD categories. The matrices will be vehicle trips and will feed directly into the TOD2 OD matrices.
    Since Work and Non-Work tours have very different TOD fractions, do each seperately.

IE TOD fractions (each Peak/Offpeak PA-AP group adds to 1)
	Work	Non-Work
AM-AM	0.115	0.073		|
AM-PM	0.851	0.599		|PA = 2, AP = 2
PM-AM	0.004	0.036		|
PM-PM	0.030	0.292		|
AM-MD	0.374	0.446	|
AM-NT	0.592	0.226	|PA = 2, AP = 1
PM-MD	0.013	0.218	|
PM-NT	0.021	0.110	|
MD-AM	0.054	0.082		|
MD-PM	0.402	0.676		|PA = 1, AP = 2
NT-AM	0.065	0.026		|
NT-PM	0.479	0.216		|
MD-MD	0.177	0.503	|
MD-NT	0.279	0.255	|PA = 1, AP = 1
NT-MD	0.211	0.161	|
NT-NT	0.333	0.081 */

	ixw_tod_ar = { { {0.177, 0.456, 0.667, 1.0}, {0.054, 0.456, 0.521, 1.0} }, { {0.374, 0.966, 0.979, 1.0}, {0.115, 0.966, 0.970, 1.0} } }
	ixn_tod_ar = { { {0.503, 0.758, 0.919, 1.0}, {0.082, 0.758, 0.784, 1.0} }, { {0.446, 0.672, 0.890, 1.0}, {0.073, 0.672, 0.708, 1.0} } }
	ix_todpa_ar = { { {3, 3, 4, 4}, {3, 3, 4, 4} }, { {1, 1, 2, 2}, {1, 1, 2, 2} } }	//AM=1, PM=2, MD=3,NT=4
	ix_todap_ar = { { {3, 4, 3, 4}, {1, 2, 1, 2} }, { {3, 4, 3, 4}, {1, 2, 1, 2} } }	

	pa_tod_v = Vector(paper.length, "Short",)
	ap_tod_v = Vector(paper.length, "Short",)

	for n = 1 to paper.length do
		for i = 1 to 2 do
			for j = 1 to 2 do
				if (paper[n] = i and apper[n] = j) then do
					for k = 1 to 4 do
						rand_val = RandomNumber()
						if (purp_v[n] = "HBW") then do
							if (ixw_tod_ar[i][j][k] > rand_val) then do
								pa_tod_v[n] = ix_todpa_ar[i][j][k]
								ap_tod_v[n] = ix_todap_ar[i][j][k]
								goto skiptonextrecord	
							end
						end
						else do
							if (ixn_tod_ar[i][j][k] > rand_val) then do
								pa_tod_v[n] = ix_todpa_ar[i][j][k]
								ap_tod_v[n] = ix_todap_ar[i][j][k]
								goto skiptonextrecord	
							end
						end
					end
				end
			end
		end
		skiptonextrecord:
	end

	SetDataVector(ix_table+"|", "PA_TOD", pa_tod_v,{{"Sort Order", {{"ID","Ascending"}}}})
	SetDataVector(ix_table+"|", "AP_TOD", ap_tod_v,{{"Sort Order", {{"ID","Ascending"}}}})

	m_ix_am = OpenMatrix(DirOutTripTab + "\\IE_AMPEAK_TRIPS.mtx", "False")			//open as memory-based
	m_ix_pm = OpenMatrix(DirOutTripTab + "\\IE_PMPEAK_TRIPS.mtx", "False")			//open as memory-based
	m_ix_md = OpenMatrix(DirOutTripTab + "\\IE_MD_TRIPS.mtx", "False")			//open as memory-based
	m_ix_nt = OpenMatrix(DirOutTripTab + "\\IE_NT_TRIPS.mtx", "False")			//open as memory-based

	vehocc_ar = {"SOV", "Pool2", "Pool3"}
	ixTODmat = {m_ix_am, m_ix_pm, m_ix_md, m_ix_nt}
	slpa_fields = {"SL_PA1", "SL_PA2", "SL_PA3", "SL_PA4", "SL_PA5", "SL_PA6", "SL_PA7"} 
	slap_fields = {"SL_AP1", "SL_AP2", "SL_AP3", "SL_AP4", "SL_AP5", "SL_AP6", "SL_AP7"} 

//Loop through the number of intermediate stops to fill in the IX TOD matrices.  The matrices will be vehicle trips and will feed directly into the TOD2 OD matrices.
	maxPAstops = r2i(VectorStatistic(PAstops, "Max",))
	maxAPstops = r2i(VectorStatistic(APstops, "Max",))

	//Start in PA direction
	for i = 1 to (maxPAstops + 1) do	
		//loop by the 4 time periods
		for tp = 1 to 4 do
			qry = "Select * where PA_TOD = " + i2s(tp) + " and IS_PA = " + i2s(i - 1)
			SetView(ix_table)
			vehcocc_tod = SelectByQuery("vehcocc_tod", "Several", qry, {{"Index Limit", 0}})

			if i = 1 then do	//zero intermediate IX tours
				UpdateMatrixFromView(ixTODmat[tp], ix_table+"|vehcocc_tod", "ORIG_TAZ", "DEST_TAZ", null, vehocc_ar, "Add", 
					{{"Missing is zero", "Yes"}})
			end
			if i > 1 then do	
				UpdateMatrixFromView(ixTODmat[tp], ix_table+"|vehcocc_tod", "ORIG_TAZ", "SL_PA1", null, vehocc_ar, "Add", 
					{{"Missing is zero", "Yes"}})
				for j = 2 to i do
					if j = i then do
						UpdateMatrixFromView(ixTODmat[tp], ix_table+"|vehcocc_tod", slpa_fields[j-1], "DEST_TAZ", null, vehocc_ar, "Add", 
							{{"Missing is zero", "Yes"}})	
					end
					else do
						UpdateMatrixFromView(ixTODmat[tp], ix_table+"|vehcocc_tod", slpa_fields[j-1], slpa_fields[j], null, vehocc_ar, "Add", 
							{{"Missing is zero", "Yes"}})	
					end
				end
			end
		end
	end

	//Next do AP direction
	for i = 1 to (maxAPstops + 1) do	
		//loop by the 4 time periods
		for tp = 1 to 4 do
			qry = "Select * where AP_TOD = " + i2s(tp) + " and IS_AP = " + i2s(i - 1)
			SetView(ix_table)
			vehcocc_tod = SelectByQuery("vehcocc_tod", "Several", qry, {{"Index Limit", 0}})
			if i = 1 then do	//zero intermediate stop tours
				UpdateMatrixFromView(ixTODmat[tp], ix_table+"|vehcocc_tod", "DEST_TAZ", "ORIG_TAZ", null, vehocc_ar, "Add", 
					{{"Missing is zero", "Yes"}})
			end
			if i > 1 then do	
				UpdateMatrixFromView(ixTODmat[tp], ix_table+"|vehcocc_tod", "DEST_TAZ", "SL_AP1", null, vehocc_ar, "Add", 
					{{"Missing is zero", "Yes"}})
				for j = 2 to i do
					if j = i then do
						UpdateMatrixFromView(ixTODmat[tp], ix_table+"|vehcocc_tod", slap_fields[j-1], "ORIG_TAZ", null, vehocc_ar, "Add", 
							{{"Missing is zero", "Yes"}})	
					end
					else do
						UpdateMatrixFromView(ixTODmat[tp], ix_table+"|vehcocc_tod", slap_fields[j-1], slap_fields[j], null, vehocc_ar, "Add", 
							{{"Missing is zero", "Yes"}})	
					end
				end
			end
		end
	end

//****************************************************************
//Trip Accumulator: XIW
//This step converts X/I Work vehicle tours to vehicle trips by occupancy. 
//All trips go into the AM/PM/MD/NT XIW matrices in the /td folder.  None of these trips go into mode choice.

  UpdateProgressBar("Trip Accumulator (XI-WORK tours)", 10) 

	xiw_table = OpenTable("xiw_table", "FFB", {DirOutDC + "\\dcXIW.bin",})
 	strct = GetTableStructure("xiw_table")		//Fields to store output table number (see below) 			
	for j = 1 to strct.length do
 		strct[j] = strct[j] + {strct[j][1]}
 	end
	strct = strct + {{"PA_TOD", "Integer", 1,,,,,,,,,}}
	strct = strct + {{"AP_TOD", "Integer", 1,,,,,,,,,}}
	strct = strct + {{"SOV", "Integer", 1,,,,,,,,,}}
	strct = strct + {{"Pool2", "Integer", 1,,,,,,,,,}}
	strct = strct + {{"Pool3", "Integer", 1,,,,,,,,,}}
	ModifyTable("xiw_table", strct)

	paper = GetDataVector(xiw_table+"|", "PAPER", {{"Sort Order", {{"ID","Ascending"}}}}) 
	apper = GetDataVector(xiw_table+"|", "APPER", {{"Sort Order", {{"ID","Ascending"}}}}) 
	PAstops = GetDataVector(xiw_table+"|", "IS_PA", {{"Sort Order", {{"ID","Ascending"}}}}) 
	APstops = GetDataVector(xiw_table+"|", "IS_AP", {{"Sort Order", {{"ID","Ascending"}}}}) 

	//Look up table with the cumulative probability of person tours by vehicle occupancy, from 2014 external survey: AVO=1.179 (or 0.8480 veh trip/psn trip)
	//	    % psn by occ: 85.12%, 12.48%, 2.37% (1, 2, 3+);  
	//First, determine the vehicle occupancy of the person tour.  Generate a random number and compare it to the probability distribution in table 'vehOcc'.
SetRandomSeed(78965)
	rand_num_v = Vector(paper.length, "float", {{"Constant", 1}})
	occ = Vector(paper.length, "short", {{"Constant", 1}})
	for n = 1 to paper.length do
		rand_num_v[n] = RandomNumber()
	end
	occ = if (rand_num_v > 0.8512) then 2 else occ			//Occupancy rate--this could change!!
	occ = if (rand_num_v > 0.9760) then 3 else occ

	/*Next, convert person tours to vehicle tours.  This is done by randomly selecting a subset of records for output on the vehicle file.  If OCC=1, always output
	  a vehicle record.  If OCC=2, there's a 50% chance of outputting a vehicle record.  If OCC=3, there's a 31.25% chance of outputting a vehicle record.
	  Generate another random number for this purpose.
	*/
	DA_v = Vector(paper.length, "Short", {{"Constant", 0}})
	Pool2_v = Vector(paper.length, "Short", {{"Constant", 0}})
	Pool3_v = Vector(paper.length, "Short", {{"Constant", 0}})
	for n = 1 to PAstops.length do
		if (occ[n] = 1) then do
			DA_v[n] = 1
		end
		else if (occ[n] = 2) then do
			Pool2_v[n] = 1
		end
		else do
			Pool3_v[n] = 1
		end
	end

	SetDataVector(xiw_table+"|", "SOV", DA_v,{{"Sort Order", {{"ID","Ascending"}}}})
	SetDataVector(xiw_table+"|", "Pool2", Pool2_v,{{"Sort Order", {{"ID","Ascending"}}}})
	SetDataVector(xiw_table+"|", "Pool3", Pool3_v,{{"Sort Order", {{"ID","Ascending"}}}})

/* Convert the Peak/Offpeak tours to the four TOD categories. The matrices will be vehicle trips and will feed directly into the TOD2 OD matrices.

IE TOD fractions (each Peak/Offpeak PA-AP group adds to 1)
	Work
AM-AM	0.101		|
AM-PM	0.749		|PA = 2, AP = 2
PM-AM	0.018		|
PM-PM	0.132		|
AM-MD	0.330	|
AM-NT	0.520	|PA = 2, AP = 1
PM-MD	0.058	|
PM-NT	0.092	|
MD-AM	0.067		|
MD-PM	0.496		|PA = 1, AP = 2
NT-AM	0.052		|
NT-PM	0.385		|
MD-MD	0.218	|
MD-NT	0.345	|PA = 1, AP = 1
NT-MD	0.169	|
NT-NT	0.267	|*/

	xiw_tod_ar = { { {0.218, 0.563, 0.732, 1.0}, {0.067, 0.563, 0.615, 1.0} }, { {0.330, 0.850, 0.908, 1.0}, {0.101, 0.850, 0.868, 1.0} } }
	xi_todpa_ar = { { {3, 3, 4, 4}, {3, 3, 4, 4} }, { {1, 1, 2, 2}, {1, 1, 2, 2} } }	//AM=1, PM=2, MD=3,NT=4
	xi_todap_ar = { { {3, 4, 3, 4}, {1, 2, 1, 2} }, { {3, 4, 3, 4}, {1, 2, 1, 2} } }	

	pa_tod_v = Vector(paper.length, "Short",)
	ap_tod_v = Vector(paper.length, "Short",)

	for n = 1 to paper.length do
		for i = 1 to 2 do
			for j = 1 to 2 do
				if (paper[n] = i and apper[n] = j) then do
					for k = 1 to 4 do
						rand_val = RandomNumber()
						if (xiw_tod_ar[i][j][k] > rand_val) then do
							pa_tod_v[n] = xi_todpa_ar[i][j][k]
							ap_tod_v[n] = xi_todap_ar[i][j][k]
							goto skiptonextxirecord	
						end
					end
				end
			end
		end
		skiptonextxirecord:
	end

	SetDataVector(xiw_table+"|", "PA_TOD", pa_tod_v,{{"Sort Order", {{"ID","Ascending"}}}})
	SetDataVector(xiw_table+"|", "AP_TOD", ap_tod_v,{{"Sort Order", {{"ID","Ascending"}}}})

	m_xi_am = OpenMatrix(DirOutTripTab + "\\EI_AMPEAK_TRIPS.mtx", "False")			//open as memory-based
	m_xi_pm = OpenMatrix(DirOutTripTab + "\\EI_PMPEAK_TRIPS.mtx", "False")			//open as memory-based
	m_xi_md = OpenMatrix(DirOutTripTab + "\\EI_MD_TRIPS.mtx", "False")			//open as memory-based
	m_xi_nt = OpenMatrix(DirOutTripTab + "\\EI_NT_TRIPS.mtx", "False")			//open as memory-based

	vehocc_ar = {"SOV", "Pool2", "Pool3"}
	xiTODmat = {m_xi_am, m_xi_pm, m_xi_md, m_xi_nt}
	slpa_fields = {"SL_PA1", "SL_PA2", "SL_PA3", "SL_PA4", "SL_PA5", "SL_PA6", "SL_PA7"} 
	slap_fields = {"SL_AP1", "SL_AP2", "SL_AP3", "SL_AP4", "SL_AP5", "SL_AP6", "SL_AP7"} 

//Loop through the number of intermediate stops to fill in the XI TOD matrices.  The matrices will be vehicle trips and will feed directly into the TOD2 OD matrices.
	maxPAstops = r2i(VectorStatistic(PAstops, "Max",))
	maxAPstops = r2i(VectorStatistic(APstops, "Max",))

	//Start in PA direction
	for i = 1 to (maxPAstops + 1) do	
		//loop by the 4 time periods
		for tp = 1 to 4 do
			qry = "Select * where PA_TOD = " + i2s(tp) + " and IS_PA = " + i2s(i - 1)
			SetView(xiw_table)
			vehcocc_tod = SelectByQuery("vehcocc_tod", "Several", qry, {{"Index Limit", 0}})

			if i = 1 then do	//zero intermediate XIW tours
				UpdateMatrixFromView(xiTODmat[tp], xiw_table+"|vehcocc_tod", "ORIG_TAZ", "DEST_TAZ", null, vehocc_ar, "Add", 
					{{"Missing is zero", "Yes"}})
			end
			if i > 1 then do	
				UpdateMatrixFromView(xiTODmat[tp], xiw_table+"|vehcocc_tod", "ORIG_TAZ", "SL_PA1", null, vehocc_ar, "Add", 
					{{"Missing is zero", "Yes"}})
				for j = 2 to i do
					if j = i then do
						UpdateMatrixFromView(xiTODmat[tp], xiw_table+"|vehcocc_tod", slpa_fields[j-1], "DEST_TAZ", null, vehocc_ar, "Add", 
							{{"Missing is zero", "Yes"}})	
					end
					else do
						UpdateMatrixFromView(xiTODmat[tp], xiw_table+"|vehcocc_tod", slpa_fields[j-1], slpa_fields[j], null, vehocc_ar, "Add", 
							{{"Missing is zero", "Yes"}})	
					end
				end
			end
		end
	end

	//Next do AP direction
	for i = 1 to (maxAPstops + 1) do	
		//loop by the 4 time periods
		for tp = 1 to 4 do
			qry = "Select * where AP_TOD = " + i2s(tp) + " and IS_AP = " + i2s(i - 1)
			SetView(xiw_table)
			vehcocc_tod = SelectByQuery("vehcocc_tod", "Several", qry, {{"Index Limit", 0}})
			if i = 1 then do	//zero intermediate stop tours
				UpdateMatrixFromView(xiTODmat[tp], xiw_table+"|vehcocc_tod", "DEST_TAZ", "ORIG_TAZ", null, vehocc_ar, "Add", 
					{{"Missing is zero", "Yes"}})
			end
			if i > 1 then do	
				UpdateMatrixFromView(xiTODmat[tp], xiw_table+"|vehcocc_tod", "DEST_TAZ", "SL_AP1", null, vehocc_ar, "Add", 
					{{"Missing is zero", "Yes"}})
				for j = 2 to i do
					if j = i then do
						UpdateMatrixFromView(xiTODmat[tp], xiw_table+"|vehcocc_tod", slap_fields[j-1], "ORIG_TAZ", null, vehocc_ar, "Add", 
							{{"Missing is zero", "Yes"}})	
					end
					else do
						UpdateMatrixFromView(xiTODmat[tp], xiw_table+"|vehcocc_tod", slap_fields[j-1], slap_fields[j], null, vehocc_ar, "Add", 
							{{"Missing is zero", "Yes"}})	
					end
				end
			end
		end
	end

//****************************************************************
//Trip Accumulator: XIN
//original version per Bill Allen:
/*This step converts X/I non-work vehicle tours to vehicle and person trips by occupancy.  The external legs of each tour are considered vehicle
  trips that bypass mode choice and go into the AM/PM/MD/NT XI matrices in the /td folder.  The internal legs are multiplied by the vehicle 
  occupancy and output as NHB person trips, so that they can go through mode choice.
*/
//changed 3/30/16 after conversation with Joe McLelland, in which it was decided that losing a small number of NHB trips eligible for transit was more acceptable than having
//the inner portion of the tour not circling back to pick up the automobile if the inner tour was taken by transit.

  UpdateProgressBar("Trip Accumulator (XI-Non-Work tours)", 10) 

	xin_table = OpenTable("xin_table", "FFB", {DirOutDC + "\\dcXIN.bin",})
 	strct = GetTableStructure("xin_table")		//Fields to store output table number (see below) 			
	for j = 1 to strct.length do
 		strct[j] = strct[j] + {strct[j][1]}
 	end
	strct = strct + {{"PA_TOD", "Integer", 1,,,,,,,,,}}
	strct = strct + {{"AP_TOD", "Integer", 1,,,,,,,,,}}
	strct = strct + {{"SOV", "Integer", 1,,,,,,,,,}}
	strct = strct + {{"Pool2", "Integer", 1,,,,,,,,,}}
	strct = strct + {{"Pool3", "Integer", 1,,,,,,,,,}}
	ModifyTable("xin_table", strct)

	paper = GetDataVector(xin_table+"|", "PAPER", {{"Sort Order", {{"ID","Ascending"}}}}) 
	apper = GetDataVector(xin_table+"|", "APPER", {{"Sort Order", {{"ID","Ascending"}}}}) 
	PAstops = GetDataVector(xin_table+"|", "IS_PA", {{"Sort Order", {{"ID","Ascending"}}}}) 
	APstops = GetDataVector(xin_table+"|", "IS_AP", {{"Sort Order", {{"ID","Ascending"}}}}) 

	//Look up table with the cumulative probability of person tours by vehicle occupancy, from 2014 external survey: AVO=1.519 (or 0.6581 veh trip/psn trip)
	//	    % psn by occ: 60.18%, 31.09%, 8.73% (1, 2, 3+);  
	//First, determine the vehicle occupancy of the person tour.  Generate a random number and compare it to the probability distribution in table 'vehOcc'.
SetRandomSeed(49561)
	rand_num_v = Vector(paper.length, "float", {{"Constant", 1}})
	occ = Vector(paper.length, "short", {{"Constant", 1}})
	for n = 1 to paper.length do
		rand_num_v[n] = RandomNumber()
	end
	occ = if (rand_num_v > 0.6018) then 2 else occ			//Occupancy rate--this could change!!
	occ = if (rand_num_v > 0.9127) then 3 else occ

	/*Next, convert person tours to vehicle tours.  This is done by randomly selecting a subset of records for output on the vehicle file.  If OCC=1, always output
	  a vehicle record.  If OCC=2, there's a 50% chance of outputting a vehicle record.  If OCC=3, there's a 31.25% chance of outputting a vehicle record.
	  Generate another random number for this purpose.
	*/
	DA_v = Vector(paper.length, "Short", {{"Constant", 0}})
	Pool2_v = Vector(paper.length, "Short", {{"Constant", 0}})
	Pool3_v = Vector(paper.length, "Short", {{"Constant", 0}})
	for n = 1 to PAstops.length do
		if (occ[n] = 1) then do
			DA_v[n] = 1
		end
		else if (occ[n] = 2) then do
			Pool2_v[n] = 1
		end
		else do
			Pool3_v[n] = 1
		end
	end

	SetDataVector(xin_table+"|", "SOV", DA_v,{{"Sort Order", {{"ID","Ascending"}}}})
	SetDataVector(xin_table+"|", "Pool2", Pool2_v,{{"Sort Order", {{"ID","Ascending"}}}})
	SetDataVector(xin_table+"|", "Pool3", Pool3_v,{{"Sort Order", {{"ID","Ascending"}}}})

/* The first and last legs (the external trips), will skip mode choice and go directly into the TOD2 OD matrices. So, we nned to convert the Peak/Offpeak tours 
   to the four TOD categories. The other trips will not use these TOD categories, and instead be added to the NHB Peak/Offpeak matrices and go through MC.

IE TOD fractions (each Peak/Offpeak PA-AP group adds to 1)

	Non-Work	
AM-AM	0.057		|
AM-PM	0.473		|PA = 2, AP = 2
PM-AM	0.050		|
PM-PM	0.420		|
AM-MD	0.352	|
AM-NT	0.178	|PA = 2, AP = 1
PM-MD	0.312	|
PM-NT	0.158	|
MD-AM	0.079		|
MD-PM	0.659		|PA = 1, AP = 2
NT-AM	0.028		|
NT-PM	0.233		|
MD-MD	0.490	|
MD-NT	0.249	|PA = 1, AP = 1
NT-MD	0.173	|
NT-NT	0.088	|*/


	xin_tod_ar = { { {0.490, 0.739, 0.912, 1.0}, {0.079, 0.738, 0.766, 1.0} }, { {0.352, 0.530, 0.842, 1.0}, {0.057, 0.530, 0.580, 1.0} } }
	xi_todpa_ar = { { {3, 3, 4, 4}, {3, 3, 4, 4} }, { {1, 1, 2, 2}, {1, 1, 2, 2} } }	//AM=1, PM=2, MD=3,NT=4
	xi_todap_ar = { { {3, 4, 3, 4}, {1, 2, 1, 2} }, { {3, 4, 3, 4}, {1, 2, 1, 2} } }	

	pa_tod_v = Vector(paper.length, "Short",)
	ap_tod_v = Vector(paper.length, "Short",)

	for n = 1 to paper.length do
		for i = 1 to 2 do
			for j = 1 to 2 do
				if (paper[n] = i and apper[n] = j) then do
					for k = 1 to 4 do
						rand_val = RandomNumber()
						if (xin_tod_ar[i][j][k] > rand_val) then do
							pa_tod_v[n] = xi_todpa_ar[i][j][k]
							ap_tod_v[n] = xi_todap_ar[i][j][k]
							goto skiptonextxinrecord	
						end
					end
				end
			end
		end
		skiptonextxinrecord:
	end


	SetDataVector(xin_table+"|", "PA_TOD", pa_tod_v,{{"Sort Order", {{"ID","Ascending"}}}})
	SetDataVector(xin_table+"|", "AP_TOD", ap_tod_v,{{"Sort Order", {{"ID","Ascending"}}}})

	m_xi_am = OpenMatrix(DirOutTripTab + "\\EI_AMPEAK_TRIPS.mtx", "False")			//open as memory-based
	m_xi_pm = OpenMatrix(DirOutTripTab + "\\EI_PMPEAK_TRIPS.mtx", "False")			//open as memory-based
	m_xi_md = OpenMatrix(DirOutTripTab + "\\EI_MD_TRIPS.mtx", "False")			//open as memory-based
	m_xi_nt = OpenMatrix(DirOutTripTab + "\\EI_NT_TRIPS.mtx", "False")			//open as memory-based

	vehocc_ar = {"SOV", "Pool2", "Pool3"}
	xiTODmat = {m_xi_am, m_xi_pm, m_xi_md, m_xi_nt}
	slpa_fields = {"SL_PA1", "SL_PA2", "SL_PA3", "SL_PA4", "SL_PA5", "SL_PA6", "SL_PA7"} 
	slap_fields = {"SL_AP1", "SL_AP2", "SL_AP3", "SL_AP4", "SL_AP5", "SL_AP6", "SL_AP7"} 

//Loop through the number of intermediate stops to fill in the XI TOD matrices.  The matrices will be vehicle trips and will feed directly into the TOD2 OD matrices.
	maxPAstops = r2i(VectorStatistic(PAstops, "Max",))
	maxAPstops = r2i(VectorStatistic(APstops, "Max",))

	//Start in PA direction
	for i = 1 to (maxPAstops + 1) do	
		//loop by the 4 time periods
		for tp = 1 to 4 do
			qry = "Select * where PA_TOD = " + i2s(tp) + " and IS_PA = " + i2s(i - 1)
			SetView(xin_table)
			vehcocc_tod = SelectByQuery("vehcocc_tod", "Several", qry, {{"Index Limit", 0}})

			if i = 1 then do	//zero intermediate XIN tours
				UpdateMatrixFromView(xiTODmat[tp], xin_table+"|vehcocc_tod", "ORIG_TAZ", "DEST_TAZ", null, vehocc_ar, "Add", 
				{{"Missing is zero", "Yes"}})
			end
			if i > 1 then do	
				UpdateMatrixFromView(xiTODmat[tp], xin_table+"|vehcocc_tod", "ORIG_TAZ", "SL_PA1", null, vehocc_ar, "Add", 
					{{"Missing is zero", "Yes"}})
				for j = 2 to i do
					if j = i then do
						UpdateMatrixFromView(xiTODmat[tp], xin_table+"|vehcocc_tod", slpa_fields[j-1], "DEST_TAZ", null, vehocc_ar, "Add", 
							{{"Missing is zero", "Yes"}})	
					end
					else do
						UpdateMatrixFromView(xiTODmat[tp], xin_table+"|vehcocc_tod", slpa_fields[j-1], slpa_fields[j], null, vehocc_ar, "Add", 
							{{"Missing is zero", "Yes"}})	
					end
				end
			end
		end
	end
	//Next do AP direction
	for i = 1 to (maxAPstops + 1) do	
		//loop by the 4 time periods
		for tp = 1 to 4 do
			qry = "Select * where AP_TOD = " + i2s(tp) + " and IS_AP = " + i2s(i - 1)
			SetView(xin_table)
			vehcocc_tod = SelectByQuery("vehcocc_tod", "Several", qry, {{"Index Limit", 0}})
	
			if i = 1 then do	//zero intermediate XIN tours
				UpdateMatrixFromView(xiTODmat[tp], xin_table+"|vehcocc_tod", "DEST_TAZ", "ORIG_TAZ", null, vehocc_ar, "Add", 
				{{"Missing is zero", "Yes"}})
			end
			if i > 1 then do	
				UpdateMatrixFromView(xiTODmat[tp], xin_table+"|vehcocc_tod", "DEST_TAZ", "SL_PA1", null, vehocc_ar, "Add", 
					{{"Missing is zero", "Yes"}})
				for j = 2 to i do
					if j = i then do
						UpdateMatrixFromView(xiTODmat[tp], xin_table+"|vehcocc_tod", slap_fields[j-1], "ORIG_TAZ", null, vehocc_ar, "Add", 
							{{"Missing is zero", "Yes"}})	
					end
					else do
						UpdateMatrixFromView(xiTODmat[tp], xin_table+"|vehcocc_tod", slap_fields[j-1], slap_fields[j], null, vehocc_ar, "Add", 
							{{"Missing is zero", "Yes"}})	
					end
				end
			end
		end
	end

//Must rename the HBU and NHB matrix offpeak cores (the full name was too long for the .bin field name)
	Opts = null
	Opts.Input.[Input Matrix] = DirOutTripTab + "\\HBU_OFFPEAK_TRIPS.mtx" 
	Opts.Input.[Target Core] = "HBU_OFFPK" 
	Opts.Input.[Core Name] = "HBU_OFFPEAK" 
	RunMacro("TCB Run Operation", "Rename Matrix Core", Opts) 

	Opts = null
	Opts.Input.[Input Matrix] = DirOutTripTab + "\\NHB_OFFPEAK_TRIPS.mtx" 
	Opts.Input.[Target Core] = "NHB_OFFPK" 
	Opts.Input.[Core Name] = "NHB_OFFPEAK" 
	RunMacro("TCB Run Operation", "Rename Matrix Core", Opts) 


    DestroyProgressBar()
    RunMacro("G30 File Close All")

    goto quit

	badquit:
		on error, notfound default
		RunMacro("TCB Closing", ret_value, "TRUE" )
		Throw("Tour Trip Accumulator: Error somewhere")
		AppendToLogFile(1, "Tour Trip Accumulator: Error somewhere")
		datentime = GetDateandTime()
		AppendToLogFile(1, "Tour Trip Accumulator " + datentime)

       	return({0, msg})

    quit:
		on error, notfound default
   		datentime = GetDateandTime()
		AppendToLogFile(1, "Exit Tour Trip Accumulator " + datentime)
    	return({1, msg})


endmacro
