pageextension 57062 "SI Prok Item Snapshot Ext." extends "Item Card"
{
    actions
    {
        addlast(Processing)
        {
            group(SIProkRecipeSnapshot)
            {
                Caption = 'Proktek';

                action(CreateRecipeSnapshot)
                {
                    ApplicationArea = All;
                    Caption = 'Створити Recipe Snapshot';
                    Image = NewDocument;

                    trigger OnAction()
                    var
                        Snapshot: Record "SI Prok Recipe Snapshot";
                    begin
                        Snapshot.Init();
                        Snapshot.Validate("Item No.", Rec."No.");
                        Snapshot.Insert(true);
                        Snapshot.RefreshBaseData();
                        Snapshot.Modify(true);
                        Page.Run(Page::"SI Prok Recipe Snapshot Card", Snapshot);
                    end;
                }

                action(OpenRecipeSnapshots)
                {
                    ApplicationArea = All;
                    Caption = 'Recipe Snapshots';
                    Image = List;

                    trigger OnAction()
                    var
                        Snapshot: Record "SI Prok Recipe Snapshot";
                    begin
                        Snapshot.SetRange("Item No.", Rec."No.");
                        Page.Run(Page::"SI Prok Recipe Snapshots", Snapshot);
                    end;
                }
            }
        }
    }
}
