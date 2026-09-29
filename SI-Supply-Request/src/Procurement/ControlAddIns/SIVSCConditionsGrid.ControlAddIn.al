controladdin "SI VSC Conditions Grid"
{
    RequestedHeight = 300;
    MinimumHeight = 220;
    MaximumHeight = 500;
    RequestedWidth = 1200;
    MinimumWidth = 700;
    HorizontalStretch = true;
    VerticalStretch = false;

    Scripts = 'src/Procurement/ControlAddIns/SIVSCConditionsGrid.js';
    StartupScript = 'src/Procurement/ControlAddIns/SIVSCConditionsGridStartup.js';
    StyleSheets = 'src/Procurement/ControlAddIns/SIVSCConditionsGrid.css';

    event ControlReady();
    event AddRow();
    event DeleteRow(EntryNo: Integer);
    event RowChanged(EntryNo: Integer; ShipmentMethodCode: Text; MinimumOrderQuantity: Decimal; OrderMultiple: Decimal; UoMCode: Text; LeadTimeCalculation: Text);

    procedure ClearGrid();
    procedure Render(DataJson: Text; ShipmentMethodsJson: Text; UnitsOfMeasureJson: Text; CategoryName: Text);
}
