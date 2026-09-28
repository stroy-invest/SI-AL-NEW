controladdin "SI WB Compact Docs"
{
    Scripts =
        './Resources/Docs/compactDocs.js';

    StartupScript =
        './Resources/Docs/startup.js';

    StyleSheets =
        './Resources/Common/siwbCompactGrid.css';

    RequestedHeight = 148;
    MinimumHeight = 132;
    MaximumHeight = 178;

    HorizontalStretch = true;
    HorizontalShrink = true;
    VerticalShrink = true;

    procedure SetData(DataJson: Text);

    event ControlReady();
    event AddRowRequested();
    event DeleteRowRequested(LineNo: Integer);
    event UploadFileRequested(LineNo: Integer);
    event OpenFileRequested(LineNo: Integer);
    event DocumentTypeChanged(LineNo: Integer; NewValue: Integer);
    event DocumentNoChanged(LineNo: Integer; NewValue: Text);
    event DocumentDateChanged(LineNo: Integer; YearValue: Integer; MonthValue: Integer; DayValue: Integer);
    event NoteChanged(LineNo: Integer; NewValue: Text);
}
