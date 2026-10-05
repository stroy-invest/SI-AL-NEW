table 50468 "SI EDS Provider Rate Limit"
{
    Caption = 'Ліміти запитів провайдера EDS';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Provider Code"; Code[50]) { Caption = 'Провайдер'; NotBlank = true; }
        field(2; Sequence; Integer) { Caption = 'Порядок'; MinValue = 1; }
        field(3; "Window Seconds"; Integer) { Caption = 'Вікно, сек.'; MinValue = 1; }
        field(4; "Max Requests"; Integer) { Caption = 'Макс. запитів'; MinValue = 1; }
        field(5; "Safety Margin %"; Decimal)
        {
            Caption = 'Безпечне використання, %';
            MinValue = 1;
            MaxValue = 100;
            InitValue = 80;
        }
        field(6; Enabled; Boolean) { Caption = 'Увімкнено'; InitValue = true; }
        field(7; Description; Text[100]) { Caption = 'Опис'; }
    }

    keys
    {
        key(PK; "Provider Code", Sequence) { Clustered = true; }
        key(ProviderEnabled; "Provider Code", Enabled) { }
    }

    trigger OnInsert()
    begin
        if "Safety Margin %" = 0 then
            "Safety Margin %" := 80;
    end;

    procedure EffectiveMaxRequests(): Integer
    var
        EffectiveMax: Integer;
    begin
        EffectiveMax := Round("Max Requests" * "Safety Margin %" / 100, 1, '<');
        if EffectiveMax < 1 then
            EffectiveMax := 1;
        exit(EffectiveMax);
    end;
}
