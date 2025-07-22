Macro "Matrix_template" (TAZFile)
//Create METDir\TAZ\matrix_template.mtx - base taz x taz empty matrix
//Create METDir\TAZ\<TAZName>_TAZID.asc
//Returns status 1,2,3 (red, yellow, green) & msg

	msg = null
	TemplateOK = 3
	tazpath = SplitPath(TAZFile)
	TAZName = tazpath[3]

	// Open TAZ dbd
	info = GetDBInfo(TAZFile)
	if info = null 
		then do
			msg = msg + {"Matrix Template ERROR! - No TAZ file"}
			TemplateOK = 1
			return({TemplateOK,msg})
		end
		
	//TAZ view
	scope = info[1]
 	CreateMap(TAZName, {{"Scope", scope},{"Auto Project", "True"}})
    layers = GetDBLayers(TAZFile)
    addlayer(TAZName, TAZName, TAZFile, layers[1])
	SetView(TAZName)

	// get number of internal and external taz
	selinttaz = "Select * where TAZ < 12000"
	selexttaz = "Select * where TAZ >= 12000"
	IntCount = Selectbyquery("inttaz", "Several", selinttaz,)
	ExtCount = Selectbyquery("exttaz", "Several", selexttaz,)

	if IntCount = 0 or ExtCount = 0 
		then do
			msg = msg + {"Matrix_template: ERROR!  Problem with TAZ file"}
			goto badtemplate
		end	
			
	//Matrix template - Base template file to create taz x taz matrices
	TemplateName = tazpath[1] + tazpath[2] + "matrix_template.mtx"
	exist = GetFileInfo(TemplateName)
	if exist = null 
		then goto createtemplate

	// Check if template matches TAZ, if not - replace it
	mat = null
	mat = OpenMatrix(TemplateName, )
	TemplateInfo = GetMatrixInfo(mat)
	NumTAZ = TemplateInfo[5][1]	
	mat = null
	if NumTAZ = (IntCount + ExtCount) 
		then goto checktazid
		else do
			msg = msg + {"Matrix_Template: Warning - existing matrix template being replaced"}
			TemplateOK = 2
		end
		
	//Create Matrix Template
	createtemplate:
	on error goto badtemplate
	mat = null
	mat = CreateMatrix({TAZName+"|", TAZName+".TAZ", "Rows"},
		{TAZName+"|", TAZName+".TAZ", "Columns"},
		{{"File Name", tazpath[1] + tazpath[2] + "matrix_template.mtx"}, {"Type", "Float"}, {"File Based", "Yes"}, {"Compression", 1}})
	mat = null

	// <TAZName>_TAZID includes base TAZ info to use in checking taz against other files
	checktazid:
	TAZIDName = tazpath[1] + tazpath[2] + TAZName + "_TAZID.bin"

	exist = GetFileInfo(TAZIDName)
	if exist = null 
		then goto createtazid

	// Check if tazid matches TAZ, if not - replace it
	TAZID = OpenTable("TAZID", "FFB", {TAZIDName,})

	Join1 = JoinViews("Join1", TAZName + ".TAZ", "TAZID.TAZ",)
	SetView(Join1)
	query1 = "Select * where TAZID.TAZ = null"
	numbad1 = Selectbyquery("numbad1", "Several", query1,)
	closeview(Join1)

	Join2 = JoinViews("Join2", "TAZID.TAZ", TAZName + ".TAZ",)
	query2 = "Select * where " + TAZName + ".TAZ = null"
	SetView(Join2)
	numbad2 = Selectbyquery("numbad2", "Several", query2,)
	CloseView(Join2)
	CloseView(TAZID)

	if numbad1 = 0 and numbad2 = 0 
		then goto quit
		else do
			msg = msg + {"Matrix_Template: Warning - existing TAZID asc being replaced"}
			TemplateOK = 2
		end

	createtazid:
	SetView(TAZName)
	int_ext = CreateExpression(TAZName, "INT_EXT", "if TAZ < 12000 then 1 else 2",
		{{"Type","Integer"},{"Width",8}})
	//ExportView(TAZName+"|", "FFA", TAZIDName,{"TAZ", "SEQ", "INT_EXT"},)
	ExportView(TAZName+"|", "FFB", TAZIDName,{"TAZ", "SEQ", "INT_EXT"},)
	goto quit

	badtemplate:
	msg = msg + {"Matrix template: ERROR! - Template NOT created"}
	TemplateOK = 1

	quit:
	closemap()
	on error default
	return({TemplateOK,msg})
endmacro