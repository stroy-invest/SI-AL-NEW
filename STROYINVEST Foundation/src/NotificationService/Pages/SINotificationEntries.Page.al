page 50256 "SI Notification Entries"
{
    Caption = 'Повідомлення користувачів';
    PageType = List;
    SourceTable = "SI Notification Entry";
    UsageCategory = History;
    ApplicationArea = All;
    Editable = false;
    CardPageId = "SI Notification Entry";

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає номер запису повідомлення.';
                }

                field("Created At"; Rec."Created At")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає дату й час створення повідомлення.';
                }

                field("Recipient User Name"; Rec."Recipient User Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає користувача, для якого створено повідомлення.';
                }

                field(Title; Rec.Title)
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає заголовок повідомлення.';
                }

                field(Severity; Rec.Severity)
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає рівень важливості повідомлення.';
                }

                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає статус повідомлення.';
                }

                field("Event Code"; Rec."Event Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає код бізнес-події, яка спричинила створення повідомлення.';
                }

                field("Recipient Group Code"; Rec."Recipient Group Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає групу, через яку було визначено отримувача.';
                }

                field("Source Record Caption"; Rec."Source Record Caption")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає опис пов’язаного запису-джерела.';
                }

                field("Read At"; Rec."Read At")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає дату й час прочитання повідомлення.';
                }
            }
        }
    }
}