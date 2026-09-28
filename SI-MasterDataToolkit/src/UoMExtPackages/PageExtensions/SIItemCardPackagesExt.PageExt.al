pageextension 58002 "SI Item Card Packages Ext." extends "Item Card"
{
    layout
    {
        addlast(Content)
        {
            part("SI Item Packages"; "SI Item Packages Part")
            {
                ApplicationArea = All;
                Caption = 'Паковання';
                SubPageLink = "Item No." = field("No.");//,
                                                        //"Variant Code" = const('');
                UpdatePropagation = Both;
            }
        }
    }

    actions
    {
        addlast(Navigation)
        {
            action("SI Test Item UoM Conversion")
            {
                ApplicationArea = All;
                Caption = 'Тест фізичного перерахунку';
                ToolTip = 'Відкриває діагностичний тест item-aware перерахунку одиниць для поточного товару.';
                Image = TestDatabase;

                trigger OnAction()
                var
                    TestPage: Page "SI Item UoM Conversion Test";
                begin
                    TestPage.SetItem(Rec."No.", '');
                    TestPage.RunModal();
                end;
            }

            action("SI Open Item Packages")
            {
                ApplicationArea = All;
                Caption = 'Паковання';
                ToolTip = 'Відкриває повний перелік паковань поточного товару.';
                Image = ItemGroup;

                RunObject = page "SI Item Packages";
                RunPageLink = "Item No." = field("No.");
            }


        }
    }
}