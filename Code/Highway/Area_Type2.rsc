Macro "Area_Type" (Args)

//Calculate density: For each zone, compute employment and population density
//Classify zones: Assign each zone to a category based on density thresholds
	// 1 - Central Business District (CBD)
	// 2 - Central Business District Fringe/Other Business District (OBD)
	// 3 - Urban
	// 4 - Suburban
	// 5 - Rural
// Also create TAZ_ATYPE file for use in Tour Generation, note this file also includes transit flags for use in transit assignment

	Dir = Args.[Run Directory]
	METDir = Args.[MET Directory]
	SEDataFile = Args.[LandUse file]
	TAZFile = Args.[TAZ File]
	theyear = Args.[Run Year]
	ZonePctFile = METDir + "\\TAZ\\TAZNeighbors_pct.bin" 

	// ZonePctFile - percentage of neighboring TAZ within 1.5 mile buffer
	// of TAZ centroid - SUM of pop and emp in this buffer used to assign area type (1-5) 

	datentime = GetDateandTime()
	AppendToLogFile(1, "Enter Area_Type2 " + datentime)
	RunMacro("TCB Init")
	
	info = GetFileInfo(ZonePctFile)
	if info = null 
		then do
			Throw("Area Type - ERROR - cannot find TAZNeighbors_pct file. Please run MRM Utilities - AreaType_TAZNeighbors or copy valid TAZNeighbor_pct.asc into TAZ directory")
		end
	msg = null
	AreaTypeOK = 1

	tbl_se = CreateObject("Table", SEDataFile)
	tbl_zone = CreateObject("Table", ZonePctFile)
	
	// check SE against TAZNeighbors to make sure they match (both are internal taz only)
	// first join TAZNeighbors to SE to see if Neighbors has missing TAZ
	
	join1 = tbl_se.Join({
		Table: tbl_zone, 
		LeftFields: "TAZ", 
		RightFields: "TAZ",
		Options: {{"A"}, {"Fields", {"PercentIN", {{"Sum"}}
		}}}})

	selnopctcount= join1.SelectByQuery({
     	SetName: "selnopct",
    	Filter: "Select * where TAZNeighbor = null",
     	Operation: "several"
		})
	
	if selnopctcount > 0
		then do
			Throw("AreaType ERROR! SE file has TAZ not present in TAZNeighbors_pct file")
		end
	
	join1 = null

	// next join SE to TAZNeighbors to SE to see if SE has missing TAZ
	
	join2 = tbl_zone.Join({
		Table: tbl_se, 
		LeftFields: "TAZ", 
		RightFields: "TAZ"})

	se_specs = tbl_se.GetFieldSpecs({NamedArray: "true"})

	selnosecount= join2.SelectByQuery({
     	SetName: "selnose",
    	Filter: "Select * where " + se_specs.TAZ + " = null",
     	Opeartion: "several"
		})

	if selnosecount > 0
		then do
			Throw("AreaType ERROR! TAZNeighbors_pct file has TAZ not present in SE file")
		end
	
	join2= null

	// Calc total employment for each TAZ by summing across all job types (retail, highway, office, etc.)
	//this should already be calculated correctly but is used as an additional check
	tbl_se.TOTEMP = tbl_se.LOIND + tbl_se.hIIND + tbl_se.RTL + tbl_se.HWY + tbl_se.LOSVC + tbl_se.HISVC + tbl_se.OFFGOV + tbl_se.EDUC

	// Add TAZ info to TAZNeighbors_pct by Neighbor TAZ (can have many copies of same taz data based on number of tazs  within buffer
	// Add fields for HHPOP, EMPTOT, and Area (using land use area) to SE file and then join to TAZNeighbors_pct file to get these values for each neighbor TAZ --- this sets up a one to many join
	// Then calculate zdat for each neighbor (zdat = category * percentin) and sum across all neighbors to get final zdat for each TAZ.
	
	a_fields = {
        {FieldName: "HHPOP", Type: "Real"},
        {FieldName: "EMPTOT", Type: "Real"},
        {FieldName: "zArea", Type: "Real"}
    }
    
	tbl_se.AddFields({Fields: a_fields})

	// Get field specs for zone and se tables to use in join and calculations 
	// Note: both have field name TAZ so need to use field specs to specify which table

	zone_specs = tbl_zone.GetFieldSpecs({NamedArray: "true"})
	se_specs = tbl_se.GetFieldSpecs({NamedArray: "true"})

	join3 = tbl_zone.Join({
	Table: tbl_se, 
	LeftFields: "TAZNeighbor", 
	RightFields: "TAZ"
	})

	// Calc zdat - category * percentin 
	join3.(se_specs.HHPOP) = ROUND(join3.(zone_specs.PercentIN) * join3.(se_specs.POP_HHS),6)
	join3.(se_specs.EMPTOT) = ROUND(join3.(zone_specs.PercentIN) * join3.(se_specs.TOTEMP),6)
	join3.(se_specs.zArea) = ROUND(join3.(zone_specs.PercentIN) * join3.(se_specs.AREA_LU),6)

	join3 = Null

	// create table with sum of zdat for each TAZ - then calculate density to assign area type
	tbl_density = tbl_se.Aggregate({
    GroupBy: "TAZ",
    FieldStats: {
			HHPOP: "sum",
      		EMPTOT: "sum",
			zArea: "sum"}
       })

	// rename fields for clarity
	tbl_density.ChangeField({FieldName:"sum_HHPOP", NewName: "HHPOP"})
	tbl_density.ChangeField({FieldName:"sum_EMPTOT", NewName: "EMPTOT"})
	tbl_density.ChangeField({FieldName:"sum_zArea", NewName: "zArea"})

	// add fields for density and area type
	a_fields = {
		{FieldName: "EMPDEN", Type: "Real"},
		{FieldName: "POPDEN", Type: "Real"},
		{FieldName: "AREATYPE", Type: "Integer"}
    }
    
	tbl_density.AddFields({Fields: a_fields})

	// calculate density
	tbl_density.EMPDEN = if tbl_density.zAREA > 0 then tbl_density.EMPTOT/tbl_density.zAREA else 0
	tbl_density.POPDEN = if tbl_density.zAREA > 0 then tbl_density.HHPOP/tbl_density.zAREA else 0

	//export density file for review - this is not used directly in the model but is useful for documentation and review of area type assignment
	DensityFile = Dir + "\\LandUse\\SE"+theyear+"_DENSITY.bin"
	tbl_density.Export({
		FileName: DensityFile}	
		)
	
	// pull table vectors for each taz's density to assign area type based on density thresholds 
	v_empdens = tbl_density.EMPDEN
	v_popdens = tbl_density.POPDEN
	v_output = if v_empdens > 10500 then 1 else if v_empdens > 2600 then 2 else if v_popdens >= 375 and (v_popdens + (v_empdens / 1.6)) > 2100 then 3 else if v_popdens >= 375 then 4 else 5
	
	//fill areatype field in density table with area type category (1-5) based on density thresholds
	tbl_density.AREATYPE = v_output

	// export TAZ_AREATYPE file - this file has TAZ and AREATYPE fields only
	// this only includes internal TAZ - external stations will be added in the transit TAZ_ATYPE file created below
	//external stations assigned ATYPE = 5 - this is used by TripGen for area type based trip generation rates
	TAZ_AreaType_File = Dir + "\\LandUse\\TAZ_AREATYPE.bin"
	tbl_density.Export({
		FileName: TAZ_AreaType_File,
		FieldNames: {"TAZ", "AREATYPE"}
		})

	//Open TAZID file (created by Matrix_template)
	
	tazpath = SplitPath(TAZFile)
	TAZIDFile = tazpath[1] + tazpath[2] + tazpath[3] + "_TAZID.bin"
	exist = GetFileInfo(TAZIDFile)
	if exist = null
		then do
			Throw("AreaType: ERROR! \\TAZ\\" + tazpath[3] + "_TAZID.bin not found")
		end

	tbl_TAZID = CreateObject("Table", TAZIDFile)
	// The TAZID table has information about externals

	a_fields = {
		{FieldName: "ZONE", Type: "Integer"},
		{FieldName: "ATYPE", Type: "Integer"},
		{FieldName: "CBD_FLAG", Type: "Integer"},
		{FieldName: "PARK_INF", Type: "Integer"},
		{FieldName: "EXP_FLAG", Type: "Integer"}	
    }

	tbl_TAZID.AddFields({Fields: a_fields})
	TAZID_specs = tbl_TAZID.GetFieldSpecs({NamedArray: "true"})

	tbl_transit_AT = tbl_TAZID.Join({
		Table: tbl_density, 
		LeftFields: "TAZ", 
		RightFields: "TAZ"})

	// For internal zones, use the area type calculated based on density
	//For external stations, assign area type 5.

	tbl_transit_AT.ATYPE = if tbl_transit_AT.INT_EXT = 2 then 5 else tbl_transit_AT.AREATYPE
	tbl_transit_AT = Null

	//  Get Transit Flags and join to _TAZID.bin
	
	TFFile = METDir + "\\MS_Control_Template\\TAZ_ATYPE_TRANSIT_FLAGS.dbf"
	exist = GetFileInfo(TFFile)
	if exist = null
		then do
			Throw("AreaType: ERROR! \\MS_Control_Template\\TAZ_ATYPE_TRANSIT_FLAGS.dbf not found")
		end

	tbl_TFIn = CreateObject("Table", TFFile)

	transit_AT2 = tbl_TAZID.Join({
		Table: tbl_TFIn, 
		LeftFields: "TAZ", 
		RightFields: "TAZ"})

	TFIn_specs = tbl_TFIn.GetFieldSpecs({NamedArray: "true"})

	transit_AT2.CBD_FLAG = if transit_AT2.(TFIn_specs.TAZ) = null then 1
    	else if s2i(theyear) <= 2002 then transit_AT2.CBDFLAG02    
		else if s2i(theyear) <= 2003 then transit_AT2.CBDFLAG03 
		else if s2i(theyear) <= 2008 then transit_AT2.CBDFLAG08    
		else if s2i(theyear) <= 2015 then transit_AT2.CBDFLAG15    
		else if s2i(theyear) <= 2025 then transit_AT2.CBDFLAG20    
		else transit_AT2.CBDFLAG30


	transit_AT2.PARK_INF = if transit_AT2.(TFIn_specs.TAZ) = null then 100 
		else if s2i(theyear) <= 2000 then transit_AT2PKINFLAT00 
		else if s2i(theyear) <= 2002 then transit_AT2.PKINFLAT02 
		else if s2i(theyear) <= 2003 then transit_AT2.PKINFLAT030 
		else if s2i(theyear) <= 2008 then transit_AT2.PKINFLAT05 
		else if s2i(theyear) <= 2015 then transit_AT2.PKINFLAT10 
		else if s2i(theyear) <= 2025 then transit_AT2.PKINFLAT20 
		else transit_AT2.PKINFLAT30 

	tbl_TAZID.EXP_FLAG = if transit_AT2.(TFIn_specs.TAZ) = null then 0 else transit_AT2.EXP_FLAG_T

	transit_AT2 = null
	tbl_TAZID.Sort({FieldArray: {{"TAZ", "Ascending"}}})
	
	// export transit TAZ_ATYPE	
	
	TAZ_AType_File = Dir + "\\TAZ_ATYPE.bin"
	tbl_TAZID.Export({
		FileName: TAZ_AreaType_File,
		FieldNames: {"TAZ", "ZONE", "ATYPE", "CBD_FLAG", "PARK_INF", "EXP_FLAG"}
		})
	

EndMacro