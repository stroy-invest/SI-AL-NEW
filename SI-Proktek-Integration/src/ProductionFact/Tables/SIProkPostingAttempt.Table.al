table 57126 "SI Prok Posting Attempt"
{
    Caption = 'Спроба проведення Proktek';
    DataClassification = CustomerContent;
    fields
    {
        field(1; "Production UUID"; Guid) { Caption = 'Production UUID'; }
        field(2; "Fact Entry No."; Integer) { Caption = 'Факт'; }
        field(3; Status; Option) { Caption = 'Статус'; OptionMembers = Started,Completed; OptionCaption = 'Розпочато,Завершено'; }
        field(4; "Started At"; DateTime) { Caption = 'Початок'; }
        field(5; "Finished At"; DateTime) { Caption = 'Завершення'; }
    }
    keys { key(PK; "Production UUID") { Clustered = true; } }
}
