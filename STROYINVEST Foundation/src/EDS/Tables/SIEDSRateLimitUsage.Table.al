table 50469 "SI EDS Rate Limit Usage"
{
    Caption = 'Використання лімітів EDS';
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; BigInteger) { AutoIncrement = true; }
        field(2; "Provider Code"; Code[50]) { }
        field(3; "Requested At"; DateTime) { }
    }
    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
        key(ProviderTime; "Provider Code", "Requested At") { }
    }
}
