page 50424 "SI EDS Inbound Events"
{
    PageType = List;
    SourceTable = "SI EDS Inbound Event";

    ApplicationArea = All;
    UsageCategory = Administration;

    Caption = 'EDS Inbound Events';

    CardPageId = "SI EDS Inbound Event Card";

    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Events)
            {
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the internal entry number of the inbound event.';
                }

                field("Received At"; Rec."Received At")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies when the event was durably accepted by EDS.';
                }

                field("Service Code"; Rec."Service Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the EDS service associated with the inbound event.';
                }

                field("Event ID"; Rec."Event ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the stable external identifier used for idempotent event acceptance.';
                }

                field("Event Type"; Rec."Event Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the type of the inbound event.';
                }

                field("Source System"; Rec."Source System")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the external system that produced the event.';
                }

                field("Source Record ID"; Rec."Source Record ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the source-system record identifier, when available.';
                }

                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the current EDS inbound processing status.';
                }

                field("Processing Attempt Count"; Rec."Processing Attempt Count")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies how many downstream processing attempts have been started.';
                }

                field("Processing Started At"; Rec."Processing Started At")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies when the latest processing attempt started.';
                }

                field("Processed At"; Rec."Processed At")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies when downstream processing completed successfully.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ViewPayload)
            {
                ApplicationArea = All;
                Caption = 'View Payload';
                Image = View;
                ToolTip = 'Displays the raw JSON payload stored for the inbound event.';

                trigger OnAction()
                var
                    PayloadText: Text;
                begin
                    PayloadText := Rec.GetPayload();

                    if PayloadText = '' then begin
                        Message('The inbound event does not contain a payload.');
                        exit;
                    end;

                    Message('%1', PayloadText);
                end;
            }

            action(ViewLastError)
            {
                ApplicationArea = All;
                Caption = 'View Last Error';
                Image = ErrorLog;
                ToolTip = 'Displays the last downstream processing error stored for the inbound event.';

                trigger OnAction()
                var
                    ErrorText: Text;
                begin
                    ErrorText := Rec.GetLastError();

                    if ErrorText = '' then begin
                        Message('No processing error is stored for this inbound event.');
                        exit;
                    end;

                    Message('%1', ErrorText);
                end;
            }
        }

        area(Navigation)
        {
            action(OpenCard)
            {
                ApplicationArea = All;
                Caption = 'Картка';

                trigger OnAction()
                begin
                    Page.Run(
                        Page::"SI EDS Inbound Event Card",
                        Rec);
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.SetCurrentKey(Status, "Received At");
        Rec.Ascending(false);
    end;
}