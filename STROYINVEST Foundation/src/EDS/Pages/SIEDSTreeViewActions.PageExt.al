pageextension 50476 "SI EDS Operations Tree Act" extends "SI EDS Operations"
{
    actions { addfirst(Processing) { action(TreeView) { ApplicationArea = All; Caption = 'Дерево'; Image = Hierarchy; RunObject = page "SI EDS Operations Tree"; } } }
}

pageextension 50477 "SI EDS Routes Tree Act" extends "SI EDS Provider Routes"
{
    actions { addfirst(Processing) { action(TreeView) { ApplicationArea = All; Caption = 'Дерево'; Image = Hierarchy; RunObject = page "SI EDS Provider Routes Tree"; } } }
}

pageextension 50478 "SI EDS Parameters Tree Act" extends "SI EDS Parameters"
{
    actions { addfirst(Processing) { action(TreeView) { ApplicationArea = All; Caption = 'Дерево'; Image = Hierarchy; RunObject = page "SI EDS Parameters Tree"; } } }
}
