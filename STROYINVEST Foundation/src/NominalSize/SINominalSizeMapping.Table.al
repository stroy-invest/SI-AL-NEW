table 50520 "SI Nominal Size Mapping"
{
 Caption = 'Відповідність номінальних діаметрів';
 DataClassification = CustomerContent;
 fields {
 field(1; "Mapping Set Code"; Code[30]) { Caption = 'Код набору'; NotBlank = true; }
 field(2; "NPS Code"; Code[20]) { Caption = 'NPS'; NotBlank = true; }
 field(3; DN; Integer) { Caption = 'DN'; MinValue = 1; }
 field(4; Active; Boolean) { Caption = 'Активний'; InitValue = true; }
 field(5; "Sort Order"; Integer) { Caption = 'Порядок'; }
 }
 keys {
 key(PK; "Mapping Set Code", "NPS Code") { Clustered = true; }
 key(ByDN; "Mapping Set Code", DN) { Unique = true; }
 key(ByOrder; "Mapping Set Code", "Sort Order", "NPS Code") { }
 }
 trigger OnInsert() begin CheckValues(); end;
 trigger OnModify() begin CheckValues(); end;
 trigger OnRename() begin CheckValues(); end;
 local procedure CheckValues()
 begin
 TestField("Mapping Set Code"); TestField("NPS Code");
 if DN < 1 then Error('DN має бути більшим за нуль.');
 end;
}
