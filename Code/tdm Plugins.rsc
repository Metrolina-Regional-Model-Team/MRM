
Macro "Model.Attributes" (Args,Result)
    Attributes = {
        {"BackgroundColor",{255,255,255}},
        {"BannerPicture", null},
        {"BannerHeight", 80},
        {"BannerWidth", 2000},
        {"ResizePicture", 1},
        {"HideBanner", 0},
        {"DebugMode", 1},
        {"MaxProgressBars", 4},
        {"Layout", null},
        {"Requires",
            {{"Program", "TransCAD"},
            {"Version", 10},
            {"Build", 40615}}},
        {"ExpandStages", "Side by Side"},
        {"MinItemSpacing", 10},
        {"CodeUI", "Code\\ui.dbd"},
        {"Base Scenario Name", "Base"},
        {"ClearLogFiles", 0},
        {"CloseOpenFiles", 1},
        {"Output Folder Format", "Output Folder\\Scenario Name"},
        {"Output Folder Parameter", "Output Folder"},
        {"Output Folder Per Run", "No"},
        {"ReportAfterStep", 0},
        {"Shape", "Rectangle"},
        {"SourceMacro", "Model.Attributes"},
        {"Time Stamp Format", "yyyyMMdd_HHmm"}
    }
EndMacro


Macro "Model.Step" (Args,Result)
    Attributes = {
        {"FrameColor",{255,255,255}},
        {"Height", 30},
        {"PicturePosition", "CenterRight"},
        {"TextFont", "Calibri|12|400|000000|0"},
        {"Width", 260}
    }
EndMacro


Macro "Model.Arrow" (Args,Result)
    Attributes = {
        {"ArrowHead", "Triangle"},
        {"ArrowHeadSize", 8},
        {"PenWidth", 1},
        {"ArrowBaseSize", 10}
    }
EndMacro


/**
  This macro will run when the user open a new model file in a TransCAD window.
  You can use it to change the value for some particular parameters.
**/
Macro "Model.OnModelReady" (Args,Result)
    Return({"Base Folder": "%Model Folder%"})
EndMacro


Macro "Model.OnModelLoad" (Args, Results)
Body:
    // Compile source code
    flowchart = RunMacro("GetFlowChart")
    { drive , path , name , ext } = SplitPath(flowchart.UI)
    rootFolder = drive + path
    ui_DB = rootFolder + "Code\\ui.dbd"
    srcFile = rootFolder + "Code\\menu.lst"
    RunMacro("CompileGISDKCode", {Source: srcFile, UIDB: ui_DB, Silent: 0, ErrorMessage: "Error compiling code"})

    if lower(GetMapUnits()) <> "miles" then
        MessageBox("Set the system to miles before running the model", {Caption: "Warning", Icon: "Warning", Buttons: "yes"})
EndMacro

