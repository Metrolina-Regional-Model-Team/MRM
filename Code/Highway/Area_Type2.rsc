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

	TAZFilesplit = SplitPath(TAZFile)
	TAZ_file = TAZFilesplit[1] + TAZFilesplit[2] + "TAZNeighbors_Pct.bin"


	msg = null
	// TAZ Neighbors file - percentage of neighboring TAZ within 1.5 mile buffer
	//  of TAZ centroid - SUM of pop and emp in this buffer used to assign area type (1-5) 
	info = GetFileInfo(TAZ_file)
	if info = null 
		then do
			on error default
			Throw("Area Type - ERROR - cannot find TAZNeighbors_pct file. Please run MRM Utilities - AreaType_TAZNeighbors or copy valid TAZNeighbor_pct.bin into TAZ directory")

		end
	
	AreaTypeOK = 1


	SEData_tbl = CreateObject("Table", SEDataFile)
	
	SEData_tbl.AddField({FieldName: "TOTEMP", Type: "integer", Width: 10, Decimals: 0})
	SEData_tbl.TOTEMP = SEData_tbl.LOIND + SEData_tbl.HIIND + SEData_tbl.RTL + SEData_tbl.HWY + SEData_tbl.LOSVC + SEData_tbl.HISVC + SEData_tbl.OFFGOV + SEData_tbl.EDUC

	TAZ_tbl = CreateObject("Table", TAZ_file)
	zone_specs = TAZ_tbl.GetFieldSpecs({NamedArray: true})
	se_specs   = SEData_tbl.GetFieldSpecs({NamedArray: true})

	// check SE against TAZNeighbors to make sure they match (both are internal taz only
	// first join TAZNeighbors to SE to see if Neighbors has missing TAZ
	// Check 1: SE TAZ missing from TAZNeighbors
	join = SEData_tbl.Join({
		Table: TAZ_tbl,
		LeftFields: "TAZ",
		RightFields: "TAZ",
		Options: {{"A"}, {"Fields", {"PercentIN", {{"Sum"}}}}}
	})
	
	missing_1 = if join.PercentIN = null then 1 else 0
	n1 = VectorStatistic(missing_1, "Sum", )
	
	if n1 <> 0 then do
		on error default
		Throw("AreaType ERROR! SE file has TAZ not present in TAZNeighbors_pct file")
	end

	join = null
	
	// next join SE to TAZNeighbors to SE to see if SE has missing TAZ
	// Check 2: TAZNeighbors TAZ missing from SE
	join = TAZ_tbl.Join({
		Table: SEData_tbl,
		LeftFields: "TAZ",
		RightFields: "TAZ"
	})
	
	missing_2 = if join.(se_specs.TAZ) = null then 1 else 0
	n2 = VectorStatistic(missing_2, "Sum", )
	
	if n2 <> 0 then do
		on error default
		Throw("AreaType ERROR! TAZNeighbors_pct file has TAZ not present in SE file")
	end

	join = null

	// Work on a copy so the main TAZNeighbors file does not get modified and new fields and calculations only go inside the copy.
	TAZ_tbl = TAZ_tbl.Export({FileName: Dir + "\\LandUse\\TAZtemp.bin"})

	// Fields to hold neighbor-weighted pop, emp and area
	a_fields = {
		{FieldName: "HHPOP",  Type: "Real", Decimals: 6},
		{FieldName: "EMPTOT", Type: "Real", Decimals: 6},
		{FieldName: "zAREA",  Type: "Real", Decimals: 6}
	}
	TAZ_tbl.AddFields({Fields: a_fields})

	zone_specs = TAZ_tbl.GetFieldSpecs({NamedArray: true})     // refresh: copy + new fields


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
        {FieldName: "EMPDEN", Type: "Real", Decimals: 6},
        {FieldName: "POPDEN", Type: "Real", Decimals: 6},
        {FieldName: "AREATYPE", Type: "Integer"}
    }

	TAZ_agg_tbl.AddFields({Fields: a_fields})

	TAZ_agg_tbl.EMPDEN = if TAZ_agg_tbl.zAREA >0 then TAZ_agg_tbl.EMPTOT/TAZ_agg_tbl.zAREA else 0
	TAZ_agg_tbl.POPDEN = if TAZ_agg_tbl.zAREA >0 then TAZ_agg_tbl.HHPOP/TAZ_agg_tbl.zAREA else 0

	TAZ_agg_tbl.Export({FileName: {Dir + "\\LandUse\\SE"+theyear+"_DENSITY.bin"}, FieldNames: {"TAZ", "zAREA", "EMPTOT", "HHPOP", "EMPDEN", "POPDEN", "AREATYPE"}})

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

	tbl_density.AddField({FieldName: "ATYPE", Type: "integer", Width: 1, Decimals: 0})
	tbl_density.ATYPE = tbl_density.AREATYPE
	a_fields = {"TAZ", "ATYPE"}
	tbl_density.Export({FileName: Dir + "\\LandUse\\TAZ_AREATYPE.bin", FieldNames: a_fields})
	tbl_density.DropFields({FieldNames: "ATYPE"})
	
	//Open TAZID file (created by Matrix_template)
	tazpath = SplitPath(TAZFile)
	TAZIDFile = tazpath[1] + tazpath[2] + tazpath[3] + "_TAZID.bin"

	exist = GetFileInfo(TAZIDFile)
	if exist = null
		then do
			on error default
			Throw("AreaType: ERROR! \\TAZ\\" + tazpath[3] + "_TAZID.bin not found")
		end
	
	tbl_TAZID = CreateObject("Table", TAZIDFile)
	tbl_TAZID = tbl_TAZID.Export({FileName: Dir + "\\LandUse\\TAZID_temp.bin"})
	
	a_fields = {
		{FieldName: "ZONE", Type: "Integer"},
		{FieldName: "ATYPE", Type: "Integer"},
		{FieldName: "CBD_FLAG", Type: "Integer"},
		{FieldName: "PARK_INF", Type: "Integer"},
		{FieldName: "EXP_FLAG", Type: "Integer"}	
    }
	tbl_TAZID.AddFields({Fields: a_fields})

	TAZID_specs = tbl_TAZID.GetFieldSpecs({NamedArray: true})


	// The TAZID table has information about externals, i.e. if INT_EX = 2. We join that with atype so we have the area type for all internals
	
	tbl_transit_AT = tbl_TAZID.Join({
		Table: tbl_density, 
		LeftFields: "TAZ", 
		RightFields: "TAZ"})

	tbl_transit_AT.ATYPE = if tbl_transit_AT.INT_EXT = 2 then 5 else tbl_transit_AT.AREATYPE
	tbl_transit_AT = Null
	tbl_TAZID.ZONE = tbl_TAZID.TAZ


	//  Also Get Transit Flags and join to file created in step above

	TFFile = METDir + "\\MS_Control_Template\\TAZ_ATYPE_TRANSIT_FLAGS.bin"
	exist = GetFileInfo(TFFile)
	if exist = null
		then do
			on error default
			Throw("AreaType: ERROR! \\MS_Control_Template\\TAZ_ATYPE_TRANSIT_FLAGS.bin not found")
	end

	tbl_TFIn = CreateObject("Table", TFFile)
	TFIn_specs = tbl_TFIn.GetFieldSpecs({NamedArray: true})

	transit_AT2 = tbl_TAZID.Join({
		Table: tbl_TFIn, 
		LeftFields: "TAZ", 
		RightFields: "TAZ"})


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

	tbl_TAZID.EXP_FLAG = if transit_AT2.(TFIn_specs.TAZ) = null then 0 else transit_AT2.EXP_FLAG_T

	transit_AT2 = null
	tbl_TAZID.Sort({FieldArray: {{"TAZ", "Ascending"}}})

	a_fields = {"ZONE", "ATYPE", "CBD_FLAG", "PARK_INF", "EXP_FLAG"}
	tbl_TAZID.Export({FileName: Dir + "\\TAZ_ATYPE.bin", FieldNames: a_fields})


	goto quit
	
	badend:
		on error, notfound default
		AppendToLogFile(2, "Area_Type: Error")
		Throw("Area_Type: Error")
    quit:
		on error, notfound default
   		datentime = GetDateandTime()
		AppendToLogFile(1, "Exit Area_Type2 " + datentime)
    	return({AreaTypeOK, msg})
EndMacro