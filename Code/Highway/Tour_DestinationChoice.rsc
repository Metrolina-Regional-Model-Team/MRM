Macro "Tour_DestinationChoice" (Args)

//Assumes that accessibility & tour frequency tables have already been created
// 8/16, model group: edited to compare total attraction to total productions; if attractions are less than productions, proportionally increase attractions to 10% more than total productions
// 8/16, mk: strengthened the constraint on external stations for IX tours.  In prior version there were a large disceprancy of IX vs. XI tours at stations.  This version caps the percentage
//		of IX trip ends at 75% of non-XX volumes (per 2012 HHTS).
// 9/16, mk: removed the Destination Choice procedure on the initial ATW step, since this will be redone once HBW-ATWs and XIW-ATWs are combined without any effect from intial DC
//1/17, mk: changed Attractions safety margin from 10% greater than productions to 1% (line 171)
// 1/17, mk: changed from .dbf to .bin
// 8/17, mk: coefficients changed
// 8/17, mk: modified choice methodology to improve speed, removed sorting probabilities, set random seeds before each purpose
// 2/18, mk: added fields for O-D (and D-O) travel times
// 2/18, mk: this version changes the coefficient for intrazonal variable based on the origin/home zone's area type (HBW, SCH, HBU, HBS, and HBO but not ATW)
// 2/22/18, mk: changes per BA's 2/21/18 email
// 2/26/18, mk: changes per BA's 2/26/18 email
// 5/2/18, mk: changes per BA's 5/1/18 email
// 5/4/18, mk: correct XIW & XIN
// 5/8/18, mk: randomally sort by Tours instead of by zones; were getting concentrated areas of long distance tours at end of each set of tours (adds a little over an hour of run time)
// 5/29/18, mk: coefficient changes per BA's 5/11/18 email
// 6/20/18, mk: changed double-contraint factor minimum from 0 to 0.01 for non-Work purposes
// 6/20/18, mk: resets School attractions by county to equal 1.03 times the county's productions
// 9/20/18, mk: fixed DO time for offpeak purposes (was recording peak times instead)
// 2/25/19, mk: change HBW coeffs to match DCapp5 per Bill's 2/25/19 email
// 3/27/19, mk: changed pEXT equations to match Bill/survey results
// 4/15/19, mk: randomized order for IX tours, set remaining_attraction minimum to zero
// 8/22/19, mk: TC8 and/or Windows 10 fix; added extra random number fields for randomizing sequence for all 6 non-Ext purposes

//Note: SCHOOL external probability for Catawba County zones (6500-6699) increased to 90%, since there are no schools in current Catawba zones

	// on error goto badquit
	// LogFile = Args.[Log File].value
	// ReportFile = Args.[Report File].value
	// SetLogFileName(LogFile)
	// SetReportFileName(ReportFile)
	
	sedata_file = Args.[LandUse file]
	Dir = Args.[Run Directory]
	theyear = Args.[Run Year]
	msg = null
	datentime = GetDateandTime()
	AppendToLogFile(1, "Tour Destination Choice: " + datentime)
	RunMacro("TCB Init")

	RunMacro("G30 File Close All") 

	DirArray  = Dir + "\\TG"
 	DirOutDC  = Dir + "\\TD"
 	
 	yr_str = Right(theyear,2)
	yr = s2i(yr_str)

  CreateProgressBar("Tour Destination Choice...Opening files", "TRUE")

//Open all needed tables, pull out vectors
	se_vw = OpenTable("SEFile", "FFB", {sedata_file,})
	hhbyincome = OpenTable("hhbyincome", "FFB", {DirArray + "\\HH_INCOME.bin",})
	distExtsta_vw = OpenTable("distextsta", "FFA", {Dir + "\\Ext\\Dist_to_Closest_ExtSta.asc",})
	distCBD_vw = OpenTable("distcbd", "FFA", {Dir + "\\LandUse\\Dist_to_CBD.asc",})
	access_peak = OpenTable("access_peak", "FFB", {DirArray + "\\ACCESS_PEAK.bin",})
	access_free = OpenTable("access_free", "FFB", {DirArray + "\\ACCESS_FREE.bin",})
	areatype = OpenTable("areatype", "FFB", {Dir + "\\landuse\\SE" + theyear + "_DENSITY.bin",})  
	arate_vw = OpenTable("arate_vw", "FFB", {DirArray + "\\ARATE_TR.bin",})
	atfacta_vw = OpenTable("atfacta_vw", "FFB", {DirArray + "\\ATFACTA_TR.bin",})
	tourfac_vw = OpenTable("tourfac_vw", "FFB", {DirArray + "\\TOURFAC.bin",})

//pay attention to order.  Attractions (for doubly-constraining) are calculated by order.
	se_vectors = GetDataVectors(se_vw+"|", {"TAZ", "HH", "POP_HHS", "LOIND", "HIIND", "RTL", "HWY", "LOSVC", "HISVC", "OFFGOV", 
						"EDUC", "STU_K8", "STU_HS", "STU_CU", "MED_INC", "AREA", "TOTEMP", "STCNTY", "SEQ", "POP"},{{"Sort Order", {{"TAZ","Ascending"}}}})
	taz = se_vectors[1]
	hh = se_vectors[2]
	pophhs = se_vectors[3]
	loind = se_vectors[4]
	hiind = se_vectors[5]
	retail = se_vectors[6]
	hwy = se_vectors[7]
	losvc = se_vectors[8]
	hisvc = se_vectors[9]
	offgov = se_vectors[10]
	educ = se_vectors[11]
	stuk8 = se_vectors[12]
	stuhs = se_vectors[13]
	stucu = se_vectors[14]
	medinc = se_vectors[15]
	area = se_vectors[16]			//area is in square miles
	totemp = se_vectors[17]
	stcnty = se_vectors[18]
	tazseq = se_vectors[19]
	pop = se_vectors[20]
	pop = max(pop, 1)
	k12enr = stuk8 + stuhs
	cbddum = if (taz = 10001 or taz = 10002 or taz = 10003 or taz = 10004 or taz = 10005 or taz = 10006 or taz = 10007 or taz = 10008 or taz = 10009 or 
			taz = 10010 or taz = 10011 or taz = 10012 or taz = 10013 or taz = 10014 or taz = 10015 or taz = 10016 or taz = 10017 or taz = 10018 or taz = 10019 or 
			taz = 10020 or taz = 10021 or taz = 10022 or taz = 10023 or taz = 10024 or taz = 10025 or taz = 10026 or taz = 10027 or taz = 10028 or taz = 10029 or
			taz = 10030 or taz = 10031 or taz = 10032 or taz = 10033 or taz = 10034 or taz = 10035 or 
			taz = 10052 or taz = 10086 or taz = 10116 or taz = 10117 or taz = 10118 or taz = 10119 or  
			taz = 10144 or taz = 10145 or taz = 10146 or taz = 10160 or taz = 10161 or taz = 10164 or taz = 10165 or taz = 10235) then 1 else 0
	ret = max(retail + hwy,1)
	nret = max(totemp - ret,1)
	retemp = retail + hwy
	dens = if (area * totemp * hh > 0) then 100 * log((1000 * totemp + 1900 * hh) / area) else 0		//density is in square miles
	empdens = totemp / (area * 640)		//employment per acre (area in sq. miles in SE file)
	retempdens = retemp / (area * 640)		//employment per acre (area in sq. miles in SE file)

	dst2extsta = GetDataVector(distExtsta_vw+"|", "Len", {{"Sort Order", {{"From","Ascending"}}}}) 
	dst2cbd = GetDataVector(distCBD_vw+"|", "Len", {{"Sort Order", {{"From","Ascending"}}}}) 
	//to get rid of external stations:
	dim dist2extsta_ar[hh.length]
	dim dist2cbd_ar[hh.length]
	for i =  1 to hh.length do		
		dist2extsta_ar[i] = dst2extsta[i]
		dist2cbd_ar[i] = dst2cbd[i]
	end
	dist2extsta = a2v(dist2extsta_ar)
	dist2cbd = a2v(dist2cbd_ar)

	accfree_vectors = GetDataVectors(access_free+"|", {"EMPCMP15", "EMPT2CMP", "HHCmp15"},{{"Sort Order", {{"TAZ","Ascending"}}}}) 
	accE15cfr = accfree_vectors[1]
	accEt2cfr = accfree_vectors[2]
	accH15cfr = accfree_vectors[3]


/*	accpeak_vectors = GetDataVectors(access_peak+"|", {"EMPCMP15", "HHCMP15"},{{"Sort Order", {{"TAZ","Ascending"}}}}) 
	accE15cpk = accpeak_vectors[1]
	accH15cpk = accpeak_vectors[2]
*/
//	accEt2cpk = GetDataVector(access_peak+"|", "EMPT2CMP", {{"Sort Order", {{"TAZ","Ascending"}}}})
	accE15cpk = GetDataVector(access_peak+"|", "EMPCMP15", {{"Sort Order", {{"TAZ","Ascending"}}}})

	atype = GetDataVector(areatype+"|", "AREATYPE", {{"Sort Order", {{"TAZ","Ascending"}}}}) 

	hhbyincome_v = GetDataVectors(hhbyincome+"|", {"TAZ", "INC1", "INC2", "INC3", "INC4"},{{"Sort Order", {{"TAZ","Ascending"}}}}) 
	inc4 = hhbyincome_v[5]
	pct4 = if (hh = 0) then 0 else (inc4 / hh)

//Get attraction rate factors
	dim atfacta_ar[atype.length]
	dim atot[6]
	dim apurp[6]
	dim remain[6]
	dim sumattr[6]
	attr_v = {hh, pophhs, loind, hiind, retail, hwy, losvc, hisvc, offgov, educ, stuk8, stuhs, stucu, medinc, dens, cbddum}
	arate_vectors = GetDataVectors(arate_vw+"|", {"HH", "POP_HHS", "LOIND", "HIIND", "RTL", "HWY", "LOSVC", "HISVC", "OFFGOV", 
						"EDUC", "STUK8", "STUHS", "STUCU", "MED_INC", "DENS", "CBD"},) 
	atfacta_vectors = GetDataVectors(atfacta_vw+"|", {"AT1", "AT2", "AT3", "AT4", "AT5"},) 
	tourfac_v = GetDataVector(tourfac_vw+"|", "Factor",) 

/*
vws = GetViewNames()
for i = 1 to vws.length do
     CloseView(vws[i])
end
*/
//Pull total number of productions for each purpose (except ATW, which has not been determined yet)
	prod_attr = OpenTable("prod_attr", "FFB", {DirArray + "\\Productions_Attractions.bin",})
	p_flds = {"P_HBW", "P_SCH", "P_HBU", "P_HBS", "P_HBO"}
	p_vecs = GetDataVectors(prod_attr+"|", p_flds, )
	dim p_sums[5]
	for i = 1 to p_flds.length do
		p_sums[i] = VectorStatistic(p_vecs[i], "Sum", )
	end

//Open county table for SCH attraction adjustments
	county_tab = OpenTable("county_tab", "FFB", {DirArray + "\\county.bin",})

//Calculate attractions by tour purpose {order = HBW, SCH, HBU, HBS, HBO, ATW}.  Array {remain} is total attractions from which 1 will be removed after each tour to that destination zone.
	for i = 1 to 6 do	//Loop on purposes (6)
		apurp[i] = Vector(hh.length, "short", {{"Constant", 0}})
		for j = 1 to atype.length do
			atfacta_ar[j] = atfacta_vectors[atype[j]][i]		//create a area type factor vector
		end
		atfacta = a2v(atfacta_ar)
		for j = 1 to 16 do	//16		
			if i = 1 then do
				attrfill_v = if (totemp = 0) then 0 else r2i((attr_v[j] * arate_vectors[j][i]))		//For HBW, if no empl, then attr = 0
			end
			else if i = 4 then do
				attrfill_v = if (retemp = 0) then 0 else r2i((attr_v[j] * arate_vectors[j][i]))			//For HBS, if no retail empl, then attr = 0
			end
			else if i > 4 then do
				attrfill_v = if ((hh + totemp) = 0) then 0 else r2i(attr_v[j] * arate_vectors[j][i])		//For HBO & ATW, if no HH or jobs, then attr = 0
			end
			else do
				attrfill_v = r2i(attr_v[j] * arate_vectors[j][i])	
			end
			apurp[i] = apurp[i] + attrfill_v
		end

		apurp[i] = r2i(max(apurp[i] * tourfac_v[i] * atfacta,0))
		apurp_sum = VectorStatistic(apurp[i], "Sum", )

		//if School, then factor by county so that # attractions in each county =  1%  greater than each county's productions
		if i = 2 then do 	//School
			SetDataVector(prod_attr+"|", "A_TOT_SCH", apurp[i], )
			join1 = JoinViews("join1", "SEFile.TAZ", "prod_attr.TAZ", )
			join2 = JoinViews("join1", "county_tab.STCNTY", "join1.STCNTY", {{"A", }})
			county_v = GetDataVectors(join2+"|", {"STCNTY", "P_SCH", "A_TOT_SCH"},{{"Sort Order", {{"STCNTY","Ascending"}}}})
			county_id = county_v[1]
			prod_by_county = county_v[2]
			initAttr_by_county = county_v[3]
			modAttr_by_county = r2i((prod_by_county * 1.01) + 0.5)
			for j = 1 to county_id.length do
				qry = "Select * where join1.SEFile.STCNTY = " + i2s(county_id[j])
				SetView("join1")
				countyset = SelectByQuery("countyset", "Several", qry)
				initAttr = GetDataVector(join1+"|countyset", "A_TOT_SCH",{{"Sort Order", {{"SEFile.TAZ","Ascending"}}}})				
				modAttr = r2i((initAttr * (modAttr_by_county[j] / initAttr_by_county[j])) + 0.5)
				SetDataVector(join1+"|countyset", "A_TOT_SCH", modAttr, {{"Sort Order", {{"SEFile.TAZ","Ascending"}}}})
			end				
			apurp[i] = GetDataVector(join1+"|", "A_TOT_SCH",{{"Sort Order", {{"SEFile.TAZ","Ascending"}}}})
		end
		//Otherwise compare total attractions to total productions.  If not enough attractions, increase attractions so that there are 1% more attractions than productions.
		else if i < 6 then do
			if (apurp_sum < p_sums[i]) then do
				apurp[i] = r2i((apurp[i] * (p_sums[i] / apurp_sum * 1.01) + 0.5))
			end
		end
		
		remain[i] = apurp[i]
		sumattr[i] = Vector(hh.length, "short", {{"Constant", 0}})
		atot[i] = VectorStatistic(apurp[i], "Sum",)
		if i = 1 then do
			remain[i] = remain[i] 
		end
	end

//need to do the following steps in order to keep # of attractions by purpose constant
	hbwattr_ar = v2a(apurp[1])
	hbwattr = a2v(hbwattr_ar,)
	schattr_ar = v2a(apurp[2])
	schattr = a2v(schattr_ar,)
	hbuattr_ar = v2a(apurp[3])
	hbuattr = a2v(hbuattr_ar,)
	hbsattr_ar = v2a(apurp[4])
	hbsattr = a2v(hbsattr_ar,)
	hboattr_ar = v2a(apurp[5])
	hboattr = a2v(hboattr_ar,)
	atwattr_ar = v2a(apurp[6])
	atwattr = a2v(atwattr_ar,)

//fill in total attractions for each TAZ into production_attraction table
//	prod_attr = OpenTable("prod_attr", "FFB", {DirArray + "\\Productions_Attractions.bin",})
	flds = {"A_TOT_HBW", "A_TOT_SCH", "A_TOT_HBU", "A_TOT_HBS", "A_TOT_HBO", "A_TOT_ATW"}
	vcts = {hbwattr, schattr, hbuattr, hbsattr, hboattr, atwattr}
	for i = 1 to flds.length do
		SetDataVector(prod_attr+"|", flds[i], vcts[i], )
	end

//create a new field to store a random number to each TAZ set in the tour record file.  For each purpose, we will randomize the tours by TAZ set.
	tourrecords = OpenTable("tourrecords", "FFB", {DirArray + "\\TourRecords.bin",})
	tourrecords_v = GetDataVectors(tourrecords+"|", {"TAZ"},{{"Sort Order", {{"TAZ","Ascending"}}}})
	tourtaz = tourrecords_v[1]					//this creates a random-number field to the tour record table, to be used for SCH, HBU, HBW & HBS tour purposes.
	strct = GetTableStructure(tourrecords)
	for j = 1 to strct.length do				//Done so that when subtract one(1) attraction for the destination zone, it is done
 		strct[j] = strct[j] + {strct[j][1]}		//in a random, un-biased way (so that lower number zones don't get preference).
 	end
 	for p = 1 to flds.length do							//The random-number field is removed from table at the end of macro.
		strct = strct + {{"tazrandnum" + i2s(p), "Real", 10,8,,,,,,,,}}
	end
	ModifyTable(tourrecords, strct)
	tazrandnum = Vector(tourtaz.length, "float", )
	
	rmse_results = CreateTable("rmse_results", DirOutDC + "\\rmse_results.bin", "FFB", {{"HBW_RMSE", "Real", 8, 2, "No"}, {"SCH_RMSE", "Real", 8, 2, "No"}, {"HBU_RMSE", "Real", 8, 2, "No"}, {"HBS_RMSE", "Real", 8, 2, "No"}, {"HBO_RMSE", "Real", 8, 2, "No"}, {"ATW_RMSE", "Real", 8, 2, "No"}}) 
	rmse_addrec = AddRecord("rmse_results", )

//open travel time matrices for DC calcs below
	autopk = OpenMatrix(Dir + "\\Skims\\TThwy_peak.mtx", "False")			//open as memory-based
	OpenMatrixFileHandle(autopk, "Write")
	matrix_indices = GetMatrixIndexNames(autopk)	
	for i = 1 to matrix_indices[1].length do
		if matrix_indices[1][i] = "Internals" then goto gotpkindex
	end
	int_pkindex = CreateMatrixIndex("Internals", autopk, "Both", se_vw+"|", "TAZ", "TAZ" )	//just internal zones
	gotpkindex:
	autopkcur = CreateMatrixCurrency(autopk, "TotalTT", "Rows", "Internals", )
	autopkcurall = CreateMatrixCurrency(autopk, "TotalTT", "Rows", "Columns", )
	autopkintcur = CreateMatrixCurrency(autopk, "TotalTT", "Internals", "Internals", )
	autofree = OpenMatrix(Dir + "\\Skims\\TThwy_free.mtx", "False")			//open as memory-based
	OpenMatrixFileHandle(autofree, "Write")
	matrix_indices = GetMatrixIndexNames(autofree)	
	for i = 1 to matrix_indices[1].length do
		if matrix_indices[1][i] = "Internals" then goto gotfreeindex
	end
	int_freeindex = CreateMatrixIndex("Internals", autofree, "Both", se_vw+"|", "TAZ", "TAZ" )	//just internal zones
	gotfreeindex:
	autofreecur = CreateMatrixCurrency(autofree, "TotalTT", "Rows", "Columns", )
	autofreeintcur = CreateMatrixCurrency(autofree, "TotalTT", "Internals", "Internals", )
	compfree = OpenMatrix(Dir + "\\tg\\composite.mtx", "False")			//open as memory-based
//	int_compfreeindex = CreateMatrixIndex("Internals", compfree, "Both", se_vw+"|", "TAZ", "TAZ" )	//internal index created (and kept) in TourAccessibility
	compfreeintcur1 = CreateMatrixCurrency(compfree, "compfree1", "Internals", "Internals", )
	compfreeintcur23 = CreateMatrixCurrency(compfree, "compfree23", "Internals", "Internals", )	//composite times for the 4 income groups (Inc 2 & 3 are the same)
	compfreecur4 = CreateMatrixCurrency(compfree, "compfree4", "Rows", "Internals", )		//includes External zones, for XI-nonwork
	compfreeintcur4 = CreateMatrixCurrency(compfree, "compfree4", "Internals", "Internals", )
	compintcurarray = {compfreeintcur1, compfreeintcur23, compfreeintcur23, compfreeintcur4}

	//create a sequential vector to add to cumulative probability vector so that when it's sorted, the correct (first) TAZ is chosen
	aide_de_sort_vec = Vector(taz.length, "float", {{"Sequence", 0.001, 0.001}})


//******************************CALCULATE THE NUMBER OF IX AND XI TOURS (BROKEN DOWN BY WORK/NON-WORK ******************************************************
  UpdateProgressBar("Calculate the number of IX Work Tours", 10) 

//Open extstavol table
	extstavoltab = OpenTable("extstavoltab", "FFA", {Dir + "\\Ext\\EXTSTAVOL" + yr_str + ".asc",})
	extstavol_v = GetDataVectors(extstavoltab+"|", {"MODEL_STA", "TOT_AUTO"},{{"Sort Order", {{"MODEL_STA","Ascending"}}}})
	extsta = extstavol_v[1]
	extstavol = extstavol_v[2]
//	extstavol_ar = v2a(extstavol)		//have to do this so doesn't remove attraction from exstavol vector as well (not sure why)
	totextstavol = VectorStatistic(extstavol, "Sum",)

//Open table containing PC X/X trip ends (calculated in Tour_XX.rsc
	xxvoltab = OpenTable("xxvoltab", "FFA", {DirArray + "\\thruvol.asc",})	
	pcxx = GetDataVector(xxvoltab+"|", "auto",{{"Sort Order", {{"MODEL_STA","Ascending"}}}})
	totxxvol = VectorStatistic(pcxx, "Sum",)
	
//Open IX/XI tables (IX first, XI second)
	ixxipcttab = OpenTable("ixxipcttab", "CSV", {DirArray + "\\IXXI_pct.csv",})	
	ixxipct = GetDataVector(ixxipcttab+"|", "PercentVeh",)
	ixpct = ixxipct[1]
	xipct = ixxipct[2]

//Calculate the number of IX & XI vehicles at each station (plus total overall)  
	remainExtVol = extstavol - pcxx
	ixveh = r2i(remainExtVol * ixpct)
	totixveh = VectorStatistic(ixveh, "Sum",)
	xiveh = remainExtVol - ixveh				// need to check that adds up after converting IX to persons
	totxiveh = VectorStatistic(xiveh, "Sum",)
	
//Calculate the number of IX person tours.  (Use 1.375 persons/vehicle; divide by 2 to get tours--productions/attractions)  
	ixtours = r2i(ixveh * 1.375 / 2)
	totixtours = VectorStatistic(ixtours, "Sum",)

//Calculate the number of IX person tours that are Work & Non-Work (assumes the ratio is the same at every extsta
	ixworkpcttab = OpenTable("ixworkpcttab", "CSV", {DirArray + "\\IX_Work_Pct.csv",})	
	ixworkpct_v = GetDataVector(ixworkpcttab+"|", "Percent",)
	ixworkpct = ixworkpct_v[1]
	ixnonworkpct = ixworkpct_v[2]

	totixworktours = r2i(totixtours * ixworkpct)
	totixnonworktours = r2i(totixtours * (1 - ixworkpct))

//********************** Separate Out IX Work Trips from HBW **********************************************************************************
//Get each zone's distance to closest Extsta, and open travel time distribution table
    //	dst2extsta = GetDataVector(distExtsta_vw+"|", "Len", {{"Sort Order", {{"From","Ascending"}}}}) 
 	HBW_IX_disttab = OpenTable("HBW_IX_disttab", "CSV", {DirArray + "\\HBW_IX.csv",})	
	Lowval = GetDataVector(HBW_IX_disttab+"|", "Low",)
	Highval = GetDataVector(HBW_IX_disttab+"|", "High",)
	HBW_IX_distpct = GetDataVector(HBW_IX_disttab+"|", "Percent",)
   	
	//calculate the number of tours availible in each distribution (by distance) range
	dim HBW_IX_tours[Lowval.length]	
	for i = 1 to Lowval.length do
		HBW_IX_tours[i] = r2i(totixworktours * HBW_IX_distpct[i]/100)
	end
	
	//create a temp table to put all HBW tours in (HHID, disttoexsta, randnum); then sort table by randnum and first "x" number in dist bin become XIN 
	strct = GetTableStructure(tourrecords)
	for j = 1 to (strct.length) do
 		strct[j] = strct[j] + {strct[j][1]}
 	end
	dim newstrct[13]
	for j = 1 to 13 do							//there are 13 fields that need to copied from TourRecords.bin (not randum numbers)
		newstrct[j] = strct[j]
	end
	temphbwdc = CreateTable("temphbwdc", DirOutDC + "\\temp_hbwdc.bin", "FFB", newstrct)
	newstrct = newstrct + {{"HHID", "Integer", 7,,,,,,,,,}}
	newstrct = newstrct + {{"ORIG_TAZ", "Integer", 6,,,,,,,,,}}
	newstrct = newstrct + {{"ORIG_SEQ", "Integer", 6,,,,,,,,,}}
	newstrct = newstrct + {{"DEST_TAZ", "Integer", 6,,,,,,,,,}}
	newstrct = newstrct + {{"DEST_SEQ", "Integer", 6,,,,,,,,,}}
	newstrct = newstrct + {{"OD_Time", "Real", 8,2,,,,,,,,}}
	newstrct = newstrct + {{"DO_Time", "Real", 8,2,,,,,,,,}}
	newstrct = newstrct + {{"Purp", "Character", 3,,,,,,,,,}}
	newstrct = newstrct + {{"EXT", "Integer", 2,,,,,,,,,}}
	newstrct = newstrct + {{"distEXT", "Real", 10,6,,,,,,,,}}	
	newstrct = newstrct + {{"randnum", "Real", 10,8,,,,,,,,}}
	newstrct = newstrct + {{"tazrandnum", "Real", 10,8,,,,,,,,}}		//for the HBW II table ONLY, create a random number field, which will be used for the ATW DC
		
	ModifyTable(temphbwdc, newstrct)

	qry = "Select * where HBW > 0"
	SetView("tourrecords")
	havetours = SelectByQuery("havetours", "Several", qry)
	SortSet("havetours", "TAZ")
	tourrecordset_v = GetDataVectors(tourrecords+"|havetours", {"ID", "TAZ", "TAZ_SEQ", "SIZE", "INCOME", "LIFE", "WRKRS", "SCH", "HBU", "HBW", "HBS", "HBO", "tazrandnum1"},{{"Sort Order", {{"tazrandnum1","Ascending"},{"ID","Ascending"}}}}) 
	hhidset = tourrecordset_v[1]
	tourtazset = tourrecordset_v[2]
	tourtazseqset = tourrecordset_v[3]
	sizeset = tourrecordset_v[4]
	incset = tourrecordset_v[5]
	lcset = tourrecordset_v[6]
	wrkrsset = tourrecordset_v[7]
	schtoursset = tourrecordset_v[8]
	hbutoursset = tourrecordset_v[9]
	hbwtoursset = tourrecordset_v[10]
	hbstoursset = tourrecordset_v[11]
	hbotoursset = tourrecordset_v[12]

	lasttaz = 0
	temptourid = 0
	iitourid = 0
	ixtourid = 0
	
SetRandomSeed(37)
	for n = 1 to hhidset.length do				//loop thru tour records	
//		pbar.Step()
		if hbwtoursset[n] = 0 then do			//go to next record if there are no hbw tours
			goto nohbwtours
		end
		thistaz = tourtazset[n]
		thistazseq = tourtazseqset[n]
		thisdistextsta = dist2extsta[thistazseq]
		for i = 1 to hbwtoursset[n] do
			rand_val = RandomNumber()
			rand_val2 = RandomNumber()
			temptourid = temptourid + 1
			filltable = AddRecord("temphbwdc", {{"ID", temptourid}, {"HHID", hhidset[n]}, {"TAZ", thistaz}, {"TAZ_SEQ", thistazseq}, {"SIZE", sizeset[n]}, {"INCOME", incset[n]}, {"LIFE", lcset[n]}, {"WRKRS", wrkrsset[n]}, 
								{"SCH", schtoursset[n]}, {"HBU", hbutoursset[n]}, {"HBW", hbwtoursset[n]}, {"HBS", hbstoursset[n]}, {"HBO", hbotoursset[n]}, 
								{"ORIG_TAZ", thistaz}, {"ORIG_SEQ", thistazseq}, {"PURP", "HBW"}, {"distEXT", thisdistextsta}, {"randnum", rand_val}, {"EXT", 0}, {"tazrandnum", rand_val2}})
		end
		nohbwtours:
	end
	//loop by distance buckets, then sort the by random num then fill "EXT" of first x number
	SetView("temphbwdc")
	temprecordset_v = GetDataVectors(temphbwdc+"|", {"ID", "distEXT", "randnum", "EXT"},{{"Sort Order", {{"ID","Ascending"}}}}) 
	hhidset = temprecordset_v[1]
	distset = temprecordset_v[2]
	randset = temprecordset_v[3]
	EXTset = temprecordset_v[4]
	dim HBW_IX_tours_counter[HBW_IX_tours.length]

	for i = 1 to HBW_IX_tours.length do
		qry = "Select * where distEXT >= " + i2s(Lowval[i]) + " and distEXT < " + i2s(Highval[i])
		SetView("temphbwdc")
		inbucket = SelectByQuery("inbucket", "Several", qry)
		HBW_IX_tours_counter[i] = inbucket
		if inbucket > 0 then do
			EXTfill_v = GetDataVectors("temphbwdc|inbucket", {"ID", "EXT"},{{"Sort Order", {{"randnum","Ascending"}}}})
			for j = 1 to HBW_IX_tours[i] do
				EXTfill_v[2][j] = 1
			end
			SetDataVector("temphbwdc|inbucket", "EXT", EXTfill_v[2],{{"Sort Order", {{"randnum","Ascending"}}}})
		end
	end
		

//******************************** HBW DESTINATION CHOICE --INTERNALS ONLY *******************************************************************************************
  UpdateProgressBar("Destination Choice: HBW", 10) 

//Create HBW tour II destination table
	strct = GetTableStructure(tourrecords)
	for j = 1 to (strct.length) do
 		strct[j] = strct[j] + {strct[j][1]}
 	end
	dim newstrct[13]
	for j = 1 to 13 do							//there are 13 fields that need to copied from TourRecords.bin (not randum numbers)
		newstrct[j] = strct[j]
	end
	hbwdestii = CreateTable("hbwdestii", DirOutDC + "\\dcHBW.bin", "FFB", newstrct)
	newstrct = newstrct + {{"HHID", "Integer", 7,,,,,,,,,}}
	newstrct = newstrct + {{"ORIG_TAZ", "Integer", 6,,,,,,,,,}}
	newstrct = newstrct + {{"ORIG_SEQ", "Integer", 6,,,,,,,,,}}
	newstrct = newstrct + {{"DEST_TAZ", "Integer", 6,,,,,,,,,}}
	newstrct = newstrct + {{"DEST_SEQ", "Integer", 6,,,,,,,,,}}
	newstrct = newstrct + {{"OD_Time", "Real", 8,2,,,,,,,,}}
	newstrct = newstrct + {{"DO_Time", "Real", 8,2,,,,,,,,}}
	newstrct = newstrct + {{"Purp", "Character", 3,,,,,,,,,}}
	newstrctii = newstrct + {{"tazrandnum", "Real", 10,8,,,,,,,,}}		//for the HBW II table ONLY, create a random number field, which will be used for the ATW DC

	ModifyTable(hbwdestii, newstrctii)

SetRandomSeed(100)
/*	for n = 1 to tourtaz.length do
		rand_val = RandomNumber()
		tazrandnum[n] = rand_val
	end
	SetDataVector(temphbwdc+"|", "tazrandnum1", tazrandnum,{{"Sort Order", {{"ID","Ascending"}}}})	// Note "tazrandnum1" for HBW
*/
//Pull vectors sorted by randomized TAZ sets
	qry = "Select * where EXT = 0" 
	SetView("temphbwdc")
	hbw_II = SelectByQuery("hbw_II", "Several", qry)
	tourrecordset_v = GetDataVectors(temphbwdc+"|hbw_II", {"ID", "TAZ", "TAZ_SEQ", "SIZE", "INCOME", "LIFE", "WRKRS", "SCH", "HBU", "HBW", "HBS", "HBO", "tazrandnum"},{{"Sort Order", {{"tazrandnum","Ascending"},{"ID","Ascending"}}}}) 

	hhidset = tourrecordset_v[1]
	tourtazset = tourrecordset_v[2]
	tourtazseqset = tourrecordset_v[3]
	sizeset = tourrecordset_v[4]
	incset = tourrecordset_v[5]
	lcset = tourrecordset_v[6]
	wrkrsset = tourrecordset_v[7]
	schtoursset = tourrecordset_v[8]
	hbutoursset = tourrecordset_v[9]
	hbwtoursset = tourrecordset_v[10]
	hbstoursset = tourrecordset_v[11]
	hbotoursset = tourrecordset_v[12]
	tazrandnumset = tourrecordset_v[13]

	lasttaz = 0
	iitourid = 0
	ixtourid = 0
//Loop all tours
SetRandomSeed(737)
	pbar = CreateObject("G30 Progress Bar", "HBW Tours", true, hhidset.length)
	
	for n = 1 to hhidset.length do				//hhidset.length	
		pbar.Step()

		if hbwtoursset[n] = 0 then do			//go to next record if there are no hbw tours
			goto nohbwiitours
		end
		thistaz = tourtazset[n]
		thistazseq = tourtazseqset[n]
		thiscnty = stcnty[thistazseq]
		thisAT = atype[thistazseq]
		intraco = if (stcnty = thiscnty) then 1 else 0
		//intrazonal = if (taz <> thistaz) then 0 else if (thisAT = 1) then -0.7 else if (thisAT = 2) then 0.0 else if (thisAT < 5) then -2.0 else -0.3	//changed for validation
		intrazonal = if (taz <> thistaz) then 0 else 1
//		for i = 1 to hbwtoursset[n] do
		rand_val = RandomNumber()
		if thistaz = lasttaz then do			//skip the probability array creation step if already been done for this TAZ
			goto skipprobhbw
		end
		htime = GetMatrixVector(autopkintcur, {{"Row", thistaz}})	//pull the TT vector for this TAZ from the peak speed matrix
		//U1 = -0.06521*htime + 0.8109*intraco - 0.03048*cbddum - 0.001735*empdens + log(totemp) + 0.7*intrazonal  //calculate probability array -- U1 for Inc 1-3
		//U2 = -0.04812*htime + 1.1500*intraco - 0.2652*cbddum - 0.0005294*empdens + log(totemp) + 0.7*intrazonal  //U2 for INC4
		//U1 = -0.0862*htime + 0.944*intraco + 0.525*cbddum + 0.00248*empdens + 0.949*log(totemp) + 2.14*intrazonal  //calculate probability array -- U1 for Inc 1-3
		//U2 = -0.0862*htime + 0.479*intraco + 1.14*cbddum + 0.00248*empdens + 0.949*log(totemp) + 1.13*intrazonal  //U2 for INC4
		U1 = -0.075*htime + 0.944*intraco + 0.525*cbddum + 0.00248*empdens + 0.949*log(totemp) + 2.14*intrazonal  //calculate probability array -- U1 for Inc 1-3
		U2 = -0.075*htime + 0.479*intraco + 1.14*cbddum + 0.00248*empdens + 0.949*log(totemp) + 1.13*intrazonal  //U2 for INC4

		//factor exp. utile by the ratio of remaining attrs to total attrs for this dest zone ([1] = HBW)
		fac = if (hbwattr > 0) then (remain[1] / hbwattr) else 0	
		eU1 = if (totemp = 0) then 0 else exp(U1) * fac
		eU2 = if (totemp = 0) then 0 else exp(U2) * fac						//zero out zones with no employment
		sumeU1 = VectorStatistic(eU1, "Sum",)
		sumeU2 = VectorStatistic(eU2, "Sum",)
		prob1 = eU1 / sumeU1
		prob2 = eU2 / sumeU2  
		vecs1 = {prob1, taz, tazseq}
		cumprob1 = CumulativeVector(vecs1[1])		//cumulative sum of probabilities, not sorted
		cumprob1[U1.length] = 1
		vecs2 = {prob2, taz, tazseq}
		cumprob2 = CumulativeVector(vecs2[1])
		cumprob2[U1.length] = 1
		lasttaz = thistaz
		skipprobhbw:
		redo_randval_hbw:
		rand_val = RandomNumber()
		//redo if zero since dividing by zero below results in null ; redo if one since last element is defined as one from above, and will be choice whether or not it's eligible
		if (rand_val = 0 or rand_val = 1)  then do
			goto redo_randval_hbw
		end
		addnum = max(r2i(1/rand_val), 500)
		if (incset[n] <> 4) then do
			cumprob = cumprob1 / rand_val				//divide cumulative probabilities by random number; any number under 1.0 is not the chosen value and
			cumprob = if cumprob < 1.0 then addnum else cumprob		//is thus given a high number (100).  The first number greater than or equal to 1.0 is the chosen
			cumprob = cumprob + aide_de_sort_vec				//value, will be placed first in order in the sort, and is picked below:
			sorted_vecs = SortVectors({cumprob, vecs1[2], vecs1[3]})	
		end
		else do
			cumprob = cumprob2 / rand_val
			cumprob = if cumprob < 1.0 then addnum else cumprob
			cumprob = cumprob + aide_de_sort_vec
			sorted_vecs = SortVectors({cumprob, vecs2[2], vecs2[3]})			
		end
		dest_taz = sorted_vecs[2][1]
		dest_tazseq = sorted_vecs[3][1]
		odtime = GetMatrixValue(autopkintcur, i2s(thistaz), i2s(dest_taz))
		dotime = GetMatrixValue(autopkintcur, i2s(dest_taz), i2s(thistaz))
		iitourid = iitourid + 1
		filltable = AddRecord("hbwdestii", {{"ID", iitourid}, {"HHID", hhidset[n]}, {"TAZ", thistaz}, {"TAZ_SEQ", thistazseq}, {"SIZE", sizeset[n]}, {"INCOME", incset[n]}, {"LIFE", lcset[n]}, {"WRKRS", wrkrsset[n]}, 
					{"SCH", schtoursset[n]}, {"HBU", hbutoursset[n]}, {"HBW", hbwtoursset[n]}, {"HBS", hbstoursset[n]}, {"HBO", hbotoursset[n]}, 
					{"ORIG_TAZ", thistaz}, {"ORIG_SEQ", thistazseq}, {"DEST_TAZ", dest_taz}, {"DEST_SEQ", dest_tazseq}, {"OD_Time", odtime}, {"DO_Time", dotime}, {"PURP", "HBW"}})
		remain[1][dest_tazseq] = max(remain[1][dest_tazseq] - 1, 0)	//this removes one attraction from destination zone for each tour
		sumattr[1][dest_tazseq] = sumattr[1][dest_tazseq] + 1
		skipIIhbw:
		//end
		nohbwiitours:
	end

	pbar.Destroy()

	sse = 0
	totattr = 0
	totsumattr = 0
	for i = 1 to hh.length do
		sse = sse + Pow((sumattr[1][i] - hbwattr[i]), 2)
		totattr = totattr + hbwattr[i]
		totsumattr = totsumattr + sumattr[1][i]
	end
	rmse = Sqrt(sse / hh.length)
	SetRecordValues("rmse_results", null, {{"HBW_RMSE", rmse}})
	
	//fill assigned II tours into productions_attractions table
	jointab = JoinViews("jointab", "prod_attr.TAZ", "hbwdestii.DEST_TAZ", {{"A",}})
	attv = GetDataVector(jointab+"|", "[N hbwdestii]", )
	SetDataVector(prod_attr+"|", "DC_II_HBW", attv, )
	CloseView("jointab")

//reportfile = OpenFile(DirOutDC + "\\DC_report.txt","w")
//WriteLine(reportfile, "Tour Destination Choice Results")
//WriteLine(reportfile, "HBW RMSE = " + r2s(rmse))
     CloseView("hbwdestii")

//**************************CREATE HBW IX TABLE *******************************************************************************************
	strct = GetTableStructure(tourrecords)
	for j = 1 to (strct.length) do
 		strct[j] = strct[j] + {strct[j][1]}
 	end
	dim newstrct[13]
	for j = 1 to 13 do							//there are 13 fields that need to copied from TourRecords.bin (not randum numbers)
		newstrct[j] = strct[j]
	end
	hbwdestix = CreateTable("hbwdestix", DirOutDC + "\\dcHBWext.bin", "FFB", newstrct)
	newstrct = newstrct + {{"HHID", "Integer", 7,,,,,,,,,}}
	newstrct = newstrct + {{"ORIG_TAZ", "Integer", 6,,,,,,,,,}}
	newstrct = newstrct + {{"ORIG_SEQ", "Integer", 6,,,,,,,,,}}
	newstrct = newstrct + {{"DEST_TAZ", "Integer", 6,,,,,,,,,}}
	newstrct = newstrct + {{"DEST_SEQ", "Integer", 6,,,,,,,,,}}
	newstrct = newstrct + {{"OD_Time", "Real", 8,2,,,,,,,,}}
	newstrct = newstrct + {{"DO_Time", "Real", 8,2,,,,,,,,}}
	newstrct = newstrct + {{"Purp", "Character", 3,,,,,,,,,}}

	ModifyTable(hbwdestix, newstrct)

//Pull vectors sorted by randomized TAZ sets
	qry = "Select * where EXT = 1" 
	SetView("temphbwdc")
	hbw_IX = SelectByQuery("hbw_IX", "Several", qry)
	tourrecordset_v = GetDataVectors(temphbwdc+"|hbw_IX", {"ID", "TAZ", "TAZ_SEQ", "SIZE", "INCOME", "LIFE", "WRKRS", "SCH", "HBU", "HBW", "HBS", "HBO", "tazrandnum"},{{"Sort Order", {{"tazrandnum","Ascending"},{"ID","Ascending"}}}}) 

	hhidset = tourrecordset_v[1]
	tourtazset = tourrecordset_v[2]
	tourtazseqset = tourrecordset_v[3]
	sizeset = tourrecordset_v[4]
	incset = tourrecordset_v[5]
	lcset = tourrecordset_v[6]
	wrkrsset = tourrecordset_v[7]
	schtoursset = tourrecordset_v[8]
	hbutoursset = tourrecordset_v[9]
	hbwtoursset = tourrecordset_v[10]
	hbstoursset = tourrecordset_v[11]
	hbotoursset = tourrecordset_v[12]
	tazrandnumset = tourrecordset_v[13]

	for n = 1 to hbw_IX do
		ixtourid = ixtourid + 1
		filltable = AddRecord("hbwdestix", {{"ID", ixtourid}, {"HHID", hhidset[n]}, {"TAZ", tourtazset[n]}, {"TAZ_SEQ", tourtazseqset[n]}, {"SIZE", sizeset[n]}, {"INCOME", incset[n]}, {"LIFE", lcset[n]}, {"WRKRS", wrkrsset[n]}, 
					{"SCH", schtoursset[n]}, {"HBU", hbutoursset[n]}, {"HBW", hbwtoursset[n]}, {"HBS", hbstoursset[n]}, {"HBO", hbotoursset[n]}, {"ORIG_TAZ", tourtazset[n]}, {"ORIG_SEQ", tourtazseqset[n]}, {"PURP", "HBW"}})
	end
     CloseView("temphbwdc")
//ShowArray(hhidset)
//goto skip2hbs
//*********************************SCHOOL DESTINATION CHOICE****************************************************************************************************************
	//stays as is
skip2school:
  UpdateProgressBar("Destination Choice: School", 10) 
//Create School tour II & IX destination tables

	strct = GetTableStructure(tourrecords)
	for j = 1 to strct.length do
 		strct[j] = strct[j] + {strct[j][1]}
 	end
	dim newstrct[13]
	for j = 1 to 13 do							//there are 13 fields that need to copied from TourRecords.bin (not randum numbers)
		newstrct[j] = strct[j]
	end
	schdestii = CreateTable("schdestii", DirOutDC + "\\dcSCH.bin", "FFB", newstrct)
	schdestix = CreateTable("schdestix", DirOutDC + "\\dcSCHext.bin", "FFB", newstrct)
	newstrct = newstrct + {{"HHID", "Integer", 6,,,,,,,,,}}
	newstrct = newstrct + {{"ORIG_TAZ", "Integer", 6,,,,,,,,,}}
	newstrct = newstrct + {{"ORIG_SEQ", "Integer", 6,,,,,,,,,}}
	newstrct = newstrct + {{"DEST_TAZ", "Integer", 6,,,,,,,,,}}
	newstrct = newstrct + {{"DEST_SEQ", "Integer", 6,,,,,,,,,}}
	newstrct = newstrct + {{"OD_Time", "Real", 8,2,,,,,,,,}}
	newstrct = newstrct + {{"DO_Time", "Real", 8,2,,,,,,,,}}
	newstrct = newstrct + {{"Purp", "Character", 3,,,,,,,,,}}

	ModifyTable(schdestii, newstrct)
	ModifyTable(schdestix, newstrct)
	
//Calculate probability that tour from this origin, for this purpose, is I/X
//	pEXT = min(0.71 * 0.29 * Pow(dist2extsta, -1.33), 0.30)
	pEXT = min(0.73 * 0.29 * Pow(dist2extsta, -1.33), 0.30)

//Fill in random number for each TAZ set
//	rand_val = RandomNumber()
//	tazrandnum[1] = rand_val
SetRandomSeed(544)
	for n = 1 to tourtaz.length do
/*		if (tourtaz[n] = tourtaz[n-1]) then do
			tazrandnum[n] = tazrandnum[n-1]
		end
		else do
*/			rand_val = RandomNumber()
			tazrandnum[n] = rand_val
//		end
	end
	SetDataVector(tourrecords+"|", "tazrandnum2", tazrandnum,{{"Sort Order", {{"ID","Ascending"}}}}) 	// Note "tazrandnum2" for SCH
//Pull vectors sorted by randomized TAZ sets
	qry = "Select * where SCH > 0"
	SetView("tourrecords")
	havetours = SelectByQuery("havetours", "Several", qry)
	SortSet("havetours", "TAZ")
	tourrecordset_v = GetDataVectors(tourrecords+"|havetours", {"ID", "TAZ", "TAZ_SEQ", "SIZE", "INCOME", "LIFE", "WRKRS", "SCH", "HBU", "HBW", "HBS", "HBO", "tazrandnum2"},{{"Sort Order", {{"tazrandnum2","Ascending"},{"ID","Ascending"}}}}) 
	hhidset = tourrecordset_v[1]
	tourtazset = tourrecordset_v[2]
	tourtazseqset = tourrecordset_v[3]
	sizeset = tourrecordset_v[4]
	incset = tourrecordset_v[5]
	lcset = tourrecordset_v[6]
	wrkrsset = tourrecordset_v[7]
	schtoursset = tourrecordset_v[8]
	hbutoursset = tourrecordset_v[9]
	hbwtoursset = tourrecordset_v[10]
	hbstoursset = tourrecordset_v[11]
	hbotoursset = tourrecordset_v[12]
	tazrandnumset = tourrecordset_v[13]

	lasttaz = 0
	iitourid = 0
	ixtourid = 0

//Loop all tours
SetRandomSeed(744)
	pbar = CreateObject("G30 Progress Bar", "School Tours", true, hhidset.length)

	for n = 1 to hhidset.length do				//hhidset.length	
		pbar.Step()
		
		if schtoursset[n] = 0 then do			//go to next record if there are no school tours
			goto noschtours
		end
		thistaz = tourtazset[n]
		thistazseq = tourtazseqset[n]
		thiscnty = stcnty[thistazseq]
		thisAT = atype[thistazseq]
		intraco = if (stcnty = thiscnty) then 1 else 0
		//intrazonal = if (taz <> thistaz) then 0 else if (thisAT = 1) then -0.4 else if (thisAT = 2) then 0.3 else if (thisAT < 5) then -1.0 else 0.0	//changed for validation
		intrazonal = if (taz <> thistaz) then 0 else 1
		for i = 1 to schtoursset[n] do
			rand_val = RandomNumber()
			//add increased (90%) external probability for zones in Catawba Co (6500-6999), since there are no school zones in region
			if thistaz between 6500 and 6999 then do
				if rand_val < 0.90 then do
					ixtourid = ixtourid + 1
					filltable = AddRecord("schdestix", {{"ID", ixtourid}, {"HHID", hhidset[n]}, {"TAZ", thistaz}, {"TAZ_SEQ", thistazseq}, {"SIZE", sizeset[n]}, {"INCOME", incset[n]}, {"LIFE", lcset[n]}, {"WRKRS", wrkrsset[n]}, 
									{"SCH", schtoursset[n]}, {"HBU", hbutoursset[n]}, {"HBW", hbwtoursset[n]}, {"HBS", hbstoursset[n]}, {"HBO", hbotoursset[n]}, {"ORIG_TAZ", thistaz}, {"ORIG_SEQ", thistazseq}, {"PURP", "SCH"}})
					goto skipIIsch
				end
				else do 
					goto schii
				end
			end
			else if pEXT[thistazseq] > rand_val then do	//create a record for this tour if it is IX
				ixtourid = ixtourid + 1
				filltable = AddRecord("schdestix", {{"ID", ixtourid}, {"HHID", hhidset[n]}, {"TAZ", thistaz}, {"TAZ_SEQ", thistazseq}, {"SIZE", sizeset[n]}, {"INCOME", incset[n]}, {"LIFE", lcset[n]}, {"WRKRS", wrkrsset[n]}, 
								{"SCH", schtoursset[n]}, {"HBU", hbutoursset[n]}, {"HBW", hbwtoursset[n]}, {"HBS", hbstoursset[n]}, {"HBO", hbotoursset[n]}, {"ORIG_TAZ", thistaz}, {"ORIG_SEQ", thistazseq}, {"PURP", "SCH"}})
				goto skipIIsch
			end
			else do
				schii:
				if thistaz = lasttaz then do			//skip the probability array creation step if already been done for this TAZ
					goto skipprobsch
				end
				htime = GetMatrixVector(autofreeintcur, {{"Row", thistaz}})	//pull the TT vector for this TAZ from the offpeak speed matrix
				//U1 = -0.3418 * htime + 1.681 * intraco + log(k12enr) + 0.2 * intrazonal		//calculate probability array (just done for first HH in this TAZ) 
				U1 = -0.268*htime + 1.38*intraco + 0.807*log(k12enr) - 0.253*intrazonal
				//factor exp. utile by the ratio of remaining attrs to total attrs for this dest zone, but with a minimun ratio of 0.01 so that no zone truly runs out of attractions
				fac = if (schattr > 0) then max((remain[2] / schattr), 0.01) else 0 //[2] = SCH
				eU1 = if (k12enr = 0) then 0 else exp(U1) * fac
				sumeU1 = VectorStatistic(eU1, "Sum",)
				prob1 = eU1 / sumeU1
				vecs1 = {prob1, taz, tazseq}
				cumprob1 = CumulativeVector(vecs1[1])
				cumprob1[U1.length] = 1
			end
			lasttaz = thistaz
			skipprobsch:
			redo_randval_sch:
			rand_val = RandomNumber()
			if (rand_val = 0 or rand_val = 1)  then do
				goto redo_randval_sch
			end
			addnum = max(r2i(1/rand_val), 500)
			cumprob = cumprob1 / rand_val
			cumprob = if cumprob < 1.0 then addnum else cumprob
			cumprob = cumprob + aide_de_sort_vec
			sorted_vecs = SortVectors({cumprob, vecs1[2], vecs1[3]})				
			dest_taz = sorted_vecs[2][1]
			dest_tazseq = sorted_vecs[3][1]
			odtime = GetMatrixValue(autofreeintcur, i2s(thistaz), i2s(dest_taz))
			dotime = GetMatrixValue(autofreeintcur, i2s(dest_taz), i2s(thistaz))
			iitourid = iitourid + 1
			filltable = AddRecord("schdestii", {{"ID", iitourid}, {"HHID", hhidset[n]}, {"TAZ", thistaz}, {"TAZ_SEQ", thistazseq}, {"SIZE", sizeset[n]}, {"INCOME", incset[n]}, {"LIFE", lcset[n]}, {"WRKRS", wrkrsset[n]},
						{"SCH", schtoursset[n]}, {"HBU", hbutoursset[n]}, {"HBW", hbwtoursset[n]}, {"HBS", hbstoursset[n]}, {"HBO", hbotoursset[n]}, 
						{"ORIG_TAZ", thistaz}, {"ORIG_SEQ", thistazseq}, {"DEST_TAZ", dest_taz}, {"DEST_SEQ", dest_tazseq}, {"OD_Time", odtime}, {"DO_Time", dotime}, {"PURP", "SCH"}})
			remain[2][dest_tazseq] = max(remain[2][dest_tazseq] - 1, 0)	//this removes one attraction from destination zone for each tour
			sumattr[2][dest_tazseq] = sumattr[2][dest_tazseq] + 1
			skipIIsch:
		end
		noschtours:
	end
	pbar.Destroy()

	sse = 0
	totattr = 0
	for i = 1 to hh.length do
		sse = sse + Pow((sumattr[2][i] - schattr[i]), 2)
		totattr = totattr + schattr[i]
	end
	rmse = Sqrt(sse / hh.length)
	SetRecordValues("rmse_results", null, {{"SCH_RMSE", rmse}})
//showmessage("School rmse = " + r2s(rmse))
	
	//fill assigned II tours into productions_attractions table
	jointab = JoinViews("jointab", "prod_attr.TAZ", "schdestii.DEST_TAZ", {{"A",}})
	attv = GetDataVector(jointab+"|", "[N schdestii]", )
	SetDataVector(prod_attr+"|", "DC_II_SCH", attv, )
	CloseView("jointab")

     CloseView("schdestii")
skiptohbu:
//******************************** HBU DESTINATION CHOICE ***************************************************************************************************************
	//stays as is
  UpdateProgressBar("Destination Choice: HBU", 10) 
//Create HBU tour II & IX destination tables

	strct = GetTableStructure(tourrecords)
	for j = 1 to strct.length do
 		strct[j] = strct[j] + {strct[j][1]}
 	end
	dim newstrct[13]
	for j = 1 to 13 do							//there are 13 fields that need to copied from TourRecords.bin (not randum numbers)
		newstrct[j] = strct[j]
	end
	hbudestii = CreateTable("hbudestii", DirOutDC + "\\dcHBU.bin", "FFB", newstrct)
	hbudestix = CreateTable("hbudestix", DirOutDC + "\\dcHBUext.bin", "FFB", newstrct)
	newstrct = newstrct + {{"HHID", "Integer", 6,,,,,,,,,}}
	newstrct = newstrct + {{"ORIG_TAZ", "Integer", 6,,,,,,,,,}}
	newstrct = newstrct + {{"ORIG_SEQ", "Integer", 6,,,,,,,,,}}
	newstrct = newstrct + {{"DEST_TAZ", "Integer", 6,,,,,,,,,}}
	newstrct = newstrct + {{"DEST_SEQ", "Integer", 6,,,,,,,,,}}
	newstrct = newstrct + {{"OD_Time", "Real", 8,2,,,,,,,,}}
	newstrct = newstrct + {{"DO_Time", "Real", 8,2,,,,,,,,}}
	newstrct = newstrct + {{"Purp", "Character", 3,,,,,,,,,}}

	ModifyTable(hbudestii, newstrct)
	ModifyTable(hbudestix, newstrct)
	
//Calculate probability that tour from this origin, for this purpose, is I/X
//	pEXT = min(8.5 * 0.29 * Pow(dist2extsta, -1.33), 0.30)
	pEXT = min(11.5 * 0.29 * Pow(dist2extsta, -1.33), 0.30)

//Fill in random number for each TAZ set
//	rand_val = RandomNumber()
//	tazrandnum[1] = rand_val
SetRandomSeed(91)
	for n = 1 to tourtaz.length do
/*		if (tourtaz[n] = tourtaz[n-1]) then do
			tazrandnum[n] = tazrandnum[n-1]
		end
		else do
*/			rand_val = RandomNumber()
			tazrandnum[n] = rand_val
//		end
	end
	SetDataVector(tourrecords+"|", "tazrandnum3", tazrandnum,{{"Sort Order", {{"ID","Ascending"}}}})	// Note "tazrandnum3" for HBU
//Pull vectors sorted by randomized TAZ sets
	qry = "Select * where HBU > 0"
	SetView("tourrecords")
	havetours = SelectByQuery("havetours", "Several", qry)
	SortSet("havetours", "TAZ")
	tourrecordset_v = GetDataVectors(tourrecords+"|havetours", {"ID", "TAZ", "TAZ_SEQ", "SIZE", "INCOME", "LIFE", "WRKRS", "SCH", "HBU", "HBW", "HBS", "HBO", "tazrandnum3"},{{"Sort Order", {{"tazrandnum3","Ascending"},{"ID","Ascending"}}}}) 
	hhidset = tourrecordset_v[1]
	tourtazset = tourrecordset_v[2]
	tourtazseqset = tourrecordset_v[3]
	sizeset = tourrecordset_v[4]
	incset = tourrecordset_v[5]
	lcset = tourrecordset_v[6]
	wrkrsset = tourrecordset_v[7]
	schtoursset = tourrecordset_v[8]
	hbutoursset = tourrecordset_v[9]
	hbwtoursset = tourrecordset_v[10]
	hbstoursset = tourrecordset_v[11]
	hbotoursset = tourrecordset_v[12]
	tazrandnumset = tourrecordset_v[13]

	lasttaz = 0
	temptourid = 0
	iitourid = 0
	ixtourid = 0

//Loop all tours
SetRandomSeed(991)
	pbar = CreateObject("G30 Progress Bar", "HBU Tours", true, hhidset.length)
	
	for n = 1 to hhidset.length do		
		pbar.Step()
		if hbutoursset[n] = 0 then do			//go to next record if there are no hbu tours
			goto nohbutours
		end
		thistaz = tourtazset[n]
		thistazseq = tourtazseqset[n]
		thiscnty = stcnty[thistazseq]
		thisAT = atype[thistazseq]
		intraco = if (stcnty = thiscnty) then 1 else 0
		//intrazonal = if (taz <> thistaz) then 0 else if (thisAT = 1) then -0.7 else if (thisAT = 2) then 0.0 else if (thisAT < 5) then -2.0 else -0.3	//changed for validation
		intrazonal = if (taz <> thistaz) then 0 else 1
		for i = 1 to hbutoursset[n] do
			rand_val = RandomNumber()
			if pEXT[thistazseq] > rand_val then do	//create a record for this tour if it is IX
				ixtourid = ixtourid + 1
				filltable = AddRecord("hbudestix", {{"ID", ixtourid}, {"HHID", hhidset[n]}, {"TAZ", thistaz}, {"TAZ_SEQ", thistazseq}, {"SIZE", sizeset[n]}, {"INCOME", incset[n]}, {"LIFE", lcset[n]}, {"WRKRS", wrkrsset[n]}, 
									{"SCH", schtoursset[n]}, {"HBU", hbutoursset[n]}, {"HBW", hbwtoursset[n]}, {"HBS", hbstoursset[n]}, {"HBO", hbotoursset[n]}, {"ORIG_TAZ", thistaz}, {"ORIG_SEQ", thistazseq}, {"PURP", "HBU"}})
				goto skipIIhbu
			end
			else do
				if thistaz = lasttaz then do			//skip the probability array creation step if already been done for this TAZ
					goto skipprobhbu
				end
				htime = GetMatrixVector(autofreeintcur, {{"Row", thistaz}})	//pull the TT vector for this TAZ from the offpeak speed matrix
				//U1 = -0.1635 * htime + log(stucu) + 0.47 * intraco + 0.2 * intrazonal		//calculate probability array (just done for first HH in this TAZ) 
				//U1 = -0.122 * htime + log(stucu) + 1.39 * intraco
				U1 = -0.15 * htime + log(stucu) + 1.39 * intraco
				//factor exp. utile by the ratio of remaining attrs to total attrs for this dest zone, but with a minimun ratio of 0.01 so that no zone truly runs out of attractions
				fac = if (hbuattr > 0) then max((remain[3] / hbuattr), 0.01) else 0	//([3] = HBS)
				eU1 = if (stucu = 0) then 0 else exp(U1) * fac
				sumeU1 = VectorStatistic(eU1, "Sum",)
				prob1 = eU1 / sumeU1
				vecs1 = {prob1, taz, tazseq}
				cumprob1 = CumulativeVector(vecs1[1])
				cumprob1[U1.length] = 1
			end
			lasttaz = thistaz
			skipprobhbu:
			redo_randval_hbu:
			rand_val = RandomNumber()
			if (rand_val = 0 or rand_val = 1)  then do
				goto redo_randval_hbu
			end
			addnum = max(r2i(1/rand_val), 500)
			cumprob = cumprob1 / rand_val
			cumprob = if cumprob < 1.0 then addnum else cumprob
			cumprob = cumprob + aide_de_sort_vec
			sorted_vecs = SortVectors({cumprob, vecs1[2], vecs1[3]})				
			dest_taz = sorted_vecs[2][1]
			dest_tazseq = sorted_vecs[3][1]
			odtime = GetMatrixValue(autofreeintcur, i2s(thistaz), i2s(dest_taz))
			dotime = GetMatrixValue(autofreeintcur, i2s(dest_taz), i2s(thistaz))
			iitourid = iitourid + 1
			filltable = AddRecord("hbudestii", {{"ID", iitourid}, {"HHID", hhidset[n]}, {"TAZ", thistaz}, {"TAZ_SEQ", thistazseq}, {"SIZE", sizeset[n]}, {"INCOME", incset[n]}, {"LIFE", lcset[n]}, {"WRKRS", wrkrsset[n]}, 
						{"SCH", schtoursset[n]}, {"HBU", hbutoursset[n]}, {"HBW", hbwtoursset[n]}, {"HBS", hbstoursset[n]}, {"HBO", hbotoursset[n]}, 
						{"ORIG_TAZ", thistaz}, {"ORIG_SEQ", thistazseq}, {"DEST_TAZ", dest_taz}, {"DEST_SEQ", dest_tazseq}, {"OD_Time", odtime}, {"DO_Time", dotime}, {"PURP", "HBU"}})
			remain[3][dest_tazseq] = max(remain[3][dest_tazseq] - 1, 0)	//this removes one attraction from destination zone for each tour
			sumattr[3][dest_tazseq] = sumattr[3][dest_tazseq] + 1
			skipIIhbu:
		end
		nohbutours:
	end
	pbar.Destroy()

	sse = 0
	totattr = 0
	for i = 1 to hh.length do
		sse = sse + Pow((sumattr[3][i] - hbuattr[i]), 2)
		totattr = totattr + hbuattr[i]
	end
	rmse = Sqrt(sse / hh.length)
	SetRecordValues("rmse_results", null, {{"HBU_RMSE", rmse}})
	
	//fill assigned II tours into productions_attractions table
	jointab = JoinViews("jointab", "prod_attr.TAZ", "hbudestii.DEST_TAZ", {{"A",}})
	attv = GetDataVector(jointab+"|", "[N hbudestii]", )
	SetDataVector(prod_attr+"|", "DC_II_HBU", attv, )
	CloseView("jointab")

     CloseView("hbudestii")

skip2hbs:	
//********************** Separate Out IX Non-work Trips from HBS & HBO (combine both purposes) *****************************************************************
//Get each zone's distance to closest Extsta, and open travel time distribution table
    //	dst2extsta = GetDataVector(distExtsta_vw+"|", "Len", {{"Sort Order", {{"From","Ascending"}}}}) 
 	HBSO_IX_disttab = OpenTable("HBSO_IX_disttab", "CSV", {DirArray + "\\HBO_IX.csv",})	//check name
	Lowval = GetDataVector(HBSO_IX_disttab+"|", "Low",)
	Highval = GetDataVector(HBSO_IX_disttab+"|", "High",)
	HBSO_IX_distpct = GetDataVector(HBSO_IX_disttab+"|", "Percent",)
   	
	//calculate the number of tours availible in each distribution (by distance) range
	dim HBSO_IX_tours[Lowval.length]	
	for i = 1 to Lowval.length do
		HBSO_IX_tours[i] = r2i(totixnonworktours * HBSO_IX_distpct[i]/100)
	end
	
	//create a temp table to put all HBW tours in (HHID, disttoexsta, randnum); then sort table by randnum and first "x" number in dist bin become XIN 
	strct = GetTableStructure(tourrecords)
	for j = 1 to (strct.length) do
 		strct[j] = strct[j] + {strct[j][1]}
 	end
	dim newstrct[13]
	for j = 1 to 13 do							//there are 13 fields that need to copied from TourRecords.bin (not randum numbers)
		newstrct[j] = strct[j]
	end
	temphbsodc = CreateTable("temphbsodc", DirOutDC + "\\temp_hbsodc.bin", "FFB", newstrct)
	newstrct = newstrct + {{"HHID", "Integer", 7,,,,,,,,,}}
	newstrct = newstrct + {{"ORIG_TAZ", "Integer", 6,,,,,,,,,}}
	newstrct = newstrct + {{"ORIG_SEQ", "Integer", 6,,,,,,,,,}}
	newstrct = newstrct + {{"DEST_TAZ", "Integer", 6,,,,,,,,,}}
	newstrct = newstrct + {{"DEST_SEQ", "Integer", 6,,,,,,,,,}}
	newstrct = newstrct + {{"OD_Time", "Real", 8,2,,,,,,,,}}
	newstrct = newstrct + {{"DO_Time", "Real", 8,2,,,,,,,,}}
	newstrct = newstrct + {{"Purp", "Character", 3,,,,,,,,,}}
	newstrct = newstrct + {{"EXT", "Integer", 2,,,,,,,,,}}
	newstrct = newstrct + {{"distEXT", "Real", 10,6,,,,,,,,}}	
	newstrct = newstrct + {{"randnum", "Real", 10,8,,,,,,,,}}
	newstrct = newstrct + {{"tazrandnum", "Real", 10,8,,,,,,,,}}		
		
	ModifyTable(temphbsodc, newstrct)

	qry = "Select * where HBS > 0 or HBO > 0"
	SetView("tourrecords")
	havetours = SelectByQuery("havetours", "Several", qry)
	SortSet("havetours", "TAZ")
	tourrecordset_v = GetDataVectors(tourrecords+"|havetours", {"ID", "TAZ", "TAZ_SEQ", "SIZE", "INCOME", "LIFE", "WRKRS", "SCH", "HBU", "HBW", "HBS", "HBO", "tazrandnum4"},{{"Sort Order", {{"tazrandnum4","Ascending"},{"ID","Ascending"}}}}) 
	hhidset = tourrecordset_v[1]
	tourtazset = tourrecordset_v[2]
	tourtazseqset = tourrecordset_v[3]
	sizeset = tourrecordset_v[4]
	incset = tourrecordset_v[5]
	lcset = tourrecordset_v[6]
	wrkrsset = tourrecordset_v[7]
	schtoursset = tourrecordset_v[8]
	hbutoursset = tourrecordset_v[9]
	hbwtoursset = tourrecordset_v[10]
	hbstoursset = tourrecordset_v[11]
	hbotoursset = tourrecordset_v[12]

	lasttaz = 0
	temptourid = 0
	iitourid = 0
	ixtourid = 0

	for n = 1 to hhidset.length do				//loop thru tour records	
//		pbar.Step()
//		if (hbstoursset[n] = 0 and hbotoursset[n]) = 0 then do			//go to next record if there are no hbs or hbo tours
//			goto nohbsotours
//		end
		thistaz = tourtazset[n]
		thistazseq = tourtazseqset[n]
		thisdistextsta = dist2extsta[thistazseq]
		//fill PURP (either HBS or HBO) & other fields
		if hbstoursset[n] > 0 then do
			for j = 1 to hbstoursset[n] do
				temptourid = temptourid + 1
				rand_val = RandomNumber()
				rand_val2 = RandomNumber()
				filltable = AddRecord("temphbsodc", {{"ID", temptourid}, {"HHID", hhidset[n]}, {"TAZ", thistaz}, {"TAZ_SEQ", thistazseq}, {"SIZE", sizeset[n]}, {"INCOME", incset[n]}, {"LIFE", lcset[n]}, {"WRKRS", wrkrsset[n]}, 
							{"SCH", schtoursset[n]}, {"HBU", hbutoursset[n]}, {"HBW", hbwtoursset[n]}, {"HBS", hbstoursset[n]}, {"HBO", hbotoursset[n]}, 
							{"ORIG_TAZ", thistaz}, {"ORIG_SEQ", thistazseq}, {"PURP", "HBS"}, {"distEXT", thisdistextsta}, {"randnum", rand_val}, {"EXT", 0}, {"tazrandnum", rand_val2}})
			end
		end
		if hbotoursset[n] > 0 then do
			for k = 1 to hbotoursset[n] do
				temptourid = temptourid + 1
				rand_val = RandomNumber()
				rand_val2 = RandomNumber()
				filltable = AddRecord("temphbsodc", {{"ID", temptourid}, {"HHID", hhidset[n]}, {"TAZ", thistaz}, {"TAZ_SEQ", thistazseq}, {"SIZE", sizeset[n]}, {"INCOME", incset[n]}, {"LIFE", lcset[n]}, {"WRKRS", wrkrsset[n]}, 
							{"SCH", schtoursset[n]}, {"HBU", hbutoursset[n]}, {"HBW", hbwtoursset[n]}, {"HBS", hbstoursset[n]}, {"HBO", hbotoursset[n]}, 
							{"ORIG_TAZ", thistaz}, {"ORIG_SEQ", thistazseq}, {"PURP", "HBO"}, {"distEXT", thisdistextsta}, {"randnum", rand_val}, {"EXT", 0}, {"tazrandnum", rand_val2}})
			end
		end				
		nohbsotours:
	end
	//loop by distance buckets, then sort the by random num then fill "EXT" of first x number
	SetView("temphbsodc")
	temprecordset_v = GetDataVectors(temphbsodc+"|", {"ID", "distEXT", "randnum", "EXT"},{{"Sort Order", {{"ID","Ascending"}}}}) 
	hhidset = temprecordset_v[1]
	distset = temprecordset_v[2]
	randset = temprecordset_v[3]
	EXTset = temprecordset_v[4]

	for i = 1 to HBSO_IX_tours.length do
		qry = "Select * where distEXT >= " + i2s(Lowval[i]) + " and distEXT < " + i2s(Highval[i])
		SetView("temphbsodc")
		inbucket = SelectByQuery("inbucket", "Several", qry)
		if inbucket > 0 then do
			EXTfill_v = GetDataVectors("temphbsodc|inbucket", {"ID", "EXT"},{{"Sort Order", {{"randnum","Ascending"}}}})
			for j = 1 to HBSO_IX_tours[i] do
				EXTfill_v[2][j] = 1
			end
			SetDataVector("temphbsodc|inbucket", "EXT", EXTfill_v[2],{{"Sort Order", {{"randnum","Ascending"}}}})
		end
	end

//********************************* HBS DESTINATION CHOICE --INTERNALS ONLY ***********************************************************************************************

  UpdateProgressBar("Destination Choice: HBS", 10) 
//Create HBS tour II destination table

	strct = GetTableStructure(tourrecords)
	for j = 1 to strct.length do
 		strct[j] = strct[j] + {strct[j][1]}
 	end
	dim newstrct[13]
	for j = 1 to 13 do							//there are 13 fields that need to copied from TourRecords.bin (not randum numbers)
		newstrct[j] = strct[j]
	end
	hbsdestii = CreateTable("hbsdestii", DirOutDC + "\\dcHBS.bin", "FFB", newstrct)
	newstrct = newstrct + {{"HHID", "Integer", 6,,,,,,,,,}}
	newstrct = newstrct + {{"ORIG_TAZ", "Integer", 6,,,,,,,,,}}
	newstrct = newstrct + {{"ORIG_SEQ", "Integer", 6,,,,,,,,,}}
	newstrct = newstrct + {{"DEST_TAZ", "Integer", 6,,,,,,,,,}}
	newstrct = newstrct + {{"DEST_SEQ", "Integer", 6,,,,,,,,,}}
	newstrct = newstrct + {{"OD_Time", "Real", 8,2,,,,,,,,}}
	newstrct = newstrct + {{"DO_Time", "Real", 8,2,,,,,,,,}}
	newstrct = newstrct + {{"Purp", "Character", 3,,,,,,,,,}}

	ModifyTable(hbsdestii, newstrct)
	
//Pull vectors sorted by randomized TAZ sets
	qry = "Select * where Purp = 'HBS' and EXT = 0" 
	SetView("temphbsodc")
	hbs_II = SelectByQuery("hbs_II", "Several", qry)
	tourrecordset_v = GetDataVectors(temphbsodc+"|hbs_II", {"ID", "TAZ", "TAZ_SEQ", "SIZE", "INCOME", "LIFE", "WRKRS", "SCH", "HBU", "HBW", "HBS", "HBO", "tazrandnum"},{{"Sort Order", {{"tazrandnum","Ascending"},{"ID","Ascending"}}}}) 

SetRandomSeed(86489)
/*	for n = 1 to tourtaz.length do
			rand_val = RandomNumber()
			tazrandnum[n] = rand_val
	end
	SetDataVector(tourrecords+"|", "tazrandnum4", tazrandnum,{{"Sort Order", {{"ID","Ascending"}}}})	// Note "tazrandnum4" for HBS
*/
//Pull vectors sorted by randomized TAZ sets
	hhidset = tourrecordset_v[1]
	tourtazset = tourrecordset_v[2]
	tourtazseqset = tourrecordset_v[3]
	sizeset = tourrecordset_v[4]
	incset = tourrecordset_v[5]
	lcset = tourrecordset_v[6]
	wrkrsset = tourrecordset_v[7]
	schtoursset = tourrecordset_v[8]
	hbutoursset = tourrecordset_v[9]
	hbwtoursset = tourrecordset_v[10]
	hbstoursset = tourrecordset_v[11]
	hbotoursset = tourrecordset_v[12]
	tazrandnumset = tourrecordset_v[13]

	lasttaz = 0
	iitourid = 0
	ixtourid = 0

//Loop all tours
SetRandomSeed(72)
	pbar = CreateObject("G30 Progress Bar"," HBS Tours", true, hhidset.length)
	
	for n = 1 to hhidset.length do				//hhidset.length	
		pbar.Step()

		if hbstoursset[n] = 0 then do			//go to next record if there are no hbw tours
			goto nohbstours
		end
		thistaz = tourtazset[n]
		thistazseq = tourtazseqset[n]
		thiscnty = stcnty[thistazseq]
		thisAT = atype[thistazseq]
		intraco = if (stcnty = thiscnty) then 1 else 0
		//intrazonal = if (taz <> thistaz) then 0 else if (thisAT < 3) then 0.8 else if (thisAT < 5) then 2.0 else 1.0	//changed for validation
		intrazonal = if (taz <> thistaz) then 0 else 1
//		for i = 1 to hbstoursset[n] do
		rand_val = RandomNumber()
		if thistaz = lasttaz then do			//skip the probability array creation step if already been done for this TAZ
			goto skipprobhbs
		end
		ctime = GetMatrixVector(compintcurarray[incset[n]], {{"Row", thistaz}})	//pull the TT vector for this TAZ from the offpeak composite speed matrix based on income group
		timeSq = ctime * ctime
		//U1 = -0.3782*ctime - 0.1907*atype - 2.1877*cbddum + log(retemp + 0.003874*pop) - 0.8*intrazonal + 0.0011*timeSq		//calculate probability array -- U1 for Inc 1-3
		//U2 = -0.3175*ctime - 0.2576*atype - 1.5588*cbddum + 0.0000000468*accH15cfr + log(retemp + 0.003135*pop) - 0.5*intrazonal + 0.0011*timeSq	//U2 for INC4
		U1 = -0.294*ctime + 0.930*log(retemp) + 0.0649*retempdens - 0.763*cbddum + 0.232*intraco		//calculate probability array -- U1 for Inc 1-3
		U2 = -0.282*ctime + 0.930*log(retemp) + 0.0649*retempdens - 0.268*intrazonal - 0.155*atype	//U2 for INC4
		//factor exp. utile by the ratio of remaining attrs to total attrs for this dest zone, but with a minimun ratio of 0.01 so that no zone truly runs out of attractions
		fac = if (hbsattr > 0) then max((remain[4] / hbsattr), 0.01) else 0	//([4] = HBS)
		eU1 = if (totemp = 0) then 0 else exp(U1) * fac
		eU2 = if (totemp = 0) then 0 else exp(U2) * fac						//zero out zones with no employment
		sumeU1 = VectorStatistic(eU1, "Sum",)
		sumeU2 = VectorStatistic(eU2, "Sum",)
		prob1 = eU1 / sumeU1
		prob2 = eU2 / sumeU2
		vecs1 = {prob1, taz, tazseq}
		cumprob1 = CumulativeVector(vecs1[1])
		cumprob1[U1.length] = 1
		vecs2 = {prob2, taz, tazseq}
		cumprob2 = CumulativeVector(vecs2[1])
		cumprob2[U1.length] = 1
		lasttaz = thistaz
		skipprobhbs:
		redo_randval_hbs:
		rand_val = RandomNumber()
		if (rand_val = 0 or rand_val = 1)  then do
			goto redo_randval_hbs
		end
		addnum = max(r2i(1/rand_val), 500)
		if (incset[n] <> 4) then do
			cumprob = cumprob1 / rand_val
			cumprob = if cumprob < 1.0 then addnum else cumprob
			cumprob = cumprob + aide_de_sort_vec
			sorted_vecs = SortVectors({cumprob, vecs1[2], vecs1[3]})				
		end
		else do
			cumprob = cumprob2 / rand_val
			cumprob = if cumprob < 1.0 then addnum else cumprob
			cumprob = cumprob + aide_de_sort_vec
			sorted_vecs = SortVectors({cumprob, vecs2[2], vecs2[3]})				
		end
		dest_taz = sorted_vecs[2][1]
		dest_tazseq = sorted_vecs[3][1]
		odtime = GetMatrixValue(autofreeintcur, i2s(thistaz), i2s(dest_taz))
		dotime = GetMatrixValue(autofreeintcur, i2s(dest_taz), i2s(thistaz))
		iitourid = iitourid + 1
		filltable = AddRecord("hbsdestii", {{"ID", iitourid}, {"HHID", hhidset[n]}, {"TAZ", thistaz}, {"TAZ_SEQ", thistazseq}, {"SIZE", sizeset[n]}, {"INCOME", incset[n]}, {"LIFE", lcset[n]}, {"WRKRS", wrkrsset[n]}, 
					{"SCH", schtoursset[n]}, {"HBU", hbutoursset[n]}, {"HBW", hbwtoursset[n]}, {"HBS", hbstoursset[n]}, {"HBO", hbotoursset[n]}, 
					{"ORIG_TAZ", thistaz}, {"ORIG_SEQ", thistazseq}, {"DEST_TAZ", dest_taz}, {"DEST_SEQ", dest_tazseq}, {"OD_Time", odtime}, {"DO_Time", dotime}, {"PURP", "HBS"}})
		remain[4][dest_tazseq] = max(remain[4][dest_tazseq] - 1, 0)	//this removes one attraction from destination zone for each tour
		sumattr[4][dest_tazseq] = sumattr[4][dest_tazseq] + 1
		//end
		nohbstours:
	end
	pbar.Destroy()

	sse = 0
	totattr = 0
	for i = 1 to hh.length do
		sse = sse + Pow((sumattr[4][i] - hbsattr[i]), 2)
		totattr = totattr + hbsattr[i]
	end
	rmse = Sqrt(sse / hh.length)
	SetRecordValues("rmse_results", null, {{"HBS_RMSE", rmse}})
	
	//fill assigned II tours into productions_attractions table
	jointab = JoinViews("jointab", "prod_attr.TAZ", "hbsdestii.DEST_TAZ", {{"A",}})
	attv = GetDataVector(jointab+"|", "[N hbsdestii]", )
	SetDataVector(prod_attr+"|", "DC_II_HBS", attv, )
	CloseView("jointab")

     CloseView("hbsdestii")

//**************************CREATE HBS IX TABLE *******************************************************************************************
	strct = GetTableStructure(tourrecords)
	for j = 1 to (strct.length) do
 		strct[j] = strct[j] + {strct[j][1]}
 	end
	dim newstrct[13]
	for j = 1 to 13 do							//there are 13 fields that need to copied from TourRecords.bin (not randum numbers)
		newstrct[j] = strct[j]
	end
	hbsdestix = CreateTable("hbsdestix", DirOutDC + "\\dcHBSext.bin", "FFB", newstrct)
	newstrct = newstrct + {{"HHID", "Integer", 7,,,,,,,,,}}
	newstrct = newstrct + {{"ORIG_TAZ", "Integer", 6,,,,,,,,,}}
	newstrct = newstrct + {{"ORIG_SEQ", "Integer", 6,,,,,,,,,}}
	newstrct = newstrct + {{"DEST_TAZ", "Integer", 6,,,,,,,,,}}
	newstrct = newstrct + {{"DEST_SEQ", "Integer", 6,,,,,,,,,}}
	newstrct = newstrct + {{"OD_Time", "Real", 8,2,,,,,,,,}}
	newstrct = newstrct + {{"DO_Time", "Real", 8,2,,,,,,,,}}
	newstrct = newstrct + {{"Purp", "Character", 3,,,,,,,,,}}

	ModifyTable(hbsdestix, newstrct)

//Pull vectors sorted by randomized TAZ sets
	qry = "Select * where PURP = 'HBS' and EXT = 1" 
	SetView("temphbsodc")
	hbs_IX = SelectByQuery("hbs_IX", "Several", qry)
	tourrecordset_v = GetDataVectors(temphbsodc+"|hbs_IX", {"ID", "TAZ", "TAZ_SEQ", "SIZE", "INCOME", "LIFE", "WRKRS", "SCH", "HBU", "HBW", "HBS", "HBO", "tazrandnum"},{{"Sort Order", {{"tazrandnum","Ascending"},{"ID","Ascending"}}}}) 

	hhidset = tourrecordset_v[1]
	tourtazset = tourrecordset_v[2]
	tourtazseqset = tourrecordset_v[3]
	sizeset = tourrecordset_v[4]
	incset = tourrecordset_v[5]
	lcset = tourrecordset_v[6]
	wrkrsset = tourrecordset_v[7]
	schtoursset = tourrecordset_v[8]
	hbutoursset = tourrecordset_v[9]
	hbwtoursset = tourrecordset_v[10]
	hbstoursset = tourrecordset_v[11]
	hbotoursset = tourrecordset_v[12]
	tazrandnumset = tourrecordset_v[13]

	for n = 1 to hbs_IX do
		ixtourid = ixtourid + 1
		filltable = AddRecord("hbsdestix", {{"ID", ixtourid}, {"HHID", hhidset[n]}, {"TAZ", tourtazset[n]}, {"TAZ_SEQ", tourtazseqset[n]}, {"SIZE", sizeset[n]}, {"INCOME", incset[n]}, {"LIFE", lcset[n]}, {"WRKRS", wrkrsset[n]}, 
					{"SCH", schtoursset[n]}, {"HBU", hbutoursset[n]}, {"HBW", hbwtoursset[n]}, {"HBS", hbstoursset[n]}, {"HBO", hbotoursset[n]}, {"ORIG_TAZ", tourtazset[n]}, {"ORIG_SEQ", tourtazseqset[n]}, {"PURP", "HBS"}})
	end

//********************************* HBO DESTINATION CHOICE INTERNALS ONLY *****************************************************************************************
  UpdateProgressBar("Destination Choice: HBO", 10) 

//Create HBO tour II & IX destination tables

	strct = GetTableStructure(tourrecords)
	for j = 1 to strct.length do
 		strct[j] = strct[j] + {strct[j][1]}
 	end
	dim newstrct[13]
	for j = 1 to 13 do							//there are 13 fields that need to copied from TourRecords.bin (not randum numbers)
		newstrct[j] = strct[j]
	end
	hbodestii = CreateTable("hbodestii", DirOutDC + "\\dcHBO.bin", "FFB", newstrct)
	newstrct = newstrct + {{"HHID", "Integer", 7,,,,,,,,,}}
	newstrct = newstrct + {{"ORIG_TAZ", "Integer", 6,,,,,,,,,}}
	newstrct = newstrct + {{"ORIG_SEQ", "Integer", 6,,,,,,,,,}}
	newstrct = newstrct + {{"DEST_TAZ", "Integer", 6,,,,,,,,,}}
	newstrct = newstrct + {{"DEST_SEQ", "Integer", 6,,,,,,,,,}}
	newstrct = newstrct + {{"OD_Time", "Real", 8,2,,,,,,,,}}
	newstrct = newstrct + {{"DO_Time", "Real", 8,2,,,,,,,,}}
	newstrct = newstrct + {{"Purp", "Character", 3,,,,,,,,,}}

	ModifyTable(hbodestii, newstrct)
	
SetRandomSeed(763)
//Pull vectors sorted by randomized TAZ sets
	qry = "Select * where PURP = 'HBO' and EXT = 0" 
	SetView("temphbsodc")
	hbo_II = SelectByQuery("hbo_II", "Several", qry)
	tourrecordset_v = GetDataVectors(temphbsodc+"|hbo_II", {"ID", "TAZ", "TAZ_SEQ", "SIZE", "INCOME", "LIFE", "WRKRS", "SCH", "HBU", "HBW", "HBS", "HBO", "tazrandnum"},{{"Sort Order", {{"tazrandnum","Ascending"},{"ID","Ascending"}}}}) 

	hhidset = tourrecordset_v[1]
	tourtazset = tourrecordset_v[2]
	tourtazseqset = tourrecordset_v[3]
	sizeset = tourrecordset_v[4]
	incset = tourrecordset_v[5]
	lcset = tourrecordset_v[6]
	wrkrsset = tourrecordset_v[7]
	schtoursset = tourrecordset_v[8]
	hbutoursset = tourrecordset_v[9]
	hbwtoursset = tourrecordset_v[10]
	hbstoursset = tourrecordset_v[11]
	hbotoursset = tourrecordset_v[12]
	tazrandnumset = tourrecordset_v[13]

	lasttaz = 0
	iitourid = 0
	ixtourid = 0

//Loop all tours
SetRandomSeed(953)
	pbar = CreateObject("G30 Progress Bar", "HBO Tours", true,  hhidset.length)
	
	for n = 1 to hhidset.length do				//hhidset.length	
		pbar.Step() 
		if hbotoursset[n] = 0 then do			//go to next record if there are no hbo tours
			goto nohbotours
		end
		thistaz = tourtazset[n]
		thistazseq = tourtazseqset[n]
		thiscnty = stcnty[thistazseq]
		thisAT = atype[thistazseq]
		intraco = if (stcnty = thiscnty) then 1 else 0
		//intrazonal = if (taz <> thistaz) then 0 else if (thisAT = 1) then -0.7 else if (thisAT = 2) then 0.0 else if (thisAT < 5) then -2.0 else -0.3	//changed for validation
		intrazonal = if (taz <> thistaz) then 0 else 1
		sameAT = if (atype = thisAT) then 1 else 0		//create a dummy same area type vector 
//		for i = 1 to hbotoursset[n] do
		rand_val = RandomNumber()
		if thistaz = lasttaz then do			//skip the probability array creation step if already been done for this TAZ
			goto skipprobhbo
		end
		ctime = GetMatrixVector(compintcurarray[incset[n]], {{"Row", thistaz}})	//pull the TT vector for this TAZ from the offpeak composite speed matrix based on income group
		dist2extsta = a2v(dist2extsta_ar)
		dist2cbd = a2v(dist2cbd_ar)
		//U1 = -0.2201*ctime - 0.4972*atype + 0.1709*sameAT + 0.03015*dist2cbd - 0.00000002033*accE15cfr + 0.4836*pct4 + log(totemp + 0.192242*pop) + 0.2*cbddum + 0.45*intraco + 0.2*intrazonal	//calculate probability array -- U1 for Inc 1-3
		//U2 = -0.2453*ctime - 0.4178*atype + 0.2998*sameAT + 0.02397*dist2cbd - 0.000000015*accE15cfr + 1.128*pct4 + log(totemp + 0.109481*pop) + 0.2*cbddum + 0.45*intraco + 0.2*intrazonal	//U2 for INC4
		U1 = -0.301*ctime + 0.00202*ctime*ctime + 0.00775*empdens - 0.00000378*accE15cfr + 0.742*log(totemp + 0.1108*pop) - 0.102*cbddum + 0.329*intraco + 0.874*intrazonal	- 0.194*atype//calculate probability array -- U1 for Inc 1-3
		U2 = -0.294*ctime + 0.00202*ctime*ctime + 0.00775*empdens - 0.00000229*accE15cfr + 0.742*log(totemp + 0.1108*pop) - 0.102*cbddum + 0.329*intraco + 0.656*intrazonal	- 0.235*atype//U2 for INC4
		//factor exp. utile by the ratio of remaining attrs to total attrs for this dest zone, but with a minimun ratio of 0.01 so that no zone truly runs out of attractions
		fac = if (hboattr > 0) then max((remain[5] / hboattr), 0.01) else 0	//([5] = HBO)
		eU1 = if (totemp = 0) then 0 else exp(U1) * fac
		eU2 = if (totemp = 0) then 0 else exp(U2) * fac						//zero out zones with no employment
		sumeU1 = VectorStatistic(eU1, "Sum",)
		sumeU2 = VectorStatistic(eU2, "Sum",)
		prob1 = eU1 / sumeU1
		prob2 = eU2 / sumeU2
		vecs1 = {prob1, taz, tazseq}
		cumprob1 = CumulativeVector(vecs1[1])
		cumprob1[U1.length] = 1
		vecs2 = {prob2, taz, tazseq}
		cumprob2 = CumulativeVector(vecs2[1])
		cumprob2[U1.length] = 1
		lasttaz = thistaz
		skipprobhbo:
		redo_randval_hbo:
		rand_val = RandomNumber()
		if (rand_val = 0 or rand_val = 1)  then do
			goto redo_randval_hbo
		end
		addnum = max(r2i(1/rand_val), 500)
		if (incset[n] <> 4) then do
			cumprob = cumprob1 / rand_val
			cumprob = if cumprob < 1.0 then addnum else cumprob
			cumprob = cumprob + aide_de_sort_vec
			sorted_vecs = SortVectors({cumprob, vecs1[2], vecs1[3]})				
		end
		else do
			cumprob = cumprob2 / rand_val
			cumprob = if cumprob < 1.0 then addnum else cumprob
			cumprob = cumprob + aide_de_sort_vec
			sorted_vecs = SortVectors({cumprob, vecs2[2], vecs2[3]})				
		end
		dest_taz = sorted_vecs[2][1]
		dest_tazseq = sorted_vecs[3][1]
		odtime = GetMatrixValue(autofreeintcur, i2s(thistaz), i2s(dest_taz))
		dotime = GetMatrixValue(autofreeintcur, i2s(dest_taz), i2s(thistaz))
		iitourid = iitourid + 1
		filltable = AddRecord("hbodestii", {{"ID", iitourid}, {"HHID", hhidset[n]}, {"TAZ", thistaz}, {"TAZ_SEQ", thistazseq}, {"SIZE", sizeset[n]}, {"INCOME", incset[n]}, {"LIFE", lcset[n]}, {"WRKRS", wrkrsset[n]}, 
					{"SCH", schtoursset[n]}, {"HBU", hbutoursset[n]}, {"HBW", hbwtoursset[n]}, {"HBS", hbstoursset[n]}, {"HBO", hbotoursset[n]}, 
					{"ORIG_TAZ", thistaz}, {"ORIG_SEQ", thistazseq}, {"DEST_TAZ", dest_taz}, {"DEST_SEQ", dest_tazseq}, {"OD_Time", odtime}, {"DO_Time", dotime}, {"PURP", "HBO"}})
		remain[5][dest_tazseq] = max(remain[5][dest_tazseq] - 1, 0)	//this removes one attraction from destination zone for each tour
		sumattr[5][dest_tazseq] = sumattr[5][dest_tazseq] + 1
		skipIIhbo:
//		end
		nohbotours:
	end
	pbar.Destroy()

	sse = 0
	totattr = 0
	for i = 1 to hh.length do
		sse = sse + Pow((sumattr[5][i] - hboattr[i]), 2)
		totattr = totattr + hboattr[i]
	end
	rmse = Sqrt(sse / hh.length)
	SetRecordValues("rmse_results", null, {{"HBO_RMSE", rmse}})
	
	//fill assigned II tours into productions_attractions table
	jointab = JoinViews("jointab", "prod_attr.TAZ", "hbodestii.DEST_TAZ", {{"A",}})
	attv = GetDataVector(jointab+"|", "[N hbodestii]", )
	SetDataVector(prod_attr+"|", "DC_II_HBO", attv, )
	CloseView("jointab")

     CloseView("hbodestii")

//**************************CREATE HBO IX TABLE *******************************************************************************************
	strct = GetTableStructure(tourrecords)
	for j = 1 to (strct.length) do
 		strct[j] = strct[j] + {strct[j][1]}
 	end
	dim newstrct[13]
	for j = 1 to 13 do							//there are 13 fields that need to copied from TourRecords.bin (not randum numbers)
		newstrct[j] = strct[j]
	end
	hbodestix = CreateTable("hbodestix", DirOutDC + "\\dcHBOext.bin", "FFB", newstrct)
	newstrct = newstrct + {{"HHID", "Integer", 7,,,,,,,,,}}
	newstrct = newstrct + {{"ORIG_TAZ", "Integer", 6,,,,,,,,,}}
	newstrct = newstrct + {{"ORIG_SEQ", "Integer", 6,,,,,,,,,}}
	newstrct = newstrct + {{"DEST_TAZ", "Integer", 6,,,,,,,,,}}
	newstrct = newstrct + {{"DEST_SEQ", "Integer", 6,,,,,,,,,}}
	newstrct = newstrct + {{"OD_Time", "Real", 8,2,,,,,,,,}}
	newstrct = newstrct + {{"DO_Time", "Real", 8,2,,,,,,,,}}
	newstrct = newstrct + {{"Purp", "Character", 3,,,,,,,,,}}

	ModifyTable(hbodestix, newstrct)

//Pull vectors sorted by randomized TAZ sets
	qry = "Select * where PURP = 'HBO' and EXT = 1" 
	SetView("temphbsodc")
	hbo_IX = SelectByQuery("hbo_IX", "Several", qry)
	tourrecordset_v = GetDataVectors(temphbsodc+"|hbo_IX", {"ID", "TAZ", "TAZ_SEQ", "SIZE", "INCOME", "LIFE", "WRKRS", "SCH", "HBU", "HBW", "HBS", "HBO", "tazrandnum"},{{"Sort Order", {{"tazrandnum","Ascending"},{"ID","Ascending"}}}}) 

	hhidset = tourrecordset_v[1]
	tourtazset = tourrecordset_v[2]
	tourtazseqset = tourrecordset_v[3]
	sizeset = tourrecordset_v[4]
	incset = tourrecordset_v[5]
	lcset = tourrecordset_v[6]
	wrkrsset = tourrecordset_v[7]
	schtoursset = tourrecordset_v[8]
	hbutoursset = tourrecordset_v[9]
	hbwtoursset = tourrecordset_v[10]
	hbstoursset = tourrecordset_v[11]
	hbotoursset = tourrecordset_v[12]
	tazrandnumset = tourrecordset_v[13]

	for n = 1 to hbo_IX do
		ixtourid = ixtourid + 1
		filltable = AddRecord("hbodestix", {{"ID", ixtourid}, {"HHID", hhidset[n]}, {"TAZ", tourtazset[n]}, {"TAZ_SEQ", tourtazseqset[n]}, {"SIZE", sizeset[n]}, {"INCOME", incset[n]}, {"LIFE", lcset[n]}, {"WRKRS", wrkrsset[n]}, 
					{"SCH", schtoursset[n]}, {"HBU", hbutoursset[n]}, {"HBW", hbwtoursset[n]}, {"HBS", hbstoursset[n]}, {"HBO", hbotoursset[n]}, {"ORIG_TAZ", tourtazset[n]}, {"ORIG_SEQ", tourtazseqset[n]}, {"PURP", "HBO"}})
	end

//******* AT-WORK TOUR FREQUENCY *********** AT-WORK TOUR FREQUENCY *********** AT-WORK TOUR FREQUENCY *********** AT-WORK TOUR FREQUENCY ***********
atwdc:
  UpdateProgressBar("Destination Choice: At-Work Tour Frequency", 10) 

hbwdestii = OpenTable("hbwdestii", "FFB", {DirOutDC + "\\dcHBW.bin",})

//Alternative percentages: 0 tours = 94.1%, 1 tour = 5.3%, 2 tours = 0.6%, 3 tours = ___%, 4 tours = ___%

//Uses the HBW DC I-I output file (hbwdestii) as the input for this step.  Sort the vectors by HHID.
//	SetView("hbwdestii")
	hbwoutfile_v = GetDataVectors(hbwdestii+"|", {"ID", "TAZ", "TAZ_SEQ", "SIZE", "INCOME", "LIFE", "WRKRS", "HHID", "DEST_TAZ", "DEST_SEQ"},{{"Sort Order", {{"HHID","Ascending"}}}})
	idhbwout = hbwoutfile_v[1]
	tazhbwout = hbwoutfile_v[2]
	taz_seqhbwout = hbwoutfile_v[3]
	inchbwout = hbwoutfile_v[5]
	wkrhbwout = hbwoutfile_v[7]
	dest = hbwoutfile_v[9]
	destseq = hbwoutfile_v[10]
	inc4hbwout = if (inchbwout = 4) then 1 else 0

//Get median income of HBW tour origin(home) zone & hh density of HBW destination (work) zone.
	dim medincval[idhbwout.length]
	dim areaval[idhbwout.length]
	dim hhval[idhbwout.length]
//	dim accE15cfr_ar[idhbwout.length]
	for n = 1 to idhbwout.length do
		origtaz = taz_seqhbwout[n]
		desttaz = dest[n]			
		if origtaz = prevtaz then do
			medincval[n] = medincval[n-1]
			hhval[n] = hhval[n-1] 
			areaval[n] = areaval[n-1]
//			accE15cfr_ar[n] = accE15cfr_ar[n-1]
		end
		else do
			medincval[n] = medinc[taz_seqhbwout[n]]
			hhval[n] = hh[destseq[n]]
			areaval[n] = area[destseq[n]]
//			accE15cfr_ar[n] = accE15cfr[taz_seqhbwout[n]]
		end
		prevtaz = origtaz
	end
	medinchbwout = a2v(medincval)
	hhhbwout = a2v(hhval)
	areahbwout = a2v(areaval)
	hhdenshbwout = hhhbwout / (areahbwout * 640)		//SE file has area in SqMiles, needs to be in acres
//	accE15cfr_v = a2v(accE15cfr_ar)
	
	U1 = -1.484 + 0.0000012 * medinchbwout

	E2U0 = Vector(idhbwout.length, "float", {{"Constant", 1}})
	E2U1 = exp(U1)						//Initial alternatives are 0, 1+ HBU tours
	E2U_cum = E2U0 + E2U1

	prob0 = E2U0 / E2U_cum
	prob1 = E2U1 / E2U_cum

	choice_v = Vector(idhbwout.length, "short", {{"Constant", 0}})	//set choice vector to 0 tours

//Do a big loop in order to sort each HH's alternatives by ascending probability.  
SetRandomSeed(358)
	for n = 1 to idhbwout.length do
		rand_val = RandomNumber()
		//if probability of 1 HBU tour is less than random number then 0 tours, else use 1+ fractions:
		//The 1+ categories are 1 (89.8% of all 1+ tours) & 2 (10.2%)
		if (rand_val >= prob0[n]) then do
			rand_val = RandomNumber()
			choice_v[n] = if (rand_val < 0.898) then 1 else 2
		end
	end
	atw_v = choice_v

	SetDataVector(hbwdestii+"|", "ATW", atw_v,{{"Sort Order", {{"HHID","Ascending"}}}})
	
	//fill total ATW productions into productions_attractions table
	jointab = JoinViews("jointab", "prod_attr.TAZ", "hbwdestii.TAZ", {{"A", }, {"Fields", {{"ATW", {{"Sum"}}}}}})
	attv = GetDataVector(jointab+"|", "ATW", )
	SetDataVector(prod_attr+"|", "P_ATW", attv, )
	CloseView("jointab")


//********************************* ATW DESTINATION CHOICE (Actually, just creating ATW files by internal and external **********************************************
  UpdateProgressBar("Destination Choice: ATW", 10) 

//This is the first run of the ATW DC model.  It does not include the X/I non-resident workers yet.
// 9/16 edit, MK; don't do destination choice at this point since we're going to redo it later in the macro after the HBW-ATWs and XIW-ATWs have been merged

//Create ATW tour II & IX destination tables

	strct = GetTableStructure(tourrecords)
	for j = 1 to strct.length do
 		strct[j] = strct[j] + {strct[j][1]}
 	end
	dim newstrct[13]
	for j = 1 to 13 do							//there are 13 fields that need to copied from TourRecords.bin (not randum numbers)
		newstrct[j] = strct[j]
	end
	atwdestii = CreateTable("atwdestii", DirOutDC + "\\dcATW.bin", "FFB", newstrct)
	atwdestix = CreateTable("atwdestix", DirOutDC + "\\dcATWext.bin", "FFB", newstrct)
	newstrct = newstrct + {{"HHID", "Integer", 6,,,,,,,,,}}
	newstrct = newstrct + {{"ORIG_TAZ", "Integer", 6,,,,,,,,,}}
	newstrct = newstrct + {{"ORIG_SEQ", "Integer", 6,,,,,,,,,}}
	newstrct = newstrct + {{"DEST_TAZ", "Integer", 6,,,,,,,,,}}
	newstrct = newstrct + {{"DEST_SEQ", "Integer", 6,,,,,,,,,}}
	newstrct = newstrct + {{"OD_Time", "Real", 8,2,,,,,,,,}}
	newstrct = newstrct + {{"DO_Time", "Real", 8,2,,,,,,,,}}
	newstrct = newstrct + {{"Purp", "Character", 3,,,,,,,,,}}
	newstrct = newstrct + {{"HBWID", "Integer", 6,,,,,,,,,}}

	ModifyTable(atwdestii, newstrct)
	ModifyTable(atwdestix, newstrct)
	
//Calculate probability that tour from this origin, for this purpose, is I/X
//	pEXT = min(3.6 * 0.29 * Pow(dist2extsta, -1.33), 0.30)
	pEXT = min(5.2 * 0.29 * Pow(dist2extsta, -1.33), 0.30)

/*mk: don't need to sort by random number here since all we're doing is dividing into external and internal files
	dim atwrandval[atwsort.length]
	rand_val = RandomNumber()
	atwrandval[1] = rand_val
	for n = 2 to atwsort.length do
		if (atwsort[n] = atwsort[n-1]) then do
			atwrandval[n] = atwrandval[n-1]
		end
		else do
			rand_val = RandomNumber()
			atwrandval[n] = rand_val
		end
	end
	atwrandval_v = a2v(atwrandval)
	SetDataVector(hbwdestii+"|havetours", "tazrandnum", atwrandval_v,{{"Sort Order", {{"DEST_SEQ","Ascending"}}}})
*/
//Pull vectors from HBW-II output file (which now has # of ATW tours)
	qry = "Select * where ATW > 0"
	SetView("hbwdestii")
	havetours = SelectByQuery("havetours", "Several", qry)
	SortSet("havetours", "DEST_SEQ, HHID")					//sort by HBW destination zone (which for ATW is origin zone)
	atwrecordset_v = GetDataVectors(hbwdestii+"|havetours", {"ID", "TAZ", "TAZ_SEQ", "SIZE", "INCOME", "LIFE", "WRKRS", "SCH", "HBU", "HBW", "HBS", "HBO", "ATW", "HHID", "DEST_TAZ", "DEST_SEQ"},) 
	hbwidset = atwrecordset_v[1]		//Here the household ID is found in the HHID field from hbwdestii
	hometazset = atwrecordset_v[2]
	hometazseqset = atwrecordset_v[3]
	sizeset = atwrecordset_v[4]
	incset = atwrecordset_v[5]
	lcset = atwrecordset_v[6]
	wrkrsset = atwrecordset_v[7]
	schtoursset = atwrecordset_v[8]
	hbutoursset = atwrecordset_v[9]
	hbwtoursset = atwrecordset_v[10]
	hbstoursset = atwrecordset_v[11]
	hbotoursset = atwrecordset_v[12]
	atwtoursset = atwrecordset_v[13]
	hhidset = atwrecordset_v[14]		//Here the household ID is found in the HHID field from hbwdestii
	atwtazset = atwrecordset_v[15]
	atwtazseqset = atwrecordset_v[16]

	iitourid = 0
	ixtourid = 0

//Loop all tours
SetRandomSeed(883)
	for n = 1 to hhidset.length do				//hhidset.length	
		if atwtoursset[n] = 0 then do			//go to next record if there are no ATW tours
			goto noatwtours
		end
		for i = 1 to atwtoursset[n] do
			rand_val = RandomNumber()
			if pEXT[atwtazseqset[n]] > rand_val then do	//create a record for this tour if it is IX
				ixtourid = ixtourid + 1
				filltable = AddRecord("atwdestix", {{"ID", ixtourid}, {"HHID", hhidset[n]}, {"TAZ", hometazset[n]}, {"TAZ_SEQ", hometazseqset[n]}, {"SIZE", sizeset[n]}, {"INCOME", incset[n]}, 
							{"LIFE", lcset[n]}, {"WRKRS", wrkrsset[n]}, {"SCH", schtoursset[n]}, {"HBU", hbutoursset[n]}, {"HBW", hbwtoursset[n]}, {"HBS", hbstoursset[n]}, 
							{"HBO", hbotoursset[n]}, {"ATW", atwtoursset[n]}, {"HBWID", hbwidset[n]}, {"ORIG_TAZ", atwtazset[n]}, {"ORIG_SEQ", atwtazseqset[n]}, {"PURP", "ATW"}})
			end
			else do
				iitourid = iitourid + 1
				filltable = AddRecord("atwdestii", {{"ID", iitourid}, {"HHID", hhidset[n]}, {"TAZ", hometazset[n]}, {"TAZ_SEQ", hometazseqset[n]}, {"SIZE", sizeset[n]}, {"INCOME", incset[n]}, 
							{"LIFE", lcset[n]}, {"WRKRS", wrkrsset[n]}, {"SCH", schtoursset[n]}, {"HBU", hbutoursset[n]}, {"HBW", hbwtoursset[n]}, {"HBS", hbstoursset[n]}, 
							{"HBO", hbotoursset[n]}, {"ATW", atwtoursset[n]}, {"HBWID", hbwidset[n]}, {"ORIG_TAZ", atwtazset[n]}, {"ORIG_SEQ", atwtazseqset[n]}, {"PURP", "ATW"}})
			end
		end
		noatwtours:
	end

//Remove the random number field from the HBW II DC file (was used for the ATW DC only).  The random number field is the last one.  
	fields_ar = GetFields("hbwdestii", null)
	num = fields_ar[1].length
	strct = GetTableStructure(hbwdestii)
	for j = 1 to (strct.length) do
 		strct[j] = strct[j] + {strct[j][1]}
 	end
	dim newstrct[num-1]
	for j = 1 to (num-1) do
		newstrct[j] = strct[j]
	end
	ModifyTable(hbwdestii, newstrct)

//***********************************************************************************************************************************************************
//Remove the random number field from the tour_records file.  The random number field is the last one.  
	fields_ar = GetFields("tourrecords", null)
	num = fields_ar[1].length
	strct = GetTableStructure(tourrecords)
	for j = 1 to (strct.length) do
 		strct[j] = strct[j] + {strct[j][1]}
 	end
	dim newstrct[num-6]	// now 6 random number fields to remove
	for j = 1 to (num-6) do
		newstrct[j] = strct[j]
	end
	ModifyTable(tourrecords, newstrct)
     CloseView("tourrecords")

//******************************** APPEND I/X TOUR FILES ***************************************************************************************************************
  UpdateProgressBar("Destination Choice: I/X", 10) 

/*	hbwdestix = OpenTable("hbwdestix", "DBASE", {DirOutDC + "\\dcHBWext.bin"}, {{"Shared", "True"}})
	schdestix = OpenTable("schdestix", "DBASE", {DirOutDC + "\\dcSCHext.bin"}, {{"Shared", "True"}})
	hbudestix = OpenTable("hbudestix", "DBASE", {DirOutDC + "\\dcHBUext.bin"}, {{"Shared", "True"}})
	hbsdestix = OpenTable("hbsdestix", "DBASE", {DirOutDC + "\\dcHBSext.bin"}, {{"Shared", "True"}})
	hbodestix = OpenTable("hbodestix", "DBASE", {DirOutDC + "\\dcHBOext.bin"}, {{"Shared", "True"}})
	atwdestix = OpenTable("atwdestix", "DBASE", {DirOutDC + "\\dcATWext.bin"}, {{"Shared", "True"}})
*/
	CopyTableFiles("hbwdestix", null, null, null,  DirOutDC + "\\dcEXT.bin",null)
	mergedix = OpenTable("mergedix", "FFB", {DirOutDC + "\\dcEXT.bin",})
	
	fields_ar = GetFields("mergedix", null)
	num = fields_ar[1].length
	dim fieldnames[num] 
	for i = 1 to num do
		fieldnames[i] = fields_ar[1][i]
	end
	addixtables = {"hbwdestix|", "schdestix|", "hbudestix|", "hbsdestix|", "hbodestix|", "atwdestix|"}
	for i = 2 to addixtables.length do								//start with SCH, as HBW already copied by CopyTableFiles
		rh = GetFirstRecord(addixtables[i], {{"ID", "Ascending"}})
		vals = GetRecordsValues(addixtables[i], rh, null, null, null, "Row", null)
		filltable = AddRecords("mergedix", fieldnames, vals, null)
	end
	id_v = GetDataVector(mergedix+"|", "ID",)
	new_id_v = Vector(id_v.length, "long", {{"Sequence", 1,1}})
	SetDataVector(mergedix+"|", "ID", new_id_v,)
	

//********************************* I/X DESTINATION CHOICE ***************************************************************************************************************

	atwdestii = OpenTable("atwdestii", "FFB", {DirOutDC + "\\dcATW.bin"}, {{"Shared", "False"}})	//just for checking
	mergedix = OpenTable("mergedix", "FFB", {DirOutDC + "\\dcEXT.bin",})
	merged_id = GetDataVector(mergedix+"|", "ID", {{"Sort Order", {{"ID","Ascending"}}}})
	tazrandnum = Vector(merged_id.length, "float", )

	//add a random number field to random sort the TAZs (otherwise get too many to certain Extstations for first number of TAZs)
	strct = GetTableStructure(mergedix)
	for j = 1 to (strct.length) do
 		strct[j] = strct[j] + {strct[j][1]}
 	end
	strct = strct + {{"tazrandnum", "Real", 10,8,,,,,,,,}}		
	ModifyTable(mergedix, strct)

//Fill in random number for each record
SetRandomSeed(984)
	for n = 1 to merged_id.length do
		rand_val = RandomNumber()
		tazrandnum[n] = rand_val
	end
	SetDataVector(mergedix+"|", "tazrandnum", tazrandnum,{{"Sort Order", {{"ORIG_SEQ","Ascending"}}}})

	ixrecordset_v = GetDataVectors(mergedix+"|", {"ORIG_TAZ", "ORIG_SEQ", "tazrandnum"},{{"Sort Order", {{"tazrandnum","Ascending"}}}})
	origtaz = ixrecordset_v[1]		
	origtazseq = ixrecordset_v[2]		
	result_v = Vector(origtaz.length, "long", )

//Note: added attraction constraint here because was getting too many IX to high-volume ext stations
//Aug. 2016, added extra constraint that caps IX volumes at any individual external station at 10% more than the ratio of total IX vehicle trip ends (2*IX tours/1.375) to total extsta volume - XX volume
	extstavoltab = OpenTable("extstavoltab", "FFA", {Dir + "\\Ext\\EXTSTAVOL" + yr_str + ".asc",})
	extstavol_v = GetDataVectors(extstavoltab+"|", {"MODEL_STA", "TOT_AUTO", "TOT_CV", "TOT_MT", "TOT_HT"},{{"Sort Order", {{"MODEL_STA","Ascending"}}}})
	extsta = extstavol_v[1]
	extstavol = extstavol_v[2]
	extstavol_ar = v2a(extstavol)		//have to do this so doesn't remove attraction from exstavol vector as well (not sure why)
	totextstavol = VectorStatistic(extstavol, "Sum",)

//Open table containing PC X/X trip ends (calculated in Tour_XX.rsc
	xxvoltab = OpenTable("xxvoltab", "FFA", {DirArray + "\\thruvol.asc",})	
	pcxx = GetDataVector(xxvoltab+"|", "auto",{{"Sort Order", {{"MODEL_STA","Ascending"}}}})
	totxxvol = VectorStatistic(pcxx, "Sum",)
	
//Calculate the maximum IX tours for each external station.  
	num_ix_tours = id_v.length	//get number of IX person tours
	num_pcix_ends = (2 * num_ix_tours / 1.375)
	max_pcixratio = (num_pcix_ends / (totextstavol - totxxvol)) + 0.10

	remain_extstavol = a2v(extstavol_ar)
	remain_extstavol = r2i(1.375 * max_pcixratio * (remain_extstavol - pcxx) / 2)	//convert from trip ends back to person trips
	extstaseq = Vector(extsta.length, "short", {{"Sequence", 1, 1}}) 

	dim htime_ar[extstavol.length]
	extsta_val = Vector(origtaz.length, "short", )
	extstaseq_val = Vector(origtaz.length, "short", )
	lasttaz = 0
	odtime_v = Vector(origtaz.length, "float", )
	dotime_v = Vector(origtaz.length, "float", )

	//create a sequential vector to add to cumulative probability vector so that when it's sorted, the correct (first) EXTSTA is chosen
	aide_de_sort_vec_ext = Vector(extstavol.length, "float", {{"Sequence", 0.001, 0.001}})

SetRandomSeed(85497)
	for n = 1 to origtaz.length do		//origtaz.length			
		if origtaz[n] = lasttaz then do			//skip the probability array creation step if already been done for this TAZ
			goto skipprobix
		end
		htimeplus = GetMatrixVector(autofreecur, {{"Row", origtaz[n]}})	//pull the TT vector for this TAZ from the free speed matrix
		counter = 1
		for i = (hh.length + 1) to htimeplus.length do	
			htime_ar[counter] = htimeplus[i]				//to keep only the external stations
			counter = counter + 1
		end
		htime = a2v(htime_ar)
		U = -0.08577 * htime + log(extstavol)		//calculate probability array (just done for first HH in this TAZ) 
		fac = if (extstavol > 0) then (remain_extstavol / extstavol) else 0	//factor exp. utile by the ratio of remaining attrs to total attrs for this external station
		eU = if (extstavol = 0) then 0 else exp(U) * fac
		sumeU = VectorStatistic(eU, "Sum",)
		prob = eU / sumeU
		vecs = {prob, extsta, extstaseq}
		cumprob1 = CumulativeVector(vecs[1])
		cumprob1[U.length] = 1

//Don't need to loop on the number of tours.  Here, each input record represents one tour.
		skipprobix:
		redo_randval_ix:
		rand_val = RandomNumber()
		if (rand_val = 0 or rand_val = 1)  then do
			goto redo_randval_ix
		end
		addnum = max(r2i(1/rand_val), 500)
		cumprob = cumprob1 / rand_val
		cumprob = if cumprob < 1.0 then addnum else cumprob
		cumprob = cumprob + aide_de_sort_vec_ext
		sorted_vecs = SortVectors({cumprob, vecs[2], vecs[3]})				
		extsta_val[n] = sorted_vecs[2][1]
		extstaseq_val[n] = sorted_vecs[3][1]
		odtime_v[n] = GetMatrixValue(autofreecur, i2s(origtaz[n]), i2s(extsta_val[n]))
		dotime_v[n] = GetMatrixValue(autofreecur, i2s(extsta_val[n]), i2s(origtaz[n]))
		remain_extstavol[extstaseq_val[n]] = max(remain_extstavol[extstaseq_val[n]] - 1, 0.0)
		lasttaz = origtaz[n]
	end
	SetDataVectors(mergedix+"|", {{"DEST_TAZ", extsta_val}, {"DEST_SEQ", extstaseq_val}, {"OD_Time", odtime_v}, {"DO_Time", dotime_v}}, {{"Sort Order", {{"tazrandnum"}}}})
	
	//fill assigned IX tours into productions_attractions table
	jointab = JoinViews("jointab", "prod_attr.TAZ", "mergedix.DEST_TAZ", {{"A",}})
	attv = GetDataVector(jointab+"|", "[N mergedix]", )
	SetDataVector(prod_attr+"|", "DC_IX", attv, )
	CloseView("jointab")

//Remove the random number field from the IX file.  The random number field is the last one.  
	fields_ar = GetFields("mergedix", null)
	num = fields_ar[1].length
	strct = GetTableStructure(mergedix)
	for j = 1 to (strct.length) do
 		strct[j] = strct[j] + {strct[j][1]}
 	end
	dim newstrct[num-1]
	for j = 1 to (num-1) do
		newstrct[j] = strct[j]
	end
	ModifyTable(mergedix, newstrct)

	// get travel time distance matrix for XI bins
	autopkdist = OpenMatrix(Dir + "\\Skims\\SPMAT_Peak.mtx", "False")			//open as memory-based
	matrix_indices = GetMatrixIndexNames(autopkdist)	
	for i = 1 to matrix_indices[1].length do
		if matrix_indices[1][i] = "Externals" then goto gotpkdistEXTindex
	end
	int_pkdistindex = CreateMatrixIndex("Externals", autopkdist, "Both", extstavoltab+"|", "MODEL_STA", "MODEL_STA" )	//just external zones
	gotpkdistEXTindex:
	for i = 1 to matrix_indices[1].length do
		if matrix_indices[1][i] = "Internals" then goto gotpkdistINTindex
	end
	int_pkdistindex = CreateMatrixIndex("Internals", autopkdist, "Both", se_vw+"|", "TAZ", "TAZ" )	//just external zones
	gotpkdistINTindex:
	autopkdistcur = CreateMatrixCurrency(autopkdist, "Length (Skim)", "Externals", "Internals", )


//********************************* SUMMARIZE I/X TOURS ***********************************************************************************************

//Sum total I/X round-trip tours by external station
	dim pcix_ar[extsta.length]
	for n =  1 to extsta.length do
		qry = "Select * where DEST_TAZ = " + i2s(extsta[n])
		SetView("mergedix")
		pcix_ar[n] = SelectByQuery("ixsta_count", "Several", qry)
	end
	pcix = a2v(pcix_ar, {{"Type", "Long"}})
	
//********************************* CALCULATE X/I TOURS ***********************************************************************************************
  UpdateProgressBar("Destination Choice: X/I", 10) 

//Open table containing PC X/X trip ends (calculated in Tour_XX.rsc
//	xxvoltab = OpenTable("xxvoltab", "FFA", {DirArray + "\\thruvol.asc",})	

//	pcxx = GetDataVector(xxvoltab+"|", "auto",{{"Sort Order", {{"MODEL_STA","Ascending"}}}})

//Multiply I/X tour ends by 2 to convert from tours to trips and divide by 1.375 to convert from person travel to vehicle travel.  [WGA] already checked and
// the result of this equation is non-negative for all stations in 2010. Analysis of 2014 external survey data said that 44% of the X/I passenger car
// trips are for work.  Apply that percentage here.  So the I/X tours are person tours and the X/I tours are vehicle tours, from this point on.
//12/2024: new % of XI trips that are work is 27% (from RSG big data, also RITIS?)

// **  NEED TO OPEN UP TABLE WITH THE 27% WORK

	pcxi = (extstavol - pcxx - (2*pcix)/1.375)/2
//	wrk = r2i(round(0.44 * pcxi,0))
	wrk = r2i(round(0.27 * pcxi,0))
	nwrk = r2i(round(pcxi - wrk,0))
	wrk = max(wrk,0)		//just in case you get a negative -- maybe can update???
	nwrk = max(nwrk,0)	

//Get number of XI workers & non-workers; create tables
	totwrk = r2i(VectorStatistic(wrk, "Sum",))
	totnwrk = r2i(VectorStatistic(nwrk, "Sum",))

	xidestwrk = CreateTable("xidestwrk", DirOutDC + "\\dcXIW.bin", "FFB", {{"ID", "Integer", 6, null, "Yes"},{"ORIG_TAZ", "Integer", 5, null,},{"ORIG_SEQ", "Integer", 3, null,},
										{"DEST_TAZ", "Integer", 5, null,},{"DEST_SEQ", "Integer", 5, null,},{"OD_Time", "Real", 8, 2,},{"DO_Time", "Real", 8, 2,},{"ATW", "Integer", 1, null,}})
	xidestnwrk = CreateTable("xidestnwrk", DirOutDC + "\\dcXIN.bin", "FFB", {{"ID", "Integer", 6, null, "Yes"},{"ORIG_TAZ", "Integer", 5, null,},{"ORIG_SEQ", "Integer", 3, null,},
										{"DEST_TAZ", "Integer", 5, null,},{"DEST_SEQ", "Integer", 5, null,},{"OD_Time", "Real", 8, 2,},{"DO_Time", "Real", 8, 2,},{"ATW", "Integer", 1, null,}})

//********************************* X/I WORK & NON-WORK DESTINATION CHOICE ***********************************************************************************************
//Get each zone's distance to closest Extsta, and open travel time distribution table
    //	dst2extsta = GetDataVector(distExtsta_vw+"|", "Len", {{"Sort Order", {{"From","Ascending"}}}}) 
 	XIW_shortdisttab = OpenTable("XIW_shortdisttab", "CSV", {DirArray + "\\HBW_XI_short.csv",})	
	LowvalshortXIW = GetDataVector(XIW_shortdisttab+"|", "Low",)
	HighvalshortXIW = GetDataVector(XIW_shortdisttab+"|", "High",)
	XIW_shortdistpctXIW = GetDataVector(XIW_shortdisttab+"|", "Percent",)
 
 	XIW_longdisttab = OpenTable("XIW_longdisttab", "CSV", {DirArray + "\\HBW_XI_long.csv",})	
	Lowvallong = GetDataVector(XIW_longdisttab+"|", "Low",)
	Highvallong = GetDataVector(XIW_longdisttab+"|", "High",)
	XIW_longdistpct = GetDataVector(XIW_longdisttab+"|", "Percent",)
 
 	XIN_shortdisttab = OpenTable("XIN_shortdisttab", "CSV", {DirArray + "\\HBO_XI_short.csv",})	
	LowvalshortXIN = GetDataVector(XIN_shortdisttab+"|", "Low",)
	HighvalshortXIN = GetDataVector(XIN_shortdisttab+"|", "High",)
	XIN_shortdistpctXIN = GetDataVector(XIN_shortdisttab+"|", "Percent",)
 
 	XIN_longdisttab = OpenTable("XIN_longdisttab", "CSV", {DirArray + "\\HBO_XI_long.csv",})	
	LowvallongXIN = GetDataVector(XIN_longdisttab+"|", "Low",)
	HighvallongXIN = GetDataVector(XIN_longdisttab+"|", "High",)
	XIN_longdistpctXIN = GetDataVector(XIN_longdisttab+"|", "Percent",)
 
//Loop all tours
SetRandomSeed(46498)
/* 	  Calculate utility & probability.  This is the HBW model, minus the INTRACO term, which cannot be calculated.  Use the high income model 
	  only.  Not trying to match attractions for this purpose.  Tweak HTIME coefficient to match external survey average trip length. (original HBW value: -0.07360)
*/
/* 12/2024: We are now using distance bins to assign eligible destination zones.  We are taking the time & distance variable out, and using the
		distance bins instead.  If the total XI volume at the station is < 1% of the total XI volume at all stations, then it is designated
		as a "Short" station, and uses that distance bin.  Otherwise, it uses the "Long" bin.
*/
	wrkcounter = 0
	nwrkcounter = 0
	extstaseq = 0
	lasttaz = 0
	for n = 1 to extsta.length do
		extstaseq = extstaseq + 1
		//start with XIW
		if wrk[n] > 0 then do
			hdist = GetMatrixVector(autopkdistcur, {{"Row", extsta[n]}})	//pull the TT vector for this TAZ from the peak speed matrix
			if wrk[n] < (totwrk * 0.1) then do	//is this a short external station
				Lowval = LowvalshortXIW
				Highval = HighvalshortXIW
				XIW_distpct = XIW_shortdistpctXIW
			end
			else do
				Lowval = LowvallongXIW
				Highval = HighvallongXIW
				XIW_distpct = XIW_longdistpctXIW
			end
			
			for i = 1 to XIW_distpct.length do
				Lowval_v = Vector(hdist.length, "Float", {{"Constant", Lowval[i]}})
				Highval_v = Vector(hdist.length, "Float", {{"Constant", Highval[i]}})
				numrec = ceil(wrk[n] * XIW_distpct[i]/100)
				bindist = if (hdist => Lowval_v and hdist < Highval_v) then 1 else 0
				U = (-0.00000001031*accE15cpk + log(ret + 1.8556*nret)) * bindist	 
				eU = exp(U)
				sumeU = VectorStatistic(eU, "Sum",)
				prob = eU / sumeU
				vecs = {prob, taz, tazseq}
				cumprob1 = CumulativeVector(vecs[1])
				cumprob1[U.length] = 1
				lasttaz = extsta[n]
				redo_randval_xiw:
				rand_val = RandomNumber()
				if (rand_val = 0 or rand_val = 1)  then do
					goto redo_randval_xiw
				end
				addnum = max(r2i(1/rand_val), 500)
				cumprob = cumprob1 / rand_val
				cumprob = if cumprob < 1.0 then addnum else cumprob
				cumprob = cumprob + aide_de_sort_vec
				sorted_vecs = SortVectors({cumprob, vecs[2], vecs[3]})				
				posUcounter = 0
				for p = 1 to U.length do
					if U[p] > 0 then do
						posUcounter = posUcounter + 1
					end
				end
				reccounter = 0
				for j = 1 to numrec do
					reccounter = reccounter + 1
					wrkcounter = wrkcounter + 1
					dest_taz = sorted_vecs[2][reccounter]
					dest_tazseq = sorted_vecs[3][reccounter]
					odtime = GetMatrixValue(autopkcurall, i2s(extsta[n]), i2s(dest_taz))
					dotime = GetMatrixValue(autopkcurall, i2s(dest_taz), i2s(extsta[n]))
					filltable = AddRecord("xidestwrk", {{"ID", wrkcounter}, {"ORIG_TAZ", extsta[n]}, {"ORIG_SEQ", extstaseq}, {"DEST_TAZ", dest_taz}, {"DEST_SEQ", dest_tazseq}, {"OD_Time", odtime}, {"DO_Time", dotime}})
					if reccounter = posUcounter then do
						reccounter = 0
					end
				end
			end
		end
		//now XIN (within same loop of external stations
		if nwrk[n] > 0 then do
			hdist = GetMatrixVector(autopkdistcur, {{"Row", extsta[n]}})	//pull the dist vector for this TAZ from the peak speed matrix
			if nwrk[n] < (totnwrk * 0.1) then do	//is this a short external station
				Lowval = LowvalshortXIN
				Highval = HighvalshortXIN
				XIN_distpct = XIN_shortdistpctXIN
			end
			else do
				Lowval = LowvallongXIN
				Highval = HighvallongXIN
				XIN_distpct = XIN_longdistpctXIN
			end
			for i = 1 to XIN_distpct.length do
				Lowval_v = Vector(hdist.length, "Float", {{"Constant", Lowval[i]}})
				Highval_v = Vector(hdist.length, "Float", {{"Constant", Highval[i]}})
				numrec = ceil(nwrk[n] * XIN_distpct[i]/100)
				bindist = if (hdist => Lowval_v and hdist < Highval_v) then 1 else 0
				U = (-0.4178*atype - 0.000000015*accE15cfr + 1.128*pct4 + log(totemp + 0.109481*pop)) * bindist	 
//				U = -0.2453*ctime - 0.4178*atype + 0.02397*dist2cbd - 0.000000015*accE15cfr + 1.128*pct4 + log(totemp + 0.109481*pop) + 0.5*cbddum	//calculate probability array (just done for first HH in this TAZ)
				eU = exp(U)
				sumeU = VectorStatistic(eU, "Sum",)
				prob = eU / sumeU
				vecs = {prob, taz, tazseq}
				cumprob1 = CumulativeVector(vecs[1])
				cumprob1[U.length] = 1
				lasttaz = extsta[n]
				redo_randval_xin:
				rand_val = RandomNumber()
				if (rand_val = 0 or rand_val = 1)  then do
					goto redo_randval_xin
				end
				addnum = max(r2i(1/rand_val), 500)
				cumprob = cumprob1 / rand_val
				cumprob = if cumprob < 1.0 then addnum else cumprob
				cumprob = cumprob + aide_de_sort_vec
				sorted_vecs = SortVectors({cumprob, vecs[2], vecs[3]})				
				posUcounter = 0
				for p = 1 to U.length do
					if U[p] > 0 then do
						posUcounter = posUcounter + 1
					end
				end
				reccounter = 0
				for j = 1 to numrec do
					reccounter = reccounter + 1
					nwrkcounter = nwrkcounter + 1
					dest_taz = sorted_vecs[2][reccounter]
					dest_tazseq = sorted_vecs[3][reccounter]
					odtime = GetMatrixValue(autopkcurall, i2s(extsta[n]), i2s(dest_taz))
					dotime = GetMatrixValue(autopkcurall, i2s(dest_taz), i2s(extsta[n]))
					filltable = AddRecord("xidestnwrk", {{"ID", nwrkcounter}, {"ORIG_TAZ", extsta[n]}, {"ORIG_SEQ", extstaseq}, {"DEST_TAZ", dest_taz}, {"DEST_SEQ", dest_tazseq}, {"OD_Time", odtime}, {"DO_Time", dotime}})
					if reccounter = posUcounter then do
						reccounter = 0
					end
				end
			end
		end
	end

	//fill assigned XIW tours into productions_attractions table
	jointab = JoinViews("jointab", "prod_attr.TAZ", "xidestwrk.DEST_TAZ", {{"A",}})
	attv = GetDataVector(jointab+"|", "[N xidestwrk]", )
	SetDataVector(prod_attr+"|", "DC_XIW", attv, )
	CloseView("jointab")

	
	//fill assigned XIN tours into productions_attractions table
	jointab = JoinViews("jointab", "prod_attr.TAZ", "xidestnwrk.DEST_TAZ", {{"A",}})
	attv = GetDataVector(jointab+"|", "[N xidestnwrk]", )
	SetDataVector(prod_attr+"|", "DC_XIN", attv, )
	CloseView("jointab")
	

//************************** APPLY ATW TOUR FREQUENCY TO X/I WORKERS *****************************************************************************************************

//This step tells us how often the non-resident workers make ATW tours while at work.

	inc4dum = 1					//income 4 dummy: let's assume that all of the X/I workers are inc 4
//	hhdens = if (area > 0) then (hh / area) else 0
	med_incdum = 58066		//We don't know the "home zone median income" value for non-residents, so use the 2010 Metrolina mean zonal value of $58,066, calculated from the 2010 S/E file
	wrkdum = 1.56		//We don't know the workers/HH for non-residents, so use the average value for Metrolina in 2010, calculated by the HH synthesis model. Because we 
				//have an X/I work trip, we know there must be at least one worker in the HH, so exclude the zero-worker HHs in this calculation = 976,538 workers / (833,570 - 206,937 HH).
	
// ** THIS SHOULD BE TOTWRK, BUT NUMBERS DON'T MATCH; NOT SURE WHY **
	desttazseq_v = GetDataVector(xidestwrk+"|", "DEST_SEQ",) 
	dim areaval[wrkcounter]
	dim hhval[wrkcounter]
	dim accE15cfr_ar[wrkcounter]
	origtaz = 0
	for n = 1 to wrkcounter do
		hhval[n] = hh[desttazseq_v[n]]
		areaval[n] = area[desttazseq_v[n]]
		accE15cfr_ar[n] = accE15cfr[desttazseq_v[n]]
	end
	hhout = a2v(hhval)
	areaout = a2v(areaval)
	accE15cfr_v = a2v(accE15cfr_ar)
	hhdens = hhout / (areaout * 640)		//SE file has area in SqMiles, needs to be in acres

	U1 = -2.659 - 0.3166*wrkdum + 0.000003801*med_incdum + 0.7615*inc4dum + 0.03204*hhdens 	// Use the accessibility of the workplace zone.

 	E2U0 = Vector(wrkcounter, "float", {{"Constant", 1}})
	E2U1 = exp(U1)						//Initial alternatives are 0, 1+ X/I ATW tours
	E2U_cum = E2U0 + E2U1

	prob0 = E2U0 / E2U_cum
	prob1 = E2U1 / E2U_cum

	choice_v = Vector(wrkcounter, "short", {{"Constant", 0}})	//reset choice vector to 0 tours

//Do a big loop in order to sort each HH's alternatives by ascending probability.  
SetRandomSeed(617)
	for n = 1 to wrkcounter do
		rand_val = RandomNumber()
		//if probability of 1 HBU tour is less than random number then 0 tours, else use 1+ fractions:
		//The 1+ categories are 1 (89.8% of all 1+ tours) & 2 (10.2%)
		if (rand_val >= prob0[n]) then do
			rand_val = RandomNumber()
			choice_v[n] = if (rand_val < 0.898) then 1 else 2
		end
	end
	atw_v = choice_v

	SetDataVector(xidestwrk+"|", "ATW", atw_v,)

//************************** MERGE RESIDENT & NON-RESIDENT WORKER ATW RECORDS ********************************************************************************************

	recnum = GetDataVector(atwdestii+"|", "ID",) 	//just to get the number of II ATW records

//select only tours from XI-Work table that have ATW tours
	qry = "Select * where ATW > 0"
	SetView("xidestwrk")
	newidnum = recnum.length + 1
	atwtours = SelectByQuery("atwtours", "Several", qry)
	SortSet("atwtours", "DEST_SEQ")
	exsta_recs = GetDataVector(xidestwrk+"|atwtours", "ORIG_TAZ",) 	
	desttaz_recs = GetDataVector(xidestwrk+"|atwtours", "DEST_TAZ",) 	
	destseq_recs = GetDataVector(xidestwrk+"|atwtours", "DEST_SEQ",) 	
	atwnum_recs = GetDataVector(xidestwrk+"|atwtours", "ATW",) 	

//For the X/I non-resident work records, we have no information about the traveller or his HH.  Fortunately, the ATW DC model does not need any data on the
// traveller or his HH. Move the external station to TAZ and the workplace to ORIG, then zero out DEST.

	for n = 1 to atwtours do
		filltable = AddRecord("atwdestii", {{"ID", newidnum}, {"TAZ", exsta_recs[n]}, {"ORIG_TAZ", desttaz_recs[n]}, {"ORIG_SEQ", destseq_recs[n]}})
		if (atwnum_recs[n] = 2) then do
			newidnum = newidnum + 1
			filltable = AddRecord("atwdestii", {{"ID", newidnum}, {"TAZ", exsta_recs[n]}, {"ORIG_TAZ", desttaz_recs[n]}, {"ORIG_SEQ", destseq_recs[n]}})
		end
		newidnum = newidnum + 1
	end
		
	ii = recnum.length
	ix = VectorStatistic(atwnum_recs, "Sum", )
	totatw = r2i(ii + ix)

//********************************* RE-APPLY ATW DESTINATION CHOICE ******************************************************************************************************

//This is the second run of the ATW DC model.  It now includes the X/I non-resident workers.

//Add random number field to merged ATW table, then sort it on the randomized workplace zone.

	strct = GetTableStructure(atwdestii)
	for j = 1 to strct.length do
 		strct[j] = strct[j] + {strct[j][1]}
 	end
	strct = strct + {{"tazrandnum", "Real", 10,8,,,,,,,,}}
	ModifyTable(atwdestii, strct)
	
	atwdestii = OpenTable("atwdestii", "FFB", {DirOutDC + "\\dcATW.bin"}, {{"Shared", "False"}})

	qry = "Select * where ID > 0"
	SetView("atwdestii")
	havetours = SelectByQuery("havetours", "Several", qry)
	SortSet("havetours", "ORIG_SEQ")					
	tourrecordset_v = GetDataVector(atwdestii+"|havetours", "ORIG_SEQ",{{"Sort Order", {{"ORIG_SEQ","Ascending"}}}}) 
	dim atwrandval[tourrecordset_v.length]
//	rand_val = RandomNumber()
//	atwrandval[1] = rand_val
SetRandomSeed(1331)
	for n = 1 to tourrecordset_v.length do
/*		if (tourrecordset_v[n] = tourrecordset_v[n-1]) then do
			atwrandval[n] = atwrandval[n-1]
		end
		else do
*/			rand_val = RandomNumber()
			atwrandval[n] = rand_val
//		end
	end
	atwrandval_v = a2v(atwrandval)
	SetDataVector(atwdestii+"|havetours", "tazrandnum", atwrandval_v,{{"Sort Order", {{"ORIG_SEQ","Ascending"}}}}) 
//now sort by random number
	SetView("atwdestii")
	sorted = SelectByQuery("sorted", "Several", qry)
	SortSet("sorted", "tazrandnum")					
	tourrecordset_v = GetDataVectors(atwdestii+"|", {"ORIG_TAZ","ORIG_SEQ","tazrandnum"} ,{{"Sort Order", {{"tazrandnum","Ascending"}}}}) 
	tourtazset = tourrecordset_v[1]
	tourtazseqset = tourrecordset_v[2]

	lasttaz = 0
	dim dest_taz[tourtazset.length]
	dim dest_tazseq[tourtazset.length]
	odtime_v = Vector(tourtazset.length, "float", )
	dotime_v = Vector(tourtazset.length, "float", )

//Must increase the number of ATW trip ends, to account for the non-resident workers. Use the "ii" and "xi" variables computed in the previous step.  
	tend = atwattr * (ii + ix) / ii
	remain_v = tend
//reset sum of ATW attractions for each zone to zero 
	sumattr[6] = Vector(hh.length, "short", {{"Constant", 0}})

//Loop all tours
//This time, don't calculate I/X tours.  The input resident ATW tours have already been calculated as I/I and the input non-resident workers are assumed to not make I/X ATW tours.
SetRandomSeed(3113)
	for n = 1 to tourtazset.length do				
		thistaz = tourtazset[n]
		if thistaz = lasttaz then do			//skip the probability array creation step if already been done for this TAZ
			goto skipprobatwiiix
		end
		thistazseq = tourtazseqset[n]
		thiscnty = stcnty[thistazseq]
		thisAT = atype[thistazseq]
		intraco = if (stcnty = thiscnty) then 1 else 0
		//intrazonal = if (taz <> thistaz) then 0 else if (thisAT < 3) then 0.8 else if (thisAT < 5) then 2.0 else 1.0	//changed for validation
		intrazonal = if (taz <> thistaz) then 0 else 1
		ctime = GetMatrixVector(compintcurarray[4], {{"Row", thistaz}})	//pull the TT vector for this TAZ from the free speed matrix
		//U = -0.3148*ctime - 0.3274*atype - 0.00000001045*accE15cfr + log(nret + 4.5676*ret + 0.1475*pop) - 0.58*intrazonal  - 0.33*cbddum - 0.80*intraco
		U = -0.312*ctime - 0.00000681*accE15cfr + 0.801*log(nret + 11.36*ret) + 0.536*intrazonal  + 0.902*cbddum + 0.289*intraco	
		//factor exp. utile by the ratio of remaining attrs to total attrs for this dest zone, but with a minimun ratio of 0.01 so that no zone truly runs out of attractions
		fac = if (atwattr > 0) then max((remain_v / atwattr), 0.01) else 0	 
		eU = exp(U) * fac
		sumeU = VectorStatistic(eU, "Sum",)
		prob = eU / sumeU
		vecs = {prob, taz, tazseq}
		cumprob1 = CumulativeVector(vecs[1])
		cumprob1[U.length] = 1
		lasttaz = thistaz
		skipprobatwiiix:
		redo_randval_atwiiix:
		rand_val = RandomNumber()
		if (rand_val = 0 or rand_val = 1)  then do
			goto redo_randval_atwiiix
		end
		addnum = max(r2i(1/rand_val), 500)
		cumprob = cumprob1 / rand_val
		cumprob = if cumprob < 1.0 then addnum else cumprob
		cumprob = cumprob + aide_de_sort_vec
		sorted_vecs = SortVectors({cumprob, vecs[2], vecs[3]})				
		dest_taz[n] = sorted_vecs[2][1]
		dest_tazseq[n] = sorted_vecs[3][1]
		odtime_v[n] = GetMatrixValue(autofreeintcur, i2s(thistaz), i2s(dest_taz[n]))
		dotime_v[n] = GetMatrixValue(autofreeintcur, i2s(dest_taz[n]), i2s(thistaz))
		remain_v[dest_tazseq[n]] = max(remain_v[dest_tazseq[n]] - 1, 0)	//this removes one attraction from destination zone for each tour
		sumattr[6][dest_tazseq[n]] = sumattr[6][dest_tazseq[n]] + 1
	end
	dest_taz_v = a2v(dest_taz)
	dest_tazseq_v = a2v(dest_tazseq)
	SetDataVector(atwdestii+"|sorted", "DEST_TAZ", dest_taz_v,{{"Sort Order", {{"tazrandnum","Ascending"}}}}) 
	SetDataVector(atwdestii+"|sorted", "DEST_SEQ", dest_tazseq_v,{{"Sort Order", {{"tazrandnum","Ascending"}}}}) 
	SetDataVector(atwdestii+"|sorted", "OD_Time", odtime_v,{{"Sort Order", {{"tazrandnum","Ascending"}}}}) 
	SetDataVector(atwdestii+"|sorted", "DO_Time", dotime_v,{{"Sort Order", {{"tazrandnum","Ascending"}}}}) 

	sse = 0
	totattr = 0
	for i = 1 to hh.length do
		sse = sse + Pow((sumattr[6][i] - atwattr[i]), 2)
		totattr = totattr + atwattr[i]
	end
	rmse = Sqrt(sse / hh.length)
	SetRecordValues("rmse_results", null, {{"ATW_RMSE", rmse}})
//showmessage("ATW rmse = " + r2s(rmse))

//Remove the random number field from the ATW II DC file.  There are 22 fields to keep (includes HBWID for feedback).  
	strct = GetTableStructure(atwdestii)
	for j = 1 to (strct.length) do
 		strct[j] = strct[j] + {strct[j][1]}
 	end
	dim newstrct[22]
	for j = 1 to 22 do
		newstrct[j] = strct[j]
	end
	ModifyTable(atwdestii, newstrct)
	
	//fill assigned II tours into productions_attractions table
	jointab = JoinViews("jointab", "prod_attr.TAZ", "atwdestii.DEST_TAZ", {{"A",}})
	attv = GetDataVector(jointab+"|", "[N atwdestii]", )
	SetDataVector(prod_attr+"|", "DC_II_ATW", attv, )
	CloseView("jointab")

	SetMatrixIndex(autopk, "Rows", "Columns")
	SetMatrixIndex(autofree, "Rows", "Columns")

	DeleteMatrixIndex(autopk, "Internals")
	DeleteMatrixIndex(autofree, "Internals")

	CloseMatrixFileHandle(autopk)
	CloseMatrixFileHandle(autofree)

   	DestroyProgressBar()
    RunMacro("G30 File Close All")

    goto quit

	badquit:
		on error, notfound default
		RunMacro("TCB Closing", ret_value, "TRUE" )
		Throw("Tour Destination Choice: Error somewhere")
		AppendToLogFile(1, "Tour Destination Choice: Error somewhere")
		datentime = GetDateandTime()
		AppendToLogFile(1, "Tour Destination Choice " + datentime)

       	return({0, msg})

    quit:
		on error, notfound default
   		datentime = GetDateandTime()
		AppendToLogFile(1, "Exit Tour Destination Choice " + datentime)
    	return({1, msg})
		
skiptoend:
endmacro