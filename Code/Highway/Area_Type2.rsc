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

	//table class can not be created from .asc file. So used TAZNeighbors_Pct.bin file that was copied into the location and created table from it
	//TAZfolder = "C:\\MRM\\Metrolina\\TAZ"
	TAZ_file = METDir + "\\TAZ\\TAZNeighbors_Pct.bin"


	// TAZ Neighbors file - percentage of neighboring TAZ within 1.5 mile buffer
	//  of TAZ centroid - SUM of pop and emp in this buffer used to assign area type (1-5) 
	/*TAZFilesplit = SplitPath(TAZFile)
	ZonePctFile = TAZFilesplit[1] + TAZFilesplit[2] + "TAZNeighbors_pct.asc"*/
	info = GetFileInfo(TAZ_file)
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

	/*SEDataView = Opentable("SEDataView","FFB",{SEDataFile,})
	ZonePctView = OpenTable("ZonePctView", "FFA", {ZonePctFile,})*/
	SEData_tbl = CreateObject("Table", SEDataFile)
	
	SEData_tbl.AddField({FieldName: "TOTEMP", Type: "integer", Width: 10, Decimals: 0})
	SEData_tbl.TOTEMP = SEData_tbl.LOIND + SEData_tbl.HIIND + SEData_tbl.RTL + SEData_tbl.HWY + SEData_tbl.LOSVC + SEData_tbl.HISVC + SEData_tbl.OFFGOV + SEData_tbl.EDUC

	TAZ_tbl = CreateObject("Table", TAZ_file)

	// check SE against TAZNeighbors to make sure they match (both are internal taz only
	// first join TAZNeighbors to SE to see if Neighbors has missing TAZ
	/*join1 = JoinViews("join1", SEDataView + ".TAZ", ZonePctView + ".TAZ",
	    {{"A"}, {"Fields", {"PERCENT_1", {{"Sum"}}}}})

	SetView(join1)
	selnopct = "Select * where TAZNeighbor = null"
	Selectbyquery("check_pct", "Several", selnopct,)
	selnopctcount = getsetcount("check_pct")
	
	if selnopctcount > 0
		then do
			Throw("AreaType ERROR! SE file has TAZ not present in TAZNeighbors_pct file")
			// Throw("AreaType ERROR! SE file has TAZ ")
			// Throw("not present in TAZNeighbors_pct file")
			// goto badend
		end
	CloseView(join1)*/
	//SEData_tbl.RenameField({FieldName: "TAZSEData", NewName: "TAZ"})
	join = SEData_tbl.Join({
  		Table: TAZ_tbl, 
  		LeftFields: "TAZ", 
  		RightFields: "TAZ",Options: {{"A"}, {"Fields",{"PercentIN", {{"Sum"}}}}}
 	})

	n1 = join.SelectByQuery({
  		SetName: "count_set",
  		Query: "Select * where TAZNeighbor = null"
 	})

	if n1 <> 0 then Throw("AreaType ERROR! SE file has TAZ not present in TAZNeighbors_pct file")

	join = null
	
	// next join SE to TAZNeighbors to SE to see if SE has missing TAZ
	/*join2 = JoinViews("join2", ZonePctView + ".TAZ", SEDataView + ".TAZ",)

	SetView(join2)
	selnose = "Select * where SEDataView.TAZ = null"
	SelectbyQuery("check_SE", "Several", selnose,)
	selnosecount = getsetcount("check_SE")
	
	if selnosecount > 0
		then do
			Throw("AreaType ERROR! TAZNeighbors_pct file has TAZ not present in SE file")
			// Throw("AreaType ERROR! TAZNeighbors_pct file ")
			// Throw("has TAZ not present in SE file")
			// goto badend
		end
	CloseView(join2)*/
	join = TAZ_tbl.Join({
  		Table: SEData_tbl, 
  		LeftFields: "TAZ", 
  		RightFields: "TAZ"
 	})

	n2 = join.SelectByQuery({
  		SetName: "count_set",
  		Query: "Select * where TAZNeighbor = null"
 	})

	if n2 <> 0 then Throw("AreaType ERROR! TAZNeighbors_pct file has TAZ not present in SE file")

	join = null
	// Replace CalcZone Fortran beginning here

	/*SetView(SEDataView)
	
	on NotFound do
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

	vLOIND  = GetDataVector(SEDataView + "|", "LOIND",)
	vHIIND  = GetDataVector(SEDataView + "|", "HIIND",)
	vRTL    = GetDataVector(SEDataView + "|", "RTL",)
	vHWY    = GetDataVector(SEDataView + "|", "HWY",)
	vLOSVC  = GetDataVector(SEDataView + "|", "LOSVC",)
	vHISVC  = GetDataVector(SEDataView + "|", "HISVC",)
	vOFFGOV = GetDataVector(SEDataView + "|", "OFFGOV",)
	vEDUC   = GetDataVector(SEDataView + "|", "EDUC",)
	vTOTEMP = vLOIND + vHIIND + vRTL + vHWY + vLOSVC + vHISVC + vOFFGOV + vEDUC
	SetDataVector(SEDataView + "|", "TOTEMP", vTOTEMP, )*/
	//join1 = null
	//join2 = null
	/*field_names = SEData_tbl.GetFieldNames()

	for field_name in field_names do
   		if field_name <> "TOTEMP" then do
     		SEData_tbl.AddField({FieldName: "TOTEMP", Type: "integer", Width: 10, Decimals: 0})
			SEData_tbl.TOTEMP = SEData_tbl.LOIND + SEData_tbl.HIIND + SEData_tbl.RTL + SEData_tbl.HWY + SEData_tbl.LOSVC + SEData_tbl.HISVC + SEData_tbl.OFFGOV + SEData_tbl.EDUC 
		end
		else SEData_tbl.TOTEMP = SEData_tbl.LOIND + SEData_tbl.HIIND + SEData_tbl.RTL + SEData_tbl.HWY + SEData_tbl.LOSVC + SEData_tbl.HISVC + SEData_tbl.OFFGOV + SEData_tbl.EDUC
	end*/

	//Add TAZ info to TAZNeighbors_pct by Neighbor TAZ (can have many copies of same taz data data based on # taz it it within buffer
	/*ZonePctDataView = JoinViews("ZonePctDataView", ZonePctView + ".TAZNeighbor", SEDataView + ".TAZ",)*/
	// ExportView(ZonePctDataView + "|", "FFB", METDir + "\\TAZ\\Wurk.bin", {"ZONE_ID", "ZONEIN_ID", "PercentIN", "TAZ", "SEQ", "POP_HHS", "TOTEMP", "AREA_LU"},)

	// Calc zdat - category * percentin 
	/*hhpop = CreateExpression(ZonePctDataView, "HHPOP", "ROUND(PercentIN * POP_HHS,6)",)
	emptot = CreateExpression(ZonePctDataView, "EMPTOT", "ROUND(PercentIN * TOTEMP,6)",)
	zarea = CreateExpression(ZonePctDataView, "zAREA", "ROUND(PercentIN * AREA_LU,6)",)
	    
	ExportView(ZonePctDataView + "|", "FFB", Dir + "\\LandUse\\TAZtemp.bin", 
	 	{ZonePctView+ ".TAZ", "TAZNeighbor", "PercentIN", "HHPOP", "EMPTOT", "zAREA"},)
//	CloseView(SEDataView)
	CloseView(ZonePctView)
	CloseView(ZonePctDataView)*/

	/*ZpctView = OpenTable("ZpctView", "FFB", {Dir + "\\LandUse\\TAZtemp.bin",})	
	ZdatView = JoinViews("ZdatView", SEDataView + ".TAZ", ZpctView + ".TAZ",
	    {{"A"}, {"Fields", 
		  {"HHPOP", {{"Sum"}}},{"EMPTOT", {{"Sum"}}},{"zAREA", {{"Sum"}}} 
		}})
	empden = CreateExpression(ZdatView, "EMPDEN", "if zAREA > 0 then EMPTOT / zAREA else 0",)
	popden = CreateExpression(ZdatView, "POPDEN", "if zAREA > 0 then HHPOP / zAREA else 0",)
	
	ExportView(ZdatView + "|", "DBASE", Dir + "\\LandUse\\SE"+theyear+"_DENSITY.dbf", 
			{SEDataView + ".TAZ", "zAREA", "EMPTOT", "HHPOP", "EMPDEN", "POPDEN"},
			{{"Additional Fields",{{"AREATYPE", "INTEGER", 1, 0, "False"}}}})
	
	CloseView(SEDataView)
	CloseView(ZpctView)
	CloseView(ZdatView)*/
	// End of calczone replacement

	a_fields = {
        {FieldName: "HHPOP", Type: "Real"},
        {FieldName: "EMPTOT", Type: "Real"},
        {FieldName: "zAREA", Type: "Real"}
    }
    
	TAZ_tbl.AddFields({Fields: a_fields})

	zone_specs = TAZ_tbl.GetFieldSpecs({NamedArray: "true"})
	se_specs = SEData_tbl.GetFieldSpecs({NamedArray: "true"})

	join = TAZ_tbl.Join({
		Table: SEData_tbl, 
		LeftFields: "TAZNeighbor",
		RightFields: "TAZ"
	})

	join.(zone_specs.HHPOP) = ROUND(join.(zone_specs.PercentIN) * join.(se_specs.POP_HHS),6)
	join.(zone_specs.EMPTOT) = ROUND(join.(zone_specs.PercentIN) * join.(se_specs.TOTEMP),6)
	join.(zone_specs.zAREA) = ROUND(join.(zone_specs.PercentIN) * join.(se_specs.AREA_LU),6)
	  
	TAZ_agg_tbl = TAZ_tbl.Aggregate({
    	GroupBy: {"TAZ"},
    	FieldStats: {
      		HHPOP: "sum",
      		EMPTOT: "sum",
      		zAREA: "sum"
    	}
  	})
	TAZ_agg_tbl.RenameField({FieldName: "sum_HHPOP", NewName: "HHPOP"})
	TAZ_agg_tbl.RenameField({FieldName: "sum_EMPTOT", NewName: "EMPTOT"})
	TAZ_agg_tbl.RenameField({FieldName: "sum_zAREA", NewName: "zAREA"})
	
	a_fields = {
        {FieldName: "EMPDEN", Type: "Real"},
        {FieldName: "POPDEN", Type: "Real"},
        {FieldName: "AREATYPE", Type: "Integer"}
    }

	TAZ_agg_tbl.AddFields({Fields: a_fields})

	TAZ_agg_tbl.EMPDEN = if TAZ_agg_tbl.zAREA >0 then TAZ_agg_tbl.EMPTOT/TAZ_agg_tbl.zAREA else 0
	TAZ_agg_tbl.POPDEN = if TAZ_agg_tbl.zAREA >0 then TAZ_agg_tbl.HHPOP/TAZ_agg_tbl.zAREA else 0

	TAZ_agg_tbl.Export({FileName: Dir + "\\LandUse\\SE"+theyear+"_DENSITY.bin"})
	

	/*//Reopen new density file with ATYPE added 
	DensityView = Opentable("DensityView","DBASE",{Dir + "\\LandUse\\SE"+theyear+"_DENSITY.dbf",})
	SetView("DensityView")
  
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
	 		{{"Type","Integer"},{"Width",1}})*/

	//In order to set the width of a field of this table below, this table must be set to null first.
	TAZ_agg_tbl = null

	density_file = Dir + "\\LandUse\\SE"+theyear+"_DENSITY.bin"

	tbl_density = CreateObject("Table", density_file)

	tbl_density.ChangeField({FieldName: "TAZ", Width: 10})	

	tbl_density.AREATYPE = 	if (tbl_density.EMPDEN > 10500) then 1 
               				else if (tbl_density.EMPDEN > 2600 and tbl_density.AREATYPE = null) then 2 
               				else if (tbl_density.POPDEN >= 375 and (tbl_density.POPDEN + (tbl_density.EMPDEN / 1.6) > 2100) and tbl_density.AREATYPE = null)then 3 
            				else if (tbl_density.POPDEN >= 375 and(tbl_density.POPDEN + (tbl_density.EMPDEN / 1.6) <= 2100) and tbl_density.AREATYPE = null) then 4 
               				else 5

	/*// So far we only have internal TAZ - good for TAZ_AREATYPE used by TripGen
	Exportview(DensityView + "|", "FFA", Dir + "\\LandUse\\TAZ_AREATYPE.asc", {"TAZ","ATYPE"},)
	DestroyExpression("DensityView.ATYPE")	
	// For Transit, (root.TAZ_ATYPE.asc - need external stations (ATYPE = 5) */

	tbl_density.AddField({FieldName: "ATYPE", Type: "integer", Width: 1, Decimals: 0})
	tbl_density.ATYPE = tbl_density.AREATYPE
	a_fields = {"TAZ", "ATYPE"}
	tbl_density.Export({FileName: Dir + "\\LandUse\\TAZ_AREATYPE.bin", FieldNames: a_fields})
	tbl_density.DropFields({FieldNames: "ATYPE"})
	density_specs = tbl_density.GetFieldSpecs({NamedArray: "true"})
	//Open TAZID file (created by Matrix_template)
	/*tazpath = SplitPath(TAZFile)

	TAZIDFile = tazpath[1] + tazpath[2] + tazpath[3] + "_TAZID.asc"*/
	TAZIDFile = METDir + "\\TAZ\\TAZ3896_TAZID.bin"
	exist = GetFileInfo(TAZIDFile)
	if exist = null
		then do
			Throw("AreaType: ERROR! Metrolina\\TAZ\\TAZ3896_TAZID.bin not found")
			// Throw("AreaType: ERROR! \\TAZ\\" + tazpath[3] + "_TAZID.asc not found")
			// AppendToLogFile(2, "AreaType: ERROR! \\TAZ\\" + tazpath[3] + "_TAZID.asc not found")
			// AreaTypeOK = 0
			// goto badend
		end
	

	/*TAZID = OpenTable("TAZID", "FFA", {TAZIDFile,})
	TransitATJoin1 = JoinViews("TransitATJoin1", "TAZID.TAZ", "DensityView.TAZ",)
	CloseView("DensityView")
	CloseView("TAZID")*/
	
	/*tbl_TAZID = CreateObject("Table", TAZIDFile)

	tbl_TAZID.ChangeField({FieldName: "TAZ", Type: "Integer", Width: 5})	

	tazid_specs = tbl_TAZID.GetFieldSpecs({NamedArray: "true"})

	join1 = tbl_TAZID.Join({
	Table: tbl_density, 
	LeftFields: tazid_specs.TAZ,
	RightFields: density_specs.TAZ
	})

	join1_specs = join1.GetFieldSpecs({NamedArray: "true"})*/
	
	tbl_TAZID = CreateObject("Table", TAZIDFile)
	a_fields = {
		{FieldName: "ZONE", Type: "Integer"},
		{FieldName: "ATYPE", Type: "Integer"},
		{FieldName: "CBD_FLAG", Type: "Integer"},
		{FieldName: "PARK_INF", Type: "Integer"},
		{FieldName: "EXP_FLAG", Type: "Integer"}	
    }

	tbl_TAZID.AddFields({Fields: a_fields})
	TAZID_specs = tbl_TAZID.GetFieldSpecs({NamedArray: "true"})

	// The TAZID table has information about externals, i.e. if INT_EX = 2. We join that with atype so we have the area type for all internals
	
	tbl_transit_AT = tbl_TAZID.Join({
		Table: tbl_density, 
		LeftFields: "TAZ", 
		RightFields: "TAZ"})

	tbl_transit_AT.ATYPE = if tbl_transit_AT.INT_EXT = 2 then 5 else tbl_transit_AT.AREATYPE
	tbl_transit_AT = Null
	tbl_TAZID.ZONE = tbl_TAZID.TAZ


	//  Also Get Transit Flags and join to file created in step above

	/*TFFile = METDir + "\\MS_Control_Template\\TAZ_ATYPE_TRANSIT_FLAGS.dbf"
	exist = GetFileInfo(TFFile)
	if exist = null
		then do
			Throw("AreaType: ERROR! \\MS_Control_Template\\TAZ_ATYPE_TRANSIT_FLAGS.bin not found")
			// Throw("AreaType: ERROR! \\MS_Control_Template\\TAZ_ATYPE_TRANSIT_FLAGS.dbf not found")
			// AppendToLogFile(2, "AreaType: ERROR! \\MS_Control_Template\\TAZ_ATYPE_TRANSIT_FLAGS.dbf not found")
			// AreaTypeOK = 0
			// goto badend
		end

	TFIn = OpenTable("TFIn", "DBASE", {TFFile,})
	TransitATJoin2 = JoinViews("TransitATJoin2", "TransitATJoin1.TAZID.TAZ", "TFIn.TAZ",)
	CloseView("TFIn")
	CloseView("TransitATJoin1")*/
	
	/*TFFile = METDir + "\\MS_Control_Template\\TAZ_ATYPE_TRANSIT_FLAGS.bin"
	
	tbl_TF = CreateObject("Table", TFFile)
	
	if exist = null
		then do
			Throw("AreaType: ERROR! \\MS_Control_Template\\TAZ_ATYPE_TRANSIT_FLAGS.bin not found")
		end
	
	tf_specs = tbl_TF.GetFieldSpecs({NamedArray: "true"})

	join2 = join1.Join({
	Table: tbl_TF, 
	LeftFields: tazid_specs.TAZ,
	RightFields: tf_specs.TAZ
	})*/


	TFFile = METDir + "\\MS_Control_Template\\TAZ_ATYPE_TRANSIT_FLAGS.bin"
	exist = GetFileInfo(TFFile)
	if exist = null
		then do
			Throw("AreaType: ERROR! \\MS_Control_Template\\TAZ_ATYPE_TRANSIT_FLAGS.bin not found")
		end

	//TFIn = OpenTable("TFIn", "DBASE", {TFFile,})
	tbl_TFIn = CreateObject("Table", TFFile)
	TFIn_specs = tbl_TFIn.GetFieldSpecs({NamedArray: "true"})

	transit_AT2 = tbl_TAZID.Join({
		Table: tbl_TFIn, 
		LeftFields: "TAZ", 
		RightFields: "TAZ"})


	// Transit taz_atype uses "ZONE"
	/*SetView("TransitATJoin2")

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
	
	
	CloseView("TransitATJoin2")*/

	/*temp = join2.Export()

	a_fields = {
		{FieldName: "ZONE", Type: "Integer", Width: 5},
        {FieldName: "ATYPE", Type: "Integer", Width: 5},
        {FieldName: "CBD_FLAG", Type: "Integer", Width: 5},
        {FieldName: "PARK_INF", Type: "Integer", Width: 5},
        {FieldName: "EXP_FLAG", Type: "Integer", Width: 5}
    }

	temp.AddFields({Fields: a_fields})
	
	temp_specs = temp.GetFieldSpecs({NamedArray: "true"})

	temp.ZONE = tbl_TAZID.TAZ

	temp.ATYPE = if (INT_EXT = 2) then 5 else AREATYPE*/

	tbl_TAZID.CBD_FLAG = if transit_AT2.(TFIn_specs.TAZ) = null then 1
                else if S2I(theyear) <= 2000 then (transit_AT2.CBDFLAG00)
                else if S2I(theyear) <= 2002 then (transit_AT2.CBDFLAG02)
                else if S2I(theyear) <= 2003 then (transit_AT2.CBDFLAG03)
                else if S2I(theyear) <= 2008 then (transit_AT2.CBDFLAG05)
                else if S2I(theyear) <= 2015 then (transit_AT2.CBDFLAG10)
                else if S2I(theyear) <= 2025 then (transit_AT2.CBDFLAG20)
                else (transit_AT2.CBDFLAG30)

	tbl_TAZID.PARK_INF = if transit_AT2.(TFIn_specs.TAZ) = null then 100
                else if S2I(theyear) <= 2000 then (transit_AT2.PKINFLAT00)
                else if S2I(theyear) <= 2002 then (transit_AT2.PKINFLAT02)
                else if S2I(theyear) <= 2003 then (transit_AT2.PKINFLAT03)
                else if S2I(theyear) <= 2008 then (transit_AT2.PKINFLAT05)
                else if S2I(theyear) <= 2015 then (transit_AT2.PKINFLAT10)
                else if S2I(theyear) <= 2025 then (transit_AT2.PKINFLAT20)
                else (transit_AT2.PKINFLAT30)

	tbl_TAZID.EXP_FLAG = if transit_AT2.(TFIn_specs.TAZ) = null then 0 else EXP_FLAG_T

	transit_AT2 = null
	tbl_TAZID.Sort({FieldArray: {{"TAZ", "Ascending"}}})

	a_fields = {"TAZ", "ZONE", "ATYPE", "CBD_FLAG", "PARK_INF", "EXP_FLAG"}
	tbl_TAZID.Export({FileName: Dir + "\\TAZ_ATYPE.bin", FieldNames: a_fields})

	//temp.Export({FileName: Dir + "\\holdher2.bin"})

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