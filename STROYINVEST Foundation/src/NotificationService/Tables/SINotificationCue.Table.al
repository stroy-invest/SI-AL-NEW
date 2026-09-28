table 50215 "SI Notification Cue"
{
    Caption = 'Сповіщення';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
            DataClassification = SystemMetadata;
        }

        field(10; "Recipient Security ID Filter"; Guid)
        {
            Caption = 'Фільтр користувача';
            FieldClass = FlowFilter;
        }

        field(20; "Unread Notifications"; Integer)
        {
            Caption = 'Непрочитані';
            FieldClass = FlowField;
            CalcFormula =
                count("SI Notification Entry"
                    where(
                        "Recipient Security ID" =
                            field("Recipient Security ID Filter"),
                        Status =
                            const(Unread)));
        }
    }

    keys
    {
        key(PK; "Primary Key")
        {
            Clustered = true;
        }
    }
}