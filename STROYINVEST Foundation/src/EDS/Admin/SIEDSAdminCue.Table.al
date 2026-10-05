table 50470 "SI EDS Admin Cue"
{
    Caption = 'EDS Admin Cue';
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Primary Key"; Code[10]) { }
        field(10; "Services"; Integer) { FieldClass = FlowField; CalcFormula = count("SI EDS Service"); }
        field(11; "Operations"; Integer) { FieldClass = FlowField; CalcFormula = count("SI EDS Operation"); }
        field(12; "Providers"; Integer) { FieldClass = FlowField; CalcFormula = count("SI EDS Provider"); }
        field(13; "Endpoints"; Integer) { FieldClass = FlowField; CalcFormula = count("SI EDS Endpoint"); }
        field(14; "Credentials"; Integer) { FieldClass = FlowField; CalcFormula = count("SI EDS Credential"); }
        field(15; "Routes"; Integer) { FieldClass = FlowField; CalcFormula = count("SI EDS Provider Route"); }
        field(16; "Parameters"; Integer) { FieldClass = FlowField; CalcFormula = count("SI EDS Parameter"); }
        field(17; "Rate Limits"; Integer) { FieldClass = FlowField; CalcFormula = count("SI EDS Provider Rate Limit"); }
        field(20; "Async Pending"; Integer) { FieldClass = FlowField; CalcFormula = count("SI EDS Async Request" where(Status = const(Pending))); }
        field(21; "Async Errors"; Integer) { FieldClass = FlowField; CalcFormula = count("SI EDS Async Request" where(Status = const(Error))); }
        field(22; "Async Timed Out"; Integer) { FieldClass = FlowField; CalcFormula = count("SI EDS Async Request" where(Status = const("Timed Out"))); }
        field(30; "Execution Log"; Integer) { FieldClass = FlowField; CalcFormula = count("SI EDS Exec. Log"); }
        field(31; "Technical Failures"; Integer) { FieldClass = FlowField; CalcFormula = count("SI EDS Exec. Log" where("Result Type" = const("Technical Failure"))); }
    }

    keys { key(PK; "Primary Key") { Clustered = true; } }
}
