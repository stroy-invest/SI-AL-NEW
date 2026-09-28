controladdin "SI Product Config Values Grid"
{
    RequestedHeight = 132;
    RequestedWidth = 1100;
    MinimumHeight = 90;
    MinimumWidth = 700;
    MaximumHeight = 210;
    VerticalStretch = false;
    HorizontalStretch = true;

    Scripts = 'src/ControlAddIns/SIProductConfigValuesGrid.js';
    StartupScript = 'src/ControlAddIns/SIProductConfigValuesGridStartup.js';

    event ControlReady();
    event AddRowRequested();
    event DeleteRowRequested(ParameterCode: Text);
    event ParameterLookupRequested();
    event ControlledValueLookupRequested(ParameterCode: Text);
    event ReferenceValueLookupRequested(ParameterCode: Text);
    event ValueChanged(ParameterCode: Text; ValueField: Text; NewValue: Text);

    procedure RenderRows(RowsJson: Text);
}
