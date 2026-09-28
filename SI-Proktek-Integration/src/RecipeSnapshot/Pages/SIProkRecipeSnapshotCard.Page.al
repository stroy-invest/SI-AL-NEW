page 57020 "SI Prok Recipe Snapshot Card"
{
    PageType = Card;
    SourceTable = "SI Prok Recipe Snapshot";
    Caption = 'Recipe Snapshot';
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(BaseProduct)
            {
                Caption = 'Базовий продукт';
                field("Entry No."; Rec."Entry No.") { ApplicationArea = All; Editable = false; }
                field(Status; Rec.Status) { ApplicationArea = All; Editable = false; }
                field("Item No."; Rec."Item No.") { ApplicationArea = All; }
                field("Variant Code"; Rec."Variant Code") { ApplicationArea = All; }
                field("Production BOM No."; Rec."Production BOM No.") { ApplicationArea = All; }
                field(Description; Rec.Description) { ApplicationArea = All; }
                field("Base Formula Code"; Rec."Base Formula Code") { ApplicationArea = All; }
                field("Derived Formula Code"; Rec."Derived Formula Code") { ApplicationArea = All; }
                field("Proktek Formula Index"; Rec."Proktek Formula Index") { ApplicationArea = All; }
                field("Proktek Formula UUID"; Rec."Proktek Formula UUID") { ApplicationArea = All; }
            }
            part(Modifiers; "SI Prok Recipe Snapshot Lines")
            {
                ApplicationArea = All;
                SubPageLink = "Snapshot Entry No." = field("Entry No.");
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(CertifySnapshot)
            {
                ApplicationArea = All;
                Caption = 'Сертифікувати';
                Image = Approve;

                trigger OnAction()
                begin
                    Rec.TestField("Item No.");
                    Rec.TestField("Production BOM No.");
                    Rec.Status := Rec.Status::Certified;
                    Rec.Modify(true);
                    CurrPage.Update(false);
                end;
            }

            action(PreviewDerivedFormula)
            {
                ApplicationArea = All;
                Caption = 'Proktek: JSON preview derived Formula';
                Image = View;

                trigger OnAction()
                var
                    SnapshotMgt: Codeunit "SI Prok Recipe Snapshot Mgt.";
                    Preview: Text;
                begin
                    CurrPage.SaveRecord();
                    Preview := SnapshotMgt.BuildDerivedFormulaPreview(Rec."Entry No.");
                    Message('%1', Preview);
                end;
            }

            action(ExportDerivedFormula)
            {
                ApplicationArea = All;
                Caption = 'Proktek: експортувати derived Formula';
                Image = Export;

                trigger OnAction()
                var
                    SnapshotSync: Codeunit "SI Prok Snapshot Sync";
                begin
                    CurrPage.SaveRecord();
                    SnapshotSync.ExportSnapshot(Rec."Entry No.");
                    CurrPage.Update(false);
                end;
            }
        }
    }
}
