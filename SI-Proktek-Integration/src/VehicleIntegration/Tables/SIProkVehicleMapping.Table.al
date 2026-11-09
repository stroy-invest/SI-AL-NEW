table 57110 "SI Prok Vehicle Mapping"
{
    Caption = 'Відповідність ТЗ Proktek';
    DataClassification = CustomerContent;
    LookupPageId = "SI Prok Vehicle Mappings";
    DrillDownPageId = "SI Prok Vehicle Mappings";

    fields
    {
        field(1; "Connection Code"; Code[50])
        {
            Caption = 'Підключення Proktek';
            TableRelation = "SI Prok Connection".Code;
            NotBlank = true;
        }
        field(2; "Vehicle No."; Code[20])
        {
            Caption = 'Транспортний засіб BC';
            TableRelation = "SI Vehicle Profile"."No.";
            NotBlank = true;
        }
        field(3; "External Mixer Code"; Code[50])
        {
            Caption = 'Mixer Code Proktek';
            Editable = false;
        }
        field(4; "External Mixer ID"; Integer)
        {
            Caption = 'Mixer ID Proktek';
            Editable = false;
        }
        field(5; "External Mixer UUID"; Guid)
        {
            Caption = 'Mixer UUID Proktek';
            Editable = false;
        }
        field(6; "Last Synced At"; DateTime)
        {
            Caption = 'Остання синхронізація';
            Editable = false;
        }
        field(7; "Sync Status"; Option)
        {
            Caption = 'Стан синхронізації';
            OptionMembers = NotSynced,Synced,Conflict,Error;
            OptionCaption = 'Не синхронізовано,Синхронізовано,Конфлікт,Помилка';
            Editable = false;
        }
        field(8; "Last Error"; Text[2048])
        {
            Caption = 'Останнє повідомлення';
            Editable = false;
        }
    }
    keys
    {
        key(PK; "Connection Code", "Vehicle No.") { Clustered = true; }
        key(ExternalCode; "Connection Code", "External Mixer Code") { }
        key(ExternalId; "Connection Code", "External Mixer ID") { }
        key(ExternalUuid; "Connection Code", "External Mixer UUID") { }
    }
    trigger OnInsert()
    begin
        TestField("Connection Code");
        TestField("Vehicle No.");
    end;
}
