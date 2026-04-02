Macro "Tour_TruckTGTD" (Args)

// 1/19, mk: This model replicates the current (MRM18v1.1) trip model for commercial vehicles (COM, MTK, HTK) up to TOD2.
//		Includes trip generation, EE trips, trip distribution, and transposing TD files for TOD2.

	// on error goto badquit
	// LogFile = Args.[Log File].value
	// ReportFile = Args.[Report File].value
	// SetLogFileName(LogFile)
	// SetReportFileName(ReportFile)
	
	sedata_file = Args.[LandUse file]
	Dir = Args.[Run Directory]
	MetDir = Args.[MET Directory]
	theyear = Args.[Run Year]
	msg = null
	datentime = GetDateandTime()
	AppendToLogFile(1, "Tour Truck Model: " + datentime)
	RunMacro("TCB Init")

	RunMacro("G30 File Close All") 

	DirTG  = Dir + "\\TG"
 	
 	yr_str = Right(theyear,2)
	yr = s2i(yr_str)



  CreateProgressBar("Tour Truck Model", "TRUE")

// ************************************************************************************

// ************ Trip Generation (from Trip model) *******************************************

//Open tables, networks & matrices and pull data
	se_vw = OpenTable("SEFile","FFB", {sedata_file,})
	areatype = OpenTable("areatype", "FFB", {Dir + "\\landuse\\SE" + theyear + "_DENSITY.bin",})  
	distExtsta_vw = OpenTable("distextsta", "FFA", {Dir + "\\Ext\\Dist_to_Closest_ExtSta.asc",})
	basvol_vw = OpenTable("basvol", "FFA", {MetDir + "\\ExtSta\\extstavol.asc",})
	bthruv_vw = OpenTable("bthruv", "FFA", {MetDir + "\\ExtSta\\bvthru.asc",})
	stavol_vw = OpenTable("stavol", "FFA", {Dir + "\\ext\\extstavol" + yr_str + ".asc",})
//	distCBD_vw = OpenTable("distcbd", "FFA", {Dir + "\\LandUse\\Dist_to_CBD.asc",})  //(no longer used)

	se_v = GetDataVectors(se_vw+"|", {"TAZ", "HH", "POP_HHS", "LOIND", "HIIND", "RTL", "HWY", "OFFGOV", "TOTEMP", "SEQ", "LOSVC", "HISVC", "EDUC", "AREA"},{{"Sort Order", {{"TAZ","Ascending"}}}, {"Return Options Array", "True"}})
	popemp = se_v.POP_HHS + se_v.TOTEMP
	retail = se_v.RTL + se_v.HWY
	service = se_v.LOSVC + se_v.HISVC + se_v.OFFGOV + se_v.EDUC
//	nonindemp = Max(retail + hwy + losvc + hisvc + educ, 1)
	indemp = se_v.LOIND + se_v.HIIND
//	tpop = Max(pop, 1)

	dst2extsta = GetDataVector(distExtsta_vw+"|", "Len", {{"Sort Order", {{"From","Ascending"}}}}) 
//	dst2cbd = GetDataVector(distCBD_vw+"|", "Len", {{"Sort Order", {{"From","Ascending"}}}}) 
	//to get rid of external stations:
	dim dist2extsta_ar[se_v.TAZ.length]
//	dim dist2cbd_ar[taz.length]
	for i =  1 to se_v.TAZ.length do		//create a intracounty vector with all TAZs = 0 except for this TAZ (=1)
		dist2extsta_ar[i] = dst2extsta[i]
//		dist2cbd_ar[i] = dst2cbd[i]
	end
	dist2extsta = a2v(dist2extsta_ar)
//	dist2cbd = a2v(dist2cbd_ar)

	basvol_v = GetDataVectors(basvol_vw+"|", {"TOT_CV", "TOT_MT", "TOT_HT", "MODEL_STA"},{{"Sort Order", {{"MODEL_STA","Ascending"}}}})
	extsta = basvol_v[4]
	extstastartseq = se_v.TAZ.length + 1
	extstaseq = Vector(extsta.length, "short", {{"Sequence", extstastartseq, 1}}) 	//start extsta sequence after internal zones

	bthruv_v = GetDataVectors(bthruv_vw+"|", {"com", "mtk", "htk"},{{"Sort Order", {{"MODEL_STA","Ascending"}}}})

	stavol_v = GetDataVectors(stavol_vw+"|", {"TOT_CV", "TOT_MT", "TOT_HT"},{{"Sort Order", {{"MODEL_STA","Ascending"}}}})

	taz_ar = v2a(se_v.TAZ)
	extsta_ar = v2a(extsta)
	extstaseq_ar = v2a(extstaseq)
	tottaz = taz_ar + extsta_ar
	tottaz_v = a2v(tottaz)
	tazseq_ar = v2a(se_v.SEQ)
	tottazseq = tazseq_ar + extstaseq_ar
	tottazseq_v = a2v(tottazseq)

vt_ar = {"COM", "MTK", "HTK"}

//Create table to store total number of tours for each truck type and internal/external combination
	trucktab = CreateTable("trucktab", DirTG + "\\trucktable.bin", "FFB", {{"TAZ","Integer", 5, null, "No"}, {"SEQ","Integer", 5, null, "No"}, 
			{"COM_PROD_II","Real", 9, 4, "No"}, {"COM_PROD_IX","Real", 9, 4, "No"}, {"COM_PROD_XI","Real", 9, 4, "No"}, 
			{"MTK_PROD_II","Real", 9, 4, "No"}, {"MTK_PROD_IX","Real", 9, 4, "No"}, {"MTK_PROD_XI","Real", 9, 4, "No"}, 
			{"HTK_PROD_II","Real", 9, 4, "No"}, {"HTK_PROD_IX","Real", 9, 4, "No"}, {"HTK_PROD_XI","Real", 9, 4, "No"}, 
			{"COM_ATTR_II","Real", 9, 4, "No"}, {"COM_ATTR_IX","Real", 9, 4, "No"}, {"COM_ATTR_XI","Real", 9, 4, "No"}, 
			{"MTK_ATTR_II","Real", 9, 4, "No"}, {"MTK_ATTR_IX","Real", 9, 4, "No"}, {"MTK_ATTR_XI","Real", 9, 4, "No"}, 
			{"HTK_ATTR_II","Real", 9, 4, "No"}, {"HTK_ATTR_IX","Real", 9, 4, "No"}, {"HTK_ATTR_XI","Real", 9, 4, "No"}})
	rh = AddRecords("trucktab", null, null, {{"Empty Records", tottaz_v.length}})
	SetDataVector(trucktab+"|", "TAZ", tottaz_v,)
	SetDataVector(trucktab+"|", "SEQ", tottazseq_v,)

//Create xxfactor table 
	xxfactab = CreateTable("xxfactab", DirTG + "\\xxfactor.bin", "FFB", {{"STATION","Integer", 5, null, "No"}, 
			{"COM_FACTOR","Real", 6, 3, "No"}, {"MTK_FACTOR","Real", 6, 3, "No"}, {"HTK_FACTOR","Real", 6, 3, "No"}})
	rh = AddRecords("xxfactab", null, null, {{"Empty Records", extsta.length}})
	SetDataVector(xxfactab+"|", "STATION", extsta,)

	//factors & coefficients:
	//Area type adjustment factor, 
//	atfacta = 1.0	//Since all area type factors are 1.0 for now
	tfactor = 1.0
	
	//Aug. 2024:  Gallup added atfacta=0.5 for AT 1 & atfacta=0.25 for AT 2


	strct = GetTableStructure(areatype, {{"Include Original", "True"}})

	// Add a field for AFACTA

	strct = strct + {{"ATFACTACOM", "Real", 12, 2, "False", , , , , , , null}}
	strct = strct + {{"ATFACTAMTK", "Real", 12, 2, "False", , , , , , , null}}
	strct = strct + {{"ATFACTAHTK", "Real", 12, 2, "False", , , , , , , null}}
	// Modify the table

	ModifyTable(areatype, strct)


		vw1 = "areatype"

	//Fill ATFACTA based on area type
		ptr = GetFirstRecord("areatype|",)
		while ptr <> null do
	
			if vw1.AREATYPE> 2 
				then vw1.ATFACTACOM = 1.0 
			if vw1.AREATYPE = 1
				then vw1.ATFACTACOM = 1.0 
			if vw1.AREATYPE = 2
				then vw1.ATFACTACOM = 1.0 

			ptr = GetNextRecord("areatype|",,)
		end

		ptr = GetFirstRecord("areatype|",)
		while ptr <> null do
	
			if vw1.AREATYPE> 2 
				then vw1.ATFACTAMTK = 1.0 
			if vw1.AREATYPE = 1
				then vw1.ATFACTAMTK = 0.5
			if vw1.AREATYPE = 2
				then vw1.ATFACTAMTK = 0.25
		
			ptr = GetNextRecord("areatype|",,)
		end

		ptr = GetFirstRecord("areatype|",)
		while ptr <> null do
	
			if vw1.AREATYPE> 2 
				then vw1.ATFACTAHTK = 1.2
			if vw1.AREATYPE = 1
				then vw1.ATFACTAHTK = 0.15
			if vw1.AREATYPE = 2
				then vw1.ATFACTAHTK = 0.25
		
			ptr = GetNextRecord("areatype|",,)
		end

	areatype_v = GetDataVectors(areatype+"|", {"TAZ", "ZAREA", "EMPTOT", "HHPOP", "EMPDEN", "POPDEN", "AREATYPE", "ATFACTACOM", "ATFACTAMTK", "ATFACTAHTK"},{{"Sort Order", {{"TAZ","Ascending"}}}})


//Aug. 2024:  Gallup added atfacta=0.5 for AT 1 & atfacta=0.25 for AT 2

strct = GetTableStructure(areatype, {{"Include Original", "True"}})

// Add a field for AFACTA

strct = strct + {{"ATFACTACOM", "Real", 12, 2, "False", , , , , , , null}}
strct = strct + {{"ATFACTAMTK", "Real", 12, 2, "False", , , , , , , null}}
strct = strct + {{"ATFACTAHTK", "Real", 12, 2, "False", , , , , , , null}}
// Modify the table

ModifyTable(areatype, strct)


	vw1 = "areatype"

//Fill ATFACTA based on area type
	ptr = GetFirstRecord("areatype|",)
	while ptr <> null do
  
		if vw1.AREATYPE> 2 
			then vw1.ATFACTACOM = 1.0 
		if vw1.AREATYPE = 1
			then vw1.ATFACTACOM = 1.0 
		if vw1.AREATYPE = 2
			then vw1.ATFACTACOM = 1.0 

		ptr = GetNextRecord("areatype|",,)
	end

	ptr = GetFirstRecord("areatype|",)
	while ptr <> null do
  
		if vw1.AREATYPE> 2 
			then vw1.ATFACTAMTK = 1.0 
		if vw1.AREATYPE = 1
			then vw1.ATFACTAMTK = 0.5
		if vw1.AREATYPE = 2
			then vw1.ATFACTAMTK = 0.25
	
		ptr = GetNextRecord("areatype|",,)
	end

	ptr = GetFirstRecord("areatype|",)
	while ptr <> null do
  
		if vw1.AREATYPE> 2 
			then vw1.ATFACTAHTK = 1.2
		if vw1.AREATYPE = 1
			then vw1.ATFACTAHTK = 0.15
		if vw1.AREATYPE = 2
			then vw1.ATFACTAHTK = 0.25
	
		ptr = GetNextRecord("areatype|",,)
	end

areatype_v = GetDataVectors(areatype+"|", {"TAZ", "ZAREA", "EMPTOT", "HHPOP", "EMPDEN", "POPDEN", "AREATYPE", "ATFACTACOM", "ATFACTAMTK", "ATFACTAHTK"},{{"Sort Order", {{"TAZ","Ascending"}}}})


/*	arate =  { {0.146, 0.099, 0.038},	//hh
		   {0.000, 0.000, 0.000},	//pop_hhs
		   {0.454 ,0.266, 0.139},	//loind
		   {0.454 ,0.266, 0.139},	//hiind
		   {0.501, 0.253, 0.065},	//rtl
		   {0.501, 0.253, 0.065},	//hwy
		   {0.454, 0.068, 0.009},	//losvc
		   {0.454, 0.068, 0.009},	//hisvc
		   {0.454, 0.068, 0.009},	//offgov
		   {0.454, 0.068, 0.009},	//educ
		   {0.000, 0.000, 0.000},	//stuk8
		   {0.000, 0.000, 0.000},	//stuhs
		   {0.000, 0.000, 0.000},	//stucu
		   {0.000, 0.000, 0.000},	//dens
		   {0.000, 0.000, 0.000},	//medinc
		   {0.000, 0.000, 0.000} }	//cbd
*/
	//'ARATE' array: attraction model coefficients. This is derived from the 2012 survey. Also note that the NHB and Truck coefficients
	//  have already been cut in half (from their originally calibrated values) to convert total trip ends to true attractions.  See AttrResults.xls.
	//	      com    mtk    htk	   
/*	arate =  { {0.146, 0.099, 0.038},	//se_v.HH
		   {0.454 ,0.266, 0.139},	//indemp (loind + hiind)
		   {0.501, 0.253, 0.065},	//retail (ret + hwy)
		   {0.454, 0.068, 0.009} }	//service (losvc + hisvc + offgov + educ)
*/
	//summer 2024:  TRMG2 rates replace previous MRM rates
	arate =  { {0.218, 0.086, 0.028},	//se_v.HH
		   {0.087 ,0.226, 0.100},	//indemp (loind + hiind)
		   {0.774, 0.220, 0.048},	//retail (ret + hwy)
		   {0.383, 0.059, 0.007} }	//service (losvc + hisvc + offgov + educ)	
		
	//'EXTADJ' array: adjustments to external share models, in order to make the base year (2010) estimates match the cordon counts.
	//  to make the base year (2010) estimates match the cordon counts.
	//  Array is (vehicle type 1-5, direction 1-2), where direction 1 is I/E and direction 2 is E/I.
	//	      com    mtk    htk	   
//	extadj =  { {0.3600, 0.9050, 3.2500},	// I/E
//		    {0.2134, 0.5390, 1.4500} }	// E/I	
	extadj =  { {0.4772, 0.7798, 5.3757},	// I/E
		    {0.1491, 0.2673, 1.4012} }	// E/I
	dim extpct[3]
 
  //Loop on vehicle type: VT1 = commercial, VT2 = MT, VT3 = HT.  This includes I/I + I/X.
	for vt = 1 to 3 do	//3
   UpdateProgressBar("Tour Truck Model (Generation: " + vt_ar[vt] + ")", 10) 
			// Commercial and Truck productions (= attractions).  Store them all as "income 1".  Apply Attraction area type adjustment. (line 190)
 	if vt=1 then do 
 		atfacta = areatype_v[8]
 	end
 	if vt=2 then do 
 		atfacta = areatype_v[9]
	end
	if vt=3 then do 
		atfacta = areatype_v[10]
	end
		prod_int = (se_v.HH * arate[1][vt] + indemp * arate[2][vt] + retail * arate[3][vt] + service * arate[4][vt]) * atfacta* tfactor
//	  end
		//Apply I/E model to split productions into I/I and I/E.  I/E model estimates the % of total productions that are externally attracted,
		// as an exponential function of the zone's distance to the cordon. Model was calibrated from 2012 survey data; see iemodel.xlsx.
		// If that distance is 0.0, can't do the exponentiation, so just set the external share to 100%.  Calculate 2 percents: Work and
		// Non-work.  Start with the Work share for COM/MTK/HTK, then change it to match the cordon count data.  External trips are
		// all "income 1".  Last term in "EXTPCT" equations is a final adjustment to get the proper regional total I/E trips. (line 2413)
	
		extpct[vt] = if (dist2extsta < 0.0001) then 1.0000 else (1.31 * Pow(dist2extsta, -1.47) * extadj[1][vt])
		extpct[vt] = if (extpct[vt] > 0.95) then 0.95 else extpct[vt]
	
		ixprod_int = prod_int * extpct[vt]		// (line 2443)
		iiprod_int = prod_int * (1.0 - extpct[vt])	// (line 2467)
		
		//Before removing the I/E's, sum the productions by purpose and income for later use.
          	tprod = VectorStatistic(prod_int, "Sum",)		// (line 2452)
          	
		//Sum regional trip productions by purpose and income.  Sum them by I/I (for later use in normalization) and 
		// by I/E (for later use in cordon allocation).  (line 2485)
		totiiprod = VectorStatistic(iiprod_int, "Sum",)
		totextprod = VectorStatistic(ixprod_int, "Sum",)

		//Now, on to attractions. For the NHB and Truck purposes (6-11), the originally calibrated attraction model coefficients have been already divided by 2,
		// in order to convert total trip ends to true attractions. Also, adjust attractions by Area Type and factor in the global adjustment factor.
		
		attr_int = (se_v.HH * arate[1][vt] + indemp * arate[2][vt] + retail * arate[3][vt] + service * arate[4][vt]) * atfacta* tfactor
		
		//Sum total attractions by purpose.  Do this twice to help the normalization calculation, below.	 (line 2575)
		tattr1 = VectorStatistic(attr_int, "Sum",)
		tattr2 = VectorStatistic(attr_int, "Sum",)
		
		//Some of the attraction models contain negative coefficients and this may result in negative attractions being calculated for
		// some zones.  For such zones, set attractions to zero and normalize the rest of the zones' attractions to match the correct regional total	 (line 2601)	
		attr_int = if (attr_int < 0.0) then 0.0 else attr_int
		tattr2 = VectorStatistic(attr_int, "Sum",)		
		attr_int = attr_int * tattr1 / tattr2		// (line 2707)
		tattr3 = VectorStatistic(attr_int, "Sum",)	// (line 2808)	
		
		//Apply E/I model to calculate E/I attractions.  E/I model estimates the % of total attractions that are externally produced,
		// as a parabolic function of the zone's distance to the cordon.  This is slightly different than the I/E model.  The I/E model splits
		// total productions into I/E and I/I: 
		//   I/E prod = total prod * I/E%
		//   I/I prod = total prod * (1 - I/E%)
		// In the case of E/I trips, we don't have the total to start with,
		// only the I/I value.  Thus, the equations become:
		//  total attr = I/I attr / (1 - E/I%)
		//  E/I attr   = total attr * E/I%
		//  or: E/I attr   = I/I attr * E/I% / (1 - E/I%)	 (line 2812)
		//Set an arbitrary upper limit of 75% on the E/I share.
		 extw = 0.55 - 0.057 * dist2extsta + 0.0015 * dist2extsta * dist2extsta
		extw = if (extw > 0.75) then 0.75 else extw		
		
		//Use the Work E/I fractions for COM/truck, modified to match the base year cordon data.  Use different upper limit here: 95% E/I. Again, somewhat arbitrary. (line 2844)		
		extpct[vt] = extw * extadj[2][vt]		
		extpct[vt] = if (extpct[vt] > 0.95) then 0.95 else extpct[vt]		
		
		xiattr_int = attr_int * extpct[vt] / (1.0 - extpct[vt])

		//Sum regional I/I attractions for later use in normalization.  Sum regional E/I person attractions for later use in cordon allocation. (line 2874)
          	totiiattr = VectorStatistic(attr_int, "Sum",)
          	totextattr = VectorStatistic(xiattr_int, "Sum",)	

		/* Now, we must allocate the I/E attractions and the E/I productions among the external stations.  This is done in proportion to the
		C  estimated future total daily External (I/E + E/I) 2-way volume at each station.  These volumes are handled separately, by type.
		C We start by calculating an estimated External volume at each external station.  This is the total input volume, multiplied by
		c  the base year E/E trip share, by station and type.  These volumes are used to allocate the I/E attractions to the stations and the
		c  E/I productions to the stations.  Then, we calculate the actual future E/E volume by station as the input total, less the I/E attrs,
		c  less the E/I prods.  Then, calculate the E/E growth factors as the ratio of future to base 2000 E/E volume, by station.
		c All calculations are stratified by 1 of 2 vehicle type groupings:
		c  TYPE4: 1=auto (PC), 2=COM, 3=MTK, 4=HTK.
		c  TYPE5: 1=work auto, 2=nonwk auto, 3=COM, 4=MTK, 5=HTK.
		
		C Here is where the resulting numbers are stored:
		c  BASVOL(type4,station)        base 2000 total cordon volume (veh)
		c  STAVOL(type4,station)        input forecast yr tot cordon vol (veh)
		c  BTHRUV(type4,station)        base 2000 E/E trip volume (veh)
		c  BTHRUP(type4,station)        base 2000 E/E trip share (fraction)
		c  EXTVOL(type5,station)        initial fcast yr external volume (veh)
		c  TOTEXT(type5)                total initial fcast yr ext vol (veh)
		c  EXTPROD(type5,station)       final fcast yr external prods (psn)
		c  EXTATTR(type5,station)       final fcast yr external attrs (psn)
		c  STATRIPENDS(type5,station)   final fcast yr ext trip ends (veh)
		c  FTHRUV(type4,station)        forecast year E/E trip volume (veh)
		c  XXFACT(type4,station)        forecast year E/E trip factor
		
		C First, calculate initial estimate of E/E trips by station, using the Base year data. Then, calculate each station's share of the initial
		c  future I/E + E/I cordon volume by vehicle type, and sum it by type.
		*/
		
		bthrup =  if (basvol_v[vt] > 0.0) then (bthruv_v[vt] / basvol_v[vt]) else 0	// (line 3017)
		extvol = basvol_v[vt] * (1.0 - bthrup)
		totext = VectorStatistic(extvol, "Sum",)

		//Zero out the I/I cells of the PROD and ATTR arrays.  (line 3048)
//		 prod_int = 0.0
//		 attr_int = 0.0
		 
		 //Allocate I/E attractions and E/I productions to stations, by vehicle type. Divide person trips in cars by 
		 // average external vehicle occupancy to get vehicle trips.  Sum trip ends across purposes.  (line 3069)
		extattr = totextprod * extvol / totext
		extprod = totextattr * extvol / totext
		statripends = extattr + extprod

		 //Store the cordon station external person trip ends in the PROD and ATTR arrays.  Put them all in Income 1. (line 3087)
		xiprod = extprod
		ixattr = extattr


		 //Here we calculate the E/E vehicle trip growth factors, as follows:
		//   1) Future Through Trip Ends = Future Total Cordon Veh. Trip Ends - Future External Veh. Trip Ends
		//   2) Growth Factor = Future Through Veh. Trip Ends / Base Through Veh. Trip Ends
		//  This is done separately by vehicle type (TYPE4), for each external station, but not separately by direction. (line 3107)
		fthruv = stavol_v[vt] - statripends
		xxfact = if (bthruv_v[vt] > 0.01) then (fthruv / bthruv_v[vt]) else 1.0
		//need to add a message if any are negative.  Reset to zero if are
//		xxfact = if (fthruv > 0.0) then xxfact else 1.0
		fthruv = if (fthruv > 0.0) then fthruv else 0.0

		SetDataVector(xxfactab+"|", vt_ar[vt] + "_FACTOR", xxfact,)
		
		 //Rewind production and attraction files and start ninth loop to normalize I/I trip ends.  Normalize I/I HB trips to the
		 // production total, by income.  For the NHB purposes, force the attraction total to equal the production total.  Then set the
		 // productions by zone equal to the adjusted attractions by zone. Normalization should not be needed for COM and truck trips, but
		 // do it anyway just to be safe. Also, apply the non-resident NHB adjustment factor. The '3800' loop covers internal zones only.
 		tempp = totiiprod
 		tempa = totiiattr
 		attr_int = if (tempa < 0.001) then attr_int else attr_int * tempp / tempa


		 // Create output Production/Attraction files.  First, write Productions.  For the 6 NHB/COM/truck purposes, Productions are defined as equal to Attractions.
		//add internals and externals to make right size. Make sure type match to concatenate
		zero_internal_v = Vector(se_v.TAZ.length, "float", {{"Constant", 0.0}})
		zero_external_v = Vector(fthruv.length, "float", {{"Constant", 0.0}})

		concate_ar = {{iiprod_int,zero_external_v}, {ixprod_int,zero_external_v}, {zero_internal_v,xiprod}, 
			{attr_int,zero_external_v}, {zero_internal_v,ixattr}, {xiattr_int,zero_external_v}} 
		dim prod_attr_out[6]	//(prod_tot_ii, prod_tot_ix, prod_tot_xi, attr_tot_ii, attr_tot_ix, attr_tot_xi)
		for i = 1 to concate_ar.length do
			vec1 = concate_ar[i][1]
			vec2 = concate_ar[i][2]
			if (vec1.type = vec2.type) then do
				prod_attr_out[i] = ConcatenateVectors({concate_ar[i][1],concate_ar[i][2]})
			end
			else if (vec1.type <> "float") then do	//need a ext.length vector of that type
				tyypeof = vec1.type//vec1.type
				zero_ext_v = Vector(fthruv.length, tyypeof, {{"Constant", 0.0}})
				prod_attr_out[i] = ConcatenateVectors({concate_ar[i][1],zero_ext_v})
			end
			else do
				tyypeof = vec2.type
				zero_int_v = Vector(se_v.TAZ.length, tyypeof, {{"Constant", 0.0}})
				prod_attr_out[i] = ConcatenateVectors({zero_int_v,concate_ar[i][2]})
			end
		end			

/*		prod_tot_ii = ConcatenateVectors({iiprod_int,zero_external_v})
		prod_tot_ix = ConcatenateVectors({ixprod_int,zero_external_v})
		prod_tot_xi = ConcatenateVectors({zero_internal_v,xiprod})
		attr_tot_ii = ConcatenateVectors({attr_int,zero_external_v})
		attr_tot_ix = ConcatenateVectors({zero_internal_v,ixattr})
		attr_tot_xi = ConcatenateVectors({xiattr_int,zero_external_v})
*/
		SetDataVector(trucktab+"|", vt_ar[vt] + "_PROD_II", prod_attr_out[1],)
		SetDataVector(trucktab+"|", vt_ar[vt] + "_PROD_IX", prod_attr_out[2],)
		SetDataVector(trucktab+"|", vt_ar[vt] + "_PROD_XI", prod_attr_out[3],)
		SetDataVector(trucktab+"|", vt_ar[vt] + "_ATTR_II", prod_attr_out[4],)
		SetDataVector(trucktab+"|", vt_ar[vt] + "_ATTR_IX", prod_attr_out[5],)
		SetDataVector(trucktab+"|", vt_ar[vt] + "_ATTR_XI", prod_attr_out[6],)
	end
    RunMacro("G30 File Close All")

// ************************************************************************************

// ************ EE_Trips (from Trip model)  *******************************************

// ************************************************************************************

// Moved from Trip Gen macro - Aug 2015
// Moved EE trip tables (TDeeA, TDeeC, TDeeM, TDeeH) from TG subdirector to TD subdirectory

	// LogFile = Args.[Log File].value
	// SetLogFileName(LogFile)
	// ReportFile = Args.[Report File].value
	// SetReportFileName(ReportFile)

	METDir = Args.[MET Directory]
	Dir = Args.[Run Directory]
	sedata_file = Args.[LandUse File]
	theyear = Args.[Run Year]
	yearnet = right(theyear,2)
	msg = null
	TripGenOK = 1

	datentime = GetDateandTime()
	AppendToLogFile(1, "Enter EE_Trips: " + datentime)

	DirTG  = Dir + "\\TG"
 	
 	yr_str = Right(theyear,2)
	yr = s2i(yr_str)


//____CREATE EE MATRICES_______________________CHANGE SOURCE TO TEMPLATE_____________

	OM = OpenMatrix(MetDir + "\\TAZ\\Matrix_Template.mtx", "True")
	mc1 = CreateMatrixCurrency(OM, "Table", "Rows", "Columns", )

	CopyMatrixStructure({mc1}, {{"File Name", Dir + "\\TD\\TDeeC.mtx"},
		{"Label", "TDeeC"},
		{"File Based", "Yes"},
		{"Tables", {"Trips"}},
    		{"Operation", "Union"}})

	CopyMatrixStructure({mc1}, {{"File Name", Dir + "\\TD\\TDeeM.mtx"},
		{"Label", "TDeeM"},
		{"File Based", "Yes"},
		{"Tables", {"Trips"}},
		{"Operation", "Union"}})

	CopyMatrixStructure({mc1}, {{"File Name", Dir + "\\TD\\TDeeH.mtx"},
		{"Label", "TDeeH"},
		{"File Based", "Yes"},
		{"Tables", {"Trips"}},
		{"Operation", "Union"}})

//_________COMMMERCIAL_________RARARARARRARARRRRRRRRRRAAAA

	opentable("com", "FFA", {MetDir + "\\ExtSta\\thrubase_com.asc",})
	opentable("factor", "FFB", {Dir + "\\TG\\xxfactor.bin",})
	JoinViews("com + factor", "com.From", "factor.Station", )
	setview("com + factor")
	ExportView("com + factor|", "DBASE", Dir + "\\TG\\extfac_com.dbf", {"From", "To", "Station", "cvthru", "COM_FACTOR"},)

	closeview("com")
	closeview("factor")
	closeview("com + factor")
	opentable("com + factor", "DBASE", {Dir + "\\TG\\extfac_com.dbf",})
	
	strct = GetTableStructure("com + factor")
	for i = 1 to strct.length do
		// Copy the current name to the end of strct
		strct[i] = strct[i] + {strct[i][1]}
	end
	new_struct = strct + {{"eeC", "Real", 12, 4, "True",,,, null}}
		
	ModifyTable("com + factor", new_struct)

	closeview("com + factor")

	tab = opentable("com + factor", "DBASE", {Dir + "\\TG\\extfac_com.dbf",})

	setview("com + factor")

	hi = GetFirstRecord("com + factor|",)
	while hi <> null do
		mval = GetRecordValues("com + factor", hi, {"cvthru", "COM_FACTOR"})

		com = mval[1][2]
		factor = mval[2][2]

		SetRecordValues("com + factor",null,{{"eeC", (com*factor)}})

		hi = GetNextRecord("com + factor|", null,)
	end

	FM = OpenMatrix(Dir + "\\TD\\TDeeC.mtx", "True")

	viewset = tab + "|"
	update_flds = {tab+".eeC"}
	UpdateMatrixFromView(FM, viewset, "From", "To", null, update_flds, "Replace",
    	{{"Missing is zero", "Yes"}})

	FM = null
	tab = null
	viewset = null
	update_flds = null

	closeview("com + factor")

//_____________MEDIUM_TRRRUUUCCCKKKSSSSSS___________

	opentable("mtk", "FFA", {MetDir + "\\ExtSta\\thrubase_mtk.asc",})
	opentable("factor", "FFB", {Dir + "\\TG\\xxfactor.bin",})

	JoinViews("mtk + factor", "mtk.From", "factor.Station", )
	setview("mtk + factor")
	ExportView("mtk + factor|", "DBASE", Dir + "\\TG\\extfac_mtk.dbf", {"From", "To", "Station", "mtthru", "MTK_FACTOR"},)

	closeview("mtk")
	closeview("factor")
	closeview("mtk + factor")
	opentable("mtk + factor", "DBASE", {Dir + "\\TG\\extfac_mtk.dbf",})
	setview("mtk + factor")
	strct = GetTableStructure("mtk + factor")
	for i = 1 to strct.length do
		// Copy the current name to the end of strct
		strct[i] = strct[i] + {strct[i][1]}
	end
	new_struct = strct + {{"eeM", "Real", 12, 4, "True",,,, null}}
		
	ModifyTable("mtk + factor", new_struct)

	closeview("mtk + factor")

	tab = opentable("mtk + factor", "DBASE", {Dir + "\\TG\\extfac_mtk.dbf",})

	setview("mtk + factor")
	hi = GetFirstRecord("mtk + factor|",)
	while hi <> null do
		mval = GetRecordValues("mtk + factor", hi, {"mtthru", "MTK_FACTOR"})

		mtk = mval[1][2]
		factor = mval[2][2]

		SetRecordValues("mtk + factor",null,{{"eeM", (mtk*factor)}})

		hi = GetNextRecord("mtk + factor|", null,)
	end

	FM = OpenMatrix(Dir + "\\TD\\TDeeM.mtx", "True")

	viewset = tab + "|"
	update_flds = {tab+".eeM"}
	UpdateMatrixFromView(FM, viewset, "From", "To", null, update_flds, "Replace",
    	{{"Missing is zero", "Yes"}})

	FM = null
	tab = null
	viewset = null
	update_flds = null

	closeview("mtk + factor")

//_____HEAVVVEY_METAL_TRUCKS________

	opentable("htk", "FFA", {MetDir + "\\ExtSta\\thrubase_htk.asc",})
	opentable("factor", "FFB", {Dir + "\\TG\\xxfactor.bin",})

	JoinViews("htk + factor", "htk.From", "factor.Station", )
	setview("htk + factor")
	ExportView("htk + factor|", "DBASE", Dir + "\\TG\\extfac_htk.dbf", {"From", "To", "Station", "htthru", "HTK_FACTOR"},)

	closeview("htk")
	closeview("factor")
	closeview("htk + factor")
	opentable("htk + factor", "DBASE", {Dir + "\\TG\\extfac_htk.dbf",})
	setview("htk + factor")
	strct = GetTableStructure("htk + factor")
	for i = 1 to strct.length do
		// Copy the current name to the end of strct
		strct[i] = strct[i] + {strct[i][1]}
	end
	new_struct = strct + {{"eeH", "Real", 12, 4, "True",,,, null}}
		
	ModifyTable("htk + factor", new_struct)

	closeview("htk + factor")
	tab = opentable("htk + factor", "DBASE", {Dir + "\\TG\\extfac_htk.dbf",})

	setview("htk + factor")
	hi = GetFirstRecord("htk + factor|",)
	while hi <> null do
		mval = GetRecordValues("htk + factor", hi, {"htthru", "HTK_FACTOR"})

		htk = mval[1][2]
		factor = mval[2][2]

		SetRecordValues("htk + factor",null,{{"eeH", (htk*factor)}})

		hi = GetNextRecord("htk + factor|", null,)
	end

	FM = OpenMatrix(Dir + "\\TD\\TDeeH.mtx", "True")


	viewset = tab + "|"
	update_flds = {tab+".eeH"}
	UpdateMatrixFromView(FM, viewset, "From", "To", null, update_flds, "Replace",
    	{{"Missing is zero", "Yes"}})

	FM = null
	tab = null
	viewset = null
	update_flds = null

	closeview("htk + factor")

	RunMacro("G30 File Close All")

//	quit:

/*	datentime = GetDateandTime()
	AppendToLogFile(1, "Exit EE_Trips: " + datentime)


	return({TripGenOK, msg})
*/


// ************************************************************************************

// ************ Trip Distribution (from Trip model)  *******************************************

// ************************************************************************************

	//Trip Distribution - Commercial Vehicles	
	//Friction factors, intrazonal K : Bill Allen Oct, 2013
	//Modified for new UI - Oct, 2015

	// LogFile = Args.[Log File].value
	// ReportFile = Args.[Report File].value
	// SetLogFileName(LogFile)
	// SetReportFileName(ReportFile)

	sedata_file = Args.[LandUse file]
	Dir = Args.[Run Directory]
	MetDir = Args.[MET Directory]
	theyear = Args.[Run Year]
	msg = null
	datentime = GetDateandTime()
	AppendToLogFile(1, "Tour Truck Model: " + datentime)
	RunMacro("TCB Init")

	RunMacro("G30 File Close All") 

	DirTG  = Dir + "\\TG"
 	
 	yr_str = Right(theyear,2)
	yr = s2i(yr_str)
	msg = null
	TripDistOK = 1

	datentime = GetDateandTime()
	AppendToLogFile(1, "Enter TDcom: " + datentime)

	iter = 4	//actually 3 iterations and 1 initial run
	ttimefac = 1.0
	htollfac = 0.0
	intrak = 1.0
//	afac = 1.0
	kfac = 1.0	

	// Travel time (off-peak) -- create new indices for without external stations and with only external stations
	autofree = OpenMatrix(Dir + "\\Skims\\TThwy_free.mtx", "False")			//open as memory-based
	autofreecur = CreateMatrixCurrency(autofree, "TotalTT", "Rows", "Columns", )
	transfree = OpenMatrix(Dir + "\\Skims\\TTTran_free.mtx", "False")			//open as memory-based
	transfreecur = CreateMatrixCurrency(transfree, "TTTranFr", "Rows", "Columns", )

	//template matrix
	TemplateMat = null
	templatecore = null
	TemplateMat = OpenMatrix(MetDir + "\\TAZ\\matrix_template.mtx", "True")
	templatecore = CreateMatrixCurrency(TemplateMat, "Table", "Rows", "Columns", )

	vt_ar = {"COM", "MTK", "HTK"}
	vt_lc_ar = {"com", "mtk", "htk"}
	triptype = {"II", "IX", "XI"}
	type_ar = {{"com", "iec", "eic"}, {"mtk", "iem", "eim"}, {"htk", "ieh", "eih"}}

	//create a temp matrix to do calcs
	flds = {"ht", "tt", "ct", "imp", "frac", "x", "t", "ffac_low", "ffac_hi", "ffac"} 
	flds_int = {"low", "hi"} 
	CopyMatrixStructure({templatecore}, {{"File Name", Dir + "\\TD\\tempcalc.mtx"},
    		{"Label", "tempcalc"},
   			{"File Based", "Yes"},
   			{"Tables", flds},
   			{"Operation", "Union"}})
	calc_mat = OpenMatrix(Dir + "\\TD\\tempcalc.mtx", "False")
	calc_array = CreateMatrixCurrencies(calc_mat, , , )
	//and another for integers
	CopyMatrixStructure({templatecore}, {{"File Name", Dir + "\\TD\\tempcalcint.mtx"},
    		{"Label", "tempcalcint"},
   			{"Type", "Short"},
   			{"File Based", "Yes"},
   			{"Tables", flds_int},
   			{"Operation", "Union"}})
	calcint_mat = OpenMatrix(Dir + "\\TD\\tempcalcint.mtx", "False")
	calcint_array = CreateMatrixCurrencies(calcint_mat, , , )

	//open production and attraction table
	prodattr_vw = OpenTable("prodattr_vw", "FFB", {Dir + "\\TG\\trucktable.bin",})	


	//Loop by truck type
	for vt = 1 to 3 do
		for trptype = 1 to 3 do //triptype = {"II", "IX", "XI"}
			//create new td matrix
			CopyMatrixStructure({templatecore}, {{"File Name", Dir + "\\TD\\TD" + type_ar[vt][trptype] + ".mtx"},
		    		{"Label", "TD" + type_ar[vt][trptype]},
		   			{"File Based", "Yes"},
		   			{"Tables", {"Trips"}},
		   			{"Operation", "Union"}})

			//Read and store F factors.  These are in free format. NOTE: This version assumes that an F factor is input for every
			// whole unit of impedance, starting at 1 (1,2,3,...).  It will interpolate between those integer units.
			fftable = OpenTable("fftable", "FFB", {MetDir + "\\Pgm\\FrictionFactors\\ff" + type_ar[vt][trptype] + ".bin",})	//fields are "Unit" and "fac"
			ff_v = GetDataVectors(fftable+"|", {"Unit", "fac"},{{"Sort Order", {{"Unit","Ascending"}}}, {"Return Options Array", "True"}})
			unit = ff_v.unit
			ff = ff_v.fac
			ff_ar = v2a(ff)
			impmax = unit.length
			
			//get production and attraction vectors
			prodattr_v = GetDataVectors(prodattr_vw+"|", {"TAZ", "SEQ", vt_ar[vt] + "_PROD_" + triptype[trptype], vt_ar[vt] + "_ATTR_" + triptype[trptype]},{{"Sort Order", {{"TAZ","Ascending"}}}})
			taz_v = prodattr_v[1]
			seq_v = prodattr_v[2]
			prod_v = prodattr_v[3]
			prod_v.columnbased = true
			attr_v = prodattr_v[4]
			
			//Now start the main iteration loop.  Assume we will run ITER number of iterations, regardless of convergence.  
			for i = 1 to iter do
				
				//Get skims and compute composite time. HTOLLFAC is the value of time, expressed in cents/minute.
				htim = autofreecur
				ht = calc_array.ht
				ht := if (htim > 0.001) then (1 / htim) else 0.0
				ttim = transfreecur
				tt = calc_array.tt
				tt := if (ttim > 0.001) then (1 / ttim) else 0.0
				ct = calc_array.ct
				ct := ht + ttimefac * tt
				imp = calc_array.imp
				imp := if (ct > 0.001) then (1 / ct) else 0.0
				//Use the impedance value to look up the F factor with linear interpolation.
				low = calcint_array.low
				low := if (imp > 1.0) then floor(imp) else 1
//				low := r2i(low)
				hi = calcint_array.hi
				hi := low + 1.0
				hi := if (hi < impmax) then hi else impmax
//				hi := r2i(hi)
				frac = calc_array.frac
				frac := if (imp > 1.0) then (imp - low) else 0.0
				ffac_low = calc_array.ffac_low
				ffac_hi = calc_array.ffac_hi
//				hivalue = CreateMatrixCurrency(hi_m, "hivalue",,,)
 				ffac_low := ff_ar[low]
 				ffac_hi := ff_ar[hi]
				ffac = calc_array.ffac
 				ffac := ffac_low - (imp - low) * (ffac_low - ffac_hi)
 				ffac := max(ffac, 0.0)
 				
				//need to initialize afac
				if i = 1 then do
					afac_v = Vector(attr_v.length, "float",{{"Constant", 1.0}, {"Row Based", "True"}})
				end			

				//Compute the basic accessibility statistic for this O/D pair:  Aj * Fij * AFj * K.  Sum it for this row.
				x = calc_array.x
				x := ffac * attr_v * afac_v * kfac
				rowsum_v = GetMatrixVector(x, {{"Marginal", "Row Sum"}})
				
				//End first JZ loop.
				//Compute "production factor" for this row to save some calculations later.
				pfac_v = if (rowsum_v > 0.0001) then (prod_v / rowsum_v) else 0.0 

				//Start second JZ loop.
				//Compute trips and sum attractions.
				t = calc_array.t
				t := x * pfac_v 
				sumatt = GetMatrixVector(t, {{"Marginal","Column Sum"}})
				
				//Do another JZ loop to compute the (cumulative) attraction factors.
				afac_v = if (sumatt > 0.0001) then (afac_v * attr_v / sumatt) else 1.0

			end	//iteration loops
			out_m = OpenMatrix(Dir + "\\TD\\TD" + type_ar[vt][trptype] + ".mtx", "False")		
			out_cur = CreateMatrixCurrency(out_m, "Trips", "Rows", "Columns", )
			out_cur := t
			
		end	//trptype loop
	end	//vt loop

    RunMacro("G30 File Close All")


// ************************************************************************************

// ************ TOD2_COM_MTK_HTK (from Trip model)  *******************************************

// ************************************************************************************


//Transpose matrix of commercial vehicles, medium and heavy trucks.  

	// LogFile = Args.[Log File].value
	// ReportFile = Args.[Report File].value
	// SetLogFileName(LogFile)
	// SetReportFileName(ReportFile)

	METDir = Args.[MET Directory]
	Dir = Args.[Run Directory]
	msg = null
	TOD2_COMMTKHTKOK = 1

	datentime = GetDateandTime()
	AppendToLogFile(1, "Enter TOD2_COM_MTK_HTK: " + datentime)

	RunMacro("TCB Init")

	//template matrix

	TemplateMat = null
	templatecore = null

	TemplateMat = OpenMatrix(MetDir + "\\TAZ\\matrix_template.mtx", "True")
	templatecore = CreateMatrixCurrency(TemplateMat, "Table", "Rows", "Columns", )


	CopyMatrixStructure({templatecore}, {{"File Name", Dir + "\\tod2\\ToTranspose.mtx"},
	    {"Label", "ToTranspose"},
	    {"File Based", "Yes"},
	    {"Tables", {"TransposeCOM", "TransposeMTK", "TransposeHTK"}},
	    {"Operation", "Union"}})


//_________COM, MTK, HTK:  Transpose_all_II_EI_IE_com trips______________________

	M1 = openmatrix(Dir + "\\tod2\\ToTranspose.mtx", "True")
	M2 = openmatrix(Dir + "\\TD\\tdcom.mtx", "True")
	M3 = openmatrix(Dir + "\\TD\\tdeic.mtx", "True")
	M4 = openmatrix(Dir + "\\TD\\tdiec.mtx", "True")
	M5 = openmatrix(Dir + "\\TD\\tdmtk.mtx", "True")
	M6 = openmatrix(Dir + "\\TD\\tdeim.mtx", "True")
	M7 = openmatrix(Dir + "\\TD\\tdiem.mtx", "True")
	M8 = openmatrix(Dir + "\\TD\\tdhtk.mtx", "True")
	M9 = openmatrix(Dir + "\\TD\\tdeih.mtx", "True")
	M10 = openmatrix(Dir + "\\TD\\tdieh.mtx", "True")

	c1 = CreateMatrixCurrency(M1, "TransposeCOM", "Rows", "Columns",)
	c2 = CreateMatrixCurrency(M1, "TransposeMTK", "Rows", "Columns",)
	c3 = CreateMatrixCurrency(M1, "TransposeHTK", "Rows", "Columns",)
	c4 = CreateMatrixCurrency(M2, "Trips", "Rows", "Columns",)
	c5 = CreateMatrixCurrency(M3, "Trips", "Rows", "Columns",)
	c6 = CreateMatrixCurrency(M4, "Trips", "Rows", "Columns",)
	c7 = CreateMatrixCurrency(M5, "Trips", "Rows", "Columns",)
	c8 = CreateMatrixCurrency(M6, "Trips", "Rows", "Columns",)
	c9 = CreateMatrixCurrency(M7, "Trips", "Rows", "Columns",)
	c10 = CreateMatrixCurrency(M8, "Trips", "Rows", "Columns",)
	c11 = CreateMatrixCurrency(M9, "Trips", "Rows", "Columns",)
	c12 = CreateMatrixCurrency(M10, "Trips", "Rows", "Columns",)

        MatrixOperations(c1, {c4,c5,c6}, {1.0,1.0,1.0},,, {{"Operation", "Add"}, {"Force Missing", "No"}})
        MatrixOperations(c2, {c7,c8,c9}, {1.0,1.0,1.0},,, {{"Operation", "Add"}, {"Force Missing", "No"}})
        MatrixOperations(c3, {c10,c11,c12}, {1.0,1.0,1.0},,, {{"Operation", "Add"}, {"Force Missing", "No"}})

    c1 = null
    c2 = null
    c3 = null
    c4 = null
    c6 = null
    c7 = null
    c8 = null
    c9 = null
    c10 = null
    c11 = null
    c12 = null
    c13 = null
    M1 = null
    M2 = null
    M3 = null
    M4 = null
    M5 = null
    M6 = null
    M7 = null
    M8 = null
    M9 = null
    M10 = null



//__________Transpose_COM_____________________________________________________

     Opts = null
     Opts.Input.[Input Matrix] = Dir + "\\tod2\\ToTranspose.mtx"
     Opts.Output.[Transposed Matrix].Label = "TransposeCOM_MTK_HTK"
     Opts.Output.[Transposed Matrix].[File Name] = Dir + "\\tod2\\Transpose_COM_MTK_HTK.mtx"

     ret_value = RunMacro("TCB Run Operation", 1, "Transpose Matrix", Opts)

     if !ret_value then goto badtranspose

goto quit

badtranspose:
	Throw("TOD2_COM_MTK_HTK - bad transpose")
    TOD2_COMMTKHTKOK = 0         


//quit:

	datentime = GetDateandTime()
	AppendToLogFile(1, "Exit TOD2_COM_MTK_HTK: " + datentime)
	return({TOD2_COMMTKHTKOK, msg})

skiptoend:


    goto quit

	badquit:
		on error, notfound default
		RunMacro("TCB Closing", ret_value, "TRUE" )
		Throw("Tour Truck Model: Error somewhere")
		AppendToLogFile(1, "Tour Truck Model: Error somewhere")
		datentime = GetDateandTime()
		AppendToLogFile(1, "Tour Truck Model " + datentime)

       	return({0, msg})

    quit:
		on error, notfound default
   		datentime = GetDateandTime()
		AppendToLogFile(1, "Exit Tour Truck Model " + datentime)
DestroyProgressBar()
    RunMacro("G30 File Close All")

    	return({1, msg})

endmacro






