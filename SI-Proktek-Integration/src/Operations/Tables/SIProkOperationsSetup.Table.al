table 57210 "SI Prok Operations Setup"
{
    Caption = 'Налаштування операцій Proktek';
    DataClassification = CustomerContent;
    LookupPageId = "SI Prok Operations Setup";
    DrillDownPageId = "SI Prok Operations Setup";

    fields
    {
        field(1; "Connection Code"; Code[50])
        {
            Caption = 'Профіль Proktek';
            TableRelation = "SI Prok Connection".Code;
            NotBlank = true;
        }
        field(10; "Sync Enabled"; Boolean)
        {
            Caption = 'Автоматична синхронізація дозволена';
            ToolTip = 'Дозвіл для Job Queue. Ручна синхронізація доступна окремо. За замовчуванням вимкнено.';
        }
        field(11; "Sync Interval Minutes"; Integer)
        {
            Caption = 'Інтервал, хв';
            MinValue = 1;
            MaxValue = 1440;
            ToolTip = 'Застосовується до стандартного Job Queue дією «Налаштувати Job Queue». Зміна поля сама не переплановує чергу.';
        }
        field(12; "Sync Lookback Days"; Integer)
        {
            Caption = 'Повторне опитування, днів';
            MinValue = 0;
            MaxValue = 30;
            ToolTip = 'Кожен запуск повторно опитує повні дні від Today - N до Today. Повторний Production UUID обробляється ідемпотентно.';
        }
        field(20; "Processing Mode"; Enum "SI Prok Processing Mode")
        {
            Caption = 'Режим проведення після першого друку';
            ToolTip = 'Manual: перегляд журналу та підтвердження проведення. Automatic: проведення після першої прийнятої дії «Надрукувати». Фізичний друк RDL ще не підключено.';
        }
    }

    keys
    {
        key(PK; "Connection Code") { Clustered = true; }
    }

    trigger OnInsert()
    begin
        if "Sync Interval Minutes" = 0 then
            "Sync Interval Minutes" := 1;
        if "Sync Lookback Days" = 0 then
            "Sync Lookback Days" := 1;
    end;
}
