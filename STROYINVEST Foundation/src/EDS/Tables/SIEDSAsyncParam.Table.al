table 50449 "SI EDS Async Param"
{
    Caption = 'EDS Async Parameter';
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Request Entry No."; Integer) { }
        field(2; "Line No."; Integer) { }
        field(3; Code; Code[50]) { }
        field(4; Value; Text[2048]) { }
    }

    keys
    {
        key(PK; "Request Entry No.", "Line No.") { Clustered = true; }
        key(CodeKey; "Request Entry No.", Code) { }
    }
}
