Macro "Area_Type" (Args)

//	changed location of TAZ_ATYPE.asc to root, changed format - McLelland,  Apr. 9, 2007
//	added exp_flag, altered parking inflation factor equation to cover intermediate years, McLelland - Aug 11, 2008
//	updated employment categories - Gallup, Feb. 26, 2013
//	updated reference to TAZ file to guide user to TAZ3521 - Gallup, Feb. 6, 2015
//	Altered for new user interface - McLelland - June, 2016
//	Replaces CalcZone, fortran program written by Urbitran.  Aug, 2017
//	Uses TAZNeighbors file replacing zone_pct 

	on error goto badend
	// LogFile = Args.[Log File].value
	// ReportFile = Args.[Report File].value
	// SetLogFileName(LogFile)
	// SetReportFileName(ReportFile)

	Dir = Args.[Run Directory]
	METDir = Args.[MET Directory]
	SEDataFile = Args.[LandUse file]
	TAZFile = Args.[TAZ File]
	theyear = Args.[Run Year]

	datentime = GetDateandTime()
	AppendToLogFile(1, "Enter Area_Type2 " + datentime)
	RunMacro("TCB Init")


	// TAZ Neighbors file - percentage of neighboring TAZ within 1.5 mile buffer
	//  of TAZ centroid - SUM of pop and emp in this buffer used to assign area type (1-5) 
	TAZFilesplit = SplitPath(TAZFile)
	//ZonePctFile = TAZFilesplit[1] + TAZFilesplit[2] + "TAZNeighbors_pct.asc"
	ZonePctFile = TAZFilesplit[1] + TAZFilesplit[2] + "TAZNeighbors_pct.bin"
	info = GetFileInfo(ZonePctFile)
	if info = null 
		then do
			Throw("Area Type - ERROR - cannot find TAZNeighbors_pct file. Please run MRM Utilities - AreaType_TAZNeighbors or copy valid TAZNeighbor_pct.asc into TAZ directory")
			// Throw("Area Type - ERROR - cannot find TAZNeighbors_pct file")
			// Throw("Please run MRM Utilities - AreaType_TAZNeighbors")
			// Throw(" or copy valid TAZNeighbor_pct.asc into TAZ directory")
			// goto badend
		end
	msg = null
	AreaTypeOK = 1

	//SEDataView = Opentable("SEDataView","FFB",{SEDataFile,})
	//ZonePctView = OpenTable("ZonePctView", "FFA", {ZonePctFile,})
	
	tbl_se = CreateObject("Table", SEDataFile)
	tbl_se.TOTEMP = tbl_se.LOIND + tbl_se.hIIND + tbl_se.RTL + tbl_se.HWY + tbl_se.LOSVC + tbl_se.HISVC + tbl_se.OFFGOV + tbl_se.EDUC
	
	tbl_zone = CreateObject("Table", ZonePctFile)


	// check SE against TAZNeighbors to make sure they match (both are internal taz only
	// first join TAZNeighbors to SE to see if Neighbors has missing TAZ
	//join1 = JoinViews("join1", SEDataView + ".TAZ", ZonePctView + ".TAZ",
	 //   {{"A"}, {"Fields", {"PERCENT_1", {{"Sum"}}}}})

	join = tbl_se.Join({
		Table: tbl_zone, 
		LeftFields: "TAZ", 
		RightFields: "TAZ",
		Options: {{"A"}, {"Fields", {"PERCENT_1", {{"Sum"}}
		}}}})

	//SetView(join1)
	//selnopct = "Select * where TAZNeighbor = null"
	//Selectbyquery("check_pct", "Several", selnopct,)
	//selnopctcount = getsetcount("check_pct")

	selnopctcount= join1.SelectByQuery({
     	SetName: "selnopct",
    	Filter: "Select * where TAZNeighbor = null",
     	Opeartion: "several"
		})
	
	if selnopctcount > 0
		then do
			Throw("AreaType ERROR! SE file has TAZ not present in TAZNeighbors_pct file")
			// Throw("AreaType ERROR! SE file has TAZ ")
			// Throw("not present in TAZNeighbors_pct file")
			// goto badend
		end
	
	join= null
	//CloseView(join1)

	// next join SE to TAZNeighbors to SE to see if SE has missing TAZ
	//join2 = JoinViews("join2", ZonePctView + ".TAZ", SEDataView + ".TAZ",)
	join = tbl_zone.Join({
		Table: tbl_se, 
		LeftFields: "TAZ", 
		RightFields: "TAZ"})

	//SetView(join2)
	//selnose = "Select * where SEDataView.TAZ = null"
	//SelectbyQuery("check_SE", "Several", selnose,)
	//selnosecount = getsetcount("check_SE")
	selnosecount= join.SelectByQuery({
     	SetName: "selnose",
    	Filter: "Select * where Table_1.TAZ = null",
     	Opeartion: "several"
		})
	
	
	if selnosecount > 0
		then do
			Throw("AreaType ERROR! TAZNeighbors_pct file has TAZ not present in SE file")
			// Throw("AreaType ERROR! TAZNeighbors_pct file ")
			// Throw("has TAZ not present in SE file")
			// goto badend
		end
	join= null
	//CloseView(join2)

	// Replace CalcZone Fortran beginning here

	//SetView(SEDataView)
	
	/*on NotFound do
		// Add TOTEMP to end of Land Use File
		strct = GetTableStructure(SEDataView)
		for i = 1 to strct.length do
	   		strct[i] = strct[i] + {strct[i][1]}
		end
		new_struct = strct + {{"TOTEMP", "INTEGER", 10, 0, "False",,,,null}}
		ModifyTable(SEDataView, new_struct)
		goto skipcreate
	end
	GetField(SEDataView  + ".TOTEMP")

	skipcreate:
	on notfound default
	*/

	/*vLOIND  = GetDataVector(SEDataView + "|", "LOIND",)
	vHIIND  = GetDataVector(SEDataView + "|", "HIIND",)
	vRTL    = GetDataVector(SEDataView + "|", "RTL",)
	vHWY    = GetDataVector(SEDataView + "|", "HWY",)
	vLOSVC  = GetDataVector(SEDataView + "|", "LOSVC",)
	vHISVC  = GetDataVector(SEDataView + "|", "HISVC",)
	vOFFGOV = GetDataVector(SEDataView + "|", "OFFGOV",)
	vEDUC   = GetDataVector(SEDataView + "|", "EDUC",)
	vTOTEMP = vLOIND + vHIIND + vRTL + vHWY + vLOSVC + vHISVC + vOFFGOV + vEDUC
	SetDataVector(SEDataView + "|", "TOTEMP", vTOTEMP, )
	*/

	//Add TAZ info to TAZNeighbors_pct by Neighbor TAZ (can have many copies of same taz data data based on # taz it it within buffer
	//ZonePctDataView = JoinViews("ZonePctDataView", ZonePctView + ".TAZNeighbor", SEDataView + ".TAZ",)

	a_fields = {
        {FieldName: "HHPOP", Type: "Real"},
        {FieldName: "EMPTOT", Type: "Real"},
        {FieldName: "zArea", Type: "Real"},
		{FieldName: "EMPDEN", Type: "Real"},
		{FieldName: "POPDEN", Type: "Real"}
    }
    
tbl_zone.AddFields({Fields: a_fields})

a_fields = {
        {FieldName: "HHPOP", Type: "Real"},
        {FieldName: "EMPTOT", Type: "Real"},
        {FieldName: "zArea", Type: "Real"},
		{FieldName: "EMPDEN", Type: "Real"},
		{FieldName: "POPDEN", Type: "Real"},
		{FieldName: "AREATYPE", Type: "Integer"}
    }
    
tbl_zone.AddFields({Fields: a_fields})

zone_specs = tbl_zone.GetFieldSpecs({NamedArray: "true"})
se_specs = tbl_se.GetFieldSpecs({NamedArray: "true"})

join = tbl_zone.Join({
Table: tbl_se, 
LeftFields: "TAZNeighbor", 
RightFields: "TAZ"
})

join.(zone_specs.HHPOP) = ROUND(join.(zone_specs.PercentIN) * join.(se_specs.POP_HHS),6)
join.(zone_specs.EMPTOT) = ROUND(join.(zone_specs.PercentIN) * join.(se_specs.TOTEMP),6)
join.(zone_specs.zArea) = ROUND(join.(zone_specs.PercentIN) * join.(se_specs.AREA_LU),6)
join.(zone_specs.EMPDEN) = if join.(zone_specs.zAREA) >0 then join.(zone_specs.EMPTOT)/join.(zone_specs.zAREA) else 0
join.(zone_specs.POPDEN) = if join.(zone_specs.zAREA) >0 then join.(zone_specs.HHPOP)/join.(zone_specs.zAREA) else 0

	// ExportView(ZonePctDataView + "|", "FFB", METDir + "\\TAZ\\Wurk.bin", {"ZONE_ID", "ZONEIN_ID", "PercentIN", "TAZ", "SEQ", "POP_HHS", "TOTEMP", "AREA_LU"},)

	// Calc zdat - category * percentin 
	//hhpop = CreateExpression(ZonePctDataView, "HHPOP", "ROUND(PercentIN * POP_HHS,6)",)
	//emptot = CreateExpression(ZonePctDataView, "EMPTOT", "ROUND(PercentIN * TOTEMP,6)",)
	//zarea = CreateExpression(ZonePctDataView, "zAREA", "ROUND(PercentIN * AREA_LU,6)",)


	//ExportView(ZonePctDataView + "|", "FFB", Dir + "\\LandUse\\TAZtemp.bin", 
	// 	{ZonePctView+ ".TAZ", "TAZNeighbor", "PercentIN", "HHPOP", "EMPTOT", "zAREA"},)


//	CloseView(SEDataView)
//	CloseView(ZonePctView)
//	CloseView(ZonePctDataView)


	//ZpctView = OpenTable("ZpctView", "FFB", {Dir + "\\LandUse\\TAZtemp.bin",})	
	/*ZdatView = JoinViews("ZdatView", SEDataView + ".TAZ", ZpctView + ".TAZ",
	    {{"A"}, {"Fields", 
		  {"HHPOP", {{"Sum"}}},{"EMPTOT", {{"Sum"}}},{"zAREA", {{"Sum"}}} 
		}})
	*/

	//empden = CreateExpression(ZdatView, "EMPDEN", "if zAREA > 0 then EMPTOT / zAREA else 0",)
	//popden = CreateExpression(ZdatView, "POPDEN", "if zAREA > 0 then HHPOP / zAREA else 0",)
	
	// we may not even need to export this.... see if year_density used other places
	join = null
	DensityFile = Dir + "\\LandUse\\SE"+theyear+"_DENSITY.bin"
	tbl_zone.Export({
		FileName: DensityFile,
		FieldNames: {"TAZ", "zAREA", "EMPTOT", "HHPOP", "EMPDEN", "POPDEN", "AREATYPE"}	
		})

	/*ExportView(ZdatView + "|", "DBASE", Dir + "\\LandUse\\SE"+theyear+"_DENSITY.dbf", 
			{SEDataView + ".TAZ", "zAREA", "EMPTOT", "HHPOP", "EMPDEN", "POPDEN"},
			{{"Additional Fields",{{"AREATYPE", "INTEGER", 1, 0, "False"}}}})
	
	CloseView(SEDataView)
	CloseView(ZpctView)
	CloseView(ZdatView)
	*/
	// End of calczone replacement

	//Reopen new density file with ATYPE added 
	//DensityView = Opentable("DensityView","DBASE",{Dir + "\\LandUse\\SE"+theyear+"_DENSITY.bin",})
	//SetView("DensityView")
  
	vw1 = "DensityView"
	//Calculate Zonal Employment and Household Population Density
	ptr = GetFirstRecord("DensityView|",)
	while ptr <> null do
    
		if vw1.EMPDEN > 10500 
			then vw1.AREATYPE = 1
		if vw1.EMPDEN > 2600 and vw1.AREATYPE = null 
			then vw1.AREATYPE = 2
		if vw1.POPDEN >= 375 and vw1.AREATYPE = null 
			then do
				if vw1.POPDEN + (vw1.EMPDEN / 1.6) > 2100 and vw1.AREATYPE = null 
					then vw1.AREATYPE = 3
					else vw1.AREATYPE = 4
			end
		if vw1.AREATYPE = null then vw1.AREATYPE = 5
      
		ptr = GetNextRecord("DensityView|",,)
	end

	// reset width of TAZ field to 10 (for \landuse\taz_areatype.asc)
	strct = GetTableStructure(DensityView)
	for i = 1 to strct.length do
		strct[i] = strct[i] + {strct[i][1]}
	end
	if strct[1][1] = "TAZ" then strct[1][3] = 10
	ModifyTable(DensityView, strct)

	atype = CreateExpression("DensityView", "ATYPE", "AREATYPE",
	 		{{"Type","Integer"},{"Width",1}})


	// So far we only have internal TAZ - good for TAZ_AREATYPE used by TripGen
	Exportview(DensityView + "|", "FFA", Dir + "\\LandUse\\TAZ_AREATYPE.asc", {"TAZ","ATYPE"},)
	DestroyExpression("DensityView.ATYPE")	
	// For Transit, (root.TAZ_ATYPE.asc - need external stations (ATYPE = 5) 

	//Open TAZID file (created by Matrix_template)
	tazpath = SplitPath(TAZFile)

	TAZIDFile = tazpath[1] + tazpath[2] + tazpath[3] + "_TAZID.asc"
	exist = GetFileInfo(TAZIDFile)
	if exist = null
		then do
			Throw("AreaType: ERROR! \\TAZ\\" + tazpath[3] + "_TAZID.asc not found")
			// Throw("AreaType: ERROR! \\TAZ\\" + tazpath[3] + "_TAZID.asc not found")
			// AppendToLogFile(2, "AreaType: ERROR! \\TAZ\\" + tazpath[3] + "_TAZID.asc not found")
			// AreaTypeOK = 0
			// goto badend
		end

	TAZID = OpenTable("TAZID", "FFA", {TAZIDFile,})
	TransitATJoin1 = JoinViews("TransitATJoin1", "TAZID.TAZ", "DensityView.TAZ",)
	CloseView("DensityView")
	CloseView("TAZID")
	
	//  Also Get Transit Flags and join to file created in step above

	TFFile = METDir + "\\MS_Control_Template\\TAZ_ATYPE_TRANSIT_FLAGS.dbf"
	exist = GetFileInfo(TFFile)
	if exist = null
		then do
			Throw("AreaType: ERROR! \\MS_Control_Template\\TAZ_ATYPE_TRANSIT_FLAGS.dbf not found")
			// Throw("AreaType: ERROR! \\MS_Control_Template\\TAZ_ATYPE_TRANSIT_FLAGS.dbf not found")
			// AppendToLogFile(2, "AreaType: ERROR! \\MS_Control_Template\\TAZ_ATYPE_TRANSIT_FLAGS.dbf not found")
			// AreaTypeOK = 0
			// goto badend
		end

	TFIn = OpenTable("TFIn", "DBASE", {TFFile,})
	TransitATJoin2 = JoinViews("TransitATJoin2", "TransitATJoin1.TAZID.TAZ", "TFIn.TAZ",)
	CloseView("TFIn")
	CloseView("TransitATJoin1")
		 
	// Transit taz_atype uses "ZONE"
	SetView("TransitATJoin2")

	zone = CreateExpression("TransitATJoin2", "ZONE", "TransitATJoin1.TAZID.TAZ",{{"Type","Integer"},{"Width",5}})

	atype = CreateExpression("TransitATJoin2", "ATYPE", "if INT_EXT = 2 then 5 else AREATYPE",
	 		{{"Type","Integer"},{"Width",5}})

	//use 2005 inflation through 2008, 2010 infl. for 2009-15, 2020 infl. for 2016-25, 
	// 2030 inf. for 2026+
	cbd_flag = CreateExpression("TransitATJoin2", "CBD_FLAG", "if TFIn.TAZ = null then 1 else if "+theyear+" <= 2000 then CBDFLAG00 else if "+theyear+" <= 2002 then CBDFLAG02 else if "+theyear+" <= 2003 then CBDFLAG03 else if "+theyear+" <= 2008 then CBDFLAG05 else if "+theyear+" <= 2015 then CBDFLAG10 else if "+theyear+" <= 2025 then CBDFLAG20 else CBDFLAG30",
		{{"Type","Integer"},{"Width",5}})

	park_inf = CreateExpression("TransitATJoin2", "PARK_INF", "if TFIn.TAZ = null then 100 else if "+theyear+" <= 2000 then PKINFLAT00 else if "+theyear+" <= 2002 then PKINFLAT02 else if "+theyear+" <= 2003 then PKINFLAT03 else if "+theyear+" <= 2008 then PKINFLAT05 else if "+theyear+" <= 2015 then PKINFLAT10 else if "+theyear+" <= 2025 then PKINFLAT20 else PKINFLAT30",
		{{"Type","Integer"},{"Width",5}})

	exp_flag = CreateExpression("TransitATJoin2", "EXP_FLAG", "if TFIn.TAZ = null then 0 else EXP_FLAG_T",
		{{"Type","Integer"},{"Width",5}})
	
	// export transit TAZ_ATYPE.asc	
	ExportView("TransitATJoin2|", "FFA", Dir + "\\TAZ_ATYPE.asc",{"ZONE","TransitATJoin2.ATYPE","CBD_FLAG","PARK_INF", "EXP_FLAG"},
		{{"Row Order", {{"TransitATJoin1.TAZID.TAZ", "Ascending"}}}}) 
	ExportView("TransitATJoin2|", "FFA", Dir + "\\holdher2.asc",,
		{{"Row Order", {{"TransitATJoin1.TAZID.TAZ", "Ascending"}}}}) 
	
	
	CloseView("TransitATJoin2")	
	goto quit
	
	badend:
		on error, notfound default
		AppendToLogFile(2, "Area_Type: Error ")
		Throw("Area_Type: Error ")

    quit:
		on error, notfound default
   		datentime = GetDateandTime()
		AppendToLogFile(1, "Exit Area_Type2 " + datentime)
    	return({AreaTypeOK, msg})
EndMacro