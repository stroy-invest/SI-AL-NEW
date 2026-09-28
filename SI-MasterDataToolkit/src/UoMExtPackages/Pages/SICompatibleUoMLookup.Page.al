page 58003 "SI Compatible UoM Lookup"
{
    PageType = List;
    SourceTable = "Unit of Measure";
    SourceTableTemporary = true;
    ApplicationArea = All;
    UsageCategory = None;
    Caption = 'Сумісні одиниці вимірювання';
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field(Code; Rec.Code)
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає код одиниці вимірювання.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає опис одиниці вимірювання.';
                }
                field("SI Symbol"; Rec."SI Symbol")
                {
                    ApplicationArea = All;
                    ToolTip = 'Показує короткий символ одиниці вимірювання.';
                }
                field("SI UoM Kind"; Rec."SI UoM Kind")
                {
                    ApplicationArea = All;
                    ToolTip = 'Показує структурний тип одиниці вимірювання.';
                }
                field("SI Reference UoM Code"; Rec."SI Reference UoM Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Показує базову одиницю для масштабованої одиниці.';
                }
                field("SI Conversion Factor"; Rec."SI Conversion Factor")
                {
                    ApplicationArea = All;
                    ToolTip = 'Показує коефіцієнт перерахунку в базову одиницю.';
                }
            }
        }
    }

    procedure LoadCompatibleUoMs(ItemBaseUoMCode: Code[10])
    var
        SourceUoM: Record "Unit of Measure";
        UoMMgt: Codeunit "SI UoM Mgt.";
        RootCode: Code[10];
    begin
        Rec.Reset();
        Rec.DeleteAll();

        if not UoMMgt.TryGetRootBaseUoMCode(ItemBaseUoMCode, RootCode) then
            Error(
                'Для базової одиниці товару %1 не налаштовано коректний ланцюжок перерахунку. Відкрийте картку одиниці вимірювання та заповніть тип, базову одиницю і коефіцієнт.',
                ItemBaseUoMCode);

        SourceUoM.SetRange("SI Blocked", false);
        if SourceUoM.FindSet() then
            repeat
                if (SourceUoM."SI UoM Kind" in
                    [SourceUoM."SI UoM Kind"::Base, SourceUoM."SI UoM Kind"::Scaled]) and
                   UoMMgt.AreConvertible(SourceUoM.Code, ItemBaseUoMCode)
                then begin
                    Rec := SourceUoM;
                    Rec.Insert();
                end;
            until SourceUoM.Next() = 0;

        Rec.SetCurrentKey(Code);
        if Rec.Get(ItemBaseUoMCode) then;
    end;
}
