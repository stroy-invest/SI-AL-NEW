controladdin SIProjectRespGrid
{
    RequestedHeight = 174;
    MinimumHeight = 54;
    MaximumHeight = 174;
    RequestedWidth = 900;
    MinimumWidth = 500;
    HorizontalStretch = true;
    VerticalStretch = false;
    VerticalShrink = true;

    Scripts = 'src/UI/ControlAddIns/SIProjectRespGrid/SIProjectRespGrid.js';
    StartupScript = 'src/UI/ControlAddIns/SIProjectRespGrid/SIProjectRespGridStartup.js';
    StyleSheets = 'src/UI/ControlAddIns/SIProjectRespGrid/SIProjectRespGrid.css';

    event ControlReady();
    event AddAssignment();
    event DeleteAssignment(LineNo: Integer);
    event LookupRole(LineNo: Integer);
    event LookupEmployee(LineNo: Integer);
    event UpdateValidFrom(LineNo: Integer; NewValue: Text);
    event UpdateValidTo(LineNo: Integer; NewValue: Text);
    event UpdatePrimary(LineNo: Integer; NewValue: Boolean);

    procedure SetAssignments(Data: Text);
}
