table 61031 "SI Supply Site Sel Buffer"
{
    ObsoleteState = Pending;
    ObsoleteReason = 'Legacy site-selection state. Runtime uses SI Supply Request Site only.';
    Caption = 'Вибір будівельних майданчиків';
    TableType = Temporary;
    fields
    {
        field(1; "Site Code"; Code[20]) { Caption = 'Код'; }
        field(2; "Site Name"; Text[100]) { Caption = 'Будівельний майданчик'; }
        field(3; Selected; Boolean) { Caption = 'Вибрати'; }
    }
    keys { key(PK; "Site Code") { Clustered = true; } }
}
