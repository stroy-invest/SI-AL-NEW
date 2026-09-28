page 59102 "SI Weighbridge Document Lines"
{
    PageType = ListPart;
    SourceTable = "SI Weighbridge Document Line";

    ApplicationArea = All;
    UsageCategory = None;

    Caption = 'Рядки';

    AutoSplitKey = true;
    DelayedInsert = true;

    // User cannot create arbitrary blank rows through the grid.
    InsertAllowed = false;
    MultipleNewLines = false;
    ShowFilter = false;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = All;
                    Caption = 'Товар';
                    Width = 24;
                }

                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = All;
                    Caption = 'Варіант';
                    Width = 16;
                }

                field("Allocated Weight"; Rec."Allocated Weight")
                {
                    ApplicationArea = All;
                    Caption = 'Розподілена вага, кг';
                    Width = 18;
                }

                field("Weight UoM Code"; Rec."Weight UoM Code")
                {
                    ApplicationArea = All;
                    Caption = 'Од. вим. ваги';
                    Editable = false;
                    Width = 10;
                }

                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = All;
                    Caption = 'Кількість';
                    Editable = false;
                    Width = 14;
                }

                field(
                    "Unit of Measure Code";
                Rec."Unit of Measure Code")
                {
                    ApplicationArea = All;
                    Caption = 'Од. вим. товару';
                    Editable = false;
                    Width = 14;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(AddLine)
            {
                ApplicationArea = All;
                Caption = 'Додати рядок';
                //Image = AddLine;

                ToolTip =
                    'Додає ще один товарний рядок та автоматично переносить у нього залишок нерозподіленої фізичної ваги.';

                trigger OnAction()
                var
                    NewLine:
                        Record "SI Weighbridge Document Line";
                    ExistingLine:
                        Record "SI Weighbridge Document Line";
                    Header:
                        Record "SI Weighbridge Document";

                    NextLineNo: Integer;
                    AllocatedTotal: Decimal;
                    RemainingWeight: Decimal;
                begin
                    Rec.TestField("Document Entry No.");

                    if not Header.Get(
                        Rec."Document Entry No.")
                    then
                        Error(
                            'Операційний документ %1 не знайдено.',
                            Rec."Document Entry No.");

                    ExistingLine.Reset();

                    ExistingLine.SetRange(
                        "Document Entry No.",
                        Rec."Document Entry No.");

                    if ExistingLine.FindSet() then
                        repeat
                            AllocatedTotal +=
                                ExistingLine."Allocated Weight";

                            if ExistingLine."Line No." > NextLineNo then
                                NextLineNo :=
                                    ExistingLine."Line No.";
                        until ExistingLine.Next() = 0;

                    RemainingWeight :=
                        Header."Net Weight" -
                        AllocatedTotal;

                    if RemainingWeight <= 0 then
                        Error(
                            'Уся фізична вага вже розподілена між рядками. Перед додаванням нового рядка зменште розподілену вагу існуючого рядка.');

                    NextLineNo += 10000;

                    NewLine.Init();

                    NewLine."Document Entry No." :=
                        Rec."Document Entry No.";

                    NewLine."Line No." :=
                        NextLineNo;

                    NewLine."Allocated Weight" :=
                        RemainingWeight;

                    NewLine.EnsureWeightUoM();

                    NewLine.Insert(true);

                    Rec.Get(
                        NewLine."Document Entry No.",
                        NewLine."Line No.");

                    CurrPage.Update(false);
                end;
            }

            action(RecalculateLine)
            {
                ApplicationArea = All;
                Caption = 'Перерахувати';
                Image = Refresh;

                trigger OnAction()
                var
                    UoMConversionMgt:
                        Codeunit "SI WB UoM Conversion Mgt.";
                begin
                    Rec.TestField("Document Entry No.");
                    Rec.TestField("Line No.");

                    UoMConversionMgt.RecalculateLine(
                        Rec);

                    Rec.Modify(true);

                    CurrPage.Update(false);
                end;
            }
        }
    }
}