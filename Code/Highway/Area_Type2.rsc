Macro "Area_Type" (Args)

	//on error goto badend

	Dir = Args.[Run Directory]
	METDir = Args.[MET Directory]
	SEDataFile = Args.[LandUse file]
	TAZFile = Args.[TAZ File]
	theyear = Args.[Run Year]
	ZonePctFile = METDir + "\\TAZ\\TAZNeighbors_pct.bin" 

	datentime = GetDateandTime()
	AppendToLogFile(1, "Enter Area_Type2 " + datentime)
	RunMacro("TCB Init")

	// TAZ Neighbors file - percentage of neighboring TAZ within 1.5 mile buffer
	//  of TAZ centroid - SUM of pop and emp in this buffer used to assign area type (1-5) 
	
	info = GetFileInfo(ZonePctFile)
	if info = null 
		then do
			Throw("Area Type - ERROR - cannot find TAZNeighbors_pct file. Please run MRM Utilities - AreaType_TAZNeighbors or copy valid TAZNeighbor_pct.bin into TAZ directory")
		end
	msg = null
	AreaTypeOK = 1

	//SEDataView = Opentable("SEDataView","FFB",{SEDataFile,})
	//ZonePctView = OpenTable("ZonePctView", "FFA", {ZonePctFile,})
	
	tbl_se = CreateObject("Table", SEDataFile)
	tbl_zone = CreateObject("Table", ZonePctFile)

	// check SE against TAZNeighbors to make sure they match (both are internal taz only
	// first join TAZNeighbors to SE to see if Neighbors has missing TAZ
	//join1 = JoinViews("join1", SEDataView + ".TAZ", ZonePctView + ".TAZ",
	 //   {{"A"}, {"Fields", {"PERCENT_1", {{"Sum"}}}}})

	join = tbl_se.Join({
		Table: tbl_zone, 
		LeftFields: "TAZ", 
		RightFields: "TAZ",
		Options: {{"A"}, {"Fields", {"PercentIN", {{"Sum"}}
		}}}})

	//SetView(join1)
	//selnopct = "Select * where TAZNeighbor = null"
	//Selectbyquery("check_pct", "Several", selnopct,)
	//selnopctcount = getsetcount("check_pct")

	selnopctcount= join.SelectByQuery({
     	SetName: "selnopct",
    	Filter: "Select * where TAZNeighbor = null",
     	Operation: "several"
		})
	
	if selnopctcount > 0
		then do
			Throw("AreaType ERROR! SE file has TAZ not present in TAZNeighbors_pct file")
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
		end

	join = null
	//CloseView(join2)
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

	tbl_se.TOTEMP = tbl_se.LOIND + tbl_se.hIIND + tbl_se.RTL + tbl_se.HWY + tbl_se.LOSVC + tbl_se.HISVC + tbl_se.OFFGOV + tbl_se.EDUC
	
	//Add TAZ info to TAZNeighbors_pct by Neighbor TAZ (can have many copies of same taz data data based on # taz it it within buffer

	a_fields = {
        {FieldName: "HHPOP", Type: "Real", Decimals: 6},
        {FieldName: "EMPTOT", Type: "Real",Decimals: 6},
        {FieldName: "zArea", Type: "Real", Decimals: 6}
    }
    
	tbl_zone.AddFields({Fields: a_fields})

//ZonePctDataView = JoinViews("ZonePctDataView", ZonePctView + ".TAZNeighbor", SEDataView + ".TAZ",)
	join = tbl_zone.Join({
	Table: tbl_se, 
	LeftFields: "TAZNeighbor", 
	RightFields: "TAZ"
	})

	// ExportView(ZonePctDataView + "|", "FFB", METDir + "\\TAZ\\Wurk.bin", {"ZONE_ID", "ZONEIN_ID", "PercentIN", "TAZ", "SEQ", "POP_HHS", "TOTEMP", "AREA_LU"},)

	// Calc zdat - category * percentin 
	//hhpop = CreateExpression(ZonePctDataView, "HHPOP", "ROUND(PercentIN * POP_HHS,6)",)
	//emptot = CreateExpression(ZonePctDataView, "EMPTOT", "ROUND(PercentIN * TOTEMP,6)",)
	//zarea = CreateExpression(ZonePctDataView, "zAREA", "ROUND(PercentIN * AREA_LU,6)",)

	join.HHPOP = ROUND(join.PercentIN * join.POP_HHS,6)
	join.EMPTOT = ROUND(join.PercentIN * join.TOTEMP,6)
	join.zArea = ROUND(join.PercentIN * join.AREA_LU,6)

	join = Null
	
	//ExportView(ZonePctDataView + "|", "FFB", Dir + "\\LandUse\\TAZtemp.bin", 
	// 	{ZonePctView+ ".TAZ", "TAZNeighbor", "PercentIN", "HHPOP", "EMPTOT", "zAREA"},)

//	CloseView(SEDataView)
//	CloseView(ZonePctView)
//	CloseView(ZonePctDataView)

	//ZpctView = OpenTable("ZpctView", "FFB", {Dir + "\\LandUse\\TAZtemp.bin",})
	tbl_density = tbl_zone.Aggregate({
    GroupBy: "TAZ",
    FieldStats: {
			HHPOP: "sum",
      		EMPTOT: "sum",
			zArea: "sum"}
       })

	tbl_density.ChangeField({FieldName:"sum_HHPOP", NewName: "HHPOP"})
	tbl_density.ChangeField({FieldName:"sum_EMPTOT", NewName: "EMPTOT"})
	tbl_density.ChangeField({FieldName:"sum_zArea", NewName: "zArea"})

	a_fields = {
		{FieldName: "EMPDEN", Type: "Real", Decimals: 6},
		{FieldName: "POPDEN", Type: "Real",	Decimals: 6},
		{FieldName: "AREATYPE", Type: "Integer"}
    }
    
	tbl_density.AddFields({Fields: a_fields})

	/*ZdatView = JoinViews("ZdatView", SEDataView + ".TAZ", ZpctView + ".TAZ",
	    {{"A"}, {"Fields", 
		  {"HHPOP", {{"Sum"}}},{"EMPTOT", {{"Sum"}}},{"zAREA", {{"Sum"}}} 
		}})
	*/

	tbl_density.EMPDEN = if tbl_density.zAREA > 0 then tbl_density.EMPTOT/tbl_density.zAREA else 0
	tbl_density.POPDEN = if tbl_density.zAREA > 0 then tbl_density.HHPOP/tbl_density.zAREA else 0

	//empden = CreateExpression(ZdatView, "EMPDEN", "if zAREA > 0 then EMPTOT / zAREA else 0",)
	//popden = CreateExpression(ZdatView, "POPDEN", "if zAREA > 0 then HHPOP / zAREA else 0",)

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
  
	//vw1 = "DensityView"  

	//Calculate Zonal Employment and Household Population Density
	/*ptr = GetFirstRecord("DensityView|",)
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
	*/
	
	v_empdens = tbl_density.EMPDEN
	v_popdens = tbl_density.POPDEN
	
	v_output = if v_empdens > 10500 then 1 else if v_empdens > 2600 then 2 else if v_popdens >= 375 and (v_popdens + (v_empdens / 1.6)) > 2100 then 3 else if v_popdens >= 375 then 4 else 5
	tbl_density.AREATYPE = v_output

	DensityFile = Dir + "\\LandUse\\SE"+theyear+"_DENSITY.bin"
	tbl_density.Export({
		FileName: DensityFile}	
		)

	TAZ_AreaType_File = Dir + "\\LandUse\\TAZ_AREATYPE.bin"

	//tbl_density.AddField({FieldName: "ATYPE", Type: "Integer", Width: 1})
	//tbl_density.ATYPE = tbl_density.AREATYPE

	tbl_density.Export({
		FileName: TAZ_AreaType_File
		//FieldNames: {"TAZ", "ATYPE"}
		})

	// reset width of TAZ field to 10 (for \landuse\taz_areatype.asc)
	/*strct = GetTableStructure(DensityView)
	for i = 1 to strct.length do
		strct[i] = strct[i] + {strct[i][1]}
	end
	if strct[1][1] = "TAZ" then strct[1][3] = 10
	ModifyTable(DensityView, strct)

	atype = CreateExpression("DensityView", "ATYPE", "AREATYPE",
	 		{{"Type","Integer"},{"Width",1}})
	*/

	// So far we only have internal TAZ - good for TAZ_AREATYPE used by TripGen
	//Exportview(DensityView + "|", "FFA", Dir + "\\LandUse\\TAZ_AREATYPE.asc", {"TAZ","ATYPE"},)
	//DestroyExpression("DensityView.ATYPE")	
	// For Transit, (root.TAZ_ATYPE.asc - need external stations (ATYPE = 5) 

	//Open TAZID file (created by Matrix_template)
	tazpath = SplitPath(TAZFile)
	TAZIDFile = tazpath[1] + tazpath[2] + tazpath[3] + "_TAZID.bin"  /// ADD to MRM and Make Integer... 
	exist = GetFileInfo(TAZIDFile)
	if exist = null
		then do
			Throw("AreaType: ERROR! \\TAZ\\" + tazpath[3] + "_TAZID.bin not found")
		end

	//TAZID = OpenTable("TAZID", "FFA", {TAZIDFile,})

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

	//TransitATJoin1 = JoinViews("TransitATJoin1", "TAZID.TAZ", "DensityView.TAZ",)
	//CloseView("DensityView")
	//CloseView("TAZID")
	
	//  Also Get Transit Flags and join to file created in step above

	//TFFile = METDir + "\\MS_Control_Template\\TAZ_ATYPE_TRANSIT_FLAGS.dbf"
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

	//TransitATJoin2 = JoinViews("TransitATJoin2", "TransitATJoin1.TAZID.TAZ", "TFIn.TAZ",)
	//CloseView("TFIn")
	//CloseView("TransitATJoin1")
		 
	// Transit taz_atype uses "ZONE"
	//SetView("TransitATJoin2")

	//zone = CreateExpression("TransitATJoin2", "ZONE", "TransitATJoin1.TAZID.TAZ",{{"Type","Integer"},{"Width",5}})   
	//atype = CreateExpression("TransitATJoin2", "ATYPE", "if INT_EXT = 2 then 5 else AREATYPE",

	//use 2005 inflation through 2008, 2010 infl. for 2009-15, 2020 infl. for 2016-25, 
	// 2030 inf. for 2026+
	//cbd_flag = CreateExpression("TransitATJoin2", "CBD_FLAG", "if TFIn.TAZ = null then 1 else if "+theyear+" <= 2000 then CBDFLAG00 else if "+theyear+" <= 2002 then CBDFLAG02 else if "+theyear+" <= 2003 then CBDFLAG03 else if "+theyear+" <= 2008 then CBDFLAG05 else if "+theyear+" <= 2015 then CBDFLAG10 else if "+theyear+" <= 2025 then CBDFLAG20 else CBDFLAG30",
	//	{{"Type","Integer"},{"Width",5}})
	
	tbl_TAZID.CBD_FLAG = if transit_AT2.(TFIn_specs.TAZ) = null then 1 else if S2I(theyear) <= 2025 then transit_AT2.CBDFLAG20 else transit_AT2.CBDFLAG30

	//park_inf = CreateExpression("TransitATJoin2", "PARK_INF", "if TFIn.TAZ = null then 100 else if "+theyear+" <= 2000 then PKINFLAT00 else if "+theyear+" <= 2002 then PKINFLAT02 else if "+theyear+" <= 2003 then PKINFLAT03 else if "+theyear+" <= 2008 then PKINFLAT05 else if "+theyear+" <= 2015 then PKINFLAT10 else if "+theyear+" <= 2025 then PKINFLAT20 else PKINFLAT30",
	//	{{"Type","Integer"},{"Width",5}})

	tbl_TAZID.PARK_INF = if transit_AT2.(TFIn_specs.TAZ) = null then 100 else if S2I(theyear) <= 2025 then transit_AT2.PKINFLAT20 else transit_AT2.PKINFLAT30 

	//exp_flag = CreateExpression("TransitATJoin2", "EXP_FLAG", "if TFIn.TAZ = null then 0 else EXP_FLAG_T",
	//	{{"Type","Integer"},{"Width",5}})
	
	tbl_TAZID.EXP_FLAG = if transit_AT2.(TFIn_specs.TAZ) = null then 0 else transit_AT2.EXP_FLAG_T

	transit_AT2 = null
	tbl_TAZID.Sort({FieldArray: {{"TAZ", "Ascending"}}})

	// export transit TAZ_ATYPE.asc	
	//ExportView("TransitATJoin2|", "FFA", Dir + "\\TAZ_ATYPE.asc",{"ZONE","TransitATJoin2.ATYPE","CBD_FLAG","PARK_INF", "EXP_FLAG"},
	//	{{"Row Order", {{"TransitATJoin1.TAZID.TAZ", "Ascending"}}}}) 
	
	TAZ_AType_File = Dir + "\\TAZ_ATYPE.bin"
	tbl_TAZID.Export({
		FileName: TAZ_AreaType_File,
		FieldNames: {"TAZ", "ZONE", "ATYPE", "CBD_FLAG", "PARK_INF", "EXP_FLAG"}
		})

	//ExportView("TransitATJoin2|", "FFA", Dir + "\\holdher2.asc",,
	//	{{"Row Order", {{"TransitATJoin1.TAZID.TAZ", "Ascending"}}}}) 
	
	//CloseView("TransitATJoin2")	
	//goto quit
	
	/*badend:
		on error, notfound default
		AppendToLogFile(2, "Area_Type: Error ")
		Throw("Area_Type: Error ")

    quit:
		on error, notfound default
   		datentime = GetDateandTime()
		AppendToLogFile(1, "Exit Area_Type2 " + datentime)
    	return({AreaTypeOK, msg})
	*/

EndMacro