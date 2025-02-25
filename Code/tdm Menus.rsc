
Class "Visualize.Menu.Items"

    init do 
        self.runtimeObj = CreateObject("Model.Runtime")
    enditem 
    
    Macro "GetMenus" do
        Menus = {
					{ ID: "M1", Title: "Show Selected Param Info" , Macro: "SelectedParamInfo" }
				}
        Return(Menus)
    enditem 

    Macro "SelectedParamInfo" do
        ShowArray({ SelectedParamInfo: self.runtimeObj.GetSelectedParamInfo() })
        enditem  
 
EndClass


Macro "OpenParamFile" (Args,Result)
Body:
	mr = CreateObject("Model.Runtime")
	curr_param = mr.GetSelectedParamInfo()
	result = mr.OpenFile(curr_param.Name)
EndMacro


MenuItem "Metro Menu Item" text: "Metrolina"
    menu "Metrolina Menu"

menu "Metrolina Menu"
    init do
    enditem

    MenuItem "Create Tour Dir" text: "Create Scenario"
        do 
        mr = CreateObject("Model.Runtime")
        Args = mr.GetValues()
        {, scen_name} = mr.GetScenario()

        // Check that a scenario is selected and that a folder has been chosen
        if scen_name = null then do
            ShowMessage("Choose a scenario.")
            return()
        end

        mr.RunCode("Create Tour Dir", Args)
        return(1)
    enditem

    separator

    MenuItem "Utilities" text: "Tools"
        menu "MRM Utilities"

endMenu 
menu "MRM Utilities"
    init do
    enditem

   MenuItem "diff" text: "Diff Tool" do
        mr = CreateObject("Model.Runtime")
        mr.RunCodeEx("Open Diff Tool")
    enditem

endMenu



