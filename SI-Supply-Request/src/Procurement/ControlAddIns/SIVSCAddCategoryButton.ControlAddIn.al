controladdin "SI VSC Add Category Button"
{
    RequestedHeight = 38;
    MinimumHeight = 38;
    MaximumHeight = 38;
    RequestedWidth = 220;
    MinimumWidth = 160;
    HorizontalStretch = false;
    VerticalStretch = false;

    Scripts = 'src/Procurement/ControlAddIns/VSCAddCategoryButton/SIVSCAddCategoryButton.js';
    StartupScript = 'src/Procurement/ControlAddIns/VSCAddCategoryButton/SIVSCAddCategoryButtonStartup.js';

    event AddCategory();
}
