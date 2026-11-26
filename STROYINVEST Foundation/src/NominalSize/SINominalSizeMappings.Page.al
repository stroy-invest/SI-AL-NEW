page 50520 "SI Nominal Size Mappings"
{
 PageType = List; SourceTable = "SI Nominal Size Mapping";
 SourceTableView = sorting("Mapping Set Code", "Sort Order", "NPS Code");
 Caption = 'Відповідність номінальних діаметрів'; ApplicationArea = All; UsageCategory = Administration;
 layout { area(Content) { repeater(Lines) {
 field(MappingSet; Rec."Mapping Set Code") { ApplicationArea = All; }
 field(NPS; Rec."NPS Code") { ApplicationArea = All; }
 field(DN; Rec.DN) { ApplicationArea = All; }
 field(Active; Rec.Active) { ApplicationArea = All; }
 field(SortOrder; Rec."Sort Order") { ApplicationArea = All; }
 } } }
 actions { area(Processing) { action(SeedPipeMapping) {
 Caption = 'Заповнити відповідності NPS–DN'; ApplicationArea = All;
 AccessByPermission = tabledata "SI Nominal Size Mapping" = I;
 trigger OnAction()
 var Seed: Codeunit "SI Nominal Size Seed";
 begin Seed.SeedPipeMapping(); CurrPage.Update(false); end;
 } } }
}
