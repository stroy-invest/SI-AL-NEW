table 57141 "SI Prok Driver Mapping"
{
    Caption = 'Зіставлення водіїв Proktek';
    DataClassification = CustomerContent;
    LookupPageId = "SI Prok Driver Mappings";
    fields
    {
        field(1; "Connection Code"; Code[50]) { Caption = 'Профіль Proktek'; TableRelation = "SI Prok Connection".Code; }
        field(2; "Driver UUID"; Guid) { Caption = 'UUID водія Proktek'; }
        field(3; "Employee No."; Code[20]) { Caption = 'Код співробітника BC (Description 1)'; TableRelation = Employee."No."; }
        field(4; "Driver Name"; Text[100]) { Caption = 'Водій Proktek'; }
        field(5; "External Driver ID"; Integer) { Caption = 'ID водія Proktek'; }
    }
    keys { key(PK; "Connection Code", "Driver UUID") { Clustered = true; } }
}
